:- begin_tests(typeInf).
:- include(typeInf).

/* direct typeExp tests */
test(typeExp_builtin_conversion, [true(T == float)]) :-
    typeExp(iToFloat(int), T).

test(typeExp_iplus_infers_args, [true(T == int)]) :-
    typeExp(iplus(X, Y), T),
    assertion(X == int),
    assertion(Y == int).

test(typeExp_iplus_bad_return, [fail]) :-
    typeExp(iplus(int, int), float).

test(typeStatement_gvar, [nondet, true(T == int)]) :-
    deleteGVars(),
    typeStatement(gvLet(v, T, iplus(X, Y)), unit),
    assertion(X == int),
    assertion(Y == int),
    gvar(v, int).

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

test(typeStatement_gfLet_infers_signature, [nondet]) :-
    deleteGVars(),
    typeStatement(gfLet(add, [x, y], [A, B], R, exprStmt(iplus(x, y))), unit),
    assertion(A == int),
    assertion(B == int),
    assertion(R == int),
    gvar(add, [int, int, int]).

test(typeExp_letIn_mismatch, [fail]) :-
    typeExp(letIn(x, int, float, x), _).

test(typeExp_letIn_infers_local_type, [nondet, true(T == int)]) :-
    typeExp(letIn(x, XType, int, iplus(x, int)), T),
    assertion(XType == int).

test(typeStatement_ifStmt_bad_cond, [fail]) :-
    typeStatement(
        ifStmt(float,
               block([exprStmt(int)]),
               block([exprStmt(int)])),
        _).

test(typeStatement_forStmt_bad_start, [fail]) :-
    typeStatement(
        forStmt(i, float, int, block([exprStmt(print(i))])),
        _).

test(typeExp_tuple_nested, [nondet, true(T == tuple([int, tuple([float, string])]))]) :-
    typeExp(tupleExp([int, tupleExp([float, string])]), T).

test(typeExp_sumVal_bad_tag, [fail]) :-
    typeExp(sumVal(middle, int, sum([left-int, right-string])), _).

/* infer tests */
test(infer_exprStmt, [nondet, true(T == int)]) :-
    infer([exprStmt(iplus(int, int))], T).

test(infer_invalid_expr_mismatch, [fail]) :-
    infer([exprStmt(iplus(int, float))], _).

test(infer_gvar, [nondet]) :-
    infer([gvLet(v, T, iplus(X, Y))], unit),
    assertion(T == int),
    assertion(X == int),
    assertion(Y == int),
    gvar(v, int).

test(infer_gvLet_bad_type, [fail]) :-
    infer([gvLet(v, int, float)], _).

test(infer_gfLet_call, [nondet, true(T == int)]) :-
    infer([
        gfLet(add, [x, y], [int, int], int, exprStmt(iplus(x, y))),
        exprStmt(add(int, int))
    ], T).

test(infer_gfLet_infers_signature, [nondet]) :-
    infer([
        gfLet(add, [x, y], [A, B], R, exprStmt(iplus(x, y)))
    ], unit),
    assertion(A == int),
    assertion(B == int),
    assertion(R == int),
    gvar(add, [int, int, int]).

test(infer_multiple_gfLets, [nondet, true(T == int)]) :-
    infer([
        gfLet(add, [x, y], [int, int], int, exprStmt(iplus(x, y))),
        gfLet(twice, [z], [int], int, exprStmt(add(z, z))),
        exprStmt(twice(int))
    ], T).

test(infer_invalid_gfLet_bad_return, [fail]) :-
    infer([
        gfLet(add_bad, [x, y], [int, int], float, exprStmt(iplus(x, y)))
    ], _).

test(infer_invalid_gfLet_bad_args, [fail]) :-
    infer([
        gfLet(add, [x, y], [int, int], int, exprStmt(iplus(x, y))),
        exprStmt(add(int, float))
    ], _).

test(infer_block, [nondet, true(T == int)]) :-
    infer([block([gvLet(v, int, int), exprStmt(iplus(int, int))])], T),
    gvar(v, int).

test(infer_returnStmt, [nondet, true(T == int)]) :-
    infer([returnStmt(iplus(int, int))], T).

test(infer_letIn_exprStmt, [nondet, true(T == int)]) :-
    infer([exprStmt(letIn(x, int, int, iplus(x, int)))], T).

test(infer_letIn_infers_type, [nondet, true(T == int)]) :-
    infer([exprStmt(letIn(x, XType, int, iplus(x, int)))], T),
    assertion(XType == int).

test(infer_letIn_mismatch, [fail]) :-
    infer([exprStmt(letIn(x, int, float, x))], _).

test(infer_letInStmt, [nondet, true(T == int)]) :-
    infer([letInStmt(x, int, int, exprStmt(iplus(x, int)))], T).

test(infer_ifStmt, [nondet, true(T == int)]) :-
    infer([
        ifStmt(ieq(int, int),
               block([exprStmt(iplus(int, int))]),
               block([exprStmt(imul(int, int))]))
    ], T).

test(infer_invalid_if_branch_mismatch, [fail]) :-
    infer([
        ifStmt(ieq(int, int),
               block([exprStmt(int)]),
               block([exprStmt(float)]))
    ], _).

test(infer_forStmt, [nondet, true(T == unit)]) :-
    infer([
        forStmt(i, int, int, block([exprStmt(print(i))]))
    ], T).

test(infer_invalid_for_body, [fail]) :-
    infer([
        forStmt(i, int, int, exprStmt(i))
    ], _).

test(infer_tuple_exprStmt, [nondet, true(T == tuple([int, float]))]) :-
    infer([exprStmt(tupleExp([int, float]))], T).

test(infer_tuple_invalid_element, [fail]) :-
    infer([exprStmt(tupleExp([bogus]))], _).

test(infer_gvLetTuple_bindings_usable, [nondet, true(T == int)]) :-
    infer([
        gvLetTuple([x, y], tupleExp([int, float])),
        exprStmt(iplus(x, int))
    ], T),
    gvar(x, int),
    gvar(y, float).

test(infer_gvLetTuple_arity_mismatch, [fail]) :-
    infer([
        gvLetTuple([x, y, z], tupleExp([int, float]))
    ], _).

test(infer_sumVal_exprStmt, [nondet, true(T == sum([left-int, right-string]))]) :-
    infer([
        exprStmt(sumVal(left, int, sum([left-int, right-string])))
    ], T).

test(infer_matchStmt, [nondet, true(T == int)]) :-
    infer([
        matchStmt(
            sumVal(right, string, sum([left-int, right-string])),
            [
                case(left, x, exprStmt(iplus(x, int))),
                case(right, y, block([exprStmt(print(y)), exprStmt(int)]))
            ])
    ], T).

test(infer_matchStmt_missing_branch, [fail]) :-
    infer([
        matchStmt(
            sumVal(left, int, sum([left-int, right-string])),
            [
                case(left, x, exprStmt(x))
            ])
    ], _).

test(infer_matchStmt_branch_mismatch, [fail]) :-
    infer([
        matchStmt(
            sumVal(left, int, sum([left-int, right-string])),
            [
                case(left, x, exprStmt(x)),
                case(right, y, exprStmt(y))
            ])
    ], _).

test(infer_failed_run_cleans_globals, [fail]) :-
    infer([gvLet(v, int, int), exprStmt(iplus(int, float))], _).

test(no_leaked_global_after_failed_infer, [nondet]) :-
    \+ gvar(v, _).

:- end_tests(typeInf).
