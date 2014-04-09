//navbar button actions

$("#importbtn").click(function() {
    alert("not yet implemented!");
});

$("#exportbtn").click(function() {
    alert("not yet implemented!");
});

$("#helpbtn").click(function() {
    alert("not yet implemented!");
});

$("#aboutbtn").click(function() {
    alert("not yet implemented!");
});

//clipboard

$("#clearclipboardconfirm").click(function() {
    clearClipboard();
});

var clipboardcontents = [];

function addToClipboard(item){
    clipboardcontents.push(item);
    rerenderClipboard();
}

function removeFromClipboard(itemID){
    clipboardcontents.splice(itemID, 1);
    rerenderClipboard();
}

function rerenderClipboard(){
    var clipboard = $("#clipboard");
    clipboard.html(generateClipboardHTML());
}

function generateClipboardHTML(){
    var clipboardHTML = "";
    for (var i = 0; i < clipboardcontents.length; i++){
        var item = clipboardcontents[i];
        clipboardHTML += makeThumbnail( "clip" + i, item);
    }
    return clipboardHTML;
}

function clearClipboard(){
    clipboardcontents = [];
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

function allowDrop(event){
    event.preventDefault();
}

//generate proofs tab

var generatedProofs = [];

$("#generateproofsbtn").click(function() {
    generateProofs();
});

function generateProofs(){
    var theory = $("#generateprooftheory").val();
    var goal = $("#generateproofgoal").val();
    //TODO: format theory and goal into appropriate JSON request
    //TODO: send AJAX request and process response
    //TODO: populate placeholder
    var placeholder = $("#generatedproofsplaceholder");
    generatedProofs = ["pollou", "kotopollou"];
    placeholder.html(makeThumbnail("proof0", "pollou") + makeThumbnail("proof1", "kotopollou"));
}

function makeThumbnail(id, content){
    var templateStart = "<div draggable=\"true\" ondragstart=\"drag(event)\" style=\"width:400px;height:500px;float:left;padding-left:15px;padding-bottom:15px\" id=\"";
    var templateMiddle = "\"><div class=\"thumbnail\" style=\"height:100%\">";
    var templateEnd = "</div></div>";
    return templateStart + id + templateMiddle + content + templateEnd;
}

function addProofDrop(event){
    var match = event.dataTransfer.getData("Text").match(/proof(\d+)/);
    if (match){
        var id = match[1];
        var proof = generatedProofs[id];
        addToClipboard(proof);
    } else {
        console.log("attempted to add invalid object to the clipboard!");
    }
}