% Contruct a proof in Natural Deduction
% prove is of the format prove([givens, ex: and(a,b), c, d], [goal that needs to be proven], Output proof given as variable)
prove(Givens, Goal, Proof) :- is_list(Givens), is_list(Goal), toSteps(Givens, Steps), !, backwardProve(no, Steps, [], [[], []], Goal, Proof).
proveMRA(Givens, Goal, Proof) :- is_list(Givens), is_list(Goal), toSteps(Givens, Steps), !, backwardProve(yes, Steps, [], [[], []], Goal, Proof).
provable(Givens, Goal, yes, Verdict) :- 
	is_list(Givens), 
	is_list(Goal), 
	(
		proveMRA(Givens, Goal, _),
		Verdict = yes, !;
		
		Verdict = no
	).
provable(Givens, Goal, no, Verdict) :- 
	is_list(Givens), 
	is_list(Goal), 
	(
		prove(Givens, Goal, _),
		Verdict = yes, !;
		
		Verdict = no
	).
	
% FORWARD PROVE: iterates through all steps and breaks down formulas into smaller, simpler parts
% this process does not take into account the goals or the proof so far
% this process repeats itself until no further progress can be made (ie: until formulas can not be broken down any longer)
forwardProve(Steps, Context, NewSteps) :- 
	length(Steps, S1), 
	andE(Steps, Context, NewSteps1), 
	notE(NewSteps1, Context, NewSteps2), 
	falsityI(NewSteps2, Context, NewSteps3), 
	length(NewSteps3, S2), S2 > S1, 
	forwardProve(NewSteps3, Context, NewSteps).
forwardProve(NewSteps, _, NewSteps).
% Forward Prove Rules: different rules that break down different types of formulas
% all rules are of the form rule(current steps, Expanded steps)
% AND ELIMINATION:
andE(Steps, Context, NewSteps) :- a2(Context, Steps, AllSteps), andEx(Steps, Context, AllSteps, NewSteps).
andEx(OldSteps, _, [], OldSteps).
andEx(OldSteps, Context, [step(and(A, B), _, LineNumber)|Steps], NewSteps) :- 
	andEx(OldSteps, Context, Steps, NS), 
	(
		m3(step(A, _, _), NS, Context), 
		m3(step(B, _, _), NS, Context), 
		LeftRightClause = [], !;
		
		m3(step(A, _, _), NS, Context), 
		ln(NS, NextLineNumber), 
		LeftRightClause = [step(B, [andE, LineNumber], NextLineNumber)], !;
		
		m3(step(B, _, _), NS, Context), 
		ln(NS, NextLineNumber), 
		LeftRightClause = [step(A, [andE, LineNumber], NextLineNumber)], !;
		
		ln(NS, NextLineNumber), ln(NextLineNumber, NextNextLineNumber), 
		LeftRightClause = [step(A, [andE, LineNumber], NextNextLineNumber), 
		step(B, [andE, LineNumber], NextLineNumber)], !
	),
	a2(LeftRightClause, NS, NewSteps).
andEx(OldSteps, Context, [_|Steps], NewSteps) :- andEx(OldSteps, Context, Steps, NewSteps).
% NOT ELIMINATION:
notE(Steps, Context, NewSteps) :- a2(Context, Steps, AllSteps), notEx(Steps, Context, AllSteps, NewSteps).
notEx(OldSteps, _, [], OldSteps).
notEx(OldSteps, Context, [step(n(n(A)), _, LineNumber)|Steps], NewSteps) :-
	notEx(OldSteps, Context, Steps, NS),
	(
		m3(step(A, _, _), NS, Context), ExtraSteps = [], !;
		
		ln(NS, NextLineNumber), ExtraSteps = [step(A, [notE, LineNumber], NextLineNumber)], !
	),
	a2(ExtraSteps, NS, NewSteps).
notEx(OldSteps, Context, [_|Steps], NewSteps) :- notEx(OldSteps, Context, Steps, NewSteps).
% FALSITY INTRODUCTION:
falsityI(Steps, Context, NewSteps) :- a2(Context, Steps, AllSteps), falsityIx(Steps, Context, AllSteps, NewSteps).
falsityIx(OldSteps, _, [], OldSteps).
falsityIx(OldSteps, _, _, OldSteps) :- m2(step(falsity, _, _), OldSteps), !.
falsityIx(OldSteps, Context, [step(A, _, LineNumber1)|_], [step(falsity, [falsityI, LineNumber1, LineNumber2], NextLineNumber)|OldSteps]) :- 
	m3(step(n(A), _, LineNumber2), OldSteps, Context), ln(OldSteps, NextLineNumber).
falsityIx(OldSteps, Context, [_|Steps], NewSteps) :- falsityIx(OldSteps, Context, Steps, NewSteps).

% BACKWARD PROVE: tries to match the current steps to goals, or simplify goals and try matching again
% whenever no further progress can be made, a call to forwardProve is made in order to break down steps into simpler formulas that might be of use
% BASE CASE: no more goals to prove means we've completed the proof
backwardProve(_, Steps, _, _, [], Steps) :- !.
backwardProve(MRA, Steps, Context, Extras, Goals, Proof) :- 
	check(MRA, Steps, Context, Extras, Goals, Proof);
	% if contradiction has already been established, it reaaaaally makes no sense 
	% to try and prove your goal with any other rule. hence the cut after the falsityE rule below
	falsityE(MRA, Steps, Context, Extras, Goals, Proof), !;
	andI(MRA, Steps, Context, Extras, Goals, Proof);
	impliesI(MRA, Steps, Context, Extras, Goals, Proof);
	MRA = no, notI(MRA, Steps, Context, Extras, Goals, Proof);
	forward(MRA, Steps, Context, Extras, Goals, Proof);
	falsityIE(MRA, Steps, Context, Extras, Goals, Proof);
	impliesE(MRA, Steps, Context, Extras, Goals, Proof);
	MRA = no, proofByContradiction(MRA, Steps, Context, Extras, Goals, Proof).

% CHECK: if the goal appears as a step (ie: if the goal has been derived) check it and try to prove the rest of the goals
check(MRA, Steps, Context, Extras, [G|Goals], [step(G, [check, LineNumber], NextLineNumber)|Proof]) :- 
	m3(step(G, _, LineNumber), Steps, Context), 
	backwardProve(MRA, Steps, Context, Extras, Goals, Proof), ln(Proof, NextLineNumber).
% AND INTRODUCTION: prove and(a,b) by proving a and b separately
andI(MRA, Steps, Context, Extras, [and(A, B)|Goals], [step(and(A, B), [andI, LineNumber1, LineNumber2], NextLineNumber)|Proof]) :- 
	m3(step(A, _, LineNumber1), Steps, Context), 
	m3(step(B, _, LineNumber2), Steps, Context), 
	!, backwardProve(MRA, Steps, Context, Extras, Goals, Proof), ln(Proof, NextLineNumber).
andI(MRA, Steps, Context, Extras, [and(A, B)|Goals], [step(and(A, B), [andI, LineNumber1, LineNumber2], NextLineNumber)|Proof]) :- 
	m3(step(A, _, LineNumber1), Steps, Context), !, 
	backwardProve(MRA, Steps, Context, Extras, [B|Goals], Proof),  m2(step(B, _, LineNumber2), Proof), ln(Proof, NextLineNumber).
andI(MRA, Steps, Context, Extras, [and(A, B)|Goals], [step(and(A, B), [andI, LineNumber1, LineNumber2], NextLineNumber)|Proof]) :- 
	m3(step(B, _, LineNumber2), Steps, Context), !,
	backwardProve(MRA, Steps, Context, Extras, [A|Goals], Proof), m2(step(A, _, LineNumber1), Proof), 
	ln(Proof, NextLineNumber).
andI(MRA, Steps, Context, Extras, [and(A, B)|Goals], [step(and(A, B), [andI, LineNumber1, LineNumber2], NextLineNumber)|Proof]) :- 
	backwardProve(MRA, Steps, Context, Extras, [A, B|Goals], Proof), 
	m2(step(A, _, LineNumber1), Proof), m2(step(B, _, LineNumber2), Proof), 
	ln(Proof, NextLineNumber).
% FALSITY ELIMINATION: if contradiction has been established, vacuously prove current goal
falsityE(MRA, Steps, Context, Extras, [G|Goals], [step(G, [falsityE, LineNumber], NextLineNumber)|Proof]) :-
	not(G = falsity),
	m3(step(falsity, _, LineNumber), Steps, Context), 
	backwardProve(MRA, Steps, Context, Extras, Goals, Proof), ln(Proof, NextLineNumber).
% IMPLIES INTRODUCTION: prove implies(a, b) by starting a nested proof and assuming a, and trying to prove b
impliesI(MRA, Steps, Context, Extras, [implies(A, B)|Goals], [step(implies(A, B), [impliesI, LineNumber1, LineNumber2], NextLineNumber), box(BoxProof)|Proof]) :-
	backwardProve(MRA, Steps, Context, Extras, Goals, Proof), 
	ln(Proof, LineNumber1), a2(Context, Steps, NewContext), 
	backwardProve(MRA, [step(A, [hypothesis], LineNumber1)], NewContext, Extras, [B], BoxProof), 
	ln(BoxProof, NextLineNumber), is(LineNumber2, NextLineNumber-1).
% NOT INTRODUCTION: prove ¬a by starting a nested proof and assuming a, and trying to prove contradiction
notI(MRA, Steps, Context, Extras, [n(A)|Goals], [step(n(A), [notI, LineNumber1, LineNumber2], NextLineNumber), box(BoxProof)|Proof]) :-
	backwardProve(MRA, Steps, Context, Extras, Goals, Proof), 
	ln(Proof, LineNumber1), a2(Steps, Context, NewContext), 
	backwardProve(MRA, [step(A, [hypothesis], LineNumber1)], NewContext, Extras, [falsity], BoxProof), 
	ln(BoxProof, NextLineNumber), is(LineNumber2, NextLineNumber - 1).
% FORWARD PROVE: if no further progress can be done backwards, try to break down derived formulas again
forward(MRA, Steps, Context, Extras, Goals, Proof) :- 
	length(Steps, S1), 
	forwardProve(Steps, Context, NewSteps), 
	length(NewSteps, S2), S2 > S1, !,
	backwardProve(MRA, NewSteps, Context, Extras, Goals, Proof).
% FALSITY INTRODUCTION-ELIMINATION: for each derived step of the form ¬a, prove a, then falsity then the goal
falsityIE(MRA, Steps, Context, Extras, [G|Goals], [step(G, [falsityE, LineNumber], NextLineNumber), step(falsity, [falsityI, LN1, LN2], LineNumber)| Proof]) :-
	not(G = falsity), !,
	not(m3(step(falsity, _, _), Steps, Context)),
	nth0(0, Extras, PastTries, RestExtras),
	bagof(A, (m3(step(n(A), _, LN1), Steps, Context), not(m3(step(A, _, _), Steps, Context))), [X]),
	not(m2(X, PastTries)),
	nth0(0, NewExtras, [X|PastTries], RestExtras),
	backwardProve(MRA, Steps, Context, NewExtras, Goals, RestProof),
	backwardProve(MRA, RestProof, Context, NewExtras, [X], Proof),
	ln(Proof, LineNumber),
	ln(LineNumber, NextLineNumber),
	is(LN2, LineNumber - 1).
falsityIE(MRA, Steps, Context, Extras, [_|Goals], [step(falsity, [falsityI, LN1, LN2], LineNumber)| Proof]) :-
	not(m3(step(falsity, _, _), Steps, Context)),
	nth0(0, Extras, PastTries, RestExtras),
	bagof(A, (m3(step(n(A), _, LN1), Steps, Context), not(m3(step(A, _, _), Steps, Context))), [X]),
	not(m2(X, PastTries)),
	nth0(0, NewExtras, [X|PastTries], RestExtras),
	backwardProve(MRA, Steps, Context, NewExtras, Goals, RestProof),
	backwardProve(MRA, RestProof, Context, NewExtras, [X], Proof),
	ln(Proof, LineNumber),
	is(LN2, LineNumber - 1).
% IMPLIES ELIMINATION: for each derived step of the form implies(a,b), prove a, derive b, then prove goal from/using b
impliesE(MRA, Steps, Context, Extras, Goals, Proof) :-
	nth0(1, Extras, PastTries, RestExtras),
	bagof(implies(A, B), m3(step(implies(A, B), _, LN1), Steps, Context), [implies(X, Y)]),
	not(m2(implies(X, Y), PastTries)),
	nth0(1, NewExtras, [implies(X, Y)|PastTries], RestExtras),
	backwardProve(MRA, Steps, Context, NewExtras, [X], SubProof),
	ln(SubProof, NextLine), is(LN2, NextLine - 1), !,
	backwardProve(MRA, [step(Y, [impliesE, LN1, LN2], NextLine)|SubProof], Context, NewExtras, Goals, Proof).
% PROOF BY CONTRADICTION: prove a by starting a nested proof and assuming ¬a, and trying to prove contradiction
proofByContradiction(MRA, Steps, Context, Extras, [G|Goals], [step(G, [notE, NextLineNumber], NextNextLineNumber), step(n(n(G)), [notI, LineNumber1, LineNumber2], NextLineNumber), box(BoxProof)|Proof]) :-
	not(G = falsity), not(G = n(_)),
	backwardProve(MRA, Steps, Context, Extras, Goals, Proof),
	ln(Proof, LineNumber1), a2(Steps, Context, NewContext), !,
	backwardProve(MRA, [step(n(G), [hypothesis], LineNumber1)], NewContext, Extras, [falsity], BoxProof),
	ln(BoxProof, NextLineNumber), is(LineNumber2, NextLineNumber - 1),
	ln(NextLineNumber, NextNextLineNumber).