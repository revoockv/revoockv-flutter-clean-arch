# Few rebuilds — watch only what you show

Syntax of `watch` / `registerHandler` and the order rule: `reactive_state_syntax.md`. Where widgets live:
`widget_placement.md`.

A widget rebuilds every time a listenable it watches notifies. Four questions before every `watch`:

1. **Does this widget show the value?** No → do not watch it here: pass the listenable down, or react with
   `registerHandler` (it never rebuilds).
2. **Does it use the whole value?** No → select the part with `watchPropertyValue` (linter: `watch_select`).
3. **How often does the value change?** Ticks, positions, levels, typed text → only the smallest widget that
   shows it watches it.
4. **Is the selected part cheap and comparable with `==`?** A bool, a number, a string, an enum, an entity with
   `==` — yes. A new `List` or a `.where(…)` is a new object on every call — select its `length` or a key instead.

## `watchPropertyValue` — rebuild only when a part changes

```dart
// ❌ rebuilds on every change of the state: loading → failure → idle…
final bool isLoading = watch(addingState).value.isLoading;

// ✅ rebuilds only when isLoading flips
final bool isLoading = watchPropertyValue(_isLoadingOf, target: addingState);

static bool _isLoadingOf(ValueListenable<ResultState<void, NoteFailure>> state) => state.value.isLoading;
```

- The selector gets the **listenable itself**, not its value: `(ValueListenable<T> state) => state.value.part`.
- Always pass `target:` (the watch use case result or a controller): nothing is looked up in GetIt.
- The selector is a private `static` method (`_isLoadingOf`, `_countOf`) or a short typed closure; it only reads.
- After every notification watch_it compares the new part with the old one by `==` and rebuilds only when they
  differ. So a selector never builds a list or an object without `==`.
- It is bound to its position in `build()` like `watch` (linter: `watch_order`).
- Example: `example/lib/features/notes/presentation/widgets/add_note_widget.dart` (`_AddButtonWidget`).

### Typical selectors

| You show | Select |
|---|---|
| progress of an action | `state.value.isLoading` |
| whether a take is recorded | `state.value is RecordingRecorderState` (not the timer and the level inside it) |
| a badge with the count of items of one song | `list.value.where((Recording r) => r.songId == songId).length` |
| the text of a field (not the cursor) | `(TextEditingController c) => c.text` — `watch(textController)` rebuilds on every cursor move too |
| whether a field is empty | `(TextEditingController c) => c.text.trim().isEmpty` — rebuilds twice, not on every key |
| one field of a settings entity | `settings.value.themeMode` |

`ResultState` you `switch` over (loading / failure / value) is the whole value: `watch(…).value` is right there.
The items of a filtered list (`watch(…).value.where(…).toList()`) are shown items, not a part — watch the whole list
(the linter lets a chain that ends in `.toList()` / `.toSet()` pass).

## Fast state — the lowest widget only

State that changes several times a second — a recording timer and input level, a playback position, a progress
fraction, a scroll offset, typed text — is watched **only** by the small widget that draws it:

```dart
// ❌ the page watches the recorder: every 200 ms the whole page (and its TextField with the lyrics) rebuilds
final RecorderState recorder = watch(watchRecorderUseCase()).value;

// ✅ the page asks one question that changes twice per take
final bool isRecording = watchPropertyValue(_isRecordingOf, target: watchRecorderUseCase());

// ✅ the timer row watches the ticks itself and gives plain values to a pure widget
final class _RecordingTimeWidget extends WatchingWidget {
  const _RecordingTimeWidget();

  @override
  Widget build(BuildContext context) {
    final RecorderState recorder = watch(watchRecorderUseCase()).value;
    if (recorder is! RecordingRecorderState) return const SizedBox.shrink();
    return RecordingIndicatorWidget(elapsed: recorder.elapsed, level: recorder.level);
  }
}
```

The same for a list: the list watches *which* item plays (`recordingId`, `isPlaying`), and only the tile of that item
has a small `WatchingWidget` for the position (the progress bar). Never pass a fast value through constructors of a
whole subtree — every widget on the way rebuilds.

## Watch where it is shown

- A page (or a shell with tabs) owns controllers, calls use cases and reacts (`registerHandler`). It watches only
  what *it* shows: the selected tab, the title.
- Each area of the screen (a tab, a list, a panel) is its own `WatchingWidget` that watches what that area shows,
  derives what it needs (search, sort, statistics) and passes the values to pure widgets.
- Data that only one tab needs is watched inside that tab, not by the shell: otherwise a change of it rebuilds every
  tab and the navigation.
- Derived values (filtering, sorting, statistics) are computed in the widget that shows them — and when several
  widgets need them, by a derived notifier of the repository (`reactive_state_syntax.md` → "Derived state").
- A search field: the widget of the results watches `watchPropertyValue((TextEditingController c) => c.text, target: …)`, not the
  whole `TextEditingValue` (selection, composing).

## Rebuilds that cost nothing

- `const` constructors for widgets without parameters, `const` lists of children.
- A `ListView.builder` with `key: ValueKey<String>(item.id)` on the items.
- `IndexedStack` keeps tabs alive; a tab that is not shown still rebuilds on what it watches — keep its watches low.

## Checklist

- No `watch(x).value.part` — `watchPropertyValue(…, target: x)` (linter: `watch_select`).
- No fast state watched above the widget that draws it.
- No page watches data only its children show.
- Leaf widgets are pure: data and callbacks, no watch (`widget_placement.md`).
