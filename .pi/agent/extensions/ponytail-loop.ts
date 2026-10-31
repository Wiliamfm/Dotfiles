/**
 * Ponytail loop: after an explicit ponytail turn, a fresh `pi` reviews
 * the change against the session's first request. `/fix 2 5`
 * then starts a new session that fixes only those findings (and gets reviewed too).
 */
import { spawn } from "node:child_process";
import { realpathSync } from "node:fs";
import { homedir } from "node:os";
import { resolve } from "node:path";
import type { ExtensionAPI, JsonAgentSessionEvent } from "@earendil-works/pi-coding-agent";
import { BorderedLoader } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";

const PONYTAIL_SKILL = '<skill name="ponytail" ';
const SKILL_BLOCK = /^(?:<skill name="[^"]+" location="[^"]+">\n[\s\S]*?\n<\/skill>\n*)+/;
const ROOT_REQUEST = /<request>\n([\s\S]*?)\n<\/request>/;

const text = (content: unknown): string =>
	typeof content === "string"
		? content
		: Array.isArray(content)
			? content.map((c) => (c?.type === "text" ? c.text : "")).join("\n")
			: "";

export default function (pi: ExtensionAPI) {
	let pending: { request: string } | undefined;

	pi.on("before_agent_start", async (event, ctx) => {
		pending = undefined;
		// print/RPC can't show the review, and Pi waits for agent_settled handlers, so it would only block
		if (ctx.mode !== "tui" || event.messageType !== "user" || !event.prompt.startsWith(PONYTAIL_SKILL)) return;
		const first = ctx.sessionManager.getBranch().find((e) => e.type === "message" && e.message.role === "user");
		const request = (first?.type === "message" ? text(first.message.content) : event.prompt).replace(SKILL_BLOCK, "");
		pending = { request: request.match(ROOT_REQUEST)?.[1] ?? request };
	});

	pi.on("agent_settled", async (event, ctx) => {
		const current = pending;
		pending = undefined;
		if (!current || event.aborted) return;

		const task = `/skill:ponytail-review Review the change made for the request below. Apply other available skills where relevant to the review. Report only; do not modify files.\n\n## Request\n${current.request}`;
		const args = [process.argv[1], "--mode", "json", "-p", "--no-session", "--no-extensions", "--tools", "read,grep,find,ls,bash"];
		if (ctx.model) args.push("--model", `${ctx.model.provider}/${ctx.model.id}`, "--thinking", pi.getThinkingLevel());
		const canonical = (path: string) => {
			path = path.replace(/^@/, "");
			const absolute = resolve(ctx.cwd, path.startsWith("~/") ? resolve(homedir(), path.slice(2)) : path);
			try {
				return realpathSync(absolute);
			} catch {
				return absolute;
			}
		};
		const skills = new Map<string, string>();
		for (const command of pi.getCommands()) {
			if (command.source === "skill" && command.sourceInfo.path) {
				args.push("--skill", command.sourceInfo.path);
				skills.set(canonical(command.sourceInfo.path), command.name.slice(6));
			}
		}
		args.push(task);

		const loaded = new Set<string>();
		const skillLabel = () => `Skills loaded: ${[...loaded].join(" · ") || "none"}`;
		const review = (onUpdate: () => void, signal?: AbortSignal) => {
			let buffer = "";
			let report = "";
			let failure: string | undefined;
			let streamError: unknown;
			const reads = new Map<string, string>();
			const processLine = (line: string) => {
				if (!line.trim() || signal?.aborted) return;
				const event = JSON.parse(line) as JsonAgentSessionEvent;
				if (event.type === "tool_execution_start" && event.toolName === "read" && typeof event.args?.path === "string") {
					reads.set(event.toolCallId, event.args.path);
				} else if (event.type === "tool_execution_end") {
					const path = reads.get(event.toolCallId);
					reads.delete(event.toolCallId);
					const name = path && !event.isError ? skills.get(canonical(path)) : undefined;
					if (name && !loaded.has(name)) {
						loaded.add(name);
						onUpdate();
					}
				}
				// shortcut: Shell/custom readers are not inferred; add adapters if they become skill loaders.
				if (event.type !== "message_end") return;
				if (event.message.role === "user") {
					let prompt = text(event.message.content);
					let match: RegExpMatchArray | null;
					while ((match = prompt.match(/^<skill name="([^"]+)" location="[^"]+">\n[\s\S]*?\n<\/skill>\n*/))) {
						loaded.add(match[1]);
						prompt = prompt.slice(match[0].length);
					}
					onUpdate();
				} else if (event.message.role === "assistant") {
					report = text(event.message.content).trim();
					const reason = event.message.stopReason;
					failure = reason === "error" || reason === "aborted" || reason === "length"
						? event.message.errorMessage || `Reviewer stopped: ${reason}`
						: undefined;
				}
			};
			return new Promise<string>((resolve, reject) => {
				const child = spawn(process.execPath, args, { cwd: ctx.cwd, signal, stdio: ["ignore", "pipe", "pipe"] });
				let stderr = "";
				child.stderr.setEncoding("utf8").on("data", (chunk: string) => { stderr = (stderr + chunk).slice(-16 * 1024); });
				child.stdout.setEncoding("utf8").on("data", (chunk: string) => {
					buffer += chunk;
					const lines = buffer.split("\n");
					buffer = lines.pop()!;
					try {
						for (const line of lines) processLine(line);
					} catch (err) {
						streamError = err;
					}
				});
				child.on("error", reject);
				child.on("close", (code) => {
					try {
						if (code !== 0) throw new Error(stderr.trim() || `Review process exited with code ${code}`);
						if (streamError) throw streamError;
						processLine(buffer);
						if (failure) throw new Error(failure);
						resolve(report);
					} catch (err) {
						reject(err);
					}
				});
			});
		};

		const report = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
			const loader = new BorderedLoader(tui, theme, "Ponytail review running...");
			const skills = new Text(skillLabel(), 1, 0);
			loader.addChild(skills);
			loader.onAbort = () => done(null);
			review(() => {
				skills.setText(skillLabel());
				tui.requestRender();
			}, loader.signal).then(done, (err) => {
				// err.message repeats the whole command line, including the full task
				if (!loader.signal.aborted) ctx.ui.notify(`Ponytail review failed: ${err.stderr?.trim() || err.message}`, "error");
				done(null);
			});
			return loader;
		});
		if (!report) return;

		pi.sendMessage(
			{ customType: "ponytail-review", content: `## Ponytail review\n\n${skillLabel()}\n\n${report}`, display: true, details: { request: current.request } },
			{ triggerTurn: false },
		);
	});

	pi.registerCommand("fix", {
		description: "Fix findings of the last ponytail review in a fresh session, e.g. /fix 2 5",
		handler: async (args, ctx) => {
			const picks = args.trim();
			if (!picks) return ctx.ui.notify("Usage: /fix <finding numbers>, e.g. /fix 2 5", "error");
			const last = ctx.sessionManager
				.getBranch()
				.findLast((e) => e.type === "custom_message" && e.customType === "ponytail-review");
			if (last?.type !== "custom_message") return ctx.ui.notify("No ponytail review in this session", "error");

			const { request } = last.details as { request: string };
			const prompt = [
				`/skill:ponytail Fix findings ${picks} from the review below. Fix only those and leave everything else as is.`,
				"Respect `shortcut:` comments unless a finding is about them.",
				"",
				"## Original request",
				`<request>\n${request}\n</request>`,
				"",
				text(last.content),
			].join("\n");

			await ctx.newSession({
				parentSession: ctx.sessionManager.getSessionFile(),
				withSession: async (next) => {
					await next.sendUserMessage(prompt, { expandPromptTemplates: true });
				},
			});
		},
	});
}
