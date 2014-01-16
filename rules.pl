% Convert list of givens to steps (internal ND data-structure)
toSteps(Givens, RevSteps) :- reverse(Steps, RevSteps), toSteps(Givens, Steps, 0).
toSteps([], [], _).
toSteps([G|Givens], [step(G, given, LineNumber)|Steps], LineNumber) :- is(N, LineNumber + 1), toSteps(Givens, Steps, N).

% Append 3 lists and Append shortcut
a2(L1, L2, L) :- append(L1, L2, L).
a3(L1, L2, L3, L) :- append(L1, L2, Lx), append(Lx, L3, L).

% Get next line number from steps
ln([step(_, _, LineNumber)|_], NextLineNumber) :- is(NextLineNumber, LineNumber + 1).
ln(LineNumber, NextLineNumber) :- integer(LineNumber), is(NextLineNumber, LineNumber + 1).

% Contruct a proof in Natural Deduction
prove(Givens, Goal, Proof) :- is_list(Givens), is_list(Goal), toSteps(Givens, Steps), !, forwardProve(Steps, Goal, Proof).
% Forward Prove
forwardProve(Steps, Goal, Proof) :- length(Steps, S1), andE(Steps, NewSteps), length(NewSteps, S2), S2 > S1, forwardProve(NewSteps, Goal, Proof).
forwardProve(Steps, Goal, Proof) :- backwardProve(Steps, Goal, Proof).
% Forward Prove Rules: And Elimination,
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

% BackwardProve
backwardProve(Steps, [], Steps).
backwardProve(Steps, [G|Goals], [step(G, [check, LineNumber], NextLineNumber)|Proof]) :- member(step(G, _, LineNumber), Steps), ln(Steps, NextLineNumber), backwardProve(Steps, Goals, Proof).
%backwardProve(Steps, _, Steps).