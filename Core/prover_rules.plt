% how to run the tests:
% load the files required to run the tests (the files containing the predicates under test)
% load the tests by typing "load_test_files([])." or load this file directly
% run the tests by typing "run_tests."
% some tests take a few seconds to run

:- begin_tests(rules).

% forward rule tests

test(failI, [fail]) :- prove([and(a,b)], c, _).
test(failI, [fail]) :- prove([], a, _).

test(andE) :- prove([and(and(b, and(c, d)), a), and(e, f)], d, _).
test(andE) :- prove([and(and(b, and(c, d)), a), and(e, f)], f, _).

test(notE) :- prove([n(n(n(n(n(n(a)))))), and(n(n(e)), f)], a, _).
test(notEandE) :- prove([n(n(n(n(n(n(and(a, n(n(b)))))))))], b, _).

test(falsityI) :- prove([b, n(b)], falsity, _).
test(falsityI) :- prove([and(b, n(b))], falsity, _).
test(falsityI) :- prove([n(n(b)), n(b)], falsity, _).
test(falsityInotE) :- prove([n(n(b)), n(n(n(b)))], falsity, _).

test(failI, [fail]) :- prove([and(and(a, n(n(b))), c), n(n(and(d, e)))], f, _).

% backward rule tests

test(andI) :- prove([and(a, b), c], and(b, c), _).
test(andI) :- prove([and(a, b), c], and(and(b, c), a), _).
test(andI) :- prove([and(a, b), c], and(and(b, c), and(b,c)), _).
test(andI, [fail]) :- prove([c], and(a, b), _).
test(andI, [fail]) :- prove([and(a, b), c], and(and(b, d), and(b,c)), _).

test(falsityE) :- prove([a, n(a)], g, _).

test(impliesI) :- prove([and(a, b)], implies(a, implies(c, b)), _).
test(impliesIandI) :- prove([and(and(a, b), e)], and(implies(d, e), implies(a, implies(c, b))), _).
test(impliesIandI) :- prove([a], implies(b, and(a, a)), _).
test(impliesIandI) :- prove([a] , implies(b, implies(c, and(a, and(b,c)))), _).
test(impliesIfalsityE) :- prove([a] , implies(b, implies(n(a), g)), _).
test(impliesIfalsityE, [fail]) :- prove([a] , implies(b, implies(c, g)), _).
test(impliesIandI, [fail]) :- prove([a] , implies(b, implies(c, and(a, and(g,c)))), _).

test(notIimpliesI) :- prove([a], implies(b, n(and(a,n(b)))), _).
test(notI, [fail]) :- prove([and(a, b)], n(a), _).
test(notIimpliesI, [fail]) :- prove([a], implies(b, n(and(a,n(c)))), _).

test(falsityIE) :- prove([n(and(a,b)), b], implies(a, g), _).
test(falsityIEimpliesI) :- prove([n(and(a, implies(b, c)))], implies(and(a, c), g), _).
test(falsityIEimpliesI, [fail]) :- prove([n(and(a, implies(b, c)))], implies(and(a, d), g), _).

test(impliesEimpliesI) :- prove([implies(a, b), implies(b, c)], implies(a, c), _).
test(impliesEimpliesI) :- prove([implies(and(a, b), c), implies(a, b)], implies(a, c), _).
test(impliesEimpliesI) :- prove([and(a, d), implies(b, c)], implies(implies(a, b), c), _).
test(impliesEimpliesIfalsityIEnotI) :- prove([n(and(a, n(b))), implies(n(n(b)), b)], implies(a, b), _).
test(impliesEimpliesIfalsityIE) :- prove([implies(a, c), implies(c, and(d, b)), implies(d, n(and(b, c)))], implies(a, g), _).
test(impliesEimpliesI, [fail]) :- prove([implies(a, c), implies(c, and(d, b)), implies(d, n(and(n(b), c)))], implies(a, g), _).

test(impliesIproofByContradiction) :- prove([n(and(a, n(b)))], implies(a, b), _).
test(impliesIproofByContradiction) :- prove([implies(and(n(b), a), falsity)], implies(a, b), _).

% other tests

test(pierceLaw) :- prove([], implies(implies(implies(p, q), p), p), _).

% examples from the AL paper

test(example1) :- prove([implies(a, implies(b, c))], implies(and(a,b), c), _).
test(example1, [blocked('orI unimplimented')]) :- prove([n(or(a, b))], n(a), _).
test(example2) :- prove([implies(a, falsity), implies(n(a), falsity)], falsity, _).
test(example2) :- prove([a, n(a)], falsity, _).
test(example4, [fail]) :- prove([implies(and(a, b), falsity), implies(n(b), falsity)], falsity, _).
test(example4) :- prove([implies(and(a, b), falsity), implies(n(b), falsity)], implies(n(b), falsity), _).
test(example4) :- prove([implies(and(a, b), falsity), implies(n(b), falsity)], implies(a, falsity), _).
test(example6, [fail]) :- prove([implies(and(a, n(b)), falsity), implies(and(b, c), falsity), implies(and(and(a, b), n(c)), falsity)], falsity, _).
test(example6) :- prove([implies(and(a, n(b)), falsity), implies(and(b, c), falsity), implies(and(and(a, b), n(c)), falsity)], implies(a, falsity), _).
test(example7, [blocked('rules unimplimented')]) :- prove([n(or(b, n(b)))], falsity, _).
test(example7) :- prove([and(b, n(b))], falsity, _).
test(example8) :- prove([implies(and(a, n(b)), falsity), implies(and(b, c), falsity), implies(and(and(a, b), n(c)), falsity)], n(a), _).
test(example10) :- prove([n(and(a, b)), n(and(n(a), c)), b, c], n(d), _).
test(example11) :- prove([n(and(a, b)), n(and(c, n(b))), c], n(a), _).

:- end_tests(rules).