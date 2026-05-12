# Research Task: How to Best Prompt Apple Foundation Models

## Goal

Exhaustively scrape Apple's Foundation Models docs and compile a practical guide for AI coding agents. Focus on: prompting techniques, best practices, anti-patterns, model limitations + workarounds, use cases, and complete code examples.

## Fetching Docs

Use WebFetch with Sosumi: replace `developer.apple.com` with `sosumi.ai`, keep the same path.
Example: `https://sosumi.ai/documentation/foundationmodels`

## Execution — Agent Delegation

### Step 1: Fetch Pages (4 Sonnet Agents in Parallel)

Each agent WebFetches its URLs, extracts all practical guidance, code examples, anti-patterns, limitations, numbers/constraints, and Note/Important/Tip callouts. Writes findings to its output file. **Follow any links to other `/documentation/foundationmodels/` pages not listed here.**

**Agent 1 → `prompt-lab/research/01-prompting.md`**
- `https://sosumi.ai/documentation/foundationmodels/prompting-an-on-device-foundation-model`
- `https://sosumi.ai/documentation/foundationmodels/updating-prompts-for-new-model-versions`
- `https://sosumi.ai/documentation/foundationmodels/evaluating-prompts-to-measure-performance`
- `https://sosumi.ai/documentation/foundationmodels/analyzing-runtime-performance`

**Agent 2 → `prompt-lab/research/02-guided-generation-tools.md`**
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

**Agent 3 → `prompt-lab/research/03-safety-locales-adapters.md`**
- `https://sosumi.ai/documentation/foundationmodels/improving-the-safety-of-generative-model-output`
- `https://sosumi.ai/documentation/foundationmodels/systemlanguagemodel/guardrails`
- `https://sosumi.ai/documentation/foundationmodels/supporting-languages-and-locales-with-foundation-models`
- `https://sosumi.ai/documentation/foundationmodels/loading-and-using-a-custom-adapter-with-foundation-models`
- `https://sosumi.ai/documentation/foundationmodels/systemlanguagemodel/adapter`
- `https://sosumi.ai/documentation/foundationmodels/categorizing-and-organizing-data-with-content-tags`
- `https://sosumi.ai/documentation/foundationmodels/systemlanguagemodel/usecase`

**Agent 4 → `prompt-lab/research/04-sessions-model-errors.md`**
- `https://sosumi.ai/documentation/foundationmodels` (overview — note any undiscovered pages)
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

### Step 2: WWDC Transcripts (1 Sonnet Agent, after Step 1)

**Agent 5 → `prompt-lab/research/05-wwdc.md`**
Fetch transcripts (skip 404s gracefully). Also fetch any WWDC links discovered by other agents.
- `https://sosumi.ai/videos/play/wwdc2025/10604`
- `https://sosumi.ai/videos/play/wwdc2025/289`
- `https://sosumi.ai/videos/play/wwdc2025/10605`
- `https://sosumi.ai/videos/play/wwdc2025/295`

### Step 3: Gap Check (1 Sonnet Agent)

Read all research files. Fetch any `/documentation/foundationmodels/` pages that were linked but not yet visited. Write to `prompt-lab/research/06-gaps.md`.

### Step 4: Synthesis (1 Opus Agent)

Read all research files (01-06). Write final guide to `prompt-lab/research/foundation-models-guide.md`. Organize by: model overview → prompting best practices & anti-patterns → limitations + workarounds → guided generation → tool calling → session management → generation options → safety → locales → adapters → testing/evaluation → error handling → complete code templates. Include every code example verbatim. Flag anything undocumented.

## Rules

1. **Nothing gets skipped.** Every technique, workaround, limitation, and code example from the docs must appear in the final output.
2. **Exact numbers.** Context window size, example counts, temperature ranges, type lists — precise values, not approximations.
3. **Complete code.** Never truncate or abbreviate examples.
4. **Preserve anti-pattern reasoning.** When Apple says "don't do X because Y", keep the why.
5. **Follow every link** under `/documentation/foundationmodels/`. No gaps.
6. **Flag what's missing.** If something important is undocumented, say so explicitly.
