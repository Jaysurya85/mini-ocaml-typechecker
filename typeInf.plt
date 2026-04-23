:- begin_tests(typeInf).
:- include(typeInf). 


test(infer_exprStmt, [nondet, true(T == int)]) :-
    infer([exprStmt(iplus(int, int))], T).

test(infer_invalid_expr_mismatch, [fail]) :-
    infer([exprStmt(iplus(int, float))], _).

test(infer_gvar, [nondet]) :-
    infer([gvLet(v, T, iplus(X, Y))], unit),
    assertion(T==int), assertion(X==int), assertion(Y=int),
    gvar(v,int).

test(infer_gvLet_bad_type, [fail]) :-
    infer([gvLet(v, int, float)], _).

test(infer_gfLet_call, [nondet, true(T == int)]) :-
    infer([
        gfLet(add, [x, y], [int, int], int, exprStmt(iplus(x, y))),
        exprStmt(add(int, int))
    ], T).

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

test(infer_nested_block, [nondet, true(T == float)]) :-
    infer([block([exprStmt(print(string)), block([exprStmt(iToFloat(int))])])], T).

test(infer_letIn_exprStmt, [nondet, true(T == int)]) :-
    infer([exprStmt(letIn(x, int, int, iplus(x, int)))], T).

test(letIn_inside_gfLet_body, [nondet, true(T == int)]) :-
    infer([
        gfLet(add1, [y], [int], int, exprStmt(letIn(x, int, y, iplus(x, int)))),
        exprStmt(add1(int))
    ], T).

test(infer_letIn_mismatch, [fail]) :-
    infer([exprStmt(letIn(x, int, float, x))], _).

test(infer_ifStmt, [nondet, true(T == int)]) :-
    infer([
        ifStmt(ieq(int, int),
               block([exprStmt(iplus(int, int))]),
               block([exprStmt(imul(int, int))]))
    ], T).

test(infer_ifStmt_with_letIn_branches, [nondet, true(T == int)]) :-
    infer([
        ifStmt(ieq(int, int),
               block([exprStmt(letIn(x, int, int, iplus(x, int)))]),
               block([exprStmt(letIn(y, int, int, iminus(y, int)))]))
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

test(infer_forStmt_after_global_let, [nondet, true(T == unit)]) :-
    infer([
        gvLet(limit, int, int),
        forStmt(i, int, int, block([exprStmt(print(i))]))
    ], T),
    gvar(limit, int).

test(infer_invalid_for_body, [fail]) :-
    infer([
        forStmt(i, int, int, exprStmt(i))
    ], _).

test(infer_tuple_exprStmt, [nondet, true(T == tuple([int, float]))]) :-
    infer([exprStmt(tupleExp([int, float]))], T).

test(infer_tuple_nested, [nondet, true(T == tuple([tuple([int, float]), string]))]) :-
    infer([
        exprStmt(tupleExp([tupleExp([int, float]), string]))
    ], T).

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

test(infer_gvLetTuple_nested_tuple, [nondet, true(T == tuple([int, float]))]) :-
    infer([
        gvLetTuple([pair, label], tupleExp([tupleExp([int, float]), string])),
        exprStmt(pair)
    ], T),
    gvar(pair, tuple([int, float])),
    gvar(label, string).

test(infer_sumVal_exprStmt, [nondet, true(T == sum([left-int, right-string]))]) :-
    infer([
        exprStmt(sumVal(left, int, sum([left-int, right-string])))
    ], T).

test(infer_sumVal_bad_payload, [fail]) :-
    infer([
        exprStmt(sumVal(left, string, sum([left-int, right-string])))
    ], _).

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

:-end_tests(typeInf).
