:- dynamic gvar/2.

/* Local let-in expression with scoped binding. */
typeExp(letIn(Name, VarType, ValueExpr, InExpr), T):-
    atom(Name),
    bType(VarType),
    typeExp(ValueExpr, VarType),
    setup_call_cleanup(
        asserta(gvar(Name, VarType), Ref),
        once(typeExp(InExpr, T)),
        erase(Ref)
    ).

/* Tuple expression. */
typeExp(tupleExp(Exprs), tuple(Types)):-
    is_list(Exprs),
    typeExpTuple(Exprs, Types).

/* Sum value expression. */
typeExp(sumVal(Tag, Expr, sum(Variants)), sum(Variants)):-
    atom(Tag),
    bType(sum(Variants)),
    member(Tag-Type, Variants),
    typeExp(Expr, Type).

typeExp(Fct, T):-
    \+ var(Fct),
    \+ atom(Fct),
    functor(Fct, Fname, _Nargs),
    !,
    Fct =.. [Fname|Args],
    append(Args, [T], FType),
    functionType(Fname, TArgs),
    typeExpList(FType, TArgs).

/* Resolve named variables from the environment. */
typeExp(Name, T):-
    atom(Name),
    gvar(Name, T),
    \+ is_list(T).

/* Already-known type. */
typeExp(T, T).

/* Match expression lists against expected types. */
typeExpList([], []).
typeExpList([Hin|Tin], [Hout|Tout]):-
    typeExp(Hin, Hout),
    typeExpList(Tin, Tout).

typeExpTuple([], []).
typeExpTuple([Expr|Exprs], [Type|Types]):-
    typeExp(Expr, Type),
    bType(Type),
    typeExpTuple(Exprs, Types).

/* Global variable definition. */
typeStatement(gvLet(Name, T, Code), unit):-
    atom(Name),
    typeExp(Code, T),
    bType(T),
    asserta(gvar(Name, T)).

/* Tuple unpacking for globals. */
typeStatement(gvLetTuple(Names, TupleExpr), unit):-
    is_list(Names),
    typeExp(TupleExpr, tuple(Types)),
    same_length(Names, Types),
    assertGlobalBindings(Names, Types).

/* Global function definition with scoped arguments. */
typeStatement(gfLet(Name, ArgNames, ArgTypes, ReturnType, Body), unit):-
    atom(Name),
    is_list(ArgNames),
    is_list(ArgTypes),
    same_length(ArgNames, ArgTypes),
    append(ArgTypes, [ReturnType], FType),
    bType(FType),
    assertz(gvar(Name, FType), FRef),
    (
        setup_call_cleanup(
            assertArgBindings(ArgNames, ArgTypes, ArgRefs),
            once(typeStatement(Body, ReturnType)),
            deleteBindings(ArgRefs)
        )
    ->
        true
    ;
        erase(FRef),
        fail
    ).

/* Expression statement. */
typeStatement(exprStmt(Expr), T):-
    typeExp(Expr, T),
    bType(T).

/* Block statement. */
typeStatement(block(Code), T):-
    is_list(Code),
    typeCode(Code, T).

/* If statement. */
typeStatement(ifStmt(Cond, ThenBlock, ElseBlock), T):-
    typeExp(Cond, int),
    typeStatement(ThenBlock, T),
    typeStatement(ElseBlock, T),
    bType(T).

/* For loop with scoped loop variable. */
typeStatement(forStmt(VarName, StartExpr, EndExpr, Body), unit):-
    atom(VarName),
    typeExp(StartExpr, int),
    typeExp(EndExpr, int),
    setup_call_cleanup(
        asserta(gvar(VarName, int), Ref),
        once(typeStatement(Body, unit)),
        erase(Ref)
    ).

/* Match must cover each sum variant. */
typeStatement(matchStmt(Expr, Cases), T):-
    typeExp(Expr, sum(Variants)),
    is_list(Cases),
    matchCases(Cases, Variants, T),
    bType(T).

/* A block has the type of its last statement. */
typeCode([S], T):-typeStatement(S, T).
typeCode([S, S2|Code], T):-
    typeStatement(S,_T),
    typeCode([S2|Code], T).

/* Top-level inference entry point. */
infer(Code, T) :-
    is_list(Code),
    deleteGVars(),
    typeCode(Code, T).

/* Basic types. */
bType(int).
bType(float).
bType(string).
bType(unit).
bType(tuple(Types)):- is_list(Types), bType(Types).
bType(sum(Variants)):- is_list(Variants), bTypeSumVariants(Variants).

/* Function types keep the return type last. */
bType([H]):- bType(H).
bType([H|T]):- bType(H), bType(T).

bTypeSumVariants([]).
bTypeSumVariants([Tag-Type|Variants]):-
    atom(Tag),
    bType(Type),
    bTypeSumVariants(Variants).

deleteGVars() :- retractall(gvar(_, _)).

assertArgBindings([], [], []).
assertArgBindings([Name|Names], [Type|Types], [Ref|Refs]):-
    atom(Name),
    bType(Type),
    asserta(gvar(Name, Type), Ref),
    assertArgBindings(Names, Types, Refs).

deleteBindings([]).
deleteBindings([Ref|Refs]):-
    erase(Ref),
    deleteBindings(Refs).

assertGlobalBindings([], []).
assertGlobalBindings([Name|Names], [Type|Types]):-
    atom(Name),
    bType(Type),
    asserta(gvar(Name, Type)),
    assertGlobalBindings(Names, Types).

/* Match cases add the case variable only inside that branch. */
matchCases([], [], _).
matchCases([case(Tag, VarName, ThenStmt)|Cases], Variants, T):-
    atom(Tag),
    atom(VarName),
    select(Tag-VarType, Variants, RemainingVariants),
    setup_call_cleanup(
        asserta(gvar(VarName, VarType), Ref),
        once(typeStatement(ThenStmt, T)),
        erase(Ref)
    ),
    matchCases(Cases, RemainingVariants, T).

/* Built-in function types. */

fType(iplus, [int,int,int]).
fType(iminus, [int,int,int]).
fType(imul, [int,int,int]).
fType(idiv, [int,int,int]).
fType(fplus, [float, float, float]).
fType(fminus, [float,float,float]).
fType(fmul, [float,float,float]).
fType(fdiv, [float,float,float]).
fType(fToInt, [float,int]).
fType(iToFloat, [int,float]).
fType(ieq, [int,int,int]).
fType(feq, [float,float,int]).
fType(streq, [string,string,int]).
fType(print, [_X, unit]).

/* Find user-defined or built-in function signatures. */

functionType(Name, Args):-
    gvar(Name, Args),
    is_list(Args).

functionType(Name, Args) :-
    fType(Name, Args), !.

gvar(_, _) :- false().
