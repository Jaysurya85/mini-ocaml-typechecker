:- dynamic gvar/2.

/* public expression predicate */
typeExp(Expr, Type):-
    typeExp(Expr, Type, []).

/* local let-in expression */
typeExp(letIn(Name, VarType, ValueExpr, InExpr), T, Env):-
    atom(Name),
    bType(VarType),
    typeExp(ValueExpr, VarType, Env),
    typeExp(InExpr, T, [Name-VarType|Env]).

/* tuple expression */
typeExp(tupleExp(Exprs), tuple(Types), Env):-
    is_list(Exprs),
    typeExpTuple(Exprs, Types, Env),
    bType(tuple(Types)).

/* sum value expression */
typeExp(sumVal(Tag, Expr, sum(Variants)), sum(Variants), Env):-
    atom(Tag),
    bType(sum(Variants)),
    member(Tag-Type, Variants),
    typeExp(Expr, Type, Env).

/* function call */
typeExp(Fct, T, Env):-
    nonvar(Fct),
    compound(Fct),
    Fct =.. [Fname|Args],
    functionType(Fname, TArgs),
    !,
    append(Args, [T], FType),
    typeExpList(FType, TArgs, Env).

/* local variable lookup */
typeExp(Name, T, Env):-
    atom(Name),
    lookupEnv(Name, T, Env),
    !.

/* global variable lookup */
typeExp(Name, T, _Env):-
    atom(Name),
    gvar(Name, T),
    \+ is_list(T).

/* propagate already known types and type variables */
typeExp(T, T, _Env):-
    bType(T).

/* list version for function arguments */
typeExpList([], [], _Env).
typeExpList([Hin|Tin], [Hout|Tout], Env):-
    typeExp(Hin, Hout, Env),
    typeExpList(Tin, Tout, Env).

typeExpTuple([], [], _Env).
typeExpTuple([Expr|Exprs], [Type|Types], Env):-
    typeExp(Expr, Type, Env),
    bType(Type),
    typeExpTuple(Exprs, Types, Env).

lookupEnv(Name, Type, [Name-Type|_Rest]).
lookupEnv(Name, Type, [_Other|Rest]):-
    lookupEnv(Name, Type, Rest).

/* public statement predicate */
typeStatement(Stmt, Type):-
    typeStatement(Stmt, Type, []).

/* global variable definition */
typeStatement(gvLet(Name, T, Code), unit, Env):-
    atom(Name),
    typeExp(Code, T, Env),
    bType(T),
    asserta(gvar(Name, T)).

/* global tuple unpacking */
typeStatement(gvLetTuple(Names, TupleExpr), unit, Env):-
    is_list(Names),
    typeExp(TupleExpr, tuple(Types), Env),
    same_length(Names, Types),
    validNames(Names),
    validTypes(Types),
    assertGlobalBindings(Names, Types).

/* global function definition */
typeStatement(gfLet(Name, ArgNames, ArgTypes, ReturnType, Body), unit, Env):-
    atom(Name),
    is_list(ArgNames),
    is_list(ArgTypes),
    same_length(ArgNames, ArgTypes),
    validNames(ArgNames),
    append(ArgTypes, [ReturnType], FType),
    bType(FType),
    bindArgs(ArgNames, ArgTypes, Env, BodyEnv),
    typeStatement(Body, ReturnType, BodyEnv),
    bType(ReturnType),
    assertz(gvar(Name, FType)).

/* expression statement */
typeStatement(exprStmt(Expr), T, Env):-
    typeExp(Expr, T, Env),
    bType(T).

/* optional explicit return statement */
typeStatement(returnStmt(Expr), T, Env):-
    typeExp(Expr, T, Env),
    bType(T).

/* code block */
typeStatement(block(Code), T, Env):-
    is_list(Code),
    typeCode(Code, T, Env).

/* if statement: conditions are represented as int in this small language */
typeStatement(ifStmt(Cond, ThenBlock, ElseBlock), T, Env):-
    typeExp(Cond, int, Env),
    typeStatement(ThenBlock, T, Env),
    typeStatement(ElseBlock, T, Env),
    bType(T).

/* for loop */
typeStatement(forStmt(VarName, StartExpr, EndExpr, Body), unit, Env):-
    atom(VarName),
    typeExp(StartExpr, int, Env),
    typeExp(EndExpr, int, Env),
    typeStatement(Body, unit, [VarName-int|Env]).

/* local let-in statement */
typeStatement(letInStmt(Name, VarType, ValueExpr, Body), T, Env):-
    atom(Name),
    bType(VarType),
    typeExp(ValueExpr, VarType, Env),
    typeStatement(Body, T, [Name-VarType|Env]).

/* same as letInStmt, but with the lvLetIn name */
typeStatement(lvLetIn(Name, VarType, ValueExpr, Body), T, Env):-
    typeStatement(letInStmt(Name, VarType, ValueExpr, Body), T, Env).

/* match over sum types */
typeStatement(matchStmt(Expr, Cases), T, Env):-
    typeExp(Expr, sum(Variants), Env),
    is_list(Cases),
    matchCases(Cases, Variants, T, Env),
    bType(T).

/* code has the type of its last statement */
typeCode([S], T):-
    typeCode([S], T, []).
typeCode([S, S2|Code], T):-
    typeCode([S, S2|Code], T, []).

typeCode([S], T, Env):-
    typeStatement(S, T, Env).
typeCode([S, S2|Code], T, Env):-
    typeStatement(S, _T, Env),
    typeCode([S2|Code], T, Env).

/* top level predicate */
infer(Code, T):-
    is_list(Code),
    deleteGVars(),
    (
        once(typeCode(Code, T))
    ->
        true
    ;
        deleteGVars(),
        fail
    ).

/* basic types and type variables */
bType(T):- var(T), !.
bType(int).
bType(float).
bType(string).
bType(unit).
bType(tuple(Types)):-
    is_list(Types),
    bType(Types).
bType(sum(Variants)):-
    is_list(Variants),
    bTypeSumVariants(Variants).

/* function types are lists, with the return type last */
bType([H]):-
    bType(H).
bType([H|T]):-
    bType(H),
    bType(T).

bTypeSumVariants([]).
bTypeSumVariants([Tag-Type|Variants]):-
    atom(Tag),
    bType(Type),
    bTypeSumVariants(Variants).

/* cleanup */
deleteGVars():-
    retractall(gvar(_, _)).

validNames([]).
validNames([Name|Names]):-
    atom(Name),
    validNames(Names).

validTypes([]).
validTypes([Type|Types]):-
    bType(Type),
    validTypes(Types).

bindArgs([], [], Env, Env).
bindArgs([Name|Names], [Type|Types], Env, OutEnv):-
    bindArgs(Names, Types, [Name-Type|Env], OutEnv).

assertGlobalBindings([], []).
assertGlobalBindings([Name|Names], [Type|Types]):-
    asserta(gvar(Name, Type)),
    assertGlobalBindings(Names, Types).

matchCases([], [], _T, _Env).
matchCases([case(Tag, VarName, ThenStmt)|Cases], Variants, T, Env):-
    atom(Tag),
    atom(VarName),
    select(Tag-VarType, Variants, RemainingVariants),
    typeStatement(ThenStmt, T, [VarName-VarType|Env]),
    matchCases(Cases, RemainingVariants, T, Env).

/* builtin functions */
fType(iplus, [int,int,int]).
fType(iminus, [int,int,int]).
fType(imul, [int,int,int]).
fType(idiv, [int,int,int]).

fType(fplus, [float,float,float]).
fType(fminus, [float,float,float]).
fType(fmul, [float,float,float]).
fType(fdiv, [float,float,float]).

fType(fToInt, [float,int]).
fType(iToFloat, [int,float]).

fType(ieq, [int,int,int]).
fType(feq, [float,float,int]).
fType(streq, [string,string,int]).

fType(print, [_X, unit]).
fType(println, [_X, unit]).

/* starter-style aliases */
fType('+', [int,int,int]).
fType('+.', [float,float,float]).
fType(itimes, [int,int,int]).
fType(idivide, [int,int,int]).
fType(ftimes, [float,float,float]).
fType(fdivide, [float,float,float]).
fType('=', [int,int,int]).
fType('==', [float,float,int]).
fType('<', [float,float,int]).

/* user-defined functions first, then builtins */
functionType(Name, Args):-
    gvar(Name, Args),
    is_list(Args).

functionType(Name, Args):-
    fType(Name, Args),
    !.
