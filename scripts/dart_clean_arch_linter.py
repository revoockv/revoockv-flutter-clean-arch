#!/usr/bin/env python3
"""
Automated Dart code analyzer for revoockv Flutter Clean Architecture.

Scans .dart files and reports violations of the clean architecture rules.
Exits with code 1 when violations are found (for CI integration).
Usage:
  python scripts/dart_clean_arch_linter.py <path> [--strict] [--ignore <rule>]
  python scripts/dart_clean_arch_linter.py lib/features/song --strict

Rules (all enabled by default):
  naming_file        — file names must follow conventions (_widget.dart, _page.dart, _use_case.dart, _controller.dart)
  naming_class       — widget/page classes must end with _Widget/_Page suffix
  magic_numbers      — numbers must be static const (exceptions: -1, 0, 1, 2)
  magic_strings      — string literals in widget code must be static const
  magic_colors       — Color/Colors references must be static const
  widget_helpers     — no widget-returning helper methods inside page/widget classes (use widgets/ folder)
  inline_callbacks   — no inline closures in callback properties (onPressed, onChanged, etc.)
  import_violation   — presentation (widgets, controllers) must not import the data layer, repositories or use cases, nor call di/GetIt — only getters
  setstate_usage     — no setState() calls (UI state lives in ValueNotifiers of a controller)
  stateful_no_lifecycle — StatefulWidget/WatchingStatefulWidget must have initState/dispose/didUpdateWidget
  dartdoc_public     — every public declaration (class, function, method, getter, constructor, field) has /// documentation
  no_state_in_di     — no instanceName keys and no ValueNotifier/ValueListenable registered in GetIt
  widget_stateless   — StatelessWidget preferred; StatefulWidget only with lifecycle methods
  watching_widget    — Watching widgets call watch()/registerHandler()/createOnce(); other widgets never do; no watchValue/watchIt
  no_controller_in_ui — complicated stateful logic must be in controllers/ folder
  static_const_order — static const fields must be before constructor
  no_build_return    — private helper methods returning Widget must be separate StatelessWidget in widgets/
    folder_naming      — feature folder structure must match conventions
    async_gap_context_mounted — Navigator/ScaffoldMessenger calls after await must check context.mounted or mounted first
    widget_key_parameter   — public widget constructors must have named 'key' parameter
    controller_lifecycle   — a widget owns its controllers: createOnce(…, dispose: …) in WatchingWidget, or initState/dispose in State
    widget_methods     — no private methods returning Widget type (anywhere, including widgets/ folder)
    stateless_with_controllers — StatelessWidget calling controller.init()/dispose() must be StatefulWidget
    value_listenable_exposure — domain, repository public API and getters expose ValueListenable, never ValueNotifier
    watch_order        — watch()/registerHandler() only at the top level of build(), never inside if/for/switch/callbacks
    static_const_in_state_class — static const of a stateful widget live in its State class
    magic_numbers_in_layout — numbers in EdgeInsets/Size/Offset/Color must be static const
    theme_import       — values shared by features live in lib/core/presentation/theme.dart (AppTheme)
Default ignored files (cannot be disabled): firebase_options.dart

"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Sequence

__version__ = "0.7.0"
# ── Rule definitions ────────────────────────────────────────────────

ALL_RULES = {
    "naming_file",
    "naming_class",
    "magic_numbers",
    "magic_strings",
    "magic_colors",
    "widget_helpers",
    "inline_callbacks",
    "import_violation",
    "setstate_usage",
    "stateful_no_lifecycle",
    "dartdoc_public",
    "no_state_in_di",
    "widget_stateless",
    "watching_widget",
    "no_controller_in_ui",
    "static_const_order",
    "no_build_return",
    "folder_naming",
    "async_gap_context_mounted",
    "widget_key_parameter",
    "controller_lifecycle",
    "widget_methods",
    "stateless_with_controllers",
    "static_const_in_state_class",
    "magic_numbers_in_layout",
    "theme_import",
    "value_listenable_exposure",
    "watch_order",
}

# Files ignored by default (generated/config files that should not be linted)
DEFAULT_IGNORE_FILES = [
    "firebase_options.dart",
]

# Numbers allowed without static const
ALLOWED_NUMBERS = {-1, 0, 1, 2}

# Callback property names that must not receive inline closures
CALLBACK_PROPERTIES = {
    "onPressed", "onChanged", "onSubmitted", "onTap", "onLongPress",
    "onTapDown", "onTapUp", "onTapCancel", "onPanStart", "onPanUpdate",
    "onPanEnd", "onPanCancel", "onScaleStart", "onScaleUpdate", "onScaleEnd",
    "onSelected", "onDeleted", "onLoaded", "onError", "onResult",
    "onValueChange", "onAnimationComplete", "onDismissed", "onEnded",
}

# Patterns that indicate presentation layer files
PRESENTATION_PATH_PATTERNS = [r"presentation/"]

# Any watch_it call that is bound to its position in build():
#   watch(watch<Name>UseCase()) / watch(controller)           — show state
#   registerHandler(target: ..., handler: _onX)               — react to state (side effects)
#   createOnce(_createController, dispose: _disposeController) — own a controller
WATCH_IT_ORDERED_CALL = r'(?<![\w.])(?:watch|registerHandler|createOnce)\s*\('

# Patterns that indicate domain layer files
DOMAIN_PATH_PATTERNS = [r"domain/"]

# Patterns that indicate data layer files
DATA_PATH_PATTERNS = [r"data/"]

# Widget-returning method patterns (helper methods that should be separate widgets)
WIDGET_RETURN_TYPE = r"(?:Stateless)?Widget"
# ── Data structures ─────────────────────────────────────────────────

@dataclass
class Violation:
    file: str
    line: int
    rule: str
    message: str
    snippet: str = ""

    def to_dict(self) -> dict:
        return asdict(self)
@dataclass
class AnalysisResult:
    file: str
    violations: list[Violation] = field(default_factory=list)

    @property
    def has_violations(self) -> bool:
        return len(self.violations) > 0
@dataclass
class AnalysisReport:
    total_files: int = 0
    total_violations: int = 0
    results: list[AnalysisResult] = field(default_factory=list)
    rules_enabled: set[str] = field(default_factory=set)

    @property
    def has_violations(self) -> bool:
        return self.total_violations > 0

    def to_dict(self) -> dict:
        return {
            "total_files": self.total_files,
            "total_violations": self.total_violations,
            "rules_enabled": sorted(self.rules_enabled),
            "results": [
                {
                    "file": r.file,
                    "violations_count": len(r.violations),
                    "violations": [v.to_dict() for v in r.violations],
                }
                for r in self.results
            ],
        }
# ── Helpers ─────────────────────────────────────────────────────────

def _read_file(path: Path) -> str:
    return path.read_text(encoding="utf-8")
def _line_at(content: str, line_num: int) -> str:
    lines = content.splitlines()
    if 1 <= line_num <= len(lines):
        return lines[line_num - 1].strip()
    return ""
def _is_presentation_file(file_path: str) -> bool:
    return any(re.search(p, file_path) for p in PRESENTATION_PATH_PATTERNS)
def _is_domain_file(file_path: str) -> bool:
    return any(re.search(p, file_path) for p in DOMAIN_PATH_PATTERNS)
def _is_data_file(file_path: str) -> bool:
    return any(re.search(p, file_path) for p in DATA_PATH_PATTERNS)
def _relative_to_lib(file_path: str, lib_root: str) -> str:
    lib_root = lib_root.rstrip("/")
    if file_path.startswith(lib_root):
        return file_path[len(lib_root):]
    return file_path
def _get_class_name(line: str) -> str | None:
    m = re.search(r'\bclass\s+(\w+)', line)
    return m.group(1) if m else None
def _is_public_class(line: str) -> bool:
    return bool(re.search(r'\bclass\s+(?!_)[A-Z]\w+', line))
def _is_public_method(line: str) -> bool:
    return bool(re.search(r'\b(?:void|int|string|bool|List|Map|Set|Widget|Future|ValueNotifier|Stream)\s+[a-z]\w+\s*\(', line))
def _is_framework_method(line: str) -> bool:
    """Check if a method is a framework/lifecycle method that doesn't need dartdoc."""
    framework_names = [
        'build', 'initState', 'dispose', 'didUpdateWidget', 'reassemble',
        'debugFillProperties', 'createState', 'reloadStyle', 'didChangeDependencies',
        'paint', 'sizeChanged', 'handleAction', 'handleDidPop', 'handleDidPush',
        'handleDidChangeMetrics', 'handleDidChangePlatformBrightness',
        'handleWindowPadding', 'handleWindowMetrics', 'handleFirstFrame',
    ]
    for name in framework_names:
        if re.search(r'\b' + name + r'\s*\(', line):
            return True
    return False
def _is_use_case_call(method_line: str) -> bool:
    return bool(re.search(r'\bFuture<.*>\s+call\s*\(', method_line)) or \
           bool(re.search(r'.*>\s+call\s*\(', method_line))
def _is_static_const(line: str) -> bool:
    # Only class-member `static const` counts. File-top-level `const Type _name`
    # declarations are NOT accepted — simple constants must live inside the
    # owning class as private static const members.
    return bool(re.search(r'\bstatic\s+const\b', line))
def _is_static_const_block_start(line: str) -> bool:
    return bool(re.search(r'\bstatic\s+const', line))
def _has_initstate(content: str) -> bool:
    return bool(re.search(r'\bvoid\s+initState\s*\(', content))
def _has_dispose(content: str) -> bool:
    return bool(re.search(r'\bvoid\s+dispose\s*\(', content))
def _has_didupdatewidget(content: str) -> bool:
    return bool(re.search(r'\bvoid\s+didUpdateWidget\s*\(', content))
def _has_lifecycle(content: str) -> bool:
    return _has_initstate(content) or _has_dispose(content) or _has_didupdatewidget(content)
def _is_stateful_widget_class(content: str) -> bool:
    return bool(re.search(r'\b(class|extends)\s+\w*(StatefulWidget|State<\w+,\s*\w+>)', content)) or \
           bool(re.search(r'\bextends\s+(StatefulWidget|State<\w+,\s*\w+>)', content)) or \
           bool(re.search(r'\b(class|extends)\s+\w*(WatchingStatefulWidget)', content)) or \
           bool(re.search(r'\bextends\s+WatchingStatefulWidget', content))
def _has_widget_return_type(line: str) -> bool:
    return bool(re.search(rf'\b{WIDGET_RETURN_TYPE}\s+[a-z_]\w*\s*\(', line))
def _is_private_method(line: str) -> bool:
    return bool(re.search(rf'\b{WIDGET_RETURN_TYPE}\s+_+\w+\s*\(', line))
def _is_in_widgets_folder(file_path: str) -> bool:
    return bool(re.search(r'widgets/', file_path))
def _is_in_controllers_folder(file_path: str) -> bool:
    return bool(re.search(r'controllers/', file_path))
def _is_in_di_folder(file_path: str) -> bool:
    return bool(re.search(r'/di/', file_path))
def _is_private_widget_class(content: str) -> bool:
    return bool(re.search(r'\bclass\s+_+\w+.*extends\s+(Stateless)?Widget', content))
def _get_indent(line: str) -> str:
    m = re.match(r'^(\s*)', line)
    return m.group(1) if m else ""
def _has_dartdoc_before(line: str, prev_lines: list[str]) -> bool:
    for pl in reversed(prev_lines):
        stripped = pl.strip()
        if stripped == "":
            continue
        if stripped.startswith("///"):
            return True
        return False
    return False
def _has_dartdoc_before_line(content: str, line_num: int) -> bool:
    lines = content.splitlines()
    for i in range(line_num - 2, -1, -1):
        stripped = lines[i].strip()
        if stripped == "":
            continue
        return stripped.startswith("///")
    return False
def _previous_code_line(lines: list[str], line_num: int) -> str:
    """The stripped non-empty line above 1-based [line_num] ("" at the top)."""
    for i in range(line_num - 2, -1, -1):
        if lines[i].strip():
            return lines[i].strip()
    return ""
def _has_dartdoc_before_method(content: str, line_num: int) -> bool:
    lines = content.splitlines()
    for i in range(line_num - 2, -1, -1):
        stripped = lines[i].strip()
        if stripped == "":
            continue
        return stripped.startswith("///")
    return False
# ── Checkers ────────────────────────────────────────────────────────

def check_naming_file(result: AnalysisResult) -> None:
    """Check file naming conventions."""
    fp = result.file
    basename = Path(fp).name

    # Widget files
    if "widgets/" in fp and not basename.endswith("_widget.dart"):
        result.violations.append(Violation(
            file=fp, line=0, rule="naming_file",
            message=f"Widget file '{basename}' must end with _widget.dart",
        ))

    # Page files
    if "pages/" in fp and not basename.endswith("_page.dart"):
        result.violations.append(Violation(
            file=fp, line=0, rule="naming_file",
            message=f"Page file '{basename}' must end with _page.dart",
        ))

    # Use case files
    if "usecases/" in fp or "use_cases/" in fp:
        if not basename.endswith("_use_case.dart"):
            result.violations.append(Violation(
                file=fp, line=0, rule="naming_file",
                message=f"Use case file '{basename}' must end with _use_case.dart",
            ))

    # Controller files
    if "controllers/" in fp and not basename.endswith(("_controller.dart", "_state.dart")):
        result.violations.append(Violation(
            file=fp, line=0, rule="naming_file",
            message=f"Controller file '{basename}' must end with _controller.dart (or _state.dart for its state class)",
        ))

    # DI files
    if "di/" in fp:
        if "_di.dart" not in basename and "_getters.dart" not in basename:
            result.violations.append(Violation(
                file=fp, line=0, rule="naming_file",
                message=f"DI file '{basename}' must be named <feature>_di.dart or <feature>_getters.dart",
            ))
def check_naming_class(result: AnalysisResult) -> None:
    """Check widget/page class naming suffixes."""
    content = _read_file(Path(result.file))
    lines = content.splitlines()

    for i, line in enumerate(lines, 1):
        class_name = _get_class_name(line)
        if not class_name:
            continue

        # Widget classes (StatelessWidget, StatefulWidget, WatchingWidget, WatchingStatefulWidget)
        # must end with Widget suffix — but skip if the class name already ends with "Page"
        # (page classes use _Page suffix, not _Widget)
        if re.search(r'\bextends\s+StatelessWidget', line) or \
           re.search(r'\bextends\s+StatefulWidget', line) or \
           re.search(r'\bextends\s+WatchingWidget', line) or \
           re.search(r'\bextends\s+WatchingStatefulWidget', line):
            if not class_name.endswith("Widget") and not class_name.endswith("Page"):
                result.violations.append(Violation(
                    file=result.file, line=i, rule="naming_class",
                    message=f"Widget class '{class_name}' must end with Widget suffix",
                    snippet=_line_at(content, i),
                ))

        # Page classes (StatelessPage, StatefulPage) must end with _Page suffix
        if re.search(r'\bextends\s+StatelessPage', line) or \
           re.search(r'\bextends\s+StatefulPage', line):
            if not class_name.endswith("_Page"):
                result.violations.append(Violation(
                    file=result.file, line=i, rule="naming_class",
                    message=f"Page class '{class_name}' must end with _Page suffix",
                    snippet=_line_at(content, i),
                ))

def check_magic_numbers(result: AnalysisResult) -> None:
    """Check for magic numbers not declared as static const.

    Numbers inside string literals and comments are text, not magic numbers;
    every line of a `static const` / `static final` declaration (also one that
    spans several lines) is a declaration.
    """
    content = _read_file(Path(result.file))
    code, _ = _scan_dart(content)
    lines = code.splitlines()
    declared_lines: set[int] = set()
    for m in _CONST_DECLARATION.finditer(code):
        first = code.count("\n", 0, m.start()) + 1
        last = code.count("\n", 0, _statement_end(code, m.end())) + 1
        declared_lines.update(range(first, last + 1))

    # Track static const declarations in this file
    static_const_numbers: set[int] = set()
    for line in lines:
        if _is_static_const(line):
            nums = re.findall(r'(?<!\w)(-?\d+\.?\d*)(?!\w)', line)
            for n in nums:
                try:
                    static_const_numbers.add(float(n))
                except ValueError:
                    pass

    # Numbers to skip (commonly used legitimately)
    skip_patterns = [
        r'//\s*.*\d+',  # comments
        r"import\s+'",  # imports
        r"package:",  # package names
        r'instanceName:',  # GetIt keys
        r"Duration\(",  # Duration values
        r"EdgeInsets\.",  # EdgeInsets values
        r"Size\(",  # Size values
        r"MediaQuery",  # MediaQuery values
        r"double\.parse",  # parsing
        r'\.height\s*=',  # layout assignments
        r'\.width\s*=',  # layout assignments
        r'\.padding\s*=',  # padding assignments
        r'\.spacing\s*=',  # spacing assignments
        r'\.radius\s*=',  # radius assignments
        r'\.size\s*=',  # size assignments
        r'\.fontSize\s*=',  # fontSize assignments
        r'\.fontWeight\s*=',  # fontWeight assignments
        r'\.opacity\s*=',  # opacity assignments
        r'\.duration\s*=',  # duration assignments
        r'\.delay\s*=',  # delay assignments
        r'\.iterations\s*=',  # animation iterations
        r'\.curve\s*=',  # animation curves
        r'\.iterations\s*=',  # iterations
        r'\.repeat\s*=',  # repeat
        r'\.count\s*=',  # count
        r'\.length\s*=',  # length
        r'\.index\s*=',  # index
        r'\.offset\s*=',  # offset
        r'\.max\s*=',  # max
        r'\.min\s*=',  # min
        r'\.clamp\s*\(',  # clamp
        r'\.toDouble\s*\(',  # toDouble
        r'\.toInt\s*\(',  # toInt
        r'\.toString\s*\(',  # toString
        r'==\s*-?1\b',  # comparisons with -1
        r'!=\s*-?1\b',  # comparisons with -1
        r'==\s*0\b',  # comparisons with 0
        r'!=\s*0\b',  # comparisons with 0
        r'==\s*1\b',  # comparisons with 1
        r'!=\s*1\b',  # comparisons with 1
        r'==\s*2\b',  # comparisons with 2
        r'!=\s*2\b',  # comparisons with 2
    ]

    for i, line in enumerate(lines, 1):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith("//"):
            continue

        # Skip imports
        if stripped.startswith("import ") or stripped.startswith("export "):
            continue

        # Skip static const / final declarations
        if _is_static_const(line) or i in declared_lines:
            continue

        # Skip lines that are layout-related (already tracked)
        is_layout_line = False
        for pattern in skip_patterns:
            if re.search(pattern, line):
                is_layout_line = True
                break
        if is_layout_line:
            continue

        # Skip GetIt keys
        if "instanceName:" in line:
            continue

        # Find magic numbers
        # Match numbers that are not -1, 0, 1, 2
        # `$3` is a record field, not a number.
        numbers = re.finditer(r'(?<![\w$])(-?\d+\.?\d*)(?!\w)', line)
        for m in numbers:
            num_str = m.group(1)
            try:
                num = float(num_str)
            except ValueError:
                continue

            if num in ALLOWED_NUMBERS:
                continue

            # Check if this number is in a static const block (already declared)
            if num in static_const_numbers:
                continue

            # Check if it's in a skip pattern context
            is_skip = False
            for pattern in skip_patterns:
                if re.search(pattern, line):
                    is_skip = True
                    break
            if is_skip:
                continue

            result.violations.append(Violation(
                file=result.file, line=i, rule="magic_numbers",
                message=f"Magic number '{num_str}' should be declared as static const",
                snippet=_line_at(content, i),
            ))
@dataclass
class _DartString:
    """A string literal found by [_scan_dart]."""
    start: int
    end: int
    # Text outside `$name` / `${…}`: the whole value of a plain literal,
    # the pieces between the interpolations of an interpolated one.
    segments: list[str]
    interpolated: bool


def _scan_dart(content: str) -> tuple[str, list[_DartString]]:
    """Split Dart source into code and string literals.

    Returns the source with every comment and string literal blanked out
    (same length, newlines kept — so offsets and brackets in code stay valid)
    and every string literal, the ones inside `${…}` included.
    """
    n = len(content)
    masked = list(content)
    strings: list[_DartString] = []

    def blank(a: int, b: int) -> None:
        for k in range(a, b):
            if masked[k] != "\n":
                masked[k] = " "

    def read_string(start: int, i: int) -> int:
        """[i] at the opening quote, [start] at the `r` of a raw string; returns the end."""
        raw = start != i
        quote = content[i]
        delim = quote * 3 if content.startswith(quote * 3, i) else quote
        j = i + len(delim)
        segments: list[str] = []
        current: list[str] = []
        interpolated = False
        while j < n:
            if content.startswith(delim, j):
                j += len(delim)
                break
            ch = content[j]
            if ch == "\n" and len(delim) == 1:
                break
            if ch == "\\" and not raw:
                current.append(content[j:j + 2])
                j += 2
                continue
            if ch == "$" and not raw and j + 1 < n and (content[j + 1] == "{" or content[j + 1].isalpha() or content[j + 1] == "_"):
                interpolated = True
                segments.append("".join(current))
                current = []
                if content[j + 1] == "{":
                    j = skip_code(j + 2)
                else:
                    j += 1
                    while j < n and (content[j].isalnum() or content[j] == "_"):
                        j += 1
                continue
            current.append(ch)
            j += 1
        segments.append("".join(current))
        strings.append(_DartString(start, j, segments, interpolated))
        return j

    def literal_start(i: int) -> int:
        """Offset of the literal whose quote is at [i] (its `r` prefix included)."""
        if i > 0 and content[i - 1] in "rR" and not (i > 1 and (content[i - 2].isalnum() or content[i - 2] == "_")):
            return i - 1
        return i

    def skip_code(j: int) -> int:
        """Code inside `${…}`: returns the offset after the matching `}`."""
        depth = 0
        while j < n:
            ch = content[j]
            if ch in "'\"":
                j = read_string(literal_start(j), j)
                continue
            if ch in "({[":
                depth += 1
            elif ch in ")]}":
                if depth == 0 and ch == "}":
                    return j + 1
                depth -= 1
            j += 1
        return n

    i = 0
    while i < n:
        ch = content[i]
        if content.startswith("//", i):
            j = content.find("\n", i)
            j = n if j == -1 else j
            blank(i, j)
            i = j
        elif content.startswith("/*", i):
            j = content.find("*/", i + 2)
            j = n if j == -1 else j + 2
            blank(i, j)
            i = j
        elif ch in "'\"":
            start = literal_start(i)
            end = read_string(start, i)
            blank(start, end)
            i = end
        else:
            i += 1
    strings.sort(key=lambda s: s.start)
    return "".join(masked), strings


def _statement_end(code: str, start: int) -> int:
    """Offset of the `;` that ends the statement starting at [start] (brackets balanced)."""
    depth = 0
    for j in range(start, len(code)):
        ch = code[j]
        if ch in "({[":
            depth += 1
        elif ch in ")]}":
            depth -= 1
            if depth < 0:
                return j
        elif ch == ";" and depth == 0:
            return j
    return len(code)


# Declarations whose literals are constants: `static const` / `static final`
# (a RegExp or a list built once) up to the `;` that ends them.
_CONST_DECLARATION = re.compile(r"\bstatic\s+(?:const|final)\b")

# Directives: their strings are URIs, not text.
_DIRECTIVE = re.compile(r"^[ \t]*(?:import|export|part|library)\b", re.M)

# Framework-only lines (DI registration and the like).
_SKIP_LINE = re.compile(
    r"instanceName:|GetIt\.instance|getIt\.|registerSingleton|registerLazySingleton|registerFactory"
)

# Values that look like framework enum names (TextAlign.center, …).
_FRAMEWORK_VALUE = re.compile(
    r"\.(center|start|end|left|right|top|bottom|inherit|normal|bold|italic|w[1-9]|visible|hidden|clip|fade|scroll|expand|none|all|horizontal|vertical)"
)

# Escapes that only add whitespace.
_WHITESPACE_ESCAPES = re.compile(r"\\[ntr]")


def _is_text(segment: str) -> bool:
    """Whether [segment] holds more than whitespace or a number."""
    value = _WHITESPACE_ESCAPES.sub("", segment).strip()
    if not value:
        return False
    try:
        float(value)
        return False
    except ValueError:
        return True


def _magic_string_literals(content: str) -> list[_DartString]:
    """The literals of [content] that `magic_strings` reports."""
    code, strings = _scan_dart(content)
    lines = content.splitlines()
    exempt: list[tuple[int, int]] = []
    for m in _CONST_DECLARATION.finditer(code):
        exempt.append((m.start(), _statement_end(code, m.end())))
    for m in _DIRECTIVE.finditer(code):
        exempt.append((m.start(), _statement_end(code, m.end())))
    found: list[_DartString] = []
    for s in strings:
        if any(a <= s.start < b for a, b in exempt):
            continue
        texts = [segment for segment in s.segments if _is_text(segment)]
        if not texts:
            continue
        if not s.interpolated and _FRAMEWORK_VALUE.search(texts[0]):
            continue
        if _SKIP_LINE.search(lines[content.count("\n", 0, s.start)]):
            continue
        found.append(s)
    return found


def check_magic_strings(result: AnalysisResult) -> None:
    """String literals must be private `static const` members of the owning class.

    Applies to every layer and every place — UI text, error messages, log
    messages, exceptions, JSON keys, CLI arguments, enum labels. In an
    interpolated string every text piece between the interpolations is a
    constant too: `'$_searchSuccess${report.total}$_jobsTo${report.path}'`.
    Accepted: literals inside a `static const` / `static final` declaration
    (also when it spans several lines), directives, and pieces that are only
    whitespace or a number.
    """
    content = _read_file(Path(result.file))
    for s in _magic_string_literals(content):
        texts = [segment for segment in s.segments if _is_text(segment)]
        line = content.count("\n", 0, s.start) + 1
        message = (
            f"Text '{texts[0]}' in an interpolated string should be declared as static const"
            if s.interpolated
            else f"String literal '{texts[0]}' should be declared as static const"
        )
        result.violations.append(Violation(
            file=result.file, line=line, rule="magic_strings",
            message=message, snippet=_line_at(content, line),
        ))
def check_magic_colors(result: AnalysisResult) -> None:
    """Check for Color/Colors references that should be static const."""
    content = _read_file(Path(result.file))
    lines = content.splitlines()

    # Track static const Color declarations
    static_const_colors: set[str] = set()
    for line in lines:
        if _is_static_const(line) and ("Color" in line or "Colors" in line):
            colors = re.findall(r'(Colors\.\w+|Color\(\d+\))', line)
            static_const_colors.update(colors)

    for i, line in enumerate(lines, 1):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith("//"):
            continue

        # Skip imports
        if stripped.startswith("import ") or stripped.startswith("export "):
            continue

        # Skip static const declarations
        if _is_static_const(line):
            continue

        # Skip framework type references (not usage)
        if re.search(r'(TextStyle|BoxDecoration|BoxShadow|BorderRadius|Border|EdgeInsets|Offset|Size|Rect|Point|Matrix4|Quaternion|Vector3|Vector2|ColorScheme|MaterialColor|MaterialType|Clip|BlendMode|FilterQuality|ImageFilter|ImageQuality|ImageRepeat|ImageShader|ImageInfo|ImageConfiguration|ImageProvider|ImageStream|ImageCache|ImageCacheConfiguration|ImageChunkEvent|ImageError|ImageErrorListener|ImageErrorWidgetBuilder|ImageFrame|ImageStreamCompleter|ImageStreamListener|ImageTickerProvider|ImageTransformer)\s*\(', line):
            continue

        # Skip framework enum references
        if re.search(r'(TextAlign|TextDirection|TextOverflow|MainAxisAlignment|CrossAxisAlignment|AxisSize|ScrollDirection|ScrollPhysics|ImageQuality|ImageRepeat|Clip|BlendMode|FilterQuality)\.\w+', line):
            continue

        # Find Color/Colors references
        colors = re.finditer(r'(Colors\.\w+|Color\(\d+\))', line)
        for m in colors:
            c = m.group(1)

            # Skip if already declared as static const
            if c in static_const_colors:
                continue

            result.violations.append(Violation(
                file=result.file, line=i, rule="magic_colors",
                message=f"Color reference '{c}' should be declared as static const",
                snippet=_line_at(content, i),
            ))
def check_widget_helpers(result: AnalysisResult) -> None:
    """Check for widget-returning helper methods inside page/widget classes."""
    content = _read_file(Path(result.file))
    lines = content.splitlines()

    # Check if file is in widgets/ folder (allowed to have widget-returning methods)
    in_widgets_folder = _is_in_widgets_folder(result.file)

    # Check if file contains a private widget class (allowed)
    is_private_widget = _is_private_widget_class(content)

    if in_widgets_folder or is_private_widget:
        return

    for i, line in enumerate(lines, 1):
        if _is_private_method(line):
            result.violations.append(Violation(
                file=result.file, line=i, rule="widget_helpers",
                message=f"Widget-returning helper method found — extract to separate StatelessWidget in widgets/ folder",
                snippet=_line_at(content, i),
            ))
def check_inline_callbacks(result: AnalysisResult) -> None:
    """Check for inline closures in callback properties."""
    content = _read_file(Path(result.file))
    lines = content.splitlines()

    for i, line in enumerate(lines, 1):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith("//"):
            continue

        # Skip imports
        if stripped.startswith("import ") or stripped.startswith("export "):
            continue

        # Check for inline callbacks
        for prop in CALLBACK_PROPERTIES:
            pattern = rf'{prop}\s*:\s*(?:\(\w+\)\s*=>|async\s*\(\w+\)\s*=>|\(\)\s*=>|async\s*\(\)\s*=>)'
            if re.search(pattern, line):
                # Allow inline closures that only forward constructor parameters
                # e.g. `onPressed: () => _handleSignOut(context)` is fine because
                # `context` is a constructor parameter being forwarded to a method.
                # Only flag when the closure does actual work (logic, multiple calls, etc.)
                closure_match = re.search(
                    rf'{prop}\s*:\s*((?:async\s*)?\(?(\w+)?\)?\s*=>\s*(.+))',
                    line,
                )
                if closure_match:
                    closure_body = closure_match.group(3).strip()
                    # If the body is a single method call that forwards
                    # constructor parameters (this.xxx or parameter names), allow it.
                    if re.match(r'_\w+\s*\(\s*this\.\w+', closure_body) or \
                       re.match(r'_\w+\s*\(\s*\w+\s*\)', closure_body) and \
                       not re.search(r'\bif\b|\belse\b|\bfor\b|\bwhile\b|\btry\b|\bcatch\b|\breturn\b', closure_body):
                        continue

                result.violations.append(Violation(
                    file=result.file, line=i, rule="inline_callbacks",
                    message=f"Inline closure in '{prop}' callback — extract to private method",
                    snippet=_line_at(content, i),
                ))
                break  # One violation per line is enough
def check_import_violation(result: AnalysisResult) -> None:
    """Check that presentation reaches dependencies only through getters: no data layer, repository or use case imports, no di/GetIt calls."""
    content = _read_file(Path(result.file))
    lines = content.splitlines()

    if not _is_presentation_file(result.file):
        return

    # DI files are allowed to import repositories — they construct them
    if _is_in_di_folder(result.file):
        return

    code, _ = _scan_dart(content)
    code_lines = code.splitlines()

    for i, line in enumerate(lines, 1):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith("//"):
            continue

        # Widgets and controllers reach dependencies only through getters
        if i <= len(code_lines) and re.search(r'(?<![\w.])(?:di\s*(?:<|\(|\.\w)|GetIt\.)', code_lines[i - 1]):
            result.violations.append(Violation(
                file=result.file, line=i, rule="import_violation",
                message="Presentation must not call di / GetIt directly — use <feature>_getters.dart",
                snippet=_line_at(content, i),
            ))
            continue

        # Skip imports that are not from repositories or usecases
        if not (stripped.startswith("import ") or stripped.startswith("export ")):
            continue

        # Controllers are self-contained: use cases come in as method parameters
        if _is_in_controllers_folder(result.file) and re.search(r"(?:['/]di/|_getters\.dart|package:(?:get_it|watch_it)/)", stripped):
            result.violations.append(Violation(
                file=result.file, line=i, rule="import_violation",
                message="Controller must not import getters or DI — take the use case as a method parameter",
                snippet=_line_at(content, i),
            ))
            continue

        # Check for data layer imports (data sources, services, models)
        if re.search(r"['/]data/", stripped) and not re.search(r'repositories?/', stripped):
            result.violations.append(Violation(
                file=result.file, line=i, rule="import_violation",
                message="Presentation must not import the data layer (data sources, services, models) — use <feature>_getters.dart",
                snippet=_line_at(content, i),
            ))
            continue

        # Check for repository imports
        if re.search(r'repositories?/', stripped) or re.search(r'repository/', stripped):
            result.violations.append(Violation(
                file=result.file, line=i, rule="import_violation",
                message=f"Presentation layer must not import repositories directly — use <feature>_getters.dart",
                snippet=_line_at(content, i),
            ))

        # Check for usecase imports
        if re.search(r'use_?cases?/', stripped):
            result.violations.append(Violation(
                file=result.file, line=i, rule="import_violation",
                message=f"Presentation layer must not import use cases directly — use <feature>_getters.dart",
                snippet=_line_at(content, i),
            ))
def check_setstate_usage(result: AnalysisResult) -> None:
    """Check for setState() calls."""
    content = _read_file(Path(result.file))
    lines = content.splitlines()

    for i, line in enumerate(lines, 1):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith("//"):
            continue

        # Skip imports
        if stripped.startswith("import ") or stripped.startswith("export "):
            continue

        # Find setState calls
        if re.search(r'\bsetState\s*\(', line):
            result.violations.append(Violation(
                file=result.file, line=i, rule="setstate_usage",
                message="setState() is forbidden — keep UI state in ValueNotifiers (a controller) and read it with watch(...).value",
                snippet=_line_at(content, i),
            ))
def check_stateful_no_lifecycle(result: AnalysisResult) -> None:
    """Check that StatefulWidget/WatchingStatefulWidget has lifecycle methods."""
    content = _read_file(Path(result.file))

    # Check if this file contains a StatefulWidget or WatchingStatefulWidget
    is_stateful = bool(re.search(r'\b(class|extends)\s+\w*(StatefulWidget|State<\w+,\s*\w+>)', content) or \
                       re.search(r'\bextends\s+StatefulWidget', content) or \
                       re.search(r'\b(class|extends)\s+\w*(WatchingStatefulWidget)', content) or \
                       re.search(r'\bextends\s+WatchingStatefulWidget', content))

    if not is_stateful:
        return

    # Check if it has lifecycle methods
    if not _has_lifecycle(content):
        # Find the line with the class declaration
        lines = content.splitlines()
        for i, line in enumerate(lines, 1):
            if re.search(r'\bclass\s+\w+', line) and \
               (re.search(r'StatefulWidget', line) or re.search(r'WatchingStatefulWidget', line)):
                result.violations.append(Violation(
                    file=result.file, line=i, rule="stateful_no_lifecycle",
                    message="StatefulWidget/WatchingStatefulWidget without initState/dispose/didUpdateWidget — use StatelessWidget",
                    snippet=_line_at(content, i),
                ))
                break
# Words that start a statement or a directive, never a declaration
_NOT_DECLARATION = {
    "return", "if", "else", "for", "while", "do", "switch", "case", "default", "try", "catch",
    "on", "finally", "throw", "rethrow", "await", "yield", "assert", "break", "continue",
    "super", "this", "import", "export", "part", "library", "typedef", "new",
}

# Optional modifiers, an optional type (generics, nullable, records), `get`/`set`, then the name
_DECLARATION = re.compile(
    r'^(?:@\w+(?:\([^)]*\))?\s+)*'
    r'(?P<mods>(?:(?:static|external|abstract|const|final|late|covariant|factory|var)\s+)*)'
    r'(?P<type>(?!(?:get|set|operator)\s)(?:[A-Za-z_$][\w$.]*(?:<[^;{}()=]*>)?\??|\([^()]*\)\??|void)\s+)?'
    r'(?P<accessor>(?:get|set|operator)\s+)?'
    r'(?P<name>[A-Za-z_$][\w$]*)(?:\.(?P<named>[A-Za-z_$][\w$]*))?'
    r'\s*(?P<after><[^>]*>\s*\(|\(|=>|\{|;|=|,)'
)

# Members the framework calls; they never need their own documentation
_FRAMEWORK_MEMBERS = {
    "build", "initState", "dispose", "didUpdateWidget", "didChangeDependencies", "reassemble",
    "deactivate", "activate", "debugFillProperties", "createState", "main",
}


def _doc_above(lines: list[str], line_num: int) -> tuple[bool, bool]:
    """(has a `///` comment, is `@override`) above 1-based [line_num], skipping annotations."""
    is_override = False
    for i in range(line_num - 2, -1, -1):
        stripped = lines[i].strip()
        if not stripped:
            continue
        if stripped.startswith("@"):
            is_override = is_override or stripped.startswith("@override")
            continue
        return stripped.startswith("///"), is_override
    return False, is_override


def _class_bodies(code: str) -> list[tuple[int, int, str, bool]]:
    """(open brace, close brace, name, is sealed) of every class / enum / mixin / extension body."""
    bodies = []
    for m in re.finditer(r'(\bsealed\s+)?\b(?:class|enum|mixin|extension(?:\s+type)?)\s+(\w+)?[^{;]*\{', code):
        open_brace = m.end() - 1
        bodies.append((open_brace, _block_end(code, open_brace), m.group(2) or "", bool(m.group(1))))
    return bodies


def check_dartdoc_public(result: AnalysisResult) -> None:
    """Check that every public declaration has /// documentation.

    Declarations are found by their place in the code, not by their type: top-level
    functions, getters and variables, and the members of a public class / enum /
    mixin / extension — methods, getters, setters, constructors, fields — whatever
    they return (`Future<void>`, `String?`, `Note`, …). Overrides, framework members
    (`build`, `initState`, …), private names and members of private classes are skipped.
    """
    content = _read_file(Path(result.file))
    lines = content.splitlines()
    code, _ = _scan_dart(content)
    code_lines = code.splitlines()
    bodies = _class_bodies(code)

    # Brace / paren depth at the start of every line
    starts: list[tuple[int, int, int]] = []   # (offset, brace depth, paren depth)
    brace = paren = 0
    offset = 0
    for code_line in code_lines:
        starts.append((offset, brace, paren))
        for ch in code_line:
            if ch == "{":
                brace += 1
            elif ch == "}":
                brace -= 1
            elif ch in "([":
                paren += 1
            elif ch in ")]":
                paren -= 1
        offset += len(code_line) + 1

    previous_code = ";"
    for i, code_line in enumerate(code_lines, 1):
        stripped = code_line.strip()
        if not stripped:
            continue
        starts_statement = previous_code.endswith((";", "{", "}")) or previous_code.startswith("@")
        previous_code = stripped
        line_offset, depth, paren_depth = starts[i - 1]
        if paren_depth or not starts_statement:
            continue

        # Public classes, enums, mixins, extensions
        m = re.match(r'(?:(?:abstract|base|final|interface|sealed|mixin)\s+)*(class|enum|mixin|extension)\s+(\w+)', stripped)
        if m:
            if not m.group(2).startswith("_") and not _doc_above(lines, i)[0]:
                result.violations.append(Violation(
                    file=result.file, line=i, rule="dartdoc_public",
                    message=f"Public {m.group(1)} '{m.group(2)}' missing /// documentation",
                    snippet=_line_at(content, i),
                ))
            continue

        # Where the line is: top level, or directly inside a class-like body
        owner = None
        for open_brace, close_brace, name, is_sealed in bodies:
            if open_brace < line_offset < close_brace:
                owner = (open_brace, name, is_sealed)
        if owner is None:
            if depth != 0:
                continue
            class_name = ""
            is_sealed = False
        else:
            is_sealed = owner[2]
            body_depth = code.count("{", 0, owner[0] + 1) - code.count("}", 0, owner[0] + 1)
            if depth != body_depth or owner[1].startswith("_"):
                continue
            class_name = owner[1]

        # A function type is part of the type: `Future<Result<void>> Function(String) _add;`
        d = _DECLARATION.match(re.sub(r'\bFunction\s*(?:<[^>]*>)?\s*\([^()]*\)\??', 'Fn', stripped))
        if not d or d.group("name") in _NOT_DECLARATION:
            continue
        name, named = d.group("name"), d.group("named")
        is_constructor = bool(class_name) and name == class_name
        if not (d.group("type") or d.group("accessor") or is_constructor or "factory" in d.group("mods")):
            continue  # a call or an enum value, not a declaration
        if named is not None and not is_constructor:
            continue  # `a.b(` — a call on an object
        public_name = named if is_constructor and named else name
        if public_name.startswith("_") or name.startswith("_") or name in _FRAMEWORK_MEMBERS:
            continue
        if is_constructor and is_sealed and not named:
            continue  # the base constructor of a sealed class cannot be called outside its library

        has_doc, is_override = _doc_above(lines, i)
        if has_doc or is_override:
            continue
        if is_constructor:
            what = f"Public constructor '{class_name}{'.' + named if named else ''}'"
        elif name == "call":
            what = "Use case call() method"
        elif d.group("accessor"):
            what = f"Public {d.group('accessor').strip()}ter '{name}'"
        elif d.group("after") in ("(", "=>", "{") or d.group("after").endswith("("):
            what = f"Public {'method' if class_name else 'function'} '{name}'"
        else:
            what = f"Public {'field' if class_name else 'variable'} '{name}'"
        result.violations.append(Violation(
            file=result.file, line=i, rule="dartdoc_public",
            message=f"{what} missing /// documentation",
            snippet=_line_at(content, i),
        ))


_STATE_BASES = ("ValueNotifier", "ValueListenable", "ChangeNotifier", "Listenable")
_state_classes_cache: dict[str, set[str]] = {}


def _state_classes(lib_root: str | None) -> set[str]:
    """Classes under [lib_root] that hold state: subclasses (also indirect) of
    ValueNotifier / ChangeNotifier / ValueListenable / Listenable."""
    if lib_root is None:
        return set()
    if lib_root in _state_classes_cache:
        return _state_classes_cache[lib_root]
    parents: dict[str, set[str]] = {}
    for dart_file in Path(lib_root).rglob("*.dart"):
        code, _ = _scan_dart(_read_file(dart_file))
        for m in re.finditer(r'\bclass\s+(\w+)[^{;]*?\{', code):
            header = m.group(0)
            supers = set(re.findall(r'\b(?:extends|implements|with)\s+([\w\s,<>?]+?)(?=\s+(?:implements|with)\b|\s*\{)', header))
            names: set[str] = set()
            for group in supers:
                names.update(re.findall(r'\b([A-Z]\w*)\b', group))
            parents[m.group(1)] = names
    state: set[str] = set()
    changed = True
    while changed:
        changed = False
        for name, bases in parents.items():
            if name not in state and bases & (state | set(_STATE_BASES)):
                state.add(name)
                changed = True
    _state_classes_cache[lib_root] = state
    return state


def check_no_state_in_di(result: AnalysisResult) -> None:
    """Check that GetIt holds no state: no instanceName keys, no registered ValueNotifier.

    State lives in repositories and reaches the UI only through watch use cases.
    """
    content = _read_file(Path(result.file))
    lines = content.splitlines()
    state = _state_classes(_lib_root(result.file))
    # A registration by type (`register…<T>`, `di<T>`) or by instance
    # (`register…(T(…))`, `register…(T.new)`).
    registered = re.compile(
        r'\b(?:register\w*|GetIt\.I(?:nstance)?|getIt|di)\s*'
        r'(?:<\s*(\w+)|\(\s*(?:\(\)\s*=>\s*)?(?:const\s+)?(\w+)\s*(?:\.new\b|<[^>]*>\s*\(|\())'
    )

    for i, line in enumerate(lines, 1):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith("//"):
            continue

        if re.search(r'\binstanceName\s*:', stripped):
            message = "instanceName is not used — register by type; state reaches the UI via watch use cases"
        elif re.search(r'\b(?:register\w*|GetIt\.I(?:nstance)?|getIt|di)\s*<\s*Value(?:Notifier|Listenable)\b', stripped):
            message = "ValueNotifier/ValueListenable must not live in GetIt — keep it in the repository"
        else:
            m = registered.search(stripped)
            name = (m.group(1) or m.group(2)) if m else None
            if name not in state:
                continue
            message = (
                f"'{name}' holds state (a ValueNotifier/ChangeNotifier) and must not "
                "live in GetIt — keep the state in a repository and expose it through "
                "a watch use case; UI-only state belongs to a controller owned by a "
                "StatefulWidget"
            )

        result.violations.append(Violation(
            file=result.file, line=i, rule="no_state_in_di",
            message=message,
            snippet=_line_at(content, i),
        ))
def check_widget_stateless(result: AnalysisResult) -> None:
    """Check that StatelessWidget is preferred over StatefulWidget."""
    content = _read_file(Path(result.file))

    # Check for StatefulWidget that could be StatelessWidget
    if re.search(r'\bclass\s+\w+\s+extends\s+StatefulWidget', content) or \
       re.search(r'\bextends\s+StatefulWidget', content):
        # If it has no lifecycle methods, it should be StatelessWidget
        if not _has_lifecycle(content):
            lines = content.splitlines()
            for i, line in enumerate(lines, 1):
                if re.search(r'\bclass\s+\w+', line) and re.search(r'StatefulWidget', line):
                    result.violations.append(Violation(
                        file=result.file, line=i, rule="widget_stateless",
                        message="StatefulWidget without lifecycle methods — use StatelessWidget",
                        snippet=_line_at(content, i),
                    ))
                    break
def _find_class_body(lines: list[str], class_line: int) -> tuple[int, int]:
    """Return (class_start, class_end) 1-indexed for a class starting at class_line."""
    class_start = class_line
    brace_count = 0
    found_brace = False
    class_end = class_start
    for j in range(class_start - 1, len(lines)):
        for ch in lines[j]:
            if ch == '{':
                brace_count += 1
                found_brace = True
            elif ch == '}':
                brace_count -= 1
        if found_brace and brace_count == 0:
            class_end = j + 1
            break
    return class_start, class_end
def _widget_classes(code: str) -> list[tuple[str, str, str | None, int, str]]:
    """(name, base, generic argument, offset, body) of every class with an `extends` clause."""
    found = []
    for m in re.finditer(r'\bclass\s+(\w+)[^{;]*?\bextends\s+(\w+)(?:\s*<\s*(\w+)\s*>)?[^{;]*\{', code):
        body = code[m.end():_block_end(code, m.end() - 1)]
        found.append((m.group(1), m.group(2), m.group(3), m.start(), body))
    return found


def check_watching_widget(result: AnalysisResult) -> None:
    """Check that watch_it calls and Watching widgets come together.

    - `WatchingWidget` / `WatchingStatefulWidget` (its State) must call `watch()`,
      `registerHandler()` or `createOnce()` — on a watch use case or on a controller.
    - `StatelessWidget` / the State of a plain `StatefulWidget` must not call them:
      watch_it throws at runtime outside Watching widgets.
    - `watchValue()` / `watchIt()` in presentation widgets are violations.
    """
    content = _read_file(Path(result.file))
    lines = content.splitlines()

    if _is_presentation_file(result.file) and not _is_in_di_folder(result.file):
        for i, line in enumerate(lines, 1):
            if line.strip().startswith("//"):
                continue
            if re.search(r'\bwatch(?:Value|It)\s*[<(]', line):
                result.violations.append(Violation(
                    file=result.file, line=i, rule="watching_widget",
                    message="watchValue()/watchIt() are not allowed — use watch(watch<Name>UseCase()).value or watch(controller).value",
                    snippet=_line_at(content, i),
                ))

    code, _ = _scan_dart(content)
    classes = _widget_classes(code)
    bases = {name: base for name, base, _, _, _ in classes}
    state_bodies = {generic: body for _, base, generic, _, body in classes if base == "State" and generic}

    def report(offset: int, message: str) -> None:
        i = code.count("\n", 0, offset) + 1
        result.violations.append(Violation(
            file=result.file, line=i, rule="watching_widget", message=message, snippet=_line_at(content, i),
        ))

    for name, base, generic, offset, body in classes:
        calls = re.search(WATCH_IT_ORDERED_CALL, body)
        if base == "WatchingWidget" and not calls:
            report(offset, "WatchingWidget without watch()/registerHandler()/createOnce() — use StatelessWidget")
        elif base == "WatchingStatefulWidget" and not re.search(WATCH_IT_ORDERED_CALL, state_bodies.get(name, "")):
            report(offset, "WatchingStatefulWidget without watch()/registerHandler()/createOnce() in its State — use StatefulWidget")
        elif calls and (base == "StatelessWidget" or (base == "State" and bases.get(generic) == "StatefulWidget")):
            report(offset, "watch()/registerHandler()/createOnce() work only in WatchingWidget/WatchingStatefulWidget — they throw here at runtime")

def check_no_controller_in_ui(result: AnalysisResult) -> None:
    """Check that complicated stateful logic is extracted to controllers/ folder."""
    # Skip files already in controllers/ folder — they are controllers by design
    if _is_in_controllers_folder(result.file):
        return

    # Skip repository implementations (data layer) — they expose ValueNotifiers by design
    if re.search(r'(data|domain)/repositories/', result.file):
        return

    # This is a soft check — we look for patterns that suggest a controller is needed
    content = _read_file(Path(result.file))

    # Count the stateful elements the file creates (received ones are owned
    # elsewhere): ValueNotifier, TextEditingController, FocusNode.
    code, _ = _scan_dart(content)
    created = re.findall(
        r'(?:=\s*|\(\s*|return\s+)(ValueNotifier|TextEditingController|FocusNode)\s*(?:<[^>]*>)?\s*\(',
        code,
    )
    vn_count = created.count("ValueNotifier")
    te_count = created.count("TextEditingController")
    fn_count = created.count("FocusNode")

    # If there are multiple stateful elements, suggest controller
    if vn_count + te_count + fn_count >= 3:
        lines = content.splitlines()
        for i, line in enumerate(lines, 1):
            if re.search(r'\bclass\s+\w+', line):
                result.violations.append(Violation(
                    file=result.file, line=i, rule="no_controller_in_ui",
                    message=f"Multiple stateful elements ({vn_count} ValueNotifiers, {te_count} TextEditingControllers, {fn_count} FocusNodes) — consider extracting to controllers/ folder",
                    snippet=_line_at(content, i),
                ))
                break
def check_static_const_order(result: AnalysisResult) -> None:
    """Check that static const fields are placed before constructor or first method."""
    content = _read_file(Path(result.file))
    lines = content.splitlines()

    # Check if this file contains a StatefulWidget with a State class
    is_stateful = bool(re.search(
        r'\b(class|extends)\s+\w*(StatefulWidget|State<\w+,\s*\w+>)', content
    )) or bool(re.search(
        r'\bextends\s+StatefulWidget', content
    )) or bool(re.search(
        r'\b(class|extends)\s+\w*(WatchingStatefulWidget)', content
    )) or bool(re.search(
        r'\bextends\s+WatchingStatefulWidget', content
    ))

    if is_stateful:
        # Find the State class boundary
        state_class_line = None
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if re.search(r'\bclass\s+\w+State\s+extends\s+State<', stripped) or \
               re.search(r'\bclass\s+\w+State\s+extends\s+', stripped):
                state_class_line = i
                break

        if state_class_line:
            # Find the first method or field after the State class declaration
            # (excluding static const fields which are allowed)
            first_method_line = None
            brace_depth = 0
            for i in range(state_class_line - 1, len(lines)):
                stripped = lines[i].strip()
                if not stripped or stripped.startswith('//'):
                    continue
                # Count braces to track class scope
                brace_depth += stripped.count('{') - stripped.count('}')
                if brace_depth <= 0:
                    break
                # The class declaration itself (`final class _XState extends State<X> {`) is not a member
                if i == state_class_line - 1:
                    continue
                # Check for method definitions (not static const, not fields)
                if re.search(r'\bvoid\s+\w+\s*\(', stripped) or \
                   re.search(r'\b(Future|FutureOr|void|int|double|String|bool|Color|Duration)\s+\w+\s*\(', stripped) or \
                   re.search(r'\bvoid\s+\w+\s*\(', stripped) or \
                   re.search(r'\b@override\s*\n.*?\bvoid\s+\w+\s*\(', stripped):
                    first_method_line = i + 1
                    break
                # Check for non-static-const field assignments
                if re.search(r'\bfinal\s+', stripped) and not re.search(r'\bstatic\s+const\b', stripped):
                    first_method_line = i + 1
                    break

            if first_method_line:
                # Check for static const fields after the first method,
                # but only within the State class scope
                state_class_start = state_class_line - 1  # 0-indexed
                brace_depth = 0
                state_class_end = len(lines)
                for i in range(state_class_start, len(lines)):
                    stripped = lines[i].strip()
                    if not stripped or stripped.startswith('//'):
                        continue
                    brace_depth += stripped.count('{') - stripped.count('}')
                    if brace_depth <= 0:
                        state_class_end = i + 1  # 1-indexed
                        break

                for i in range(first_method_line, state_class_end):
                    if _is_static_const(lines[i - 1]):
                        result.violations.append(Violation(
                            file=result.file, line=i, rule="static_const_order",
                            message=f"static const field after first method in State class — move before first method",
                            snippet=_line_at(content, i),
                        ))
            return

    # Original logic for StatelessWidget / non-StatefulWidget
    constructor_line = None
    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        if stripped.startswith("const ") and "(" in stripped and ")" in stripped:
            constructor_line = i
            break
        if re.search(r'\b\w+\s*\(', stripped) and re.search(r':\s*this\.', stripped):
            constructor_line = i
            break

    if not constructor_line:
        return

    # Find the class boundary for this constructor
    class_start = None
    brace_depth = 0
    class_end = len(lines)
    for i in range(constructor_line - 1, -1, -1):
        stripped = lines[i].strip()
        if not stripped or stripped.startswith('//'):
            continue
        if re.search(r'\bclass\s+\w+', stripped):
            class_start = i + 1  # 1-indexed
            break
        if re.search(r'\bextends\s+', stripped):
            class_start = i + 1  # 1-indexed
            break

    # Track class boundary from constructor to end
    brace_depth = 0
    for i in range(constructor_line - 1, len(lines)):
        stripped = lines[i].strip()
        if not stripped or stripped.startswith('//'):
            continue
        brace_depth += stripped.count('{') - stripped.count('}')
        if brace_depth <= 0:
            class_end = i + 1  # 1-indexed
            break

    # Check if there are static const declarations after the constructor, within the class
    for i in range(constructor_line + 1, class_end):
        if _is_static_const(lines[i - 1]):
            result.violations.append(Violation(
                file=result.file, line=i, rule="static_const_order",
                message=f"static const field after constructor — move before constructor",
                snippet=_line_at(content, i),
            ))
def check_no_build_return(result: AnalysisResult) -> None:
    """Check for private helper methods returning Widget (should be separate StatelessWidget)."""
    content = _read_file(Path(result.file))
    lines = content.splitlines()

    # Skip if it's a private widget class (private widgets can have their own helpers)
    if _is_private_widget_class(content):
        return

    for i, line in enumerate(lines, 1):
        if _is_private_method(line):
            result.violations.append(Violation(
                file=result.file, line=i, rule="no_build_return",
                message="Private method returning Widget — create separate StatelessWidget in widgets/ folder",
                snippet=_line_at(content, i),
            ))
# Global set to track already-reported feature roots for folder_naming deduplication
_folder_naming_reported: set[str] = set()
def check_async_gap_context_mounted(result: AnalysisResult) -> None:
    """Check that Navigator/ScaffoldMessenger calls after await have context.mounted guard.

    When an async closure or method uses `await` and then calls Navigator.pop/push
    or ScaffoldMessenger.of, it must first check `if (!context.mounted) return;`
    to avoid using a BuildContext across async gaps.
    """
    content = _read_file(Path(result.file))
    lines = content.splitlines()

    # Patterns that indicate navigation/context usage after async
    nav_patterns = [
        r'Navigator\.pop\s*\(',
        r'Navigator\.push\s*\(',
        r'Navigator\.pushNamed\s*\(',
        r'Navigator\.pushReplacement\s*\(',
        r'Navigator\.pushNamedAndRemoveUntil\s*\(',
        r'ScaffoldMessenger\.of\s*\(',
    ]

    for i, line in enumerate(lines, 1):
        stripped = line.strip()

        # Skip comments and imports
        if stripped.startswith("//") or stripped.startswith("import ") or stripped.startswith("export "):
            continue

        # Check if this line contains a navigation/context call
        is_nav_call = False
        for pattern in nav_patterns:
            if re.search(pattern, line):
                is_nav_call = True
                break

        if not is_nav_call:
            continue

        # Check if there's an 'await' keyword within 100 lines before this line
        # (within the same async scope)
        has_await_before = False
        search_start = max(0, i - 100)  # 0-indexed
        for j in range(search_start, i - 1):
            if re.search(r'\bawait\s+', lines[j]):
                has_await_before = True
                break

        if not has_await_before:
            continue

        # Check if there's a mounted guard between the await and this nav call
        # Accept both: if (!context.mounted) return; and if (!mounted) return;
        has_mounted_guard = False
        for j in range(search_start, i - 1):
            if re.search(r'if\s*\(\s*!?\s*(context\.)?mounted\s*\)', lines[j]):
                has_mounted_guard = True
                break

        if not has_mounted_guard:
            result.violations.append(Violation(
                file=result.file, line=i, rule="async_gap_context_mounted",
                message="Navigator/ScaffoldMessenger call after await without mounted guard — add 'if (!context.mounted) return;' or 'if (!mounted) return;' before navigation",
                snippet=_line_at(content, i),
            ))
_DOMAIN_SUBFOLDERS = ("entities", "repositories", "use_cases")

def _check_domain_file_location(result: AnalysisResult) -> None:
    """Enforce that domain-layer files live under a valid domain subfolder.

    Any *.dart file under a .../domain/ directory (feature or core) must be
    placed in domain/entities/, domain/repositories/, or domain/use_cases/ —
    never directly inside domain/ (e.g. domain/result.dart is a violation;
    domain/entities/result.dart is correct).
    """
    fp = result.file
    parts = fp.split("/")
    if "domain" not in parts:
        return
    try:
        domain_idx = parts.index("domain")
    except ValueError:
        return
    rest = parts[domain_idx + 1:]
    # A file directly in domain/ has exactly the filename remaining.
    if len(rest) == 1:
        result.violations.append(Violation(
            file=fp, line=0, rule="folder_naming",
            message=(f"Domain file '{rest[0]}' must live under "
                     f"domain/entities/, domain/repositories/, or "
                     f"domain/use_cases/ (not directly in domain/)"),
         )),


def check_folder_naming(result: AnalysisResult) -> None:
    """Check that feature AND core folder structures match conventions.

    Both every feature under lib/features/<feature>/ and lib/core/ must contain:
       - data/data_sources/ (NOT data_source/)
       - data/models/
       - data/repositories/
       - domain/entities/
       - domain/repositories/
       - domain/use_cases/
       - presentation/pages/
       - presentation/widgets/
       - presentation/di/
       - presentation/controllers/ (optional, for stateful controllers)

    core/ follows the same structure as features, so domain files such as
    result.dart belong in domain/entities/ (never directly in domain/).

    Violations are reported only once per root, not per file.
    """
    # Also enforce that domain-layer files live under a valid domain subfolder.
    _check_domain_file_location(result)

    fp = result.file
    parts = fp.split("/")

    # Determine the root directory to validate: a feature root or the core root.
    feature_root = None
    feature_name = None
    if "/features/" in fp:
        try:
            features_idx = parts.index("features")
        except ValueError:
            features_idx = -1
        if features_idx + 1 < len(parts):
            feature_name = parts[features_idx + 1]
            feature_root = "/".join(parts[: features_idx + 2])    # .../features/<feature>
    elif "/core/" in fp:
        core_idx = parts.index("core")
        feature_root = "/".join(parts[: core_idx + 1])    # .../core
        feature_name = "core"

    if feature_root is None:
        return

    # Deduplicate: only report once per root (feature or core)
    if feature_root in _folder_naming_reported:
        return

    # Expected subfolders
    expected_subfolders = {
        "data_sources",
        "models",
        "repositories",
    }
    expected_domain_subfolders = {
        "entities",
        "repositories",
        "use_cases",
    }
    expected_presentation_subfolders = {
        "pages",
        "widgets",
        "di",
        "controllers",
    }

    # Scan the feature root for actual subfolders
    feature_path = Path(feature_root)
    if not feature_path.is_dir():
        return

    # Check data/ subfolders
    data_folder = feature_path / "data"
    if data_folder.is_dir():
        actual_data_sub = {d.name for d in data_folder.iterdir() if d.is_dir()}
        missing = expected_subfolders - actual_data_sub
        extra = actual_data_sub - expected_subfolders

        for sub in missing:
            result.violations.append(Violation(
                file=fp, line=0, rule="folder_naming",
                message=f"Feature '{feature_name}' data/ missing subfolder '{sub}/'",
            ))
        for sub in extra:
            # Check if it's a wrong name (e.g., data_source instead of data_sources)
            result.violations.append(Violation(
                file=fp, line=0, rule="folder_naming",
                message=f"Feature '{feature_name}' data/ has unexpected subfolder '{sub}/' — expected one of {sorted(expected_subfolders)}",
            ))

    # Check domain/ subfolders
    domain_folder = feature_path / "domain"
    if domain_folder.is_dir():
        actual_domain_sub = {d.name for d in domain_folder.iterdir() if d.is_dir()}
        missing = expected_domain_subfolders - actual_domain_sub
        extra = actual_domain_sub - expected_domain_subfolders

        for sub in missing:
            result.violations.append(Violation(
                file=fp, line=0, rule="folder_naming",
                message=f"Feature '{feature_name}' domain/ missing subfolder '{sub}/'",
            ))
        for sub in extra:
            result.violations.append(Violation(
                file=fp, line=0, rule="folder_naming",
                message=f"Feature '{feature_name}' domain/ has unexpected subfolder '{sub}/' — expected one of {sorted(expected_domain_subfolders)}",
            ))

    # Check presentation/ subfolders
    presentation_folder = feature_path / "presentation"
    if presentation_folder.is_dir():
        actual_pres_sub = {d.name for d in presentation_folder.iterdir() if d.is_dir()}
        missing = expected_presentation_subfolders - actual_pres_sub
        extra = actual_pres_sub - expected_presentation_subfolders

        for sub in missing:
            result.violations.append(Violation(
                file=fp, line=0, rule="folder_naming",
                message=f"Feature '{feature_name}' presentation/ missing subfolder '{sub}/'",
            ))
        for sub in extra:
            result.violations.append(Violation(
                file=fp, line=0, rule="folder_naming",
                message=f"Feature '{feature_name}' presentation/ has unexpected subfolder '{sub}/' — expected one of {sorted(expected_presentation_subfolders)}",
            ))

    # Mark this feature root as reported
    _folder_naming_reported.add(feature_root)
def check_widget_key_parameter(result: AnalysisResult) -> None:
    """Check that public widget constructors have a named 'key' parameter.

    All public widget classes (StatelessWidget, StatefulWidget, WatchingWidget,
    WatchingStatefulWidget) must declare a named 'key' parameter in their
    constructor, following Flutter best practices.
    """
    content = _read_file(Path(result.file))
    lines = content.splitlines()

    for i, line in enumerate(lines, 1):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith("//"):
            continue

        # Check for public widget class declarations (skip private classes starting with _)
        is_widget_class = bool(
            re.search(r'\b(class|extends)\s+\w*(StatelessWidget|StatefulWidget|WatchingWidget|WatchingStatefulWidget)', line) or
            re.search(r'\bextends\s+(StatelessWidget|StatefulWidget|WatchingWidget|WatchingStatefulWidget)', line)
        )

        if not is_widget_class:
            continue

        # Skip private widget classes (starting with _)
        class_name = _get_class_name(line)
        if class_name and class_name.startswith('_'):
            continue

        # Find the constructor for this class
        # Look for 'const' constructor or regular constructor
        class_start = i
        constructor_line = None
        brace_depth = 0
        found_brace = False

        for j in range(i - 1, len(lines)):
            stripped_j = lines[j].strip()
            if stripped_j.startswith("//"):
                continue
            brace_depth += stripped_j.count('{') - stripped_j.count('}')
            if brace_depth <= 0 and found_brace:
                break
            if '{' in stripped_j:
                found_brace = True
            # Check for constructor pattern: const ClassName({ ... }) or ClassName({ ... })
            if re.search(r'\b(const\s+)?[A-Z]\w+\s*\(\s*{', lines[j]) or \
               re.search(r'\bconst\s+[A-Z]\w+\s*\(', lines[j]) or \
               re.search(r'\b[A-Z]\w+\s*\(\s*\{', lines[j]):
                constructor_line = j + 1  # 1-indexed
                break

        if constructor_line:
            # Check if the constructor has a named 'key' parameter
            # Look at the constructor line and possibly the next few lines
            constructor_text = ""
            brace_depth = 0
            for j in range(constructor_line - 1, min(constructor_line + 9, len(lines))):
                constructor_text += lines[j]
                brace_depth += lines[j].count('{') - lines[j].count('}')
                if brace_depth <= 0 and '{' in lines[j]:
                    break

            # Check for named key parameter: {Key? key} or {required Key key} or {Key key} or super.key
            if not (re.search(r'\bkey\s*:', constructor_text) or re.search(r'\bsuper\.key\b', constructor_text)):
                class_name = _get_class_name(line)
                result.violations.append(Violation(
                    file=result.file, line=i, rule="widget_key_parameter",
                    message=f"Public widget class '{class_name}' constructor missing named 'key' parameter — add '{{Key? key}}'",
                    snippet=_line_at(content, i),
                ))
def _block_end(code: str, open_brace: int) -> int:
    """Offset of the `}` matching the `{` at [open_brace]."""
    depth = 0
    for j in range(open_brace, len(code)):
        if code[j] == "{":
            depth += 1
        elif code[j] == "}":
            depth -= 1
            if depth == 0:
                return j
    return len(code)


def _created_resources(body: str) -> int:
    """Disposable resources created in [body] (not received through the constructor)."""
    return len(re.findall(
        r'(?:=\s*|\(\s*|return\s+)(?:ValueNotifier|TextEditingController|ScrollController|FocusNode)\s*(?:<[^>]*>)?\s*\(',
        body,
    ))


def check_controller_lifecycle(result: AnalysisResult) -> None:
    """Check that widgets with controllers having ValueNotifiers use StatefulWidget with lifecycle.

    If a widget class contains controllers with ValueNotifiers or other disposable
    resources (TextEditingController, ScrollController, FocusNode, etc.), it must
    be a StatefulWidget with initState (to create controllers) and dispose (to dispose them).
    """
    content = _read_file(Path(result.file))
    lines = content.splitlines()

    # Skip files already in controllers/ folder — they are controllers by design
    if _is_in_controllers_folder(result.file):
        return

    # Count disposable resources created inside the widget (not received via constructor).
    # Constructor-received resources are declared as `final Type name;` (no initializer).
    # Resources created with `= Type(...)` or assigned inside initState count.
    lines = content.splitlines()

    # ValueNotifiers: exclude constructor-received ones (final ... name; with no =)
    vn_count = 0
    for line in lines:
        stripped = line.strip()
        if re.search(r'final\s+ValueNotifier<', stripped) and not re.search(r'=\s*ValueNotifier', stripped):
            continue
        if re.search(r'ValueNotifier<', stripped) or re.search(r'ValueNotifier\(', stripped):
            vn_count += 1

    # TextEditingController: exclude constructor-received
    te_count = 0
    for line in lines:
        stripped = line.strip()
        if re.search(r'final\s+TextEditingController', stripped) and not re.search(r'=\s*TextEditingController', stripped):
            continue
        if re.search(r'TextEditingController', stripped):
            te_count += 1

    # ScrollController: exclude constructor-received
    sc_count = 0
    for line in lines:
        stripped = line.strip()
        if re.search(r'final\s+ScrollController', stripped) and not re.search(r'=\s*ScrollController', stripped):
            continue
        if re.search(r'ScrollController', stripped):
            sc_count += 1

    # FocusNode: exclude constructor-received
    fn_count = 0
    for line in lines:
        stripped = line.strip()
        if re.search(r'final\s+FocusNode', stripped) and not re.search(r'=\s*FocusNode', stripped):
            continue
        if re.search(r'FocusNode', stripped):
            fn_count += 1

    total_resources = vn_count + te_count + sc_count + fn_count

    # If no disposable resources, skip
    if total_resources == 0:
        return

    # Check if this is a StatelessWidget (violation)
    is_stateless = bool(re.search(r'\bextends\s+StatelessWidget', content))
    is_stateful = bool(re.search(r'\bextends\s+StatefulWidget', content)) or \
                  bool(re.search(r'\bextends\s+WatchingStatefulWidget', content))

    if is_stateless:
        # Only a StatelessWidget that creates resources itself is a violation;
        # the State class in the same file may own them.
        code, _ = _scan_dart(content)
        for m in re.finditer(r'\bclass\s+\w+[^{;]*\bextends\s+StatelessWidget\b[^{]*\{', code):
            body = code[m.end():_block_end(code, m.end() - 1)]
            created = _created_resources(body)
            if created:
                i = code.count("\n", 0, m.start()) + 1
                result.violations.append(Violation(
                    file=result.file, line=i, rule="controller_lifecycle",
                    message=f"Widget creates {created} disposable resource(s) (ValueNotifier, TextEditingController, ScrollController, FocusNode) — must use StatefulWidget with initState/dispose",
                    snippet=_line_at(content, i),
                ))

    # A WatchingWidget owns its resources through createOnce(…, dispose: …)
    code, _ = _scan_dart(content)
    for m in re.finditer(r'\bclass\s+\w+[^{;]*\bextends\s+WatchingWidget\b[^{]*\{', code):
        body = code[m.end():_block_end(code, m.end() - 1)]
        if _created_resources(body) and not re.search(r'(?<![\w.])createOnce\s*\(', body):
            i = code.count("\n", 0, m.start()) + 1
            result.violations.append(Violation(
                file=result.file, line=i, rule="controller_lifecycle",
                message="WatchingWidget creates a disposable resource without createOnce(…, dispose: …) — it would be recreated on every build and never disposed",
                snippet=_line_at(content, i),
            ))

    # If StatefulWidget, check it has initState and dispose
    if is_stateful:
        has_initstate = _has_initstate(content)
        has_dispose = _has_dispose(content)

        if not has_initstate:
            for i, line in enumerate(lines, 1):
                if re.search(r'\bclass\s+\w+', line) and (re.search(r'StatefulWidget', line) or re.search(r'WatchingStatefulWidget', line)):
                    result.violations.append(Violation(
                        file=result.file, line=i, rule="controller_lifecycle",
                        message=f"StatefulWidget with {total_resources} disposable resource(s) missing initState — controllers must be created in initState",
                        snippet=_line_at(content, i),
                    ))
                    break

        if not has_dispose:
            for i, line in enumerate(lines, 1):
                if re.search(r'\bclass\s+\w+', line) and (re.search(r'StatefulWidget', line) or re.search(r'WatchingStatefulWidget', line)):
                    result.violations.append(Violation(
                        file=result.file, line=i, rule="controller_lifecycle",
                        message=f"StatefulWidget with {total_resources} disposable resource(s) missing dispose — controllers must be disposed",
                        snippet=_line_at(content, i),
                    ))
                    break
def check_widget_methods(result: AnalysisResult) -> None:
    """Check for private methods returning Widget type.

    No private method inside any class may return Widget — extract to a
    separate StatelessWidget in widgets/ folder instead.  This applies
    regardless of whether the file lives inside a widgets/ directory.
    """
    content = _read_file(Path(result.file))
    lines = content.splitlines()

    for i, line in enumerate(lines, 1):
        if _is_private_method(line):
            result.violations.append(Violation(
                file=result.file, line=i, rule="widget_methods",
                message="Private method returning Widget — extract to a separate StatelessWidget in widgets/ folder",
                snippet=_line_at(content, i),
            ))
def check_stateless_with_controllers(result: AnalysisResult) -> None:
    """Check that the top-level StatelessWidget creating controllers has proper lifecycle.

    Only the **top-level** widget class in a file is checked — sub-widgets that
    merely receive a controller as a constructor parameter are exempt, since they
    do not own the controller lifecycle.

    If the top-level StatelessWidget creates a controller instance (e.g.
    `ControllerName()`) and calls `.init()` or `.dispose()` on it without having
    `initState()`/`dispose()` lifecycle methods, it must be converted to
    StatefulWidget with proper lifecycle.
    """
    content = _read_file(Path(result.file))
    lines = content.splitlines()

    # Skip files already in controllers/ folder
    if _is_in_controllers_folder(result.file):
        return

    # Only check StatelessWidget files
    is_stateless = bool(re.search(r'\bextends\s+StatelessWidget', content))
    is_stateful = bool(re.search(r'\bextends\s+StatefulWidget', content)) or \
                   bool(re.search(r'\bextends\s+WatchingStatefulWidget', content))
    if not is_stateless:
        return

    # Find the FIRST (top-level) widget class in the file
    top_class_line = None
    top_class_name = None
    for i, line in enumerate(lines, 1):
        if re.search(r'\bclass\s+\w+', line) and re.search(r'StatelessWidget', line):
            top_class_line = i
            top_class_name = _get_class_name(line)
            break

    if top_class_line is None:
        return

    # Extract only the body of the top-level class (up to the next class or end)
    brace_depth = 0
    class_start = top_class_line - 1  # 0-indexed
    class_end = len(lines)
    found_brace = False
    for j in range(class_start, len(lines)):
        for ch in lines[j]:
            if ch == '{':
                brace_depth += 1
                found_brace = True
            elif ch == '}':
                brace_depth -= 1
        if found_brace and brace_depth == 0:
            class_end = j + 1
            break

    class_body = "\n".join(lines[class_start:class_end])

    # Check if the top-level class CREATES a controller instance (not just receives one)
    # Patterns: `ControllerName()` or `final ControllerName controller = ControllerName()`
    creates_controller = bool(re.search(
        r'[A-Z]\w+Controller\s*\(\s*\)', class_body
    )) or bool(re.search(
        r'=\s*[A-Z]\w+Controller\s*\(\s*\)', class_body
    ))

    if not creates_controller:
        return

    # Check if the top-level class calls .init() or .dispose() on a controller
    has_init_call = bool(re.search(r'\b\w+\.init\s*\(', class_body))
    has_dispose_call = bool(re.search(r'\b\w+\.dispose\s*\(', class_body))

    if not has_init_call and not has_dispose_call:
        return

    # Check if the top-level class has lifecycle methods
    has_initstate = _has_initstate(class_body)
    has_dispose = _has_dispose(class_body)

    if not has_initstate or not has_dispose:
        missing = []
        if not has_initstate:
            missing.append("initState")
        if not has_dispose:
            missing.append("dispose")
        result.violations.append(Violation(
            file=result.file, line=top_class_line, rule="stateless_with_controllers",
            message=f"StatelessWidget creates controller and calls {', '.join(missing)}() — convert to StatefulWidget with {' and '.join(missing)}()",
            snippet=_line_at(content, top_class_line),
        ))
def check_watch_order(result: AnalysisResult) -> None:
    """Check that watch()/registerHandler() run unconditionally at the top level of build().

    watch_it binds every watch()/registerHandler() call to its position in build()
    (like React hooks). A call inside an if/for/switch block or inside a builder
    callback changes positions between builds.
    """
    if not _is_presentation_file(result.file):
        return

    content = _read_file(Path(result.file))
    lines = content.splitlines()

    for i, line in enumerate(lines, 1):
        if not re.search(r'\bWidget\s+build\s*\(\s*BuildContext\s+\w+\s*\)\s*\{', line):
            continue

        _, build_end = _find_class_body(lines, i)
        base_indent = None
        statement_indent = None
        previous_code = "{"

        # Body lines are i+1 .. build_end-1 (1-indexed) → lines[i .. build_end-2]
        for j in range(i, build_end - 1):
            text = lines[j]
            stripped = text.strip()
            if not stripped or stripped.startswith("//"):
                continue

            indent = len(text) - len(text.lstrip())
            if base_indent is None:
                base_indent = indent
            # A line starts a new statement when the previous code line closed one
            if previous_code.endswith((";", "{", "}")):
                statement_indent = indent
            previous_code = stripped

            if re.search(WATCH_IT_ORDERED_CALL, stripped) and statement_indent != base_indent:
                result.violations.append(Violation(
                    file=result.file, line=j + 1, rule="watch_order",
                    message="watch()/registerHandler()/createOnce() must be called unconditionally at the top of build() — not inside if/for/switch or callbacks",
                    snippet=_line_at(content, j + 1),
                ))
def check_value_listenable_exposure(result: AnalysisResult) -> None:
    """Check that reactive state is exposed outward only as ValueListenable.

    - Domain files (repository interfaces, use cases) must not mention ValueNotifier.
    - Repository implementations may hold a private ValueNotifier, but public
      members must not return or expose ValueNotifier.
    - `<feature>_getters.dart` must not return ValueNotifier.
    """
    content = _read_file(Path(result.file))
    lines = content.splitlines()

    is_domain = _is_domain_file(result.file)
    is_repository_impl = _is_data_file(result.file) and "repositories/" in result.file
    is_getters = result.file.endswith("_getters.dart")
    if not (is_domain or is_repository_impl or is_getters):
        return

    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        if stripped.startswith(("//", "import ", "export ")):
            continue
        if "ValueNotifier" not in stripped:
            continue

        if is_domain:
            message = "Domain must expose ValueListenable<T>, not ValueNotifier<T>"
        else:
            m = re.search(r'\bValueNotifier<[^=;(]*>\s+(?:get\s+)?([A-Za-z_]\w*)\s*(?:\(|=>|;|=)', stripped)
            if not m or m.group(1).startswith("_"):
                continue
            message = f"Public member '{m.group(1)}' exposes ValueNotifier — return ValueListenable<T> instead"

        result.violations.append(Violation(
            file=result.file, line=i, rule="value_listenable_exposure",
            message=message,
            snippet=_line_at(content, i),
        ))
def check_static_const_in_state_class(result: AnalysisResult) -> None:
    """Check that static const fields in StatefulWidget/WatchingStatefulWidget are in the State class, not the widget class.

    For StatefulWidget / WatchingStatefulWidget, static const fields should be declared
    in the State class (where they are used), not in the widget class.
    """
    content = _read_file(Path(result.file))
    lines = content.splitlines()

    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        if stripped.startswith("//"):
            continue
        if re.search(r'\b(class|extends)\s+\w*(StatefulWidget|State<\w+,\s*\w+>)', line) or \
           re.search(r'\bextends\s+(StatefulWidget|State<\w+,\s*\w+>)', line) or \
           re.search(r'\b(class|extends)\s+\w*(WatchingStatefulWidget)', line) or \
           re.search(r'\bextends\s+WatchingStatefulWidget', line):
            # Find the widget class body
            class_start, class_end = _find_class_body(lines, i)
            widget_body = "\n".join(lines[class_start:class_end])

            # Check if the widget class has static const fields (not in State class)
            widget_static_consts = []
            for j in range(class_start - 1, class_end):
                wline = lines[j]
                if _is_static_const(wline):
                    # This is a static const field in the widget class
                    widget_static_consts.append((j + 1, wline.strip()))

            if widget_static_consts:
                # Check if there's a State class — if so, static consts should be there
                for j in range(class_end, len(lines)):
                    state_line = lines[j]
                    if re.search(r'\bclass\s+\w+State\s+extends\s+State<', state_line) or \
                       re.search(r'\bclass\s+\w+State\s+extends\s+', state_line):
                        # Found a State class — all static consts should be in it, not in the widget class
                        for line_num, line_text in widget_static_consts:
                            result.violations.append(Violation(
                                file=result.file, line=line_num, rule="static_const_in_state_class",
                                message=f"static const field '{line_text.strip()}' is in the widget class — move to the State class",
                                snippet=line_text,
                            ))
                        break  # Only check the first State class
def check_magic_numbers_in_layout(result: AnalysisResult) -> None:
    """Check that numbers inside layout constructors (EdgeInsets, etc.) are declared as static const.

    Numbers used in layout constructors like EdgeInsets.only(left: 8),
    EdgeInsets.all(16), etc. should be declared as static const, not hardcoded.
    """
    content = _read_file(Path(result.file))
    lines = content.splitlines()

    # Track static const number declarations in this file
    static_const_numbers: set[float] = set()
    for line in lines:
        if _is_static_const(line):
            nums = re.findall(r'(?<!\w)(-?\d+\.?\d*)(?!\w)', line)
            for n in nums:
                try:
                    static_const_numbers.add(float(n))
                except ValueError:
                    pass

    # Layout constructor patterns that should have static const numbers
    layout_patterns = [
        r'EdgeInsets\.only\s*\(',
        r'EdgeInsets\.all\s*\(',
        r'EdgeInsets\.symmetric\s*\(',
        r'EdgeInsets\.fromPaddingBuffer\s*\(',
        r'EdgeInsets\.lerp\s*\(',
        r'Size\s*\(',
        r'Offset\s*\(',
        r'Color\s*\(',
    ]

    for i, line in enumerate(lines, 1):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith("//"):
            continue

        # Skip imports
        if stripped.startswith("import ") or stripped.startswith("export "):
            continue

        # Skip static const declarations
        if _is_static_const(line):
            continue

        # Check if this line is inside a layout constructor
        is_layout_line = False
        for pattern in layout_patterns:
            if re.search(pattern, line):
                is_layout_line = True
                break

        if not is_layout_line:
            continue

        # Find numbers in this line
        numbers = re.finditer(r'(?<!\w)(-?\d+\.?\d*)(?!\w)', line)
        for m in numbers:
            num_str = m.group(1)
            try:
                num = float(num_str)
            except ValueError:
                continue

            # Skip allowed numbers
            if num in ALLOWED_NUMBERS:
                continue

            # Skip if already declared as static const
            if num in static_const_numbers:
                continue

            result.violations.append(Violation(
                file=result.file, line=i, rule="magic_numbers_in_layout",
                message=f"Magic number '{num_str}' in layout constructor — declare as static const",
                snippet=_line_at(content, i),
            ))
# Layout words: a private const with one of these in its name is a spacing value
LAYOUT_NAME_WORDS = ("padding", "spacing", "gap", "margin", "inset")

# Shared constants file of the project, relative to lib/
CORE_THEME_FILE = "core/presentation/theme.dart"

_STATIC_CONST_DECL = re.compile(r'^\s*static\s+const\s+(double|int|Color)\s+(\w+)\s*=\s*([^;]+);')

# Per-run cache: lib root -> (theme constants, private constants by key)
_const_index_cache: dict[str, tuple[dict[tuple[str, str], str], dict[tuple[str, str, str], set[str]]]] = {}


def _lib_root(file_path: str) -> str | None:
    """Return the path of the closest `lib` directory above [file_path]."""
    parts = Path(file_path).parts
    if "lib" not in parts:
        return None
    idx = len(parts) - 1 - parts[::-1].index("lib")
    return str(Path(*parts[: idx + 1]))


def _owner_of(file_path: str) -> str | None:
    """Return the feature name (or 'core') that a file belongs to."""
    parts = Path(file_path).parts
    if "features" in parts and parts.index("features") + 1 < len(parts):
        return parts[parts.index("features") + 1]
    if "core" in parts:
        return "core"
    return None


def _normalize_value(value: str) -> str:
    value = value.strip()
    try:
        return str(float(value))
    except ValueError:
        return re.sub(r"\s+", "", value)


def _const_index(lib_root: str):
    """Index shared theme constants and private static consts of every feature under [lib_root]."""
    if lib_root in _const_index_cache:
        return _const_index_cache[lib_root]

    theme: dict[tuple[str, str], str] = {}
    theme_path = Path(lib_root) / CORE_THEME_FILE
    if theme_path.is_file():
        class_name = "AppTheme"
        for line in _read_file(theme_path).splitlines():
            m_class = re.search(r'\bclass\s+(\w+)', line)
            if m_class:
                class_name = m_class.group(1)
            m = _STATIC_CONST_DECL.match(line)
            # Only spacing constants: a private gap must not borrow a radius
            # or a border width that happens to have the same value.
            if m and not m.group(2).startswith("_") and \
                    any(word in m.group(2).lower() for word in LAYOUT_NAME_WORDS):
                theme.setdefault((m.group(1), _normalize_value(m.group(3))), f"{class_name}.{m.group(2)}")

    private: dict[tuple[str, str, str], set[str]] = {}
    for dart_file in Path(lib_root).rglob("*.dart"):
        owner = _owner_of(str(dart_file))
        if owner is None or owner == "core":
            continue
        for line in _read_file(dart_file).splitlines():
            m = _STATIC_CONST_DECL.match(line)
            if m and m.group(2).startswith("_"):
                key = (m.group(1), m.group(2).lstrip("_").lower(), _normalize_value(m.group(3)))
                private.setdefault(key, set()).add(owner)

    _const_index_cache[lib_root] = (theme, private)
    return theme, private


def check_theme_import(result: AnalysisResult) -> None:
    """Check that values shared between features live in core/presentation/theme.dart.

    (a) The same private `static const` (type, name, value) in two or more
        features is a shared value — move it to the core theme class.
    (b) A private spacing constant (padding/spacing/gap/margin/inset) whose value
        already exists in the core theme class must use that shared constant.
    Constants used by a single widget stay private `static const` of that widget.
    """
    if not _is_presentation_file(result.file) or _is_in_di_folder(result.file):
        return
    if result.file.endswith(CORE_THEME_FILE):
        return
    lib_root = _lib_root(result.file)
    owner = _owner_of(result.file)
    if lib_root is None or owner is None or owner == "core":
        return

    theme, private = _const_index(lib_root)
    content = _read_file(Path(result.file))

    for i, line in enumerate(content.splitlines(), 1):
        m = _STATIC_CONST_DECL.match(line)
        if not m or not m.group(2).startswith("_"):
            continue
        dart_type, name, value = m.group(1), m.group(2), _normalize_value(m.group(3))

        owners = private.get((dart_type, name.lstrip("_").lower(), value), set())
        if len(owners) > 1:
            result.violations.append(Violation(
                file=result.file, line=i, rule="theme_import",
                message=f"'{name}' is shared by features {sorted(owners)} — move it to lib/{CORE_THEME_FILE}",
                snippet=_line_at(content, i),
            ))
            continue

        shared = theme.get((dart_type, value))
        if shared and any(word in name.lower() for word in LAYOUT_NAME_WORDS):
            result.violations.append(Violation(
                file=result.file, line=i, rule="theme_import",
                message=f"'{name}' duplicates {shared} from lib/{CORE_THEME_FILE} — use the shared constant",
                snippet=_line_at(content, i),
            ))
# ── Main ────────────────────────────────────────────────────────────

CHECKERS = {
    "naming_file": check_naming_file,
    "naming_class": check_naming_class,
    "magic_numbers": check_magic_numbers,
    "magic_strings": check_magic_strings,
    "magic_colors": check_magic_colors,
    "widget_helpers": check_widget_helpers,
    "inline_callbacks": check_inline_callbacks,
    "import_violation": check_import_violation,
    "setstate_usage": check_setstate_usage,
    "stateful_no_lifecycle": check_stateful_no_lifecycle,
    "dartdoc_public": check_dartdoc_public,
    "no_state_in_di": check_no_state_in_di,
    "widget_stateless": check_widget_stateless,
    "watching_widget": check_watching_widget,
    "no_controller_in_ui": check_no_controller_in_ui,
    "static_const_order": check_static_const_order,
    "no_build_return": check_no_build_return,
    "folder_naming": check_folder_naming,
    "async_gap_context_mounted": check_async_gap_context_mounted,
    "widget_key_parameter": check_widget_key_parameter,
    "controller_lifecycle": check_controller_lifecycle,
    "widget_methods": check_widget_methods,
    "stateless_with_controllers": check_stateless_with_controllers,
    "static_const_in_state_class": check_static_const_in_state_class,
    "magic_numbers_in_layout": check_magic_numbers_in_layout,
    "theme_import": check_theme_import,
    "value_listenable_exposure": check_value_listenable_exposure,
    "watch_order": check_watch_order,
}
def _collect_dart_files(path: str) -> list[Path]:
    """Collect all .dart files under the given path."""
    p = Path(path)
    if p.is_file():
        return [p] if p.suffix == ".dart" else []
    return sorted(p.rglob("*.dart"))
def analyze(path: str, rules: set[str], json_output: bool = False, ignore_files: list[str] | None = None) -> AnalysisReport:
    """Analyze Dart files and return a report."""
    # Reset per-run state for folder_naming dedup
    _folder_naming_reported.clear()
    _const_index_cache.clear()

    dart_files = _collect_dart_files(path)

    report = AnalysisReport(rules_enabled=rules)
    report.total_files = len(dart_files)

    # Merge default ignore files with user-provided ones
    all_ignored = list(DEFAULT_IGNORE_FILES)
    if ignore_files:
        all_ignored.extend(ignore_files)

    for dart_file in dart_files:
        fp = str(dart_file)

        # Skip files matching default or --ignore-files patterns
        skip = False
        for pattern in all_ignored:
            if pattern.lower() in fp.lower():
                skip = True
                break
        if skip:
            continue

        result = AnalysisResult(file=fp)

        for rule in sorted(rules):
            checker = CHECKERS.get(rule)
            if checker:
                try:
                    checker(result)
                except Exception as e:
                    print(f"Warning: checker '{rule}' failed on {fp}: {e}", file=sys.stderr)

        report.results.append(result)
        report.total_violations += len(result.violations)

    if json_output:
        print(json.dumps(report.to_dict(), indent=2))
    else:
        _print_text_report(report)

    return report
def _print_text_report(report: AnalysisReport) -> None:
    """Print a human-readable report."""
    print(f"\n{'='*70}")
    print(f"  revoockv Clean Architecture — Dart Linter Report")
    print(f"{'='*70}")
    print(f"  Files analyzed: {report.total_files}")
    print(f"  Violations found: {report.total_violations}")
    print(f"  Rules enabled: {', '.join(sorted(report.rules_enabled))}")
    print(f"{'='*70}\n")

    for result in report.results:
        if not result.has_violations:
            continue

        print(f"  {result.file}")
        for v in result.violations:
            line_info = f"line {v.line}: " if v.line > 0 else ""
            print(f"    [{v.rule}] {line_info}{v.message}")
            if v.snippet:
                print(f"      -> {v.snippet[:100]}")
        print()
def _parse_rules(rule_str: str) -> set[str]:
    """Parse comma-separated rule names or 'all'."""
    rule_str = rule_str.strip().lower()
    if rule_str == "all":
        return ALL_RULES.copy()
    rules = set()
    for r in rule_str.split(","):
        r = r.strip()
        if r in ALL_RULES:
            rules.add(r)
        else:
            print(f"Warning: unknown rule '{r}' — skipping", file=sys.stderr)
    return rules
def main() -> None:
    parser = argparse.ArgumentParser(
        description="Automated Dart code analyzer for revoockv Flutter Clean Architecture.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Rules (comma-separated, or 'all' for all):
  naming_file        — file names must follow conventions
  naming_class       — widget/page classes must end with _Widget/_Page
  magic_numbers      — numbers must be static const (exceptions: -1, 0, 1, 2)
  magic_strings      — string literals must be static const
  magic_colors       — Color/Colors references must be static const
  widget_helpers     — no widget-returning helper methods (use widgets/ folder)
  inline_callbacks   — no inline closures in callbacks
  import_violation   — presentation reaches data only via getters (no data/, repos, use cases, di)
  setstate_usage     — no setState() calls
  stateful_no_lifecycle — StatefulWidget must have lifecycle methods
  dartdoc_public     — public classes/methods must have /// documentation
  no_state_in_di     — no instanceName, no ValueNotifier in GetIt
  widget_stateless   — StatelessWidget preferred
  watching_widget    — watch_it calls only in Watching widgets, and Watching widgets always call them
  no_controller_in_ui — stateful logic in controllers/ folder
  static_const_order — static const before constructor
  no_build_return    — private Widget methods → separate StatelessWidget
    folder_naming      — feature folder structure must match conventions
    async_gap_context_mounted — Navigator/ScaffoldMessenger after await must check context.mounted
    widget_key_parameter — public widget constructors must have named 'key' parameter
    controller_lifecycle — widgets with disposable controllers must use StatefulWidget with initState/dispose
    widget_methods     — no private methods returning Widget type (anywhere, including widgets/ folder)
    stateless_with_controllers — StatelessWidget calling controller.init()/dispose() must be StatefulWidget
    value_listenable_exposure — expose ValueListenable outward, never ValueNotifier
    watch_order        — watch()/registerHandler() unconditionally at the top of build()
    static_const_in_state_class — static const of a stateful widget in its State class
    magic_numbers_in_layout — numbers in EdgeInsets/Size/Offset/Color must be static const
    theme_import       — shared values in lib/core/presentation/theme.dart

Default ignored files: firebase_options.dart (cannot be disabled)

Examples:
    python scripts/dart_clean_arch_linter.py lib/features/song
    python scripts/dart_clean_arch_linter.py lib/features/song --rules magic_numbers,inline_callbacks
    python scripts/dart_clean_arch_linter.py lib/features/song --json
    python scripts/dart_clean_arch_linter.py lib/features/song --strict
    python scripts/dart_clean_arch_linter.py lib/features/auth --ignore-files firebase_options.dart
         """,
    )
    parser.add_argument("path", nargs="?", default="lib", help="Path to Dart files or directory (default: whole project lib)")
    parser.add_argument("--rules", default="all", help="Comma-separated rule names or 'all'")
    parser.add_argument("--json", action="store_true", help="Output JSON format")
    parser.add_argument("--strict", action="store_true", help="Exit with code 1 on any violation")
    parser.add_argument("--ignore", nargs="*", help="Rules to ignore (comma-separated per arg)")
    parser.add_argument("--ignore-files", nargs="*", help="File patterns to skip entirely (glob or substring)")
    parser.add_argument("--version", action="version", version=f"%(prog)s {__version__}")

    args = parser.parse_args()

    rules = _parse_rules(args.rules)

    # Remove ignored rules
    for ignore_arg in (args.ignore or []):
        for r in ignore_arg.split(","):
            r = r.strip()
            if r in rules:
                rules.discard(r)

    path = args.path

    if not Path(path).exists():
        print(f"Error: path '{path}' does not exist", file=sys.stderr)
        sys.exit(1)

    report = analyze(path, rules, args.json, args.ignore_files)

    if args.strict and report.has_violations:
        sys.exit(1)

    sys.exit(0)
if __name__ == "__main__":
    main()
