% PRETTY_PRINT: predicates used to pretty print a proof to the output

% Pretty print prove
prettyProve(Givens, Goal) :- pprove(Givens, Goal). % alias
pprove(Givens, Goal) :- prove(Givens, Goal, Proof), prune(Proof, PrunedProof), prettyPrint(PrunedProof, '').
prettyPrint([], _) :- !.
prettyPrint([Step|Proof], Indent) :- prettyPrint(Proof, Indent), prettyPrintStep(Step, Indent), !.
prettyPrintStep(step(Formula, Reason, LineNumber), Indent) :- 
	prettyPrintFormula(Formula, PrettyFormula), 
	format('~w~w~20|~w~40|~d~60|~n', [Indent, PrettyFormula, Reason, LineNumber]), !.
prettyPrintStep(box(BoxProof), Indent) :-
	atomic_concat(Indent, '>', NewIndent),
	prettyPrint(BoxProof, NewIndent).
prettyPrintFormula(and(A, B), String) :- prettyPrintFormula(A, PrettyA), prettyPrintFormula(B, PrettyB), swritef(String, '(%w&%w)', [PrettyA, PrettyB]).
prettyPrintFormula(or(A, B), String) :- prettyPrintFormula(A, PrettyA), prettyPrintFormula(B, PrettyB), swritef(String, '(%w|%w)', [PrettyA, PrettyB]).
prettyPrintFormula(n(A), String) :- prettyPrintFormula(A, PrettyA), swritef(String, '~(%w)', [PrettyA]).
prettyPrintFormula(implies(A, B), String) :- prettyPrintFormula(A, PrettyA), prettyPrintFormula(B, PrettyB), swritef(String, '(%w->%w)', [PrettyA, PrettyB]).
prettyPrintFormula(A, A).
