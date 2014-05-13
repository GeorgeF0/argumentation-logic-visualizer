% ARG_TO_GAP: provides predicates to convert an argument into a gap proof

% Return the parent hypotheses of the given defense node
parentSet([_, _], 1, []).
parentSet([Nodes, AttDefs], NodeID, [Parent|ParentSet]) :-
	m2([NodeID, AttackNodeID], AttDefs),
	m2([AttackNodeID, ParentNodeID], AttDefs),
	m2([[Parent], ParentNodeID], Nodes),
	parentSet([Nodes, AttDefs], ParentNodeID, ParentSet).

% Returns a list of the negated child hypotheses for the given child proofs
childSet([], []).
childSet([[step(NegHyp, _, _)|_]|ChildGAPs], [NegHyp|ChildHypotheses]) :-
	childSet(ChildGAPs, ChildHypotheses).

convertArgToGAP(Argument, Theory, TheoryAndProof) :-
	convertArgToGAP(Argument, Theory, 1, Proof),
	toSteps(Theory, TheorySteps),
	a2(Proof, TheorySteps, TheoryAndProof).
convertArgToGAP([Nodes, AttDefs], Theory, NodeID, Proof) :-
	findall(Def, (m2([Att, NodeID], AttDefs), m2([Def, Att], AttDefs)), Defs),
	findall(SubProof, (m2(X, Defs), convertArgToGAP([Nodes, AttDefs], Theory, X, SubProof)), SubProofs),
	makeSubProof([Nodes, AttDefs], Theory, SubProofs, NodeID, Proof).

makeSubProof([Nodes, AttDefs], Theory, ChildGAPs, NodeID, SubProof) :-
	parentSet([Nodes, AttDefs], NodeID, ParentSet),
	childSet(ChildGAPs, ChildSet),
	lineFix(ParentSet, ChildGAPs, FixedChildGAPs),
	append(FixedChildGAPs, MergedCGAPs),
	a2(Theory, ParentSet, Context),
	toSteps(Context, ContextSteps), !,
	ln(ContextSteps, LineNumber1),
	m2([[Node], NodeID], Nodes),
	a2(MergedCGAPs, [step(Node, [hypothesis], LineNumber1)], HypothesisChildren),
	backwardProve(no, HypothesisChildren, ContextSteps, [[], []], [falsity], BoxProof),
	childGAPsUsed(BoxProof, [Node|ChildSet], ParentSet),
	ln(BoxProof, NextLineNumber), is(LineNumber2, NextLineNumber - 1),
	(
		Node = n(A),
		ln(NextLineNumber, NextNextLineNumber),
		SubProof = [step(A, [notE, NextLineNumber], NextNextLineNumber), step(n(Node), [notI, LineNumber1, LineNumber2], NextLineNumber), box(BoxProof)], !;

		SubProof = [step(n(Node), [notI, LineNumber1, LineNumber2], NextLineNumber), box(BoxProof)], !
	),
	!.

% Make sure that all the (negations of the) child hypotheses were used in the attack
childGAPsUsed(Proof, ChildSet, ParentSet) :-
	(
		Proof = [step(falsity, [falsityI, _, LN], _)|_];
		
		Proof = [step(falsity, [check, _], _), step(falsity, [falsityI, _, LN], _)|_]
	),
	m2(step(X, _, LN), Proof),
	getConjunctionComponents(X, Components),
	a2(ChildSet, ParentSet, UsedFormulas),
	subset(Components, UsedFormulas).

% Returns the components making up a conjunction
% Example: a&b&c&¬d -> [a,b,c,¬d]
getConjunctionComponents(and(A, B), Components):-
	getConjunctionComponents(A, Component1),
	getConjunctionComponents(B, Component2),
	a2(Component1, Component2, Components), !.
getConjunctionComponents(X, [X]).
	
% Changes the lines of the proofs of the child proofs so that no two steps
% have the same line number. References are updated as well
lineFix(ParentSet, ChildGAPs, FixedChildGAPs) :-
	length(ParentSet, L),
	lineFix(L, ChildGAPs, 0, FixedChildGAPs).
lineFix(_, [], _, []).
lineFix(From, [ChildGAP|ChildGAPs], Offset, [FixedChildGAP|FixedChildGAPs]) :-
	shiftLines(From, Offset, ChildGAP, FixedChildGAP),
	ln(ChildGAP, NewOffset),
	lineFix(From, ChildGAPs, NewOffset, FixedChildGAPs).
shiftLines(_, _, [], []).
shiftLines(From, Offset, [step(A, [R|Reason], LineNumber)|Proof], [step(A, [R|FixedReason], FixedLineNumber)|FixedProof]) :-
	shiftNumbers(From, Offset, [LineNumber|Reason], [FixedLineNumber|FixedReason]),
	shiftLines(From, Offset, Proof, FixedProof).
shiftLines(From, Offset, [box(BoxProof)|Proof], [box(FixedBoxProof)|FixedProof]) :-
	shiftLines(From, Offset, BoxProof, FixedBoxProof),
	shiftLines(From, Offset, Proof, FixedProof).
shiftNumbers(_, _, [], []).
shiftNumbers(From, Offset, [N|Numbers], [FN|FixedNumbers]) :-
	(
		N > From, is(FN, N + Offset);
		
		FN = N
	),
	shiftNumbers(From, Offset, Numbers, FixedNumbers).