#!/usr/bin/env bash
# Create absolute symlinks from $HOME into this repo.
# Safe to re-run: existing symlinks are replaced, real files/dirs are never touched.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# repo path (relative to $DOTFILES) -> link path (relative to $HOME)
LINKS=(
	".bashrc                    .bashrc"
	".config                    .config"
	".agents                    .agents"
	".agents/AGENTS.md          .pi/agent/AGENTS.md"
	".pi/agent/settings.json    .pi/agent/settings.json"
	".pi/agent/extensions       .pi/agent/extensions"
)

for entry in "${LINKS[@]}"; do
	read -r src dest <<<"$entry"
	src="$DOTFILES/$src"
	dest="$HOME/$dest"

	if [[ ! -e "$src" ]]; then
		echo "skip  $dest (missing in repo: $src)"
	elif [[ -e "$dest" && ! -L "$dest" ]]; then
		echo "skip  $dest (real file/dir exists, move it into the repo first)"
	else
		mkdir -p "$(dirname "$dest")"
		ln -sfn "$src" "$dest"
		echo "link  $dest -> $src"
	fi
done
