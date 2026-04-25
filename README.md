# Prolog Type Inference Project

This project implements a small type inference system in SWI-Prolog for a simplified OCaml-like language.

The implementation supports:

- expression inference
- global variable definitions
- global function definitions
- expression statements
- blocks
- local `let in`
- `if` statements
- `for` loops
- tuple expressions and tuple types
- tuple unpacking
- sum types
- `match` statements

The current test suite contains:

- `31` total tests
- `23` `infer/2` entry-point tests
- `8` direct predicate tests

## How To Run

Run the full test suite:

```bash
make test
```

Run tests directly with SWI-Prolog:

```bash
swipl -q -g "consult('typeInf.plt'), run_tests, halt."
```

## Entry Point

The main top-level predicate is:

```prolog
infer(Code, T).
```

`Code` is a list of statements.  
`T` is the inferred type of the last statement in the list.

Example:

```prolog
infer([exprStmt(iplus(int, int))], T).
```

Expected result:

```prolog
T = int.
```

## Supported Types

Basic types:

- `int`
- `float`
- `string`
- `unit`

Function types:

- represented as lists
- example: `[int, int, int]` means `int -> int -> int`

Tuple types:

- `tuple([T1, T2, ...])`

Sum types:

- `sum([left-int, right-string])`

## Supported Expressions

### Basic expression forms

- plain basic types such as `int`, `float`, `string`
- variable lookup through `gvar/2`
- builtin function calls such as `iplus(int, int)`
- user-defined function calls such as `add(int, int)`

### Local let-in

```prolog
letIn(Name, VarType, ValueExpr, InExpr)
```

Example:

```prolog
letIn(x, int, int, iplus(x, int))
```

### Tuple expressions

```prolog
tupleExp([E1, E2, ...])
```

Example:

```prolog
tupleExp([int, float, string])
```

Inferred type:

```prolog
tuple([int, float, string])
```

### Sum values

```prolog
sumVal(Tag, Expr, SumType)
```

Example:

```prolog
sumVal(left, int, sum([left-int, right-string]))
```

Inferred type:

```prolog
sum([left-int, right-string])
```

## Supported Statements

### Global variable definition

```prolog
gvLet(Name, Type, Expr)
```

Example:

```prolog
gvLet(v, int, iplus(int, int))
```

### Tuple unpacking

```prolog
gvLetTuple([x, y], tupleExp([int, float]))
```

This creates:

```prolog
gvar(x, int).
gvar(y, float).
```

### Global function definition

```prolog
gfLet(Name, ArgNames, ArgTypes, ReturnType, Body)
```

Example:

```prolog
gfLet(add, [x, y], [int, int], int, exprStmt(iplus(x, y)))
```

### Expression statement

```prolog
exprStmt(Expr)
```

### Block

```prolog
block([Stmt1, Stmt2, ...])
```

The block type is the type of its last statement.

### If statement

```prolog
ifStmt(Cond, ThenBlock, ElseBlock)
```

Rules:

- `Cond` must have type `int`
- both branches must produce the same type

### For loop

```prolog
forStmt(VarName, StartExpr, EndExpr, Body)
```

Rules:

- start and end expressions must have type `int`
- loop variable is locally bound as `int`
- body must have type `unit`

### Match statement

```prolog
matchStmt(
    Expr,
    [
        case(left, x, ThenStmt),
        case(right, y, ElseStmt)
    ]
)
```

Rules:

- `Expr` must have a sum type
- cases must cover the declared variants exactly
- each case binds its variable locally to the matched variant type
- all branches must produce the same type

## Builtin Functions

Integer arithmetic:

- `iplus`
- `iminus`
- `imul`
- `idiv`

Float arithmetic:

- `fplus`
- `fminus`
- `fmul`
- `fdiv`

Conversions:

- `fToInt`
- `iToFloat`

Equality:

- `ieq`
- `feq`
- `streq`

Other:

- `print`

## Project Structure And Design Notes

Global names are tracked through dynamic `gvar/2` facts.

The implementation uses temporary `gvar/2` bindings with cleanup for:

- function arguments
- `letIn`
- `for` loop variables
- `match` case variables

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

## Test Coverage

The test suite covers:

- valid basic expressions
- builtin functions
- global lets
- global functions
- blocks
- `letIn`
- `ifStmt`
- `forStmt`
- tuple expressions
- tuple unpacking
- sum values
- `matchStmt`
- cleanup and scoping behavior
- failure cases for mismatches and invalid forms

Representative failure cases include:

- invalid argument types
- invalid function return declarations
- branch type mismatches
- invalid loop bodies
- tuple arity mismatch
- invalid tuple RHS
- invalid sum tags
- invalid sum payloads
- missing `match` branches
- invalid `match` constructors

## Example Queries

Infer a simple expression:

```prolog
typeExp(iplus(int, int), T).
```

Infer a function call after a definition:

```prolog
infer([
    gfLet(add, [x, y], [int, int], int, exprStmt(iplus(x, y))),
    exprStmt(add(int, int))
], T).
```

Infer a tuple:

```prolog
infer([
    exprStmt(tupleExp([int, float, string]))
], T).
```

Infer a sum match:

```prolog
infer([
    matchStmt(
        sumVal(left, int, sum([left-int, right-string])),
        [
            case(left, x, exprStmt(iplus(x, int))),
            case(right, y, block([exprStmt(print(y)), exprStmt(int)]))
        ])
], T).
```
