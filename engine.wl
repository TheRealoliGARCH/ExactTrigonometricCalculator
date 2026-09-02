(* Exact trigonometric engine for the Exact Trigonometric Calculator. *)

ClearAll[
  ExactPair, CanonicalAngle, AddPair, SubPair, DoublePair, TriplePair,
  HalfPair, MultiplyPair, CorePair, UnitDecimalAngle,
  NumberOfDecimalPlaces, DigitFractionPair, EvaluateDecimal,
  RunCalculation, CubicLargestRoot, QuinticLargestRoot,
  IntegerPair, IntegerCoreNodes, $ExactCore, $IntegerCoreAngles,
  $IntegerCoreLookup, $IntegerDecomposition
];

(* Pure Wolfram Language constructive exact computation. All generated
   trigonometric values are stored directly as exact radical expressions. *)

ExactPair[s_, c_] := <|"Sin" -> s, "Cos" -> c|>;
CanonicalAngle[a_] := Mod[a, 360];

AddPair[p_, q_] := ExactPair[
  p["Sin"] q["Cos"] + p["Cos"] q["Sin"],
  p["Cos"] q["Cos"] - p["Sin"] q["Sin"]
];

SubPair[p_, q_] := ExactPair[
  p["Sin"] q["Cos"] - p["Cos"] q["Sin"],
  p["Cos"] q["Cos"] + p["Sin"] q["Sin"]
];

DoublePair[p_] := ExactPair[
  2 p["Sin"] p["Cos"],
  p["Cos"]^2 - p["Sin"]^2
];

TriplePair[p_] := ExactPair[
  3 p["Sin"] - 4 p["Sin"]^3,
  4 p["Cos"]^3 - 3 p["Cos"]
];

HalfPair[p_] := ExactPair[
  Sqrt[(1 - p["Cos"])/2],
  Sqrt[(1 + p["Cos"])/2]
];

MultiplyPair[p_, n_Integer?NonNegative] := Module[{s, c},
  If[n == 0, Return[ExactPair[0, 1]]];
  s = p["Sin"];
  c = p["Cos"];
  ExactPair[s ChebyshevU[n - 1, c], ChebyshevT[n, c]]
];

CubicLargestRoot[f_] := Root[f, 3];
QuinticLargestRoot[target_] := Root[16 #^5 - 20 #^3 + 5 # - target &, 5];

(* Fundamental constructive anchors.
   The dependency chain follows the explicit radical hierarchy:
   20 -> 10 -> 5, 18 -> 9, 4 = 9 - 5 -> 2 -> 1,
   and 3 = 18 - 15. *)

CorePair[0] = ExactPair[0, 1];
CorePair[30] = ExactPair[1/2, Sqrt[3]/2];
CorePair[45] = ExactPair[Sqrt[2]/2, Sqrt[2]/2];
CorePair[60] = ExactPair[Sqrt[3]/2, 1/2];
CorePair[90] = ExactPair[1, 0];

(* Use compact closed radicals directly to reduce downstream expression size. *)
CorePair[15] = ExactPair[
  (Sqrt[6] - Sqrt[2])/4,
  (Sqrt[6] + Sqrt[2])/4
];

CorePair[18] = ExactPair[
  (Sqrt[5] - 1)/4,
  Sqrt[10 + 2 Sqrt[5]]/4
];

(* Cardano radical form for cos 20 degrees. The conjugate cube roots
   are principal branches and their sum is real. *)
CorePair[20] := CorePair[20] = Module[{c},
  c = (1 + I Sqrt[3])^(1/3)/2 + (1 - I Sqrt[3])^(1/3)/2;
  ExactPair[Sqrt[1 - c^2], c]
];

CorePair[10] := CorePair[10] = HalfPair[CorePair[20]];
CorePair[5] := CorePair[5] = HalfPair[CorePair[10]];
CorePair[9] := CorePair[9] = HalfPair[CorePair[18]];
CorePair[4] := CorePair[4] = SubPair[CorePair[9], CorePair[5]];
CorePair[2] := CorePair[2] = HalfPair[CorePair[4]];
CorePair[1] := CorePair[1] = HalfPair[CorePair[2]];
CorePair[3] := CorePair[3] = SubPair[CorePair[18], CorePair[15]];
CorePair[6] := CorePair[6] = DoublePair[CorePair[3]];
CorePair[7] := CorePair[7] = AddPair[CorePair[5], CorePair[2]];
CorePair[8] := CorePair[8] = DoublePair[CorePair[4]];
CorePair[36] := CorePair[36] = DoublePair[CorePair[18]];
CorePair[54] := CorePair[54] = TriplePair[CorePair[18]];
CorePair[75] := CorePair[75] = AddPair[CorePair[45], CorePair[30]];

CorePair[1/3] := CorePair[1/3] = Module[{c},
  c = CubicLargestRoot[4 #^3 - 3 # - CorePair[1]["Cos"] &];
  ExactPair[Sqrt[1 - c^2], c]
];

CorePair[1/2] := CorePair[1/2] = HalfPair[CorePair[1]];

$IntegerCoreAngles = {
  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 18, 20,
  30, 36, 45, 54, 60, 75, 90
};

IntegerCoreNodes[] := $IntegerCoreAngles;
$IntegerCoreLookup = AssociationThread[
  $IntegerCoreAngles,
  ConstantArray[True, Length[$IntegerCoreAngles]]
];

(* For non-core first-quadrant angles, precompute the nearest-core
   decomposition once. Core angles themselves bypass this table. *)
$IntegerDecomposition = Association@Table[
  k -> With[{candidates = Select[$IntegerCoreAngles, # < k &]},
    {Max[candidates], k - Max[candidates]}
  ],
  {k, 1, 90}
];

(* Session-local memoization only. *)
$ExactCore = <||>;

(* Construct an integer-angle DAG. *)
IntegerPair[n_Integer] := Module[{k = Mod[n, 360], p, base, decomposition},
  If[KeyExistsQ[$ExactCore, k], Return[$ExactCore[k]]];

  p = Which[
    0 <= k <= 90 && KeyExistsQ[$IntegerCoreLookup, k],
      CorePair[k],
    0 <= k <= 90,
      decomposition = $IntegerDecomposition[k];
      AddPair[CorePair[decomposition[[1]]], IntegerPair[decomposition[[2]]]],
    k <= 180,
      base = IntegerPair[180 - k];
      ExactPair[base["Sin"], -base["Cos"]],
    k <= 270,
      base = IntegerPair[k - 180];
      ExactPair[-base["Sin"], -base["Cos"]],
    True,
      base = IntegerPair[360 - k];
      ExactPair[-base["Sin"], base["Cos"]]
  ];

  AssociateTo[$ExactCore, k -> p];
  p
];

(* Construct 1/10^n degree recursively from the quintic subdivision equation. *)
UnitDecimalAngle[n_Integer?Positive] := UnitDecimalAngle[n] = Module[{targetPair, c},
  targetPair = If[n == 1, CorePair[1/2], HalfPair[UnitDecimalAngle[n - 1]]];
  c = QuinticLargestRoot[targetPair["Cos"]];
  ExactPair[Sqrt[1 - c^2], c]
];

NumberOfDecimalPlaces[f_Rational] := Module[{q = Denominator[f], a = 0, b = 0},
  While[Mod[q, 2] == 0, q = Quotient[q, 2]; a++];
  While[Mod[q, 5] == 0, q = Quotient[q, 5]; b++];
  If[q != 1, Return[$Failed]];
  Max[a, b]
];

DigitFractionPair[f_Rational] := Module[{digits, scale, numerator, text, terms, d, i},
  If[!(0 < f < 1), Return[$Failed]];
  digits = NumberOfDecimalPlaces[f];
  If[digits === $Failed, Return[$Failed]];
  scale = 10^digits;
  numerator = Numerator[f] scale/Denominator[f];
  text = IntegerString[numerator, 10, digits];
  terms = DeleteCases[
    Table[
      d = FromDigits[StringTake[text, {i}]];
      If[d == 0, Nothing,
        MultiplyPair[UnitDecimalAngle[i], d]
      ],
      {i, StringLength[text]}
    ],
    Nothing
  ];
  Fold[AddPair, ExactPair[0, 1], terms]
];

EvaluateDecimal[text_String] := Module[{s, a, p, whole, frac, fp},
  s = StringTrim[StringReplace[text, "°" -> ""]];
  If[!StringMatchQ[s, RegularExpression["[+-]?(\\d+(\\.\\d*)?|\\.\\d+)"]],
    Return[$Failed]
  ];
  a = Rationalize[ToExpression[s], 0];
  p = CanonicalAngle[a];
  whole = Floor[p];
  frac = p - whole;
  If[frac == 0,
    Return[<|"Angle" -> a, "Principal" -> p, "Pair" -> IntegerPair[whole]|>]
  ];
  fp = DigitFractionPair[frac];
  If[fp === $Failed, Return[$Failed]];
  <|"Angle" -> a, "Principal" -> p, "Pair" -> AddPair[IntegerPair[whole], fp]|>
];

RunCalculation[text_String] := Module[{r = EvaluateDecimal[text]},
  If[r === $Failed,
    <|"Error" -> "Input must be a finite decimal degree."|>,
    <|"Angle" -> ToString[r["Angle"], InputForm],
      "Principal" -> ToString[r["Principal"], InputForm],
      "Pair" -> r["Pair"],
      "Identity" -> "1  (sin^2 A + cos^2 A = 1 by exact construction)"|>
  ]
];
