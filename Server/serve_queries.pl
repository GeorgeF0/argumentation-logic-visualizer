:- use_module(library(http/json)).
:- use_module(library(http/http_json)).
:- use_module(library(http/json_convert)).
:- use_module(library(http/http_error)).

registerQueries :- 
	http_handler(root(query), jsonEcho, []),
	http_handler(root(query/generateproofs), serveGenerateProofs, []),
	http_handler(root(query/checkgap), serveGAPCheck, []),
	http_handler(root(query/visualizegap), serveGAPToArg, []).

deregisterQueries :- 
	http_delete_handler(root(query)),
	http_delete_handler(root(query/generateproofs)),
	http_delete_handler(root(query/checkgap)),
	http_delete_handler(root(query/visualizegap)).

:- json_object and('1', '2') + [type=and].
:- json_object or('1', '2') + [type=or].
:- json_object implies('1', '2') + [type=implies].
:- json_object n('1') + [type=n].
:- json_object step(derivation, reason, line) + [type=step].
:- json_object box(proof) + [type=box].
:- json_object proof_query(theory, goal) + [type=proof_query].
:- json_object gap_query(proof) + [type=gap_query].
:- json_object arg_view_query(proof) + [type=arg_view_query].

jsonEcho(R) :-
	format('Content-type: text/plain~n~n'),
	http_read_json(R, J),
	json_to_prolog(J, P),
	write(P).
	
serveGenerateProofs(Request) :-
	http_read_json(Request, JSONIn),
	json_to_prolog(JSONIn, proof_query(Theory, Goal)),
	findall(X, (prove(Theory, [Goal], Y), reverseRecursive(Y, X)), PrologOut),
	prolog_to_json(PrologOut, JSONOut),
	reply_json(JSONOut).

serveGAPCheck(Request) :-
	http_read_json(Request, JSONIn),
	json_to_prolog(JSONIn, gap_query(Proof)),
	reverseRecursive(Proof, RevProof),
	(
		checkGAP(RevProof),
		prolog_to_json('approved', JSONOut);
		
		prolog_to_json('disproved', JSONOut)
	),
	reply_json(JSONOut).
	
serveGAPToArg(Request) :-
	http_read_json(Request, JSONIn),
	json_to_prolog(JSONIn, arg_view_query(Proof)),
	reverseRecursive(Proof, RevProof),
	convertGAPToArg(RevProof, PrologOut),
	prolog_to_json(PrologOut, JSONOut),
	reply_json(JSONOut).