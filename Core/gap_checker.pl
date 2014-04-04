% GAP_CHECKER: provides predicates that check whether a proof follows the GAP property

% Checks that the given proof follows the GAP property
% Gap checker assumes valid propositional logic proofs
checkGAP(Proof) :- 
	reverse(Proof, RevProof), 
	checkRAND(RevProof), !,
	checkRestricted(RevProof), !,
	getTheoryAndRevBox(RevProof, Theory, RevBox), !,
	checkGAP(Theory, _, [], [], RevBox), !.
checkGAP(Theory, _, AncestorHypotheses, ChildHypotheses, []) :-
	a3(Theory, AncestorHypotheses, ChildHypotheses, Context),
	not(proveMRA(Context, [falsity], _)).
checkGAP(Theory, _, AncestorHypotheses, ChildHypotheses, [step(H, [hypothesis], _)|Proof]) :-
	!, checkGAP(Theory, H, AncestorHypotheses, ChildHypotheses, Proof).
checkGAP(Theory, Hypothesis, AncestorHypotheses, ChildHypotheses, [step(_, _, _)|Proof]) :-
	checkGAP(Theory, Hypothesis, AncestorHypotheses, ChildHypotheses, Proof).
checkGAP(Theory, Hypothesis, AncestorHypotheses, ChildHypotheses, [box(BoxProof)|Proof]) :-
	checkGAP(Theory, _, [Hypothesis|AncestorHypotheses], [], BoxProof),
	BoxProof = [step(ChildHypothesis, [hypothesis], _)|_],
	checkGAP(Theory, Hypothesis, AncestorHypotheses, [n(ChildHypothesis)|ChildHypotheses], Proof).

% Checks to see if this proof is a RAND proof to start with
% A RAND proof is of the form: [givens]*, [box], ([step:notE, step:notI]||[step:notI])
checkRAND(Proof) :- checkRAND(givens, Proof).
checkRAND(givens, [box(_)|Proof]) :- checkRAND(box, Proof).
checkRAND(givens, [step(_, [given], _)|Proof]) :- checkRAND(givens, Proof).
checkRAND(box, [step(_, [notI|_], _)]).
checkRAND(box, [step(_, [notI|_], _), step(_, [notE, _], _)]).

% Checks to see if the proof consists of ruleset defined over argumentation logic
validRules([andI, andE, notI, notE, falsityI, falsityE, given, check, hypothesis]).
checkRestricted([]).
checkRestricted([step(_, [Reason|_], _)|Proof]) :- 
	validRules(ValidRules), 
	m2(Reason, ValidRules), 
	checkRestricted(Proof).
checkRestricted([box(SubProof)|Proof]) :-
	checkRestricted(SubProof),
	checkRestricted(Proof).
	
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
	reverseRecursive(InnerBox, RevInnerBox),
	reverseInnerBoxes(RevBoxProof, RevInnerBoxProof).
reverseInnerBoxes([Step|RevBoxProof], [Step|RevInnerBoxProof]) :-
	reverseInnerBoxes(RevBoxProof, RevInnerBoxProof).