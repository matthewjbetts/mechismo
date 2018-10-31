var $j = jQuery.noConflict();

$j(document).ready(function() {
    /*
     * dataTable custom sort functions for custom data type 'annotatedNumber',
     * = an optional one-letter amino-acid code, immediately followed by a number,
     * followed by any string.
     */
    jQuery.fn.dataTableExt.oSort['annotatedNumber-asc']  = function(a,b) {
        var x;
        var y;
        var cmp;

        if(a === "") {
            x = 0;
        }
        else {
            x = a.replace(/<.*?>/g, '');
            x = x.replace(/^[^\d\.\-\+]+/, '');
            x = parseFloat(x);
        }

        if(b === "") {
            y = 0;
        }
        else {
            y = b.replace(/<.*?>/g, '');
            y = y.replace(/^[^\d\.\-\+]+/, '');
            y = parseFloat(y);
        }

        if(isNaN(x)) {
            cmp = isNaN(y) ? 0 : 1;
        }
        else if(isNaN(y)) {
            cmp = -1;
        }
        else {
            cmp = (x < y) ? -1 : ((x > y) ? 1 : 0);
        }

        return cmp;
    };

    jQuery.fn.dataTableExt.oSort['annotatedNumber-desc'] = function(a,b) {
        var x;
        var y;

        if(a === "") {
            x = 0;
        }
        else {
            x = a.replace(/<.*?>/g, '');
            x = x.replace(/^[^\d\.\-\+]+/, '');
            x = parseFloat(x);
        }

        if(b === "") {
            y = 0;
        }
        else {
            y = b.replace(/<.*?>/g, '');
            y = y.replace(/^[^\d\.\-\+]+/, '');
            y = parseFloat(y);
        }

        if(isNaN(x)) {
            cmp = isNaN(y) ? 0 : -1;
        }
        else if(isNaN(y)) {
            cmp = 1;
        }
        else {
            cmp = (x > y) ? -1 : ((x < y) ? 1 : 0);
        }

        var cmp = (x > y) ? -1 : ((x < y) ? 1 : 0);
        return cmp;
    };

    $j(".dataTable").each(function() {
        // FIXME - process in to the correct format
        //   - need some kind of 'map' function, giving column
        //     headings and how to process the input data in to
        //     data that will be displayed

        // get a name for the table
        var tableName = $j(this).attr("id");
        if(typeof tableName === "undefined") {
            tableName = 'dataTable';
        }

        var dataSource = $j(this).attr('data-source');
        if(typeof dataSource === "undefined") {
            // data is in a normal html table

            // get column types and initial sort columns
            var columns = [];
            var orderInit = [];
            var idx = -1;
            $j(this).children("thead").each(function() {
                $j(this).children("tr").each(function() {
                    $j(this).children("th").each(function() {
                        ++idx;
                        if(typeof $j(this).attr('class') === "undefined") {
                            columns.push(null);
                        }
                        else {
                            var classList = $j(this).attr('class').split(/\s+/);
                            var nClasses0 = classList.length;

                            // FIXME - get columns to be used in intial sort
                            var sortInfoStr = jQuery.grep(classList, function(className, i) {
                                return(className.match(/^sort/));
                            });
                            var sortInfoRE = /sort(\d+)(\S+)/;
                            for(var i = 0; i < sortInfoStr.length; i++) {
                                var sortInfo = sortInfoRE.exec(sortInfoStr[i]);
                                if(sortInfo) {
                                    orderInit.push([sortInfo[1], idx, sortInfo[2]]);
                                }
                            }

                            // remove class names not used to specify type of data in the column
                            classList = jQuery.grep(classList, function(className, i) {
                                return(className !== "hidden");
                            });
                            var visible = (classList.length < nClasses0) ? false : true;
                                                
                            classList = jQuery.grep(classList, function(className, i) {
                                return(!className.match(/^sort/));
                            });
                            var nClasses1 = classList.length;

                            columns.push({
                                type:    (nClasses1 > 0) ? classList.join(' ') : null,
                                visible: visible,
                            });
                    }
                    });
                });
            });
            var order = [];
            if(orderInit.length > 0) {
                orderInit = orderInit.sort(function(a, b) {
                    return(a[0] - b[0]); // sort numerically by first element;
                });
                for(i = 0; i < orderInit.length; i++) {
                    order.push([orderInit[i][1], orderInit[i][2]]);
                }
            }

            var classList = $j(this).attr('class').split(/\s+/);
            var nFixedColumnsRE = /(\d+)FixedColumn/;
            var nFixedColumnsMax = 0;
            var nFixedColumns;

            for(var i = 0; i < classList.length; i++) {
                var nFixedColumns = nFixedColumnsRE.exec(classList[i]);
                if(nFixedColumns) {
                    if(nFixedColumns[1] > nFixedColumnsMax) {
                        nFixedColumnsMax = nFixedColumns[1];
                    }
                }
            }

            var table = $j(this).DataTable({
                columns: columns,
                order: order,
                pagingType: 'full_numbers',
                language: {
                    paginate: {
                        first:    "<<",
                        previous: "<",
                        next:     ">",
                        last:     ">>"
                    }
                },
                scrollX:  "100%",
                dom: '<"title">T<"clear">lfrtip',
                tableTools: {
                    sSwfPath: "/static/js/DataTables/extensions/TableTools/swf/copy_csv_xls.swf",
                    aButtons: [
                        {
                            sExtends: "csv",
                            sButtonText: "CSV",
                            sTitle: tableName,
                        },
                    ],
                },
            });

            /*
            if(nFixedColumnsMax > 0) {
                new FixedColumns(oTable, {iLeftColumns: nFixedColumnsMax});
            }
            */
        }
        else if(dataSource == 'div') {
            // data are contained within a separate div
            var idDataDiv = $j(this).attr('data-source-id');
            var datasetJSONStr = $j('#' + idDataDiv).html();
            var origDataset = jQuery.parseJSON(datasetJSONStr);
            processOrigDataset($j(this), tableName, origDataset);
        }
        else if(dataSource = 'file') {
            // data are in a file which will be processed on the server side via an ajax call
            processOrigDataset($j(this), tableName, null);
        }
        else {
            // FIXME - where are the data?
        }
    });
});

function processOrigDataset (obj, tableName, origDataset) {
    var idSearch = obj.attr('id-search');
    var searchRoot = (typeof idSearch === "undefined") ? '' : ('/search/id/' + idSearch);

    var dataset = [];
    var columns = [];
    var order;

    if(obj.hasClass("siteTable")) {
        /*
         * FIXME
         *
         * prot and site tables in search_results.tt now come from ajax calls. 
         * More work is needed to enable the same functionality for prot, site,
         * ppi, pci, pdi and struct tables elsewhere, and for reading the same
         * data from a hidden div.
         *
         * headings and other column info should be in the json too?
         */

        obj.children('thead').html(
            "<tr>" +
                "<th>id_seq</th>" +
                "<th>Protein</th>" +
                "<th>Primary Sequence Identifier</th>" +
                "<th>Site</th>" +
                "<th><span title='Given alias and modification that found this site'>User input</span></th>" +
                "<th><span title='Given residue not found at given position'>!</span></th>" +
                "<th><span title='Blosum62 substitution score'>B62</span></th>" +
                "<th><span title='Intrinsically disordered region predicted by IUPred'>Di</span></th>" +
                "<th><span title='At least one matching structure was found. Linked to the best match. Percent identity of match given.'>S</span></th>" +
                "<th><span title='Number of proteins with which this site interacts (proteins are counted more than once if the site can interact with more than one part of them)'>nP</span></th>" +
                "<th><span title='Site in contact with a protein in a matching structure. Interacting protein given, along with percentage identity of best match, Interaction Effect and links to structure showing all sites (A) and this site (T)'>Prot</span></th>" +
                "<th><span title='Number of chemical classes with which this site interacts'>nC</span></th>" +
                "<th><span title='Site in contact with a small molecule in a matching structure. Chemical group given, along with percentage identity to template, Interaction Effect and links to structure showing all sites (A) and this site (T).'>Chem</span></th>" +
                "<th><span title='Site in contact with DNA/RNA in a matching structure. Percent identity of best match given, along with Interaction Effect and links to structure showing all sites (A) and this site (T)'>DNA</span></th>" +
                "<th>Mechismo Prot Score</th>" +
                "<th>Mechismo Chem Score</th>" +
                "<th>Mechismo DNA/RNA Score</th>" +
                "<th><span title='The higher the Mechismo Score, the more likely a particular mutation or modification is to affect interactions with other molecules. Mechismo Score = the sum of (1 + maximum absolute change in pair-potential) for protein-protein, protein-chemical and protein-DNA/RNA interactions'>Mechismo Score</span></th>" +
                "</tr>"
        );        

        columns.push(
            {type: null,              visible: false}, // 00 - id_seq
            {type: null,              visible: true},  // 01 - protein
            {type: null,              visible: false}, // 02 - primary sequence identifier
            {type: 'annotatedNumber', visible: true},  // 03 - site
            {type: null,              visible: true},  // 04 - user input
            {type: null,              visible: true},  // 05 - mismatch
            {type: null,              visible: false}, // 06 - blosum62
            {type: null,              visible: false}, // 07 - disordered
            {type: null,              visible: false}, // 08 - structure
            {type: 'num',             visible: true,  className: 'dt-right'},  // 09 - nP
            {type: null,              visible: true},  // 10 - ppis
            {type: 'num',             visible: true,  className: 'dt-right'},  // 11 - nC
            {type: null,              visible: true},  // 12 - pcis
            {type: null,              visible: true},  // 13 - pdis
            {type: null,              visible: false, className: 'dt-right'}, // 14 - mechProt
            {type: null,              visible: false, className: 'dt-right'}, // 15 - mechChem
            {type: null,              visible: false, className: 'dt-right'}, // 16 - mechDNA/RNA
            {type: null,              visible: true,  className: 'dt-right'}   // 17 - mechScore
        );
        order = [[17, 'desc']];

        var tableDef = {
            columns:    columns,
            order:      order,
            pagingType: 'full_numbers',
            language: {
                paginate: {
                    first:    "<<",
                    previous: "<",
                    next:     ">",
                    last:     ">>"
                }
            },
            scrollX:    "100%",
            dom:        '<"title">T<"clear">lfrtip',

            tableTools: {
                sSwfPath: "/static/js/DataTables/extensions/TableTools/swf/copy_csv_xls.swf",
                aButtons: [
                    {
                        sExtends: "csv",
                        sButtonText: "CSV",
                        sTitle: tableName,
                    },
                ],
            },
        };

        if(origDataset === null) {
            var url = searchRoot + '/data/site_table';
            tableDef.ajax = {url: url, dataSrc: ""};
            tableDef.deferRender = true;
        }
        else {
            tableDef.data = origDataset;
        }
        var table = $j('#' + tableName).DataTable(tableDef);
    }
    else if(obj.hasClass("protTable")) {
        obj.children('thead').html(
            "<tr>" +
            "<th>id_seq</th>" +
            "<th>Protein</th>" +
            "<th>primary_id</th>" +
            "<th><span title='Given alias that found this protein'>User input</span></th>" +
            "<th>Species</th>" +
            "<th>Description</th>" +
            "<th><span title='Number of sites given'>n</span></th>" +
            "<th><span title='Number of sites where the given residue does not match the residue found at the given position'>n!</span></th>" +
            "<th><span title='minimum Blosum62 substitution-matrix value of any mutation in this protein'>minB62</span></th>" +
            "<th><span title='maximum Blosum62 substitution-matrix value of any mutation in this protein'>maxB62</span></th>" +
            "<th><span title='Number of sites in disordered regions'>nDi</span></th>" +
            "<th><span title='Number of sites in regions with matching structures'>nS</span></th>" +
            "<th><span title='Number of sites interacting with proteins'>nP</span></th>" +
            "<th><span title='Number of sites interacting with chemicals in matching structures'>nC</span></th>" +
            "<th><span title='Number of sites interacting with DNA/RNA in matching structures'>nD</span></th>" +
            "<th><span title='negative Interaction Effect: maximum negative change in InterPreTS score of any interaction involving any given site'>IE-</span></th>" +
            "<th><span title='positive Interaction Effect: maximum positive change in InterPreTS score of any interaction involving any given site'>IE+</span></th>" +
            "<th><span title='Sum of Mechismo Scores for each site in this protein. The higher the Mechismo Score, the more likely a particular mutation or modification is to affect interactions with other molecules. Mechismo Score = the sum of (1 + maximum absolute change in pair-potential) for protein-protein, protein-chemical and protein-DNA/RNA interactions'>Mechismo Score</span></th>" +
            "</tr>"
        );

        columns.push(
            {type: null,  visible: false}, // 00 - id_seq
            {type: null,  visible: true},  // 01 - protein
            {type: null,  visible: false}, // 02 - primary sequence identifier
            {type: null,  visible: true},  // 03 - user input
            {type: null,  visible: true},  // 04 - species
            {type: null,  visible: true},  // 05 - description
            {type: null,  visible: true,  className: 'dt-right'}, // 06 - n
            {type: null,  visible: true,  className: 'dt-right'}, // 07 - n!
            {type: 'num', visible: false, className: 'dt-right'}, // 08 - minB62
            {type: 'num', visible: false, className: 'dt-right'}, // 09 - maxB62
            {type: null,  visible: false, className: 'dt-right'}, // 10 - nDi
            {type: null,  visible: false, className: 'dt-right'}, // 11 - nS
            {type: null,  visible: true,  className: 'dt-right'}, // 12 - nP
            {type: null,  visible: true,  className: 'dt-right'}, // 13 - nC
            {type: null,  visible: true,  className: 'dt-right'}, // 14 - nD
            {type: 'num', visible: false, className: 'dt-right'}, // 15 - IE-
            {type: 'num', visible: false, className: 'dt-right'}, // 16 - IE+
            {type: 'num', visible: true,  className: 'dt-right'}  // 17 - mechScore
        );
        order = [[17, 'desc']];
            
        var tableDef = {
            columns:    columns,
            order:      order,
            pagingType: 'full_numbers',
            language: {
                paginate: {
                    first:    "<<",
                    previous: "<",
                    next:     ">",
                    last:     ">>"
                }
            },
            scrollX:    "100%",
            dom:        '<"title">T<"clear">lfrtip',

            tableTools: {
                sSwfPath: "/static/js/DataTables/extensions/TableTools/swf/copy_csv_xls.swf",
                aButtons: [
                    {
                        sExtends: "csv",
                        sButtonText: "CSV",
                        sTitle: tableName,
                    },
                ],
            },
        };

        if(origDataset === null) {
            var url = searchRoot + '/data/prot_table';
            tableDef.ajax = {url: url, dataSrc: ""},
            tableDef.deferRender = true;
        }
        else {
            tableDef.data = origDataset;
        }
        var table = $j('#' + tableName).DataTable(tableDef);
    }
    else if(obj.hasClass("pciTable")) {
        obj.children('thead').html(
            "<tr>" +
            "<th>id_fh</th>" +
            "<th>id_seq</th>" +
            "<th>name</th>" +
            "<th>primary_id</th>" +
            "<th>Site</th>" +
            "<th>Start</th>" +
            "<th>End</th>" +
            "<th>Template</th>" +
            "<th><span title='Percent sequence identity'>%id</span></th>" +
            "<th><span title='E-value'>e</span></th>" +
            "<th class='sort0desc annotatedNumber'><span title='Interaction Effect: change in InterPreTS score caused by the site'>IE</span></th>" +
            "<th>Chem Type</th>" +
            "<th>Chem</th>" +
            "</tr>"
        );

        columns.push(
            {type: null,              visible: false}, // 00 - id_fh
            {type: null,              visible: false}, // 01 - id_seq_a1
            {type: null,              visible: false}, // 02 - name_a1
            {type: null,              visible: false}, // 03 - primary_id_a1
            {type: 'annotatedNumber', visible: true},  // 04 - site
            {type: null,              visible: true, className: 'dt-right'},  // 05 - start_a1
            {type: null,              visible: true, className: 'dt-right'},  // 06 - end_a1
            {type: null,              visible: true},  // 07 - template
            {type: 'annotatedNumber', visible: true, className: 'dt-right'},  // 08 - pcid
            {type: 'num',             visible: true, className: 'dt-right'},  // 09 - e
            {type: 'annotatedNumber', visible: true, className: 'dt-right'},  // 10 - IE
            {type: null,              visible: true},  // 11 - chem type
            {type: null,              visible: true}   // 12 - chem

            // FIXME - what about start and end positions in the template?
        );
        order = [[10, 'desc']];

        var tableDef = {
            columns:    columns,
            order:      order,
            pagingType: 'full_numbers',
            language: {
                paginate: {
                    first:    "<<",
                    previous: "<",
                    next:     ">",
                    last:     ">>"
                }
            },
            scrollX:    "100%",
            dom:        '<"title">T<"clear">lfrtip',

            tableTools: {
                sSwfPath: "/static/js/DataTables/extensions/TableTools/swf/copy_csv_xls.swf",
                aButtons: [
                    {
                        sExtends: "csv",
                        sButtonText: "CSV",
                        sTitle: tableName,
                    },
                ],
            },
        };

        if(origDataset === null) {
            // FIXME - this should be for a '/search/id-search/seq/id-seq/data/pci_table' url...
            var url = searchRoot + '/data/pci_table';
            tableDef.ajax = {url: url, dataSrc: ""},
            tableDef.deferRender = true;
        }
        else {
            tableDef.data = origDataset;
        }

        var table = $j('#' + tableName).DataTable(tableDef);
    }
    else if(obj.hasClass("pdiTable")) {
        obj.children('thead').html(
            "<tr>" +
            "<th>id_fh</th>" +
            "<th>id_seq</th>" +
            "<th>name</th>" +
            "<th>primary_id</th>" +
            "<th>Site</th>" +
            "<th>Start</th>" +
            "<th>End</th>" +
            "<th>Template</th>" +
            "<th><span title='Percent sequence identity'>%id</span></th>" +
            "<th><span title='E-value'>e</span></th>" +
            "<th class='sort0desc annotatedNumber'><span title='Interaction Effect: change in InterPreTS score caused by the site'>IE</span></th>" +
            "</tr>"
        );

        columns.push(
            {type: null,              visible: false}, // 00 - id_fh
            {type: null,              visible: false}, // 01 - id_seq_a1
            {type: null,              visible: false}, // 02 - name_a1
            {type: null,              visible: false}, // 03 - primary_id_a1
            {type: 'annotatedNumber', visible: true},  // 04 - site
            {type: null,              visible: true, className: 'dt-right'},  // 05 - start_a1
            {type: null,              visible: true, className: 'dt-right'},  // 06 - end_a1
            {type: null,              visible: true},  // 07 - template
            {type: 'annotatedNumber', visible: true, className: 'dt-right'},  // 08 - pcid
            {type: 'num',             visible: true, className: 'dt-right'},  // 09 - e
            {type: 'annotatedNumber', visible: true, className: 'dt-right'}   // 10 - IE

            // FIXME - what about start and end positions in the template?
        );
        order = [[10, 'desc']];

        var tableDef = {
            columns:    columns,
            order:      order,
            pagingType: 'full_numbers',
            language: {
                paginate: {
                    first:    "<<",
                    previous: "<",
                    next:     ">",
                    last:     ">>"
                }
            },
            scrollX:    "100%",
            dom:        '<"title">T<"clear">lfrtip',

            tableTools: {
                sSwfPath: "/static/js/DataTables/extensions/TableTools/swf/copy_csv_xls.swf",
                aButtons: [
                    {
                        sExtends: "csv",
                        sButtonText: "CSV",
                        sTitle: tableName,
                    },
                ],
            },
        };

        if(origDataset === null) {
            // FIXME - this should be for a '/search/id-search/seq/id-seq/data/pdi_table' url...
            var url = searchRoot + '/data/pdi_table';
            tableDef.ajax = {url: url, dataSrc: ""},
            tableDef.deferRender = true;
        }
        else {
            tableDef.data = origDataset;
        }

        var table = $j('#' + tableName).DataTable(tableDef);
    }
    else if(obj.hasClass("ppiTable")) {
        obj.children('thead').html(
            "<tr>" +
            "<th>id_ch</th>" +
            "<th>id_seq_a1</th>" +
            "<th>name_a1</th>" +
            "<th>primary_id_a1</th>" +
            "<th>Site</th>" +
            "<th>Start</th>" +
            "<th>End</th>" +
            "<th>id_seq_b1</th>" +
            "<th>name_b1</th>" +
            "<th>primary_id_b1</th>" +
            "<th>Interactor</th>" +
            "<th>Start</th>" +
            "<th>End</th>" +
            "<th><span title='Evidence for the interaction. STRING score for the interaction (linked to STRING), and/or Structure (%identity >= ${json.min_pcid_known}) or Inferred from Structure'>IntEv</span></th>" +
            "<th>Template</th>" +
            "<th><span title='The template is either a hetero-dimer or a (pseudo-)homo dimer (its two components are at least 50% identical across at least 50% of their length)'>Dimer</th>" +
            "<th><span title='Minimum percentage sequence identity of either protein to the template'>%id</span></th>" +
            "<th><span title='Maximum e-value of either protein to the template'>e<span></th>" +
            "<th><span title='Interaction Effect: change in InterPreTS score caused by the site'>IE</span></th>" +
            "</tr>"
        );

        columns.push(
            {type: null,              visible: false},  // 00 - id_ch
            {type: null,              visible: false},  // 01 - id_seq_a1
            {type: null,              visible: false},  // 02 - name_a1
            {type: null,              visible: false},  // 03 - primary_id_a1
            {type: 'annotatedNumber', visible: true},   // 04 - site
            {type: null,              visible: true,  className: 'dt-right'},   // 05 - start
            {type: null,              visible: true,  className: 'dt-right'},   // 06 - end
            {type: null,              visible: false},  // 07 - id_seq_b1
            {type: null,              visible: false},  // 08 - name_b1
            {type: null,              visible: false},  // 09 - primary_id_b1
            {type: null,              visible: true},   // 10 - interactor
            {type: null,              visible: true,  className: 'dt-right'},   // 11 - start
            {type: null,              visible: true,  className: 'dt-right'},   // 12 - end
            {type: null,              visible: true},   // 13 - intev
            {type: null,              visible: true},   // 14 - template
            {type: null,              visible: true},   // 15 - dimer
            {type: 'annotatedNumber', visible: true,  className: 'dt-right'},   // 16 - pcid
            {type: 'num',             visible: true,  className: 'dt-right'},   // 17 - e
            {type: 'annotatedNumber', visible: true,  className: 'dt-right'}    // 18 - IE
        );
        order = [[18, 'desc']];

        var tableDef = {
            columns:    columns,
            order:      order,
            pagingType: 'full_numbers',
            language: {
                paginate: {
                    first:    "<<",
                    previous: "<",
                    next:     ">",
                    last:     ">>"
                }
            },
            scrollX:    "100%",
            dom:        '<"title">T<"clear">lfrtip',

            tableTools: {
                sSwfPath: "/static/js/DataTables/extensions/TableTools/swf/copy_csv_xls.swf",
                aButtons: [
                    {
                        sExtends: "csv",
                        sButtonText: "CSV",
                        sTitle: tableName,
                    },
                ],
            },
        };

        if(origDataset === null) {
            // FIXME - this should be for a '/search/id-search/seq/id-seq/data/ppi_table' url...
            var url = searchRoot + '/data/ppi_table';
            tableDef.ajax = {url: url, dataSrc: ""},
            tableDef.deferRender = true;
        }
        else {
            tableDef.data = origDataset;
        }
        var table = $j('#' + tableName).DataTable(tableDef);
    }
    else if(obj.hasClass("structTable")) {
        obj.children('thead').html(
            "<tr>" +
            "<th>id_fh</th>" +
            "<th>id_seq</th>" +
            "<th>name</th>" +
            "<th>primary_id</th>" +
            "<th>Site</th>" +
            "<th>Start</th>" +
            "<th>End</th>" +
            "<th>Template</th>" +
            "<th>%id</th>" +
            "<th>e</th>" +
            "</tr>"
        );
            
        columns.push(
            {type: null,              visible: false}, // 00 - id_fh
            {type: null,              visible: false}, // 01 - id_seq_a1
            {type: null,              visible: false}, // 02 - name_a1
            {type: null,              visible: false}, // 03 - primary_id_a1
            {type: 'annotatedNumber', visible: true},  // 04 - site
            {type: null,              visible: true,  className: 'dt-right'},  // 05 - start_a1
            {type: null,              visible: true,  className: 'dt-right'},  // 06 - end_a1
            {type: null,              visible: true},  // 07 - template
            {type: 'num',             visible: true,  className: 'dt-right'},  // 08 - pcid
            {type: 'num',             visible: true,  className: 'dt-right'}   // 09 - e
        );
        order = [[4, 'asc']];

        var tableDef = {
            columns:  columns,
            order:    order,
            scrollX:  "100%",
            dom:      '<"title">T<"clear">lfrtip',

            tableTools: {
                sSwfPath: "/static/js/DataTables/extensions/TableTools/swf/copy_csv_xls.swf",
                aButtons: [
                    {
                        sExtends: "csv",
                        sButtonText: "CSV",
                        sTitle: tableName,
                    },
                ],
            },
        };

        if(origDataset === null) {
            // FIXME - this should be for a '/search/id-search/seq/id-seq/data/struct_table' url...
            var url = searchRoot + '/data/struct_table';
            tableDef.ajax = {url: url, dataSrc: ""},
            tableDef.deferRender = true;
        }
        else {
            tableDef.data = origDataset;
        }
        var table = $j('#' + tableName).DataTable(tableDef);
    }

    /*
    obj.children("tbody").each(function() {
        $j(this).children("tr").each(function() {
            $j(this).children("td").each(function() {
                $j(this).children("ul").each(function() {
                    console.log($j(this));
                });
            });
        });
    });
    */
}
