% Make prolog not abbreviate lists and long results
%set_prolog_flag(toplevel_print_options, [quoted(true), portray(true)]).

% Convert list of givens to steps (internal ND data-structure)
% steps are of the format step(formula, reason as to how this formula was derived, position of this step in the overall proof)
toSteps(Givens, RevSteps) :- toSteps(Givens, Steps, 0), reverse(Steps, RevSteps).
toSteps([], [], _).
toSteps([G|Givens], [step(G, [given], LineNumber)|Steps], LineNumber) :- is(N, LineNumber + 1), toSteps(Givens, Steps, N).

% Append 3 lists and Append shortcut
a2(L1, L2, L) :- append(L1, L2, L).
a3(L1, L2, L3, L) :- append(L1, L2, Lx), append(Lx, L3, L).

% Member of either list and Member shortcut
m2(Item, List) :- member(Item, List).
m3(Item, List1, List2) :- member(Item, List1); member(Item, List2).

% Get next line number from steps
% ln(step, next line number)
ln([step(_, _, LineNumber)|_], NextLineNumber) :- !, is(NextLineNumber, LineNumber + 1).
ln([], 0) :- !.
% ln(current line number, next line number)
ln(LineNumber, NextLineNumber) :- !, integer(LineNumber), is(NextLineNumber, LineNumber + 1).

% Prune unused steps in a proof and "check" steps for a more natural and concise proof
prune([step(X, Y, LineNumber)|Proof], LNPrunedProof) :- 
	pruneSteps([step(X, Y, LineNumber)|Proof], [LineNumber], _, PrunedProof),
	recalculateLineNumbers(PrunedProof, LNPrunedProof), !.
% Prune unused steps in a proof and "check" steps
pruneSteps([], UsedSteps, UsedSteps, []).
pruneSteps([step(X, [Z], Y)|Proof], _, _, [step(X, [Z], Y)|Proof]) :-
	Z = given; Z = hypothesis.
pruneSteps([step(X, [Y, LN1, LN2], LN)|Proof], UsedSteps, SubSteps, [step(X, [Y, NewLN1, NewLN2], LN)|PrunedProof]) :-
	m2(LN, UsedSteps),
	(
		m2(step(_, Reason1, LN1), Proof), 
		(Reason1 = [check, LN3], NewLN1 = LN3; LN1 = NewLN1);
		
		NewLN1 = LN1
	),
	(
		m2(step(_, Reason2, LN2), Proof), 
		(Reason2 = [check, LN4], NewLN2 = LN4; LN2 = NewLN2);
		
		NewLN2 = LN2
	),
	pruneSteps(Proof, [NewLN1, NewLN2|UsedSteps], SubSteps, PrunedProof).
pruneSteps([step(X, [Y, LN1], LN)|Proof], UsedSteps, SubSteps, [step(X, [Y, NewLN1], LN)|PrunedProof]) :-
	m2(LN, UsedSteps), 
	(
		m2(step(_, Reason, LN1), Proof), 
		(Reason = [check, LN3], NewLN1 = LN3; LN1 = NewLN1);
		
		NewLN1 = LN1
	),
	pruneSteps(Proof, [NewLN1|UsedSteps], SubSteps, PrunedProof).
pruneSteps([box(BoxProof)|Proof], UsedSteps, SubSteps, [box(PrunedBoxProof)|PrunedProof]) :-
	m2(step(_, _, LN), BoxProof), m2(LN, UsedSteps),
	pruneSteps(BoxProof, UsedSteps, BoxSteps, PrunedBoxProof),
	pruneSteps(Proof, BoxSteps, SubSteps, PrunedProof).
pruneSteps([_|Proof], UsedSteps, SubSteps, PrunedProof) :- pruneSteps(Proof, UsedSteps, SubSteps, PrunedProof).
% Recalculates line numbers after removing unused steps from the proof
recalculateLineNumbers(PrunedProof, LNPrunedProof) :- 
	reverse(PrunedProof, RevPrunedProof), 
	recalculateLN(RevPrunedProof, 0, _, [], _, RevLNPrunedProof), 
	reverse(RevLNPrunedProof, LNPrunedProof).
recalculateLN([], CurrentLine, CurrentLine, Substitutions, Substitutions, []).
recalculateLN([step(X, Y, LineNumber)|Proof], CurrentLine, NewCurrentLine, Substitutions, NewSubstitutions, [step(X, Z, CurrentLine)|LNProof]) :-
	(
		Y = [Reason2, LN], m2([LN, SubLN], Substitutions), 
		Z = [Reason2, SubLN];
		
		Y = [Reason1, LN1, LN2], 
		m2([LN1, SubLN1], Substitutions), m2([LN2, SubLN2], Substitutions), 
		Z = [Reason1, SubLN1, SubLN2];
		
		Y = Z
	),
	ln(CurrentLine, NextLine),
	recalculateLN(Proof, NextLine, NewCurrentLine, [[LineNumber, CurrentLine]|Substitutions], NewSubstitutions, LNProof).
recalculateLN([box(BoxProof)|Proof], CurrentLine, NewCurrentLine1, Substitutions, NewSubstitutions1, [box(LNBoxProof)|LNProof]) :-
	reverse(BoxProof, RevBoxProof),
	recalculateLN(RevBoxProof, CurrentLine, NewCurrentLine2, Substitutions, NewSubstitutions2, RevLNBoxProof),
	reverse(RevLNBoxProof, LNBoxProof),
	recalculateLN(Proof, NewCurrentLine2, NewCurrentLine1, NewSubstitutions2, NewSubstitutions1, LNProof).

% Pretty print prove
prettyProve(Givens, Goal) :- pprove(Givens, Goal). % alias
pprove(Givens, Goal) :- prove(Givens, Goal, Proof), prune(Proof, PrunedProof), prettyPrint(PrunedProof, '').
prettyPrint([], _) :- !.
prettyPrint([Step|Proof], Indent) :- prettyPrint(Proof, Indent), prettyPrintStep(Step, Indent), !.
prettyPrintStep(step(Formula, Reason, LineNumber), Indent) :- 
	prettyPrintFormula(Formula, PrettyFormula), 
	format('~w~w~20|~w~40|~d~60|~n', [Indent, PrettyFormula, Reason, LineNumber]), !.
prettyPrintStep(box(BoxProof), Indent) :-
	atomic_concat(Indent, '>', NewIndent),
	prettyPrint(BoxProof, NewIndent).
prettyPrintFormula(and(A, B), String) :- prettyPrintFormula(A, PrettyA), prettyPrintFormula(B, PrettyB), swritef(String, '(%w&%w)', [PrettyA, PrettyB]).
prettyPrintFormula(or(A, B), String) :- prettyPrintFormula(A, PrettyA), prettyPrintFormula(B, PrettyB), swritef(String, '(%w|%w)', [PrettyA, PrettyB]).
prettyPrintFormula(n(A), String) :- prettyPrintFormula(A, PrettyA), swritef(String, '~(%w)', [PrettyA]).
prettyPrintFormula(implies(A, B), String) :- prettyPrintFormula(A, PrettyA), prettyPrintFormula(B, PrettyB), swritef(String, '(%w->%w)', [PrettyA, PrettyB]).
prettyPrintFormula(A, A).

% Contruct a proof in Natural Deduction
% prove is of the format prove([givens, ex: and(a,b), c, d], [goal that needs to be proven], Output proof given as variable)
prove(Givens, Goal, Proof) :- is_list(Givens), is_list(Goal), toSteps(Givens, Steps), !, backwardProve(Steps, [], [[], []], Goal, Proof).

% FORWARD PROVE: iterates through all steps and breaks down formulas into smaller, simpler parts
% this process does not take into account the goals or the proof so far
% this process repeats itself until no further progress can be made (ie: until formulas can not be broken down any longer)
forwardProve(Steps, Context, NewSteps) :- 
	length(Steps, S1), 
	andE(Steps, Context, NewSteps1), 
	notE(NewSteps1, Context, NewSteps2), 
	falsityI(NewSteps2, Context, NewSteps3), 
	length(NewSteps3, S2), S2 > S1, 
	forwardProve(NewSteps3, Context, NewSteps).
forwardProve(NewSteps, _, NewSteps).
% Forward Prove Rules: different rules that break down different types of formulas
% all rules are of the form rule(current steps, Expanded steps)
% AND ELIMINATION:
andE(Steps, Context, NewSteps) :- a2(Context, Steps, AllSteps), andEx(Steps, Context, AllSteps, NewSteps).
andEx(OldSteps, _, [], OldSteps).
andEx(OldSteps, Context, [step(and(A, B), _, LineNumber)|Steps], NewSteps) :- 
	andEx(OldSteps, Context, Steps, NS), 
	(
		m3(step(A, _, _), NS, Context), 
		m3(step(B, _, _), NS, Context), 
		LeftRightClause = [], !;
		
		m3(step(A, _, _), NS, Context), 
		ln(NS, NextLineNumber), 
		LeftRightClause = [step(B, [andE, LineNumber], NextLineNumber)], !;
		
		m3(step(B, _, _), NS, Context), 
		ln(NS, NextLineNumber), 
		LeftRightClause = [step(A, [andE, LineNumber], NextLineNumber)], !;
		
		ln(NS, NextLineNumber), ln(NextLineNumber, NextNextLineNumber), 
		LeftRightClause = [step(A, [andE, LineNumber], NextNextLineNumber), 
		step(B, [andE, LineNumber], NextLineNumber)], !
	),
	a2(LeftRightClause, NS, NewSteps).
andEx(OldSteps, Context, [_|Steps], NewSteps) :- andEx(OldSteps, Context, Steps, NewSteps).
% NOT ELIMINATION:
notE(Steps, Context, NewSteps) :- a2(Context, Steps, AllSteps), notEx(Steps, Context, AllSteps, NewSteps).
notEx(OldSteps, _, [], OldSteps).
notEx(OldSteps, Context, [step(n(n(A)), _, LineNumber)|Steps], NewSteps) :-
	notEx(OldSteps, Context, Steps, NS),
	(
		m3(step(A, _, _), NS, Context), ExtraSteps = [], !;
		
		ln(NS, NextLineNumber), ExtraSteps = [step(A, [notE, LineNumber], NextLineNumber)], !
	),
	a2(ExtraSteps, NS, NewSteps).
notEx(OldSteps, Context, [_|Steps], NewSteps) :- notEx(OldSteps, Context, Steps, NewSteps).
% FALSITY INTRODUCTION:
falsityI(Steps, Context, NewSteps) :- a2(Context, Steps, AllSteps), falsityIx(Steps, Context, AllSteps, NewSteps).
falsityIx(OldSteps, _, [], OldSteps).
falsityIx(OldSteps, _, _, OldSteps) :- m2(step(falsity, _, _), OldSteps), !.
falsityIx(OldSteps, Context, [step(A, _, LineNumber1)|_], [step(falsity, [falsityI, LineNumber1, LineNumber2], NextLineNumber)|OldSteps]) :- 
	m3(step(n(A), _, LineNumber2), OldSteps, Context), ln(OldSteps, NextLineNumber).
falsityIx(OldSteps, Context, [_|Steps], NewSteps) :- falsityIx(OldSteps, Context, Steps, NewSteps).

% BACKWARD PROVE: tries to match the current steps to goals, or simplify goals and try matching again
% whenever no further progress can be made, a call to forwardProve is made in order to break down steps into simpler formulas that might be of use
% BASE CASE: no more goals to prove means we've completed the proof
backwardProve(Steps, _, _, [], Steps) :- !.
backwardProve(Steps, Context, Extras, Goals, Proof) :- 
	check(Steps, Context, Extras, Goals, Proof);
	andI(Steps, Context, Extras, Goals, Proof);
	falsityE(Steps, Context, Extras, Goals, Proof);
	impliesI(Steps, Context, Extras, Goals, Proof);
	notI(Steps, Context, Extras, Goals, Proof);
	forward(Steps, Context, Extras, Goals, Proof);
	falsityIE(Steps, Context, Extras, Goals, Proof);
	impliesE(Steps, Context, Extras, Goals, Proof);
	proofByContradiction(Steps, Context, Extras, Goals, Proof).

% CHECK: if the goal appears as a step (ie: if the goal has been derived) check it and try to prove the rest of the goals
check(Steps, Context, Extras, [G|Goals], [step(G, [check, LineNumber], NextLineNumber)|Proof]) :- 
	m3(step(G, _, LineNumber), Steps, Context), 
	backwardProve(Steps, Context, Extras, Goals, Proof), ln(Proof, NextLineNumber).
% AND INTRODUCTION: prove and(a,b) by proving a and b separately
andI(Steps, Context, Extras, [and(A, B)|Goals], [step(and(A, B), [andI, LineNumber1, LineNumber2], NextLineNumber)|Proof]) :- 
	m3(step(A, _, LineNumber1), Steps, Context), 
	m3(step(B, _, LineNumber2), Steps, Context), 
	!, backwardProve(Steps, Context, Extras, Goals, Proof), ln(Proof, NextLineNumber).
andI(Steps, Context, Extras, [and(A, B)|Goals], [step(and(A, B), [andI, LineNumber1, LineNumber2], NextLineNumber)|Proof]) :- 
	m3(step(A, _, LineNumber1), Steps, Context), !, 
	backwardProve(Steps, Context, Extras, [B|Goals], Proof),  m2(step(B, _, LineNumber2), Proof), ln(Proof, NextLineNumber).
andI(Steps, Context, Extras, [and(A, B)|Goals], [step(and(A, B), [andI, LineNumber1, LineNumber2], NextLineNumber)|Proof]) :- 
	m3(step(B, _, LineNumber2), Steps, Context), !,
	backwardProve(Steps, Context, Extras, [A|Goals], Proof), m2(step(A, _, LineNumber1), Proof), 
	ln(Proof, NextLineNumber).
andI(Steps, Context, Extras, [and(A, B)|Goals], [step(and(A, B), [andI, LineNumber1, LineNumber2], NextLineNumber)|Proof]) :- 
	backwardProve(Steps, Context, Extras, [A, B|Goals], Proof), 
	m2(step(A, _, LineNumber1), Proof), m2(step(B, _, LineNumber2), Proof), 
	ln(Proof, NextLineNumber).
% FALSITY ELIMINATION: if contradiction has been established, vacuously prove current goal
falsityE(Steps, Context, Extras, [G|Goals], [step(G, [falsityE, LineNumber], NextLineNumber)|Proof]) :-
	not(G = falsity),
	m3(step(falsity, _, LineNumber), Steps, Context), 
	backwardProve(Steps, Context, Extras, Goals, Proof), ln(Proof, NextLineNumber).
% IMPLIES INTRODUCTION: prove implies(a, b) by starting a nested proof and assuming a, and trying to prove b
impliesI(Steps, Context, Extras, [implies(A, B)|Goals], [step(implies(A, B), [impliesI, LineNumber1, LineNumber2], NextLineNumber), box(BoxProof)|Proof]) :-
	backwardProve(Steps, Context, Extras, Goals, Proof), 
	ln(Proof, LineNumber1), a2(Context, Steps, NewContext), 
	backwardProve([step(A, [hypothesis], LineNumber1)], NewContext, Extras, [B], BoxProof), 
	ln(BoxProof, NextLineNumber), is(LineNumber2, NextLineNumber-1).
% NOT INTRODUCTION: prove ¬a by starting a nested proof and assuming a, and trying to prove contradiction
notI(Steps, Context, Extras, [n(A)|Goals], [step(n(A), [notI, LineNumber1, LineNumber2], NextLineNumber), box(BoxProof)|Proof]) :-
	backwardProve(Steps, Context, Extras, Goals, Proof), 
	ln(Proof, LineNumber1), a2(Steps, Context, NewContext), 
	backwardProve([step(A, [hypothesis], LineNumber1)], NewContext, Extras, [falsity], BoxProof), 
	ln(BoxProof, NextLineNumber), is(LineNumber2, NextLineNumber - 1).
% FORWARD PROVE: if no further progress can be done backwards, try to break down derived formulas again
forward(Steps, Context, Extras, Goals, Proof) :- 
	length(Steps, S1), 
	forwardProve(Steps, Context, NewSteps), 
	length(NewSteps, S2), S2 > S1, !,
	backwardProve(NewSteps, Context, Extras, Goals, Proof).
% FALSITY INTRODUCTION-ELIMINATION: for each derived step of the form ¬a, prove a, then falsity then the goal
falsityIE(Steps, Context, Extras, [G|Goals], [step(G, [falsityE, LineNumber], NextLineNumber), step(falsity, [falsityI, LN1, LN2], LineNumber)| Proof]) :-
	not(m3(step(falsity, _, _), Steps, Context)),
	nth0(0, Extras, PastTries, RestExtras),
	bagof(A, m3(step(n(A), _, LN1), Steps, Context), [X]),
	not(m2(X, PastTries)),
	nth0(0, NewExtras, [X|PastTries], RestExtras),
	backwardProve(Steps, Context, NewExtras, Goals, RestProof), !,
	backwardProve(RestProof, Context, NewExtras, [X], Proof),
	ln(Proof, LineNumber),
	ln(LineNumber, NextLineNumber),
	is(LN2, LineNumber - 1).
% IMPLIES ELIMINATION: for each derived step of the form implies(a,b), prove a, derive b, then prove goal from/using b
impliesE(Steps, Context, Extras, Goals, Proof) :-
	nth0(1, Extras, PastTries, RestExtras),
	bagof(implies(A, B), m3(step(implies(A, B), _, LN1), Steps, Context), [implies(X, Y)]),
	not(m2(implies(X, Y), PastTries)),
	nth0(1, NewExtras, [implies(X, Y)|PastTries], RestExtras),
	backwardProve(Steps, Context, NewExtras, [X], SubProof),
	ln(SubProof, NextLine), is(LN2, NextLine - 1), !,
	backwardProve([step(Y, [impliesE, LN1, LN2], NextLine)|SubProof], Context, NewExtras, Goals, Proof).
% PROOF BY CONTRADICTION: prove a by starting a nested proof and assuming ¬a, and trying to prove contradiction
proofByContradiction(Steps, Context, Extras, [G|Goals], [step(G, [notE, NextLineNumber], NextNextLineNumber), step(n(n(G)), [notI, LineNumber1, LineNumber2], NextLineNumber), box(BoxProof)|Proof]) :-
	not(G = falsity),
	backwardProve(Steps, Context, Extras, Goals, Proof),
	ln(Proof, LineNumber1), a2(Steps, Context, NewContext), !,
	backwardProve([step(n(G), [hypothesis], LineNumber1)], NewContext, Extras, [falsity], BoxProof),
	ln(BoxProof, NextLineNumber), is(LineNumber2, NextLineNumber - 1),
	ln(NextLineNumber, NextNextLineNumber).