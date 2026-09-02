(* ::Package:: *)
(* Exact decimal-subdivision regression and invariant tests. *)

Get[FileNameJoin[{DirectoryName[$TestFile], "..", "engine.wl"}]];

Test[NumberOfDecimalPlaces[1/10], 1,
  TestID -> "decimal-places-1-over-10"]
Test[NumberOfDecimalPlaces[1/1000], 3,
  TestID -> "decimal-places-1-over-1000"]
Test[NumberOfDecimalPlaces[1/8], $Failed,
  TestID -> "non-decimal-rational-rejected"]

(* Core invariant:
   UnitDecimalAngle[n] represents exactly 1/10^n degrees.
   The pair is projected back to an angle only for numerical branch
   validation; the construction itself remains exact. *)
Do[
  Test[
    N[ArcTan[UnitDecimalAngle[n]["Sin"], UnitDecimalAngle[n]["Cos"]] 180/Pi, 40],
    N[1/10^n, 40],
    SameTest -> (Abs[#1 - #2] < 10^-30 &),
    TestID -> "unit-angle-1-over-10-power-" <> ToString[n]
  ],
  {n, 1, 4}
]

(* The quintic is exactly the cosine quintuple-angle identity. *)
Do[
  Module[{target, c},
    target = If[n == 1,
      CorePair[1/2]["Cos"],
      HalfPair[UnitDecimalAngle[n - 1]]["Cos"]
    ];
    c = UnitDecimalAngle[n]["Cos"];
    Test[
      FullSimplify[16 c^5 - 20 c^3 + 5 c - target],
      0,
      TestID -> "quintic-invariant-" <> ToString[n]
    ]
  ],
  {n, 1, 4}
]

(* Each recursive step is deliberately half-angle followed by quintic
   fifth-angle inversion: 1/10^(n-1) -> 1/(2*10^(n-1)) -> 1/10^n. *)
Do[
  Module[{h = HalfPair[UnitDecimalAngle[n - 1]]},
    Test[
      N[ArcTan[h["Sin"], h["Cos"]] 180/Pi, 40],
      N[1/(2 10^(n - 1)), 40],
      SameTest -> (Abs[#1 - #2] < 10^-30 &),
      TestID -> "half-step-before-quintic-" <> ToString[n]
    ]
  ],
  {n, 2, 4}
]

(* The digit decomposition must use the n-th primitive unit for the
   n-th decimal place. *)
Do[
  Module[{p = DigitFractionPair[1/10^n]},
    Test[
      N[ArcTan[p["Sin"], p["Cos"]] 180/Pi, 40],
      N[1/10^n, 40],
      SameTest -> (Abs[#1 - #2] < 10^-30 &),
      TestID -> "digit-fraction-unit-" <> ToString[n]
    ]
  ],
  {n, 1, 4}
]

(* Representative public-interface regression test. *)
Test[
  N[ArcTan[
    EvaluateDecimal["37.125"]["Pair"]["Sin"],
    EvaluateDecimal["37.125"]["Pair"]["Cos"]
  ] 180/Pi, 35],
  37.125,
  SameTest -> (Abs[#1 - #2] < 10^-25 &),
  TestID -> "evaluate-decimal-37-125"
]
