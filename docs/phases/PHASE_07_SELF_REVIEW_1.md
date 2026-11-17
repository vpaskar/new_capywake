# Phase 07 — self-review #1

Against the implementation, after validation passed the first time. Every
finding is applied or marked invalid with a reason.

**8 findings: 2 High, 3 Medium, 3 Low. All applied.**

---

## High

### H1 — The permanently-denied branch of the gate was unreachable

`AlarmPermissionPrompt.maybeRequest` asked `shouldRequestNotification` whether
to prompt, and then — inside that branch — asked `shouldOpenSettings` whether
to send the user to the OS instead.

`shouldRequestNotification` returns **false** for `permanentlyDenied`: there
is no prompt left to show. So the settings branch could never run, and the
one user who cannot be helped by a prompt got **nothing at all** — no dialog,
no route, no explanation, after enabling their first alarm with notifications
permanently off.

Found by a test asserting `openAppSettingsCount == 1`, which found zero.

**Applied.** `sendToSettings` is computed beside the two request checks rather
than behind one of them, and the dialog's action reads *Open settings* instead
of *Allow* in that case — offering "Allow" would be a button that cannot do
what it says.

### H2 — Three pushed routes had no `Scaffold`, so `InkWell` had no `Material`

`SettingsScreen`, `ReliabilityChecklistScreen` and `WalkthroughScreen` all
returned a bare `SceneHeader`. Every tab screen gets its `Scaffold` from the
shell; a route pushed on the **root** navigator does not, and `AlarmEditScreen`
— the only other pushed route — supplies its own.

The failure was total: *No Material widget found*, thrown on build, so
Settings could not open at all from any tab.

**Applied.** All three wrap in `Scaffold`, and `SettingsGroup` carries its own
`Material` as well — the sheet its rows ink on, which is also what `CapyCard`
does. A test asserts the `Material` is there, so removing it fails rather than
reproducing the crash.

---

## Medium

### M1 — Two hero band heights are inventions wearing a measurement's clothes

`ReliabilityChecklistScreen` and `WalkthroughScreen` both pass
`bandHeight: 84.0` and `MeadowFooter(height: 52.2)`. Neither number was
measured: 84 was chosen, 52.2 borrowed from Alarms.

`SceneHeader.bandHeight` was made **required** in Phase 04 precisely so a
number could not arrive silently — and a required parameter does not stop a
number arriving *invented*. The constant's doc said "shorter than Settings'
own: this screen is a list", which reads like a measurement's rationale.

**Applied.** Both constants now say **"Not a measurement"** in their first
line and name the reason — these screens have no mockup, so there is nothing
to be Tier A against. The choice is recorded in `docs/visual/settings/`.

### M2 — The toggle row announced a loose label beside an unlabelled control

`SettingsToggleRow` put `_RowBody` (title + subtitle `Text`s) next to a
`CapyToggle` carrying its own `semanticLabel`. A screen reader therefore met
three nodes: "Motion check after dismiss", the description, and separately a
switch — with the switch's own label duplicating the first two.

**Applied.** `MergeSemantics` around the row, `ExcludeSemantics` around the
body, so it reads as one toggled node with the full sentence. Asserted with
`matchesSemantics`.

### M3 — Both picker sheets overflowed

`showSoundPickerSheet` builds a `RadioListTile` per catalogue sound (12) in a
fixed `Column`. At the default scale it overflowed by **325 px**.

**Applied.** Both sheets scroll. Found by the test that taps every chevron —
the test existed because §11 of the plan demanded "every row with a chevron
resolves to something that opens", and it caught a defect in the thing that
opens rather than in the row.

---

## Low

### L1 — `PermissionState.initial` already existed
The checklist screen declared a private `_unknownPermissions` constant that is
exactly `PermissionState.initial`, which the ported domain has carried since
Phase 02. **Applied:** use the ported one. *Fourth time this project has
rebuilt something `lib/core/` already had.*

### L2 — `permissionStateProvider` read a scoped provider without declaring it
Riverpod throws *"depends on Provider<PermissionService>, which may be
scoped"*. The platform overrides scope `permissionServiceProvider` at the root,
so the app would have thrown on opening Settings. **Applied:** `dependencies:
[permissionServiceProvider]`, plus a test (self-review #2) that pumps the real
root-scope shape.

### L3 — The walkthrough's group heading and its only row read identically
`walkthroughAlarmsTitle` was both the group heading and the row title, so the
screen said "Your alarms / Your alarms", and a test tapping `.first` hit the
heading, which does nothing. **Applied:** the row is `alarmAddAction` ("Add
alarm"), the heading keeps the section name. The duplicate is what made the
test look like a product bug.

---

## Outcome

8 findings, all applied, none invalid, none deferred. Two were defects that
made the screen **unopenable** (H2) or left a user stranded (H1); both were
found by tests this phase's plan required, not by reading.
