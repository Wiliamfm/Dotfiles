// Run: node --test .pi/agent/tests/skill-model-router.test.mjs
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { stripTypeScriptTypes } from "node:module";
import test from "node:test";

const claude = { provider: "anthropic", id: "claude-opus-5-5" };
const gpt = { provider: "openai-codex", id: "gpt-6.1-sol" };
const skill = (name) => `<skill name="${name}" location="/skills/${name}/SKILL.md">\nInstructions\n</skill>\n\nDo the task`;

async function session({ models = [claude, gpt], authenticated = true } = {}) {
	const source = readFileSync(new URL("../extensions/skill-model-router.ts", import.meta.url), "utf8");
	const { default: extension } = await import(`data:text/javascript;base64,${Buffer.from(stripTypeScriptTypes(source)).toString("base64")}`);
	const handlers = new Map();
	const notices = [];
	const ctx = {
		model: gpt,
		modelRegistry: { find: (provider, id) => models.find((model) => model.provider === provider && model.id === id) },
		ui: { notify: (message, level) => notices.push({ message, level }) },
	};
	extension({
		on: (name, handler) => handlers.set(name, handler),
		async setModel(model) {
			if (!authenticated) return false;
			ctx.model = model;
			return true;
		},
	});
	return {
		ctx, notices,
		async prompt(prompt, messageType = "user") {
			await handlers.get("before_agent_start")({ messageType, prompt }, ctx);
			return ctx.model;
		},
	};
}

test("explicit exploration selects Claude and keeps it for follow-ups", async () => {
	const pi = await session();
	assert.deepEqual(await pi.prompt(skill("explore")), claude);
	assert.deepEqual(await pi.prompt("tell me more"), claude);
	assert.equal(pi.notices.length, 1);
	assert.equal(pi.notices[0].level, "info");
});

test("explicit Ponytail switches from Claude to GPT and leaves manual choices alone", async () => {
	const pi = await session();
	await pi.prompt(skill("explore"));
	assert.deepEqual(await pi.prompt(skill("ponytail")), gpt);
	assert.deepEqual(await pi.prompt("continue"), gpt);
	pi.ctx.model = claude; // A manual /model selection.
	assert.deepEqual(await pi.prompt("continue"), claude);
});

test("reinvoking the active skill does not reselect the model or notify again", async () => {
	const pi = await session();
	await pi.prompt(skill("explore"));
	await pi.prompt(skill("explore"));
	assert.deepEqual(pi.ctx.model, claude);
	assert.equal(pi.notices.length, 1);
});

test("unrelated skills, quoted skill blocks, plain mentions and custom turns do not switch models", async () => {
	const pi = await session();
	for (const prompt of [skill("ponytail-review"), "use explore", `Example:\n${skill("explore")}`]) {
		assert.deepEqual(await pi.prompt(prompt), gpt);
	}
	assert.deepEqual(await pi.prompt(skill("explore"), "custom"), gpt);
	assert.deepEqual(pi.notices, []);
});

test("missing models or credentials warn and keep the current model", async () => {
	for (const options of [{ models: [gpt] }, { authenticated: false }]) {
		const pi = await session(options);
		assert.deepEqual(await pi.prompt(skill("explore")), gpt);
		assert.equal(pi.notices.length, 1);
		assert.equal(pi.notices[0].level, "warning");
	}
});
