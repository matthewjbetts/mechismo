var $j = jQuery.noConflict();

function drawBarChart(chart) {
    var dataSource = chart.attr('data-source');

    if(typeof dataSource === "undefined") {
        // JSON data in the text of this div
        if(chart.text() == '') {
            return;
        }
        var data = jQuery.parseJSON(chart.text());
        chart.text('');
        drawBarChartFromJSON(chart, data);
    }
    else if(dataSource == 'div') {
        // data are contained within a separate div
        var idDataDiv = chart.attr('data-source-id');
        var data = jQuery.parseJSON($j('#' + idDataDiv).text());
        drawBarChartFromJSON(chart, data);
    }
    else if(dataSource == 'file') {
        // JSON data in a remote file
        // FIXME - use d3.json() instead?
        jQuery.getJSON(
            chart.attr('data-url'),
            null,
            function(data, status, xhr) {
                if(status == 'success') {
                    drawBarChartFromJSON(chart, data);
                }
                else {
                    chart.html("<div class='error'>" + status + '</div>');
                }
            }
        );
    }
}

function drawBarChartFromJSON (chart, data) {
    var id = chart.attr("id");

    var tooltip = d3.select("body").append("div")
        .attr("class", "tooltip")
        .style("display", "none");

    var fontSize = parseInt(chart.css("font-size"));
    var maxX = d3.max(data, function(d) { return d.n; });
    var maxNTicks = 10;
    var nCharsX = maxX.toString().length;
    var nCharsY = d3.max(data, function(d) { return d.name.length; });

    maxX = (maxX > 0) ? maxX : 1;
    
    var margin = {
        top:    10,
        right:  10,
        //bottom: ((nCharsX + 1) * fontSize) , // ensures enough space for x-axis tick-marks lables written vertically
        bottom: 4 * fontSize, // ensures enough space for 3d plus % symbol
        left:   2 * (nCharsY * fontSize) / 3, // ensures enough space for y-axis tick-marks lables written horizontally (more than enough space, since chars are narrower than they are high)
    };
    var width = Math.floor(chart.width() - margin.left - margin.right);
    var height = Math.floor(chart.height() - margin.top - margin.bottom);

    var nTicks = Math.ceil(width / (2 * fontSize));
    nTicks = (nTicks > maxNTicks) ? maxNTicks : nTicks;

    var svg = d3.select(('#' + id)).append("svg")
        .attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)
        .append("g");
        //.attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    var x = d3.scale.linear()
        .range([0, width])
        //.domain([0, maxX]);
        .domain([0, 1]); // jiggery-pokery to always get last tick at exactly 100%
    
    var xAxis = d3.svg.axis()
        .scale(x)
        .orient("bottom")
        .ticks(nTicks);

    var percent = d3.format("3d");
    xAxis.tickFormat(function(d) { return(percent(100 * d) + '%'); });  // jiggery-pokery to always get last tick at exactly 100%

    var y = d3.scale.ordinal()
        .rangeRoundBands([0, height], .1)
        .domain(data.map(function(d) { return d.name; }));

    var yAxis = d3.svg.axis()
        .scale(y)
        .orient("left");

    svg.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + height + ")")
        .call(xAxis)
        .selectAll("text")  
        .style("text-anchor", "end")
        .attr("dx", "-.8em")
        .attr("dy", "-.3em")
        .attr("transform", function(d) {
            return "rotate(-90)" 
        });

    var yAxisText = svg.append("g")
        .attr("class", "y axis")
        .call(yAxis)
        .append("text")
        .attr("transform", "rotate(-90)")
        .attr("y", 6)
        .attr("dy", ".71em")
        .style("text-anchor", "end");

    var duration = 1000;
    svg.selectAll(".bar")
        .data(data)
        .enter().append("rect")
        .attr("class", "bar");

    var bars = svg.selectAll(".bar");

    // resize barchart to take into account the actual (rather than estimated) size of the axis labels
    margin.left = 0;
    d3.selectAll(".y.axis").selectAll("text").each(function() {
        var bbox = this.getBBox();
        margin.left = (bbox.width > margin.left) ? bbox.width : margin.left;
    });
    margin.left += 10;

    margin.bottom = 0;
    d3.selectAll(".x.axis").selectAll("text").each(function() {
        var bbox = this.getBBox();
        margin.bottom = (bbox.width > margin.bottom) ? bbox.width : margin.bottom;
    });
    margin.bottom += 10;

    width = Math.floor(chart.width() - margin.left - margin.right);
    height = Math.floor(chart.height() - margin.top - margin.bottom);
    svg.attr("transform", "translate(" + margin.left + "," + margin.top + ")");
    resizeBarChart();

    bars
        .attr("x", function(d) { return 0; })
        .attr("width", function(d) { return 0; })
        .attr("y", function(d) { return y(d.name); })
        .transition().delay(function(d, i) {return i / data.length * duration})
        .duration(duration)
        .attr("height", y.rangeBand())
        .attr("width", function(d) { return x(d.n) / maxX; }); // jiggery-pokery to always get last tick at exactly 100%

    bars
        .on("mouseover", function(d) {
            var pc = 100 * d.n / maxX;

            tooltip
                .style("left", (d3.event.pageX + 10) + "px")
                .style("top", (d3.event.pageY + 10) + "px")
                .style("display", "inline")
                .html(d.n + " (" + pc.toFixed(0) + "%)");
        })
        .on("mousemove", function(d) {
            tooltip
                .style("left", (d3.event.pageX + 10) + "px")
                .style("top", (d3.event.pageY + 10) + "px")
        })
        .on("mouseout", function(d) {
            tooltip.style("display", "none");
        });


    d3.select(window).on(('resize.' + id), resizeBarChart); // need '+ id' to register multiple functions for the same event

    function resizeBarChart () {
        width = parseInt(chart.css("width"), 10) - 20 - margin.left - margin.right;
        height = parseInt(chart.css("height"), 10) - margin.top - margin.bottom;

        if((width > 0) && (height > 0)) {
            x.range([0, width]);

            d3.select(svg.node().parentNode)
                .style('height', (y.rangeExtent()[1] + margin.top + margin.bottom) + 'px')
                .style('width', (width + margin.left + margin.right) + 'px');

            bars
                .attr("width", function(d) {return x(d.n) / maxX; });  // jiggery-pokery to always get last tick at exactly 100%

            var nTicks = Math.ceil(width / (2 * fontSize));
            nTicks = (nTicks > maxNTicks) ? maxNTicks : nTicks;

            xAxis
                .ticks(nTicks);

            svg.select(".x.axis").call(xAxis)
                .selectAll("text")  
                .style("text-anchor", "end")
                .attr("dx", "-.8em")
                .attr("dy", "-.3em")
                .attr("transform", function(d) {
                    return "rotate(-90)" 
                });
        }
    }
}
