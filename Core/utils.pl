% UTILS: predicates used by predicates in other files

% Convert list of givens to steps (internal ND data-structure)
% steps are of the format step(formula, reason as to how this formula was derived, position of this step in the overall proof)
toSteps(Givens, RevSteps) :- toSteps(Givens, Steps, 0), reverse(Steps, RevSteps).
toSteps([], [], _).
toSteps([G|Givens], [step(G, [given], LineNumber)|Steps], LineNumber) :- is(N, LineNumber + 1), toSteps(Givens, Steps, N).

% Append 3 lists and Append shortcut
a2(L1, L2, L) :- append(L1, L2, L).
a3(L1, L2, L3, L) :- append(L1, L2, Lx), append(Lx, L3, L).
a4(L1, L2, L3, L4, L) :- append(L1, L2, Lx), append(Lx, L3, Ly), append(Ly, L4, L).

% Member of either list and Member shortcut
m2(Item, List) :- member(Item, List).
m3(Item, List1, List2) :- member(Item, List1); member(Item, List2).

% Get next line number from steps
% ln(step, next line number)
ln([step(_, _, LineNumber)|_], NextLineNumber) :- !, is(NextLineNumber, LineNumber + 1).
ln([], 0) :- !.
% ln(current line number, next line number)
ln(LineNumber, NextLineNumber) :- !, integer(LineNumber), is(NextLineNumber, LineNumber + 1).

% Digs up the theory and first box of a proof in reverse order
getTheoryAndRevBox([step(Given, [given], _)|Proof], [Given|Theory], Box) :-
	getTheoryAndRevBox(Proof, Theory, Box).
getTheoryAndRevBox([box(BoxProof)|_], [], RevBoxProof) :-
	reverseRecursive(BoxProof, RevBoxProof).
	
reverseRecursive(BoxProof, RevAllBoxProof) :-
	reverse(BoxProof, RevBoxProof),
	reverseInnerBoxes(RevBoxProof, RevAllBoxProof).

reverseInnerBoxes([], []).
reverseInnerBoxes([box(InnerBox)|RevBoxProof], [box(RevInnerBox)|RevInnerBoxProof]) :-
	!, reverseRecursive(InnerBox, RevInnerBox),
	reverseInnerBoxes(RevBoxProof, RevInnerBoxProof).
reverseInnerBoxes([Step|RevBoxProof], [Step|RevInnerBoxProof]) :-
	reverseInnerBoxes(RevBoxProof, RevInnerBoxProof).