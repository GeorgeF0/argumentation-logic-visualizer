% PROVER_UTILS: predicates used by the proof system to facilitate theorem proving

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