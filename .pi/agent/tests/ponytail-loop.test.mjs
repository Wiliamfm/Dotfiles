// Run: node --experimental-vm-modules --test .pi/agent/tests/ponytail-loop.test.mjs
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { stripTypeScriptTypes } from "node:module";
import test from "node:test";
import { promisify } from "node:util";
import vm from "node:vm";

const skill = '<skill name="ponytail" location="/skills/ponytail">\nInstructions\n</skill>\n';
const message = (role, content) => ({ type: "message", message: { role, content } });

async function runReview(branch, prompt, { commands = [] } = {}) {
	let task;
	let reviewArgs;
	let report;
	const execFile = () => {};
	execFile[promisify.custom] = (command, args) => {
		assert.notEqual(command, "git", "Change discovery belongs to the reviewer");
		reviewArgs = args;
		task = args.at(-1);
		return Object.assign(Promise.resolve({ stdout: "Review report", stderr: "" }), { child: { stdin: { end() {} } } });
	};
	const source = readFileSync(new URL("../extensions/ponytail-loop.ts", import.meta.url), "utf8");
	const extension = new vm.SourceTextModule(stripTypeScriptTypes(source));
	await extension.link(async (name) => {
		const exports = name === "node:child_process" ? { execFile }
			: name === "@earendil-works/pi-coding-agent" ? { BorderedLoader: class { signal = new AbortController().signal; } }
			: await import(name);
		return new vm.SyntheticModule(Object.keys(exports), function () {
			for (const [key, value] of Object.entries(exports)) this.setExport(key, value);
		});
	});
	await extension.evaluate();
	const handlers = {};
	extension.namespace.default({
		on(name, handler) { handlers[name] = handler; },
		registerCommand() {},
		getCommands: () => commands,
		sendMessage(message) { report = message; },
	});
	const ctx = {
		cwd: "/", mode: "tui",
		sessionManager: { getBranch: () => branch },
		ui: {
			custom: (render) => new Promise((resolve) => render({}, {}, {}, resolve)),
			notify(message) { throw new Error(message); },
		},
	};
	await handlers.before_agent_start({ messageType: "user", prompt }, ctx);
	await handlers.agent_settled({ aborted: false }, ctx);
	return { task, args: reviewArgs, request: report?.details.request };
}

test("exploration hands off only the original request, not the plan or approval", async () => {
	const review = await runReview([
		message("user", "add X"),
		message("assistant", "Implement X in foo.ts"),
	], skill + "go ahead");
	assert.equal(review.request, "add X");
	assert.ok(review.task.endsWith("## Request\nadd X"));
	assert.doesNotMatch(review.task, /Implement X|go ahead/);
});

test("the original request excludes all leading injected skills", async () => {
	const explore = '<skill name="explore" location="/skills/explore">\nExplore instructions\n</skill>\n';
	const review = await runReview([
		message("user", [{ type: "text", text: explore + explore + "add X" }]),
		message("assistant", "Exploration and plan"),
	], skill + "go ahead");
	assert.equal(review.request, "add X");
	assert.ok(review.task.endsWith("## Request\nadd X"));
	assert.doesNotMatch(review.task, /Explore instructions|Exploration and plan|Instructions/);
});

test("a fix session reviews the original request without the previous review", async () => {
	const prompt = skill + [
		"Fix findings 2 from the review below. Fix only those and leave everything else as is.",
		"Respect `shortcut:` comments unless a finding is about them.",
		"",
		"## Original request",
		"<request>\nadd X\n</request>",
		"",
		"## Ponytail review\nPrevious findings",
	].join("\n");
	const review = await runReview([], prompt);
	assert.equal(review.request, "add X");
	assert.ok(review.task.endsWith("## Request\nadd X"));
	assert.doesNotMatch(review.task, /Fix findings|Previous findings|<request>/);
});

test("a fresh ponytail session reviews the current request", async () => {
	const review = await runReview([], skill + "add X");
	assert.equal(review.request, "add X");
});

test("the reviewer starts fresh without requiring git snapshots or a forced diff", async () => {
	const review = await runReview([], skill + "add X");
	assert.ok(review.args.includes("--no-session"));
	assert.ok(review.args.includes("--no-extensions"));
	for (const flag of ["--continue", "-c", "--resume", "-r", "--session", "--session-id", "--fork"]) {
		assert.ok(!review.args.includes(flag));
	}
	assert.match(review.task, /^\/skill:ponytail-review /);
	assert.doesNotMatch(review.task, /git diff/);
	assert.ok(review.task.endsWith("## Request\nadd X"));
});

test("the reviewer retains explicitly supplied skills outside normal discovery", async () => {
	const paths = ["/outside/ponytail-review/SKILL.md", "/outside skills/example-domain/SKILL.md"];
	const review = await runReview([], skill + "add X", {
		commands: [
			...paths.map((path) => ({ source: "skill", sourceInfo: { path } })),
			{ source: "extension", sourceInfo: { path: "/extensions/example.ts" } },
		],
	});
	const skillPaths = review.args.flatMap((arg, i) => arg === "--skill" ? [review.args[i + 1]] : []);
	assert.deepEqual(skillPaths, paths);
	assert.ok(!review.args.includes("/extensions/example.ts"));
});

test("a later explicit ponytail turn still reviews against the original request", async () => {
	const review = await runReview([
		message("user", skill + "add X"),
		message("assistant", [{ type: "text", text: "Added X in foo.ts" }]),
	], skill + "rename Y");
	assert.equal(review.request, "add X");
	assert.ok(review.task.endsWith("## Request\nadd X"));
});

test("quoting a ponytail invocation does not trigger review", async () => {
	const review = await runReview([], "Explain this prompt:\n\n" + skill + "add X");
	assert.equal(review.task, undefined);
	assert.equal(review.request, undefined);
});

test("an earlier ponytail invocation does not trigger review on a later ordinary turn", async () => {
	const review = await runReview([
		message("user", skill + "add X"),
		message("assistant", "Added X"),
	], "rename Y");
	assert.equal(review.task, undefined);
	assert.equal(review.request, undefined);
});
