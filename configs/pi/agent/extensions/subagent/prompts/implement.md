---
description: Full implementation workflow - fast gathers context, standard creates plan, deep implements
---
Use the subagent tool with the chain parameter to execute this workflow:

1. First, use the "fast" agent to find all code relevant to: $@
2. Then, use the "standard" agent to create an implementation plan for "$@" using the context from the previous step (use {previous} placeholder)
3. Finally, use the "deep" agent to implement the plan from the previous step (use {previous} placeholder)

Execute this as a chain, passing output between steps via {previous}.
