(* Run the repository MUnit test suite and return a nonzero exit code on failure. *)

report = TestReport[
  FileNameJoin[{DirectoryName[$InputFileName], "DecimalSubdivisionTests.wlt"}]
];

Print[report];

If[
  report["TestsFailedCount"] > 0 || report["TestsErroredCount"] > 0,
  Exit[1],
  Exit[0]
]
