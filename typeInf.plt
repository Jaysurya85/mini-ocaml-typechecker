:- begin_tests(typeInf).
:- include(typeInf). 

/* Note: when writing tests keep in mind that 
    the use of of global variable and function definitions
    define facts for gvar() predicate. Either test
    directy infer() predicate or call
    delegeGVars() predicate to clean up gvar().
*/

% tests for typeExp
test(typeExp_iplus) :- 
    typeExp(iplus(int,int), int).

% this test should fail
test(typeExp_iplus_F, [fail]) :-
    typeExp(iplus(int, int), float).

test(typeExp_iplus_T, [true(T == int)]) :-
    typeExp(iplus(int, int), T).

test(typeExp_builtin_conversion, [true(T == float)]) :-
    typeExp(iToFloat(int), T).

test(typeExp_builtin_print, [true(T == unit)]) :-
    typeExp(print(string), T).

% NOTE: use nondet as option to test if the test is nondeterministic

% test for statement with state cleaning
test(typeStatement_gvar, [nondet, true(T == int)]) :- % should succeed with T=int
    deleteGVars(), /* clean up variables */
    typeStatement(gvLet(v, T, iplus(X, Y)), unit),
    assertion(X == int), assertion( Y == int), % make sure the types are int
    gvar(v, int). % make sure the global variable is defined

% same test as above but with infer 
test(infer_gvar, [nondet]) :-
    infer([gvLet(v, T, iplus(X, Y))], unit),
    assertion(T==int), assertion(X==int), assertion(Y=int),
    gvar(v,int).

% test custom function with mocked definition
test(mockedFct, [nondet]) :-
    deleteGVars(), % clean up variables since we cannot use infer
    asserta(gvar(my_fct, [int, float])), % add my_fct(int)-> float to the gloval variables
    typeExp(my_fct(X), T), % infer type of expression using or function
    assertion(X==int), assertion(T==float). % make sure the types infered are correct

test(deleteGVars_cleans_globals, [fail]) :-
    asserta(gvar(temp, int)),
    deleteGVars(),
    gvar(temp, int).

test(infer_resets_old_globals, [nondet]) :-
    deleteGVars(),
    asserta(gvar(stale, string)),
    infer([gvLet(v, T, iplus(X, Y))], unit),
    assertion(T == int),
    assertion(X == int),
    assertion(Y == int),
    \+ gvar(stale, _),
    gvar(v, int).

test(infer_two_global_lets, [nondet, true(T == unit)]) :-
    infer([gvLet(v1, int, int), gvLet(v2, float, iToFloat(int))], T),
    gvar(v1, int),
    gvar(v2, float).

test(typeStatement_exprStmt, [true(T == int)]) :-
    typeStatement(exprStmt(iplus(int, int)), T).

test(typeStatement_block_expr_last, [nondet, true(T == int)]) :-
    typeStatement(block([gvLet(v, int, int), exprStmt(iplus(int, int))]), T).

test(typeStatement_block_unit_last, [nondet, true(T == unit)]) :-
    typeStatement(block([exprStmt(print(string)), gvLet(v, int, int)]), T).

test(infer_exprStmt, [nondet, true(T == int)]) :-
    infer([exprStmt(iplus(int, int))], T).

test(infer_block, [nondet, true(T == int)]) :-
    infer([block([gvLet(v, int, int), exprStmt(iplus(int, int))])], T),
    gvar(v, int).

test(infer_nested_block, [nondet, true(T == float)]) :-
    infer([block([exprStmt(print(string)), block([exprStmt(iToFloat(int))])])], T).

test(typeExp_global_var_lookup, [nondet, true(T == int)]) :-
    deleteGVars(),
    asserta(gvar(v, int)),
    typeExp(v, T).

test(typeStatement_gfLet, [nondet]) :-
    deleteGVars(),
    typeStatement(gfLet(add, [x, y], [int, int], int, exprStmt(iplus(x, y))), unit),
    gvar(add, [int, int, int]),
    \+ gvar(x, _),
    \+ gvar(y, _),
    typeExp(add(A, B), T),
    assertion(A == int),
    assertion(B == int),
    assertion(T == int).

test(infer_gfLet_call, [nondet, true(T == int)]) :-
    infer([
        gfLet(add, [x, y], [int, int], int, exprStmt(iplus(x, y))),
        exprStmt(add(int, int))
    ], T).

test(infer_gfLet_block_body, [nondet, true(T == int)]) :-
    infer([
        gfLet(add, [x, y], [int, int], int,
              block([exprStmt(print(string)), exprStmt(iplus(x, y))])),
        exprStmt(add(int, int))
    ], T).

test(gfLet_argument_cleanup_preserves_global, [nondet]) :-
    deleteGVars(),
    asserta(gvar(x, string)),
    typeStatement(gfLet(id, [x], [int], int, exprStmt(x)), unit),
    gvar(id, [int, int]),
    gvar(x, string),
    \+ gvar(x, int).

test(typeExp_letIn, [nondet, true(T == int)]) :-
    typeExp(letIn(x, int, int, iplus(x, int)), T).

test(typeExp_letIn_mismatch, [fail]) :-
    typeExp(letIn(x, int, float, x), _).

test(infer_letIn_exprStmt, [nondet, true(T == int)]) :-
    infer([exprStmt(letIn(x, int, int, iplus(x, int)))], T).

test(letIn_cleanup_preserves_global, [nondet, true(T == string)]) :-
    deleteGVars(),
    asserta(gvar(x, string)),
    typeExp(letIn(x, int, int, x), int),
    gvar(x, T),
    \+ gvar(x, int).

test(letIn_inside_gfLet_body, [nondet, true(T == int)]) :-
    infer([
        gfLet(add1, [y], [int], int, exprStmt(letIn(x, int, y, iplus(x, int)))),
        exprStmt(add1(int))
    ], T).

test(typeStatement_ifStmt, [nondet, true(T == int)]) :-
    typeStatement(
        ifStmt(ieq(int, int),
               block([exprStmt(iplus(int, int))]),
               block([exprStmt(iminus(int, int))])),
        T).

test(typeStatement_ifStmt_bad_cond, [fail]) :-
    typeStatement(
        ifStmt(float,
               block([exprStmt(int)]),
               block([exprStmt(int)])),
        _).

test(typeStatement_ifStmt_branch_mismatch, [fail]) :-
    typeStatement(
        ifStmt(ieq(int, int),
               block([exprStmt(int)]),
               block([exprStmt(float)])),
        _).

test(infer_ifStmt, [nondet, true(T == int)]) :-
    infer([
        ifStmt(ieq(int, int),
               block([exprStmt(iplus(int, int))]),
               block([exprStmt(imul(int, int))]))
    ], T).

test(infer_ifStmt_in_block, [nondet, true(T == unit)]) :-
    infer([
        block([
            exprStmt(print(string)),
            ifStmt(ieq(int, int),
                   block([gvLet(v, int, int)]),
                   block([gvLet(w, int, int)]))
        ])
    ], T).

test(typeStatement_forStmt, [nondet, true(T == unit)]) :-
    typeStatement(
        forStmt(i, int, int, block([exprStmt(print(i))])),
        T).

test(typeStatement_forStmt_bad_start, [fail]) :-
    typeStatement(
        forStmt(i, float, int, block([exprStmt(print(i))])),
        _).

test(typeStatement_forStmt_bad_end, [fail]) :-
    typeStatement(
        forStmt(i, int, float, block([exprStmt(print(i))])),
        _).

test(typeStatement_forStmt_bad_body, [fail]) :-
    typeStatement(
        forStmt(i, int, int, exprStmt(i)),
        _).

test(infer_forStmt, [nondet, true(T == unit)]) :-
    infer([
        forStmt(i, int, int, block([exprStmt(print(i))]))
    ], T).

test(forStmt_cleanup_preserves_global, [nondet, true(T == string)]) :-
    deleteGVars(),
    asserta(gvar(i, string)),
    typeStatement(forStmt(i, int, int, block([exprStmt(print(i))])), unit),
    gvar(i, T),
    \+ gvar(i, int).

test(infer_exprStmt_float_builtin, [nondet, true(T == float)]) :-
    infer([exprStmt(fplus(float, float))], T).

test(infer_block_last_unit, [nondet, true(T == unit)]) :-
    infer([block([exprStmt(iplus(int, int)), exprStmt(print(string))])], T).

test(infer_multiple_gfLets, [nondet, true(T == int)]) :-
    infer([
        gfLet(add, [x, y], [int, int], int, exprStmt(iplus(x, y))),
        gfLet(twice, [z], [int], int, exprStmt(add(z, z))),
        exprStmt(twice(int))
    ], T).

test(infer_letIn_inside_block, [nondet, true(T == int)]) :-
    infer([
        block([
            exprStmt(print(string)),
            exprStmt(letIn(x, int, int, imul(x, int)))
        ])
    ], T).

test(infer_ifStmt_with_letIn_branches, [nondet, true(T == int)]) :-
    infer([
        ifStmt(ieq(int, int),
               block([exprStmt(letIn(x, int, int, iplus(x, int)))]),
               block([exprStmt(letIn(y, int, int, iminus(y, int)))]))
    ], T).

test(infer_forStmt_after_global_let, [nondet, true(T == unit)]) :-
    infer([
        gvLet(limit, int, int),
        forStmt(i, int, int, block([exprStmt(print(i))]))
    ], T),
    gvar(limit, int).

test(infer_invalid_expr_mismatch, [fail]) :-
    infer([exprStmt(iplus(int, float))], _).

test(infer_invalid_gfLet_bad_return, [fail]) :-
    infer([
        gfLet(add_bad, [x, y], [int, int], float, exprStmt(iplus(x, y)))
    ], _).

test(infer_invalid_gfLet_bad_args, [fail]) :-
    infer([
        gfLet(add, [x, y], [int, int], int, exprStmt(iplus(x, y))),
        exprStmt(add(int, float))
    ], _).

test(infer_invalid_if_branch_mismatch, [fail]) :-
    infer([
        ifStmt(ieq(int, int),
               block([exprStmt(int)]),
               block([exprStmt(float)]))
    ], _).

test(infer_invalid_for_body, [fail]) :-
    infer([
        forStmt(i, int, int, exprStmt(i))
    ], _).

test(typeExp_tuple_2, [nondet, true(T == tuple([int, float]))]) :-
    typeExp(tupleExp([int, float]), T).

test(typeExp_tuple_3, [nondet, true(T == tuple([int, float, string]))]) :-
    typeExp(tupleExp([int, float, string]), T).

test(typeExp_tuple_nested, [nondet, true(T == tuple([int, tuple([float, string])]))]) :-
    typeExp(tupleExp([int, tupleExp([float, string])]), T).

test(typeExp_tuple_invalid_element, [fail]) :-
    typeExp(tupleExp([bogus]), _).

test(infer_tuple_exprStmt, [nondet, true(T == tuple([int, float]))]) :-
    infer([exprStmt(tupleExp([int, float]))], T).

test(infer_tuple_in_block, [nondet, true(T == tuple([int, string]))]) :-
    infer([
        block([
            exprStmt(print(string)),
            exprStmt(tupleExp([int, string]))
        ])
    ], T).

test(infer_tuple_in_letIn, [nondet, true(T == tuple([int, int]))]) :-
    infer([
        exprStmt(letIn(x, int, int, tupleExp([x, int])))
    ], T).

test(infer_tuple_nested, [nondet, true(T == tuple([tuple([int, float]), string]))]) :-
    infer([
        exprStmt(tupleExp([tupleExp([int, float]), string]))
    ], T).

:-end_tests(typeInf).
