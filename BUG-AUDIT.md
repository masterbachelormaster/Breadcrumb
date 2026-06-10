# Breadcrumb Bug Audit — Working Document

**Generated:** 2026-06-10 · **Method:** multi-agent review swarm — 12 specialized finder agents (concurrency, SwiftData, timer logic, SwiftUI state, localization, AI system, window lifecycle, notifications/permissions, dead code, UI views, documents/keychain, test quality), deduplication pass, then per-finding adversarial verification. 136 raw findings deduplicated to 95 unique issues.

**Baseline at audit time (commit 912a6aa + 2 uncommitted changes):** `xcodebuild` builds clean; all **204 tests in 16 suites pass**. Every issue below is therefore NOT covered by the existing test suite.

## How to use this document (instructions for the implementing agent)

1. Work top-down: **High → Medium → Low → Cleanup**. Within a tier, prefer ✅-verified items first.
2. Items marked **⚠️ UNVERIFIED** were found by a reviewer that read the code, but the adversarial verification pass ran out of session quota before checking them. **Re-verify each one against the current code before fixing** — treat the description as a strong hypothesis, not established fact. A few may turn out to be wrong or already fixed; if so, cross them off with a note instead of "fixing" them.
3. When an item is done: change `- [ ]` to `- [x]` and append a line `**Resolution:** <commit hash> — <one sentence>`. If you decide NOT to fix something, mark `- [x]` with `**Resolution:** wontfix — <reason>`. Never delete entries; this document is the audit trail.
4. Project rules apply to every fix: all UI text through `Strings` enum (both languages); `saveWithLogging()` not `save()`; no `DispatchQueue`; `@Observable` patterns; never rename SwiftData model properties without a new schema version + migration stage; run `xcodegen generate` after adding/removing files; build + run the full test suite after each batch of fixes.
5. Several findings share a root cause (they are cross-referenced). Read the whole file section before fixing piecemeal.

## Summary

| Severity | Count | Verified | Unverified |
|---|---|---|---|
| High | 2 | 2 | 0 |
| Medium | 30 | 11 | 19 |
| Low | 38 | 6 | 32 |
| Cleanup / Dead Code | 25 | 6 | 19 |
| **Total** | **95** | **25** | **70** |

## Already taken care of (crossed off)

- [x] **Keychain prompts on every rebuild** — root-caused to a runtime keychain bug in `KeychainHelper`; fixed in commit `f0a27f7` (data protection keychain, access gated by bundle id). Watch for regression only.
- [x] **Right-click menu on the menu bar icon does nothing on macOS 27** — macOS 27 no longer delivers right-clicks to status items at all (even native `NSStatusItem.menu` is left-click-only). Worked around in commit `b757873` via the in-popover ⋯ overflow menu. The now-dead `AppDelegate` right-click code still needs REMOVAL — that is open item in the Cleanup section below.
- [x] **Duplicate end-of-work banners** — addressed in commit `add90fa` (cancel scheduled banners when timer crosses zero). Note: related but *different* notification races are still open below.

---

## High

### BC-001 — Wake-notification tick re-entry after break end corrupts pendingSessionEnd (.breakDone flips to .workDone) and can duplicate session records

- [ ] **high** · `Breadcrumb/PomodoroTimer.swift:302` · found by: timer-logic, concurrency · ✅ Verified real (high confidence)

**Problem:** When a break (or FocusMate session) expires, tick() sets currentPhase = .sessionEnded and cancels timerTask, but never clears phaseStartDate. The NSWorkspace.didWakeNotification observer (line 66-74) calls tick() directly. If the Mac sleeps and wakes while the break-done prompt is still pending, tick() passes the `guard let start = phaseStartDate` check, recomputes remainingSeconds = 0, and re-enters the expiry branch. At that point currentPhase is already .sessionEnded, so `wasBreak` evaluates to false and pendingSessionEnd is overwritten from .breakDone to .workDone, and playWorkDoneFeedback fires again (spurious sound). The open session-end UI (wasBreak: reason == .breakDone in PomodoroSessionEndHostView) switches from the break-end buttons to the work-end save form; if the user saves, a duplicate PomodoroSession is recorded for a work session that was already saved before the break started, and startBreak() runs a second break. For FocusMate the reason stays .focusMateDone but the completion sound replays on every wake.

**Hypothesis:** The session-end branch of tick() cancels the timer task but forgets to clear phaseStartDate, and tick() has no guard against running while the phase is already .sessionEnded, so the wake-notification path re-executes the one-shot expiry transition.

**Proposed fix:** In tick()'s expiry else-branch (lines 300-312), set phaseStartDate = nil after cancelling timerTask, or add `guard currentPhase != .sessionEnded` (equivalently `guard isRunning`) at the top of tick(). Either change makes the expiry transition fire exactly once.

**Verifier refinement:** Both proposed options work; prefer setting phaseStartDate = nil in the expiry else-branch (next to timerTask cancellation) since it also stops any other stray tick() path. Note `guard isRunning` is also safe: overtime keeps isRunning true, and requestStop()/pause() already nil out phaseStartDate so the .stopped path is unaffected.

**Evidence:**
```
let wasBreak = currentPhase == .shortBreak || currentPhase == .longBreak
currentPhase = .sessionEnded
pendingSessionEnd = wasBreak ? .breakDone : (isFocusMateSession ? .focusMateDone : .workDone)
```

**Verifier notes:** Confirmed by trace. tick() guards only on phaseStartDate (PomodoroTimer.swift:281); the break/FocusMate expiry branch (299-312) cancels timerTask but leaves phaseStartDate set, and the didWakeNotification observer (66-74) calls tick() directly. On re-entry currentPhase is .sessionEnded so wasBreak is false and pendingSessionEnd is overwritten .breakDone -> .workDone with a spurious playWorkDoneFeedback; PomodoroSessionEndHostView.swift:13 keys the UI variant on reason == .breakDone, so the form switches to the work-end save variant and saveWorkSession() can record a duplicate PomodoroSession.

### BC-002 — Stop button leads to 'Save & Break' which starts a break — no way to save a status AND stop; .stopped reason is never differentiated

- [ ] **high** · `Breadcrumb/Views/PomodoroSessionEndHostView.swift:42` · found by: timer-logic · ✅ Verified real (high confidence)

**Problem:** Pressing the red Stop button during a work session calls requestStop() which sets pendingSessionEnd = .stopped, and the session-end form appears. But PomodoroSessionEndView never receives the reason — workEndContent renders identically for .workDone and .stopped. Mid-cycle (isCycleComplete == false) the primary button is 'Save & Break' (PomodoroSessionEndView.swift:200), and handleSaveWorkSession unconditionally calls timer.startBreak(): a user who pressed Stop, typed a status note, and hit the primary button is put into a 5-minute break instead of stopping. Worse, during a break the only control in PomodoroRunningView is 'Skip' (which starts the NEXT work session), so the only exits are 'Stop without saving' (discards the typed status entry) or riding out the break. There is no save-status-and-stop path after pressing Stop mid-cycle.

**Hypothesis:** PomodoroSessionEndHostView discards the SessionEndReason when building the child view (only `wasBreak: reason == .breakDone` is passed), so the save handler cannot distinguish a natural work-phase expiry from an explicit user stop and always continues the cycle.

**Proposed fix:** Pass the reason (or a `wasStopped: reason == .stopped` flag) into PomodoroSessionEndView. When stopped, make the primary button 'Save & Stop' (Strings.Pomodoro.saveAndStop already exists) and have handleSaveWorkSession call timer.stop() + onFinished() instead of startBreak(). Optionally also add a Stop control to the break phase in PomodoroRunningView.

**Verifier refinement:** In PomodoroSessionEndHostView.body, the reason is already in scope: pass wasStopped: reason == .stopped into PomodoroSessionEndView and also branch on it in handleSaveWorkSession (e.g. capture it in the onSaveWorkSession closure like onStopCompletely already does) so that when stopped it calls timer.stop() + onFinished() instead of startBreak(). In PomodoroSessionEndView, primaryWorkEndButtonTitle/Help should use Strings.Pomodoro.saveAndStop when isCycleComplete || wasStopped (the string already exists at Strings.swift:220).

**Evidence:**
```
if timer.isCycleComplete {
    timer.stop()
    onFinished()
} else {
    timer.startBreak()
```

**Verifier notes:** PomodoroSessionEndHostView.swift:13 passes only wasBreak (reason == .breakDone), discarding .stopped; workEndContent renders identically for .workDone and .stopped with mid-cycle primary 'Save & Break' (PomodoroSessionEndView.swift:200), and handleSaveWorkSession (host view:38-43) unconditionally calls timer.startBreak() when !isCycleComplete. The .stopped reason always routes to this overlay (PomodoroRunningView.swift:89; ContentView.swift:132 and MenuBarLabelView.swift:43 exclude .stopped from the window path), and during the resulting break the only control is Skip which starts the NEXT work session (PomodoroRunningView.swift:74-76, 143-151), so there is no save-status-and-stop path. Minor correction to the report: 'Stop without saving' does persist a PomodoroSession record via saveCurrentWorkSession — it only discards the typed status text.

---

## Medium

### BC-003 — Stale notification actions mutate the timer from any state — no phase validation and delivered banners are never removed

- [ ] **medium** · `Breadcrumb/AppDelegate.swift:88` · found by: concurrency · ✅ Verified real (high confidence)

**Problem:** The .pomodoroStartBreak and .pomodoroNextSession observers call pomodoroTimer.startBreak() / startNextWorkSession() unconditionally. Delivered banners are never removed (no removeDeliveredNotifications/removeAllDeliveredNotifications call exists anywhere in the codebase; cancelScheduledBanners only removes pending requests), so a break-done banner sits in Notification Center indefinitely. Clicking its 'Next session' action hours later — after the user already stopped the timer or while a new work session is mid-flight — calls startNextWorkSession(), which passes its only guard (`!isCycleComplete`, true for the post-stop defaults 1 of 4), increments currentSessionNumber, and (re)starts a work session out of nowhere; .pomodoroStartBreak similarly starts a break from idle. NotificationService.handleActionIdentifier (line 295) forwards blindly with no state check either.

**Hypothesis:** The action handlers assume they only fire in the instant the banner is presented; nobody validated that notification actions can arrive arbitrarily late relative to the timer state machine.

**Proposed fix:** In AppDelegate's observers (or in PomodoroTimer), guard the action against the expected state: only honor .pomodoroNextSession/.pomodoroStartBreak when `pomodoroTimer.pendingSessionEnd == .breakDone` / `.workDone` respectively. Additionally call notificationCenter.removeAllDeliveredNotifications (add it to the UserNotificationCenterClient protocol) inside cancelScheduledBanners() so acted-upon prompts cannot linger.

**Verifier refinement:** Guard the .pomodoroNextSession observer (or startNextWorkSession itself) with pomodoroTimer.pendingSessionEnd == .breakDone, which tick() sets when a break legitimately ends. Add removeAllDeliveredNotifications (or removeDeliveredNotifications(withIdentifiers: Banner.allIdentifiers)) to the UserNotificationCenterClient protocol and call it in cancelScheduledBanners(). Separately, delete the unreachable 'breadcrumb.action.startBreak' case and the .pomodoroStartBreak observer/Notification.Name, since that action is never registered in any UNNotificationCategory.

**Evidence:**
```
MainActor.assumeIsolated {
    self?.pomodoroTimer?.startBreak()
}
```

**Verifier notes:** Confirmed for the nextSession path: AppDelegate.swift:93-101 calls startNextWorkSession() unconditionally; grep shows no removeDeliveredNotifications/removeAllDeliveredNotifications anywhere, and cancelScheduledBanners (NotificationService.swift:140-142) only removes pending requests, so a delivered break-done banner (category with 'Next session' action, NotificationService.swift:171-175) lingers and, clicked after stop(), passes the !isCycleComplete guard (PomodoroTimer.swift:192, post-stop defaults 1<4) and starts a work session from idle. However the .pomodoroStartBreak half is overstated: 'breadcrumb.action.startBreak' (NotificationService.swift:301) is never registered as a UNNotificationAction in any category, so no banner can trigger startBreak — that handler chain is dead code, not an exploitable path.

### BC-004 — Wrap-up buffer >= remaining FocusMate time starts a 0:00 session that instantly 'completes' — no validation anywhere

- [ ] **medium** · `Breadcrumb/PomodoroTimer.swift:138` · found by: timer-logic · ✅ Verified real (high confidence)

**Problem:** startFocusMate computes remaining = max(0, Int(endTime - now) - offsetSeconds). Settings allow a buffer up to 10:50 (SettingsView.swift:114-124), and the start-time grid allows joining a session whose remaining time is only a few minutes (e.g. a boundary 45 minutes in the past for a 50-minute slot). If buffer >= remaining, the timer starts with remainingSeconds == 0 and phaseDurationSeconds == 0, shows 0:00, plays the work-done feedback on the first tick ~1 second later, and immediately presents the FocusMate-done form; scheduleCurrentPhaseBanner also schedules a 'session complete' banner after max(1, 0) = 1 second. Saving records actualDuration = 0 with completed = true (compounding the hardcoded-completed bug). Neither ContentView.confirmStartPomodoro (line 158-165) nor PomodoroConfigView validates the buffer against the chosen start time, and the config view never surfaces the buffer at all.

**Hypothesis:** The wrap-up buffer feature (e0e768e) was added at the timer layer with a max(0,...) clamp but no corresponding validation or feedback at the configuration layer, so degenerate zero-length sessions are startable.

**Proposed fix:** In confirmStartPomodoro (or startFocusMate), refuse to start (or start with buffer = 0) when endTime - now - buffer <= some minimum (e.g. 60s), and ideally show the buffer-adjusted countdown end in PomodoroConfigView so the user sees the effective session length before starting.

**Verifier refinement:** Validate in confirmStartPomodoro (or startFocusMate): if Int(endTime.timeIntervalSinceNow) - buffer < ~60s, either refuse to start (disable the Start button with a hint in PomodoroConfigView) or fall back to buffer = 0. Showing the buffer-adjusted effective countdown in PomodoroConfigView's 'ends at' line would make the degenerate case visible before starting.

**Evidence:**
```
let offsetSeconds = max(0, earlyEndSeconds)
let remaining = max(0, Int(endTime.timeIntervalSince(Date.now)) - offsetSeconds)
```

**Verifier notes:** Confirmed end to end. Buffer steppers allow up to 10:50 = 650s (SettingsView.swift:114-124); the boundary grid includes any 15-min boundary with remaining > 0 (PomodoroConfigView.swift:151), e.g. ~5 min left on a 50-min slot; startFocusMate clamps remaining to 0 (PomodoroTimer.swift:137-138) and confirmStartPomodoro (ContentView.swift:147-168) has no validation. With remainingSeconds == phaseDurationSeconds == 0 the first tick (~1s) enters the FocusMate expiry branch and presents the done form, scheduleCurrentPhaseBanner fires after max(1,0)=1s (line 334), and saveAndDone() records actualDuration = 0 with hardcoded completed = true (PomodoroSessionEndView.swift:215-217).

### BC-005 — Pausing a FocusMate session silently pushes its end past the fixed end time while the UI still advertises the original end time

- [ ] **medium** · `Breadcrumb/PomodoroTimer.swift:225` · found by: timer-logic, concurrency · ✅ Verified real (high confidence)

**Problem:** FocusMate is documented and implemented as a fixed-end-time mode (remaining is derived from endTime at start, no overtime). But PomodoroRunningView shows the Pause button for any .work phase, including FocusMate (PomodoroRunningView.swift:63-69), and pause()/resume()/tick() are purely elapsed-based (elapsedBeforePause + time since phaseStartDate). Pausing a FocusMate session for N minutes makes the countdown end N minutes after focusMateEndTime - buffer, while the phase label still reads 'until HH:MM' from the stored focusMateEndTime (PomodoroRunningView.swift:124-126) and the wrap-up buffer becomes meaningless. The session timer then no longer matches the real FocusMate partner session it is supposed to mirror.

**Hypothesis:** pause/resume were built for the Pomodoro mode's relative countdown and FocusMate mode reuses the same .work phase machinery without re-anchoring to the wall-clock end time.

**Proposed fix:** Either hide the Pause button when timer.isFocusMateSession in PomodoroRunningView, or make tick() recompute remainingSeconds from focusMateEndTime/focusMateEarlyEndSeconds (wall clock) when isFocusMateSession is true so pause cannot shift the end.

**Verifier refinement:** Hiding the Pause button when timer.isFocusMateSession is the simplest fix consistent with fixed-end semantics (a FocusMate partner session cannot be paused anyway). If pause must stay, recompute remaining from focusMateEndTime - focusMateEarlyEndSeconds wall clock in tick() for FocusMate sessions.

**Evidence:**
```
func pause() {
    isPaused = true
    if let start = phaseStartDate {
```

**Verifier notes:** Confirmed. PomodoroRunningView.swift:62-69 shows Pause for any .work phase with no isFocusMateSession check, and pause()/resume()/tick() (PomodoroTimer.swift:225-240, 280-287) count elapsed time against the phaseDurationSeconds snapshot taken at startFocusMate (line 147), so pausing N minutes pushes the real end N minutes past focusMateEndTime minus buffer. Meanwhile the phase label still renders 'until HH:MM' from the stored focusMateEndTime (PomodoroRunningView.swift:124-126), so the UI advertises a stale end time.

### BC-006 — isAvailable is a stale cache: refreshed only from Settings interactions, so the AI button never appears if the local model becomes ready mid-session

- [ ] **medium** · `Breadcrumb/Services/AIService.swift:104` · found by: ai-system · ✅ Verified real (high confidence)

**Problem:** isAvailable is computed once in init() and thereafter only via refreshAvailability(), which grep shows is called solely from SettingsView.swift:77 and OpenRouterSettingsSection.swift:45/47/118. SystemLanguageModel availability is dynamic: '.modelNotReady' at app launch (common right after boot or while the model downloads) transitions to '.available' later, but the cached flag never updates, so AIExtractButton (`if aiService.isAvailable`, AIExtractButton.swift:27) stays hidden for the entire session unless the user happens to edit AI settings. The inverse staleness also exists (key/model deleted externally leaves the button visible until the call fails), though that path at least shows a localized error.

**Hypothesis:** Availability was treated as static configuration, but local-model availability is a runtime condition that changes without any settings interaction.

**Proposed fix:** Re-resolve availability when it matters: either make isAvailable a computed property (resolveProvider() != nil — the keychain/UserDefaults/model checks are cheap), or call aiService.refreshAvailability() in AIExtractButton.onAppear / when the status form opens.

**Verifier refinement:** Prefer calling aiService.refreshAvailability() in AIExtractButton.onAppear (or task) over making isAvailable computed: a computed property reading UserDefaults/keychain/SystemLanguageModel is not observation-tracked, so views would only get fresh values on incidental body re-evaluation, and OpenRouterSettingsSection.swift:55-57 depends on isAvailable changes triggering updates.

**Evidence:**
```
func refreshAvailability() {
    isAvailable = resolveProvider() != nil
}
```

**Verifier notes:** isAvailable is set once in init (AIService.swift:101) and refreshAvailability (104-106) is called only from SettingsView.swift:77 and OpenRouterSettingsSection.swift:45/47/118 — confirmed by grep across the repo. AIExtractButton.swift:27 gates on the cached flag with no refresh, and AIService lives for the entire session (BreadcrumbApp.swift:12 @State), so a modelNotReady-at-launch local model keeps the button hidden indefinitely. The inverse-staleness caveat is also accurate: extractStatus re-resolves the provider per call (line 131) and throws a localized .notAvailable error.

### BC-007 — AIService.extractStatus bypasses mapError, so local-provider failures (context window, guardrail, unsupported language) surface as raw unlocalized FoundationModels errors

- [ ] **medium** · `Breadcrumb/Services/AIService.swift:136` · found by: ai-system · ✅ Verified real (high confidence)

**Problem:** AIService has mapError() (lines 290-305) that converts LanguageModelSession.GenerationError into localized AIServiceError cases (.contextWindowExceeded -> Strings.Errors.textTooLong etc.), but the only production AI path — extractStatus() — calls provider.extractStatus() with no do/catch, and LocalAIProvider throws the framework error unmapped. AIExtractButton then shows error.localizedDescription of a raw FoundationModels error: an unlocalized, framework-worded message instead of the carefully prepared German/English strings. mapError is effectively only reachable from the unused generate()/stream() methods. Observable symptom: a German user pasting a long status text sees a system English error instead of 'Der Text ist zu lang für die Verarbeitung'.

**Hypothesis:** Error mapping was built for the generate/stream APIs; when extraction was refactored onto the provider protocol, the mapping step was not carried over into the new code path.

**Proposed fix:** Wrap the provider call: `do { return try await provider.extractStatus(...) } catch let e as AIServiceError { throw e } catch is CancellationError { throw CancellationError() } catch { throw mapError(error) }` (with mapError available under the same #if/@available guards, falling back to .generationFailed otherwise).

**Verifier refinement:** Proposed fix is correct; preserve the CancellationError passthrough since AIExtractButton.swift:67 relies on catching CancellationError to silently ignore view-lifecycle cancellation. Because extractStatus is not availability-gated, wrap the mapError call in #if canImport(FoundationModels) + if #available(macOS 26, *) and fall back to .generationFailed(error.localizedDescription). Alternatively, do the mapping inside LocalAIProvider so all providers uniformly throw AIServiceError.

**Evidence:**
```
isGenerating = true
defer { isGenerating = false }
return try await provider.extractStatus(from: text, language: language)
```

**Verifier notes:** extractStatus (AIService.swift:130-137) has no do/catch around provider.extractStatus (line 136), and LocalAIProvider throws raw session.respond errors unmapped (LocalAIProvider.swift:51, 54); AIExtractButton.swift:70 then shows the framework's unlocalized localizedDescription. mapError (290-305) is only reachable from the unused generate/stream methods. OpenRouterProvider throws AIServiceError itself, so only the local path is affected, exactly as described.

### BC-008 — Notification action button titles are frozen at launch language and never re-registered after a language switch

- [ ] **medium** · `Breadcrumb/Services/NotificationService.swift:145` · found by: localization, notifications-permissions · ✅ Verified real (high confidence)

**Problem:** registerCategories() is called exactly once, from init() (line 109). It reads "app.language" from UserDefaults at that moment and bakes the language into the UNNotificationAction titles ("Nächste Sitzung", "Weiterarbeiten", "Stopp" / English equivalents). When the user changes the app language in Settings, banner titles/bodies update (they are built per-send with the passed language), but the action buttons on every subsequent notification keep showing the old language until the app is restarted — a mixed-language notification.

**Hypothesis:** Categories were registered once for simplicity; nobody wired a re-registration when LanguageManager.language changes, so the UNNotificationCategory set keeps the launch-time titles.

**Proposed fix:** Make registerCategories() take an AppLanguage and call it again whenever the language changes (e.g. add a `func languageChanged(_ l: AppLanguage)` invoked from SettingsView's language Picker onChange, or re-register inside scheduleBanner/sendImmediateBanner using the passed `language` before posting).

**Verifier refinement:** Simplest correct fix: call a registerCategories(for: language) from inside scheduleBanner using the passed language before building the request — this keeps categories in sync with the banner content without wiring SettingsView to NotificationService.

**Evidence:**
```
private func registerCategories() {
    let stored = userDefaults.string(forKey: "app.language") ?? "de"
    let language = AppLanguage(rawValue: stored) ?? .german
```

**Verifier notes:** registerCategories() is called exactly once from init (:109) and bakes the launch-time "app.language" UserDefaults value into the action titles (:145-158). NotificationService is created once as @State in BreadcrumbApp.swift:14 and never recreated; SettingsView's language Picker (SettingsView.swift:61) binds LanguageManager with no re-registration hook, so action buttons keep the old language until restart while banner titles/bodies (built per-schedule with the passed language) switch — significant for a menu bar app that runs for weeks.

### BC-009 — scheduleBanner's untracked Task can add a notification after cancelScheduledBanners() already ran

- [ ] **medium** · `Breadcrumb/Services/NotificationService.swift:260` · found by: concurrency, notifications-permissions · ✅ Verified real (high confidence)

**Problem:** scheduleBanner returns an unstructured Task that first awaits requestAuthorization and only then calls notificationCenter.add(request). cancelScheduledBanners() (line 140) only calls removePendingNotificationRequests — it cannot cancel an in-flight scheduling Task, and PomodoroTimer discards the returned Task. If the user pauses/stops the timer while the scheduling Task is suspended in requestAuthorization (guaranteed-long window on first run, when the system permission dialog is pending: the add() executes only after the user clicks Allow), the cancel removes nothing and the add() lands afterwards. UNTimeIntervalNotificationTrigger then starts counting from the add, so a 'Pomodoro finished' banner fires at an arbitrary later time even though the timer was paused or stopped.

**Hypothesis:** Cancellation was implemented at the UNUserNotificationCenter level (pending requests) but the asynchronous request-authorization-then-add pipeline was overlooked, leaving a cancel-then-add ordering race.

**Proposed fix:** Store the in-flight scheduling Task in a private property on NotificationService; in cancelScheduledBanners() cancel it before calling removePendingNotificationRequests, and inside the Task call try Task.checkCancellation() after the authorization await and before notificationCenter.add(request).

**Verifier refinement:** Proposed fix is correct; additionally have scheduleBanner cancel/overwrite any previously stored in-flight task when a new one is created (phase transitions call schedule* without always going through cancelScheduledBanners on the same tick), and nil the stored task on completion. Task.checkCancellation() must sit between the authorization await and add().

**Evidence:**
```
return Task {
    let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound])
    ...
    try await notificationCenter.add(request)
```

**Verifier notes:** Confirmed race: scheduleBanner (NotificationService.swift:260-273) awaits requestAuthorization before notificationCenter.add; cancelScheduledBanners (:140-142) only calls removePendingNotificationRequests and PomodoroTimer discards the returned Task at PomodoroTimer.swift:339/345 (pause/stop/startWork all call cancelScheduledBanners at :131,157,186,205,220,233,253 with no Task handle). If cancel runs while the Task is suspended in requestAuthorization (arbitrarily long on first run with the permission dialog pending), add() lands afterward and UNTimeIntervalNotificationTrigger counts from that point, firing a banner for a stopped/paused timer.

### BC-010 — Clicking the notification banner body does nothing (default action unhandled)

- [ ] **medium** · `Breadcrumb/Services/NotificationService.swift:305` · found by: windows-lifecycle, notifications-permissions · ✅ Verified real (high confidence)

**Problem:** handleActionIdentifier only matches custom action button identifiers. Tapping the banner itself delivers UNNotificationDefaultActionIdentifier, which falls into 'default: break'. Because the app is LSUIElement, the OS activation that follows shows nothing — the user taps 'Pomodoro finished' and nothing visible happens. This is most damaging in .menuBar presentation mode where no window auto-opens at session end.

**Hypothesis:** The switch was written for the registered action buttons only; the implicit default-tap identifier was forgotten.

**Proposed fix:** Add 'case UNNotificationDefaultActionIdentifier: postAppNotification(.openSessionEnd)' to handleActionIdentifier so tapping the banner opens the configured session-end prompt, same as the explicit action button.

**Evidence:**
```
case "breadcrumb.action.nextSession":
    postAppNotification(.pomodoroNextSession)
default:
    break
```

**Verifier notes:** Confirmed: didReceive (:285-293) forwards response.actionIdentifier to handleActionIdentifier (:295-308), whose switch matches only the four custom identifiers; UNNotificationDefaultActionIdentifier (banner-body click) falls into 'default: break'. In an LSUIElement app the resulting OS activation shows no UI, so clicking the banner does nothing — worst in .menuBar presentation where nothing auto-opens. Proposed fix is correct and safe for both banner types since both work-done and break-done expiry set pendingSessionEnd before the banner fires (PomodoroTimer.swift:296,304).

### BC-011 — 'Continue Working' after a manual Stop leaves the timer paused instead of resuming

- [ ] **medium** · `Breadcrumb/Views/PomodoroSessionEndHostView.swift:46` · found by: timer-logic · ✅ Verified real (high confidence)

**Problem:** requestStop() pauses the timer (pause() cancels the tick task, clears phaseStartDate, cancels banners) before setting pendingSessionEnd = .stopped. If the user then picks 'Continue Working' in the session-end form, handleContinueWorking only calls timer.clearPendingSessionEnd() — the timer stays frozen in the paused state and no completion banner is rescheduled. The user who chose to continue working must notice the frozen countdown and additionally press Resume. In the overtime (.workDone) case the same handler is fine because the timer never stopped, which is why the gap was not noticed.

**Hypothesis:** handleContinueWorking was written for the auto-overtime flow where the timer is still running; the .stopped flow added via requestStop() reuses it without undoing the pause that requestStop performed.

**Proposed fix:** In handleContinueWorking, add `if timer.isPaused { timer.resume() }` after clearPendingSessionEnd(); resume() already reschedules the phase banner and restarts ticking.

**Evidence:**
```
private func handleContinueWorking() {
    timer.clearPendingSessionEnd()
}
```

**Verifier notes:** requestStop() (PomodoroTimer.swift:242-245) calls pause() — cancelling the tick task and scheduled banners — before setting pendingSessionEnd = .stopped, and handleContinueWorking (PomodoroSessionEndHostView.swift:46-48) only clears pendingSessionEnd, leaving isPaused=true with no ticking and no banner. Mitigating factor: PomodoroRunningView.swift:63-65 then shows a prominent 'Resume' button so the state is visible and recoverable, but 'Continue Working' does not actually resume, and if the popover is closed the frozen timer never notifies. Proposed fix verified sound: resume() (PomodoroTimer.swift:236-240) restarts ticking and reschedules the banner using the preserved elapsedBeforePause (scheduleCurrentPhaseBanner subtracts it at line 334).

### BC-012 — FocusMate Skip/Stop persists wrong actualDuration (uses the formula the project's own tests label "wrongDuration")

- [ ] **medium** · `Breadcrumb/Views/PomodoroSessionEndHostView.swift:96` · found by: swiftdata, timer-logic · ✅ Verified real (high confidence)

**Problem:** saveCurrentWorkSession() computes actualDuration as originalDurationSeconds - remainingSeconds + overtimeSeconds and also stamps isFocusMate from the timer. For FocusMate sessions, originalDurationSeconds is the full configured session length while phaseDurationSeconds is only the time from actual start to end (FocusMate supports joining mid-session via the 15-min start-time grid, and the wrap-up buffer also shortens phaseDuration). When a FocusMate session ends and the user clicks 'Skip' (focusMateEndContent's Skip routes to onStopCompletely -> handleStopCompletely(wasBreak:false) -> saveCurrentWorkSession), the persisted PomodoroSession gets actualDuration = full configured duration with completed = true, overstating focus time. Example: 50-min session joined 20 min late records 3000s instead of 1800s. The same wrong base is used when stopping a FocusMate session early. These inflated values flow into Project.totalFocusTime and the stats UI. The correct path, saveAndDone() in PomodoroSessionEndView.swift:217, uses phaseDurationSeconds — and SessionDurationTests.focusMateDurationUsesPhase (BreadcrumbTests/SessionDurationTests.swift:74-88) explicitly asserts that the originalDurationSeconds-based value is the 'wrongDuration' for FocusMate.

**Hypothesis:** saveCurrentWorkSession was written for regular Pomodoro stop/skip (where originalDuration == phaseDuration) and later gained 'isFocusMate = timer.isFocusMateSession' without adapting the duration formula that saveAndDone already gets right.

**Proposed fix:** In saveCurrentWorkSession(), branch on timer.isFocusMateSession: use TimeInterval(timer.phaseDurationSeconds - timer.remainingSeconds) for FocusMate (no overtime exists there) and keep the originalDurationSeconds-based formula only for regular Pomodoro sessions, mirroring saveAndDone().

**Verifier refinement:** Proposed fix is correct: in saveCurrentWorkSession(), branch on timer.isFocusMateSession and use TimeInterval(timer.phaseDurationSeconds - timer.remainingSeconds) for FocusMate (overtime never occurs there — tick() stops FocusMate at zero, PomodoroTimer.swift:292-304), keeping the originalDurationSeconds formula for regular Pomodoro. The existing completed = remainingSeconds <= 0 check already handles both natural-end Skip (completed=true) and early Stop (completed=false) correctly.

**Evidence:**
```
session.actualDuration = TimeInterval(timer.originalDurationSeconds - timer.remainingSeconds + timer.overtimeSeconds)
session.project = boundProject
session.isFocusMate = timer.isFocusMateSession
```

**Verifier notes:** PomodoroSessionEndHostView.swift:96 computes actualDuration from originalDurationSeconds and line 98 stamps isFocusMate; startFocusMate (PomodoroTimer.swift:146-147) sets originalDurationSeconds to the full configured length while phaseDurationSeconds is the actual joined duration, so FocusMate Skip (PomodoroSessionEndView.swift:88 -> onStopCompletely -> handleStopCompletely(wasBreak:false) -> saveCurrentWorkSession) and early Stop persist inflated durations with completed=true. The correct path saveAndDone uses phaseDurationSeconds (PomodoroSessionEndView.swift:217), and SessionDurationTests.swift:82-87 explicitly labels the originalDuration formula 'wrongDuration'; inflated values flow into Project.totalFocusTime (Project.swift:40-43).

### BC-013 — Uncommitted project.yml downgrades app version from 0.8.1 (build 19) back to 0.8.0 (build 18)

- [ ] **medium** · `project.yml:27` · found by: orchestrator · ✅ Verified real (high confidence)

**Problem:** The working tree contains an uncommitted change reverting MARKETING_VERSION from "0.8.1" to "0.8.0" and CURRENT_PROJECT_VERSION from "19" to "18", while commit 912a6aa already bumped the repo to 0.8.1/19. If committed as-is, the next build/release would ship with a DOWNGRADED version number, confusing updates and release tooling (/breadcrumb-release bumps from whatever is in project.yml).

**Hypothesis:** A previous agent or tool regenerated/edited project.yml from a stale state, accidentally reverting the version bump from commit 912a6aa.

**Proposed fix:** Restore MARKETING_VERSION: "0.8.1" and CURRENT_PROJECT_VERSION: "19" in project.yml (i.e. discard the two version lines of the uncommitted diff), then run xcodegen generate. Keep or discard the FooterView menuStyle change separately (see its own finding).

**Evidence:**
```
-      MARKETING_VERSION: "0.8.1"\n+      MARKETING_VERSION: "0.8.0"
```

**Verifier notes:** Confirmed directly via git diff by the orchestrating agent: working tree reverts the version bump made in commit 912a6aa.

### BC-014 — applyResult() clobbers user-typed lastAction/nextStep with an empty string when the AI returns pure filler

- [ ] **medium** · `Breadcrumb/Views/AIExtractButton.swift:79` · found by: ai-system · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** The guard `if !lastAction.isEmpty` checks the RAW extraction result, then assigns the CLEANED value. If the model returns non-empty filler (e.g. "nothing planned" for nextStep — exactly the case AIFillerStripper exists for), the guard passes and `self.nextStep = AIFillerStripper.clean(...)` assigns "", erasing whatever the user had already typed into the optional field. The guard's evident purpose (don't overwrite existing content with an empty result) is defeated for the most common filler case. Separately, when the cleaned result IS non-empty it silently replaces any user-typed field content with no confirmation, which is at least surprising in the edit-existing-entry flow (StatusEntryForm pre-populates lastAction/nextStep from the entry being edited).

**Hypothesis:** The emptiness check was written against the provider result before the filler-stripping step was inserted into the assignment, so the post-strip emptiness is never re-checked.

**Proposed fix:** Clean first, then guard on the cleaned value: `let cleanedLast = AIFillerStripper.cleanLines(lastAction); if !cleanedLast.isEmpty { self.lastAction = cleanedLast }` (same for nextStep). Optionally merge with, rather than replace, non-empty user-typed content.

**Evidence:**
```
if !lastAction.isEmpty {
    self.lastAction = AIFillerStripper.clean(lastAction)
}
if !nextStep.isEmpty { self.nextStep = AIFillerStripper.clean(nextStep) }
```

### BC-015 — AI extraction skips the documented cleanLines/joinInline pipeline — multi-line AI output lands raw in single-line TextFields and per-line filler survives

- [ ] **medium** · `Breadcrumb/Views/AIExtractButton.swift:80` · found by: ui-views, ai-system · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** OpenRouterProvider explicitly instructs the model to separate multiple items with newlines (OpenRouterProvider.swift:137-138/143-144), but applyResult passes the result through AIFillerStripper.clean() — the single-value variant — and writes it into the single-line TextFields of StatusEntryForm (line 51-52). A filler line embedded in a multi-line result (e.g. "Punkt eins\nnichts unklar") is never stripped because clean() only exact-matches the whole string, and the newline-separated text displays poorly in a one-line TextField. AIFillerStripper.cleanLines() and BulletText.joinInline() were written exactly for this (joinInline's doc comment says it is used so 'AI-extracted output appears as plain inline text'), and CLAUDE.md documents this pipeline, but neither function is called anywhere in app code — grep shows BulletText.* has zero app-code call sites.

**Hypothesis:** The post-processing pipeline was designed and tested (BulletTextTests, AIFillerStripperTests) but AIExtractButton was never wired to it; clean() was used instead of cleanLines() + joinInline().

**Proposed fix:** In applyResult, use the documented pipeline: self.lastAction = BulletText.joinInline(AIFillerStripper.cleanLines(lastAction)) and likewise for nextStep. This also resurrects the currently dead BulletText module.

**Evidence:**
```
if !lastAction.isEmpty {
    self.lastAction = AIFillerStripper.clean(lastAction)
}
```

### BC-016 — Main breakout window has no empty-state guard — restored window shows a blank Color.clear pane

- [ ] **medium** · `Breadcrumb/Views/BreakoutWindowView.swift:13` · found by: windows-lifecycle · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** When the 'main' window exists but windowManager.currentContent is nil, BreakoutWindowView renders Color.clear — a visible, empty, transparent 'Breadcrumb' window. Neither Window scene opts out of state restoration (no .restorationBehavior(.disabled) anywhere in the repo), so quitting with the Settings/History window open and relaunching restores the window with currentContent == nil (it is not persisted), producing a ghost blank window at launch. The sibling SessionEndWindowView defends against exactly this with dismissIfPromptIsGone() in onAppear; BreakoutWindowView has no equivalent.

**Hypothesis:** The self-dismiss guard was added to SessionEndWindowView when its auto-open logic was built (commit 0e1aa1e) but the same restoration/empty-state hole in the main breakout window was never covered.

**Proposed fix:** Mirror SessionEndWindowView: in BreakoutWindowView add .onAppear { if windowManager.currentContent == nil { dismissWindow(id: "main") } } via @Environment(\.dismissWindow), or add .restorationBehavior(.disabled) to both Window scenes in BreadcrumbApp.swift.

**Evidence:**
```
} else {
    Color.clear
}
```

### BC-017 — File bookmark resolved synchronously in view body without .withoutUI/.withoutMounting — popover can freeze or trigger mount UI

- [ ] **medium** · `Breadcrumb/Views/DocumentListView.swift:101` · found by: documents-keychain, ui-views · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** Each file-document row calls resolveBookmark(doc) directly inside the row builder (line 101), so bookmark data is resolved from disk on every body evaluation of ProjectDetailView (every hover state change, overlay toggle, etc.). resolveBookmark (lines 133-149) passes options: [], which permits Foundation to mount network volumes and even present UI during resolution. If a linked file lives on a disconnected network share or ejected disk, opening the project detail popover blocks the main actor for seconds per row (popover beachballs) and may pop a 'connect to server' dialog just from rendering the list. The same default-options resolution is repeated in openDocument (line 160), so a click resolves the bookmark a second time.

**Hypothesis:** The existence check was written as a convenience function and called inline in the ViewBuilder without considering that URL(resolvingBookmarkData:) does blocking I/O and that the empty options set allows mounting and UI; the agent that wrote it only tested with local files.

**Proposed fix:** Resolve each document's bookmark once into cached state (e.g., a @State [PersistentIdentifier: URL?] populated in .task/onAppear and refreshed after edits) instead of calling resolveBookmark in the row builder, and pass options: [.withoutUI, .withoutMounting] for the display/existence check so rendering can never block on volume mounting or show dialogs. Keep default options only in openDocument where mounting is actually desired.

**Evidence:**
```
if doc.type == .file && resolveBookmark(doc) == nil {
    Text(Strings.Documents.fileNotFound(l))
```

### BC-018 — Uncommitted change switches FooterView menu to deprecated .menuStyle(.borderlessButton), making the attached ToolbarButtonStyle inert

- [ ] **medium** · `Breadcrumb/Views/FooterView.swift:42` · found by: swiftui-state, windows-lifecycle, ui-views · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** The working tree replaces `.menuStyle(.button)` with `.menuStyle(.borderlessButton)` (git diff confirms). BorderlessButtonMenuStyle has been deprecated since macOS 14 — Apple's guidance is `.menuStyle(.button)` combined with `.buttonStyle(.borderless)` — and this is a macOS 26 target. Additionally, line 45 still applies `.buttonStyle(ToolbarButtonStyle())`; with the borderlessButton menu style the custom ButtonStyle is no longer consulted for the menu label, so the ⋯ overflow button loses the hover/press highlight that its two sibling footer buttons (archive, 🍅) get from ToolbarButtonStyle, producing inconsistent footer styling.

**Hypothesis:** The switch was likely an attempt to remove default menu-button chrome, but it reached for the deprecated style instead of keeping .menuStyle(.button) and adjusting the button style.

**Proposed fix:** Revert to `.menuStyle(.button)` and keep `.buttonStyle(ToolbarButtonStyle())` (the pre-change, committed state); if chrome was the problem, use `.buttonStyle(.borderless)` or tweak ToolbarButtonStyle rather than the deprecated BorderlessButtonMenuStyle.

**Evidence:**
```
-            .menuStyle(.button)
+            .menuStyle(.borderlessButton)
             .menuIndicator(.hidden)
```

### BC-019 — NativeDictationButton's isDictating is an optimistic guess that goes stale, and its 'stop' path discards in-progress dictation text

- [ ] **medium** · `Breadcrumb/Views/NativeDictationButton.swift:33` · found by: swiftui-state, notifications-permissions, ui-views · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** toggleDictation() blindly calls isDictating.toggle() after sending startDictation:/cancelOperation: via NSApp.sendAction, with no feedback from the system about whether dictation actually started or stopped. The user can end dictation through the system dictation HUD, Esc, the dictation key, or by focus loss — the button then keeps showing the 'stop' icon (mic.badge.xmark, red). Clicking it in that stale state sends cancelOperation: to the first responder; PlaceholderNSTextView.cancelOperation (PlaceholderTextView.swift:112-118) responds by discarding any marked text, which is exactly where not-yet-finalized dictated/IME-composed words live — so the stale 'stop' click can delete the user's pending input. It takes a second click (now sending startDictation: while the icon shows 'start') to resync, and the icon/action are inverted in the meantime.

**Hypothesis:** There is no public API callback for system dictation state, and the author settled for an optimistic local toggle without any resync (e.g., on focus change or view disappearance).

**Proposed fix:** At minimum reset isDictating to false when isFocused becomes false (onChange) and when the view disappears; better, drop the toggle UI entirely and make the button a one-way 'start dictation' trigger (send startDictation: only), letting the system HUD own stop/cancel, which removes the stale-state class of bugs.

**Evidence:**
```
if isDictating {
    NSApp.sendAction(NSSelectorFromString("cancelOperation:"), to: nil, from: nil)
} … isDictating.toggle()
```

### BC-020 — Standalone session-end picker offers 'Without project' but selecting it disables the only Save button

- [ ] **medium** · `Breadcrumb/Views/PomodoroSessionEndView.swift:121` · found by: swiftui-state · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** For standalone sessions (boundProject == nil) the picker explicitly offers `Text(Strings.Projects.withoutProject(l)).tag(nil as Project?)`, but both primary actions are gated with `.disabled(selectedProject == nil && boundProject == nil)` (lines 87 and 108). So choosing the offered 'Without project' option makes 'Save & Break' / 'Save & Done' permanently disabled — the option is a dead end, even though the codebase fully supports project-less sessions (PomodoroSessionEndHostView.saveCurrentWorkSession saves sessions with `session.project = boundProject` possibly nil via Skip/Stop, and saveWorkSession itself handles nil project by just skipping the StatusEntry). Any status text the user typed in this state cannot be saved and is lost when they fall back to Skip/Stop.

**Hypothesis:** The disabled-gate was added to prevent StatusEntry creation without a project, but it gates the entire save action instead of just the entry, contradicting the deliberately offered nil tag in the picker.

**Proposed fix:** Either remove the 'Without project' nil tag from the picker (force a selection), or remove/loosen the .disabled gates so a nil-project save records the PomodoroSession without a StatusEntry (the save functions already handle this), optionally hinting that status text requires a project.

**Evidence:**
```
Text(Strings.Projects.withoutProject(l)).tag(nil as Project?)
…
.disabled(selectedProject == nil && boundProject == nil)
```

### BC-021 — FocusMate 'Save & Done' hardcodes completed = true even when the session was stopped early

- [ ] **medium** · `Breadcrumb/Views/PomodoroSessionEndView.swift:215` · found by: timer-logic · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** Stopping a FocusMate session early (Stop button → requestStop → pendingSessionEnd = .stopped) shows focusMateEndContent because PomodoroSessionEndHostView passes isFocusMate: reason == .focusMateDone || timer.isFocusMateSession. Its 'Save & Done' button calls saveAndDone(), which sets session.completed = true unconditionally — even if the user aborted after 2 minutes of a 50-minute session. This permanently inflates Project.completedPomodoroCount and adds the partial duration to totalFocusTime (which filters on completed == true). Every other save path correctly derives completed from timer.remainingSeconds <= 0 (e.g. saveWorkSession line 177, saveCurrentWorkSession line 94).

**Hypothesis:** saveAndDone was written for the natural focusMateDone expiry (where remainingSeconds is always 0, so completed = true is trivially right) and the early-stop path through the same form was not considered.

**Proposed fix:** In saveAndDone(), replace `session.completed = true` with `session.completed = timer.remainingSeconds <= 0`, matching the other save paths.

**Evidence:**
```
session.completed = true
session.endedAt = .now
session.actualDuration = TimeInterval(timer.phaseDurationSeconds - timer.remainingSeconds)
```

### BC-022 — "Update Status" reuses stale drafts from a cancelled edit, prefilling a NEW entry with the old entry's text

- [ ] **medium** · `Breadcrumb/Views/ProjectDetailView.swift:138` · found by: ui-views, swiftui-state · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** The Update Status button sets editingEntry = nil but never resets draftFreeText/draftLastAction/draftNextStep. The edit-pencil flow (lines 230-235) fills those drafts from the latest entry, and cancelling the overlay (line 171) clears only editingEntry. So: edit latest entry -> Cancel -> Update Status opens the create-mode form prefilled with the latest entry's full text; one Cmd+Return saves a duplicate StatusEntry. ProjectListView shows the intended pattern (lines 37-38 reset drafts before opening the new-project form), confirming this is an omission in the edit-latest feature (commit 6fd3135).

**Hypothesis:** When the edit-latest-entry feature added draft prefilling from the entry, the create path was not updated to clear the shared draft @State, so drafts leak across edit/create modes.

**Proposed fix:** In the Update Status button action, reset the drafts before opening the form: draftFreeText = ""; draftLastAction = ""; draftNextStep = ""; editingEntry = nil. Alternatively clear the drafts in dismissOverlay for the status form.

**Evidence:**
```
Button(Strings.Status.updateStatus(languageManager.language)) {
    editingEntry = nil
    showOverlay { showingStatusForm = true }
```

### BC-023 — Cmd+U shortcut stays active while overlays are open — stacks overlays and silently flips edit form into new-entry mode

- [ ] **medium** · `Breadcrumb/Views/ProjectDetailView.swift:143` · found by: swiftui-state · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** The 'Update Status' button keeps its Cmd+U keyboardShortcut active while a FormOverlay is shown, because the main content is only gated with .allowsHitTesting(!hasActiveOverlay) (line 168), which blocks pointer events but not keyboard shortcuts. Two observable failures: (1) with the edit-project overlay open (showingEditForm), Cmd+U also sets showingStatusForm = true, so both `if showingEditForm` and `if showingStatusForm` branches render and two FormOverlays stack in the ZStack; (2) with the status form already open in EDIT mode (editingEntry set via the pencil button), pressing Cmd+U executes `editingEntry = nil` while the form stays visible with the seeded draft text — the form silently switches from editing the latest entry to creating a new one, so Save produces a duplicate StatusEntry instead of an edit.

**Hypothesis:** allowsHitTesting was assumed to disable the whole background UI, but it only affects hit-testing; keyboardShortcut delivery is unaffected, so overlay exclusivity is never enforced for keyboard input.

**Proposed fix:** Guard the button action: `guard !hasActiveOverlay else { return }` before mutating state (and do the same for the Cmd+N button in ProjectListView), or apply .disabled(hasActiveOverlay) to the background VStack instead of/in addition to allowsHitTesting — disabled does suppress keyboard shortcuts.

**Evidence:**
```
.keyboardShortcut("u", modifiers: .command)  // action: editingEntry = nil; showOverlay { showingStatusForm = true }  // gate: .allowsHitTesting(!hasActiveOverlay)
```

### BC-024 — Cmd+N while the new-project form is open wipes the user's typed project name

- [ ] **medium** · `Breadcrumb/Views/ProjectListView.swift:37` · found by: swiftui-state · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** The '+' button has .keyboardShortcut("n", modifiers: .command) (line 44) and its action unconditionally resets draftProjectName = "" and draftProjectIcon = "doc.text" before showing the overlay. ProjectListView has no allowsHitTesting/disabled gate at all while showingNewProject is true (and even the gate used elsewhere would not block shortcuts). So while the ProjectFormView overlay is open and the user is typing a name, pressing Cmd+N instantly clears the bound TextField — the typed name and icon selection vanish with no way to recover.

**Hypothesis:** The draft reset was placed in the open action assuming the button can only be triggered when the form is closed, but the keyboard shortcut remains active while the overlay is presented.

**Proposed fix:** Guard the action with `guard !showingNewProject else { return }`, or only reset the drafts in the form's dismiss/save paths instead of the open path.

**Evidence:**
```
Button(Strings.Projects.newProject(languageManager.language), systemImage: "plus") {
    draftProjectName = ""
    draftProjectIcon = "doc.text"  // … .keyboardShortcut("n", modifiers: .command)
```

### BC-025 — Opening or resetting the system-prompt editor persists the language-specific default as a 'custom' prompt, freezing extraction instructions to one language forever

- [ ] **medium** · `Breadcrumb/Views/Settings/OpenRouterSettingsSection.swift:71` · found by: ai-system, ui-views · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** onAppear seeds the TextEditor with defaultPrompt(for: language) when no custom prompt is stored (lines 96-99), and `.onChange(of: customPrompt)` (lines 71-73) writes every change of that state to UserDefaults key "ai.openrouter.customSystemPrompt" — including the onAppear seeding change and the 'Reset to default' button (line 81), which sets the default TEXT instead of clearing the key. OpenRouterProvider only falls back to the localized default when the stored value is nil or exactly "" (OpenRouterProvider.swift:9). Net effect: after merely viewing the settings section once (or pressing Reset), the German (or English) default text is baked in as a custom prompt; switching the app language later keeps sending the old-language instructions while jsonInstructions switches language, and any improved default prompt shipped in an app update is never picked up. There is also no trimming, so a whitespace-only prompt (" ") is treated as a real custom prompt by both the fallback check and the onAppear `stored?.isEmpty` check.

**Hypothesis:** The editor binds the persisted value directly and seeds the default into the same @State for display, with no concept of 'unset', so display-seeding and reset are indistinguishable from user customization.

**Proposed fix:** Persist only when the text differs from the default: in onChange (and Reset), if newValue == defaultPrompt(for:) or newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, call UserDefaults.standard.removeObject(forKey: "ai.openrouter.customSystemPrompt"), else store it. In OpenRouterProvider line 9, also trim before the isEmpty fallback check.

**Evidence:**
```
.onChange(of: customPrompt) { _, newValue in
    UserDefaults.standard.set(newValue, forKey: "ai.openrouter.customSystemPrompt")
}
```

### BC-026 — SmartTimestampView relative and absolute timestamps follow the system locale, not the app language

- [ ] **medium** · `Breadcrumb/Views/SmartTimestampView.swift:17` · found by: localization · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** `Text(date, style: .relative)` and `date.formatted(.dateTime...)` (lines 33-38) both use Locale.current. The "Today" prefix is localized via Strings.General.today, but the time/date portion and the entire relative string are not. A user running the app in German on an English macOS (or vice versa) gets mixed output like "Heute 2:30 PM" or "5 minutes ago" next to German labels — visible on every project row, the detail view, and every history entry.

**Hypothesis:** FormatStyle defaults to Locale.current and the view was written assuming system locale always matches the in-app AppLanguage setting, which the app explicitly decouples.

**Proposed fix:** Derive a Locale from languageManager.language (de_DE / en_US) and apply it: `date.formatted(.dateTime.hour().minute().locale(appLocale))` for the absolute branch, and replace `Text(date, style: .relative)` with `Text(date, format: .relative(presentation: .named).locale(appLocale))` (or Date.RelativeFormatStyle with the explicit locale).

**Evidence:**
```
if showRelative {
    Text(date, style: .relative)
} else {
```

### BC-027 — WindowManager retains Project models in BreakoutContent — deleting the project while its History/Stats window is open leaves a dangling SwiftData model (crash or dead window)

- [ ] **medium** · `Breadcrumb/WindowManager.swift:7` · found by: swiftdata, ui-views · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** BreakoutContent.history(Project)/.stats(Project) store a live SwiftData model inside the long-lived WindowManager service (currentContent, WindowManager.swift:38). Reachable sequence: in ProjectDetailView press 'History' (windowManager.open(.history(project))), return to the popover (window stays open), then delete the project via the ⋯ menu (ProjectDetailView.swift:161 modelContext.delete + save). Nothing clears windowManager.currentContent, so BreakoutWindowView keeps rendering HistoryView(project:)/StatsContentView(project:) and the navigation title against a deleted model (BreakoutWindowView.swift:40-45 reads project.name; HistoryView reads project.entries; StatsContentView reads pomodoroSessions). Accessing properties of a deleted-and-saved model is undefined in SwiftData — depending on OS version it either crashes with a backing-data fatal error or renders a stale ghost window titled with the deleted project that can never update. PomodoroTimer.boundProject (PomodoroTimer.swift:38) holds the same kind of strong model reference, though it is not reachable for deletion while a timer runs since the popover is occupied by PomodoroRunningView.

**Hypothesis:** BreakoutContent was designed to carry the model for convenience; no invalidation hook exists between project deletion (popover context) and the independent breakout window's retained content.

**Proposed fix:** Either (a) store PersistentIdentifier in BreakoutContent and re-fetch via modelContext.model(for:)/fetch in BreakoutWindowView, falling back to closing the window when the fetch fails, or (b) after modelContext.delete(project) in ProjectDetailView/ArchivedProjectsView, call a new windowManager.projectDeleted(project.id) that clears currentContent when it references that project.

**Evidence:**
```
enum BreakoutContent: Equatable {
    case history(Project)
    case stats(Project)
```

### BC-028 — Activation-policy race: delayed .accessory switch can fire while the other window is mid-open

- [ ] **medium** · `Breadcrumb/WindowManager.swift:99` · found by: windows-lifecycle · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** windowClosed() and sessionEndWindowClosed() both sleep 50ms and then set .accessory if no other regular window is visible. But open() and presentSessionEndWindow() sleep 100ms (activateForWindowPresentation) before calling openWindowAction, so a window opened concurrently is not yet visible at the 50ms check. Example: the main window is closed via the red button right as a work session ends and the session-end window auto-opens — windowClosed()'s task sets .accessory at +50ms (the openGeneration guard is never bumped by presentSessionEndWindow), then the session-end window appears at +110ms with the app stuck in accessory mode: no dock icon, no main menu, window can order behind other apps. The reverse race exists too: sessionEndWindowClosed() has no generation guard at all, so closing the session-end window and immediately triggering open(.settings) can force .accessory while the settings window is opening.

**Hypothesis:** Policy management is split across independent fire-and-forget Tasks with hardcoded sleeps; the openGeneration counter only protects the main-window close path against main-window reopens, not cross-window open/close interleavings.

**Proposed fix:** Use one shared generation/intent counter: bump it in open(), openSessionEnd(), and autoOpenSessionEnd() (i.e., in presentSessionEndWindow), and have BOTH close handlers re-check it after their delay before setting .accessory. Alternatively replace the sleep-based visibility check with explicit state: only drop to .accessory when currentContent == nil AND no session-end presentation is pending/in-flight.

**Evidence:**
```
func sessionEndWindowClosed() {
    isSessionEndAutoOpenSuppressed = true
    Task {
        try? await Task.sleep(for: .milliseconds(50))
```

### BC-029 — LanguageManagerTests deletes the user's real language preference from the live app domain

- [ ] **medium** · `BreadcrumbTests/LanguageManagerTests.swift:32` · found by: tests-quality · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** Because tests are hosted in Breadcrumb.app, UserDefaults.standard.removeObject(forKey: "app.language") (lines 32, 43, 48, 53, 62) operates on the user's actual com.roger.breadcrumb preferences. Running the test suite on a machine where the user chose English resets the app to German (the key is currently absent from the real domain — consistent with prior test runs having wiped it). There is also no restoration if a test fails before its trailing cleanup line, and the same key is read by NotificationService.registerCategories, creating cross-suite coupling (see the registersCategoriesOnInit finding).

**Hypothesis:** LanguageManager hardcodes UserDefaults.standard (Breadcrumb/Services/LanguageManager.swift:11,16) with no injection point, so the tests had no choice but to mutate the real domain and 'clean up' by deleting the user's setting.

**Proposed fix:** Give LanguageManager an injectable UserDefaults parameter (init(userDefaults: UserDefaults = .standard)) like NotificationService already has, and rewrite these tests against a UUID-named UserDefaults(suiteName:) with removePersistentDomain in a defer.

**Evidence:**
```
UserDefaults.standard.removeObject(forKey: "app.language")
let manager = LanguageManager()
#expect(manager.language == .german)
```

### BC-030 — NotificationServiceTests outcomes depend on the developer's real app settings (tests are hosted in Breadcrumb.app)

- [ ] **medium** · `BreadcrumbTests/NotificationServiceTests.swift:318` · found by: tests-quality, notifications-permissions · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** The test target runs hosted in the real app (TEST_HOST = Breadcrumb.app in project.pbxproj:582), so UserDefaults.standard is the live com.roger.breadcrumb preferences domain. registersCategoriesOnInit (line 291) constructs NotificationService with default userDefaults: .standard; NotificationService.registerCategories (Breadcrumb/Services/NotificationService.swift:145) reads "app.language" from those defaults, yet the test hard-asserts German titles ("Weiterarbeiten", "Stopp"). If the machine's real preference is "en" — or LanguageManagerTests has not yet deleted the key in this run — the test fails. Similarly scheduleRequestsAuthorizationBeforeAddingBanner (line 125) reads the real "pomodoro.showBannerNotification": if the user disabled banners in the app's Settings, scheduleWorkDoneBanner returns nil and try #require fails. Test results vary with the developer's app configuration and with cross-suite ordering.

**Hypothesis:** Most tests in the file correctly inject a fresh UserDefaults(suiteName:), but the init/category/authorization tests were written earlier or copied without the injection, silently falling back to .standard.

**Proposed fix:** Inject a fresh UserDefaults(suiteName: UUID-based) into every NotificationService construction in this file (set "app.language" explicitly to "de" for registersCategoriesOnInit and "pomodoro.showBannerNotification" to true for the authorization test), matching the pattern already used at lines 44-49.

**Evidence:**
```
#expect(actions[0].title == "Weiterarbeiten")
...
let service = NotificationService(notificationCenter: center)  // uses .standard defaults
```

### BC-031 — Zero test coverage for V1->V2 schema migration; test containers bypass the versioned schema entirely

- [ ] **medium** · `BreadcrumbTests/PomodoroSessionSaveTests.swift:11` · found by: tests-quality · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** No test file references BreadcrumbSchemaV1, BreadcrumbSchemaV2, or BreadcrumbMigrationPlan (verified by grep across BreadcrumbTests/). Both ModelContainers built in tests (PomodoroSessionSaveTests.swift:11-14, BreadcrumbTests.swift:52-55) pass raw model types instead of the versioned schema + migrationPlan that production uses (Breadcrumb/BreadcrumbApp.swift:93). The project's own stated top risk is silent save failures from broken migrations, yet a broken or missing migration stage would ship completely undetected.

**Hypothesis:** The migration plan was added for the isFocusMate field without anyone writing a round-trip test, and the in-memory test containers were written against concrete model types because it is the shortest code.

**Proposed fix:** Add a migration test: create a store at a temp URL using a ModelContainer configured with BreadcrumbSchemaV1, insert a PomodoroSession, close it, reopen the same URL with Schema(versionedSchema: BreadcrumbSchemaV2.self) + BreadcrumbMigrationPlan, and assert data survives with isFocusMate == false. Also build the in-memory test containers from the current versioned schema so tests exercise the production schema definition.

**Evidence:**
```
let container = try ModelContainer(
    for: Project.self, StatusEntry.self, PomodoroSession.self, LinkedDocument.self,
    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
```

### BC-032 — PomodoroSessionSaveTests never calls the app's save logic — tests re-implement it inline (test theater)

- [ ] **medium** · `BreadcrumbTests/PomodoroSessionSaveTests.swift:27` · found by: tests-quality · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** Every test in this suite builds a PomodoroSession/StatusEntry by hand, inserts it, and asserts its own insert worked. The comment at line 25 admits it 'Mirrors PomodoroSessionEndView.saveAndDone()'. The real save paths (PomodoroSessionEndHostView.saveCurrentWorkSession at Breadcrumb/Views/PomodoroSessionEndHostView.swift:88-101 and PomodoroSessionEndView.swift:172-235) are never executed, so a double-insert or wrong-field bug in the views — exactly what the suite claims to guard against — would not fail any test. Worst case is stopCompletelyFromBreakCreatesNothing (lines 216-228), which fetches from a freshly created empty in-memory store and asserts count == 0: a pure tautology.

**Hypothesis:** The save logic lives inside SwiftUI views and was untestable directly, so an agent copied the logic into the tests to produce green checkmarks instead of extracting the logic into a testable unit.

**Proposed fix:** Extract session/entry creation+save into a view-independent @MainActor helper (e.g. PomodoroSessionRecorder taking a ModelContext and PomodoroTimer snapshot), call it from both PomodoroSessionEndHostView and PomodoroSessionEndView, and rewrite these tests to invoke that helper. Delete stopCompletelyFromBreakCreatesNothing or drive it through the real handler.

**Evidence:**
```
// Mirrors PomodoroSessionEndView.saveAndDone(): one session construction,
// one insert, one save. The post-save dismissal callback must not
// create a second PomodoroSession.
```

---

## Low

### BC-033 — Scheduled work/break banner survives app quit and fires as a ghost notification later

- [ ] **low** · `Breadcrumb/AppDelegate.swift:105` · found by: concurrency · ✅ Verified real (high confidence)

**Problem:** startWork/startBreak schedule a UNTimeIntervalNotificationTrigger banner for the full phase length. If the user quits Breadcrumb mid-session, the pending request stays registered with the system: applicationWillTerminate only removes the right-click event monitor, and nothing on launch (NotificationService.init / applicationDidFinishLaunching) clears stale pending or delivered requests. The 'Pomodoro finished — break available' banner therefore fires up to 25+ minutes after the app was quit, with action buttons referencing a timer that no longer exists.

**Hypothesis:** Banner cleanup was wired to timer state transitions (stop/pause) but not to app process lifecycle, and pending UNNotificationRequests outlive the process.

**Proposed fix:** Call notificationService-equivalent cleanup in both lifecycle hooks: removePendingNotificationRequests(withIdentifiers: Banner.allIdentifiers) in applicationWillTerminate, and the same in NotificationService.init (or applicationDidFinishLaunching) to clear leftovers from a crash/force-quit.

**Evidence:**
```
func applicationWillTerminate(_ notification: Notification) {
    if let eventMonitor {
        NSEvent.removeMonitor(eventMonitor)
    }
}
```

**Verifier notes:** Confirmed: scheduleBanner (NotificationService.swift:240-274) registers a UNTimeIntervalNotificationTrigger request with the system daemon, which persists after the process exits. applicationWillTerminate (AppDelegate.swift:105-109) only removes the NSEvent monitor, and NotificationService.init (lines 97-110) only sets the delegate and registers categories — grep confirms no pending-request cleanup exists at quit or launch, so a mid-session quit leaves the banner armed to fire up to a full phase length later. Severity low is correctly calibrated.

### BC-034 — Zero coverage: AIService orchestration (provider selection and availability)

- [ ] **low** · `Breadcrumb/Services/AIService.swift:1` · found by: tests-quality · ✅ Verified real (high confidence)

**Problem:** No test constructs AIService (grep finds AIService only as the AIServiceError enum in AIProviderTests). The orchestrator's core decisions — picking local vs OpenRouter from the "ai.provider" UserDefaults key, and reporting availability based on keychain key + model ID presence — are untested. AIProviderTests covers only the value types and error descriptions; OpenRouterProviderTests covers request building and JSON parsing. A regression in backend selection (e.g. defaulting to the wrong provider or mis-reading the key) would not fail any test. The AIExtractButton pipeline (extract -> AIFillerStripper.cleanLines -> BulletText.joinInline) is similarly only tested at the level of its individual pieces, never composed.

**Hypothesis:** AIService reads UserDefaults and keychain directly with no injection seams, so tests were written only for the pure leaf types around it.

**Proposed fix:** Give AIService injectable UserDefaults and a key-lookup closure, then add tests: "ai.provider"="openRouter" with key+model present -> openRouter backend available; missing key -> not configured; unknown raw value -> falls back to local. Optionally add one composed test of the extract->strip->joinInline pipeline using a stub AIProvider.

**Evidence:**
```
grep -rln "AIService(" BreadcrumbTests/ -> no matches
```

**Verifier notes:** AIService( is constructed only in BreadcrumbApp.swift:12; in BreadcrumbTests the string AIService appears solely as AIServiceError in AIProviderTests.swift:38-63 (error description tests). No test exercises resolveProvider's backend selection from the "ai.provider" key or availability resolution from keychain/model-ID presence, matching the report. Low severity is appropriate for a coverage gap.

### BC-035 — Notification action labeled "Stop"/"Stopp" does not stop the timer — it opens the session-end prompt

- [ ] **low** · `Breadcrumb/Services/NotificationService.swift:156` · found by: localization · ✅ Verified real (medium confidence)

**Problem:** The UNNotificationAction with identifier "breadcrumb.action.openSessionEnd" is titled with Strings.Notifications.actionStop ("Stopp"/"Stop"). handleActionIdentifier (line 299) maps it to postAppNotification(.openSessionEnd), which only opens the session-end window/popover; the Pomodoro overtime timer keeps running. The user presses a button labeled "Stop" and the timer does not stop — they must click again inside the prompt.

**Hypothesis:** The action was repurposed from a real stop action into an open-the-prompt action (identifier renamed to openSessionEnd) but the visible title was left as "Stop".

**Proposed fix:** Either rename the title to an honest one (e.g. reuse Strings.Pomodoro.openSessionEndPrompt: "Dialog öffnen"/"Open Prompt"), or make the handler actually call pomodoroTimer.requestStop() in addition to opening the prompt.

**Verifier refinement:** Rename the title (e.g. a new Strings entry like "Dialog öffnen"/"Open Prompt" or "Abschließen"/"Wrap up") rather than calling requestStop(): requestStop() would overwrite pendingSessionEnd from .workDone to .stopped (PomodoroTimer.swift:242-245), changing the session-end prompt to the wrong variant and losing the work-done save flow.

**Evidence:**
```
let openSessionEnd = UNNotificationAction(
    identifier: "breadcrumb.action.openSessionEnd",
    title: Strings.Notifications.actionStop(language),
```

**Verifier notes:** Confirmed: the openSessionEnd action is titled Strings.Notifications.actionStop ("Stopp"/"Stop", Strings.swift:369-371) at NotificationService.swift:156-158, and the handler (:299-300) only posts .openSessionEnd, which AppDelegate.openConfiguredSessionEndPrompt (AppDelegate.swift:134-148) routes to window/popover opening — no timer call. At work expiry PomodoroTimer.tick() enters overtime with isRunning still true (PomodoroTimer.swift:292-298), so the timer keeps counting after "Stop" is pressed. Arguably intentional (the prompt IS the stop flow and overtime records real worked time), hence medium confidence and low severity stands.

### BC-036 — Denied notification permission fails silently — Settings shows banner toggle with no authorization status

- [ ] **low** · `Breadcrumb/Services/NotificationService.swift:262` · found by: notifications-permissions · ✅ Verified real (high confidence)

**Problem:** If the user denies the notification permission (or revokes it in System Settings), requestAuthorization() at line 113 only logs, and scheduleBanner() silently skips adding the request (lines 262-266, logger.info only). SettingsView's Notifications section (Breadcrumb/Views/SettingsView.swift:138-142) still presents the 'show banner notification' toggle as ON with no indication that banners can never appear. Observable symptom: user has banners enabled, sessions end with only a sound (NSSound needs no permission) and never a banner, with zero explanation anywhere in the UI.

**Hypothesis:** Authorization state was treated as a log-only concern; no code path surfaces UNNotificationSettings.authorizationStatus to the UI.

**Proposed fix:** In SettingsView's Notifications section, query UNUserNotificationCenter notification settings (.task on appear) and, when status is .denied while showBannerNotification is true, show a localized hint (new Strings entries for both languages) with a button opening x-apple.systempreferences:com.apple.preference.notifications.

**Verifier refinement:** Proposed fix is sound but incomplete on two points: (1) the UserNotificationCenterClient protocol (NotificationService.swift:6-13) has no settings-query method, so either add `func notificationSettings() async -> UNNotificationSettings` to the protocol and expose an authorizationStatus accessor on NotificationService (keeps the test seam and UserNotifications import out of views), or query UNUserNotificationCenter.current().notificationSettings() directly in SettingsView's .task; (2) re-check on every Settings appearance (.task fires per appearance in the popover, but the breakout window case should also refresh, e.g. on scenePhase/window focus) since the user can revoke permission in System Settings at any time. Show the localized hint (new Strings.Settings entries for both languages) only when status == .denied && showBannerNotification is true, with a Link/Button opening x-apple.systempreferences:com.apple.Notifications-Settings.extension.

**Evidence:**
```
guard granted else {
    logger.info("Skipped Pomodoro banner because notification authorization was not granted: id=\(banner.identifier, privacy: .public)")
    return
}
```

**Verifier notes:** Confirmed: NotificationService.requestAuthorization() (lines 113-122) only logs; scheduleBanner() (lines 262-266) silently skips on denial with logger.info; sendImmediateBanner() (lines 230-237) doesn't check authorization and only logs the thrown error. SettingsView.swift:138-142 shows the banner toggle with no status indication, and a repo-wide grep finds no UNNotificationSettings/authorizationStatus query anywhere (only SFSpeechRecognizer's, unrelated). Sounds play without permission, so the 'sound but never a banner, zero explanation' symptom is exactly what happens.

### BC-037 — SpeechRecognizer session lifecycle races: stale recognition callbacks tear down newer sessions and the permission Task is uncancellable

- [ ] **low** · `Breadcrumb/Services/SpeechRecognizer.swift:110` · found by: concurrency · ✅ Verified real (high confidence)

**Problem:** Low only because the code is currently unreachable (see dead-code finding) — if revived, these are real bugs. (1) The recognition result handler hops to MainActor and calls self.stopListening() on error/isFinal with no session-identity check; cancelling task1 in stopListening() makes SFSpeech deliver an error callback that is enqueued and later tears down a *newer* session: it nils currentBinding after startListening set it, so the new session records with the mic hot but transcribed text silently goes nowhere. (2) startListening's permission Task (line 34) is not stored, so stopListening() cannot cancel it; beginRecognition still runs after a stop and turns the microphone back on (isListening = true) with no guard. (3) Two rapid start taps during the permission window (isListening still false) create two engines; the first AVAudioEngine is overwritten without stop()/removeTap and keeps feeding a never-cancelled recognition task.

**Hypothesis:** Start/stop are modeled as global toggles instead of per-session lifecycles; async permission and callback hops create windows where stale completions act on a newer session's state.

**Proposed fix:** If the service is kept: add a monotonically increasing session ID; capture it in startListening, the permission Task, and the recognition callback, and bail (`guard sessionID == currentSessionID`) before mutating state; store the permission Task and cancel it in stopListening().

**Verifier refinement:** Preferred: delete SpeechRecognizer + DictationButton as dead code (no live caller exists). If kept: add a monotonically increasing sessionID; bump it in BOTH startListening and stopListening; capture it in the permission Task and the recognition callback and guard `sessionID == currentSessionID` before mutating state; store the permission Task and cancel it in stopListening; and in beginRecognition, after the await returns, if the session is stale, stop the freshly created engine and remove its tap before bailing (the engine is already started inside prepareAudioEngine, so a bare guard-return would leak a hot mic).

**Evidence:**
```
Task { @MainActor in
    guard let self else { return }
    ... if hasError || isFinal { self.stopListening() }
```

**Verifier notes:** All three sub-claims hold in /Users/roger/Claude/Code/Breadcrumb/Breadcrumb/Services/SpeechRecognizer.swift. (1) The result handler (lines 106-124) calls self.stopListening() on error/isFinal with no session-identity guard, and stopListening's recognitionTask?.cancel() (line 54) triggers a final error callback; since beginRecognition is guaranteed to suspend at prepareAudioEngine's Task.detached (lines 96, 134), the stale callback can land after a restart sets currentBinding (line 24) and nil it (line 60) while the new engine still starts and sets isListening = true (line 127) — transcription silently writes to a nil binding. (2) The permission Task (line 34) is unstored and beginRecognition has no cancellation/generation check, so an in-flight start completes after a stop and turns the mic back on. (3) Two taps while isListening is still false both skip the line 19-21 stop; the second beginRecognition overwrites audioEngine (line 102) without stop()/removeTap and recognitionTask (line 125) without cancel(), leaving engine A hot and task A live. Reachability premise also verified: DictationButton (the only caller of start/stopListening) is instantiated nowhere — StatusEntryForm.swift:38 and PomodoroSessionEndView.swift:143 use NativeDictationButton, which uses native macOS dictation and never touches SpeechRecognizer — so 'low' severity is correctly calibrated.

### BC-038 — @Query without sort descriptors yields arbitrary, unstable ordering in project picker, archived list, and session-end picker

- [ ] **low** · `Breadcrumb/Views/ProjectPickerView.swift:6` · found by: swiftdata · ✅ Verified real (high confidence)

**Problem:** Three @Query usages fetch projects with a filter but no SortDescriptor: ProjectPickerView.swift:6 (standalone Pomodoro project picker), ArchivedProjectsView.swift:6 (archived list), and PomodoroSessionEndView.swift:28 (project picker in the session-end form). SwiftData returns rows in unspecified store order, so these lists/pickers can present projects in an order that differs from the main list (which sorts by latest activity) and can change between launches or after migrations. The main project list is the only sorted surface.

**Hypothesis:** The sort was implemented in-memory only for ProjectListView; the other three queries were copy-pasted without sort descriptors because small datasets masked the arbitrary ordering.

**Proposed fix:** Add a sort to each query, e.g. @Query(filter: #Predicate<Project> { $0.isActive }, sort: \Project.name) for the pickers and sort: \Project.createdAt (or name) for ArchivedProjectsView, so ordering is deterministic and matches user expectations.

**Verifier refinement:** For the two project pickers (ProjectPickerView, PomodoroSessionEndView), don't sort by \Project.name via SortDescriptor — the main list orders by latest entry timestamp, which is computed over the entries relationship and cannot be expressed in a SortDescriptor. Instead extract ProjectListView's sortedProjects logic into a shared helper (e.g. an extension on [Project]) and apply it in both pickers so ordering matches the main list. For ArchivedProjectsView, @Query(filter:..., sort: \Project.name) is appropriate since archived projects have no activity-based ordering expectation.

**Evidence:**
```
@Query(filter: #Predicate<Project> { $0.isActive })
private var activeProjects: [Project]
```

**Verifier notes:** Confirmed: ProjectPickerView.swift:6-7, ArchivedProjectsView.swift:6-7, and PomodoroSessionEndView.swift:28-29 all use @Query with a filter but no SortDescriptor, and the arrays are rendered directly (ForEach at ProjectPickerView:52, List at ArchivedProjectsView:50, Picker ForEach at PomodoroSessionEndView:123) with no in-memory sort. ProjectListView.swift:20-26 is the only surface that sorts (in-memory by latest entry timestamp), so the three flagged views show SwiftData's unspecified store order. Low severity is correctly calibrated — cosmetic ordering inconsistency, in practice mostly stable rowid order.

### BC-039 — AppDelegate wiring and notification authorization deferred until popover is first opened

- [ ] **low** · `Breadcrumb/BreadcrumbApp.swift:24` · found by: windows-lifecycle · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** appDelegate.windowManager, appDelegate.pomodoroTimer, pomodoroTimer.notificationService, and notificationService.requestAuthorization() are all wired in ContentView's .onAppear inside the MenuBarExtra — which is built lazily on first popover open. Until the user clicks the menu bar icon once per launch: the status-item right-click menu's Settings/About silently no-op (windowManager? is nil in AppDelegate.openSettings/openAbout, AppDelegate.swift:115-121), and the notification permission prompt is deferred (partially mitigated by scheduleBanner re-requesting authorization). The MenuBarLabelView .task already proves the label is the reliable launch-time hook — setOpenWindowAction is registered there.

**Hypothesis:** Service wiring was attached to the most convenient view, overlooking that MenuBarExtra .window content is only instantiated when the popover first opens.

**Proposed fix:** Move the appDelegate/notification wiring from ContentView's .onAppear into MenuBarLabelView's existing .task (the label exists from launch), or perform it in BreadcrumbApp via the label's onAppear. Keep ContentView free of app-wide wiring.

**Evidence:**
```
.onAppear {
    pomodoroTimer.notificationService = notificationService
    notificationService.requestAuthorization()
```

### BC-040 — Session-end window title hardcoded English "Session Complete" — bypasses Strings enum

- [ ] **low** · `Breadcrumb/BreadcrumbApp.swift:59` · found by: windows-lifecycle, localization · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** The Window scene title 'Session Complete' is a hardcoded English string. SessionEndWindowView never sets a navigationTitle (unlike BreakoutWindowView, which localizes every content title), so German users see an English title bar on the session-end window. This violates the project rule that all user-facing text goes through the Strings enum; a suitable localized string already exists (Strings.Pomodoro.sessionEnded, Strings.swift:166).

**Hypothesis:** The static Window(_:id:) initializer requires a compile-time title and nobody added a runtime .navigationTitle override inside the view.

**Proposed fix:** In SessionEndWindowView, inject LanguageManager and add .navigationTitle(Strings.Pomodoro.sessionEnded(languageManager.language)) on the root Group so the localized title overrides the static scene title.

**Evidence:**
```
Window("Session Complete", id: "session-end") {
    SessionEndWindowView()
```

### BC-041 — Zero coverage: migrateStoreIfNeeded one-time store move

- [ ] **low** · `Breadcrumb/BreadcrumbApp.swift:101` · found by: tests-quality · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** migrateStoreIfNeeded (BreadcrumbApp.swift:101, invoked at line 78) moves the SwiftData store from the legacy default.store path to ~/Library/Application Support/Breadcrumb/Breadcrumb.store, including a WAL checkpoint via raw SQLite3 calls. It has no tests and, being a private static method on the App type operating on fixed real paths, cannot be tested as written. A bug here loses the user's entire database on upgrade, and the raw SQLite code is exactly the kind of code that benefits from a fixture test.

**Hypothesis:** The migration was written as a one-shot fix against hardcoded production paths, making it untestable without refactoring, so it shipped verified only manually.

**Proposed fix:** Extract the move logic into a helper taking explicit (sourceURL, destinationURL) parameters, then add a test that builds a small SwiftData store (with WAL files) in a temp directory, runs the helper, and asserts the destination opens with intact records and the source files are gone. Severity is tempered by it being a legacy one-time path.

**Evidence:**
```
migrateStoreIfNeeded(to: storeURL)
...
private static func migrateStoreIfNeeded(to newURL: URL) {
```

### BC-042 — Store-path migration copies the main store file first — a crash mid-migration permanently strands the WAL data

- [ ] **low** · `Breadcrumb/BreadcrumbApp.swift:127` · found by: swiftdata · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** migrateStoreIfNeeded guards on !fileExists(newURL) (line 108) and copies suffixes in order ["", "-wal", "-shm"] — main store first. If the app crashes or is killed after copying Breadcrumb.store but before Breadcrumb.store-wal, the next launch sees the new main file, skips the migration entirely, and opens a store missing its WAL; the old default.store (with the complete data) is silently ignored forever. The sqlite3_wal_checkpoint_v2 call (line 115) mitigates this by flushing the WAL first, but its return code is unchecked — if the checkpoint fails (e.g. the file is locked by a second running instance), un-checkpointed transactions live only in the WAL and are lost in this scenario. Error-path cleanup (lines 140-148) is otherwise correct and keeps sources intact.

**Hypothesis:** The suffix order was written in the natural "main file first" order without considering that the run-once guard keys on the main file's existence, making the main file copy the de-facto commit point of the migration.

**Proposed fix:** Reorder suffixes to ["-shm", "-wal", ""] so the main store file is copied last — an interrupted migration then re-runs cleanly on next launch (after first removing any orphaned -wal/-shm destinations). Additionally check the sqlite3_wal_checkpoint_v2 return code and log on failure.

**Evidence:**
```
let suffixes = ["", "-wal", "-shm"]
...
if fileManager.fileExists(atPath: source.path(percentEncoded: false)) {
    try fileManager.copyItem(at: source, to: destination)
```

### BC-043 — PomodoroSession.startedAt records the session's end time, not its start

- [ ] **low** · `Breadcrumb/Models/PomodoroSession.swift:30` · found by: timer-logic · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** PomodoroSession.init sets startedAt = .now, but all three creation sites (PomodoroSessionEndView.saveWorkSession:172, saveAndDone:210, PomodoroSessionEndHostView.saveCurrentWorkSession:89) construct the record only when the session ends, immediately followed by endedAt = .now. Every persisted session therefore has startedAt ≈ endedAt, and the true start time is lost permanently. Nothing in the UI reads startedAt today (stats use completed/actualDuration only), so the damage is latent — but any future stats feature (sessions per day, timelines) will be built on silently wrong historical data that cannot be repaired.

**Hypothesis:** The model was designed to be created at session start, but the implementation moved session creation into the save handlers at session end without adjusting startedAt.

**Proposed fix:** At save time, back-compute the start: session.startedAt = Date.now.addingTimeInterval(-actualDuration) after computing actualDuration (or capture the real phase start in PomodoroTimer when startWork/startFocusMate runs and pass it through).

**Evidence:**
```
self.id = UUID()
self.startedAt = .now
self.endedAt = nil
```

### BC-044 — AIFillerStripper prefix patterns strip legitimate content that merely starts with a filler-like phrase

- [ ] **low** · `Breadcrumb/Services/AIFillerStripper.swift:162` · found by: ai-system · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** The hasPrefix patterns return "" for ANY string starting with the prefix, discarding real information after it. Provable examples: clean("No planned downtime — deploy on Friday") -> "" (prefix "no planned", line 159); clean("Es ist nichts dokumentiert, Doku nachholen") -> "" (prefix "es ist nichts", line 158); clean("keine weiteren Schritte bis Annas Feedback, dann Kapitel 3") -> "" (prefix "keine weiteren schritte", line 154). This directly contradicts the project's own false-positive bar codified in AIFillerStripperTests.swift:83-117, which requires 'nothing completed because the server was down' and similar contextual sentences to survive — those only survive because they happen to be in the exact-match list, not the prefix list.

**Hypothesis:** Prefix matching was added to catch unlisted exact variants ('keine nächsten Schritte vorhanden.') without bounding how much trailing real content a match may discard.

**Proposed fix:** Only treat a prefix match as filler when the remainder carries no content, e.g. require the string after the prefix to be short (< ~15 chars) and free of letters/digits beyond closing words, or convert the prefixes into anchored full-phrase regexes with a small set of allowed suffixes ('vorhanden', 'definiert', 'identified', '.', '!').

**Evidence:**
```
for prefix in fillerPrefixes {
    if lowered.hasPrefix(prefix) {
        return ""
```

### BC-045 — KeychainHelper.save falls through to SecItemAdd on ANY SecItemUpdate failure, masking the real error as errSecDuplicateItem

- [ ] **low** · `Breadcrumb/Services/KeychainHelper.swift:113` · found by: documents-keychain · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** save(key:data:backend:) calls SecItemUpdate and, on any non-success status, unconditionally tries SecItemAdd. The fallthrough is only correct for errSecItemNotFound. If the item exists but the update fails for another reason (e.g. errSecInteractionNotAllowed while the keychain is locked, or errSecAuthFailed), SecItemAdd then fails with errSecDuplicateItem, and that misleading status is what gets returned in KeychainOperationResult and written to the debug log — hiding the actual root cause. It also makes saveResult report failure for the data-protection backend and fall back to the file-based backend, potentially leaving a stale API key in the preferred backend that read() consults first.

**Hypothesis:** The update-then-add pattern was copied from a common snippet that assumes the only update failure mode is 'item not found', so the status check was omitted.

**Proposed fix:** In save(key:data:backend:), only attempt SecItemAdd when updateStatus == errSecItemNotFound; for any other update failure, return KeychainOperationResult(succeeded: false, status: updateStatus, backend: backend) so the genuine OSStatus is logged and surfaced.

**Evidence:**
```
let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
if updateStatus == errSecSuccess { ... }
var addQuery = query
```

### BC-046 — OpenRouterProvider wraps cancellation into networkError, defeating AIExtractButton's `catch is CancellationError` handling

- [ ] **low** · `Breadcrumb/Services/OpenRouterProvider.swift:18` · found by: ai-system · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** The blanket `catch` around URLSession.shared.data converts every error — including URLError(.cancelled)/CancellationError thrown when AIExtractButton.onDisappear cancels extractionTask — into AIServiceError.networkError(error.localizedDescription). AIExtractButton.extract() explicitly catches `is CancellationError` to treat cancellation as a normal lifecycle event (AIExtractButton.swift:67-68), but for the OpenRouter backend that branch is unreachable: cancellation lands in the generic catch, which sets errorMessage ('Netzwerkfehler: abgebrochen'/'cancelled') and spawns a 4-second dismiss task on a view that is going away. If the overlay is re-shown quickly, a spurious red error is visible.

**Hypothesis:** The catch was written for genuine connectivity failures without considering that task cancellation surfaces through the same URLSession throw.

**Proposed fix:** Before wrapping, rethrow cancellation: `catch is CancellationError { throw CancellationError() } catch let e as URLError where e.code == .cancelled { throw CancellationError() } catch { throw AIServiceError.networkError(error.localizedDescription) }`.

**Evidence:**
```
} catch {
    throw AIServiceError.networkError(error.localizedDescription)
}
```

### BC-047 — Hardcoded English fragments in OpenRouter error payloads reach the UI inside localized wrappers

- [ ] **low** · `Breadcrumb/Services/OpenRouterProvider.swift:58` · found by: ai-system · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** Several user-visible error payloads are hardcoded English and flow into AIExtractButton's red error label through the localized Strings.Errors wrappers, producing mixed-language messages for German users: 'Rate limit exceeded' (line 58, becomes 'Fehler bei der Textgenerierung: Rate limit exceeded'), 'Invalid response' (line 22), 'Could not decode OpenRouter wrapper: ...' (line 81), 'No content in OpenRouter response' (line 85), 'Content not UTF-8' (line 91), 'Could not parse JSON. Got: ...' (line 98). The project rule is that all user-facing text goes through the Strings enum.

**Hypothesis:** Provider-level errors were written as developer diagnostics without realizing AIExtractButton renders error.localizedDescription verbatim to the user.

**Proposed fix:** Add a dedicated AIServiceError case (e.g. .rateLimited) with both languages in Strings.Errors for the 429 path, and route the parse/decode detail strings through Strings.Errors entries (keeping raw snippets only for logging, not for the localized description).

**Evidence:**
```
case 429:
    return .generationFailed("Rate limit exceeded")
```

### BC-048 — German save tooltip says "Sichern" while the button it describes says "Speichern"

- [ ] **low** · `Breadcrumb/Strings.swift:50` · found by: localization · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** Strings.General.saveHint returns "Sichern (⌘↩)" in German, but it is attached (StatusEntryForm.swift:64-67) as the .help tooltip of the button labeled Strings.General.save = "Speichern". The tooltip uses a different German verb than the button it explains; English is consistent ("Save" / "Save (⌘↩)"). All sibling hints (saveAndBreakHint, saveAndStopHint, saveAndDoneHint) repeat the button label exactly.

**Hypothesis:** saveHint was translated independently of the existing save entry, picking the Apple-style "Sichern" instead of the app's established "Speichern".

**Proposed fix:** Change Strings.General.saveHint German value to "Speichern (⌘↩)" and update the matching expectation in StringsTests.swift:202.

**Evidence:**
```
static func saveHint(_ l: AppLanguage) -> String {
    l == .german ? "Sichern (⌘↩)" : "Save (⌘↩)"
}
```

### BC-049 — German default AI system prompt is written without umlauts and is shown to the user in Settings

- [ ] **low** · `Breadcrumb/Strings.swift:528` · found by: localization · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** Strings.AIExtraction.instructions(.german) contains ASCII-substituted German: "Experte fuer" and "als naechstes" instead of "für"/"nächstes". This string is not only sent to OpenRouter (OpenRouterProvider.swift:10) — it is displayed verbatim as the editable default System Prompt in OpenRouterSettingsSection (lines 97-99, 107), so German users see misspelled German in the Settings UI. The sibling prompts lastActionInstructions/nextStepInstructions (lines 549-567) use proper umlauts ("als nächstes"), proving there is no deliberate ASCII-only convention.

**Hypothesis:** The prompt was authored in an ASCII-only context (or by an agent avoiding umlauts in raw strings) and was never normalized when it became user-visible.

**Proposed fix:** Replace "fuer" with "für" and "naechstes" with "nächstes" in the German case of Strings.AIExtraction.instructions. Note the reset-to-default comparison in OpenRouterSettingsSection (line 79) compares against this string, so stored custom prompts are unaffected.

**Evidence:**
```
Du bist ein Experte fuer Projekt-Status-Analyse. Extrahiere aus der Statusmeldung was erledigt ist und was als naechstes geplant ist.
```

### BC-050 — AIExtractButton applies results from stale text and overwrites fields the user edited during generation

- [ ] **low** · `Breadcrumb/Views/AIExtractButton.swift:64` · found by: swiftui-state · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** extract() captures `freeText` at button-press time and, when the (potentially multi-second OpenRouter network) request completes, unconditionally writes AI results into lastAction/nextStep. The free-text view and the optional TextFields remain editable while isGenerating is true (only the extract button is disabled), so anything the user typed into Last step / Next step during generation is silently replaced, and the replacement reflects the old freeText, not what is currently in the field. Symptom: user's manual field edits vanish when the spinner finishes.

**Hypothesis:** The flow assumes the user waits passively during extraction; there is no staleness check between request input and the current binding values at completion.

**Proposed fix:** Snapshot freeText before the request and on completion only apply results if `freeText == snapshot` (or merge per-field: skip writing a field the user modified during the request, comparing against pre-request values). Alternatively disable the optional fields while isGenerating.

**Evidence:**
```
let result = try await aiService.extractStatus(from: freeText, language: language)
applyResult(lastAction: result.lastAction, nextStep: result.nextStep)
```

### BC-051 — Stale errorDismissTask is never cancelled, so an old 4s timer can clear a newer error message almost immediately

- [ ] **low** · `Breadcrumb/Views/AIExtractButton.swift:71` · found by: ai-system, swiftui-state · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** extract() assigns a fresh errorDismissTask on each failure without cancelling the previous one, and a new extraction attempt clears errorMessage but leaves any pending dismiss task running. Sequence: extraction fails at t=0 (dismiss scheduled t=4); user retries at t=3.5; second failure shows a new error at t=3.8; the OLD task fires at t=4 and blanks the new message after 0.2s instead of 4s. The user sees the second error flash and vanish.

**Hypothesis:** The dismiss timer was added as fire-and-forget without tying its lifetime to the message it dismisses.

**Proposed fix:** Cancel before replacing: call errorDismissTask?.cancel() at the start of extract() and before assigning a new task in the catch block; inside the task, return early if Task.isCancelled before nilling errorMessage (Task.sleep already throws on cancel, so `try? await ...; guard !Task.isCancelled else { return }`).

**Evidence:**
```
errorDismissTask = Task {
    try? await Task.sleep(for: .seconds(4))
    errorMessage = nil
}
```

### BC-052 — Archived-project actions are reachable only via right-click context menu

- [ ] **low** · `Breadcrumb/Views/ArchivedProjectsView.swift:57` · found by: ui-views · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** Reactivate and Permanently Delete exist solely inside a .contextMenu on a plain HStack row. There is no visible affordance (button, menu, or hint text) that the row is interactable, and the row is not a Button, so keyboard/VoiceOver users have no obvious path to these actions. HIG guidance is that context menus expose shortcuts to actions available elsewhere, not be the sole access point. The deletion itself is properly confirmed via confirmationDialog — only discoverability is broken.

**Hypothesis:** The view was built quickly mirroring the document rows' context-menu pattern without adding a visible affordance.

**Proposed fix:** Add visible controls to the row, e.g. an ellipsis Menu or a hover-revealed 'Reactivate' button (Button(Strings.Projects.reactivate(l), systemImage: "arrow.uturn.left")), keeping the context menu as a shortcut.

**Evidence:**
```
.contextMenu {
    Button(Strings.Projects.reactivate(languageManager.language), systemImage: "arrow.uturn.left") {
```

### BC-053 — Add File silently does nothing when bookmark creation fails — error swallowed, no user feedback

- [ ] **low** · `Breadcrumb/Views/DocumentListView.swift:190` · found by: documents-keychain · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** addFileViaPanel() creates the bookmark with try? and bails out with a bare return on failure. The user picks a file in the NSOpenPanel (after the popover has already been hidden via NSApp.keyWindow?.orderOut(nil) on line 185), the panel closes, and nothing appears in the document list — no error message, no log line. Bookmark creation can fail for files on volumes that don't support bookmarks (some network/FUSE mounts, iCloud placeholders), making the 'Add File' feature look broken with zero diagnostics.

**Hypothesis:** try? was used as a shortcut during rapid prototyping; the failure path was never exercised because local APFS files always succeed.

**Proposed fix:** Replace try? with do/catch: on failure, at minimum print/log the error (matching the saveWithLogging convention), and ideally show a localized error row or alert via a new Strings.Documents entry so the user knows the link was not created.

**Evidence:**
```
guard let bookmarkData = try? url.bookmarkData() else { return }
```

### BC-054 — Footer Pomodoro button is a bare tomato emoji — VoiceOver reads "tomato"

- [ ] **low** · `Breadcrumb/Views/FooterView.swift:22` · found by: ui-views · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** The standalone-Pomodoro footer button's only label is Text("🍅"). Unlike its siblings, which use Button(title, systemImage:) + .labelStyle(.iconOnly) so VoiceOver gets a meaningful title, this button is announced as the emoji's name ('tomato'), which says nothing about starting a focus timer. The .help tooltip does not fix VoiceOver output.

**Hypothesis:** The emoji was chosen to match the menu bar's 🍅 timer glyph without considering the accessibility tree.

**Proposed fix:** Either add .accessibilityLabel(Strings.Pomodoro.pomodoro(languageManager.language)) to the button, or use the same pattern as the other footer buttons: Button(Strings.Pomodoro.pomodoro(l), systemImage: "timer") { … }.labelStyle(.iconOnly).

**Evidence:**
```
Button(action: onStartStandalonePomodoro) {
    Text("🍅")
        .font(.callout)
```

### BC-055 — HistoryView builds Binding(get:set:) in body for the delete confirmationDialog and reads the same state in the action

- [ ] **low** · `Breadcrumb/Views/HistoryView.swift:86` · found by: swiftui-state · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** The delete confirmation uses an ad-hoc `Binding(get: { entryToDelete != nil }, set: { if !$0 { entryToDelete = nil } })` constructed inside body, and the destructive action then reads `if let entry = entryToDelete`. This is the exact pattern the project's SwiftUI guidance flags: the dialog's dismissal path nils the same state the action depends on, so correctness relies on SwiftUI invoking the action before the binding's set(false) — an ordering that has regressed across OS releases for alerts/dialogs. If the ordering ever flips, delete becomes a silent no-op. ProjectDetailView's equivalent dialog uses a plain $showDeleteConfirmation Bool, so the file is also internally inconsistent.

**Hypothesis:** An item-driven dialog was emulated with a hand-rolled binding instead of using the presenting:-based confirmationDialog overload designed for this.

**Proposed fix:** Use `confirmationDialog(_:isPresented:titleVisibility:presenting:actions:message:)` with `presenting: entryToDelete` and a separate `@State private var showDeleteConfirmation = false`, so the entry is handed to the action closure directly instead of being re-read from state that the dismissal mutates.

**Evidence:**
```
isPresented: .init(
    get: { entryToDelete != nil },
    set: { if !$0 { entryToDelete = nil } }
```

### BC-056 — Menu bar timer label width jitters — digits not monospaced

- [ ] **low** · `Breadcrumb/Views/MenuBarLabelView.swift:18` · found by: windows-lifecycle · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** The running-timer label renders pomodoroTimer.menuBarLabel (e.g. "🍅 24:59") as plain Text. SF's default figures are proportional, so the label width changes slightly every second as digits change (and jumps when minutes drop from two digits to one, e.g. 10:00 → 9:59), nudging neighboring menu bar items. The in-popover countdown already handles this with design: .monospaced (PomodoroRunningView.swift:22), but the menu bar Text does not.

**Hypothesis:** Monospacing was applied to the large popover countdown but forgotten on the menu bar label added later in commit 0e1aa1e.

**Proposed fix:** Add .monospacedDigit() to the Text in MenuBarLabelView (and optionally zero-pad minutes in PomodoroTimer.formattedTime) so the label keeps a constant width per phase.

**Evidence:**
```
Text(pomodoroTimer.menuBarLabel(languageManager.language))
```

### BC-057 — FocusMate end-time and start-time grid use system-locale time format, mixing languages with localized labels

- [ ] **low** · `Breadcrumb/Views/PomodoroConfigView.swift:83` · found by: localization · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** `endTime.formatted(date: .omitted, time: .shortened)` (also line 123 for the start-time grid buttons, and PomodoroRunningView.swift:125 for the running-phase label) formats with Locale.current. With app language German on an English-locale system this renders "Endet um 2:30 PM" instead of "Endet um 14:30" (and vice versa for English app on a German system). Same root cause as the SmartTimestampView finding but in the Pomodoro config/running UI.

**Hypothesis:** Same assumption as SmartTimestampView: FormatStyle's implicit Locale.current was assumed to match the in-app language setting.

**Proposed fix:** Apply an explicit locale derived from AppLanguage: `endTime.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(appLocale))` in PomodoroConfigView (lines 83, 123) and PomodoroRunningView (line 125), ideally via a shared helper like `AppLanguage.locale`.

**Evidence:**
```
Text(Strings.Pomodoro.focusMateEndsAt(l, time: endTime.formatted(date: .omitted, time: .shortened)))
```

### BC-058 — Edit-status pencil button is icon-only with no accessible text label

- [ ] **low** · `Breadcrumb/Views/ProjectDetailView.swift:237` · found by: ui-views · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** The edit button in the Current Status header uses a bare Image(systemName: "pencil") as its label. VoiceOver announces only the symbol's generic name rather than 'Edit status' (which exists in Strings.Status.editStatus and is already used for the .help tooltip). Every other icon button in the app uses the Button(title, systemImage:) + .labelStyle(.iconOnly) pattern; this one is the outlier.

**Hypothesis:** The button was added with the edit-latest-entry feature using a raw Image label instead of the project's established labeled-icon-button pattern.

**Proposed fix:** Replace the label with Button(Strings.Status.editStatus(languageManager.language), systemImage: "pencil") { … }.labelStyle(.iconOnly) (keeping the font/foregroundStyle modifiers), or add .accessibilityLabel(Strings.Status.editStatus(l)).

**Evidence:**
```
} label: {
    Image(systemName: "pencil")
        .font(.caption)
```

### BC-059 — Project list sort recomputes latestEntry inside the comparator — faults every entry of every project repeatedly per render

- [ ] **low** · `Breadcrumb/Views/ProjectListView.swift:21` · found by: swiftdata · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** Project.latestEntry (Breadcrumb/Models/Project.swift:32-34) is a computed property that materializes the full entries relationship and linearly scans it with max(by:). ProjectListView.sortedProjects calls it inside the sort comparator for both p1 and p2, i.e. it is re-evaluated O(P log P) times per body evaluation, each evaluation re-scanning all of that project's status entries. The popover body re-evaluates on every animation/observation change, so with months of accumulated StatusEntry rows this loads and scans the entire entry graph repeatedly just to derive one timestamp per project. ProjectRowView then calls project.latestEntry again per row.

**Hypothesis:** Convenience computed property reused in a hot sort path; works fine at demo scale and degrades linearly with entry history because there is no denormalized last-updated timestamp or per-render memoization.

**Proposed fix:** Cheapest fix: in sortedProjects, precompute the timestamp once per project before sorting (e.g. map to (project, latestEntry?.timestamp ?? createdAt) pairs, sort the pairs, then extract projects). Structurally better: maintain a lastEntryAt: Date property on Project updated whenever an entry is saved (would require a V3 schema version), letting the list sort without touching the entries relationship at all.

**Evidence:**
```
activeProjects.sorted { p1, p2 in
    let t1 = p1.latestEntry?.timestamp ?? p1.createdAt
    let t2 = p2.latestEntry?.timestamp ?? p2.createdAt
```

### BC-060 — Clearing the API key stores an empty string in the keychain; KeychainHelper.delete is never called from production code

- [ ] **low** · `Breadcrumb/Views/Settings/OpenRouterSettingsSection.swift:114` · found by: documents-keychain · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** saveAPIKeyIfNeeded() always routes through KeychainHelper.saveResult, even when the user empties the SecureField to remove their key. The result is a generic-password item 'openrouter.apiKey' with empty data left in the keychain forever instead of being deleted. AIService.makeProvider tolerates it (it checks !apiKey.isEmpty at AIService.swift:122), so functionality is unaffected, but the secret slot is never actually removable, and KeychainHelper.delete(key:) (KeychainHelper.swift:95) has no production caller at all — it is exercised only by tests.

**Hypothesis:** The save path was written for the happy path of entering a key; the 'remove key' flow was never designed, so delete() was left as test-only API.

**Proposed fix:** In saveAPIKeyIfNeeded(), when apiKey.trimmingCharacters(in: .whitespaces).isEmpty, call KeychainHelper.delete(key: "openrouter.apiKey") (treating success as saved) instead of saving an empty value; keep saveResult for non-empty values.

**Evidence:**
```
let result = KeychainHelper.saveResult(key: "openrouter.apiKey", value: apiKey)
```

### BC-061 — SmartTimestampView's "Today HH:mm" label goes stale across midnight

- [ ] **low** · `Breadcrumb/Views/SmartTimestampView.swift:32` · found by: ui-views · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** formattedDate compares against Date.now / Calendar.isDateInToday at body-evaluation time, but nothing ever re-invalidates the view on a time basis. MenuBarExtra content stays alive between popover openings, so an entry stamped 'Heute 23:50' continues to read 'Heute …' the next day until some unrelated state change forces a re-render. The relative mode (Text(date, style: .relative)) self-updates, making the inconsistency visible when toggling.

**Hypothesis:** Day-relative formatting was implemented as a pure computed string with no TimelineView or timer to re-evaluate it when the calendar day rolls over.

**Proposed fix:** Wrap the absolute label in TimelineView(.everyMinute) { context in ... } and compute formattedDate from context.date instead of Date.now, so the Today/elsewhen branch re-evaluates over time.

**Evidence:**
```
if calendar.isDateInToday(date) {
    let timeString = date.formatted(.dateTime.hour().minute())
    return "\(Strings.General.today(languageManager.language)) \(timeString)"
```

### BC-062 — Stats window renders focus time at fixed 48pt — long German strings overflow the 400pt min window width

- [ ] **low** · `Breadcrumb/Views/StatsContentView.swift:25` · found by: ui-views · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** formattedFocusTime returns strings like "12 Std. 45 Min." once hours accumulate, rendered with .font(.system(size: 48, weight: .medium)) next to a second 48pt column plus 40pt spacing. BreakoutWindowView allows the stats window down to 400pt wide (line 56), where the hours+minutes string alone exceeds the available width, forcing ugly mid-string wrapping. The hardcoded size also ignores the system text-size setting.

**Hypothesis:** The 48pt hero number was designed against the short sessions count and the minutes-only focus time, not the hours+minutes German format.

**Proposed fix:** Use a scalable text style (e.g. .font(.largeTitle)) or add .minimumScaleFactor(0.5).lineLimit(1) to the focus-time Text so the value scales down instead of wrapping at minimum window size.

**Evidence:**
```
Text(project.formattedFocusTime(languageManager.language))
    .font(.system(size: 48, weight: .medium))
```

### BC-063 — StatusEntryForm trims only .whitespaces — newline-only input passes validation and trailing newlines are persisted

- [ ] **low** · `Breadcrumb/Views/StatusEntryForm.swift:86` · found by: swiftui-state · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** Both the Save button gate (line 68) and save() use `trimmingCharacters(in: .whitespaces)`, which strips spaces/tabs but NOT newlines. The input is a multi-line NSTextView (PlaceholderTextView) where Return inserts \n, so a user who only presses Return gets an enabled Save button and can persist a StatusEntry whose freeText is just "\n" (renders as a blank current-status block in ProjectDetailView). Real entries also keep trailing newlines (e.g. "done.\n"), adding stray blank lines wherever the entry is displayed. The same pattern repeats in PomodoroSessionEndView.swift lines 183 and 221.

**Hypothesis:** The validation was written for single-line TextFields and not revisited when the multi-line NSTextView became the input; .whitespaces vs .whitespacesAndNewlines mixup.

**Proposed fix:** Use `.whitespacesAndNewlines` in all four places (StatusEntryForm lines 68 and 86; PomodoroSessionEndView lines 183 and 221).

**Evidence:**
```
let trimmed = freeText.trimmingCharacters(in: .whitespaces)
guard !trimmed.isEmpty else { return }
```

### BC-064 — Zero coverage: WindowManager and session-end presentation routing

- [ ] **low** · `Breadcrumb/WindowManager.swift:1` · found by: tests-quality · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** Grep across BreadcrumbTests/ finds no reference to WindowManager or SessionEndPresentation. WindowManager owns breakout-window content routing, NSApp activation-policy switching, and session-end window lifecycle — all pure @MainActor state-machine logic that is unit-testable without UI. The .window vs .menuBar session-end presentation routing (a user-facing setting) is likewise only covered at the level of its translated strings (StringsTests.swift:88-102), which would pass even if the routing itself were broken.

**Hypothesis:** Window/scene-adjacent code was assumed untestable because it touches NSApp, so no seam was created for the routable state.

**Proposed fix:** Add a small @MainActor test suite asserting WindowManager.open(_:) sets currentContent correctly, repeated opens replace content, and close resets state; abstract the NSApp.setActivationPolicy call behind an injectable closure to assert .regular/.accessory transitions. Add a test that SessionEndPresentation(rawValue:) round-trips the stored "pomodoro.sessionEndPresentation" values.

**Evidence:**
```
grep -rln "WindowManager\|SessionEndPresentation" BreadcrumbTests/ -> no matches
```

### BC-065 — KeychainHelperTests writes into the production keychain service with no failure-safe cleanup

- [ ] **low** · `BreadcrumbTests/KeychainHelperTests.swift:8` · found by: tests-quality · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** KeychainHelper hardcodes service "com.roger.breadcrumb" (Breadcrumb/Services/KeychainHelper.swift:27), so every test in this file creates real items in the user's keychain under the app's production service. Cleanup is done with trailing delete statements at the end of each test body rather than defer/teardown, so any crash or early abort between save and the trailing delete leaves stale items in the user's real keychain (mitigated only by the leading delete on the next run). The account names are test-specific, so app data is not corrupted, but the user's keychain accumulates test artifacts on aborted runs.

**Hypothesis:** KeychainHelper exposes no way to parametrize the service name, so tests reused the production service and relied on distinct account keys plus trailing deletes.

**Proposed fix:** Move each trailing KeychainHelper.delete(key:) into a defer immediately after the initial delete in every test; longer term, allow KeychainHelper's service to be overridden for tests (e.g. an internal static var or test-only parameter) so test items never live under the production service.

**Evidence:**
```
private let testKey = "com.roger.breadcrumb.test.keychainHelper"
...
KeychainHelper.delete(key: testKey)  // trailing cleanup, skipped on abort
```

### BC-066 — Keychain regression test silently passes when seeding fails, voiding the f0a27f7 regression guard

- [ ] **low** · `BreadcrumbTests/KeychainHelperTests.swift:90` · found by: tests-quality · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** saveCleansUpOtherBackend is the regression test for the cross-backend keychain cleanup behavior. If either saveForTesting seed call fails, the guard at lines 90-93 deletes the key and returns — and since a Swift Testing test with no recorded issue passes, the suite reports green without having exercised the regression at all. Seeding failures are most likely on exactly the machines/configurations where the original keychain bug manifested, so the test can be permanently inert while appearing to pass.

**Hypothesis:** The early return was added to avoid failures on machines where the file-based keychain backend prompts or errors, trading visibility for convenience.

**Proposed fix:** Replace the silent guard with try #require(dataProtectionSeed.succeeded) and try #require(fileBasedSeed.succeeded) (cleanup moved to a defer right after the first delete), or gate the whole test with .enabled(if:) evaluating seedability so skips are reported as skips, not passes.

**Evidence:**
```
guard dataProtectionSeed.succeeded, fileBasedSeed.succeeded else {
    KeychainHelper.delete(key: crossBackendKey)
    return
}
```

### BC-067 — playSound tests hijack the real UNUserNotificationCenter delegate and contain no assertions

- [ ] **low** · `BreadcrumbTests/NotificationServiceTests.swift:21` · found by: tests-quality · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** playSoundDoesNotCrash, playSoundEmptyString, and playSoundInvalidName (lines 19-39) construct NotificationService() with default arguments, which uses UNUserNotificationCenter.current() of the hosted app: each construction reassigns the real center's delegate to a short-lived test instance and re-registers the live notification categories (NotificationService.swift:108-109), clobbering the host app's notification wiring mid-run. playSoundDoesNotCrash also audibly plays the 'Glass' system sound on the developer's machine on every test run. All three tests contain zero #expect — they only verify 'no crash', which an optional-chained NSSound call cannot produce anyway.

**Hypothesis:** Smoke tests were generated to pad coverage for the sound API without injecting the mock center the rest of the file already uses.

**Proposed fix:** Pass RecordingUserNotificationCenter (and an injected UserDefaults) to these constructions; to make the tests meaningful, put sound playback behind an injectable closure or protocol on NotificationService and assert it was/wasn't invoked with the expected name — or delete the three tests.

**Evidence:**
```
let service = NotificationService()
// "Glass" is a real macOS system sound
service.playSound(named: "Glass")
```

### BC-068 — Sleep-based synchronization (50 ms) for unstructured notification Tasks

- [ ] **low** · `BreadcrumbTests/NotificationServiceTests.swift:173` · found by: tests-quality · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** notifyWorkDonePostsImmediateBanner, notifyBreakDonePostsImmediateBanner, and notifyWorkDoneSkipsBannerWhenDisabled (lines 172-173, 193-194, 214-215) use 'await Task.yield()' plus 'try await Task.sleep(for: .milliseconds(50))' to wait for the fire-and-forget Task spawned inside NotificationService.sendImmediateBanner (Breadcrumb/Services/NotificationService.swift:230). This is wall-clock synchronization: it adds 150 ms of dead time per run and the disabled-case test asserts absence after an arbitrary delay, which passes vacuously if the work is merely slow. scheduleBanner already returns its Task for tests to await; sendImmediateBanner does not.

**Hypothesis:** sendImmediateBanner was written fire-and-forget, so the tests had nothing to await and fell back to sleeping.

**Proposed fix:** Make sendImmediateBanner return its Task (discardable, same pattern as scheduleBanner at NotificationService.swift:240) and have notifyWorkDone/notifyBreakDone return it too; tests then 'await task?.value' instead of yielding and sleeping.

**Evidence:**
```
await Task.yield()
try await Task.sleep(for: .milliseconds(50))
let request = try #require(center.addedRequests.first)
```

### BC-069 — SessionDurationTests re-implements the duration formula instead of testing the code that uses it

- [ ] **low** · `BreadcrumbTests/SessionDurationTests.swift:29` · found by: tests-quality · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** The three 'Duration formula' tests (lines 21-61) and focusMateDurationUsesPhase (lines 74-88) compute 'completed' and 'actualDuration' with expressions written inside the test, then assert arithmetic on them. The real formula lives in PomodoroSessionEndView.swift:179 and PomodoroSessionEndHostView.swift:96; if either view's formula regresses (e.g. drops overtimeSeconds, or FocusMate goes back to originalDurationSeconds — the exact bug line 86's 'wrongDuration' documents), these tests still pass. Additionally breakToSessionEnded (lines 9-19) duplicates PomodoroTimerTests.breakStillEndsAtZero (PomodoroTimerTests.swift:240-250) almost verbatim.

**Hypothesis:** The duration computation is embedded in SwiftUI view methods, so an agent validated its arithmetic in isolation rather than extracting the computation to a testable location.

**Proposed fix:** Move the duration/completion computation onto PomodoroTimer (e.g. var currentSessionActualDuration: TimeInterval and var currentSessionCompleted: Bool), use those from both session-end views, and point these tests at the real properties. Delete breakToSessionEnded as a duplicate.

**Evidence:**
```
let completed = timer.remainingSeconds <= 0
let actualDuration = TimeInterval(timer.originalDurationSeconds - timer.remainingSeconds + timer.overtimeSeconds)
```

### BC-070 — Microphone/speech permission usage descriptions are English-only with no Info.plist localization

- [ ] **low** · `project.yml:23` · found by: localization · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** NSMicrophoneUsageDescription and NSSpeechRecognitionUsageDescription are hardcoded English sentences, and the project contains no .lproj folders, no InfoPlist.strings, and no .xcstrings catalogs (verified by find). When dictation is enabled on a German-locale Mac, the system permission dialogs show the English explanation text in an otherwise German experience — the app's default language is German.

**Hypothesis:** The bilingual system was built entirely around the runtime Strings enum; system-surface strings that can only be localized through bundle resources were overlooked.

**Proposed fix:** Add an InfoPlist.strings (or .xcstrings) resource with a de localization for both usage-description keys and register it in project.yml so xcodegen includes it in the bundle.

**Evidence:**
```
NSMicrophoneUsageDescription: "Breadcrumb uses the microphone for speech-to-text in status updates."
NSSpeechRecognitionUsageDescription: "Breadcrumb uses speech recognition to transcribe your status updates."
```

---

## Cleanup / Dead Code

### BC-071 — AppDelegate right-click status-item menu is dead code on macOS 27 (known) - plus its private openSettings/openAbout targets

- [ ] **cleanup** · `Breadcrumb/AppDelegate.swift:17` · found by: dead-code, windows-lifecycle · ✅ Verified real (high confidence)

**Problem:** The NSEvent local monitor for .rightMouseDown on the status bar window (lines 17-61) never fires on macOS 27 because right-clicks are no longer delivered to menu bar status items (already tracked; the in-popover overflow menu in FooterView is the replacement). The @objc openSettings/openAbout methods (lines 115-121) are referenced only by this dead menu's selectors, and the eventMonitor teardown in applicationWillTerminate exists only for it.

**Hypothesis:** OS behavior change made the feature inert; the workaround (FooterView ⋯ menu) was added without removing the obsolete monitor.

**Proposed fix:** Delete the eventMonitor property, the addLocalMonitorForEvents block (17-61), the removeMonitor call in applicationWillTerminate (106-108), and the @objc openSettings/openAbout methods (115-121). Keep the NotificationCenter observers that are still live.

**Evidence:**
```
eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { event in
    guard let window = event.window, window.level == .statusBar else { ... }  // never fires on macOS 27
```

**Verifier notes:** Confirmed dead code (already-tracked OS behavior, flagged here for removal as instructed): grep shows openSettings/openAbout are referenced only by the dead right-click menu's #selectors at AppDelegate.swift:31 and 39, and eventMonitor exists solely for the .rightMouseDown monitor (lines 17-61) plus its teardown (lines 106-108). The proposed deletion correctly preserves the live NotificationCenter observers (.openPopover, .openSessionEnd, .pomodoroStartBreak, .pomodoroNextSession) at lines 63-101; line references in the finding match the working tree.

### BC-072 — PomodoroTimer.enterOvertime() and didCrossZero are dead code (test-only)

- [ ] **cleanup** · `Breadcrumb/PomodoroTimer.swift:197` · found by: concurrency, timer-logic · ✅ Verified real (high confidence)

**Problem:** enterOvertime() is never called from app code — overtime is entered automatically inside tick() (line 294) and 'Continue working' only calls clearPendingSessionEnd(); the sole caller is PomodoroTimerTests.swift:436. Likewise didCrossZero (line 41) is written in six places in the timer but never read by any app code — only test assertions read it. Both are leftover scaffolding that complicates the state machine (enterOvertime also zeroes phaseDurationSeconds, a different overtime model than tick()'s, which would silently diverge if anyone ever wired it up).

**Hypothesis:** An earlier design required a manual 'enter overtime' action and a crossed-zero flag for the UI; the auto-overtime tick() path replaced them but the API and tests were left behind.

**Proposed fix:** Delete enterOvertime() and the didCrossZero property plus all its assignments, and remove/rewrite the corresponding tests in PomodoroTimerTests.swift (lines 263-282, 436, 571-577).

**Evidence:**
```
func enterOvertime() {
    pendingSessionEnd = nil
    isOvertime = true
```

**Verifier notes:** Confirmed by grep across the repo: enterOvertime() has exactly one caller, BreadcrumbTests/PomodoroTimerTests.swift:436; didCrossZero is declared at PomodoroTimer.swift:41, assigned in six places (129, 154, 171, 213, 261, 295), and read only in test assertions (PomodoroTimerTests.swift:136, 235, 263-282, 571-577). No view or service code references either symbol; overtime is entered automatically in tick() (294-298) and 'continue' goes through clearPendingSessionEnd(). The note that enterOvertime() zeroes phaseDurationSeconds (line 202), a divergent overtime model from tick()'s, is also accurate.

### BC-073 — AIService generate()/stream() APIs are unused, and stream() has an isGenerating clobber if ever used

- [ ] **cleanup** · `Breadcrumb/Services/AIService.swift:143` · found by: concurrency, ai-system, dead-code · ✅ Verified real (high confidence)

**Problem:** No app or test code calls AIService.generate(prompt:instructions:), generate(...generating:), or either stream(...) overload — the only used entry point is extractStatus (via AIExtractButton). That is ~115 lines (141-253) of FoundationModels plumbing kept compiled for nothing. As a latent concurrency note: stream() sets isGenerating = true synchronously and resets it in the Task's defer; two overlapping streams (or a stream overlapping extractStatus) would reset the shared flag while the other is still running, and isGenerating stays true even if the returned stream is never iterated until the producer task finishes on its own.

**Hypothesis:** Speculative API surface added for future features (e.g. summaries) that never materialized; CLAUDE.md itself notes these are 'used only by extraction currently'.

**Proposed fix:** Delete the generate() and both stream() methods (and mapError if it then becomes single-use inline). If kept intentionally for the planned PCC provider work, replace the boolean isGenerating with an active-operation counter so concurrent operations don't clobber each other.

**Verifier refinement:** Delete both generate() and both stream() overloads. Do NOT delete mapError if finding 45's fix is applied, since extractStatus should start using it; otherwise mapError becomes dead too and should go with them.

**Evidence:**
```
isGenerating = true
let (stream, continuation) = AsyncThrowingStream.makeStream(of: String.self)
let task = Task {
    defer { self.isGenerating = false }
```

**Verifier notes:** Repo-wide grep finds zero callers of any generate()/stream() overload; only extractStatus is used (AIExtractButton.swift:64). Lines 141-253 plus mapError (290-305, called only at 155/180/211/247) are dead. The isGenerating clobber is accurate as a latent note: stream() sets the flag synchronously (197, 232) and resets it in the producer Task's defer (200, 235), shared with extractStatus's set/defer (134-135).

### BC-074 — notifyWorkDone/notifyBreakDone and sendImmediateBanner have no production callers since e2dbc98

- [ ] **cleanup** · `Breadcrumb/Services/NotificationService.swift:187` · found by: notifications-permissions, concurrency, dead-code · ✅ Verified real (high confidence)

**Problem:** Commit e2dbc98 changed PomodoroTimer.tick() to call only playWorkDoneFeedback/playBreakDoneFeedback (sound) and rely exclusively on the pre-scheduled banners; this is also why add90fa's cancelScheduledBanners-in-tick fix was correctly removed — the duplicate-banner scenario no longer exists by design. But notifyWorkDone (line 187), notifyBreakDone (line 199), and sendImmediateBanner (line 213) were left behind, now only exercised by tests (BreadcrumbTests/NotificationServiceTests.swift:161-218) and required by the PomodoroNotificationScheduling protocol (lines 39-40), forcing the PomodoroTimerTests spy (line 624-628) to implement them too. Also dead: the unused 'language' parameters on playWorkDoneFeedback/playBreakDoneFeedback.

**Hypothesis:** The immediate-banner path was the pre-add90fa design; the refactor to scheduled-only banners removed the callers but not the methods, protocol requirements, or their tests.

**Proposed fix:** Remove notifyWorkDone/notifyBreakDone/sendImmediateBanner from NotificationService and from the PomodoroNotificationScheduling protocol, delete the corresponding tests and spy methods, and drop the unused language parameters from the play*Feedback methods.

**Verifier refinement:** As proposed, plus also delete Strings.Notifications.actionStartBreak (Strings.swift:360-362), which grep shows has no references — it belongs to the same dead immediate-banner/startBreak generation (overlaps with finding 14).

**Evidence:**
```
func notifyWorkDone(language: AppLanguage) {
    playWorkDoneFeedback(language: language)
    sendImmediateBanner(.workDone(.breakAvailable), language: language)
}
```

**Verifier notes:** Grep confirms zero production callers: notifyWorkDone (:187), notifyBreakDone (:199) and private sendImmediateBanner (:213) are referenced only by the protocol (:39-40), NotificationServiceTests.swift:161-218, and the PomodoroTimerTests spy (:624-631). PomodoroTimer.tick() calls only playWorkDoneFeedback/playBreakDoneFeedback (PomodoroTimer.swift:298,308,310), and the language parameter is unused in both play* bodies (:182-185, :194-197).

### BC-075 — Dead notification-action plumbing: startBreak action never registered, .pomodoroStartBreak and .openPopover observers never triggered

- [ ] **cleanup** · `Breadcrumb/Services/NotificationService.swift:301` · found by: notifications-permissions, swiftdata, windows-lifecycle, dead-code · ✅ Verified real (high confidence)

**Problem:** handleActionIdentifier handles 'breadcrumb.action.startBreak', but no UNNotificationCategory registers an action with that identifier (registerCategories only creates nextSession, continueWorking, openSessionEnd), so the branch is unreachable and .pomodoroStartBreak is never posted from anywhere in the app. Consequently the AppDelegate observer for .pomodoroStartBreak (Breadcrumb/AppDelegate.swift:83-91) never fires. Similarly, Notification.Name.openPopover is never posted by any code (the legacy 'breadcrumb.action.openPopover' identifier maps to .openSessionEnd, not .openPopover), so the AppDelegate observer at lines 63-71 is also dead.

**Hypothesis:** Earlier iterations (ca4a8ed/bc6e1d2) had a 'start break' banner action and an open-popover route; later redesigns removed the actions but left the routing and observers in place.

**Proposed fix:** Delete the 'breadcrumb.action.startBreak' case from handleActionIdentifier, the .pomodoroStartBreak and .openPopover Notification.Name definitions, and both corresponding NotificationCenter observers in AppDelegate.applicationDidFinishLaunching (keep openMenuBarPopover itself — openConfiguredSessionEndPrompt uses it). Remove the matching tests.

**Verifier refinement:** As proposed, plus remove the now-orphaned Strings.Notifications.actionStartBreak (Strings.swift:360-362) and the NotificationServiceTests assertion exercising the startBreak branch if one exists.

**Evidence:**
```
case "breadcrumb.action.startBreak":
    postAppNotification(.pomodoroStartBreak)
```

**Verifier notes:** registerCategories (:144-177) registers only nextSession, continueWorking, and openSessionEnd actions, so the "breadcrumb.action.startBreak" case at :301-302 is unreachable and .pomodoroStartBreak is posted nowhere else; the AppDelegate observer at AppDelegate.swift:83-91 is dead. Notification.Name.openPopover (AppDelegate.swift:4) is never posted anywhere (the legacy "breadcrumb.action.openPopover" identifier maps to .openSessionEnd at :299-300), so the observer at :63-71 is also dead. openMenuBarPopover itself is live (used by openConfiguredSessionEndPrompt :143,146), as the finding correctly notes.

### BC-076 — Entire custom dictation stack is dead: DictationButton and SpeechRecognizer are no longer used by any view

- [ ] **cleanup** · `Breadcrumb/Views/DictationButton.swift:3` · found by: notifications-permissions, concurrency, swiftui-state, dead-code, dead-code, ui-views · ✅ Verified real (high confidence)

**Problem:** Commits fcc1e94/e1619a8 replaced DictationButton with NativeDictationButton in both call sites (Breadcrumb/Views/StatusEntryForm.swift:38, Breadcrumb/Views/PomodoroSessionEndView.swift:143). DictationButton now has zero references, which makes the whole SFSpeechRecognizer pipeline dead in production: Breadcrumb/Services/SpeechRecognizer.swift (157 lines, still instantiated at BreadcrumbApp.swift:15 and injected into all three scenes at lines 34/51/65), BreadcrumbTests/SpeechRecognizerTests.swift, and the NSMicrophoneUsageDescription/NSSpeechRecognitionUsageDescription strings in project.yml:23-24 (native system dictation handles the mic in the OS dictation process, not the app). The dead code is also rotting: DictationButton permanently disables itself once speechRecognizer.error is ever set (.disabled at line 28; error is only cleared inside startListening, which the disabled button can never call), and SpeechRecognizer.startListening has a double-start race during the permission await where a second tap spawns a second engine and leaks the first one's running tap (mic indicator stuck on). CLAUDE.md still documents this dead system as the current dictation implementation.

**Hypothesis:** The native-dictation migration (cb98c76..fa6e0f0) swapped the call sites but never deleted the superseded implementation, its service wiring, tests, or Info.plist entries.

**Proposed fix:** Delete DictationButton.swift, SpeechRecognizer.swift, and SpeechRecognizerTests.swift; remove the speechRecognizer @State and the three .environment(speechRecognizer) injections from BreadcrumbApp.swift; drop the two usage-description keys from project.yml; run xcodegen generate; update CLAUDE.md's Dictation System section to describe NativeDictationButton.

**Verifier refinement:** Proposed fix is correct with three additions: (1) Strings.Dictation.permissionRequired (Strings.swift:578) becomes production-orphaned after deleting DictationButton — remove it and its assertions at StringsTests.swift:228-229 (keep Strings.Dictation.buttonLabel, still used by NativeDictationButton); (2) do NOT remove PlaceholderTextView — it is still live (StatusEntryForm.swift:27, PomodoroSessionEndView.swift:132) and feeds NativeDictationButton's isFocused, so rewrite CLAUDE.md's Dictation System section rather than deleting it, and drop SpeechRecognizerTests from CLAUDE.md's test-suite list; (3) after removing the two project.yml usage-description keys, run xcodegen generate, rebuild, and smoke-test the mic button once to confirm system dictation still starts (it should — dictation audio is captured by the OS dictation process, not the app, and there is no entitlements file to update).

**Evidence:**
```
struct DictationButton: View {
    @Environment(SpeechRecognizer.self) private var speechRecognizer
```

**Verifier notes:** Confirmed: DictationButton has zero call sites (grep finds only its definition at Breadcrumb/Views/DictationButton.swift:3); both forms use NativeDictationButton (StatusEntryForm.swift:38, PomodoroSessionEndView.swift:143, swapped in fcc1e94/e1619a8). SpeechRecognizer is reachable only via the dead button yet is still instantiated and injected into all three scenes (BreadcrumbApp.swift:15/34/51/65), and project.yml:23-24 keeps both usage-description keys while NativeDictationButton uses out-of-process system dictation (NSApp.sendAction("startDictation:"), NativeDictationButton.swift:29-31). The rot sub-claims also check out in the dead code: .disabled(error != nil) at DictationButton.swift:28 with error only cleared at SpeechRecognizer.swift:23 inside startListening, and a double-start window because isListening only flips true at SpeechRecognizer.swift:127 after the permission awaits (lines 34-50), so a second startListening overwrites audioEngine/recognitionTask (lines 102/125) and orphans the first running engine/tap.

### BC-077 — Personal .docx files and untracked .agents/ directory sitting in repo root, not gitignored

- [ ] **cleanup** · `Anschreiben_Aufhebungsvereinbarung_Roger_Schwertfeger.docx` · found by: dead-code · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** Two personal documents unrelated to the app sit untracked at the repo root: Anschreiben_Aufhebungsvereinbarung_Roger_Schwertfeger.docx (a termination-agreement cover letter) and German_Interview_Quotes_Translations.docx (thesis material). `git check-ignore` confirms neither is ignored, so a casual `git add .` would commit private personal/legal documents to a repo that gets pushed to GitHub. The untracked .agents/skills/breadcrumb-release/SKILL.md duplicates the release command already in .claude/commands/ (which IS gitignored) and is likewise unignored.

**Hypothesis:** Files were saved into the nearest open working directory during unrelated work; .agents/ was created by tooling on May 24 without updating .gitignore.

**Proposed fix:** Move the two .docx files out of the repo (e.g. to ~/Documents). Add `.agents/` (and optionally `*.docx`) to .gitignore so agent tooling output and personal files can never be committed.

**Evidence:**
```
?? .agents/
?? Anschreiben_Aufhebungsvereinbarung_Roger_Schwertfeger.docx
?? German_Interview_Quotes_Translations.docx   // git status; git check-ignore: not ignored
```

### BC-078 — BulletText is referenced nowhere in the app target — dead helper plus dead test suite, contradicting CLAUDE.md

- [ ] **cleanup** · `Breadcrumb/Models/BulletText.swift:9` · found by: ai-system, dead-code · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** grep for 'BulletText.' across Breadcrumb/ returns no production usages; parse/parseRaw/serialize/joinInline are exercised only by BreadcrumbTests/BulletTextTests.swift. CLAUDE.md documents AIExtractButton as collapsing extraction output 'to inline text via BulletText.joinInline()', but no such call exists, so multi-line AI output is stored with raw newlines into single-line TextFields (StatusEntryForm.swift:51-52) and into StatusEntry.lastAction/nextStep. Either the bullet/inline collapse feature was never wired up (see the cleanLines finding) or the helper is leftover from an abandoned bullet-lists feature.

**Hypothesis:** An AI agent built the bullet-text utility and tests for a planned bullets feature, and a later agent shipped the extraction UI without integrating it.

**Proposed fix:** Decide direction: wire BulletText.joinInline into AIExtractButton.applyResult (matching CLAUDE.md and fixing newline-in-TextField output), or delete BulletText.swift + BulletTextTests.swift and fix the CLAUDE.md AI System section.

**Evidence:**
```
enum BulletText {
    static func parse(_ value: String) -> [String] {
```

### BC-079 — Models/ExtractedStatus.swift does not contain ExtractedStatus — misleading filename and stale CLAUDE.md type names

- [ ] **cleanup** · `Breadcrumb/Models/ExtractedStatus.swift:1` · found by: ai-system · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** The file named ExtractedStatus.swift defines only the @Generable types LastActionExtraction and NextStepExtraction; the actual ExtractedStatus struct lives in Breadcrumb/Services/AIProvider.swift:5. CLAUDE.md additionally documents 'language-specific @Generable types (ExtractedStatusDE, ExtractedStatusEN) with @Guide descriptions in the matching language' — those types no longer exist, and the current @Guide descriptions are English-only for both languages. This is leftover naming from a removed design and actively misleads anyone navigating the code.

**Hypothesis:** The per-language ExtractedStatusDE/EN guided-generation types were replaced by the two field-specific extraction types, but the file name and docs were not updated.

**Proposed fix:** Rename the file to something like GuidedExtractionTypes.swift (then run `xcodegen generate`), or move LastActionExtraction/NextStepExtraction into LocalAIProvider.swift; update the CLAUDE.md AI System paragraph to describe the real types.

**Evidence:**
```
@available(macOS 26, *)
@Generable(description: "Completed work extracted from a project status update")
struct LastActionExtraction {
```

### BC-080 — LinkedDocument.url()/file() factories and isValid are dead production code, and url() performs far weaker validation than its doc comment and CLAUDE.md claim

- [ ] **cleanup** · `Breadcrumb/Models/LinkedDocument.swift:59` · found by: documents-keychain, dead-code, ui-views · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** The 'validated' factory methods LinkedDocument.url(string:label:originalFilename:) (lines 59-72), LinkedDocument.file(bookmark:label:originalFilename:) (lines 75-87), and the isValid property (lines 47-54) are referenced only from BreadcrumbTests/BreadcrumbTests.swift (lines 138-167). Both real creation paths bypass them: AddURLFormView.save() (AddURLFormView.swift:84) and DocumentListView.addFileViaPanel() (DocumentListView.swift:192) call the LinkedDocument initializer directly. Worse, url()'s only check is !urlString.isEmpty — it happily accepts "javascript:alert(1)", "file:///etc/passwd", or host-less garbage, while the actual UI path (AddURLFormView.normalizedURL, lines 14-23) enforces http/https scheme plus non-nil host. The factory is a trap: any future caller using the 'validated' API would store URLs the rest of the app assumes were vetted, then pass them to NSWorkspace.shared.open() in DocumentListView.openDocument.

**Hypothesis:** An earlier agent built the model-layer factories, then a later agent implemented the views with its own validation and direct init calls, leaving the factories orphaned with their validation never tightened to match.

**Proposed fix:** Either delete url()/file()/isValid and their tests, or make them the single creation path: move the scheme/host validation from AddURLFormView.normalizedURL into LinkedDocument.url() and have AddURLFormView.save() and addFileViaPanel() use the factories.

**Evidence:**
```
guard !urlString.isEmpty else { return nil }
let filename = originalFilename ?? URL(string: urlString)?.host() ?? urlString
```

### BC-081 — SessionType.shortBreak/.longBreak are never instantiated - break sessions are never recorded

- [ ] **cleanup** · `Breadcrumb/Models/PomodoroSession.swift:6` · found by: dead-code · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** Every PomodoroSession in the codebase is created with sessionType: .work (PomodoroSessionEndView.swift:174,212; PomodoroSessionEndHostView.swift:91). The .shortBreak/.longBreak cases exist only so Project.completedPomodoroCount/totalFocusTime can filter '== .work' - a filter that can never exclude anything. No break session is ever persisted, so stats code carries a distinction that does not exist in the data.

**Hypothesis:** The original design intended to log break sessions too; that was never implemented, leaving the enum and filters as speculative schema.

**Proposed fix:** Leave the enum cases in the live and frozen schemas (raw-value enum removal is a schema risk), but note the filters in Project.swift are currently no-ops; either start recording break sessions or simplify the stats filters to `completed` only with a comment. Do not rename or remove stored properties without a new schema version.

**Evidence:**
```
enum SessionType: String, Codable { case work; case shortBreak; case longBreak }
// all three creation sites pass sessionType: .work
```

### BC-082 — StatusEntry.openQuestions is a dead model field — never written, displayed, or edited anywhere

- [ ] **cleanup** · `Breadcrumb/Models/StatusEntry.swift:11` · found by: ui-views, dead-code · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** Grep across the app shows openQuestions is only declared in the model, defaulted to nil in init, and frozen in the schema files. StatusEntryForm has no field for it, ProjectDetailView/HistoryEntryRow never render it, ExtractedStatus doesn't extract into it, and no save path sets it. AIFillerStripper even carries ~dozens of filler phrases for the open-questions field type that can never be exercised through this column.

**Hypothesis:** The field was modeled for a planned 'open questions' feature (mirrored in the AI filler phrase lists) that was never wired into any form or display.

**Proposed fix:** Either surface it (add a TextField in StatusEntryForm's optional section plus display blocks in ProjectDetailView/HistoryEntryRow) or remove it — removal is a SwiftData schema change, so it requires a new BreadcrumbSchemaV3 with a migration stage per the project's migration rules; do not just delete the property.

**Evidence:**
```
var openQuestions: String?
```

### BC-083 — AIFillerStripper.cleanLines() has no production callers

- [ ] **cleanup** · `Breadcrumb/Services/AIFillerStripper.swift:174` · found by: dead-code · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** The only app consumer of AIFillerStripper is AIExtractButton, which calls clean() (AIExtractButton.swift:80,83). cleanLines() is referenced exclusively from AIFillerStripperTests.swift. Its doc comment says it is 'Used for the new bullet-list AI extraction output' - the same abandoned bullet-list feature as BulletText.

**Hypothesis:** Built for the bullet-list extraction pipeline that was never (or no longer) wired up; orphaned alongside BulletText.

**Proposed fix:** Delete cleanLines (lines 171-180) and its tests, or - if multi-line AI output should be sanitized per line - switch AIExtractButton.applyResult to call cleanLines instead of clean and keep it.

**Evidence:**
```
static func cleanLines(_ text: String) -> String {   // only callers are in AIFillerStripperTests.swift
```

### BC-084 — Eight dead Strings entries referenced nowhere in app code

- [ ] **cleanup** · `Breadcrumb/Strings.swift:169` · found by: localization, dead-code · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** A scripted cross-reference of every `static func` in Strings.swift against the app sources shows these translations are never used by any view or service: Pomodoro.overtime (line 169), Pomodoro.snooze5 (328), Pomodoro.snooze10 (331), Notifications.actionStartBreak (360 — note handleActionIdentifier still has a case for "breadcrumb.action.startBreak" at NotificationService.swift:301, but no action with that identifier is ever registered), Settings.playSound (392), Settings.systemNotification (395), Confirm.deleteDocumentTitle (646), Confirm.deleteDocumentMessage (649). snooze5/snooze10 are only referenced by StringsTests.swift:154-157, which keeps them looking alive.

**Hypothesis:** Leftovers from removed or rewritten features: the snooze UI, the start-break notification action, an older sound/notification settings layout, and a confirmation-dialog-based document delete that was replaced by the inline trash row in DocumentListView.

**Proposed fix:** Delete the eight functions (and the snooze test block in StringsTests.swift), plus the unreachable "breadcrumb.action.startBreak" case in NotificationService.handleActionIdentifier — unless the snooze finding above is resolved by re-adding the UI, in which case keep snooze5/snooze10.

**Evidence:**
```
static func overtime(_ l: AppLanguage) -> String {
    l == .german ? "Überstunden" : "Overtime"
}
```

### BC-085 — setOpenWindowAction registered redundantly in two places

- [ ] **cleanup** · `Breadcrumb/Views/ContentView.swift:114` · found by: windows-lifecycle · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** WindowManager.setOpenWindowAction is called from MenuBarLabelView's .task (runs at launch, since the label always exists — MenuBarLabelView.swift:21-23) and again from ContentView's .task every time the popover opens. The ContentView registration is always preceded by the label's and stores an equivalent OpenWindowAction, so it adds nothing.

**Hypothesis:** ContentView held the original registration before commit 0e1aa1e added MenuBarLabelView for launch-time access; the old call site was not removed.

**Proposed fix:** Delete the .task { windowManager.setOpenWindowAction(openWindow) } block (lines 113-115) and the @Environment(\.openWindow) property from ContentView, leaving MenuBarLabelView as the single registration point.

**Evidence:**
```
.task {
    windowManager.setOpenWindowAction(openWindow)
}
```

### BC-086 — Per-project UserDefaults expansion keys are never cleaned up when a project is deleted

- [ ] **cleanup** · `Breadcrumb/Views/DocumentListView.swift:27` · found by: documents-keychain · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** DocumentListView persists section expansion as "section.documents.\(project.id)" (lines 27/49) and ProjectDetailView does the same with "section.pomodoro.\(project.id)" (lines 125/280). Project deletion (ProjectDetailView confirmationDialog, line 161, and permanent delete in ArchivedProjectsView) removes the SwiftData rows but never removes these defaults, so one orphaned boolean pair accumulates in the app's preferences plist per deleted project, forever, keyed by a UUID no longer referenced anywhere.

**Hypothesis:** The UI-state persistence was bolted onto the views ad hoc with raw UserDefaults keys, and no one owns the project-deletion side effects.

**Proposed fix:** When permanently deleting a project (both call sites), also call UserDefaults.standard.removeObject(forKey:) for both "section.documents.\(project.id)" and "section.pomodoro.\(project.id)" — ideally via a small helper (e.g. Project.cleanUpDefaults()) so both delete paths share it.

**Evidence:**
```
UserDefaults.standard.set(isExpanded, forKey: "section.documents.\(project.id)")
```

### BC-087 — List .onDelete in HistoryView has no user-facing trigger on macOS and duplicates the context-menu delete

- [ ] **cleanup** · `Breadcrumb/Views/HistoryView.swift:79` · found by: ui-views · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** ForEach.onDelete provides swipe-to-delete/EditMode affordances on iOS; on macOS a List without a selection binding exposes no UI that invokes it, so confirmDeleteEntries (lines 118-121) is effectively unreachable. Row deletion is already fully handled by the context-menu Delete button (line 74) with the same confirmation dialog.

**Hypothesis:** The list code was written iOS-style or carried over from an example; the inert modifier was never noticed because the context menu covers the feature.

**Proposed fix:** Remove .onDelete(perform: confirmDeleteEntries) and the confirmDeleteEntries helper; alternatively, if keyboard deletion is wanted, add a List selection binding plus .onDeleteCommand to make delete actually reachable.

**Evidence:**
```
.onDelete(perform: confirmDeleteEntries)
```

### BC-088 — MenuBarLabelView onChange has two branches that execute the identical statement

- [ ] **cleanup** · `Breadcrumb/Views/MenuBarLabelView.swift:24` · found by: dead-code · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** The onChange(of: pendingSessionEnd) handler contains `if oldValue == nil && newValue != nil { reset() } else if newValue == nil { reset() }` - both branches call windowManager.resetSessionEndWindowSuppression() with no other effect, so the condition split is meaningless and reads as if the two cases were meant to differ.

**Hypothesis:** Two separate edits each added a reset condition; nobody noticed the branches collapsed into the same body.

**Proposed fix:** Replace with a single condition: `if oldValue == nil || newValue == nil { windowManager.resetSessionEndWindowSuppression() }` (or call it unconditionally if a nil->nil transition is impossible), keeping the trailing autoOpenSessionEndWindowIfNeeded().

**Evidence:**
```
if oldValue == nil && newValue != nil {
    windowManager.resetSessionEndWindowSuppression()
} else if newValue == nil {
    windowManager.resetSessionEndWindowSuppression()
}
```

### BC-089 — Snooze/skip plumbing is dead since the buttons were removed in 06b8276 (onSnooze, onSkip, handleSnooze, handleSkip, snooze(), Strings.snooze5/10)

- [ ] **cleanup** · `Breadcrumb/Views/PomodoroSessionEndView.swift:19` · found by: timer-logic, swiftdata, localization, dead-code, dead-code · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** Commit 06b8276 ('polish: simplify work-end overlay to two actions') removed the snooze, skip, and stop buttons from workEndContent, but left the entire call chain in place: PomodoroSessionEndView declares `onSkip` (line 15) and `onSnooze` (line 19) and never invokes either anywhere in its body; PomodoroSessionEndHostView wires handleSkip (line 50) and handleSnooze (line 83) into those dead closures; PomodoroTimer.snooze(minutes:) (line 209) is now reachable only through the dead handleSnooze; and Strings.Pomodoro.snooze5/snooze10 (Strings.swift:328-333) are unused UI strings kept alive only by StringsTests:154-157. CLAUDE.md still documents snooze (+5/+10) as a live feature, which this leftover code makes worse.

**Hypothesis:** The UI simplification commit removed only the button views, leaving the parameter plumbing, handlers, timer method, strings, and tests behind.

**Proposed fix:** Remove the onSkip/onSnooze parameters from PomodoroSessionEndView, handleSkip/handleSnooze from PomodoroSessionEndHostView, PomodoroTimer.snooze(minutes:) plus its two tests, Strings.Pomodoro.snooze5/snooze10 plus their StringsTests assertions — or, if snooze is meant to exist, re-add the buttons. Update CLAUDE.md's session-end description either way.

**Evidence:**
```
var onSkip: () -> Void
...
var onSnooze: (Int) -> Void
```

### BC-090 — Three near-identical PomodoroSession creation blocks across session-end code

- [ ] **cleanup** · `Breadcrumb/Views/PomodoroSessionEndView.swift:168` · found by: dead-code · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** saveWorkSession() (PomodoroSessionEndView.swift:168-197), saveAndDone() (207-237), and PomodoroSessionEndHostView.saveCurrentWorkSession() (88-101) each build a PomodoroSession, set completed/endedAt/actualDuration/project, and two of them duplicate the identical StatusEntry-creation block verbatim (183-194 vs 221-232). The triplication has already drifted: saveWorkSession omits session.isFocusMate, and actualDuration is computed three different ways (originalDurationSeconds-remaining+overtime vs phaseDurationSeconds-remaining), which is exactly the class of bug duplication breeds.

**Hypothesis:** FocusMate save and the host-view skip/stop paths were each copy-pasted from the original work-end save instead of extracting a shared builder.

**Proposed fix:** Extract one helper, e.g. `makeSession(timer:isFocusMate:) -> PomodoroSession` plus `makeStatusEntry(freeText:lastAction:nextStep:project:session:)`, and have all three call sites use it so duration/completion/isFocusMate logic lives in one place.

**Evidence:**
```
let session = PomodoroSession(plannedDuration: TimeInterval(timer.originalDurationSeconds), sessionType: .work, sessionNumber: timer.currentSessionNumber)  // appears 3x with diverging field setup
```

### BC-091 — onBack parameter and popover-header branch dead in SettingsView, AboutView, and HistoryView

- [ ] **cleanup** · `Breadcrumb/Views/SettingsView.swift:23` · found by: dead-code · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** All three views declare `var onBack: (() -> Void)? = nil` and render a back-button header only when it is non-nil (SettingsView.swift:34-56, AboutView.swift:12+, HistoryView.swift:27+). The only construction sites in the app are BreakoutWindowView.swift:35/38/41, all without onBack - ContentView's Screen enum has no settings/about/history cases anymore. The optional parameter and the entire header branch (including Strings.General.back usage there) are unreachable.

**Hypothesis:** Settings/About/History used to render inline in the popover with a back button; after they moved exclusively to the breakout window, the dual-context pattern was kept 'just in case'.

**Proposed fix:** Remove `var onBack` and the `if let onBack { ... }` header blocks from SettingsView, AboutView, and HistoryView, and update the stale 'View Header Pattern' section in CLAUDE.md.

**Evidence:**
```
var onBack: (() -> Void)? = nil   // SettingsView:23, AboutView:5, HistoryView:10
SettingsView() / AboutView() / HistoryView(project:)  // BreakoutWindowView:35-41, never passes onBack
```

### BC-092 — SoundPicker bypasses LanguageManager and re-implements language lookup from UserDefaults

- [ ] **cleanup** · `Breadcrumb/Views/SoundPicker.swift:33` · found by: ui-views, localization · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** SoundPicker is a SwiftUI view with full access to the environment, yet it reads the raw "app.language" UserDefaults key with a hardcoded "de" fallback instead of @Environment(LanguageManager.self) like every other view. It only updates correctly on language switch as a side effect of the parent re-rendering its label parameter; it duplicates the storage key and default, which will silently diverge if LanguageManager's key or default ever changes.

**Hypothesis:** The view was written standalone (it only takes label/selection parameters) and the author shortcut the environment wiring.

**Proposed fix:** Add @Environment(LanguageManager.self) private var languageManager and use languageManager.language in place of the currentLanguage computed property; delete currentLanguage.

**Evidence:**
```
private var currentLanguage: AppLanguage {
    let stored = UserDefaults.standard.string(forKey: "app.language") ?? "de"
    return AppLanguage(rawValue: stored) ?? .german
```

### BC-093 — Status-entry form block duplicated between StatusEntryForm and PomodoroSessionEndView

- [ ] **cleanup** · `Breadcrumb/Views/StatusEntryForm.swift:26` · found by: dead-code · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** The ZStack of PlaceholderTextView + NativeDictationButton overlay + AIExtractButton + DisclosureGroup with lastStep/nextStep TextFields exists twice, nearly verbatim: StatusEntryForm.swift:26-55 and PomodoroSessionEndView.statusEntryForm (131-160). Only frame heights and spacing differ. Any future change (e.g. adding a dictation fix or a third field) must be made twice and has already drifted (minHeight 60/120 vs 50/100, spacing 12 vs 8).

**Hypothesis:** The session-end form was copy-pasted from StatusEntryForm rather than extracting the shared input cluster.

**Proposed fix:** Extract a shared `StatusFieldsView(freeText:lastAction:nextStep:showOptionalFields:focusOnAppear:)` component used by both, parameterizing the height.

**Evidence:**
```
PlaceholderTextView(placeholder: Strings.Status.whereAreYou(l), text: $freeText, ... )
NativeDictationButton(isFocused: freeTextFocused).padding(6)  // identical cluster in both files
```

### BC-094 — StringsTests duplicates the string table instead of verifying translation completeness

- [ ] **cleanup** · `BreadcrumbTests/StringsTests.swift:10` · found by: tests-quality · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** Strings.swift contains 187 string functions; StringsTests hardcodes literal copies of fewer than half of them for both languages (e.g. lines 10-22, 104-118). This is a change-detector: every copy tweak must be edited in two places, while the majority of strings — and the actual property CLAUDE.md claims is tested ("translation completeness for both languages") — have no check at all. A new string returning German text for .english, or identical text for both languages, passes the suite unless someone remembered to add a duplicate literal here.

**Hypothesis:** Tests were generated string-by-string as features landed, accumulating literal duplication instead of a structural completeness check.

**Proposed fix:** Replace most literal assertions with a structural test: maintain one array of (String) -> closures [(AppLanguage) -> String] (or generate via a registry in Strings) and assert for each that de/en outputs are non-empty and differ where expected; keep literal assertions only for strings with format arguments (wrapUpBuffer, totalSessionsLabel).

**Evidence:**
```
#expect(Strings.General.back(l) == "Zurück")
#expect(Strings.General.settings(l) == "Einstellungen")
```

### BC-095 — Tracked junk: empty default.profraw and stale April review/prompt artifacts committed at repo root

- [ ] **cleanup** · `default.profraw` · found by: dead-code · ⚠️ UNVERIFIED — confirm in code before fixing

**Problem:** `git ls-files` shows default.profraw - a 0-byte LLVM profiling artifact from Apr 19 - is committed to the repo. Also tracked at the root are one-shot AI-review and research artifacts that are months stale and describe long-fixed states of the app: BUGS.md, UX.md, POLISH-REVIEW.md (Apr 16-25), ultrareview.md (Apr 18), foundation-models-research-prompt.md and foundation-models-research-prompt_v_long.md (Apr 25). They add noise for anyone (or any agent) reading the repo and risk being mistaken for current state.

**Hypothesis:** Profiling output and agent-session reports were committed during rapid iteration and never cleaned up once their findings were addressed.

**Proposed fix:** git rm default.profraw and add *.profraw to .gitignore. Move the stale review/prompt .md files into docs/archive/ (or delete them) so the repo root reflects only living documentation.

**Evidence:**
```
$ git ls-files | grep -E 'profraw|md'
default.profraw   (0 bytes)
BUGS.md POLISH-REVIEW.md UX.md ultrareview.md foundation-models-research-prompt*.md
```

---

## Audit completeness notes

- The 12 finder agents covered: every Swift file in `Breadcrumb/` and `BreadcrumbTests/`, `project.yml`, repo clutter, and cross-file flows (timer state machine, notification wiring, window lifecycle, AI pipeline, localization).
- The adversarial verification pass confirmed 25 findings as real (0 refuted, 0 already-fixed among those checked) before hitting the session usage limit; 70 findings remain unverified and are flagged ⚠️ above.
- Verification can be resumed cheaply: workflow run `wf_b9e7d954-0e8`, script at `~/.claude/projects/-Users-roger-Claude-Code-Breadcrumb/2ff3450a-6de0-4bfc-9ca0-74fe04b32735/workflows/scripts/breadcrumb-full-audit-wf_b9e7d954-0e8.js` — re-invoke Workflow with `resumeFromRunId: "wf_b9e7d954-0e8"` after the limit resets; completed finder/dedup/verify calls return from cache. (Same-session only; otherwise just have the implementing agent verify-as-it-goes.)
