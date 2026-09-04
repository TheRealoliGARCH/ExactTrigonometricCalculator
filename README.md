# Exact Trigonometric Calculator

A pure **Wolfram Language / Mathematica** exact trigonometric calculator for finite decimal-degree inputs.

The repository is organized around a constructive symbolic engine, a native LaTeX exporter, and a Mathematica notebook demonstrating the workflow. The notebook is intentionally minimal: it contains **one executable input cell** that loads the two `.wl` source files relative to the notebook location, performs an exact calculation, displays the LaTeX representation, and exports the result to `result.tex`.

## Requirements

- Wolfram Mathematica with the desktop Wolfram Language front end.
- The notebook and the two `.wl` source files must remain in the same directory.

## Notebook workflow

Open

```text
ExactTrigonometricCalculator.nb
```

in Mathematica and evaluate its single input cell.

The cell uses `NotebookDirectory[]` so that no machine-specific absolute paths are required. Conceptually, it performs:

```wl
Get[FileNameJoin[{NotebookDirectory[], "engine.wl"}]];
Get[FileNameJoin[{NotebookDirectory[], "latex_exporter.wl"}]];
result = RunCalculation["37.125"];
CalculationToLaTeX[result]
ExportCalculationLaTeX[result, FileNameJoin[{NotebookDirectory[], "result.tex"}]]
```

The generated `result.tex` is written beside the notebook.

## Exact construction

The engine follows the constructive chain developed for the project:

1. Exact anchors at $0^\circ$, $30^\circ$, $45^\circ$, $60^\circ$, and $90^\circ$.
2. $15^\circ$ by the half-angle formula from $30^\circ$.
3. $18^\circ$ from
   $$2\cdot18^\circ=90^\circ-3\cdot18^\circ,$$
   together with the exact Pythagorean constraint.
4. $20^\circ$ is constructed directly from the real-radical expression
   $$\cos20^\circ=\frac{\sqrt[3]{2+\sqrt3}+\sqrt[3]{2-\sqrt3}}{2},$$
   with
   $$\sin20^\circ=\sqrt{1-\cos^2 20^\circ}.$$
   This replaces the complex-unit Cardano representation and keeps the $20^\circ$ anchor entirely in real radicals.
5. $10^\circ$ is then obtained by the half-angle formula from $20^\circ$.
6. $9^\circ$ by halving $18^\circ$.
7. $5^\circ$ by halving $10^\circ$.
8. $4^\circ=9^\circ-5^\circ$, followed by $2^\circ$ and $1^\circ$ by half-angle.
9. $3^\circ=18^\circ-15^\circ$ and $6^\circ=2\cdot3^\circ$.
10. $7^\circ$, $8^\circ$, $36^\circ$, $54^\circ$, and $75^\circ$ are additional reusable DAG nodes.
11. Integer angles are constructed on demand from the explicit core DAG and quadrant symmetries.
12. $\frac13^\circ$ from
    $$\cos(3x)=\cos1^\circ.$$
13. $\frac12^\circ$ by half-angle.
14. $\frac1{10^n}{}^\circ$ recursively from the quintic
    $$16x^5-20x^3+5x-C=0,$$
    where $C$ is the exact cosine of the preceding subdivision.

The engine retains the exact symbolic expressions produced by these constructions. No `RootReduce[]` or `ToRadicals[]` post-processing pass is used. The $20^\circ$ anchor and all values derived from it therefore remain free of the complex unit in their constructive definitions.

## Finite decimal angles

For a finite decimal angle

```text
I.d1d2...dn°
```

the fractional component is constructed digit-by-digit:

$$\frac{d_1}{10}+\frac{d_2}{10^2}+\cdots+\frac{d_n}{10^n}.$$

Each nonzero digit contributes

$$d_k\left(\frac1{10^k}\right)^\circ,$$

using the exact subdivision construction for $\frac1{10^k}{}^\circ$. The digit contributions are then combined with exact addition formulae.

Only the primitive $\frac1{10^k}{}^\circ$ units are memoized. The combined fractional angle is transient and is not cached as a separate node.

For example,

```text
37.125°
```

is represented as

$$37^\circ+\frac1{10}{}^\circ+\frac2{10^2}{}^\circ+\frac5{10^3}{}^\circ.$$

## LaTeX export

`latex_exporter.wl` is a small native Wolfram Language export layer. It converts the exact expressions already produced by `engine.wl` with `TeXForm` and can save the resulting LaTeX source directly to a `.tex` file.

There is no second symbolic computation pass, no radical conversion pass, and no external process or IPC layer.

Programmatic use:

```wl
Get[FileNameJoin[{NotebookDirectory[], "engine.wl"}]];
Get[FileNameJoin[{NotebookDirectory[], "latex_exporter.wl"}]];
result = RunCalculation["37.125"];
CalculationToLaTeX[result]
ExportCalculationLaTeX[result, FileNameJoin[{NotebookDirectory[], "result.tex"}]]
```

## Integral-angle reference

The repository also contains the PDF reference:

```text
Exact Trigonometric Table of Integral Angles.pdf
```

The constructive formulas in that document provide the mathematical reference for the exact engine.

## Architecture

`ExactTrigonometricCalculator.nb` is the Mathematica demonstration notebook and contains the complete five-step workflow in a single executable input cell.

`engine.wl` is the exact symbolic engine. It provides:

- exact sine/cosine pair arithmetic;
- a fixed constructive core DAG;
- session-local memoization of constructed integer-angle pairs;
- direct exact symbolic expressions;
- Chebyshev-based integer multiplication;
- exact quadrant transformations;
- recursive decimal-angle subdivision.

`latex_exporter.wl` converts those already-exact expressions into LaTeX source.

## Programmatic use

The engine can be loaded directly from Mathematica:

```wl
Get[FileNameJoin[{NotebookDirectory[], "engine.wl"}]];
RunCalculation["37.125"]
```

For LaTeX output:

```wl
Get[FileNameJoin[{NotebookDirectory[], "latex_exporter.wl"}]];
result = RunCalculation["37.125"];
CalculationToLaTeX[result]
```

The calculation returns an association containing the exact input angle, its principal representative, the exact `{Sin, Cos}` pair, and the verification identity.

For direct symbolic access, the engine exposes constructive functions such as `CorePair`, `IntegerPair`, `UnitDecimalAngle`, `AddPair`, `SubPair`, `DoublePair`, `TriplePair`, and `HalfPair`.

## Repository structure

```text
ExactTrigonometricCalculator/
├── ExactTrigonometricCalculator.nb   # Single-cell Mathematica workflow
├── engine.wl                         # Exact symbolic engine
├── latex_exporter.wl                 # Native LaTeX exporter
├── Exact Trigonometric Table of Integral Angles.pdf
├── README.md
└── LICENSE
```

## Design principles

The calculator is intended to be a **constructive exact calculator**, rather than a numerical wrapper around built-in trigonometric evaluation. The implementation emphasizes:

- exact algebraic arithmetic;
- explicit construction identities;
- branch-aware root selection;
- a fixed, auditable DAG of reusable exact nodes;
- lazy evaluation;
- session-local memoization;
- direct exact symbolic representation;
- lightweight LaTeX export;
- transparent mathematical verification;
- notebook-relative file loading rather than machine-specific paths.

## Current scope

The current input interface accepts finite decimal degree notation, such as:

```text
37.125
```

Arbitrary rational-angle expressions such as

```text
37° + 1/177°
```

are outside the current input language and remain a future extension.

## Future work

Possible extensions include:

- arbitrary rational-angle input;
- stronger algebraic-number canonicalization and DAG sharing;
- optimized representations for deep rational subdivisions;
- richer derivation and certificate views inside Mathematica.
