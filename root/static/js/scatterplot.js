var $j = jQuery.noConflict();

function drawScatterPlot(chart) {
    var dataSource = chart.attr('data-source');

    if(typeof dataSource === "undefined") {
        // JSON data in the text of this div
        if(chart.text() == '') {
            return;
        }
        var data = jQuery.parseJSON(chart.text());
        chart.text('');
        drawScatterPlotFromJSON(chart, data);
    }
    else if(dataSource == 'div') {
        // data are contained within a separate div
        var idDataDiv = chart.attr('data-source-id');
        var data = jQuery.parseJSON($j('#' + idDataDiv).text());
        drawScatterPlotFromJSON(chart, data);
    }
    else if(dataSource == 'file') {
        // JSON data in a remote file
        // FIXME - use d3.json() instead?
        jQuery.getJSON(
            chart.attr('data-url'),
            null,
            function(data, status, xhr) {
                if(status == 'success') {
                    drawScatterPlotFromJSON(chart, data);
                }
                else {
                    chart.html("<div class='error'>" + status + '</div>');
                }
            }
        );
    }
}

function drawScatterPlotFromJSON (chart, data) {
    var id = chart.attr("id");

    var columns = data.columns;
    data = data.data;

    var tooltip = d3.select("body").append("div")
        .attr("class", "tooltip")
        .style("display", "none");

    var fontSize = parseInt(chart.css("font-size"));
    var maxX = d3.max(data, function(d) { return d[0]; });
    var maxY = d3.max(data, function(d) { return d[1]; });

    var nCharsX = maxX.toString().length;

    var margin = {
        top:    10,
        right:  10,
        bottom: 50,
        left:   50,
    };
    var width = chart.width() - margin.left - margin.right;
    var height = chart.height() - margin.top - margin.bottom;

    var nTicksX = width / (nCharsX * fontSize);
    nTicksX = (nTicksX > maxX) ? maxX : nTicksX;

    var nTicksY = height / (2 * fontSize);
    nTicksY = (nTicksY > maxY) ? maxY : nTicksY;

    var x = d3.scale.linear()
        .range([0, width]);

    var y = d3.scale.linear()
        .range([height, 0]);

    var z = d3.scale.ordinal()
        .range(colorbrewer.YlOrRd[9]);

    var svg = d3.select(('#' + id)).append("svg")
        .attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)
        .append("g")
        .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    var xAxis = d3.svg.axis()
        .scale(x)
        .orient("bottom")
        .ticks(nTicksX);

    var yAxis = d3.svg.axis()
        .scale(y)
        .orient("left")
        .ticks(nTicksY);

    x.domain([0, d3.max(data, function(d) { return d[0]; })]);
    y.domain([0, d3.max(data, function(d) { return d[1]; })]);
    z.domain([0, d3.max(data, function(d) { return d[2]; })]);

    svg.selectAll("circle")
        .data(data)
        .enter()
        .append("circle")
        .attr("class", "dot")
        .attr("cx", function(d) { return x(d[0]); })
        .attr("cy", function(d) { return y(d[1]); })
        .attr("r", function(d) {return 5; })
        .style("stroke", "#000000")
        .style("fill", function(d) {return z(d[2]); });

    var dots = svg.selectAll(".dot");

    dots
        .on("mouseover", function(d) {
            var offset = (x(d[0]) >= (x(maxX))) ? -120 : 10; 
            tooltip
                .style("left", (d3.event.pageX + offset) + "px")
                .style("top", (d3.event.pageY + 10) + "px")
                .style("display", "inline")
                .html(d[3]);
        })
        .on("mousemove", function(d) {
            var offset = (x(d[0]) >= (x(maxX))) ? -120 : 10; 
            tooltip
                .style("left", (d3.event.pageX + offset) + "px")
                .style("top", (d3.event.pageY + 10) + "px")
        })
        .on("mouseout", function(d) {
            tooltip.style("display", "none");
        })
        .on("click", function(d) {
            window.open(d[4]);
        });

    svg.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + height + ")")
        .call(xAxis)
        .append("text")
        .attr("x", width)
        .attr("y", -6)
        .style("text-anchor", "end")
        .text(columns[0]);

    svg.append("g")
        .attr("class", "y axis")
        .call(yAxis)
        .append("text")
        .attr("transform", "rotate(-90)")
        .attr("y", 6)
        .attr("dy", ".71em")
        .style("text-anchor", "end")
        .text(columns[1]);
}
