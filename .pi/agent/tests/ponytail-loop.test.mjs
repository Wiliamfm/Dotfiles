// Run: node --experimental-vm-modules --test .pi/agent/tests/ponytail-loop.test.mjs
import assert from "node:assert/strict";
import { EventEmitter } from "node:events";
import { readFileSync } from "node:fs";
import { stripTypeScriptTypes } from "node:module";
import { PassThrough } from "node:stream";
import test from "node:test";
import vm from "node:vm";

const skill = '<skill name="ponytail" location="/skills/ponytail">\nInstructions\n</skill>\n';
const message = (role, content) => ({ type: "message", message: { role, content } });

const reviewEvent = (message) => ({ type: "message_end", message });
const reviewOutput = [
	reviewEvent({ role: "user", content: '<skill name="ponytail-review" location="/skills/ponytail-review/SKILL.md">\nReview instructions\n</skill>\nReview this' }),
	reviewEvent({ role: "assistant", content: [{ type: "text", text: "Review report" }] }),
].map((event) => JSON.stringify(event) + "\n").join("");

async function runReview(branch, prompt, { commands = [], output = reviewOutput, onChunk, exitCode = 0, stderr = "", processError } = {}) {
	let task;
	let reviewArgs;
	let report;
	let loader;
	const live = [];
	const notifications = [];
	const spawn = (command, args, options) => {
		assert.notEqual(command, "git", "Change discovery belongs to the reviewer");
		reviewArgs = args;
		task = args.at(-1);
		const child = Object.assign(new EventEmitter(), { stdout: new PassThrough(), stderr: new PassThrough() });
		options.signal.addEventListener("abort", () => child.emit("error", new Error("Aborted")), { once: true });
		setImmediate(() => {
			try {
				if (processError) throw processError;
				child.stderr.write(stderr);
				const chunks = args.includes("json") ? (Array.isArray(output) ? output : [output]) : ["Review report"];
				for (const chunk of chunks) {
					if (options.signal.aborted) break;
					child.stdout.write(chunk);
					onChunk?.(live, () => { loader.controller.abort(); loader.onAbort?.(); });
				}
				child.stdout.end();
				child.stderr.end();
				child.emit("close", exitCode);
			} catch (err) {
				child.emit("error", err);
			}
		});
		return child;
	};
	const source = readFileSync(new URL("../extensions/ponytail-loop.ts", import.meta.url), "utf8");
	const extension = new vm.SourceTextModule(stripTypeScriptTypes(source));
	await extension.link(async (name) => {
		const exports = name === "node:child_process" ? { spawn }
			: name === "@earendil-works/pi-coding-agent" ? { BorderedLoader: class {
				controller = new AbortController();
				signal = this.controller.signal;
				constructor() { loader = this; }
				addChild() {}
			} }
			: name === "@earendil-works/pi-tui" ? { Text: class {
				constructor(value) { this.setText(value); }
				setText(value) { live.push(value); }
			} }
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
			custom: (render) => new Promise((resolve) => render({ requestRender() {} }, {}, {}, resolve)),
			notify(message) { notifications.push(message); },
		},
	};
	await handlers.before_agent_start({ messageType: "user", prompt }, ctx);
	await handlers.agent_settled({ aborted: false }, ctx);
	return { task, args: reviewArgs, request: report?.details.request, report, live, notifications };
}

test("review skills appear live and remain above the saved report", async () => {
	let visibleWhileRunning = false;
	const review = await runReview([], skill + "add X", {
		onChunk(live) { visibleWhileRunning ||= live.some((value) => value.includes("ponytail-review")); },
	});
	assert.ok(visibleWhileRunning, "Skills must be visible before the reviewer exits");
	assert.match(review.report.content, /Skills loaded: ponytail-review\n\nReview report$/);
	assert.doesNotMatch(review.report.content, /Review instructions|message_end/);
});

test("only successful reads of known skills are added, once, after completion", async () => {
	const events = [
		{ type: "tool_execution_start", toolCallId: "failed", toolName: "read", args: { path: "/skills/failed/SKILL.md" } },
		{ type: "tool_execution_end", toolCallId: "failed", toolName: "read", isError: true },
		{ type: "tool_execution_start", toolCallId: "ok", toolName: "read", args: { path: "skills/domain/SKILL.md" } },
		{ type: "tool_execution_end", toolCallId: "ok", toolName: "read", isError: false },
		{ type: "tool_execution_start", toolCallId: "again", toolName: "read", args: { path: "/skills/domain/SKILL.md" } },
		{ type: "tool_execution_end", toolCallId: "again", toolName: "read", isError: false },
		{ type: "tool_execution_start", toolCallId: "unknown", toolName: "read", args: { path: "/src/SKILL.md" } },
		{ type: "tool_execution_end", toolCallId: "unknown", toolName: "read", isError: false },
	];
	const [injected, report] = reviewOutput.trimEnd().split("\n");
	let chunk = 0;
	const review = await runReview([], skill + "add X", {
		commands: ["domain", "failed", "unread"].map((name) => ({ name: `skill:${name}`, source: "skill", sourceInfo: { path: `/skills/${name}/SKILL.md` } })),
		output: [injected + "\n", ...events.map((event) => JSON.stringify(event) + "\n"), report + "\n"],
		onChunk(live) {
			if (++chunk === 4) assert.doesNotMatch(live.at(-1), /domain|failed/);
			if (chunk === 5) assert.match(live.at(-1), /ponytail-review · domain$/);
		},
	});
	assert.match(review.report.content, /Skills loaded: ponytail-review · domain\n\nReview report$/);
	assert.doesNotMatch(review.report.content, /failed|unread|unknown/);
});

test("failed or truncated reviewer responses are not saved as successful reports", async () => {
	for (const stopReason of ["error", "aborted", "length"]) {
		const review = await runReview([], skill + "add X", {
			output: JSON.stringify(reviewEvent({ role: "assistant", stopReason, errorMessage: "Provider failure", content: [{ type: "text", text: "Incomplete findings" }] })) + "\n",
		});
		assert.equal(review.report, undefined);
		assert.equal(review.notifications.length, 1);
	}
});

test("split UTF-8 output preserves the final report without intermediate commentary", async () => {
	const final = "Final findings 🐴\u2028Second line\u2029Last line";
	const output = Buffer.from([
		JSON.stringify({ type: "session", version: 3 }),
		reviewOutput.trimEnd().split("\n")[0],
		JSON.stringify(reviewEvent({ role: "assistant", content: [{ type: "text", text: "Investigating..." }] })),
		JSON.stringify(reviewEvent({ role: "assistant", content: [{ type: "text", text: final }] })),
	].join("\r\n"));
	const review = await runReview([], skill + "add X", {
		output: Array.from(output, (_, i) => output.subarray(i, i + 1)),
	});
	assert.ok(review.report.content.endsWith(`Skills loaded: ponytail-review\n\n${final}`));
	assert.doesNotMatch(review.report.content, /Investigating/);
	assert.deepEqual(review.notifications, []);
});

test("invalid reviewer output is reported rather than saved", async () => {
	const review = await runReview([], skill + "add X", { output: "not JSON\n" + reviewOutput });
	assert.equal(review.report, undefined);
	assert.equal(review.notifications.length, 1);
});

test("a recovered provider error does not discard the completed review", async () => {
	const failure = reviewEvent({ role: "assistant", stopReason: "error", errorMessage: "Retrying", content: [] });
	const review = await runReview([], skill + "add X", { output: JSON.stringify(failure) + "\n" + reviewOutput });
	assert.ok(review.report.content.endsWith("Review report"));
	assert.deepEqual(review.notifications, []);
});

test("cancelling a review saves no report and shows no failure notification", async () => {
	const review = await runReview([], skill + "add X", {
		output: reviewOutput.trimEnd().split("\n").map((line) => line + "\n"),
		onChunk(_live, cancel) { cancel(); },
	});
	assert.equal(review.report, undefined);
	assert.deepEqual(review.notifications, []);
});

test("review process failures are reported without saving partial findings", async () => {
	for (const options of [{ exitCode: 1, stderr: "Process failed" }, { processError: new Error("Could not start") }]) {
		const review = await runReview([], skill + "add X", options);
		assert.equal(review.report, undefined);
		assert.equal(review.notifications.length, 1);
	}
});

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
			...paths.map((path, i) => ({ name: `skill:example-${i}`, source: "skill", sourceInfo: { path } })),
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
