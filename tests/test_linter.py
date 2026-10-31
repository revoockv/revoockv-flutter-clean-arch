"""Tests for scripts/dart_clean_arch_linter.py.

Run: python3 -m unittest discover -s tests -v   (from the skill root)
Each test writes a tiny lib/ tree into a temp dir and checks which rules fire.
"""

from __future__ import annotations

import contextlib
import importlib.util
import io
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parent.parent
EXAMPLE_LIB = SKILL_ROOT / "assets" / "example_app" / "lib"

_spec = importlib.util.spec_from_file_location("linter", SKILL_ROOT / "scripts" / "dart_clean_arch_linter.py")
linter = importlib.util.module_from_spec(_spec)
sys.modules["linter"] = linter
_spec.loader.exec_module(linter)


def run(files: dict[str, str], rules: set[str]) -> list[tuple[str, str, int]]:
    """Write [files] under a temp lib/ and return (file name, rule, line) of every violation."""
    with tempfile.TemporaryDirectory() as tmp:
        lib = Path(tmp) / "lib"
        for rel, code in files.items():
            path = lib / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(textwrap.dedent(code), encoding="utf-8")
        with contextlib.redirect_stdout(io.StringIO()):
            report = linter.analyze(str(lib), rules, json_output=True)
        return [(Path(v.file).name, v.rule, v.line) for r in report.results for v in r.violations]


WIDGETS = "features/notes/presentation/widgets/"


class WatchingWidgetTest(unittest.TestCase):
    RULES = {"watching_widget"}

    def test_watch_use_case_is_valid(self):
        code = """
            final class ListWidget extends WatchingWidget {
              @override
              Widget build(BuildContext context) {
                final List<Note> notes = watch(watchNotesUseCase()).value;
                return Text('$notes');
              }
            }
        """
        self.assertEqual(run({WIDGETS + "list_widget.dart": code}, self.RULES), [])

    def test_register_handler_on_use_case_is_valid(self):
        code = """
            final class GateWidget extends WatchingWidget {
              @override
              Widget build(BuildContext context) {
                registerHandler(target: watchAuthStateUseCase(), handler: _onChanged);
                return child;
              }
            }
        """
        self.assertEqual(run({WIDGETS + "gate_widget.dart": code}, self.RULES), [])

    def test_watch_value_and_missing_watch_are_violations(self):
        code = """
            final class BadWidget extends WatchingWidget {
              @override
              Widget build(BuildContext context) {
                final bool v = watchValue((Repo r) => r.state);
                return Text('$v');
              }
            }
        """
        found = run({WIDGETS + "bad_widget.dart": code}, self.RULES)
        self.assertEqual(sorted(line for _, _, line in found), [2, 5])


    def test_controller_watch_and_create_once_are_valid(self):
        code = """
            final class PageWidget extends WatchingWidget {
              @override
              Widget build(BuildContext context) {
                final NotesController controller = createOnce(_create, dispose: _dispose);
                registerHandler(target: controller, handler: _onState);
                return child;
              }
            }

            final class _ButtonWidget extends WatchingWidget {
              final ValueListenable<ResultState<void>> state;
              @override
              Widget build(BuildContext context) {
                final bool isLoading = watch(state).value.isLoading;
                return Text('$isLoading');
              }
            }
        """
        self.assertEqual(run({WIDGETS + "page_widget.dart": code}, self.RULES), [])

    def test_watching_stateful_without_calls_is_a_violation(self):
        code = """
            final class FormWidget extends WatchingStatefulWidget {
              @override
              State<FormWidget> createState() => _FormWidgetState();
            }

            final class _FormWidgetState extends State<FormWidget> {
              @override
              void initState() {
                super.initState();
              }

              @override
              Widget build(BuildContext context) => const SizedBox();
            }
        """
        found = run({WIDGETS + "form_widget.dart": code}, self.RULES)
        self.assertEqual([line for _, _, line in found], [2])

    def test_watch_outside_watching_widgets_is_a_violation(self):
        code = """
            final class PlainWidget extends StatelessWidget {
              @override
              Widget build(BuildContext context) {
                final int v = watch(watchCountUseCase()).value;
                return Text('$v');
              }
            }

            final class CounterWidget extends StatefulWidget {
              @override
              State<CounterWidget> createState() => _CounterWidgetState();
            }

            final class _CounterWidgetState extends State<CounterWidget> {
              @override
              Widget build(BuildContext context) {
                registerHandler(target: watchCountUseCase(), handler: _onCount);
                return const SizedBox();
              }
            }
        """
        found = run({WIDGETS + "plain_widget.dart": code}, self.RULES)
        self.assertEqual(sorted(line for _, _, line in found), [2, 15])

class WatchOrderTest(unittest.TestCase):
    RULES = {"watch_order"}

    def test_conditional_loop_and_callback_watches_are_violations(self):
        code = """
            final class OrderWidget extends WatchingWidget {
              @override
              Widget build(BuildContext context) {
                final AuthState state = watch(watchAuthStateUseCase()).value;
                final List<Note> notes =
                    watch(watchNotesUseCase()).value;
                registerHandler(
                  target: watchAuthStateUseCase(),
                  handler: _onAuth,
                );
                if (state is SignedInAuthState) {
                  final bool busy = watch(watchBusyUseCase()).value;
                }
                for (final Note note in notes) {
                  registerHandler(target: watchNoteUseCase(), handler: _onNote);
                }
                if (notes.isEmpty) return const SizedBox.shrink();
                final int count = watch(watchCountUseCase()).value;
                return ListView.builder(
                  itemBuilder: (BuildContext c, int i) {
                    final bool x = watch(watchItemUseCase()).value;
                    return const SizedBox();
                  },
                );
              }
            }
        """
        found = run({WIDGETS + "order_widget.dart": code}, self.RULES)
        self.assertEqual(sorted(line for _, _, line in found), [13, 16, 22])


class StateExposureTest(unittest.TestCase):
    def test_value_notifier_leaks(self):
        files = {
            "features/notes/domain/repositories/notes_repository.dart": """
                abstract interface class NotesRepository {
                  ValueNotifier<List<Note>> watchNotes();
                }
            """,
            "features/notes/data/repositories/notes_repository_impl.dart": """
                final class NotesRepositoryImpl {
                  final ValueNotifier<List<Note>> _notes = ValueNotifier<List<Note>>(const <Note>[]);
                  ValueListenable<List<Note>> watchNotes() => _notes;
                  ValueNotifier<int> get count => _count;
                }
            """,
        }
        found = run(files, {"value_listenable_exposure"})
        self.assertEqual(sorted((f, line) for f, _, line in found),
                         [("notes_repository.dart", 3), ("notes_repository_impl.dart", 5)])

    def test_state_in_di(self):
        code = """
            void registerAndInitNotes() {
              di.registerSingleton<ValueNotifier<bool>>(ValueNotifier<bool>(false));
              di.registerSingleton<Config>(config, instanceName: 'dev');
              di.registerLazySingleton<NotesDataSource>(InMemoryNotesDataSource.new);
            }
        """
        found = run({"features/notes/presentation/di/notes_di.dart": code}, {"no_state_in_di"})
        self.assertEqual(sorted(line for _, _, line in found), [3, 4])

    def test_notifier_subclasses_in_di(self):
        files = {
            "features/notes/presentation/controllers/filter_controller.dart": """
                final class FilterController extends ValueNotifier<String> {
                  FilterController() : super('');
                }

                final class SortController extends FilterController {}

                final class Clock with ChangeNotifier {}
            """,
            "features/notes/presentation/di/notes_di.dart": """
                void registerAndInitNotes() {
                  di.registerLazySingleton<FilterController>(FilterController.new);
                  di.registerSingleton(SortController());
                  di.registerLazySingleton(() => Clock());
                  di.registerLazySingleton<NotesRepository>(NotesRepositoryImpl.new);
                }
            """,
        }
        found = run(files, {"no_state_in_di"})
        self.assertEqual(sorted(line for _, _, line in found), [3, 4, 5])


class NamingFileTest(unittest.TestCase):
    def test_controllers_folder_holds_controllers_and_states(self):
        files = {
            "features/notes/presentation/controllers/notes_filter_state.dart": "",
            "features/notes/presentation/controllers/notes_controller.dart": "",
            "features/notes/presentation/controllers/helpers.dart": "",
        }
        found = run(files, {"naming_file"})
        self.assertEqual([name for name, _, _ in found], ["helpers.dart"])


class ImportViolationTest(unittest.TestCase):
    def test_use_case_import_in_widget(self):
        code = """
            import '../../domain/use_cases/add_note_use_case.dart';
            import '../di/notes_getters.dart';
        """
        found = run({WIDGETS + "x_widget.dart": code}, {"import_violation"})
        self.assertEqual([line for _, _, line in found], [2])

    def test_controller_must_not_touch_data_or_di(self):
        code = """
            import '../../data/data_sources/notes_data_source.dart';
            import '../../data/models/note_model.dart';
            import '../di/notes_getters.dart';
            import 'package:watch_it/watch_it.dart';

            final class NotesController {
              final NotesDataSource _source = di<NotesDataSource>();
              final Object _other = GetIt.I<Object>();

              /// 'di<Object>()' in a string is not a call.
              Future<void> add(String text, Future<Result<void>> Function(String) add) => add(text);
            }
        """
        controllers = "features/notes/presentation/controllers/"
        found = run({controllers + "notes_controller.dart": code}, {"import_violation"})
        self.assertEqual([line for _, _, line in found], [2, 3, 4, 5, 8, 9])

    def test_di_folder_may_import_data_and_call_di(self):
        code = """
            import '../../data/data_sources/notes_data_source.dart';

            void registerAndInitNotes() {
              di.registerLazySingleton<NotesDataSource>(InMemoryNotesDataSource.new);
            }
        """
        found = run({"features/notes/presentation/di/notes_di.dart": code}, {"import_violation"})
        self.assertEqual(found, [])


class StaticConstOrderTest(unittest.TestCase):
    def test_final_state_class_is_not_a_field(self):
        code = """
            final class PageWidget extends WatchingStatefulWidget {
              const PageWidget({super.key});
              @override
              State<PageWidget> createState() => _PageWidgetState();
            }

            final class _PageWidgetState extends State<PageWidget> {
              static const String _title = 'Notes';

              late final NotesController _controller;
            }
        """
        self.assertEqual(run({WIDGETS + "page_widget.dart": code}, {"static_const_order"}), [])


class ThemeImportTest(unittest.TestCase):
    RULES = {"theme_import"}
    THEME = {"core/presentation/theme.dart": """
        final class AppTheme {
          static const double spacingMedium = 16;
        }
    """}

    def test_same_const_in_two_features_must_move_to_core(self):
        files = dict(self.THEME)
        files["features/notes/presentation/widgets/a_widget.dart"] = "  static const double _cardRadius = 12;\n"
        files["features/todo/presentation/widgets/b_widget.dart"] = "  static const double _cardRadius = 12;\n"
        found = run(files, self.RULES)
        self.assertEqual(sorted(f for f, _, _ in found), ["a_widget.dart", "b_widget.dart"])

    def test_spacing_value_already_in_core(self):
        files = dict(self.THEME)
        files[WIDGETS + "a_widget.dart"] = "  static const double _padding = 16;\n  static const double _iconSize = 16;\n"
        found = run(files, self.RULES)
        self.assertEqual([line for _, _, line in found], [1])

    def test_single_widget_const_stays_private(self):
        files = dict(self.THEME)
        files[WIDGETS + "a_widget.dart"] = "  static const double _cardRadius = 12;\n"
        self.assertEqual(run(files, self.RULES), [])


class MagicStringsTest(unittest.TestCase):
    RULES = {"magic_strings"}

    def lines(self, rel: str, code: str) -> list[int]:
        return [line for _, _, line in run({rel: code}, self.RULES)]

    def test_multiline_static_declarations_are_constants(self):
        code = """
            final class A {
              static const String _failed =
                  'Could not load the notes; '
                  'try again';
              static const Map<String, String> _labels = <String, String>{
                'dou': 'DOU',
              };
              static final RegExp _spaces = RegExp(r'\\s+');
            }
        """
        self.assertEqual(self.lines(WIDGETS + "a_widget.dart", code), [])

    def test_data_layer_keys_and_arguments_are_violations(self):
        code = """
            final class NoteModel {
              NoteModel(Map<String, dynamic> json) : id = json['id'] as String;
              List<String> get args => <String>['list', '--json'];
            }
        """
        self.assertEqual(self.lines("features/notes/data/models/note_model.dart", code), [3, 4, 4])

    def test_enum_labels_are_violations(self):
        code = """
            enum Kind {
              image('Images'),
              video(_videoLabel);

              static const String _videoLabel = 'Video';

              final String label;
              const Kind(this.label);
            }
        """
        self.assertEqual(self.lines("features/notes/domain/entities/kind.dart", code), [3])

    def test_logs_throws_and_interpolated_text_are_violations(self):
        code = """
            final class A {
              void f(int total, bool stopped, List<String> args) {
                _logger.i(
                  'Load: success — '
                  '$total done',
                );
                final String s = '${args.join(' ')} ${stopped ? ', stopped' : ''}';
                throw StateError('broken');
              }
            }
        """
        self.assertEqual(self.lines("features/notes/data/a.dart", code), [5, 6, 8, 9])

    def test_constants_whitespace_and_comments_are_not_violations(self):
        code = """
            import 'package:x/y.dart';

            final class A {
              static const String _loadSuccess = 'Load: success — ';
              static const String _done = ' done';

              void f(int total, List<String> args) {
                _logger.i('$_loadSuccess$total$_done');
                final String s = '${args.join(' ')}\\n$total';
                // see 'https://example.com'
              }
            }
        """
        self.assertEqual(self.lines("features/notes/data/a.dart", code), [])

    def test_inline_literal_equal_to_a_constant_is_still_a_violation(self):
        code = """
            final class A {
              static const String _key = 'id';
              String f(Map<String, String> m) => m['id']!;
            }
        """
        self.assertEqual(self.lines("features/notes/data/a.dart", code), [4])


class DartdocPublicTest(unittest.TestCase):
    RULES = {"dartdoc_public"}

    def messages(self, code: str, path: str = "features/notes/data/a.dart") -> list[tuple[int, str]]:
        with tempfile.TemporaryDirectory() as tmp:
            lib = Path(tmp) / "lib"
            file = lib / path
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_text(textwrap.dedent(code), encoding="utf-8")
            with contextlib.redirect_stdout(io.StringIO()):
                report = linter.analyze(str(lib), self.RULES, json_output=True)
            return [(v.line, v.message.split(" missing")[0]) for r in report.results for v in r.violations]

    def test_every_kind_of_public_declaration_is_checked(self):
        code = """
            /// Documented.
            final class Store {
              final String name;

              Store(this.name);

              Store.empty() : name = '';

              factory Store.of(String name) => Store(name);

              Future<void> save(String text) async {}

              String? find(String id) => null;

              Map<String, List<Note>> group() => {};

              Note first() => throw StateError('');

              bool get isEmpty => true;

              set label(String value) {}

              Future<Result<void>> call() async => Result.ok;
            }

            int count() => 0;

            WatchNotesUseCase get watchNotesUseCase => di<WatchNotesUseCase>();
        """
        self.assertEqual(self.messages(code), [
            (4, "Public field 'name'"),
            (6, "Public constructor 'Store'"),
            (8, "Public constructor 'Store.empty'"),
            (10, "Public constructor 'Store.of'"),
            (12, "Public method 'save'"),
            (14, "Public method 'find'"),
            (16, "Public method 'group'"),
            (18, "Public method 'first'"),
            (20, "Public getter 'isEmpty'"),
            (22, "Public setter 'label'"),
            (24, "Use case call() method"),
            (27, "Public function 'count'"),
            (29, "Public getter 'watchNotesUseCase'"),
        ])

    def test_documented_private_override_and_local_are_not_violations(self):
        code = """
            /// Documented.
            sealed class Shape {
              const Shape();

              /// Documented through an annotation.
              @visibleForTesting
              void reset() {}

              @override
              String toString() => 'Shape';

              final Future<Result<void>> Function(String text) _add;

              void _helper() {
                void local() {}
                final String text = 'void fake() {}';
              }
            }

            final class _Private {
              void open() {}
            }

            /// Documented.
            enum Kind {
              image(_imageLabel),
              video(_videoLabel);

              static const String _imageLabel = 'Images';
              static const String _videoLabel = 'Video';

              /// Shown in the UI.
              final String label;

              /// Creates the kind.
              const Kind(this.label);
            }

            /// Documented.
            final class Widget2 extends StatelessWidget {
              /// Creates it.
              const Widget2({
                required this.title,
                super.key,
              });

              /// Title.
              final String title;

              @override
              Widget build(BuildContext context) => Text(title);
            }

            Future<void> main() async {}
        """
        self.assertEqual(self.messages(code), [])


class LinterFixesTest(unittest.TestCase):
    def test_override_needs_no_dartdoc(self):
        code = """
            /// A task.
            final class Task implements Job {
              @override
              void log(String line) => print(line);

              void run() {}
            }
        """
        found = run({"features/notes/data/task.dart": code}, {"dartdoc_public"})
        self.assertEqual([line for _, _, line in found], [7])

    def test_numbers_in_strings_and_multiline_consts_are_not_magic(self):
        code = """
            final class A {
              static const String _tip =
                  'Length limit (200–20,000 words), e.g. 2026-09-09.';
              static const List<int> _limits = <int>[
                5, 10, 20, 50,
              ];
              double f(double x) => x * 37; // 99 in a comment
            }
        """
        found = run({WIDGETS + "a_widget.dart": code}, {"magic_numbers"})
        self.assertEqual([line for _, _, line in found], [8])

    def test_no_controller_in_ui_counts_created_elements_only(self):
        received = """
            final class InputWidget extends StatefulWidget {
              final TextEditingController controller;
              const InputWidget({required this.controller});
            }

            class _InputState extends State<InputWidget> {
              late final FocusNode _focus;

              @override
              void initState() {
                super.initState();
                _focus = FocusNode();
              }
            }
        """
        created = """
            class _FormState extends State<FormWidget> {
              final TextEditingController _a = TextEditingController();
              final TextEditingController _b = TextEditingController();
              final FocusNode _focus = FocusNode();
            }
        """
        self.assertEqual(run({WIDGETS + "input_widget.dart": received}, {"no_controller_in_ui"}), [])
        self.assertEqual(len(run({WIDGETS + "form_widget.dart": created}, {"no_controller_in_ui"})), 1)

    def test_watching_widget_creates_resources_with_create_once(self):
        good = """
            final class SearchWidget extends WatchingWidget {
              @override
              Widget build(BuildContext context) {
                final TextEditingController text = createOnce(_createText, dispose: _disposeText);
                return TextField(controller: text);
              }

              static TextEditingController _createText() => TextEditingController();
            }
        """
        bad = """
            final class SearchWidget extends WatchingWidget {
              @override
              Widget build(BuildContext context) {
                final TextEditingController text = TextEditingController();
                return TextField(controller: text);
              }
            }
        """
        self.assertEqual(run({WIDGETS + "search_widget.dart": good}, {"controller_lifecycle"}), [])
        found = run({WIDGETS + "search_widget.dart": bad}, {"controller_lifecycle"})
        self.assertEqual([line for _, _, line in found], [2])

    def test_controller_lifecycle_is_checked_per_class(self):
        code = """
            final class PageWidget extends StatefulWidget {
              @override
              State<PageWidget> createState() => _PageState();
            }

            class _PageState extends State<PageWidget> {
              late final ValueNotifier<int> _count;

              @override
              void initState() {
                super.initState();
                _count = ValueNotifier<int>(0);
              }

              @override
              void dispose() {
                _count.dispose();
                super.dispose();
              }
            }

            final class _LabelWidget extends StatelessWidget {
              final ValueListenable<int> count;
              const _LabelWidget({required this.count});
            }

            final class _BadWidget extends StatelessWidget {
              final ValueNotifier<int> count = ValueNotifier<int>(0);
            }
        """
        found = run({WIDGETS + "page_widget.dart": code}, {"controller_lifecycle"})
        self.assertEqual([line for _, _, line in found], [28])


class FolderNamingTest(unittest.TestCase):
    def test_file_directly_in_domain(self):
        found = run({"core/domain/result.dart": "final class Result {}\n"}, {"folder_naming"})
        self.assertIn(("result.dart", "folder_naming", 0), found)


class FunctionTypeFieldTest(unittest.TestCase):
    def test_multiline_function_type_field_is_not_a_method(self):
        code = """
            /// Routes.
            final class LoreRoutes {
              final Future<Result<List<Passage>>> Function({
                required String query,
                int limit,
              })
              _findPassages;

              /// Creates the routes.
              const LoreRoutes({required this._findPassages});
            }
        """
        self.assertEqual(run({"features/a/presentation/routes/lore_routes.dart": code}, {"dartdoc_public"}), [])


class IgnorePathsTest(unittest.TestCase):
    """Folders listed in .clean_arch_ignore (global, local) or --ignore-paths are not seen by the linter."""

    FILES = {
        "pubspec.yaml": "name: app\n",
        "lib/features/a/data/data_sources/.gitkeep": "",
        "lib/features/a/data/models/.gitkeep": "",
        "lib/features/a/data/repositories/.gitkeep": "",
        "lib/features/a/domain/entities/.gitkeep": "",
        "lib/features/a/domain/repositories/.gitkeep": "",
        "lib/features/a/domain/use_cases/.gitkeep": "",
        "lib/features/a/presentation/pages/a_page.dart": "/// A.\nfinal class APage {}\n",
        "lib/features/a/presentation/widgets/.gitkeep": "",
        "lib/features/a/presentation/di/.gitkeep": "",
        "lib/features/a/presentation/controllers/.gitkeep": "",
        "lib/features/a/presentation/routes/notes.dart": "final class Notes {}\n",
    }

    def setUp(self):
        self._global = linter.GLOBAL_IGNORE_FILE
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        linter.GLOBAL_IGNORE_FILE = self.root / "skill" / ".clean_arch_ignore"
        for rel, code in self.FILES.items():
            path = self.root / "app" / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(code, encoding="utf-8")

    def tearDown(self):
        linter.GLOBAL_IGNORE_FILE = self._global
        self.tmp.cleanup()

    def lint(self, target: str = "lib", **kwargs) -> list[tuple[str, str]]:
        with contextlib.redirect_stdout(io.StringIO()):
            report = linter.analyze(str(self.root / "app" / target), {"folder_naming", "naming_file", "dartdoc_public"},
                                    json_output=True, **kwargs)
        return sorted({(Path(r.file).name, v.rule) for r in report.results for v in r.violations})

    def test_not_ignored_folder_is_reported(self):
        found = self.lint()
        self.assertIn(("notes.dart", "dartdoc_public"), found)
        self.assertTrue(any(rule == "folder_naming" for _, rule in found))

    def test_local_ignore_file_with_glob_and_comment(self):
        (self.root / "app" / ".clean_arch_ignore").write_text(
            "# server folders\n\nlib/features/*/presentation/routes/  # trailing slash and comment\n", encoding="utf-8")
        self.assertEqual(self.lint(), [])

    def test_global_ignore_file(self):
        linter.GLOBAL_IGNORE_FILE.parent.mkdir(parents=True)
        linter.GLOBAL_IGNORE_FILE.write_text("lib/features/a/presentation/routes\n", encoding="utf-8")
        self.assertEqual(self.lint(), [])

    def test_cli_paths_and_feature_target(self):
        self.assertEqual(self.lint("lib/features/a", ignore_paths=["./lib/features/a/presentation/routes"]), [])

    def test_ignored_file_is_not_counted(self):
        with contextlib.redirect_stdout(io.StringIO()):
            report = linter.analyze(str(self.root / "app" / "lib"), {"dartdoc_public"}, json_output=True,
                                    ignore_paths=["lib/features/a/presentation/routes/notes.dart"])
        self.assertEqual(report.total_files, 1)

    def test_prefix_of_a_name_is_not_a_match(self):
        self.assertIn(("notes.dart", "dartdoc_public"), self.lint(ignore_paths=["lib/features/a/presentation/rout"]))


class ExampleAppTest(unittest.TestCase):
    def test_example_app_has_no_violations(self):
        with contextlib.redirect_stdout(io.StringIO()):
            report = linter.analyze(str(EXAMPLE_LIB), linter.ALL_RULES.copy(), json_output=True)
        violations = [(r.file, v.rule, v.line, v.message) for r in report.results for v in r.violations]
        self.assertEqual(violations, [])

    def test_every_rule_has_a_checker(self):
        self.assertEqual(linter.ALL_RULES, set(linter.CHECKERS))


if __name__ == "__main__":
    unittest.main()
