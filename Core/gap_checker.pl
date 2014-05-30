% GAP_CHECKER: provides predicates that check whether a proof follows the GAP property

% Checks that the given proof follows the classic GAP property
% Gap checker assumes valid propositional logic proofs
checkGAP(Proof) :- 
	reverse(Proof, RevProof), 
	checkRAND(RevProof), !,
	checkRestrictedRules(RevProof), !,
	getTheoryAndRevBox(RevProof, Theory, RevBox), !,
	checkRestrictedTheory(Theory), !,
	checkPureND(Theory, RevBox), !,
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
	(
		ChildHypothesis = n(X),
		NegatedChildHypothesis = X;
		
		NegatedChildHypothesis = n(ChildHypothesis)
	),
	checkGAP(Theory, Hypothesis, AncestorHypotheses, [NegatedChildHypothesis|ChildHypotheses], Proof).

% Checks to see if this proof is a RAND proof to start with
% A RAND proof is of the form: [givens]*, [box], ([step:notE, step:notI]||[step:notI])
checkRAND(Proof) :- checkRAND(givens, Proof).
checkRAND(givens, [box(_)|Proof]) :- checkRAND(box, Proof).
checkRAND(givens, [step(_, [given], _)|Proof]) :- checkRAND(givens, Proof).
checkRAND(box, [step(_, [notI|_], _)]).
checkRAND(box, [step(_, [notI|_], _), step(_, [notE, _], _)]).

% Checks to see if the proof consists of ruleset defined over argumentation logic
validRules([andI, andE, notI, notE, falsityI, falsityE, given, check, hypothesis]).
checkRestrictedRules([]).
checkRestrictedRules([step(_, [Reason|_], _)|Proof]) :- 
	validRules(ValidRules), 
	m2(Reason, ValidRules), 
	checkRestrictedRules(Proof).
checkRestrictedRules([box(SubProof)|Proof]) :-
	checkRestrictedRules(SubProof),
	checkRestrictedRules(Proof).
checkRestrictedTheory([]).
checkRestrictedTheory([Given|Theory]) :-
	checkRestrictedFormula(Given),
	checkRestrictedTheory(Theory).
checkRestrictedFormula(X) :- 
	atom(X).
checkRestrictedFormula(and(X, Y)) :-
	checkRestrictedFormula(X),
	checkRestrictedFormula(Y).
checkRestrictedFormula(n(X)) :-
	checkRestrictedFormula(X).

% Checks to see if this proof does not make references to external derivations
checkPureND(Theory, Proof) :-
	length(Theory, TheoryLength),
	checkPureND(TheoryLength, _, Proof, Proof).
checkPureND(_, _, [], _) :- !.
checkPureND(L, _, [step(_, [hypothesis], LN)|Proof], WholeProof) :-
	!, checkPureND(L, LN, Proof, WholeProof).
checkPureND(L, LN, [step(_, [_|ReasonLines], _)|Proof], WholeProof) :-
	forall(m2(RL, ReasonLines), (RL >= LN; RL < L; getStep(RL, WholeProof, step(_, [hypothesis], RL)))),
	checkPureND(L, LN, Proof, WholeProof).
checkPureND(L, LN, [box(BoxProof)|Proof], WholeProof) :-
	checkPureND(L, _, BoxProof, WholeProof),
	checkPureND(L, LN, Proof, WholeProof).
	
% Checks that the given proof follows the extended GAP property
checkGAPX(Proof) :- 
	reverse(Proof, RevProof), 
	checkRAND(RevProof), !,
	checkRestrictedRules(RevProof), !,
	getTheoryAndRevBox(RevProof, Theory, RevBox), !,
	checkRestrictedTheory(Theory), !,
	checkGAPX(Theory, _, [], [], [], RevBox, RevBox, _), !.
checkGAPX(Theory, _, AncestorHypotheses, ChildHypotheses, SiblingHypotheses, [], _, _) :-
	a4(Theory, AncestorHypotheses, ChildHypotheses, SiblingHypotheses, Context),
	not(proveMRA(Context, [falsity], _)).
checkGAPX(Theory, _, AncestorHypotheses, ChildHypotheses, SiblingHypotheses, [step(H, [hypothesis], HL)|Proof], WholeProof, _) :-
	!, checkGAPX(Theory, H, AncestorHypotheses, ChildHypotheses, SiblingHypotheses, Proof, WholeProof, HL).
checkGAPX(Theory, Hypothesis, AncestorHypotheses, ChildHypotheses, SiblingHypotheses, [step(_, [_|Reason], _)|Proof], WholeProof, HL) :-
	getUsedSiblingHypotheses(Theory, Reason, WholeProof, HL, NewHypotheses),
	a2(NewHypotheses, SiblingHypotheses, NewSiblingHypotheses),
	checkGAPX(Theory, Hypothesis, AncestorHypotheses, ChildHypotheses, NewSiblingHypotheses, Proof, WholeProof, HL).
checkGAPX(Theory, Hypothesis, AncestorHypotheses, ChildHypotheses, SiblingHypotheses, [box(BoxProof)|Proof], WholeProof, HL) :-
	checkGAPX(Theory, _, [Hypothesis|AncestorHypotheses], [], [], BoxProof, WholeProof, _),
	BoxProof = [step(ChildHypothesis, [hypothesis], _)|_],
	(
		ChildHypothesis = n(X),
		NegatedChildHypothesis = X;
		
		NegatedChildHypothesis = n(ChildHypothesis)
	),
	checkGAPX(Theory, Hypothesis, AncestorHypotheses, [NegatedChildHypothesis|ChildHypotheses], SiblingHypotheses, Proof, WholeProof, HL).
	
% Uses the line references to find referenced sibling derivations
getUsedSiblingHypotheses(_, [], _, _, []) :- !.
getUsedSiblingHypotheses(Theory, Reason, WholeProof, HL, NewHypotheses) :-
	length(Theory, L),
	findall(R, (m2(R, Reason), R < HL, R >= L), External),
	findall([H, E], (m2(E, External), getStep(E, WholeProof, step(H, [notI|_], _))), HLN),
	unzip(Hs, LNs, HLN),
	subtract(External, LNs, Rest),
	findall(Reason2, (m2(R2, Rest), getStep(R2, WholeProof, step(_, [_|Reason2], _))), Reasons),
	append(Reasons, Reasons2),
	getUsedSiblingHypotheses(Theory, Reasons2, WholeProof, HL, NewHypotheses2),
	append(Hs, NewHypotheses2, NewHypotheses).
	
unzip([], [], []).
unzip([L|Ls], [R|Rs], [[L,R]|Ps]) :- unzip(Ls, Rs, Ps).