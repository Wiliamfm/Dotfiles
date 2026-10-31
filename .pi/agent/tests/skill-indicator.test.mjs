// Run: node --experimental-vm-modules --test .pi/agent/tests/skill-indicator.test.mjs
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { stripTypeScriptTypes } from "node:module";
import test from "node:test";
import vm from "node:vm";

const skills = ["tdd", "explore", "ponytail"].map((name) => ({
	name: `skill:${name}`, source: "skill", sourceInfo: { path: `/skills/${name}/SKILL.md` },
}));
const skillBlock = (name) => `<skill name="${name}" location="/skills/${name}/SKILL.md">\nInstructions\n</skill>\n`;
const user = (content) => ({ role: "user", content });

async function setup(branch = [], mode = "tui", commands = skills) {
	const source = readFileSync(new URL("../extensions/skill-indicator.ts", import.meta.url), "utf8");
	const extension = new vm.SourceTextModule(stripTypeScriptTypes(source));
	await extension.link(async (name) => {
		const exports = await import(name);
		return new vm.SyntheticModule(Object.keys(exports), function () {
			for (const [key, value] of Object.entries(exports)) this.setExport(key, value);
		});
	});
	await extension.evaluate();
	const handlers = new Map();
	let status;
	const ctx = {
		cwd: "/", mode,
		sessionManager: { getBranch: () => branch },
		ui: {
			theme: { fg: (_color, text) => text },
			setStatus(_key, value) { status = value; },
		},
	};
	extension.namespace.default({
		on(name, handler) {
			if (!handlers.has(name)) handlers.set(name, []);
			handlers.get(name).push(handler);
		},
		getCommands: () => commands,
	});
	const emit = async (name, event = {}) => {
		for (const handler of handlers.get(name) ?? []) await handler({ type: name, ...event }, ctx);
	};
	await emit("session_start", { reason: "startup" });
	let callId = 0;
	const message = async (message) => {
		await emit("message_end", { message });
		branch.push({ type: "message", message });
	};
	return {
		get status() { return status; },
		emit, message,
		async read(path, isError = false) {
			const id = String(++callId);
			await message({ role: "assistant", content: [{ type: "toolCall", id, name: "read", arguments: { path } }] });
			const content = [{ type: "text", text: "Instructions" }];
			await emit("tool_result", { toolName: "read", toolCallId: id, input: { path }, content, isError });
			await message({ role: "toolResult", toolName: "read", toolCallId: id, content, isError });
		},
	};
}

test("nested skill reads are visible immediately and survive reload through their parent's history", async () => {
	const branch = [];
	const app = await setup(branch);
	await app.message(user("do work"));
	await app.emit("tool_result", {
		toolName: "read", toolCallId: "parent/1", parentToolCallId: "parent",
		input: { path: "/skills/tdd/SKILL.md" }, isError: false,
	});
	assert.equal(app.status, "Skills: ● tdd");
	await app.message({
		role: "toolResult", toolName: "codemode", toolCallId: "parent", isError: true, content: [],
		nestedCalls: {
			complete: true,
			calls: [
				{ id: "parent/1", name: "read", arguments: { path: "/skills/tdd/SKILL.md" }, status: "ok" },
				{ id: "parent/2", name: "read", arguments: { path: "/skills/explore/SKILL.md" }, status: "error" },
			],
		},
	});
	const resumed = await setup(branch);
	assert.equal(resumed.status, "Skills: ● tdd");
});

test("non-interactive sessions do not write terminal status", async () => {
	const app = await setup([], "print");
	await app.message(user(skillBlock("explore") + "plan"));
	await app.read("/skills/tdd/SKILL.md");
	assert.equal(app.status, undefined);
});

test("reload and resume restore the latest request, and new sessions and tree navigation do not leak skills", async () => {
	const branch = [];
	const app = await setup(branch);
	await app.message(user(skillBlock("explore") + "plan"));
	await app.read("/skills/tdd/SKILL.md");
	await app.message(user("build"));
	await app.read("/skills/ponytail/SKILL.md", true);
	await app.read("/skills/tdd/SKILL.md");
	const resumed = await setup(branch);
	assert.equal(resumed.status, "Skills: ● tdd · ○ explore");
	await app.emit("session_start", { reason: "reload" });
	assert.equal(app.status, resumed.status);
	branch.splice(1);
	await app.emit("session_tree");
	assert.equal(app.status, "Skills: ● explore");
	branch.length = 0;
	await app.emit("session_start", { reason: "new" });
	assert.equal(app.status, undefined);
});

test("current-request skills remain visible at 80 columns despite long skill history", async () => {
	const app = await setup();
	await app.message(user([
		"historical-skill-number-one",
		"historical-skill-number-two",
		"historical-skill-number-three",
	].map(skillBlock).join("")));
	await app.message(user("next task"));
	await app.read("/skills/tdd/SKILL.md");
	// All fixture characters occupy one terminal column; simulate footer truncation.
	const visible = app.status.slice(0, 79) + "…";
	assert.match(visible, /^Skills: ● tdd · ○ historical-skill-number-one/);
});

test("failed reads, ordinary files, and skill mentions do not count as loads", async () => {
	const app = await setup();
	await app.read("/skills/tdd/SKILL.md", true);
	await app.read("/skills/tdd/references.md");
	await app.read("/unregistered/SKILL.md");
	await app.emit("tool_result", { toolName: "bash", input: { command: "echo SKILL.md" }, isError: false });
	await app.message(user("How does /skill:tdd work?"));
	assert.equal(app.status, undefined);
});

test("reads match discovered skill names through relative, home, and symlink paths", async (t) => {
	const dir = mkdtempSync(`${tmpdir()}/skill-indicator-`);
	t.after(() => rmSync(dir, { recursive: true, force: true }));
	writeFileSync(`${dir}/single.md`, "Instructions");
	symlinkSync(`${dir}/single.md`, `${dir}/alias.md`);
	const commands = [
		{ name: "skill:declared-name", source: "skill", sourceInfo: { path: `${dir}/single.md` } },
		{ name: "skill:home-skill", source: "skill", sourceInfo: { path: `${homedir()}/skills/home.md` } },
	];
	const app = await setup([], "tui", commands);
	await app.read(`${dir}/alias.md`);
	assert.equal(app.status, "Skills: ● declared-name");
	await app.message(user("next"));
	await app.read(`${dir.slice(1)}/single.md`);
	await app.read("~/skills/home.md");
	assert.equal(app.status, "Skills: ● declared-name · ● home-skill");
});

test("expanded skill commands load skills, including when delivered as steering messages", async () => {
	const app = await setup();
	await app.message(user(skillBlock("explore") + skillBlock("ponytail") + "plan this"));
	assert.equal(app.status, "Skills: ● explore · ● ponytail");
	await app.message(user([{ type: "text", text: skillBlock("explore") + "another task" }]));
	assert.equal(app.status, "Skills: ● explore · ○ ponytail");
	await app.message(user("show me /skill:tdd, don't invoke it"));
	assert.equal(app.status, "Skills: ○ explore · ○ ponytail");
});

test("successful skill reads appear once and become older on the next user request", async () => {
	const app = await setup();
	assert.equal(app.status, undefined);
	await app.message(user("fix the bug"));
	await app.read("/skills/tdd/SKILL.md");
	await app.read("/skills/tdd/SKILL.md");
	assert.equal(app.status, "Skills: ● tdd");
	await app.message({ role: "assistant", content: [{ type: "text", text: "Done" }] });
	assert.equal(app.status, "Skills: ● tdd");
	await app.message(user("next task"));
	assert.equal(app.status, "Skills: ○ tdd");
	await app.read("/skills/explore/SKILL.md");
	assert.equal(app.status, "Skills: ● explore · ○ tdd");
	await app.read("/skills/tdd/SKILL.md");
	assert.equal(app.status, "Skills: ● tdd · ● explore");
});
