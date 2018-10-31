var $j = jQuery.noConflict();

$j(document).ready(function() {
    // insert text in to a textarea of class "exampled" from the value of a button
    // of class "example" within the same form works on all forms with these sections
    var buttons = $j("input[type=submit], button");

    // cannot aminate using just a css class without using switchClass from jquery-ui,
    // but that does not work so nicely, at least in my hands...

    $j(".searchShown").each(function() {
        $j(this).children("form").each(function() {
            var searchForm = $j(this);
            var controlPanel = searchForm.find(".controlPanel");
            controlPanel.css({display: "inline-block"});
        });
    });

    $j(".searchHidden").each(function() {
        $j(this).children("form").each(function() {
            var searchForm = $j(this);
            var controlPanel = searchForm.find(".controlPanel");
            controlPanel.css({display: "none"});
        });
    });

    var submit = $j("input[type=submit]");
    /*
    submit.css({
        "height": "2em",
        "width": "2em",
        "background-image": "url('/static/images/search-icon-th-padded.png')",
        "background-size": "2em",
        "background-repeat": "no-repeat",
        "background-position": "0 0",
    });
    */

    var help = $j("button.helpButton");
    help.css({float: "right"});
    /*
    help.css({
        "height": "2em",
        "width": "2em",
        "background-image": "url('/static/images/help-icon-padded.png')",
        "background-size": "2em",
        "background-repeat": "no-repeat",
        "background-position": "0 0",
    });
    */

    $j(".searchShown, .searchHidden").each(function() {
        var searchWrapper = $j(this);
        $j(this).children("form").each(function() {
            var searchForm = $j(this);
            var textArea = searchForm.find("textarea");
            var nameTextBox = searchForm.find("input[type=text]");
            var controlPanel = searchForm.find(".controlPanel");
            var clearButton = searchForm.find("button.clearButton");
            var closeButton = searchForm.find("button.closeButton");
            var examples = searchForm.find("button.example");
            var submitButton = $j("input[type=submit]");
            var nPulses = 2;
            var pulseLength = 800;
            var colorOrig = submitButton.css("color");
            var bgcolorOrig = submitButton.css("background-color");
            var fileInput = searchForm.find(".fileInput");
            var fileInputInput = fileInput.find("input[type=file]");
            var fileInputDisplay = fileInput.find(".display"); 
            var stringencySelect = searchForm.find("select[name=stringency]");
            var stringencyDefault = stringencySelect.val();
            var taxonSelect = searchForm.find("select[name=taxon]");
            var taxonDefault = taxonSelect.val();
            var isoformsSelect = searchForm.find("select[name=isoforms]");
            var isoformsDefault = isoformsSelect.val();
            var extSitesAll = searchForm.find("input[name=extSites]");
            var extSitesAll = searchForm.find("input[name=extSites][value=all]");

            //console.log(defaults = "'" + stringencyDefault + "', '" + taxonDefault + "'");

            // hide any file input fields and divert the click from the associated button
            // this means I can use a button that can be styled
            fileInput.each(function() {
                var input = $j(this).children("input[type=file]");
                var button = $j(this).children("button.fileupload");
                var display = $j(this).children(".display");

                input.css({display: "none"});
                button.click(function() {
                    input.click();
                });

                input.change(function() {
                    var file = $j(this).val();
                    var fileName = file.split("\\");

                    display.html(fileName[fileName.length - 1]);

                    submitButton.animate({color: "#FFFFFF", "background-color": "#B22222"}, pulseLength);
                    for(var i = 0; i < nPulses; i++) {
                        submitButton.animate({color: colorOrig, "background-color": bgcolorOrig}, pulseLength);
                        submitButton.animate({color: "#FFFFFF", "background-color": "#B22222"}, pulseLength);
                    }
                });
            });

            $j(searchForm).keyup(function(e) {
                if(e.keyCode == 27) { // esc
                    hideSearchForm();
                }
                else {
                    showSearchForm();
                }
            });

            textArea.each(function() {
                $j(this).click(function() {
                    showSearchForm();
                });
                $j(this).css({resize: "none"});
            });

            examples.each(function() {
                $j(this).click(function() {
                    var example = jQuery.parseJSON($j(this).attr("value"));
                    //textArea.val($j(this).attr("value"));
                    textArea.val(example.search);
                    if(typeof example.params !== 'undefined') {
                        if(typeof example.params.stringency !== 'undefined') {
                            stringencySelect.val(example.params.stringency).prop('selected', true);
                        }

                        if(typeof example.params.taxon !== 'undefined') {
                            taxonSelect.val(example.params.taxon).prop('selected', true);
                        }

                        if(typeof example.params.isoforms !== 'undefined') {
                            isoformsSelect.val(example.params.isoforms).prop('selected', true);
                        }

                        if(typeof example.params.search_name !== 'undefined') {
                            nameTextBox.val(example.params.search_name);
                        }

                        if(typeof example.params.extSites !== 'undefined') {
                            toggleCheckboxes('extSites', true);
                        }
                        else {
                            toggleCheckboxes('extSites', false);
                        }
                    }

                    fileInputInput.val("");
                    fileInputDisplay.html("");
                    
                    submitButton.animate({color: "#FFFFFF", "background-color": "#B22222"}, pulseLength);
                    for(var i = 0; i < nPulses; i++) {
                        submitButton.animate({color: colorOrig, "background-color": bgcolorOrig}, pulseLength);
                        submitButton.animate({color: "#FFFFFF", "background-color": "#B22222"}, pulseLength);
                    }
                });
            });

            clearButton.each(function() {
                $j(this).click(function() {
                    textArea.val("");
                    nameTextBox.val("");
                    fileInputInput.val("");
                    fileInputDisplay.html("");
                    stringencySelect.val(stringencyDefault).prop('selected', true);
                    taxonSelect.val(taxonDefault).prop('selected', true);

                    submitButton.stop(true);
                    submitButton.css({"color": colorOrig, "background-color": bgcolorOrig});
                });
            });
    
            closeButton.each(function() {
                $j(this).click(function () {
                    $j(this).stop(true);
                    hideSearchForm();
                });
            });

            submitButton.each(function() {
                $j(this).click(function () {
                    $j(this).stop(true);
                    hideSearchForm();
                });
            });

            function showSearchForm() {
                textArea.stop(true);
                textArea.animate({
                    height: "20em",
                    "background-color": "#FFFFFF",
                });
                controlPanel.css({display: "inline-block"});
            }
        
            function hideSearchForm() {
                textArea.stop(true);
                textArea.animate({
                    height: "2em",
                    "background-color": "#EEEEEE",
                });
                controlPanel.css({display: "none"});
            }

        });
    });
});

function toggleCheckboxes(name, checked) {
    var checkboxes = $j(document).find("input[name=" + name + "]");
    var all = checkboxes.find("input[value=all]");

    checkboxes.each(function() {
        $j(this).prop("checked", checked);
    });
}
