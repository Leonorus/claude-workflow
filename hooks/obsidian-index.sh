#!/bin/bash
# SessionStart hook: emit a compact index of the Obsidian vault so Claude
# knows what notes exist without reading any of them.
# Format: one line per note, "- relative/path.md [tag1, tag2]" (tags optional).
# Exits 0 silently if the vault is missing — must not break sessions.

set -u

VAULT="${HOME}/Obsidian/Work"
MAX_LINES=200

[ -d "$VAULT" ] || exit 0

# Header so the model knows what it's looking at
printf '=== Obsidian vault index (%s) ===\n' "$VAULT"
printf 'Use mcp__obsidian__obsidian_simple_search or obsidian_get_file_contents to read.\n\n'

count=0
while IFS= read -r f; do
    rel="${f#$VAULT/}"
    # Skip dotfiles and .obsidian config dir
    case "$rel" in
        .*|.obsidian/*) continue ;;
    esac

    # Extract `tags:` line from YAML frontmatter (between first two --- markers)
    tags=$(awk '
        /^---[[:space:]]*$/ { f++; if (f==2) exit; next }
        f==1 && /^tags:/ {
            sub(/^tags:[[:space:]]*/, "")
            print
            exit
        }
    ' "$f" 2>/dev/null)

    if [ -n "$tags" ]; then
        printf -- '- %s %s\n' "$rel" "$tags"
    else
        printf -- '- %s\n' "$rel"
    fi

    count=$((count + 1))
    if [ "$count" -ge "$MAX_LINES" ]; then
        printf '... (truncated at %d notes)\n' "$MAX_LINES"
        break
    fi
done < <(find "$VAULT" -type f -name '*.md' 2>/dev/null | sort)

[ "$count" -eq 0 ] && printf '(vault is empty)\n'

exit 0
