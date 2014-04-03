% Make prolog not abbreviate lists and long results
:- set_prolog_flag(toplevel_print_options, [quoted(true), portray(true)]).
% Load all modules
:-
	[utils],
	[prover_rules],
	[prune],
	[pretty_print],
	[gap_checker],
	[gap_to_arg].