$(document).ready(function() {
    // convert all divs of class "contactMap" into interactive contact maps
    $(".contactMap").each(function() {
        contactMap($(this));
    });
});

// FIXME - rename divs to something more generic for contact maps, eg:
//
// top    = alnA
// left   = alnB
// centre = contacts
//
// Then parse the info in these divs to create the contact map

// synchronised scrolling of the contactMap elements, in step with the size of the fonts
function sync_scroll(thisObject, topObject, leftObject, centreObject, stepHorizontal, stepVertical, moveHorizontal, moveVertical) {
    if(moveHorizontal) {
        var scrollLeft = thisObject.scrollLeft();
        var left = Math.ceil(scrollLeft / stepHorizontal) * stepHorizontal;
        centreObject.scrollLeft(left);
        topObject.scrollLeft(left);
    }

    if(moveVertical) {
        var scrollTop = thisObject.scrollTop();
        var top = Math.ceil(scrollTop / stepVertical) * stepVertical;
        centreObject.scrollTop(top);
        leftObject.scrollTop(top);
    }
};

function crosshairs(e, crosshairVertical, crosshairHorizontal, stepHorizontal, stepVertical) {
    var x = Math.ceil((e.offsetX - stepHorizontal) / stepHorizontal) * stepHorizontal;
    var y = Math.ceil((e.offsetY - stepVertical) / stepVertical) * stepVertical;
    var i;

    for(i = 0; i < crosshairVertical.length; i++) {
        crosshairVertical[i].transform("t" + x + ",0");
    }

    for(i = 0; i < crosshairHorizontal.length; i++) {
        crosshairHorizontal[i].transform("t0," + y);
    }
};

function contactMap(contactMapObject) {
    // top:     alnA
    // left:    alnB
    // centre:  contacts

    var i;
    var j;
    var aseq;
    var x;
    var y;
    var row;
    var posA1;
    var resA1;
    var posB1;
    var resB1;
    var posA2;
    var resA2;
    var posB2;
    var resB2;
    var pdbResA2;
    var pdbResB2;
    var aposA;
    var aposB;
    var circleAttr;

    // get jquery objects for document elements that make up the contactMap
    var seqsAObject = contactMapObject.find(".seqsA:first");
    var seqsBObject = contactMapObject.find(".seqsB:first");
    var alnAObject = contactMapObject.find(".alnA:first");
    var alnBObject = contactMapObject.find(".alnB:first");
    var contactsObject = contactMapObject.find(".contacts:first");

    // read the JSON in these objects
    var seqsA = (seqsAObject.text() == "") ? {} : jQuery.parseJSON(seqsAObject.text());
    var seqsB = (seqsBObject.text() == "") ? {} : jQuery.parseJSON(seqsBObject.text());
    var alnA = (alnAObject.text() == "") ? {} : jQuery.parseJSON(alnAObject.text());
    var alnB = (alnBObject.text() == "") ? {} : jQuery.parseJSON(alnBObject.text());
    var contacts = (contactsObject.text() == "") ? {} : jQuery.parseJSON(contactsObject.text());

    // clear their contents
    var allObjects = [seqsAObject, seqsBObject, alnAObject, alnBObject, contactsObject];
    for(i = 0; i < allObjects.length; i++) {
        allObjects[i].html("");
    }

    // set the fontHeight so that scrolling steps in register with the sequence
    var fontHeight = 14; // Note: pixel units used
    var fontWidth = fontHeight; // FIXME - need to calculate this from some sample text

    alnAObject.on('scroll', function () {sync_scroll(alnAObject, alnAObject, alnBObject, contactsObject, fontWidth, fontHeight, 1, 0)});
    alnBObject.on('scroll', function () {sync_scroll(alnBObject, alnAObject, alnBObject, contactsObject, fontWidth, fontHeight, 0, 1)});
    contactsObject.on('scroll', function () {sync_scroll(contactsObject, alnAObject, alnBObject, contactsObject, fontHeight, 1, 1)});

    // Raphael canvas panels

    // general attributes
    var totalWidth = contactMapObject.css("width");
    var totalHeight = contactMapObject.css("height");
    //var borderWidth = alnAObject.css("border-width"); // FIXME - use this after parsing any given unit info (eg. '1px')
    var borderWidth = 10;

    var matrixWidth = alnA.len * fontWidth;
    var matrixHeight = alnB.len * fontHeight;
    
    var topHeight = (seqsA.length + 1) * fontHeight; // height of the top panel (+1 for id_line)
    var leftWidth = (seqsB.length + 1) * fontWidth; // width of the left panel

    // set div positions based on the dimensions above,
    // with extra for scroll bars, along with dimensions
    x = leftWidth + fontWidth;
    y = topHeight + fontHeight;

    alnAObject.css("height", y);
    alnAObject.css("left", x);
    alnAObject.css("width", totalWidth - x);

    alnBObject.css("width", x);
    alnBObject.css("top", y);
    alnBObject.css("height", totalHeight - y);

    contactsObject.css("left", x);
    contactsObject.css("top", y);
    contactsObject.css("width", totalWidth - x);
    contactsObject.css("height", totalHeight - y);

    var textAttr = {
        "font-family": 'courier, monospace',
        "font-size":   fontHeight + "px",
        fill:          "#000",
        //"text-anchor": "start",
        "text-anchor": "middle",
    };

    // get DOM elements in addition to jquery objects, since Raphael has to use DOM elements as far as I can tell
    var contactMapElement = contactMapObject[0];
    var alnAElement = contactMapElement.getElementsByClassName("alnA")[0];
    var alnBElement = contactMapElement.getElementsByClassName("alnB")[0];
    var contactsElement = contactMapElement.getElementsByClassName("contacts")[0];

    // top, horizontal alignment
    var alnAPanel = Raphael(alnAElement, matrixWidth, topHeight);

    for(i = 0, y = fontHeight / 2; i < seqsA.length; i++, y += fontHeight) { // position is left-middle of text when '"text-anchor": "left"', so need to offset in y by fontHeight / 2
        aseq = alnA.aseqs[seqsA[i].id].aseq.split("");
        //for(j = 0, x = 0; j < aseq.length; j++, x += fontWidth) {
        for(j = 0, x = fontWidth / 2; j < aseq.length; j++, x += fontWidth) {
            alnAPanel.text(x, y, aseq[j]).attr(textAttr);
        }
    }
    aseq = alnA.id_line.split("");
    for(j = 0, x = fontWidth / 2; j < aseq.length; j++, x += fontWidth) {
        alnAPanel.text(x, y, aseq[j]).attr(textAttr);
    }

    // left, vertical alignment 
    var alnBPanel = Raphael(alnBElement, leftWidth, matrixHeight);

    for(i = 0, x = fontWidth / 2; i < seqsB.length; i++, x += fontWidth) {
        aseq = alnB.aseqs[seqsB[i].id].aseq.split("");
        for(j = 0, y = fontHeight / 2; j < aseq.length; j++, y += fontHeight) { // position is left-middle of text when '"text-anchor": "left"', so need to offset in y by fontHeight / 2
            alnBPanel.text(x, y, aseq[j]).attr(textAttr);
        }
    }
    aseq = alnB.id_line.split("");
    for(j = 0, y = fontHeight / 2; j < aseq.length; j++, y += fontHeight) { // position is left-middle of text when '"text-anchor": "left"', so need to offset in y by fontHeight / 2
        alnBPanel.text(x, y, aseq[j]).attr(textAttr);
    }

    // central contact matrix
    var contactsPanel = Raphael(contactsElement, matrixWidth, matrixHeight);

    // crosshairs
    var crosshairVertical = [
        alnAPanel.rect(0, 0, fontWidth, topHeight).attr({fill: "#000", stroke: "#000", opacity: 0.1}),
        contactsPanel.rect(0, 0, fontWidth, matrixHeight).attr({fill: "#000", stroke: "#000", opacity: 0.1}),
    ];
    var crosshairHorizontal = [
        alnBPanel.rect(0, 0, matrixWidth, fontHeight).attr({fill: "#000", stroke: "#000", opacity: 0.1}),
        contactsPanel.rect(0, 0, matrixWidth, fontHeight).attr({fill: "#000", stroke: "#000", opacity: 0.1}),
    ];

    /*
    contactsObject.mousemove(function(e) {
        var x = Math.ceil((e.offsetX - fontWidth) / fontWidth) * fontWidth;
        var y = Math.ceil((e.offsetY - fontHeight) / fontHeight) * fontHeight;
        var i;

        for(i = 0; i < crosshairVertical.length; i++) {
            crosshairVertical[i].transform("t" + x + ",0");
        }

        for(i = 0; i < crosshairHorizontal.length; i++) {
            crosshairHorizontal[i].transform("t0," + y);
        }
    });
    */
    alnAObject.mousemove(function(e) {crosshairs(e, crosshairVertical, [], fontWidth, fontHeight)});
    alnBObject.mousemove(function(e) {crosshairs(e, [], crosshairHorizontal, fontWidth, fontHeight)});
    contactsObject.mousemove(function(e) {crosshairs(e, crosshairVertical, crosshairHorizontal, fontWidth, fontHeight)});

    for(i = 0; i < contacts.rows.length; i++) {
        row = contacts.rows[i];

        posA1 = row[contacts.fields.pos_a1];
        resA1 = row[contacts.fields.res_a1];
        aposA = alnA.pos_to_apos[seqsA[0].id][posA1];
        x = (aposA - 0.5) * fontWidth; // '- 0.5' = '-1 + 0.5'; '-1' because sequence positions are one-based, '+ 0.5' because need the centre of the circle

        posB1 = row[contacts.fields.pos_b1];
        resB1 = row[contacts.fields.res_b1];
        aposB = alnB.pos_to_apos[seqsB[0].id][posB1];
        y = (aposB - 0.5) * fontHeight;

        posA2 = row[contacts.fields.pos_a2];
        resA2 = row[contacts.fields.res_a2];
        posB2 = row[contacts.fields.pos_b2];
        resB2 = row[contacts.fields.res_b2];

        pdbResA2 = row[contacts.fields.chain_a2] + row[contacts.fields.resseq_a2];
        pdbResB2 = row[contacts.fields.chain_b2] + row[contacts.fields.resseq_b2];

        circleAttr = {
            fill: (row[contacts.fields.ss] == 1) ? "#f00" : "#fff",
            stroke: "#000",
            title: resA1 + posA1 + ':' + resB1 + posB1 + " (template: " + resA2 + posA2 + ':' + resB2 + posB2 + ", pdbres: " + pdbResA2 + ":" + pdbResB2 + ")",
        };
        contactsPanel.circle(x, y, 5).attr(circleAttr);
    }
};

// Raphael - scrolling difficult (especially multiple canvases in sync)
// Table - Will have a lot of elements in the main contact matrix (current max is more than 4 million...)
// Text (as per my draft contact_viewer) - difficult to match positions and widths of fonts and graphics
// GS - would be best to avoid text as images 

// Heatmap.js - web heatmaps (clicks, mouse movement)

