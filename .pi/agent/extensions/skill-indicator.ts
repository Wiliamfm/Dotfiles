import { realpathSync } from "node:fs";
import { homedir } from "node:os";
import { resolve } from "node:path";
import type { ExtensionAPI, ExtensionContext, MessageEndEvent } from "@earendil-works/pi-coding-agent";

/** ● loaded this request; ○ loaded earlier (history, not proof of current context or compliance). */
export default function (pi: ExtensionAPI) {
	const loaded = new Map<string, boolean>();
	const skills = new Map<string, string>();
	const reads = new Map<string, unknown>();

	function canonical(path: string, ctx: ExtensionContext) {
		path = path.replace(/^@/, "");
		const absolute = resolve(ctx.cwd, path.startsWith("~/") ? resolve(homedir(), path.slice(2)) : path);
		try {
			return realpathSync(absolute);
		} catch {
			return absolute; // Historical paths may no longer exist.
		}
	}

	function render(ctx: ExtensionContext) {
		if (ctx.mode !== "tui") return;
		const items = [...loaded]
			.sort(([, a], [, b]) => Number(b) - Number(a))
			.map(([name, fresh]) => ctx.ui.theme.fg(fresh ? "accent" : "dim", `${fresh ? "●" : "○"} ${name}`));
		ctx.ui.setStatus("skill-indicator", items.length ? `Skills: ${items.join(" · ")}` : undefined);
	}

	function recordRead(path: unknown, ctx: ExtensionContext) {
		if (typeof path !== "string") return;
		const name = skills.get(canonical(path, ctx));
		if (name) loaded.set(name, true);
	}

	function observe(message: MessageEndEvent["message"], ctx: ExtensionContext) {
		if (message.role === "user") {
			for (const name of loaded.keys()) loaded.set(name, false);
			let prompt = typeof message.content === "string"
				? message.content
				: message.content.filter((part) => part.type === "text").map((part) => part.text).join("\n");
			let match: RegExpMatchArray | null;
			while ((match = prompt.match(/^<skill name="([^"]+)" location="[^"]+">\n[\s\S]*?\n<\/skill>\n*/))) {
				loaded.set(match[1], true);
				prompt = prompt.slice(match[0].length);
			}
		} else if (message.role === "assistant") {
			for (const part of message.content) {
				if (part.type === "toolCall" && part.name === "read") reads.set(part.id, part.arguments.path);
			}
		} else if (message.role === "toolResult") {
			if (!message.isError && message.toolName === "read") recordRead(reads.get(message.toolCallId), ctx);
			reads.delete(message.toolCallId);
			for (const call of message.nestedCalls?.calls ?? []) {
				if (call.name === "read" && call.status === "ok") recordRead(call.arguments?.path, ctx);
			}
		}
	}

	function restore(ctx: ExtensionContext) {
		loaded.clear();
		reads.clear();
		skills.clear();
		for (const command of pi.getCommands()) {
			if (command.source === "skill") skills.set(canonical(command.sourceInfo.path, ctx), command.name.slice(6));
		}
		for (const entry of ctx.sessionManager.getBranch()) {
			if (entry.type === "message") observe(entry.message, ctx);
		}
		render(ctx);
	}

	pi.on("session_start", (_event, ctx) => restore(ctx));
	pi.on("session_tree", (_event, ctx) => restore(ctx));
	pi.on("message_end", (event, ctx) => {
		observe(event.message, ctx);
		render(ctx);
	});
	// shortcut: Shell/custom readers are not inferred; add adapters if they become skill loaders.
	pi.on("tool_result", (event, ctx) => {
		if (event.toolName !== "read" || event.isError) return;
		recordRead(event.input.path, ctx);
		render(ctx);
	});
}
