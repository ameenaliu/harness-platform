<!--
HARNESS INTERNAL — reference document, NOT an agent.
Shared engineering principles (SOLID, DRY, YAGNI) read by the reviewer
and developer agents in the platform-sdlc-harness workflow. Intentionally has
no YAML frontmatter so Claude Code's plugin loader cannot register it
as an invokable subagent, even if a future version recurses into
agents/shared/. If you're adding principles here, add them as plain
markdown — do not reintroduce a name/description frontmatter block.
-->

# Universal Engineering Principles

These principles apply to all code, in all languages, in every task. The Developer must
follow them. The Reviewer must flag violations as blocking issues.

## SOLID

- **Single Responsibility**: each class/module/function has one reason to change
- **Open/Closed**: open for extension, closed for modification
- **Liskov Substitution**: subtypes must be substitutable for their base types
- **Interface Segregation**: no client should depend on methods it does not use
- **Dependency Inversion**: depend on abstractions, not concretions

## DRY (Don't Repeat Yourself)

- Every piece of knowledge must have a single, authoritative representation
- Extract shared logic; never copy-paste behaviour

## YAGNI (You Aren't Gonna Need It)

- Implement only what is required now
- Do not add abstractions, parameters, or generality for hypothetical future use

## Violations to flag (Reviewer)

Report each violation as: `[SOLID/DRY/YAGNI] <location> — <one-line description>`

**SOLID violations:**
- Class/module with multiple unrelated responsibilities
- Direct modification of existing classes instead of extension
- Subtype that breaks base-type contracts
- Fat interface that forces clients to implement unused methods
- High-level module importing a low-level concrete implementation directly

**DRY violations:**
- Identical or near-identical logic duplicated across two or more locations
- Copy-pasted behaviour with minor variations that could be parameterised

**YAGNI violations:**
- Abstraction with only one implementation and no concrete near-term reason for a second
- Parameters, flags, or configuration that no caller currently uses
- Generalised infrastructure built ahead of any concrete requirement
