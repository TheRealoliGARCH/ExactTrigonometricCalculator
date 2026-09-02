(* Native LaTeX exporter for the Exact Trigonometric Calculator. *)

ClearAll[ExactToLaTeX, CalculationToLaTeX, ExportCalculationLaTeX];

ExactToLaTeX[x_] := ToString[TeXForm[x]];

CalculationToLaTeX[result_Association] := Module[{angle, pair},
  If[!KeyExistsQ[result, "Pair"], Return[$Failed]];
  angle = result["Angle"];
  pair = result["Pair"];
  StringRiffle[
    {
      "\\begin{align*}",
      "\\sin(" <> angle <> "^\\circ) &= " <> ExactToLaTeX[pair["Sin"]] <> " \\\\",
      "\\cos(" <> angle <> "^\\circ) &= " <> ExactToLaTeX[pair["Cos"]],
      "\\end{align*}"
    },
    "\n"
  ]
];

ExportCalculationLaTeX[result_Association, file_String] := Module[{latex},
  latex = CalculationToLaTeX[result];
  If[latex === $Failed, Return[$Failed]];
  Export[file, latex, "Text"]
];
