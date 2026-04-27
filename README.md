
# Prolog Type Inference Project

This project implements a small type inference system in SWI-Prolog for a simplified OCaml-like language.

The implementation supports:

- Expression inference
- Global variable definitions
- Global function definitions
- Expression statements
- Return statements
- Blocks
- Local `let in` expressions
- Local `let in` statements
- `if` statements
- `for` loops
- Tuple expressions and tuple types
- Tuple unpacking
- Sum types
- `match` statements

The current test suite contains:

- `41` total tests
- `29` `infer/2` entry-point tests
- `12` direct predicate tests

---

## How To Run

Run the full test suite:

```bash
make test
```

Run tests directly with SWI-Prolog:

```bash
swipl -q -g "consult('typeInf.plt'), run_tests, halt."
```
---

## Builtin Functions

**Integer arithmetic:** `iplus`, `iminus`, `imul`, `idiv`

**Float arithmetic:** `fplus`, `fminus`, `fmul`, `fdiv`

**Conversions:** `fToInt`, `iToFloat`

**Equality:** `ieq`, `feq`, `streq`

**Output:** `print`, `println`

**Starter-style aliases:** `+`, `+.`, `itimes`, `idivide`, `ftimes`, `fdivide`, `=`, `==`, `<`

---

## Project Structure And Design Notes

- Global names are tracked through dynamic `gvar/2` facts.
- Local names are tracked through an environment list of `Name-Type` pairs. This environment is passed through the internal predicates: `typeExp/3`, `typeStatement/3`, `typeCode/3`.
- The public predicates keep the simpler starter-style interface: `typeExp/2`, `typeStatement/2`, `typeCode/2`, `infer/2`.

The environment is used for:

- Function arguments
- `letIn`
- `letInStmt`
- `lvLetIn`
- For loop variables
- Match case variables

Function signatures are stored as lists:

```prolog
[ArgType1, ArgType2, ReturnType]
```

Tuple unpacking expands tuple element types into separate global bindings.

Sum types use an explicit representation:

```prolog
sum([left-int, right-string])
sumVal(left, int, sum([left-int, right-string]))
```

This avoids ambiguous constructor typing.

---

## Test Coverage

The test suite covers:

- Valid basic expressions
- Builtin functions
- Global lets
- Global functions
- Inferred function signatures
- Blocks
- Return statements
- `letIn`
- `letInStmt`
- `ifStmt`
- `forStmt`
- Tuple expressions
- Tuple unpacking
- Sum values
- `matchStmt`
- Cleanup and scoping behavior
- Failure cases for mismatches and invalid forms

**Representative failure cases include:**

- Invalid argument types
- Invalid function return declarations
- Branch type mismatches
- Invalid loop bodies
- Tuple arity mismatch
- Invalid tuple RHS
- Invalid sum tags
- Invalid sum payloads
- Missing match branches
- Invalid match constructors
- Failed inference cleanup

---

