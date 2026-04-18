#!/usr/bin/env sh
# UserPromptSubmit hook: reminds the model to route every task through
# classify-task before responding. Without this, CLAUDE.md's "first move on any
# task" instruction gets ignored in practice (evidenced: 1/1318 invocations
# in history before this hook).
#
# Stdout is injected into the conversation context. Silent follow-up
# clarifications are trusted to Claude's own judgement — the reminder says so.

cat <<'EOF'
<system-reminder>
First move on this task: invoke the `classify-task` skill and state the bucket out loud, then apply the matching weight. Per `CLAUDE.md` ("First move on any task"). Skip only if this message is a clear follow-up to an already-classified task earlier in this conversation.
</system-reminder>
EOF
