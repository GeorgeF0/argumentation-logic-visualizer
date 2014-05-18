//navbar button actions

$("#importclipboardconfirm").click(function(){
    var pastedText = $("#importclipboardtext").val();
    try {
        $("#importclipboardfeedback").removeClass("has-error");
        var parsedText = JSON.parse(pastedText);
        addAllToClipboard(parsedText);
        $("#importclipboardtext").val("");
        $("#importclipboardmodal").modal("hide");
    } catch (e){
        $("#importclipboardfeedback").addClass("has-error");
    }
});

$("#exportbtn").click(function() {
    exportClipboard(clipboardcontents);
});

//clipboard

$("#clearclipboardconfirm").click(function() {
    clearClipboard();
});

$("#exportbtn2").click(function() {
    exportClipboard(clipboardcontents);
});

var clipboardcontents = [];

function addAllToClipboard(items){
    clipboardcontents = clipboardcontents.concat(items);
    backupClipboard();
    rerenderClipboard();
}

function addToClipboard(item){
    clipboardcontents.push(item);
    backupClipboard();
    rerenderClipboard();
}

function removeFromClipboard(itemID){
    clipboardcontents.splice(itemID, 1);
    backupClipboard();
    rerenderClipboard();
}

function rerenderClipboard(){
    var clipboard = $("#clipboard");
    clipboard.html(generateClipboardHTML());
    drawArgThumbnails();
}

function generateClipboardHTML(){
    var clipboardHTML = "";
    for (var i = 0; i < clipboardcontents.length; i++){
        var item = clipboardcontents[i];
        clipboardHTML += render("clip" + i, item);
    }
    return clipboardHTML;
}

function render(id, item){
    switch (item.type){
        case "proof":
            return makeProofThumbnail(id, printPrologJSONProof(item[1]));
            break;
        case "gapproved":
            return makeGAPThumbnail(id, printPrologJSONProof(item[1]));
            break;
        case "arg":
            return makeArgThumbnail(id, printPrologJSONArg(item[1]), printPrologJSONFormulaSet(item[2]));
            break;
    }
}

function clearClipboard(){
    clipboardcontents = [];
    backupClipboard();
    rerenderClipboard();
}

function drag(event){
    event.dataTransfer.setData("Text", event.target.id);
}

function deleteDrop(event){
    var match = event.dataTransfer.getData("Text").match(/clip(\d+)/);
    if (match){
        var id = match[1];
        removeFromClipboard(id);
    } else {
        console.log("attempted to delete object not belonging to the clipboard!");
    }
}

function exportDrop(event){
    var match = event.dataTransfer.getData("Text").match(/clip(\d+)/);
    if (match){
        var id = match[1];
        exportClipboard([clipboardcontents[id]]);
    } else {
        console.log("attempted to delete object not belonging to the clipboard!");
    }
}

function allowDrop(event){
    event.preventDefault();
}

function addProofDrop(event){
    var objid = event.dataTransfer.getData("Text");
    var match;
    if (match = objid.match(/proof(\d+)/)){
        var id = match[1];
        var proof = generatedProofs[id];
        addToClipboard(proof);
    } else if (objid.match(/proofunderconstruction/)) {
        addToClipboard({type: "proof", 1: proofUnderConstruction});
    } else if (objid.match(/gapproved/)) {
        addToClipboard(gapproved);
    } else if (objid.match(/argviz/)) {
        addToClipboard(proofToBeVisualized);
    } else if (objid.match(/gapviz/)) {
        addToClipboard(proofToBeExtracted);
    } else if (objid.match(/argunderconstructionthumb/)) {
        if (argconstructioncomplete){
            addToClipboard(constructedArgument);
        } 
    } else {
        console.log("attempted to add invalid object to the clipboard!");
    }
}

function exportClipboard(clipboard){
    var newWindow = window.open();
    var newDocument = newWindow.document;
    newDocument.write(JSON.stringify(clipboard));
    newDocument.close();
}

//generate proofs tab

var generatedProofs = [];

$("#generateproofsbtn").click(function() {
    generateProofs();
});

function generateProofsCallback(data){
    generatedProofs = [];
    var placeholderHTML = "";
    for (var i = 0; i < data.length; i++){
        var proof = data[i];
        placeholderHTML += makeProofThumbnail("proof" + i, printPrologJSONProof(proof));
        generatedProofs.push({type:"proof", 1:proof});
    }
    var placeholder = $("#generatedproofsplaceholder");
    placeholder.html(placeholderHTML);
}

function generateProofs(){
    $("#generateprooftheoryfeedback").removeClass("has-error");
    $("#generateproofgoalfeedback").removeClass("has-error");
    var theoryInput = $("#generateprooftheory").val();
    var goalInput = $("#generateproofgoal").val();
    var hasError = false;
    try {
        var theory;
        if (theoryInput.trim() != ""){
            theory = parser.parse(theoryInput);
            if (theory[0] == "list"){
                theory = flattenParsedList(theory[1]);
                for (var i = 0; i < theory.length; i++){
                    theory[i] = parsedFormulaToPrologJSON(theory[i]);
                }
            } else if (theory[0] == "formula"){
                theory = [parsedFormulaToPrologJSON(theory[1])];
            } else {
                throw "wrong type of input!";
            }
        } else {
            theory = [];
        }
    } catch (e){
        $("#generateprooftheoryfeedback").addClass("has-error");
        console.log(e);
        hasError = true;
    }
    try {
        var goal = parser.parse(goalInput);
        if (goal[0] == "formula"){
            goal = parsedFormulaToPrologJSON(goal[1]);
        } else {
            throw "wrong type of input!";
        }
    } catch (e){
        $("#generateproofgoalfeedback").addClass("has-error");
        console.log(e);
        hasError = true;
    }
    if (hasError) return;
    var proofQuery = {type:"proof_query", theory:theory, goal:goal};
    $.ajax("query/generateproofs", {
        type: "POST",
        contentType:"application/json",
        data: JSON.stringify(proofQuery),
        success: generateProofsCallback});
}

//build proof tab

$("#buildproofbtn").click(function() {
    buildProof();
});

var targetGoal;
var proofUnderConstruction = [];
var currentLevel = 0;
var proofUnderConstructionLength = 0;

function buildProof(){
    $("#buildprooftheoryfeedback").removeClass("has-error");
    $("#buildproofgoalfeedback").removeClass("has-error");
    var theoryInput = $("#buildprooftheory").val();
    var goalInput = $("#buildproofgoal").val();
    var hasError = false;
    try {
        var theory;
        if (theoryInput.trim() != ""){
            theory = parser.parse(theoryInput);
            if (theory[0] == "list"){
                theory = flattenParsedList(theory[1]);
                for (var i = 0; i < theory.length; i++){
                    theory[i] = parsedFormulaToPrologJSON(theory[i]);
                }
            } else if (theory[0] == "formula"){
                theory = [parsedFormulaToPrologJSON(theory[1])];
            } else {
                throw "wrong type of input!";
            }
        } else {
            theory = [];
        }
    } catch (e){
        $("#buildprooftheoryfeedback").addClass("has-error");
        console.log(e);
        hasError = true;
    }
    try {
        var goal = parser.parse(goalInput);
        if (goal[0] == "formula"){
            goal = parsedFormulaToPrologJSON(goal[1]);
        } else {
            throw "wrong type of input!";
        }
    } catch (e){
        $("#buildproofgoalfeedback").addClass("has-error");
        console.log(e);
        hasError = true;
    }
    if (hasError) return;
    targetGoal = goal;
    proofUnderConstruction = setUpGivens(theory);
    currentLevel = 0;
    proofUnderConstructionLength = proofUnderConstruction.length;
    $("#buildproofcommandinput").removeAttr("disabled");
    $("#proofunderconstruction").removeAttr("draggable");
    $("#proofunderconstruction").removeAttr("ondragstart");
    rerenderProofUnderConstruction();
}

function rerenderProofUnderConstruction(){
    var proof = printPrologJSONProof(proofUnderConstruction);
    $("#proofunderconstruction").html(proof);
}

$("#buildproofcommandinput").keyup(function (e) {
    $("#buildproofcommandinputfeedback").removeClass("has-error");
    if (e.keyCode == 13 /*Enter key*/) {
        var hasError = false;
        try{
            var command = parser.parse($("#buildproofcommandinput").val());
            if (command[0] != "command"){
                throw "wrong type of input!";
            }
        } catch (e){
            $("#buildproofcommandinputfeedback").addClass("has-error");
            console.log(e);
            hasError = true;
        }
        if (hasError) return;
        command = command[1];
        switch (command[0]){
            case "--":
                deleteLastSteps(1);
                break;
            case "-":
                deleteLastSteps(command[1]);
                break;
            default:
                handleStepCommand(command);
                break;
        }
        rerenderProofUnderConstruction();
        var lastItem = proofUnderConstruction[proofUnderConstruction.length - 1];
        if (lastItem.type == "step" && formulasAreEqual(lastItem.derivation, targetGoal)){
            $("#buildproofcommandinput").attr("disabled", "");
            $("#proofunderconstruction").attr("draggable", "true");
            $("#proofunderconstruction").attr("ondragstart", "drag(event)");
        }
    }
});

function deleteLastSteps(stepsCount){
    for (var i = 0; i < stepsCount; i++){
        var currentContext = proofUnderConstruction;
        var outterContext = proofUnderConstruction;
        for (var j = 0; j < currentLevel; j++){
            outterContext = currentContext;
            currentContext = currentContext[currentContext.length - 1].proof;
        }
        var step = currentContext.pop();
        if (currentContext.length == 0){
            outterContext.pop();
            currentLevel--;
        } else if (step.reason[0] == "notI" || step.reason[0] == "impliesI"){
            currentLevel++;
        }
        proofUnderConstructionLength--;
    }
    $("#buildproofcommandinput").val("");
}

function handleStepCommand(command){
    var hasError = false;
    var c = parsedCommandToPrologJSON(command, proofUnderConstructionLength);
    if (generalValidation(c)){
        switch (c.reason[0]) {
            case "hypothesis":
                makeBox();
                currentLevel++;
                break;
            case "check":
                if (!formulasAreEqual(c.derivation, getFormula(c.reason[1]))){
                    hasError = true;
                }
                break;
            case "falsityE":
                if (getFormula(c.reason[1]) != "falsity"){
                    hasError = true;
                }
                break;
            case "falsityI":
                var f1 = getFormula(c.reason[1]);
                var f2 = getFormula(c.reason[2]);
                if (c.derivation != "falsity" || !negationOf(f1, f2)){
                    hasError = true;
                }
                break;
            case "notE":
                var f = getFormula(c.reason[1]);
                if (!doubleNegationOf(f, c.derivation)){
                    hasError = true;
                }
                break;
            case "notI":
                var f1 = getFormula(c.reason[1]);
                var r1 = getReason(c.reason[1]);
                var f2 = getFormula(c.reason[2]);
                var i1 = getCurrentBox();
                var b1 = negationOf(c.derivation, f1);
                var b2 = r1 == "hypothesis";
                var b3 = f2 == "falsity";
                var b4 = containsFormulas(i1, [c.reason[1], c.reason[2]]);
                var b5 = i1[i1.length - 1].line == c.reason[2];
                if (b1 && b2 && b3 && b4 && b5){
                    currentLevel--;
                } else {
                    hasError = true;
                }
                break;
            case "impliesE":
                var f1 = getFormula(c.reason[1]);
                var f2 = getFormula(c.reason[2]);
                if (!leftChildOf(f2, f1) || !formulasAreEqual(c.derivation, f2)){
                    hasError = true;
                }
                break;
            case "impliesI":
                var f1 = getFormula(c.reason[1]);
                var r1 = getReason(c.reason[1]);
                var f2 = getFormula(c.reason[2]);
                var i1 = getCurrentBox();
                var b1 = formulasAreEqual(leftChildOf(c.derivation), f1);
                var b2 = r1 == "hypothesis";
                var b3 = formulasAreEqual(rightChildOf(c.derivation), f2);
                var b4 = containsFormulas(i1, [c.reason[1], c.reason[2]]);
                var b5 = i1[i1.length - 1].line == c.reason[2];
                var b6 = c.derivation.type == "implies";
                if (b1 && b2 && b3 && b4 && b5 && b6){
                    currentLevel--;
                } else {
                    hasError = true;
                }
                break;
            case "andI":
                var f1 = getFormula(c.reason[1]);
                var f2 = getFormula(c.reason[2]);
                var b1 = formulasAreEqual(leftChildOf(c.derivation), f1);
                var b2 = formulasAreEqual(rightChildOf(c.derivation), f2);
                var b3 = c.derivation.type == "and";
                if (!(b1 && b2 && b3)){
                    hasError = true;
                }
                break;
            case "andE":
                var f1 = getFormula(c.reason[1]);
                var b1 = f1.type == "and";
                var b2 = b1 && formulasAreEqual(leftChildOf(f1), c.derivation);
                var b3 = b1 && formulasAreEqual(rightChildOf(f1), c.derivation);
                if (!(b1 && (b2 || b3))){
                    hasError = true;
                }
                break;
            default:
                throw "unhandled command!";
        }
    } else {
        hasError = true;
    }
    if (hasError){
        $("#buildproofcommandinputfeedback").addClass("has-error");
    } else {
        addStep(c);
        $("#buildproofcommandinput").val("");
    }
}

function containsFormulas(context, lines){
    var formulaFound = false;
    for (var i = 0; i < lines.length; i++){
        var line = lines[i];
        formulaFound = false;
        for (var j = 0; j < context.length; j++){
            var item = context[j];
            if (item.type == "step" && line == item.line){
                formulaFound = true;
                break;
            }
        }
        if (!formulaFound) return false;
    }
    return true;
}

function getCurrentBox(){
    var context = proofUnderConstruction;
    for (var i = 0; i < currentLevel; i++){
        context = context[context.length - 1].proof;
    }
    return context;
}

function leftChildOf(formula){
    return formula[1];
}

function rightChildOf(formula){
    return formula[2];
}

function negationOf(f1, f2){
    return (f1.type == "n" && formulasAreEqual(f1[1], f2));
}

function doubleNegationOf(f1, f2){
    return (f1.type == "n" && negationOf(f1[1], f2));
}

function getFormula(line){
    return getStep(line).derivation;
}

function getReason(line){
    return getStep(line).reason;
}

function getStep(line){
    var currentBox = proofUnderConstruction;
    for (var i = 0; i < currentBox.length; i++){
        var item = currentBox[i];
        if (item.type == "step" && item.line == line) return item;
        if (item.type == "box"){
            var nextItem = currentBox[i+1];
            if (!nextItem || nextItem.line > line){
                i = - 1;
                currentBox = item.proof;
            }
        }
    }
    throw "requested step not found! (line: " + line;
}

function formulasAreEqual(f1, f2){
    if (f1 == f2) return true;
    if (f1.type && f2.type && f1.type == f2.type){
        for (var i = 1; i <= operatorOperandsCount[f1.type]; i++){
            if (!formulasAreEqual(f1[i], f2[i])) return false;
        }
        return true;
    }
    return false;
}

function makeBox(){
    addStep({type:"box", proof:[]});
    proofUnderConstructionLength--;
}

function addStep(step){
    var level = currentLevel;
    var context = proofUnderConstruction;
    for (var i = 0; i < level; i++){
        context = context[context.length - 1].proof;
    }
    context.push(step);
    proofUnderConstructionLength++;
}

function getFormulaLevel(line){
    var currentBox = proofUnderConstruction;
    var thisLevel = 0;
    for (var i = 0; i < currentBox.length; i++){
        var item = currentBox[i];
        if (item.type == "step" && item.line == line) return thisLevel;
        if (item.type == "box"){
            var nextItem = currentBox[i+1];
            if (!nextItem || nextItem.line > line){
                i = - 1;
                currentBox = item.proof;
                thisLevel++;
            }
        }
    }
    throw "requested step not found! (line: " + line;
}

function formulaInSameBasin(line){
    var currentBox = proofUnderConstruction;
    for (var i = 0; i < currentBox.length; i++){
        var item = currentBox[i];
        if (item.type == "step" && item.line == line) return true;
        if (i == currentBox.length -1 && item.type == "box"){
            i = - 1;
            currentBox = item.proof;
        }
    }
    return false;
}

function generalValidation(command){
    for (var i = 1; i < command.reason.length; i++){
        if (command.reason[i] >= proofUnderConstructionLength) return false;
    }

    if (command.derivation.type != "impliesI" && command.derivation.type != "notI"){
        for (var i = 1; i < command.reason.length; i++){
            if (!formulaInSameBasin(command.reason[i])) return false;
        }
    }
    return true;
}

//gap check tab

gapproved = null;

function gapProofDrop(event){
    var match = event.dataTransfer.getData("Text").match(/clip(\d+)/);
    if (match){
        var id = match[1];
        var proof = clipboardcontents[id];
        if (proof.type == "proof"){
            gapproved = proof;
            $("#gapdroparea").html(makeProofThumbnail("invalid", printPrologJSONProof(gapproved[1])));
        }
    } else {
        console.log("attempted to check GAP of a non-proof object!");
    }
}

$("#checkgapbtn").click(function() {
    checkGAPProperty();
});

function checkGAPProperty(){
    if (gapproved && gapproved.type == "proof"){
        var gapQuery = {type:"gap_query", proof:gapproved[1]};
        $.ajax("query/checkgap", {
            type: "POST",
            contentType:"application/json",
            data: JSON.stringify(gapQuery),
            success: checkGAPPropertyCallback});
    }
}

function checkGAPPropertyCallback(data){
    if (data == "approved"){
        $("#gapdroparea").html(makeGAPThumbnail("gapproved", printPrologJSONProof(gapproved[1])));
        gapproved.type = "gapproved";
        rerenderClipboard();
    }
}

// arg view (visualize gap proof) tab

proofToBeVisualized = null;

function argProofDrop(event){
    var match = event.dataTransfer.getData("Text").match(/clip(\d+)/);
    if (match){
        var id = match[1];
        var proof = clipboardcontents[id];
        if (proof.type == "gapproved"){
            proofToBeVisualized = proof;
            $("#argdroparea").html(makeGAPThumbnail("invalid", printPrologJSONProof(proofToBeVisualized[1])));
            $("#argdragarea").html(makeEmptyThumbnail());
        }
    } else {
        console.log("attempted to visualize a non-(gap-proof) object!");
    }
}

$("#visualizeargbtn").click(function() {
    visualizeGAPProof();
});

function visualizeGAPProof(){
    if (proofToBeVisualized && proofToBeVisualized.type == "gapproved"){
        var argViewQuery = {type:"arg_view_query", proof:proofToBeVisualized[1]};
        $.ajax("query/visualizegap", {
            type: "POST",
            contentType:"application/json",
            data: JSON.stringify(argViewQuery),
            success: visualizeGAPProofCallback});
    }
}

function visualizeGAPProofCallback(data){
    var d3NodeData = printPrologJSONArg(data[1]);
    proofToBeVisualized = data;
    $("#argdragarea").html(makeArgThumbnail("argviz", d3NodeData, printPrologJSONFormulaSet(data[2]), "argvizdrawarea"));
    drawArgThumbnails();
}

// gap view (extract gap proof) tab

proofToBeExtracted = null;

function extrGapProofDrop(event){
    var match = event.dataTransfer.getData("Text").match(/clip(\d+)/);
    if (match){
        var id = match[1];
        var proof = clipboardcontents[id];
        if (proof.type == "arg"){
            proofToBeExtracted = proof;
            var d3NodeData = printPrologJSONArg(proof[1]);
            $("#extrgapdroparea").html(makeArgThumbnail("invalid2", d3NodeData, printPrologJSONFormulaSet(proof[2])));
            $("#extrgapdragarea").html(makeEmptyThumbnail());
            drawArgThumbnails();
        }
    } else {
        console.log("attempted to extract from a non-arg object!");
    }
}

$("#extractgapbtn").click(function() {
    extractGAPProof();
});

function extractGAPProof(){
    if (proofToBeExtracted && proofToBeExtracted.type == "arg"){
        var gapViewQuery = {type:"gap_view_query", arg:proofToBeExtracted[1], theory:proofToBeExtracted[2]};
        $.ajax("query/visualizearg", {
            type: "POST",
            contentType:"application/json",
            data: JSON.stringify(gapViewQuery),
            success: extractGAPProofCallback});
    }
}

function extractGAPProofCallback(data){
    proofToBeExtracted = {type:"gapproved", 1:data};
    $("#extrgapdragarea").html(makeGAPThumbnail("gapviz", printPrologJSONProof(data)));
}

// build argument tab

$("#buildargbtn").click(function() {
    buildArgument();
});

var argUnderConstruction = [[],[]];
var argTheory = null;
var argGoal = null;
var argAttack = null;
var nextArgumentPrologID = 1;
var attackedNode = null;
var attacksLeft = 1;
var argconstructioncomplete = false;
var constructedArgument = null;

function buildArgument(){
    $("#buildargtheoryfeedback").removeClass("has-error");
    $("#buildarggoalfeedback").removeClass("has-error");
    var theoryInput = $("#buildargtheory").val();
    var goalInput = $("#buildarggoal").val();
    var hasError = false;
    try {
        var theory;
        if (theoryInput.trim() != ""){
            theory = parser.parse(theoryInput);
            if (theory[0] == "list"){
                theory = flattenParsedList(theory[1]);
                for (var i = 0; i < theory.length; i++){
                    theory[i] = parsedFormulaToPrologJSON(theory[i]);
                }
            } else if (theory[0] == "formula"){
                theory = [parsedFormulaToPrologJSON(theory[1])];
            } else {
                throw "wrong type of input!";
            }
        } else {
            theory = [];
        }
    } catch (e){
        $("#buildargtheoryfeedback").addClass("has-error");
        console.log(e);
        hasError = true;
    }
    try {
        var goal = parser.parse(goalInput);
        if (goal[0] == "formula"){
            goal = parsedFormulaToPrologJSON(goal[1]);
            if (!formulaIsAtom(goal, true)){
                throw "goal must be a (negated) atom!";
            }
        } else {
            throw "wrong type of input!";
        }
    } catch (e){
        $("#buildarggoalfeedback").addClass("has-error");
        console.log(e);
        hasError = true;
    }
    if (hasError) return;

    argTheory = theory;
    argGoal = goal;
    var provableQuery = {type:"provable_query", theory:theory, goal:"falsity", mra:"no"};
    $.ajax("query/provable", {
        type: "POST",
        contentType:"application/json",
        data: JSON.stringify(provableQuery),
        success: buildArgumentCallback});
}

function buildArgumentCallback(data){
    if (data == "yes"){
        $("#buildargtheoryfeedback").addClass("has-error");
    } else {
        attacksLeft = 1;
        argUnderConstruction = [[],[]];
        argAttack = null;
        nextArgumentPrologID = 1;
        attackedNode = null;
        attacksLeft = 1;
        argconstructioncomplete = false;
        constructedArgument = null;
        $("#buildargattackinput").removeAttr("disabled");
        $("#argunderconstruction").removeAttr("draggable");
        $("#argunderconstruction").removeAttr("ondragstart");
        addArgumentToConstruction([argGoal]);
        var d3NodeData = printPrologJSONArg(argUnderConstruction);
        var theory = printPrologJSONFormulaSet(argTheory);
        $("#argunderconstruction").html(makeArgThumbnail("argunderconstructionthumb", d3NodeData, theory));
        drawArgThumbnails();
    }
}

function addArgumentToConstruction(arg){
    argUnderConstruction[0].push([arg, nextArgumentPrologID]);
    return nextArgumentPrologID++;
}

$("#buildargattackinput").keyup(function (e) {
    $("#buildargattackinputfeedback").removeClass("has-error");
    if (e.keyCode == 13 /*Enter key*/) {
        var hasError = false;
        try{
            var attack = parser.parse($("#buildargattackinput").val());
            if (attack[0] != "formula" && attack[0] != "list"){
                throw "wrong type of input!";
            }
        } catch (e){
            if ($("#buildargattackinput").val() != ""){
                $("#buildargattackinputfeedback").addClass("has-error");
                console.log(e);
                hasError = true;  
            }
        }
        if (hasError) return;
        if ($("#buildargattackinput").val() == ""){
            attack = [];
        } else {
            attack = attack[0] == "formula"? [attack[1]]:flattenParsedList(attack[1]);

        }
        for (var i = 0; i < attack.length; i++){
            attack[i] = parsedFormulaToPrologJSON(attack[i]);
            if (!formulaIsAtom(attack[i], true)){
                hasError = true;
                $("#buildargattackinputfeedback").addClass("has-error");
                break;
            }
        }
        if (hasError) return;
        argAttack = attack;
        handleAttack(printPrologJSONFormulaSet(attack));
    }
});

function handleAttack(attack){
    var d3NodeData = printPrologJSONArg(argUnderConstruction);
    var theory = printPrologJSONFormulaSet(argTheory);
    $("#argunderconstruction").html(makeArgThumbnail("argunderconstructionthumb", d3NodeData, theory, null, attack));
    drawArgThumbnails();
}

function registerAttack(attackedNodeID){
    attackedNode = attackedNodeID;
    var node = argUnderConstruction[0].find(function(node){return node[1] == attackedNodeID;})[0];
    var extraTheory = node.concat(argAttack);
    var provableQuery = {type:"provable_query", theory:argTheory.concat(extraTheory), goal:"falsity", mra:"no"};
    $.ajax("query/provable", {
        type: "POST",
        contentType:"application/json",
        data: JSON.stringify(provableQuery),
        success: registerAttackCallback1});
}

function registerAttackCallback1(data){
    if (data == "yes"){
        var provableQuery = {type:"provable_query", theory:argTheory.concat(argAttack), goal:"falsity", mra:"yes"};
        $.ajax("query/provable", {
            type: "POST",
            contentType:"application/json",
            data: JSON.stringify(provableQuery),
            success: registerAttackCallback2});
    } else if (data == "no"){
        $("#buildargattackinputfeedback").addClass("has-error");
        rerenderArgUnderConstruction();
        console.log("provided attack does not contradict targeted defense");
    }
}

function registerAttackCallback2(data){
    if (data == "no"){
        var attackNode = addArgumentAndAttackToConstruction(argAttack, attackedNode);
        generateDefenses(argAttack, attackNode);
    } else if (data == "yes"){
        $("#buildargattackinputfeedback").addClass("has-error");
        rerenderArgUnderConstruction();
        console.log("provided attack is directly inconsistent");
    }
}

function addArgumentAndAttackToConstruction(attack, attackedNode){
    var attackNode = addArgumentToConstruction(attack);
    argUnderConstruction[1].push([attackNode, attackedNode]);
    rerenderArgUnderConstruction();
    return attackNode;
}

function rerenderArgUnderConstruction(){
    var d3NodeData = printPrologJSONArg(argUnderConstruction);
    var theory = printPrologJSONFormulaSet(argTheory);
    $("#argunderconstruction").html(makeArgThumbnail("argunderconstructionthumb", d3NodeData, theory));
    drawArgThumbnails();
}

function generateDefenses(attack, attackNode){
    var parentDefenses = getParentDefenses(attackNode);
    attacksLeft--;
    if (attackSubsetOfDefenses(attack, parentDefenses)){
        if (attacksLeft == 0){
            completeArgument();
        }
    } else {
        for (var i = 0; i < attack.length; i++){
            var defense = generateDefense(attack[i]);
            addArgumentAndAttackToConstruction([defense], attackNode);
        }
        attacksLeft+= attack.length;
    }
}

function getParentDefenses(attackNode){
    var parentDefenses = [];
    var defenseNode = argUnderConstruction[1].find(function(node){return node[0] == attackNode;})[1];
    var defense = argUnderConstruction[0].find(function(node){return node[1] == defenseNode;})[0];
    parentDefenses.push(defense[0]);
    while (defenseNode != 1){
        attackNode = argUnderConstruction[1].find(function(node){return node[0] == defenseNode;})[1];
        defenseNode = argUnderConstruction[1].find(function(node){return node[0] == attackNode;})[1];
        defense = argUnderConstruction[0].find(function(node){return node[1] == defenseNode;})[0];
        parentDefenses.push(defense[0]);
    }
    return parentDefenses;
}

function attackSubsetOfDefenses(attack, parentDefenses){
    for (var i = 0; i < attack.length; i++){
        var attackComponent = attack[i];
        for (var j = 0; j < parentDefenses.length; j++){
            var defense = parentDefenses[j];
            if (formulasAreEqual(attackComponent, defense)){
                break;
            }
        }
        if (j == parentDefenses.length) return false;
    }
    return true;
}

function generateDefense(attack){
    if (typeof attack == "string"){
        return {type: "n", 1: attack};
    } else if (attack.type && attack.type == "n"){
        return attack[1];
    } else {
        throw "not sure what to expect here!" + attack;
    }
}

function completeArgument(){
    $("#buildargattackinput").attr("disabled", "");
    argconstructioncomplete = true;
    constructedArgument = {type:"arg", 1: argUnderConstruction, 2:argTheory};
}

//utilities

function formulaIsAtom(input, negated){
    return (typeof input == "string") || negated && (input.type == "n") && typeof input[1] == "string";
}

function flattenParsedList(input){
    var flatTheory = [];
    while(input.length == 2){
        flatTheory.push(input[1]);
        input = input[0];
    }
    flatTheory.push(input[0]);
    return flatTheory.reverse();
}

function parsedCommandToPrologJSON(input, line){
    var output = {type:"step"};
    output.derivation = parsedFormulaToPrologJSON(input[0]);
    output.reason = input[1];
    output.line = line;
    return output;
}

function parsedFormulaToPrologJSON(input){
    if (!(input instanceof Array)) return input;
    var output = {};
    output.type = input[0];
    for (var i = 1; i < input.length; i++){
        var param = input[i];
        param = parsedFormulaToPrologJSON(param);
        output[i] = param;
    }
    return output;
}

var operatorPrecedence = {
    "n":0,
    "and":1,
    "or":2,
    "implies":3
}

var operatorOperandsCount = {
    "n":1,
    "and":2,
    "or":2,
    "implies":2
}

var operatorShorthand = {
    "n":"!",
    "and":"&",
    "or":"|",
    "implies":"->"
}

function printPrologJSONFormula(input){
    if (!(input instanceof Object)) return input;
    var output = "";
    var operator = operatorShorthand[input.type];
    var precedence = operatorPrecedence[input.type];
    switch (operatorOperandsCount[input.type]){
        case 1:
            if (input[1] instanceof Object){
                var childPrecedence = operatorPrecedence[input[1].type];
                if (precedence >= childPrecedence){
                    output += operator + printPrologJSONFormula(input[1]);
                } else {
                    output += operator + "(" + printPrologJSONFormula(input[1]) + ")";
                }
            } else {
                output += operator + input[1];
            }
            break;
        case 2:
            if (input[1] instanceof Object){
                var childPrecedence = operatorPrecedence[input[1].type];
                if (precedence > childPrecedence){
                    output += printPrologJSONFormula(input[1]);
                } else {
                    output += "(" + printPrologJSONFormula(input[1]) + ")";
                }
            } else {
                output += input[1];
            }
            output += operator;
            if (input[2] instanceof Object){
                var childPrecedence = operatorPrecedence[input[2].type];
                if (precedence > childPrecedence){
                    output += printPrologJSONFormula(input[2]);
                } else {
                    output += "(" + printPrologJSONFormula(input[2]) + ")";
                }
            } else {
                output += input[2];
            }
            break;
    }
    return output;
}

function printPrologJSONProof(input, level){
    var tab = "&emsp;";
    function indent(amount){
        var indent = "";
        for (var i = 0; i < amount; i++){
            indent += tab;
        }
        return indent;
    }
    var output = "";
    level = level || 0;
    for (var i = 0; i < input.length; i++){
        var item = input[i];
        if (item.type == "step"){
            output += indent(level) + item.line + indent(2) + printPrologJSONFormula(item.derivation) + indent(2) + printPrologJSONReason(item.reason) + "<br>";
        } else if (item.type == "box"){
            output += printPrologJSONProof(item.proof, level + 1);
        }
    }
    return output;
}

var reasonShorthand = {
    "andI":"&I",
    "andE":"&E",
    "orI":"|I",
    "orE":"|E",
    "notI":"!I",
    "notE":"!E",
    "impliesI":"->I",
    "impliesE":"->E",
    "falsityI":"_I",
    "falsityE":"_E",
    "given":"given",
    "hypothesis":"hypothesis",
    "check":"check"
}

function printPrologJSONReason(input){
    var output = reasonShorthand[input[0]];
    switch (input.length){
        case 2:
            output += "(" + input[1] + ")";
            break;
        case 3:
            output += "(" + input[1] + "," + input[2] + ")";
            break;
    }
    return output;
}

function setUpGivens(theory){
    var givens = [];
    for (var i = 0; i < theory.length; i++){
        givens.push({type:"step", derivation:theory[i], reason:["given"], line:i});
    }
    return givens;
}

function printPrologJSONFormulaSet(input){
    var output = "{";
    for (var i = 0; i < input.length - 1; i++){
        output += printPrologJSONFormula(input[i]) + ", ";
    }
    output += (input[i] && printPrologJSONFormula(input[i]) || "") + "}";
    return output;
}

function printPrologJSONArg(input){
    var nodes = input[0];
    var attacksDefenses = input[1];
    var d3Nodes = [];
    for (var i = 0; i < nodes.length; i++){
        var node = nodes[i];
        var nodeName = printPrologJSONFormulaSet(node[0]);
        var prologNodeID = node[1];
        d3Nodes.push({name:nodeName, prologNodeID:prologNodeID, children:[]});
    }
    function getByPrologID(requiredPrologNodeID){
        return function(d3Node) {
            return d3Node.prologNodeID == requiredPrologNodeID;
        };
    }
    for (i = 0; i < attacksDefenses.length; i++){
        var attack = attacksDefenses[i];
        var attacker = d3Nodes.find(getByPrologID(attack[0]));
        var attacked = d3Nodes.find(getByPrologID(attack[1]));
        attacked.children.push(attacker);
    }
    return d3Nodes.find(getByPrologID(1));
}

function makeProofThumbnail(id, content){
    var templateStart = "<div draggable=\"true\" ondragstart=\"drag(event)\" style=\"width:400px;height:500px;float:left;padding-left:15px;padding-bottom:15px;position:relative\" id=\"";
    var templateMiddle = "\"><div class=\"thumbnail\" style=\"height:100%;white-space:nowrap;overflow:auto\">";
    var templateEnd = "</div></div>";
    return templateStart + id + templateMiddle + content + templateEnd;
}

function makeGAPThumbnail(id, content){
    var templateStart = "<div draggable=\"true\" ondragstart=\"drag(event)\" style=\"width:400px;height:500px;float:left;padding-left:15px;padding-bottom:15px;position:relative\" id=\"";
    var templateMiddle = "\"><div class=\"thumbnail\" style=\"height:100%;white-space:nowrap;overflow:auto\">";
    var templateEnd = "<img src=\"img/gap-certificate.png\" style=\"position:absolute;right:0;bottom:15px\" draggable=\"false\"></div></div>";
    return templateStart + id + templateMiddle + content + templateEnd;
}

function makeArgThumbnail(id, data, theory, renderID, attack){
    renderID = renderID || (id + "draw");
    var templateStart = "<div draggable=\"true\" ondragstart=\"drag(event)\" style=\"width:400px;height:500px;float:left;padding-left:15px;padding-bottom:15px;position:relative\" id=\"";
    var templateMiddle1 = "\"><div class=\"thumbnail\" style=\"height:100%;white-space:nowrap;overflow:auto\">";
    var templateMiddle2 = "<div id=\"";
    var templateEnd = "\"></div></div></div>";
    addToDrawQueue(renderID, data, attack);
    return templateStart + id + templateMiddle1 + "Theory: " + theory + templateMiddle2 + renderID + templateEnd;
}

function makeEmptyThumbnail(){
    return "<div style=\"width:400px;height:500px;float:left;padding-left:15px;padding-bottom:15px;position:relative\"><div class=\"thumbnail\" style=\"height:100%;white-space:nowrap;overflow:auto\"></div></div>";
}

// draw arg thumbnails

argThumbnailDrawQueue = [];

function drawArgThumbnails(){
    while (argThumbnailDrawQueue.length > 0){
        var argToDraw = argThumbnailDrawQueue.pop();
        doD3("#" + argToDraw[0], argToDraw[1], {width:375, height:450}, null, argToDraw[2], registerAttack);
    }
}

function addToDrawQueue(container, data, attack){
    argThumbnailDrawQueue.push([container, data, attack]);
}

// web storage

function backupClipboard(){
    localStorage["clipboard-data"] = JSON.stringify(clipboardcontents);
}

function retrieveClipboard(){
    return JSON.parse(localStorage["clipboard-data"] || "[]");
}

//misc - init
$("#myTab a:first").tab("show");

//polyfill from Mozilla for Array.find()
//taken from https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/find
if (!Array.prototype.find) {
    Object.defineProperty(Array.prototype, 'find', {
        enumerable: false,
        configurable: true,
        writable: true,
        value: function(predicate) {
            if (this == null) {
                throw new TypeError('Array.prototype.find called on null or undefined');
            }
            if (typeof predicate !== 'function') {
                throw new TypeError('predicate must be a function');
            }
            var list = Object(this);
            var length = list.length >>> 0;
            var thisArg = arguments[1];
            var value;

            for (var i = 0; i < length; i++) {
                if (i in list) {
                    value = list[i];
                    if (predicate.call(thisArg, value, i, list)) {
                        return value;
                    }
                }
            }
            return undefined;
        }
    });
}

clipboardcontents = retrieveClipboard();
rerenderClipboard();