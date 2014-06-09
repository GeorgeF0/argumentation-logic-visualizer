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
	lineFix(ParentSet, Theory, ChildGAPs, FixedChildGAPs),
	append(FixedChildGAPs, MergedCGAPs),
	reverse(ParentSet, RevParentSet),
	a2(Theory, RevParentSet, Context),
	toSteps(Context, ContextSteps), !,
	ln(ContextSteps, LineNumber1),
	m2([[Node], NodeID], Nodes),
	a2(MergedCGAPs, [step(Node, [hypothesis], LineNumber1)], HypothesisChildren),
	backwardProve(no, HypothesisChildren, ContextSteps, [[], [], []], falsity, BoxProof),
	childGAPsUsed(BoxProof, Theory, [Node|ChildSet], ParentSet),
	ln(BoxProof, NextLineNumber), is(LineNumber2, NextLineNumber - 1),
	(
		Node = n(A),
		ln(NextLineNumber, NextNextLineNumber),
		SubProof = [step(A, [notE, NextLineNumber], NextNextLineNumber), step(n(Node), [notI, LineNumber1, LineNumber2], NextLineNumber), box(BoxProof)], !;

		SubProof = [step(n(Node), [notI, LineNumber1, LineNumber2], NextLineNumber), box(BoxProof)], !
	),
	!.

% Make sure that all the (negations of the) child hypotheses were used in the attack
childGAPsUsed(Proof, Theory, ChildSet, ParentSet) :-
	(
		Proof = [step(falsity, [falsityI, _, LN], _)|_];
		
		Proof = [step(falsity, [check, _], _), step(falsity, [falsityI, _, LN], _)|_]
	),
	m2(step(X, _, LN), Proof),
	getConjunctionComponents(X, UsedComponents),
	subset(ChildSet, UsedComponents),
	subtract(UsedComponents, ChildSet, Rest),
	findall(TheoryComponents, (m2(T, Theory), getConjunctionComponents(T, TheoryComponents)), TheoryComponentsList),
	append(TheoryComponentsList, AllowedTheoryComponents),
	a2(AllowedTheoryComponents, ParentSet, AllowedComponents),
	subset(Rest, AllowedComponents).

% Returns the components making up a conjunction
% Example: a&b&c&¬d -> [a,b,c,¬d]
getConjunctionComponents(and(A, B), Components):-
	getConjunctionComponents(A, Component1),
	getConjunctionComponents(B, Component2),
	a2(Component1, Component2, Components), !.
getConjunctionComponents(X, [X]).
	
% Changes the lines of the proofs of the child proofs so that no two steps
% have the same line number. References are updated as well
lineFix(ParentSet, Theory, ChildGAPs, FixedChildGAPs) :-
	length(ParentSet, L),
	length(Theory, T),
	lineFix(L, ChildGAPs, T, T, RevFixedChildGAPs),
	reverse(RevFixedChildGAPs, FixedChildGAPs).
lineFix(_, [], _, _, []).
lineFix(From, [ChildGAP|ChildGAPs], Offset, TheoryOffset, [FixedChildGAP|FixedChildGAPs]) :-
	shiftLines(From, Offset, TheoryOffset, ChildGAP, FixedChildGAP),
	ln(ChildGAP, NewOffset),
	lineFix(From, ChildGAPs, NewOffset -1, TheoryOffset, FixedChildGAPs).
shiftLines(_, _, _, [], []).
shiftLines(From, Offset, TheoryOffset, [step(A, [R|Reason], LineNumber)|Proof], [step(A, [R|FixedReason], FixedLineNumber)|FixedProof]) :-
	shiftNumbers(From, Offset, TheoryOffset, [LineNumber|Reason], [FixedLineNumber|FixedReason]),
	shiftLines(From, Offset, TheoryOffset, Proof, FixedProof).
shiftLines(From, Offset, TheoryOffset, [box(BoxProof)|Proof], [box(FixedBoxProof)|FixedProof]) :-
	shiftLines(From, Offset, TheoryOffset, BoxProof, FixedBoxProof),
	shiftLines(From, Offset, TheoryOffset, Proof, FixedProof).
shiftNumbers(_, _, _, [], []).
shiftNumbers(From, Offset, TheoryOffset, [N|Numbers], [FN|FixedNumbers]) :-
	(
		N > From + TheoryOffset, is(FN, N + Offset - TheoryOffset);
		
		FN = N
	),
	shiftNumbers(From, Offset, TheoryOffset, Numbers, FixedNumbers).