% GAP_CHECKER: provides predicates that check whether a proof follows the GAP property

% Checks that the given proof follows the GAP property
% Gap checker assumes valid propositional logic proofs
checkGAP(Proof) :- reverse(Proof, RevProof), checkRAND(RevProof), checkRestricted(RevProof), checkGAP([], RevProof).
checkGAP(_, []). % should every box end with falsity? ie checkGAP(_, [step(falsity, _, _)]). how about outermost proof?
checkGAP(Context, [step(Derivation, _, _)|Proof]) :-
	checkGAP([Derivation|Context], Proof).
checkGAP(Context, [box(SubProof), step(Conclusion, [notI, _, _], _)|Proof]) :-
	not(proveMRA(Context, [falsity], _)),
	checkGAP(Context, SubProof),
	checkGAP([Conclusion|Context], Proof).

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