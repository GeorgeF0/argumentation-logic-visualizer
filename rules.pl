% Make prolog not abbreviate lists and long results
%set_prolog_flag(toplevel_print_options, [quoted(true), portray(true)]).

% Convert list of givens to steps (internal ND data-structure)
% steps are of the format step(formula, reason as to how this formula was derived, position of this step in the overall proof)
toSteps(Givens, RevSteps) :- toSteps(Givens, Steps, 0), reverse(Steps, RevSteps).
toSteps([], [], _).
toSteps([G|Givens], [step(G, given, LineNumber)|Steps], LineNumber) :- is(N, LineNumber + 1), toSteps(Givens, Steps, N).

% Append 3 lists and Append shortcut
a2(L1, L2, L) :- append(L1, L2, L).
a3(L1, L2, L3, L) :- append(L1, L2, Lx), append(Lx, L3, L).

% Member of either list and Member shortcut
m2(Item, List) :- member(Item, List).
m3(Item, List1, List2) :- member(Item, List1); member(Item, List2).

% Get next line number from steps
% ln(step, next line number)
ln([step(_, _, LineNumber)|_], NextLineNumber) :- is(NextLineNumber, LineNumber + 1).
% ln(current line number, next line number)
ln(LineNumber, NextLineNumber) :- integer(LineNumber), is(NextLineNumber, LineNumber + 1).

% Pretty print prove
prettyProve(Givens, Goal) :- pprove(Givens, Goal).
pprove(Givens, Goal) :- prove(Givens, Goal, Proof), prettyPrint(Proof).
prettyPrint([]).
prettyPrint([Step|Proof]) :- prettyPrint(Proof), prettyPrintStep(Step).
prettyPrintStep(step(Formula, Reason, LineNumber)) :- prettyPrintFormula(Formula, PrettyFormula), format('~w~20|~w~40|~d~60|~n', [PrettyFormula, Reason, LineNumber]).
prettyPrintFormula(and(A, B), String) :- prettyPrintFormula(A, PrettyA), prettyPrintFormula(B, PrettyB), swritef(String, '(%w&%w)', [PrettyA, PrettyB]).
prettyPrintFormula(or(A, B), String) :- prettyPrintFormula(A, PrettyA), prettyPrintFormula(B, PrettyB), swritef(String, '(%w|%w)', [PrettyA, PrettyB]).
prettyPrintFormula(n(A), String) :- prettyPrintFormula(A, PrettyA), swritef(String, '~(%w)', [PrettyA]).
prettyPrintFormula(implies(A, B), String) :- prettyPrintFormula(A, PrettyA), prettyPrintFormula(B, PrettyB), swritef(String, '(%w->%w)', [PrettyA, PrettyB]).
prettyPrintFormula(A, A).

% Contruct a proof in Natural Deduction
% prove is of the format prove([givens, ex: and(a,b), c, d], [goal that needs to be proven], Output proof given as variable)
prove(Givens, Goal, Proof) :- is_list(Givens), is_list(Goal), toSteps(Givens, Steps), !, backwardProve(Steps, [], Goal, Proof).

% Forward Prove: iterates through all steps and breaks down formulas into smaller, simpler parts
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
% And Elimination:
andE(Steps, Context, NewSteps) :- a2(Context, Steps, AllSteps), andEx(Steps, Context, AllSteps, NewSteps).
andEx(OldSteps, _, [], OldSteps).
andEx(OldSteps, Context, [step(and(A, B), _, LineNumber)|Steps], NewSteps) :- 
	andEx(OldSteps, Context, Steps, NS), 
	(
		(member(step(A, _, _), NS); member(step(A, _, _), Context)), 
		(member(step(B, _, _), NS); member(step(B, _, _), Context)), 
		LeftRightClause = [], !;
		
		(member(step(A, _, _), NS); member(step(A, _, _), Context)), 
		ln(NS, NextLineNumber), 
		LeftRightClause = [step(B, [andE, LineNumber], NextLineNumber)], !;
		
		(member(step(B, _, _), NS); member(step(B, _, _), Context)), 
		ln(NS, NextLineNumber), 
		LeftRightClause = [step(A, [andE, LineNumber], NextLineNumber)], !;
		
		ln(NS, NextLineNumber), ln(NextLineNumber, NextNextLineNumber), 
		LeftRightClause = [step(A, [andE, LineNumber], NextNextLineNumber), 
		step(B, [andE, LineNumber], NextLineNumber)], !
	),
	a2(LeftRightClause, NS, NewSteps).
andEx(OldSteps, Context, [_|Steps], NewSteps) :- andEx(OldSteps, Context, Steps, NewSteps).
% Not Elimination:
notE(Steps, Context, NewSteps) :- a2(Context, Steps, AllSteps), notEx(Steps, Context, AllSteps, NewSteps).
notEx(OldSteps, _, [], OldSteps).
notEx(OldSteps, Context, [step(n(n(A)), _, LineNumber)|Steps], NewSteps) :-
	notEx(OldSteps, Context, Steps, NS),
	(
		(member(step(A, _, _), NS); member(step(A, _, _), Context)), ExtraSteps = [], !;
		
		ln(NS, NextLineNumber), ExtraSteps = [step(A, [notE, LineNumber], NextLineNumber)], !
	),
	a2(ExtraSteps, NS, NewSteps).
notEx(OldSteps, Context, [_|Steps], NewSteps) :- notEx(OldSteps, Context, Steps, NewSteps).
% Falsity Introduction:
falsityI(Steps, Context, NewSteps) :- a2(Context, Steps, AllSteps), falsityIx(Steps, Context, AllSteps, NewSteps).
falsityIx(OldSteps, _, [], OldSteps).
falsityIx(OldSteps, _, _, OldSteps) :- member(step(falsity, _, _), OldSteps), !.
falsityIx(OldSteps, Context, [step(A, _, LineNumber1)|_], [step(falsity, [falsityI, LineNumber1, LineNumber2], NextLineNumber)|OldSteps]) :- 
	(member(step(n(A), _, LineNumber2), OldSteps); member(step(n(A), _, LineNumber2), Context)), ln(OldSteps, NextLineNumber).
falsityIx(OldSteps, Context, [_|Steps], NewSteps) :- falsityIx(OldSteps, Context, Steps, NewSteps).

% BackwardProve: tries to match the current steps to goals, or simplify goals and try matching again
% whenever no further progress can be made, a call to forwardProve is made in order to break down steps into simpler formulas that might be of use
% Base case: no more goals to prove means we've completed the proof
backwardProve(Steps, _, [], Steps).
% Check: if the goal appears as a step (ie: if the goal has been derived) check it and try to prove the rest of the goals
backwardProve(Steps, Context, [G|Goals], [step(G, [check, LineNumber], NextLineNumber)|Proof]) :- 
	(member(step(G, _, LineNumber), Steps); member(step(G, _, LineNumber), Context)), 
	backwardProve(Steps, Context, Goals, Proof), ln(Proof, NextLineNumber).
% And Introduction: prove and(a,b) by proving a and b separately
backwardProve(Steps, Context, [and(A, B)|Goals], [step(and(A, B), [andI, LineNumber1, LineNumber2], NextLineNumber)|Proof]) :- 
	(member(step(A, _, LineNumber1), Steps); member(step(A, _, LineNumber1), Context)), 
	(member(step(B, _, LineNumber2), Steps); member(step(B, _, LineNumber2), Context)), 
	backwardProve(Steps, Context, Goals, Proof), ln(Proof, NextLineNumber).
backwardProve(Steps, Context, [and(A, B)|Goals], [step(and(A, B), [andI, LineNumber1, LineNumber2], NextLineNumber)|Proof]) :- 
	(member(step(A, _, LineNumber1), Steps); member(step(A, _, LineNumber1), Context)), 
	backwardProve(Steps, Context, [B|Goals], Proof),  member(step(B, _, LineNumber2), Proof), ln(Proof, NextLineNumber).
backwardProve(Steps, Context, [and(A, B)|Goals], [step(and(A, B), [andI, LineNumber1, LineNumber2], NextLineNumber)|Proof]) :- 
	(member(step(B, _, LineNumber2), Steps); member(step(B, _, LineNumber2), Context)), 
	backwardProve(Steps, Context, [A|Goals], Proof), member(step(A, _, LineNumber1), Proof), 
	ln(Proof, NextLineNumber).
backwardProve(Steps, Context, [and(A, B)|Goals], [step(and(A, B), [andI, LineNumber1, LineNumber2], NextLineNumber)|Proof]) :- 
	backwardProve(Steps, Context, [A, B|Goals], Proof), 
	member(step(A, _, LineNumber1), Proof), member(step(B, _, LineNumber2), Proof), 
	ln(Proof, NextLineNumber).
% Falsity Elimination: if contradiction has been established, vacuously prove current goal
backwardProve(Steps, Context, [G|Goals], [step(G, [falsityE, LineNumber], NextLineNumber)|Proof]) :- 
	(member(step(falsity, _, LineNumber), Steps); member(step(falsity, _, LineNumber), Context)), 
	backwardProve(Steps, Context, Goals, Proof), ln(Proof, NextLineNumber).
% Implies Introduction: prove implies(a, b) by starting a nested proof and assuming a, and trying to prove b
backwardProve(Steps, Context, [implies(A, B)|Goals], [box(BoxProof), step(implies(A, B), [impliesI, LineNumber1, LineNumber2], NextLineNumber)|Proof]) :-
	backwardProve(Steps, Context, Goals, Proof), 
	ln(Proof, LineNumber1), a2(Context, Steps, NewContext), 
	backwardProve([step(A, [hypothesis], LineNumber1)], NewContext, [B], BoxProof), 
	ln(BoxProof, NextLineNumber), is(LineNumber2, NextLineNumber-1).
% try Forward prove: if no further progress can be done backwards, try to break down derived formulas again
backwardProve(Steps, Context, Goals, Proof) :- 
	length(Steps, S1), 
	forwardProve(Steps, Context, NewSteps), !, 
	length(NewSteps, S2), S2 > S1, 
	backwardProve(NewSteps, Context, Goals, Proof).