:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_files)).

init :- conf(document_root, D), http_handler(root(.), http_reply_from_files(D, []), [prefix]), registerQueries.
fin :- http_delete_handler(root(.)), deregisterQueries.
startServer :- conf(port, P), http_server(http_dispatch, [port(P)]).
stopServer :- conf(port, P), http_stop_server(P, []).

boot :- init, startServer.
shutdown :- fin, stopServer.