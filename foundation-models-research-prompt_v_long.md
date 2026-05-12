# Research Task: How to Best Prompt Apple Foundation Models

## Objective

Research Apple's Foundation Models documentation exhaustively and compile a practical guide focused on **how to write effective prompts, work around model limitations, and get the best results** from the on-device foundation model. The final document will be used as a reference for AI coding agents (Claude Code) writing Foundation Models code.

This is NOT an API reference scrape. Focus on the **practical knowledge**: what works, what doesn't, why, and what to do about it.

## How to Fetch Documentation

Use the Sosumi service via WebFetch to fetch Apple documentation as Markdown. Replace `developer.apple.com` with `sosumi.ai` and keep the same path. Example: `https://sosumi.ai/documentation/foundationmodels`

## Execution Plan — Agent Delegation

Delegate work to parallel agents. Use **sonnet** for straightforward page fetching and extraction. Use **opus** for synthesis, analysis, and writing the final document.

### Step 1: Parallel Page Fetching (Sonnet Agents)

Launch **4 sonnet agents in parallel**, each responsible for a group of pages. Each agent should WebFetch every URL in its group, extract all practical guidance, code examples, anti-patterns, limitations, numbers/constraints, and "Note"/"Important"/"Tip" callouts. Each agent writes its raw findings to a file.

**Agent 1 — Prompting & Evaluation** → writes to `prompt-lab/research/01-prompting.md`
- `https://sosumi.ai/documentation/foundationmodels/prompting-an-on-device-foundation-model`
- `https://sosumi.ai/documentation/foundationmodels/updating-prompts-for-new-model-versions`
- `https://sosumi.ai/documentation/foundationmodels/evaluating-prompts-to-measure-performance`
- `https://sosumi.ai/documentation/foundationmodels/analyzing-runtime-performance`

**Agent 2 — Guided Generation & Tool Calling** → writes to `prompt-lab/research/02-guided-generation-tools.md`
- `https://sosumi.ai/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation`
- `https://sosumi.ai/documentation/foundationmodels/expanding-generation-with-tool-calling`
- `https://sosumi.ai/documentation/foundationmodels/generate-dynamic-game-content-with-guided-generation-and-tools`
- `https://sosumi.ai/documentation/foundationmodels/generable()`
- `https://sosumi.ai/documentation/foundationmodels/guide(_:)`
- `https://sosumi.ai/documentation/foundationmodels/generationguide`
- `https://sosumi.ai/documentation/foundationmodels/tool`
- `https://sosumi.ai/documentation/foundationmodels/generatedcontent`
- `https://sosumi.ai/documentation/foundationmodels/partiallygenerated`
- `https://sosumi.ai/documentation/foundationmodels/dynamicgenerationschema`

**Agent 3 — Safety, Locales, Adapters, Use Cases** → writes to `prompt-lab/research/03-safety-locales-adapters.md`
- `https://sosumi.ai/documentation/foundationmodels/improving-the-safety-of-generative-model-output`
- `https://sosumi.ai/documentation/foundationmodels/systemlanguagemodel/guardrails`
- `https://sosumi.ai/documentation/foundationmodels/supporting-languages-and-locales-with-foundation-models`
- `https://sosumi.ai/documentation/foundationmodels/loading-and-using-a-custom-adapter-with-foundation-models`
- `https://sosumi.ai/documentation/foundationmodels/systemlanguagemodel/adapter`
- `https://sosumi.ai/documentation/foundationmodels/categorizing-and-organizing-data-with-content-tags`
- `https://sosumi.ai/documentation/foundationmodels/systemlanguagemodel/usecase`

**Agent 4 — Sessions, Options, Model, Errors, Sample App** → writes to `prompt-lab/research/04-sessions-model-errors.md`
- `https://sosumi.ai/documentation/foundationmodels` (framework overview — also discover any pages NOT listed elsewhere; note them at the top of the output file)
- `https://sosumi.ai/documentation/foundationmodels/adding-intelligent-app-features-with-generative-models`
- `https://sosumi.ai/documentation/foundationmodels/systemlanguagemodel`
- `https://sosumi.ai/documentation/foundationmodels/languagemodelsession`
- `https://sosumi.ai/documentation/foundationmodels/generationoptions`
- `https://sosumi.ai/documentation/foundationmodels/instructions`
- `https://sosumi.ai/documentation/foundationmodels/transcript`
- `https://sosumi.ai/documentation/foundationmodels/prompt`
- `https://sosumi.ai/documentation/foundationmodels/languagemodelsession/generationerror`
- `https://sosumi.ai/documentation/foundationmodels/languagemodelfeedback`
- `https://sosumi.ai/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum`

### Step 2: WWDC Transcripts (1 Sonnet Agent)

Launch **1 sonnet agent** to fetch WWDC session transcripts. Skip gracefully if a URL returns 404.

**Agent 5 — WWDC Sessions** → writes to `prompt-lab/research/05-wwdc-transcripts.md`
- `https://sosumi.ai/videos/play/wwdc2025/10604`
- `https://sosumi.ai/videos/play/wwdc2025/289`
- `https://sosumi.ai/videos/play/wwdc2025/10605`
- `https://sosumi.ai/videos/play/wwdc2025/295`
- Follow any WWDC session links discovered by Agent 4 on the documentation pages.

Run Step 2 after Step 1 completes (Agent 5 may need discovered links from Agent 4).

### Step 3: Gap Check (1 Sonnet Agent)

Launch **1 sonnet agent** that reads all 5 research files, then:
1. Checks Agent 4's output for any discovered pages that weren't fetched by other agents — fetch those
2. Checks if any page referenced links to other `/documentation/foundationmodels/` pages that weren't visited — fetch those
3. Writes any additional findings to `prompt-lab/research/06-gaps.md`

### Step 4: Synthesis (1 Opus Agent)

Launch **1 opus agent** that reads ALL research files (`prompt-lab/research/01-06`) and compiles the final document at `prompt-lab/research/foundation-models-guide.md`.

The opus agent should be given the output structure below and the extraction rules.

## Extraction Rules (For Fetching Agents)

For every page, extract:

1. **Practical guidance** — what to do, how to do it, recommended patterns
2. **Anti-patterns** — what NOT to do, with Apple's explanation of why it fails
3. **Limitations** — what the on-device model can't do well, and the documented workarounds
4. **Numbers and constraints** — context window size, token limits, supported types, locale lists, recommended example counts
5. **Code examples that demonstrate a technique** — complete, copy-pasteable, with the technique they illustrate
6. **"Note"/"Important"/"Tip" callouts** — these often contain the most critical practical knowledge
7. **Behavioral details** — how the model decides things (when it calls tools, how property order affects output, how sampling modes change behavior)

Do NOT spend space on: import statements, boilerplate availability annotations, or information purely about Xcode setup.

## Output Structure (For Synthesis Agent)

### 1. The On-Device Model: What You're Working With
- What it is, where it runs, what makes it different from cloud models
- Context window size (exact number if documented, or "not documented" if not)
- Supported languages and locales (complete list)
- Availability checking and handling unavailability
- UseCase options (.general vs .contentTagging) and when to pick each

### 2. Prompting Best Practices
This is the core section. Be maximally thorough.

**Writing effective prompts:**
- Keep prompts simple and concise (1-3 paragraphs max) — the model is smaller than cloud models
- Use direct imperative verbs ("List", "Create", not passive voice)
- Conversational tone with simple sentences
- Avoid jargon, hedging, unnecessary politeness

**Role and persona assignment:**
- "You are [role]" pattern with examples
- Defining both the model's role and the user's persona
- How tone in the prompt affects tone in the output

**Few-shot prompting:**
- Apple's recommended number of examples
- Keep examples minimal and simple
- How few-shot works with guided generation
- What happens when examples are too complex

**Reducing the reasoning burden:**
- The model has limited reasoning — don't ask it to figure out complex approaches
- Provide step-by-step plans instead
- Break complex tasks into multiple LanguageModelSession instances (one task per session)
- Accept the latency tradeoff of multiple requests

**Replacing prompt conditionals with Swift code:**
- Don't embed if/else logic in prompts
- Use Swift switch statements to build different instruction strings
- This reduces context window usage and improves reliability

**The reasoningSteps workaround:**
- Add a dedicated `reasoningSteps: String` property to @Generable types
- Declare it FIRST so the model reasons before answering
- Use @Guide on the answer field to specify "answer only"
- Why: prevents reasoning text from contaminating structured output

**Iteration and refinement:**
- Refine wording for directness
- Add emphasis ("must", "should", "do not", "avoid")
- Repeat key instructions at the end of the prompt
- Test after each change

**Anti-patterns (things that DON'T work):**
- Combining multiple unrelated requests in one prompt
- Long, complex prompts with nested conditionals
- Expecting multi-step reasoning
- Passive voice and indirect instructions
- Unnecessary politeness or hedging
- Complex few-shot examples (model copies/hallucinates details)
- Unreliable prompts that break with slight condition changes

### 3. Guided Generation: Getting Structured Output
- When to use guided generation vs plain text
- @Generable: what types it supports (complete list), nesting, enums
- @Guide: all constraint types with examples (.range, .anyOf, .count, .pattern, .minimum, .maximum, .minimumCount, .maximumCount, .constant, .element)
- Property declaration order determines generation order — put reasoning fields first, answer fields last
- Description best practices: keep them concise (long descriptions increase latency and eat context)
- Optional properties and nil handling (representNilExplicitlyInGeneratedContent)
- Streaming with PartiallyGenerated for responsive UIs
- DynamicGenerationSchema when the structure isn't known at compile time
- includeSchemaInPrompt: when to pass true vs false

### 4. Tool Calling: Extending the Model
- When to use tools (dynamic data, external APIs, grounding in authoritative sources)
- Tool protocol implementation pattern (complete template)
- Writing effective tool names and descriptions
- The model decides autonomously whether to call tools — but explicit instructions encourage it
- @Generable for tool Arguments and Output types
- Combining tools with guided generation
- Tool call flow through the transcript
- includesSchemaInInstructions flag

### 5. Session Management Patterns
- Instructions (system-level) vs Prompt (user-level): what goes where
- Multi-turn conversations with Transcript
- Resuming sessions from a transcript
- Using multiple sessions for complex workflows (one focused task per session)
- prewarm(promptPrefix:) for faster first response

### 6. Generation Options: Tuning Output
- Temperature: what it controls, useful ranges
- Sampling modes:
  - .greedy — deterministic, same input = same output, good for consistent recommendations
  - .random(probabilityThreshold:seed:) — nucleus sampling
  - .random(top:seed:) — top-k sampling
- maximumResponseTokens: controlling output length
- When to use each sampling mode

### 7. Safety & Guardrails
- .default guardrails: standard safety, use for most cases
- .permissiveContentTransformations: relaxed filtering for content transformation tasks
- When to use each level
- Handling guardrail violations gracefully

### 8. Dealing with Model Limitations
Compile every limitation mentioned across all pages with its workaround:
- Small context window → concise prompts, Swift-side conditionals, multiple sessions
- Limited reasoning → provide step-by-step plans, reasoningSteps field pattern
- Inconsistent instruction following → emphasis words, repetition, iteration
- Hallucination in few-shot → keep examples minimal
- Complex conditional logic → move to Swift code
- Performance/latency → prewarm, greedy sampling, concise @Guide descriptions
- Guardrail false positives → .permissiveContentTransformations for content transforms
- Any other limitations discovered during research

### 9. Working with Multiple Languages
- Supported locales (complete list)
- Language-specific @Generable types pattern (separate types with @Guide descriptions in each language)
- Handling unsupported locale errors

### 10. Custom Adapters
- What they are and when to use them
- Loading, compiling, compatibility checking
- Entitlement requirements

### 11. Testing & Evaluating Prompts
- Apple's recommended evaluation workflow
- Updating prompts when Apple ships new model versions
- Feedback API for reporting issues to Apple

### 12. Error Handling Patterns
- Every GenerationError case, what triggers it, and the recommended response
- Graceful degradation when the model is unavailable

### 13. Complete Code Templates
Collect the best code examples from across all pages, organized by use case:
- Basic text generation
- Structured output with @Generable
- Streaming structured output
- Few-shot prompting
- Role assignment
- Tool calling
- Multi-session workflow
- Content tagging
- Availability checking with fallback
- Prewarm + generate
- ReasoningSteps pattern
- Swift-side conditional instructions

## Critical Rules

1. **Be exhaustive.** If Apple documents a technique, workaround, or limitation — it must be in the output. This document will be the SOLE reference for an AI coding agent.

2. **Capture exact numbers.** Context window size, recommended example counts, temperature ranges, supported type lists — include the precise values, not approximations.

3. **Include complete code examples.** Don't truncate or abbreviate. Every code example should be copy-pasteable.

4. **Preserve Apple's specific wording for anti-patterns.** When Apple says "don't do X because Y", keep the exact reasoning.

5. **Follow every link.** If a page links to another page under `/documentation/foundationmodels/`, fetch it. If it links to a WWDC session, fetch the transcript. Don't leave gaps.

6. **Flag what's NOT documented.** If something important seems undocumented (e.g., exact context window token count, complete locale list), say so explicitly.

7. **Prioritize practical knowledge over API boilerplate.** Method signatures matter only when they reveal constraints or behavior.
