import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	pi.on("before_agent_start", async (event, ctx) => {
		if (event.messageType !== "user") return;
		const skill = event.prompt.match(/^<skill name="(explore|ponytail)" location="/)?.[1];
		if (!skill) return;
		const [provider, id] = skill === "explore"
			? ["anthropic", "claude-opus-5-5"]
			: ["openai-codex", "gpt-6.1-sol"];
		if (ctx.model?.provider === provider && ctx.model.id === id) return;
		const model = ctx.modelRegistry.find(provider, id);
		if (!model) {
			ctx.ui.notify(`${skill}: model ${provider}/${id} not found; keeping the current model`, "warning");
			return;
		}
		if (!(await pi.setModel(model))) {
			ctx.ui.notify(`${skill}: no credentials for ${provider}/${id}; keeping the current model`, "warning");
			return;
		}
		ctx.ui.notify(`${skill}: switched to ${provider}/${id}`, "info");
	});
}
