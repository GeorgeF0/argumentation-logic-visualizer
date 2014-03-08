% PRUNE: predicates used to prune unused steps and "check" rule applications from the proof

% Prune unused steps in a proof and "check" steps for a more natural and concise proof
prune([step(X, Y, LineNumber)|Proof], LNPrunedProof) :- 
	pruneSteps([step(X, Y, LineNumber)|Proof], [LineNumber], _, PrunedProof),
	recalculateLineNumbers(PrunedProof, LNPrunedProof), !.
% Prune unused steps in a proof and "check" steps
pruneSteps([], UsedSteps, UsedSteps, []).
pruneSteps([step(X, [Z], Y)|Proof], _, _, [step(X, [Z], Y)|Proof]) :-
	Z = given; Z = hypothesis.
pruneSteps([step(X, [Y, LN1, LN2], LN)|Proof], UsedSteps, SubSteps, [step(X, [Y, NewLN1, NewLN2], LN)|PrunedProof]) :-
	m2(LN, UsedSteps),
	(
		m2(step(_, Reason1, LN1), Proof), 
		(Reason1 = [check, LN3], NewLN1 = LN3; LN1 = NewLN1);
		
		NewLN1 = LN1
	),
	(
		m2(step(_, Reason2, LN2), Proof), 
		(Reason2 = [check, LN4], NewLN2 = LN4; LN2 = NewLN2);
		
		NewLN2 = LN2
	),
	pruneSteps(Proof, [NewLN1, NewLN2|UsedSteps], SubSteps, PrunedProof).
pruneSteps([step(X, [Y, LN1], LN)|Proof], UsedSteps, SubSteps, [step(X, [Y, NewLN1], LN)|PrunedProof]) :-
	m2(LN, UsedSteps), 
	(
		m2(step(_, Reason, LN1), Proof), 
		(Reason = [check, LN3], NewLN1 = LN3; LN1 = NewLN1);
		
		NewLN1 = LN1
	),
	pruneSteps(Proof, [NewLN1|UsedSteps], SubSteps, PrunedProof).
pruneSteps([box(BoxProof)|Proof], UsedSteps, SubSteps, [box(PrunedBoxProof)|PrunedProof]) :-
	m2(step(_, _, LN), BoxProof), m2(LN, UsedSteps),
	pruneSteps(BoxProof, UsedSteps, BoxSteps, PrunedBoxProof),
	pruneSteps(Proof, BoxSteps, SubSteps, PrunedProof).
pruneSteps([_|Proof], UsedSteps, SubSteps, PrunedProof) :- pruneSteps(Proof, UsedSteps, SubSteps, PrunedProof).
% Recalculates line numbers after removing unused steps from the proof
recalculateLineNumbers(PrunedProof, LNPrunedProof) :- 
	reverse(PrunedProof, RevPrunedProof), 
	recalculateLN(RevPrunedProof, 0, _, [], _, RevLNPrunedProof), 
	reverse(RevLNPrunedProof, LNPrunedProof).
recalculateLN([], CurrentLine, CurrentLine, Substitutions, Substitutions, []).
recalculateLN([step(X, Y, LineNumber)|Proof], CurrentLine, NewCurrentLine, Substitutions, NewSubstitutions, [step(X, Z, CurrentLine)|LNProof]) :-
	(
		Y = [Reason2, LN], m2([LN, SubLN], Substitutions), 
		Z = [Reason2, SubLN];
		
		Y = [Reason1, LN1, LN2], 
		m2([LN1, SubLN1], Substitutions), m2([LN2, SubLN2], Substitutions), 
		Z = [Reason1, SubLN1, SubLN2];
		
		Y = Z
	),
	ln(CurrentLine, NextLine),
	recalculateLN(Proof, NextLine, NewCurrentLine, [[LineNumber, CurrentLine]|Substitutions], NewSubstitutions, LNProof).
recalculateLN([box(BoxProof)|Proof], CurrentLine, NewCurrentLine1, Substitutions, NewSubstitutions1, [box(LNBoxProof)|LNProof]) :-
	reverse(BoxProof, RevBoxProof),
	recalculateLN(RevBoxProof, CurrentLine, NewCurrentLine2, Substitutions, NewSubstitutions2, RevLNBoxProof),
	reverse(RevLNBoxProof, LNBoxProof),
	recalculateLN(Proof, NewCurrentLine2, NewCurrentLine1, NewSubstitutions2, NewSubstitutions1, LNProof).
