/**
 * Ponytail loop: after a run in a ponytail session changes files, a fresh
 * `pi` reviews that run's diff with the ponytail-review skill. `/fix 2 5`
 * then starts a new session that fixes only those findings (and gets reviewed too).
 */
import { execFile } from "node:child_process";
import { copyFileSync, existsSync, mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { promisify } from "node:util";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { BorderedLoader } from "@earendil-works/pi-coding-agent";

const exec = promisify(execFile);
const PONYTAIL_SKILL = '<skill name="ponytail" ';
const SKILL_BLOCK = /^<skill name="[^"]+" location="[^"]+">\n[\s\S]*?\n<\/skill>\n*/;
const ROOT_REQUEST = /<request>\n([\s\S]*?)\n<\/request>/;

const text = (content: unknown): string =>
	typeof content === "string"
		? content
		: Array.isArray(content)
			? content.map((c) => (c?.type === "text" ? c.text : "")).join("\n")
			: "";

/** Tree hash of the whole working tree (tracked + untracked), without touching the real index. */
async function snapshot(cwd: string): Promise<string | undefined> {
	const dir = mkdtempSync(join(tmpdir(), "ponytail-loop-"));
	const env = { ...process.env, GIT_INDEX_FILE: join(dir, "index") };
	try {
		const realIndex = resolve(cwd, (await exec("git", ["rev-parse", "--git-path", "index"], { cwd })).stdout.trim());
		// start from the real index so git only re-hashes changed files
		if (existsSync(realIndex)) copyFileSync(realIndex, env.GIT_INDEX_FILE);
		await exec("git", ["add", "-A"], { cwd, env });
		return (await exec("git", ["write-tree"], { cwd, env })).stdout.trim();
	} catch {
		return undefined; // not a git repo
	} finally {
		rmSync(dir, { recursive: true, force: true });
	}
}

function ponytailActive(ctx: ExtensionContext, prompt: string): boolean {
	if (prompt.includes(PONYTAIL_SKILL)) return true;
	return ctx.sessionManager
		.getBranch()
		.some((e) => e.type === "message" && e.message.role === "user" && text(e.message.content).includes(PONYTAIL_SKILL));
}

export default function (pi: ExtensionAPI) {
	let pending: { before: string; request: string } | undefined;

	pi.on("before_agent_start", async (event, ctx) => {
		pending = undefined;
		// print/RPC can't show the review, and Pi waits for agent_settled handlers, so it would only block
		if (ctx.mode !== "tui" || event.messageType !== "user" || !ponytailActive(ctx, event.prompt)) return;
		const before = await snapshot(ctx.cwd);
		if (before) pending = { before, request: event.prompt.replace(SKILL_BLOCK, "") };
	});

	pi.on("agent_settled", async (event, ctx) => {
		const current = pending;
		pending = undefined;
		if (!current || event.aborted) return;
		const after = await snapshot(ctx.cwd);
		if (!after || after === current.before) return;

		const task = `/skill:ponytail-review Review the change made for the request below. See the change with: git diff ${current.before} ${after}\n\n## Request\n${current.request}`;
		const args = [process.argv[1], "-p", "--no-session", "--no-extensions", "--tools", "read,grep,find,ls,bash"];
		if (ctx.model) args.push("--model", `${ctx.model.provider}/${ctx.model.id}`, "--thinking", pi.getThinkingLevel());
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

		const request = current.request.match(ROOT_REQUEST)?.[1] ?? current.request;
		pi.sendMessage(
			{ customType: "ponytail-review", content: `## Ponytail review\n\n${report}`, display: true, details: { request } },
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
