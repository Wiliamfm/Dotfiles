/**
 * Ponytail loop: after an explicit ponytail turn, a fresh `pi` reviews
 * the change against the session's first request. `/fix 2 5`
 * then starts a new session that fixes only those findings (and gets reviewed too).
 */
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { BorderedLoader } from "@earendil-works/pi-coding-agent";

const exec = promisify(execFile);
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
		const args = [process.argv[1], "-p", "--no-session", "--no-extensions", "--tools", "read,grep,find,ls,bash"];
		if (ctx.model) args.push("--model", `${ctx.model.provider}/${ctx.model.id}`, "--thinking", pi.getThinkingLevel());
		for (const command of pi.getCommands()) {
			if (command.source === "skill" && command.sourceInfo.path) args.push("--skill", command.sourceInfo.path);
		}
		args.push(task);

		const review = async (signal?: AbortSignal) => {
			const child = exec(process.execPath, args, { cwd: ctx.cwd, signal, maxBuffer: 16 * 1024 * 1024 });
			child.child.stdin?.end(); // print mode waits for piped stdin to close
			return (await child).stdout.trim();
		};

		const report = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
			const loader = new BorderedLoader(tui, theme, "Ponytail review running...");
			loader.onAbort = () => done(null);
			review(loader.signal).then(done, (err) => {
				// err.message repeats the whole command line, including the full task
				if (!loader.signal.aborted) ctx.ui.notify(`Ponytail review failed: ${err.stderr?.trim() || err.message}`, "error");
				done(null);
			});
			return loader;
		});
		if (!report) return;

		pi.sendMessage(
			{ customType: "ponytail-review", content: `## Ponytail review\n\n${report}`, display: true, details: { request: current.request } },
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
