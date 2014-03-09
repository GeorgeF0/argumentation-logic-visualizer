% GAP_CHECKER: provides predicates that check whether a proof follows the GAP property

% Checks that the given proof follows the GAP property
checkGAP(Proof) :- checkGAP([], Proof).
checkGAP(_, []). % should every box end with falsity? ie checkGAP(_, [step(falsity, _, _)]). how about outermost proof?
checkGAP(Context, [step(Derivation, _, _)|Proof]) :-
	checkGAP([Derivation|Context], Proof).
checkGAP(Context, [box(SubProof), step(Conclusion, [notI, _, _], _)|Proof]) :-
	not(prove(Context, [falsity], _)),
	checkGAP(Context, SubProof),
	checkGAP([Conclusion|Context], Proof).