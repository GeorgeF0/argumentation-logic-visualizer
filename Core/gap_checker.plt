% Proofs used to test predicates
% given a&b, ¬(b&c), c, prove d
proof1([step(d,[falsityE,6],7),step(falsity,[falsityI,1,5],6),step(and(b,c),[andI,3,2],5),step(a,[andE,0],4),step(b,[andE,0],3),step(c,[given],2),step(n(and(b,c)),[given],1),step(and(a,b),[given],0)]).
% given ¬(a&c), ¬(¬c&b), b, prove ¬a
proof2([step(n(a),[notI,3,12],13),box([step(falsity,[falsityE,11],12),step(falsity,[falsityI,0,10],11),step(and(a,c),[andI,3,9],10),step(c,[notE,8],9),step(n(n(c)),[notI,4,7],8),box([step(falsity,[falsityE,6],7),step(falsity,[falsityI,1,5],6),step(and(n(c),b),[andI,4,2],5),step(n(c),[hypothesis],4)]),step(a,[hypothesis],3)]),step(b,[given],2),step(n(and(n(c),b)),[given],1),step(n(and(a,c)),[given],0)]).
% given c, ¬(a&c), prove a->b
proof3([step(implies(a,b),[impliesI,2,5],6),box([step(b,[falsityE,4],5),step(falsity,[falsityI,1,3],4),step(and(a,c),[andI,2,0],3),step(a,[hypothesis],2)]),step(n(and(a,c)),[given],1),step(c,[given],0)]).
% given ¬(a&b), ¬b->c, prove a->c
proof4([step(implies(a,c),[impliesI,2,9],10),box([step(c,[check,8],9),step(c,[impliesE,1,7],8),step(n(b),[notI,3,6],7),box([step(falsity,[falsityE,5],6),step(falsity,[falsityI,0,4],5),step(and(a,b),[andI,2,3],4),step(b,[hypothesis],3)]),step(a,[hypothesis],2)]),step(implies(n(b),c),[given],1),step(n(and(a,b)),[given],0)]).
% given a, prove a
proof5([step(a,[notE,4],5),step(n(n(a)),[notI,1,3],4),box([step(falsity,[check,2],3),step(falsity,[falsityI,0,1],2),step(n(a),[hypothesis],1)]),step(a,[given],0)]).
% given a&¬b->falsity, b&c->falsity, a&b&¬c->falsity, prove ¬a
proof6([step(n(a),[notI,3,20],21),box([step(falsity,[check,19],20),step(falsity,[impliesE,0,18],19),step(and(a,n(b)),[andI,3,17],18),step(n(b),[notI,4,16],17),box([step(falsity,[check,15],16),step(falsity,[impliesE,1,14],15),step(and(b,c),[andI,4,13],14),step(c,[notE,12],13),step(n(n(c)),[notI,5,11],12),box([step(falsity,[falsityE,10],11),step(falsity,[falsityI,5,9],10),step(c,[falsityE,8],9),step(falsity,[impliesE,2,7],8),step(and(and(a,b),n(c)),[andI,6,5],7),step(and(a,b),[andI,3,4],6),step(n(c),[hypothesis],5)]),step(b,[hypothesis],4)]),step(a,[hypothesis],3)]),step(implies(and(and(a,b),n(c)),falsity),[given],2),step(implies(and(b,c),falsity),[given],1),step(implies(and(a,n(b)),falsity),[given],0)]).
% given a&b, prove a
proof7([step(a,[check,2],3),step(a,[andE,0],2),step(b,[andE,0],1),step(and(a,b),[given],0)]).
% given b&c, ¬(¬a&c), prove a&b
proof8([step(and(a,b),[andI,10,4],11),step(a,[notE,9],10),step(n(n(a)),[notI,5,8],9),box([step(falsity,[falsityE,7],8),step(falsity,[falsityI,1,6],7),step(and(n(a),c),[andI,5,2],6),step(n(a),[hypothesis],5)]),step(b,[check,3],4),step(b,[andE,0],3),step(c,[andE,0],2),step(n(and(n(a),c)),[given],1),step(and(b,c),[given],0)]).
% given c, ¬(a&c), prove ¬a
proof9([step(n(a),[notI,2,5],6),box([step(falsity,[falsityE,4],5),step(falsity,[falsityI,1,3],4),step(and(a,c),[andI,2,0],3),step(a,[hypothesis],2)]),step(n(and(a,c)),[given],1),step(c,[given],0)]).
% given c, ¬(b&c), ¬(a&¬b), prove ¬a
proof10([step(n(a),[notI,3,11],12),box([step(falsity,[falsityE,10],11),step(falsity,[falsityI,2,9],10),step(and(a,n(b)),[andI,3,8],9),step(n(b),[notI,4,7],8),box([step(falsity,[falsityE,6],7),step(falsity,[falsityI,1,5],6),step(and(b,c),[andI,4,0],5),step(b,[hypothesis],4)]),step(a,[hypothesis],3)]),step(n(and(a,n(b))),[given],2),step(n(and(b,c)),[given],1),step(c,[given],0)]).
% given c, ¬(b&c), ¬(d&c), ¬(a&¬b&¬d), prove ¬a
proof11([step(n(a),[notI,4,18],19),box([step(falsity,[falsityE,17],18),step(falsity,[falsityI,1,16],17),step(and(and(a,n(b)),n(d)),[andI,15,9],16),step(and(a,n(b)),[andI,4,14],15),step(n(b),[notI,10,13],14),box([step(falsity,[falsityE,12],13),step(falsity,[falsityI,3,11],12),step(and(b,c),[andI,10,0],11),step(b,[hypothesis],10)]),step(n(d),[notI,5,8],9),box([step(falsity,[falsityE,7],8),step(falsity,[falsityI,2,6],7),step(and(d,c),[andI,5,0],6),step(d,[hypothesis],5)]),step(a,[hypothesis],4)]),step(n(and(b,c)),[given],3),step(n(and(d,c)),[given],2),step(n(and(and(a,n(b)),n(d))),[given],1),step(c,[given],0)]).
% given d, ¬(¬c&d), ¬(¬b&c), ¬(a&b), prove ¬a
proof12([step(n(a),[notI,4,19],20),box([step(falsity,[falsityE,18],19),step(falsity,[falsityI,1,17],18),step(and(a,b),[andI,4,16],17),step(b,[notE,15],16),step(n(n(b)),[notI,5,14],15),box([step(falsity,[falsityE,13],14),step(falsity,[falsityI,2,12],13),step(and(n(b),c),[andI,5,11],12),step(c,[notE,10],11),step(n(n(c)),[notI,6,9],10),box([step(falsity,[falsityE,8],9),step(falsity,[falsityI,3,7],8),step(and(n(c),d),[andI,6,0],7),step(n(c),[hypothesis],6)]),step(n(b),[hypothesis],5)]),step(a,[hypothesis],4)]),step(n(and(n(c),d)),[given],3),step(n(and(n(b),c)),[given],2),step(n(and(a,b)),[given],1),step(d,[given],0)]).
% given c, ¬(b&c), ¬(a&¬b), prove ¬a
proof13([step(n(a),[notI,3,12],13),box([step(falsity,[falsityE,11],12),step(falsity,[falsityI,1,10],11),step(and(b,c),[andI,9,0],10),step(b,[notE,8],9),step(n(n(b)),[notI,4,7],8),box([step(falsity,[falsityE,6],7),step(falsity,[falsityI,2,5],6),step(and(a,n(b)),[andI,3,4],5),step(n(b),[hypothesis],4)]),step(a,[hypothesis],3)]),step(n(and(a,n(b))),[given],2),step(n(and(b,c)),[given],1),step(c,[given],0)]).
% given c, ¬(b&c), ¬(d&c), ¬(a&¬b&¬d), prove ¬a
proof14([step(n(a),[notI,4,20],21),box([step(falsity,[falsityE,19],20),step(falsity,[falsityI,1,18],19),step(and(b,c),[andI,17,0],18),step(b,[notE,16],17),step(n(n(b)),[notI,5,15],16),box([step(falsity,[falsityE,14],15),step(falsity,[falsityI,2,13],14),step(and(d,c),[andI,12,0],13),step(d,[notE,11],12),step(n(n(d)),[notI,6,10],11),box([step(falsity,[falsityE,9],10),step(falsity,[falsityI,3,8],9),step(and(and(a,n(b)),n(d)),[andI,7,6],8),step(and(a,n(b)),[andI,4,5],7),step(n(d),[hypothesis],6)]),step(n(b),[hypothesis],5)]),step(a,[hypothesis],4)]),step(n(and(and(a,n(b)),n(d))),[given],3),step(n(and(d,c)),[given],2),step(n(and(b,c)),[given],1),step(c,[given],0)]).
% given d, ¬(¬c&d), ¬(¬b&c), ¬(a&b), prove ¬a
proof15([step(n(a),[notI,4,17],18),box([step(falsity,[falsityE,16],17),step(falsity,[falsityI,1,15],16),step(and(n(c),d),[andI,14,0],15),step(n(c),[notI,5,13],14),box([step(falsity,[falsityE,12],13),step(falsity,[falsityI,2,11],12),step(and(n(b),c),[andI,10,5],11),step(n(b),[notI,6,9],10),box([step(falsity,[falsityE,8],9),step(falsity,[falsityI,3,7],8),step(and(a,b),[andI,4,6],7),step(b,[hypothesis],6)]),step(c,[hypothesis],5)]),step(a,[hypothesis],4)]),step(n(and(a,b)),[given],3),step(n(and(n(b),c)),[given],2),step(n(and(n(c),d)),[given],1),step(d,[given],0)]).

:- begin_tests(gap).

% restricted proofs tests
test(validRestrictedProof) :- proof1(Proof), reverse(Proof, RevProof), checkRestricted(RevProof).
test(validRestrictedProof) :- proof2(Proof), reverse(Proof, RevProof), checkRestricted(RevProof).

test(invalidRestrictedProof, [fail]) :- proof3(Proof), reverse(Proof, RevProof), checkRestricted(RevProof).
test(invalidRestrictedProof, [fail]) :- proof4(Proof), reverse(Proof, RevProof), checkRestricted(RevProof).

% RAND proofs tests
test(validRANDProof) :- proof5(Proof), reverse(Proof, RevProof), checkRAND(RevProof).
test(validRANDProof) :- proof6(Proof), reverse(Proof, RevProof), checkRAND(RevProof).

test(invalidRANDProof, [fail]) :- proof7(Proof), reverse(Proof, RevProof), checkRAND(RevProof).
test(invalidRANDProof, [fail]) :- proof8(Proof), reverse(Proof, RevProof), checkRAND(RevProof).

% GAP proofs tests
test(validGAPProof) :- proof9(Proof), checkGAP(Proof).
test(validGAPProof) :- proof10(Proof), checkGAP(Proof).
test(validGAPProof) :- proof11(Proof), checkGAP(Proof).
test(validGAPProof) :- proof12(Proof), checkGAP(Proof).

test(invalidGAPProof, [fail]) :- proof13(Proof), checkGAP(Proof).
test(invalidGAPProof, [fail]) :- proof14(Proof), checkGAP(Proof).
test(invalidGAPProof, [fail]) :- proof15(Proof), checkGAP(Proof).

:- end_tests(gap).