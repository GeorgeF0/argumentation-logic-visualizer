% GAP_TO_ARG: provides predicates to convert a GAP proof to its argumentation form

% Converts a GAP proof to its argumentation representation
convertGAPToArg(Proof, [Nodes, AttDefs]) :-
	reverse(Proof, RevProof),
	getTheoryAndRevBox(RevProof, Theory, Box),
	getDefence(Box, Theory, 1, 0, Nodes, [_|AttDefs]), !.
% Makes a node and defence relation against given attack (and handles its subtree as well)
getDefence([step(Hypothesis, [hypothesis], _)|Proof], Theory, You, Target, [[[Hypothesis], You]|Nodes], [[You, Target]|AttDefs]) :-
	getAttack(Proof, [Hypothesis|Theory], You, Nodes, AttDefs).
% Makes a node and attack relation against given defence (and handles its subtree as well)
getAttack(Proof, Ignore, N, Nodes, AttDefs) :-
	reverse(Proof, [step(falsity, [falsityI, _, LN], _)|_]),
	m2(step(_, [andI|_], LN), Proof),
	findAttackComponents(Proof, Ignore, LN, Components),
	makeAttackNode(Components, Attack),
	Ignore = [_|Theory],
	findall([AttComponent, DefAgainstAtt], m2([AttComponent, DefAgainstAtt], Components), DefendedAgainstComponents),
	ln(N, NextN), ln(NextN, NextNextN),
	getDefences(Theory, NextNextN, NextN, DefendedAgainstComponents, DNodes, DAttDefs),
	Nodes = [[[Attack], NextN]|DNodes],
	AttDefs = [[NextN, N]|DAttDefs].
% Gathers all defences against an attack (and their subtrees)
getDefences(Theory, You, Target, [[_, Box]|Components], Nodes, AttDefs) :-
	getDefence(Box, Theory, You, Target, DNodes, DAttDefs),
	reverse(DNodes, [[_, LastId]|_]),
	ln(LastId, NewYou),
	getDefences(Theory, NewYou, Target, Components, DsNodes, DsAttDefs),
	a2(DNodes, DsNodes, Nodes),
	a2(DAttDefs, DsAttDefs, AttDefs).
getDefences(_, _, _, [], [], []).
% Creates the attack node given the components of an attack
% example: returns [¬b, ¬d] from [[¬b, [defence against ¬b]], [¬d, [defence against ¬d]]]
makeAttackNode([[X|_]|Components], [X|Attack]) :-
	makeAttackNode(Components, Attack).
makeAttackNode([], []).
% Breaks down an attack into individual components and the defence attempts against them
% returns a list of a mixture of:
% [A] (for part of the attack used as defences up the tree - there's no way to attack them)
% [A, defAgainstA] (for part of the attack that was attempted to defend against, plus the box of the proof that does so)
% example: given attack a&b&¬c&d returns [[a], [[b], [...]], [[¬c], [...]]],
% assuming a was used as a defence above (you cannot defend against your defence, so this is a terminal part of the attack),
% there was an attempt to defend against b and ¬c (given by the parts of the proof [...]),
% and d was part of the theory hence there's no defence against that
findAttackComponents(Proof, Ignore, LN, Components) :-
	m2(step(and(A, B), [andI, LN1, LN2], LN), Proof),
	getAttackComponent(A, LN1, Ignore, Proof, Components1),
	getAttackComponent(B, LN2, Ignore, Proof, Components2),
	a2(Components1, Components2, Components).
getAttackComponent(and(_, _), LN, Ignore, Proof, Components) :-
	!, findAttackComponents(Proof, Ignore, LN, Components).
getAttackComponent(A, LN, Ignore, Proof, Component) :-
	m2(A, Ignore), Component = [], !;
	not(m2(step(A, _, LN), Proof)), Component = [[A]], !;
	getBox(LN, Proof, _, Box), Component = [[A, Box]].
% Gets the relevant part of the proof that corresponds to the attempt to defend
% against some part of an attack (the defence and attacks against it will be
% gathered from this part of the proof)
getBox(LN, [step(_, _, LN)|_], LastBox, LastBox).
getBox(LN, [box(LastBox)|Proof], _, Box) :-
	!, getBox(LN, Proof, LastBox, Box).
getBox(LN, [_|Proof], LastBox, Box) :-
	getBox(LN, Proof, LastBox, Box).