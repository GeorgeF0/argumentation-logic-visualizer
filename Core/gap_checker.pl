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
	checkGAP(Theory, [], [], [], RevBox, RevBox, _), !.

% Checks that the given proof follows the extended GAP property
checkGAPX(Proof) :- 
	reverse(Proof, RevProof), 
	checkRAND(RevProof), !,
	checkRestrictedRules(RevProof), !,
	getTheoryAndRevBox(RevProof, Theory, RevBox), !,
	checkRestrictedTheory(Theory), !,
	checkGAP(Theory, [], [], [], RevBox, RevBox, _), !.

% Checks for the actual GAP for each (sub)derivation in the proof
checkGAP(Theory, AncestorHypotheses, ChildHypotheses, SiblingHypotheses, [], _, _) :-
	a4(Theory, AncestorHypotheses, ChildHypotheses, SiblingHypotheses, Context),
	not(proveMRA(Context, falsity, _)).
checkGAP(Theory, [], ChildHypotheses, SiblingHypotheses, [step(_, [hypothesis], HL)|Proof], WholeProof, _) :-
	!, checkGAP(Theory, [], ChildHypotheses, SiblingHypotheses, Proof, WholeProof, HL).
checkGAP(Theory, AncestorHypotheses, ChildHypotheses, SiblingHypotheses, [step(_, [_|Reason], _)|Proof], WholeProof, HL) :-
	getUsedHypotheses(Theory, Reason, WholeProof, HL, NewAncHypotheses, NewSibHypotheses),
	a2(NewSibHypotheses, SiblingHypotheses, NewSiblingHypotheses),
	a2(NewAncHypotheses, AncestorHypotheses, NewAncestorHypotheses),
	checkGAP(Theory, NewAncestorHypotheses, ChildHypotheses, NewSiblingHypotheses, Proof, WholeProof, HL).
checkGAP(Theory, AncestorHypotheses, ChildHypotheses, SiblingHypotheses, [box(BoxProof)|Proof], WholeProof, HL) :-
	checkGAP(Theory, [], [], [], BoxProof, WholeProof, _),
	BoxProof = [step(ChildHypothesis, [hypothesis], _)|_],
	(
		ChildHypothesis = n(X),
		NegatedChildHypothesis = X;
		
		NegatedChildHypothesis = n(ChildHypothesis)
	),
	checkGAP(Theory, AncestorHypotheses, [NegatedChildHypothesis|ChildHypotheses], SiblingHypotheses, Proof, WholeProof, HL).

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
	
% Uses the line references to find referenced sibling derivations
getUsedHypotheses(_, [], _, _, [], []) :- !.
getUsedHypotheses(Theory, Reason, WholeProof, HL, NewAncHypotheses, NewSibHypotheses) :-
	length(Theory, L),
	findall(R, (m2(R, Reason), R < HL, R >= L), External),
	findall([H1, E1], (m2(E1, External), getStep(E1, WholeProof, step(H1, [notI|_], _))), HLN1),
	unzip(Hs1, LNs1, HLN1),
	subtract(External, LNs1, Rest1),
	findall([H2, E2], (m2(E2, Rest1), getStep(E2, WholeProof, step(H2, [hypothesis], _))), HLN2),
	unzip(Hs2, LNs2, HLN2),
	subtract(Rest1, LNs2, Rest2),
	findall(Reason2, (m2(R2, Rest2), getStep(R2, WholeProof, step(_, [_|Reason2], _))), Reasons),
	append(Reasons, Reasons2),
	getUsedHypotheses(Theory, Reasons2, WholeProof, HL, NewAncHypotheses2, NewSibHypotheses2),
	append(Hs1, NewSibHypotheses2, NewSibHypotheses),
	append(Hs2, NewAncHypotheses2, NewAncHypotheses).
	
unzip([], [], []).
unzip([L|Ls], [R|Rs], [[L,R]|Ps]) :- unzip(Ls, Rs, Ps).