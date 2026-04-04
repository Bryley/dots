---
name: write-like-me
description: Draft emails, messages, replies, and documentation in the user's natural writing style without obvious AI wording
---

# Write like Me

Use this skill only when writing on the user's behalf.

This includes:
- Emails
- Text replies
- Slack messages
- Issue comments
- Documentation wording
- Message drafts
- Git commit messages
- Rewritten phrasing meant to sound like the user wrote it

Do not use this skill for normal assistant responses unless the task is specifically to produce writing for the user to send or publish.

## Goal
Write in a way that feels natural, clear, and believable as the user's own writing.

The output should sound like the user wrote it themselves after taking a bit of time to make it good.

## Style
- Natural
- Direct
- Clear
- Thoughtful
- Human
- Lightly polished
- Believable
- Not stiff
- Not corporate
- Not overly formal unless the context requires it
- Friendly and warm when context allows

## Rules
- Do not use em-dashes.
- Use plain ASCII punctuation by default (`'` and `"`). Avoid smart quotes.
- Avoid obvious AI-smelling phrasing.
- Avoid fake warmth, fake enthusiasm, or performative politeness.
- Avoid corporate, academic, or overly polished wording unless the situation genuinely needs it.
- Preserve the original intent and meaning.
- Prefer simple strong wording over inflated wording.
- Use contractions where natural and non-formal.
- Keep the writing sounding like a real person, not an assistant or brand voice.
- For message drafts, prefer a short friendly opener (for example, "Hey team," or "Hi all,") unless the user asks for a direct start.

## Avoid
- "delve"
- "leverage"
- "robust"
- "seamless"
- "thoughtfully"
- "nuanced"
- "in order to"
- "it's worth noting"
- "moving forward"
- Generic assistant phrasing
- Templated transitions
- Em-dashes for emphasis
- Overuse of semicolons
- Unnecessary buzzwords
- Rewriting simple wording into something fancier for no reason

## Writing Philosophy
- First preserve the meaning.
- Then preserve the tone and intent.
- Then improve clarity and flow.
- If the source text is already decent, make targeted improvements instead of rewriting everything.
- Do not sand off all personality.
- Do not make the writing sound “AI polished”.

## If the User Asks to Improve Existing Writing
Prefer listing targeted edits first unless a full rewrite is explicitly requested.

## Output Separation (Important)
- Clearly separate assistant commentary from the user-sendable draft.
- Put only user-copyable text inside fenced code blocks.
- Keep labels like `Main message`, `Thread`, `Option A`, or any explanation outside code blocks.
- Never place meta text inside code blocks (for example: "Main channel message:", "Thread details:", "Copy/paste this").
- Brief assistant context is allowed outside code blocks when useful, but keep it short.
- If no context is needed, return only one or more code blocks with the drafted text.
- Do not include placeholders like "[Your Name]" unless the user explicitly asks for templates.

## By Default
- Make the output sound like the user.
- Keep it natural.
- Keep it readable.
- Keep it good enough that another person would assume the user wrote it.
