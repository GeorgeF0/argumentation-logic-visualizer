% Make prolog not abbreviate lists and long results
%set_prolog_flag(toplevel_print_options, [quoted(true), portray(true)]).

% Convert list of givens to steps (internal ND data-structure)
% steps are of the format step(formula, reason as to how this formula was derived, position of this step in the overall proof)
toSteps(Givens, RevSteps) :- reverse(Steps, RevSteps), toSteps(Givens, Steps, 0).
toSteps([], [], _).
toSteps([G|Givens], [step(G, given, LineNumber)|Steps], LineNumber) :- is(N, LineNumber + 1), toSteps(Givens, Steps, N).

% Append 3 lists and Append shortcut
a2(L1, L2, L) :- append(L1, L2, L).
a3(L1, L2, L3, L) :- append(L1, L2, Lx), append(Lx, L3, L).

% Get next line number from steps
% ln(step, next line number)
ln([step(_, _, LineNumber)|_], NextLineNumber) :- is(NextLineNumber, LineNumber + 1).
% ln(current line number, next line number)
ln(LineNumber, NextLineNumber) :- integer(LineNumber), is(NextLineNumber, LineNumber + 1).

% Contruct a proof in Natural Deduction
% prove is of the format prove([givens, ex: and(a,b), c, d], [goal that needs to be proven], Output proof given as variable)
prove(Givens, Goal, Proof) :- is_list(Givens), is_list(Goal), toSteps(Givens, Steps), !, backwardProve(Steps, Goal, Proof).

% Forward Prove: iterates through all steps and breaks down formulas into smaller, simpler parts
% this process does not take into account the goals or the proof so far
% this process repeats itself until no further progress can be made (ie: until formulas can not be broken down any longer)
forwardProve(Steps, NewSteps) :- length(Steps, S1), andE(Steps, NewSteps1), notE(NewSteps1, NewSteps2), length(NewSteps2, S2), S2 > S1, forwardProve(NewSteps2, NewSteps).
forwardProve(NewSteps, NewSteps).
% Forward Prove Rules: different rules that break down different types of formulas
% all rules are of the form rule(current steps, Expanded steps)
% And Elimination:
andE(Steps, NewSteps) :- andEx(Steps, Steps, NewSteps).
andEx(OldSteps, [], OldSteps).
andEx(OldSteps, [step(and(A, B), _, LineNumber)|Steps], NewSteps) :- 
	andEx(OldSteps, Steps, NS), 
	(member(step(A, _, _), NS), member(step(B, _, _), NS), LeftRightClause = [], !;
	member(step(A, _, _), NS), ln(NS, NextLineNumber), LeftRightClause = [step(B, [andE, LineNumber], NextLineNumber)], !;
	member(step(B, _, _), NS), ln(NS, NextLineNumber), LeftRightClause = [step(A, [andE, LineNumber], NextLineNumber)], !;
	ln(NS, NextLineNumber), ln(NextLineNumber, NextNextLineNumber), LeftRightClause = [step(A, [andE, LineNumber], NextNextLineNumber), step(B, [andE, LineNumber], NextLineNumber)], !),
	a2(LeftRightClause, NS, NewSteps).
andEx(OldSteps, [_|Steps], NewSteps) :- andEx(OldSteps, Steps, NewSteps).
% Not Elimination:
notE(Steps, NewSteps) :- notEx(Steps, Steps, NewSteps).
notEx(OldSteps, [], OldSteps).
notEx(OldSteps, [step(n(n(A)), _, LineNumber)|Steps], NewSteps) :-
	notEx(OldSteps, Steps, NS),
	(member(step(A, _, _), NS), ExtraSteps = [], !;
	ln(NS, NextLineNumber), ExtraSteps = [step(A, [notE, LineNumber], NextLineNumber)], !),
	a2(ExtraSteps, NS, NewSteps).
notEx(OldSteps, [_|Steps], NewSteps) :- notEx(OldSteps, Steps, NewSteps).
% BackwardProve: tries to match the current steps to goals, or simplify goals and try matching again
% whenever no further progress can be made, a call to forwardProve is made in order to break down steps into simpler formulas that might be of use
% Base case: no more goals to prove means we've completed the proof
backwardProve(Steps, [], Steps).
% Check: if the goal appears as a step (ie: if the goal has been derived) check it and try to prove the rest of the goals
backwardProve(Steps, [G|Goals], [step(G, [check, LineNumber], NextLineNumber)|Proof]) :- member(step(G, _, LineNumber), Steps), backwardProve(Steps, Goals, Proof), ln(Proof, NextLineNumber).
% And Introduction: prove and(a,b) by proving a and b separately
backwardProve(Steps, [and(A, B)| Goals], [step(and(A, B), [andI, LineNumber1, LineNumber2], NextLineNumber)|Proof]) :- backwardProve(Steps, [A, B|Goals], Proof), member(step(A, _, LineNumber1), Proof), member(step(B, _, LineNumber2), Proof), ln(Proof, NextLineNumber).
% try Forward prove: if no further progress can be done backwards, try to break down derived formulas again
backwardProve(Steps, Goals, Proof) :- length(Steps, S1), forwardProve(Steps, NewSteps), !, length(NewSteps, S2), S2 > S1, backwardProve(NewSteps, Goals, Proof).