#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: bash scripts/install-skills.sh [--target all|claude|codex] [--dry-run]

Link every skill except TEMPLATE from this checkout into personal skill folders.
Defaults to both Claude Code and Codex. Existing unrelated entries are never replaced.

Environment overrides:
  TONY_CLAUDE_SKILLS_DIR  Default: ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills
  TONY_CODEX_SKILLS_DIR   Default: $HOME/.agents/skills

Keep this checkout in place: installed skills link to it, so git pull updates them.
EOF
}

target=all
dry_run=false
while (($#)); do
  case "$1" in
    --target)
      if (($# < 2)); then
        usage >&2
        exit 2
      fi
      target=$2
      shift 2
      ;;
    --dry-run) dry_run=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

destinations=()
case "$target" in
  all|claude|codex) ;;
  *) printf 'Invalid target: %s\n' "$target" >&2; exit 2 ;;
esac
if [[ "$target" == all || "$target" == claude ]]; then
  destinations+=("${TONY_CLAUDE_SKILLS_DIR:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills}")
fi
if [[ "$target" == all || "$target" == codex ]]; then
  destinations+=("${TONY_CODEX_SKILLS_DIR:-$HOME/.agents/skills}")
fi

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
skills=()
for source in "$repo_root"/plugins/tony/skills/*; do
  [[ -f "$source/SKILL.md" && "${source##*/}" != TEMPLATE ]] || continue
  skills+=("$source")
done
if ((${#skills[@]} == 0)); then
  printf 'No skills found in %s/plugins/tony/skills\n' "$repo_root" >&2
  exit 1
fi

# Check every destination before installing anything, including broken symlinks.
conflicts=false
for destination in "${destinations[@]}"; do
  if [[ ( -e "$destination" || -L "$destination" ) && ! -d "$destination" ]]; then
    printf 'Not a directory: %s\n' "$destination" >&2
    conflicts=true
    continue
  fi
  for source in "${skills[@]}"; do
    link="$destination/${source##*/}"
    if [[ -L "$link" && "$(readlink "$link")" == "$source" ]]; then
      continue
    fi
    if [[ -e "$link" || -L "$link" ]]; then
      printf 'Conflict: %s already exists; move it aside before retrying.\n' "$link" >&2
      conflicts=true
    fi
  done
done
if [[ "$conflicts" == true ]]; then
  printf 'Nothing installed.\n' >&2
  exit 1
fi

for destination in "${destinations[@]}"; do
  if [[ "$dry_run" == false ]]; then mkdir -p -- "$destination"; fi
  for source in "${skills[@]}"; do
    link="$destination/${source##*/}"
    if [[ -L "$link" && "$(readlink "$link")" == "$source" ]]; then
      printf 'Already installed: %s\n' "$link"
    elif [[ "$dry_run" == true ]]; then
      printf 'Would link: %s -> %s\n' "$link" "$source"
    else
      ln -s -- "$source" "$link"
      printf 'Installed: %s\n' "$link"
    fi
  done
done
