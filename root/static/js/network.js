var $j = jQuery.noConflict();

function drawNetwork (network) {
    var dataSource = network.attr('data-source');
    var idSearch = network.attr('id-search');
    var searchRoot = (typeof idSearch === "undefined") ? '' : ('/search/id/' + idSearch);

    if(typeof dataSource === "undefined") {
        // JSON data in the text of this div
        if(network.text() == '') {
            return;
        }
        var graph = jQuery.parseJSON(network.text());
        network.text('');
        drawNetworkFromJSON(searchRoot, network, graph);
    }
    else if(dataSource == 'file') {
        // JSON data in a remote file
        // FIXME - use d3.json() instead?
        jQuery.getJSON(
            network.attr('data-url'),
            null,
            function(graph, status, xhr) {
                if(status == 'success') {
                    drawNetworkFromJSON(searchRoot, network, graph);
                }
                else {
                    network.html("<div class='error'>" + status + '</div>');
                }
            }
        );
    }
}

function drawNetworkFromJSON (searchRoot, network, graph) {
    var id = network.attr("id");

    /*
      The following is a hack to account for the change in width on applying jquery-ui tabs,
      which change the size of the div. I could apply the tabs function before drawing the
      network, but then networks in hidden tabs would have no width or height...
    */
    //network.css('padding', '0 2em 0 0');
    //network.css('border-width', '0 0 0 0');
    //network.css('margin', '0 0 0 0');

    var width = network.width();
    var height = network.height();
    if(height <= 0) {
        height = $j(window).height() - network.offset().top;
    }

    var n_nodes = graph.nodes.length;
    if(graph.n_ids > graph.n_ids_max) {
        network.removeClass("network");
        network.addClass("contents");
        network.html("(Network view disabled for more than " + graph.n_ids_max + " nodes.)");
    }
    else if(n_nodes > 0) {
        var maxRadius = 0;
        var nodePadding = 1;
        var alphaMax = 0.001;
        var r = 5;
        var markerSize = 10;
        var forceRunning = 0;
        var centre = [width / 2, height / 2];
        var r = 5;
        var scale = 1;

        var tooltip = d3.select("body").append("div")
            .attr("class", "tooltip")
            .style("display", "none");

        var zoom = d3.behavior.zoom()
            .on('zoom', zoomed);
        
        var drag = d3.behavior.drag()
            .origin(function(d) { return d; })
            .on('dragstart', dragStart)
            .on('drag', dragMove)
            .on('dragend', dragEnd);

        var svg = d3.select('#' + id).append('svg')
            .attr('width', width)
            .attr('height', height)
            .append('g')
            .call(zoom);

        svg.style('overflow', 'hidden');

        var rect = svg.append('rect')
            .attr('width', width)
            .attr('height', height)
            .style('fill', 'none')
            .style('pointer-events', 'all');

        svg.on('click', function() {
            force.stop();
        });

        var container = svg.append('g')
            .style('pointer-events', 'all');
        
        // create an arrowhead marker
        var markerSize = 10;
        container.append('defs').append('marker')
            .attr('id', 'arrowhead')
            .attr('viewBox', '0 -5 10 10')
            .attr('refX', 0)
            .attr('refY', 0)
            .attr('markerWidth', markerSize)
            .attr('markerHeight', markerSize)
            .attr('markerUnits', 'userSpaceOnUse')
            .attr('orient', 'auto')
            .append('path')
            .attr('d', 'M0 -5 L10 0 L0 5');

        graph.nodes.forEach(function(d, i) {
            if(d.type == 'query') {
                d.url = searchRoot + '/seq/' + d.id;
            }
            else if(d.type == 'nucleic') {
                // FIXME - set url
            }
            else if(d.type == 'chemical') {
                // FIXME - set url
            }
            else if(d.type == 'friend') {
                d.url = searchRoot+ '/seq/' + d.id;
            }
        });

        var force = d3.layout.force()
            .size([width, height])
            .charge(-300)
            .alpha(alphaMax)
            .linkDistance(100)
            .nodes(graph.nodes)
            .links(graph.links);

        function forceStart() { // couldn't get force.on('start') to work
            forceRunning = 1;
            controls.optimise.attr('class', 'on');
            force.start();
        }

        force.on("tick", tick);

        force.on('end', function(e) {
            forceRunning = 0;
            controls.optimise.attr('class', 'off');
            messages.text('');
            scaleToSVG(1000);
        });

        var messages = d3.select(('#' + id))
            .append('p')
            .attr('class', 'messages')
            .text('');

        var controlPanel = d3.select(('#' + id))
            .append('ul')
            .attr('class', 'controlPanel');

        var controls = {};
        controls.optimise = controlPanel
            .append('li')
            .html(function() {
                return forceRunning ? '<span title="Freeze network layout">O</span>' : '<span title="Optimise network layout">O</span>';
            })
            .attr('class', function() {
                return forceRunning ? 'on' : 'off';
            })
            .on('click', function() {
                if(forceRunning) {
                    force.stop();
                }
                else {
                    forceStart();
                }
            });

        /*
         * FIXME
         *
         * hiding and showing nodes (and associated edges):
         *
         * - by classification
         *   - type
         *     - query
         *     - chemical
         *     - nucleic
         *     - friend
         *
         * - by value:
         *   - n_sites_on
         *   - n_sites_degree
         *   - degree
         *
         * - individual nodes (after right-click?)
         * 
         * 
         * hiding and showing edges (and associated nodes):
         *
         * - by classification:
         *   - ie_class
         *
         * - by value:
         *   - n_sites
         *   - ie
         * 
         * 
         * issues:
         * 
         * - hiding some nodes means some edges should be hidden too,
         *   and vice-versa
         *
         * - some classifications and values might change from their intial
         *   state depending on what has already been hidden or shown, eg:
         * 
         *   - after hiding chemicals, some nodes will become singletons (n_sites_degree = 0)
         *   - after hiding some edges (eg. by ie_class), some nodes will become singletons
         *
         * - would like to be able to undo some changes
         *
         * solutions:
         *
         * - for each node and each edge, record whether or not it is currently hidden
         * - after each change, hide edges between two nodes that are hidden
         *
         */

        var nodeShow = [];
        jQuery.each(graph.nodes, function(index, value) {
            nodeShow[value.idx] = 'show';
        });

        var linkShow = [];
        jQuery.each(graph.links, function(index, value) {
            linkShow[value.idx] = 'show';
        });

        var showTypes = {'query' : 1, 'chemical': 1, 'nucleic': 1, 'friend': 1, 'unconnected' : 1, 'nosites' : 1};
        var togglesNodes = {};

        var toggleText = {
            'chemical':    {'show': '<span title="Show chemicals">C</span>',                     'hide': '<span title="Hide chemicals">C</span>', },
            'nucleic':     {'show': '<span title="Show DNA/RNA">D</span>',                       'hide': '<span title="Hide DNA/RNA">D</span>',   },
            'friend':      {'show': '<span title="Show friends (protein interactors)">F</span>', 'hide': '<span title="Hide friends (protein interactors)">F</span>',   },
            'unconnected': {'show': '<span title="Show unconnected">U</span>',                   'hide': '<span title="Hide unconnected">U</span>'},
            'nosites':     {'show': '<span title="Show interactors with no sites">S</span>',     'hide': '<span title="Hide interactors with no sites">S</span>'},
        };

        controlPanel
            .append('li')
            .html('<span title="Show all nodes and edges">A</span>')
            .on('click', function() {
                showTypes = {'query' : 1, 'chemical': 1, 'nucleic': 1, 'friend': 1, 'unconnected' : 1, 'nosites' : 1};

                jQuery.each(showTypes, function(index, value) {
                    if(index != 'query') {
                        togglesNodes[index]
                            .html(toggleText[index]['hide'])
                            .attr('class', 'on');
                    }
                });

                node.each(function() {
                    var node = d3.select(this);
                    var d = node.data()[0];

                    d.fixed = false;
                });

                jQuery.each(graph.nodes, function(index, d) {
                    if(d.degree == 0) {
                        nodeShow[d.idx] = 'show';
                    }
                });
                linkShowUpdate();
                networkUpdate();
            });

        jQuery.each(showTypes, function(index, value) {
            if(index != 'query') {
                togglesNodes[index] = controlPanel
                    .append('li')
                    .html(toggleText[index]['hide'])
                    .attr('class', 'on')
                    .on('click', function() {
                        toggleNodes(index);
                    });
            }
        });

        controls.freeNodes = controlPanel
            .append('li')
            .html('<span title="Free pinned nodes (nodes are pinned when you click and drag them)">P</span>')
            .on('click', function() {
                node.each(function() {
                    var node = d3.select(this);
                    var d = node.data()[0];

                    d.fixed = false;
                });
            });

        controls.zoomToFit = controlPanel
            .append('li')
            .html('<span title="Scale entire network to fit in panel">\<\></span>')
            .on('click', function() {
                scaleToSVG(300);
            });

        var node = container.selectAll('.node')
            .data(graph.nodes, function(d) { return d.idx; });
        nodeUpdate(node);
        var label = node.selectAll('text');
        var fontSize = parseInt(label.style('font-size'));
        var minVisibleFontSize = 10;

        var link = container.selectAll('.link')
            .data(graph.links, function(d) { return d.idx; });
        linkUpdate(link);

        forceStart();
    }

    function scaleToSVG (duration) {
        var minX = 1000000000000;
        var maxX = 0;
        var minY = 1000000000000;
        var maxY = 0;
        var viewBoxWidth;
        var viewBoxHeight;

        graph.nodes.forEach(function(d, i) {
            var radius = d.r + 5;

            if(nodeShow[d.idx] == 'show') {
                minX = Math.min(minX, d.x - radius);
                maxX = Math.max(maxX, d.x + radius);
                minY = Math.min(minY, d.y - radius);
                maxY = Math.max(maxY, d.y + radius);
            }
        });

        // for debugging scaling and translating
        //svg.append('rect').attr({stroke: '#666666', fill: 'none', x: (width / 2) - 50, y: (height / 2) - 50, width: 100, height: 100});
        //container.append('rect').attr({stroke: '#FF0000', fill: 'none', x: (minX + (maxX - minX) / 2) - 25, y: (minY + (maxY - minY) / 2) - 25, width: 50, height: 50});
        //container.append('rect').attr({stroke: '#00FF00', fill: 'none', x: (width / 2) - 25, y: (height / 2) - 25, width: 50, height: 50});

        // scale the graph so that it fits on the canvas
        scale = Math.min(width / (maxX - minX), height / (maxY - minY));
        //scale = (scale > 1.0) ? 1.0 : scale;

        // hide the text if it's too small to be read
        labelsVisible()

        // first translation is to move the centre of the graph to the centre of the svg
        var reCenter = [
            (width / 2) - (minX + (maxX - minX) / 2),
            (height / 2) - (minY + (maxY - minY) / 2),
        ];

        // second translation is applied after scaling, and effectively means network is scaled
        // around the centre: http://stackoverflow.com/questions/11671100/scale-path-from-center
        var translation = [(1 - scale) * (width / 2), (1 - scale) * (height / 2)];

        // transformations are applied in right-to-left order
        //console.log('transform', 'translate(' + translation + ') scale(' + scale + ') translate(' +  reCenter + ')');
        container.transition().attr('transform', 'translate(' + translation + ') scale(' + scale + ') translate(' +  reCenter + ')').duration(duration);

        // reset initial paramaters for later use of d3.behavior.zoom
        zoom.scale(scale);
        //zoom.translate(translation);
    }

    function labelsVisible() {
        var visibleFontSize = parseInt(fontSize * scale);
        if(visibleFontSize < minVisibleFontSize) {
            label.style('display', 'none');
        }
        else {
            //label.style('font-size', visibleFontSize);
            label.style('display', 'inline');
        }
    }

    function zoomed() {
        var visibleFontSize = (d3.event.scale >= 1) ? fontSize : parseInt(fontSize * d3.event.scale);
        if(visibleFontSize < minVisibleFontSize) {
            label.style('display', 'none');
        }
        else {
            //label.style('font-size', visibleFontSize);
            label.style('display', 'inline');
        }
        container.attr('transform', 'translate(' + d3.event.translate + ') scale(' + d3.event.scale + ')');
    }

    function dragStart(d) {
        force.stop();
        d3.event.sourceEvent.stopPropagation();
    }

    function dragMove(d) {
        // not using d3.event.dx and dy as the nodes tended to judder when dragged
        // var coord = [d3.event.dx, d3.event.dy];
        var coord = d3.mouse(this);
        d.px += coord[0];
        d.py += coord[1];
        d.x += coord[0];
        d.y += coord[1];

        var idNode = d.id;

        d3.select(this).attr('transform', nodeMove(d));
        link.select(function(d, i) { return(((d.source.id == idNode) || (d.target.id == idNode)) ? this : null); })
            .attr('d', function(d) { return linkMove(d); });
    }

    function dragEnd(d) {
        d.fixed = true;
        //force.resume();
    }

    var foci = [
        {x: 0,     y: 0},
        {x: width, y: 0},
    ];

    function tick(e) {
        link.attr('d', function(d) { return linkMove(d); });
        node.attr('transform', function(d) { return nodeMove(d); });

        // collision detection
        graph.nodes.each(collide(0.5));

        // push nodes with no edges to the bottom of the layout
        var k = 0.2 * e.alpha;
        graph.nodes.forEach(function(d, i) {
            if(d.degree == 0) {
                d.x += (foci[1].x - d.x) * k;
                d.y += (foci[1].y - d.y) * k;
            }
            else {
                d.x += (foci[0].x - d.x) * k;
                d.y += (foci[0].y - d.y) * k;
            }
        });

        // zoom in or out to fit everything in the svg
        scaleToSVG(300);

        var myAlpha = e.alpha.toFixed(6);
        if(myAlpha <= alphaMax) {
            force.stop();
        }

        if(myAlpha > alphaMax) {
            messages.text('Sub-optimal layout (alpha = ' + myAlpha + ')');
        }
        else {
            force.stop();
        }
    }

    function collide(alpha) {
        var quadtree = d3.geom.quadtree(graph.nodes);
        return function(d) {
            var r = d.r + maxRadius + nodePadding;
            var nx1 = d.x - r;
            var nx2 = d.x + r;
            var ny1 = d.y - r;
            var ny2 = d.y + r;

            quadtree.visit(function(quad, x1, y1, x2, y2) {
                if (quad.point && (quad.point !== d)) {
                    var x = d.x - quad.point.x,
                    y = d.y - quad.point.y,
                    l = Math.sqrt(x * x + y * y),
                    r = d.r + quad.point.r + nodePadding;
                    if (l < r) {
                        l = (l - r) / l * alpha;
                        d.x -= x *= l;
                        d.y -= y *= l;
                        quad.point.x += x;
                        quad.point.y += y;
                    }
                }
                return x1 > nx2 || x2 < nx1 || y1 > ny2 || y2 < ny1;
            });
        };
    }

    function linkMove (d) {
        // draw lines between nodes
        /*
          FIXME - ideally these would be drawn between the centre of each node,
          even if it's not a circle. However, x and y refer to the centre of a
          circle but to the top left corner of a rectangle (for example).
         */

        if(typeof d.source.x === 'undefined') {
            path = 'M0 0 L0 0';
        }
        else {
            var x1 = d.source.x;
            var y1 = d.source.y;
            var x2 = d.target.x;
            var y2 = d.target.y;
            var dx = x2 - x1;
            var dy = y2 - y1;
            var r1 = d.source.r;
            var r2 = d.target.r;
            var h = Math.sqrt((dx * dx) + (dy * dy));
            var path;

            var offsetX2 = (r2 + markerSize) * dx / h;
            var offsetY2 = (r2 + markerSize) * dy / h;

            x2 = x2 - offsetX2;
            y2 = y2 - offsetY2;

            // FIXME - offset should put the arc on the edge of the circle at the appropriate point

            if(d.source === d.target) { // self edge
                var dr = (typeof d.source.r === 'undefined') ? 0 : d.source.r * 2;
                
                // slight offset of arc endpoint otherwise the arc is not drawn
                var x2 = x1 - 1;
                var y2 = y1 - 1;

                path = 'M' + x1 + ' ' + y1 + ' A' + dr + ' ' + dr + ' 1 1 1 ' + x2 + ' ' + y2;
            }
            else if(d.bi === 1) {
                //var dr = 100;
                var dr = h;

                path = 'M' + x1 + ' ' + y1 + ' A' + dr + ' ' + dr + ' 0 0 1 ' + x2 + ' ' + y2;
            }
            else {
                path = 'M' + x1 + ' ' + y1 + ' L' + x2 + ' ' + y2;
            }
        }

        return path;
    }

    function nodeMove (d) {
        if(typeof d.x === "undefined") {
            return 'translate(0, 0)';
        }
        else {
            return 'translate(' + d.x + ',' + d.y + ')';
        }
    }

    function linkUpdate (link) {
        var linkEnter = link.enter()
            .insert('path', '.node')
            .attr('class', function(d) {
                var n_ies = d.ies.length;
                var idx_max_ie = n_ies - 1;
                var myClass = 'link';
               
                if(n_ies > 0) {
                    var ies = d.ies.sort(function(a, b) { return a.ie - b.ie; });
                    if(ies[0].ie_class == 'disabling') {
                        if(ies[idx_max_ie].ie_class == 'enabling') {
                            myClass = 'link enablingAndDisabling';
                        }
                        else {
                            myClass = 'link disabling';
                        }
                    }
                    else if(ies[idx_max_ie].ie_class == 'enabling') {
                        myClass = 'link enabling';
                    }
                }

                return myClass;
            })
            .attr('marker-end', 'url(#arrowhead)')
            .attr('stroke-width', function(d) {
                var thickness = d.n_sites * 2 + 0.5; // FIXME - use a d3 scale for this?
                thickness = (thickness > markerSize) ? markerSize : thickness;
                return thickness;
            })
            .on('mouseover', function(d) {
                tooltip
                    .style('left', (d3.event.pageX + 10) + 'px')
                    .style('top', (d3.event.pageY + 10) + 'px')
                    .style('display', 'inline')
                    .html(linkDescription(d));
            })
            .on('mousemove', function(d) {
                tooltip
                    .style('left', (d3.event.pageX + 10) + 'px')
                    .style('top', (d3.event.pageY + 10) + 'px')
            })
            .on('mouseout', function(d) {
                tooltip.style('display', 'none');
            });

        linkEnter.attr('d', function(d) { return linkMove(d); });

        return linkEnter;
    }

    function nodeUpdate (node) {
        var nodeEnter = node.enter()
            .append('g')
            .attr('class', function(d) { return 'node ' + d.type; })
            .call(drag);

        var shape = nodeEnter.append('circle')
            .attr('r', function(d) {
                // FIXME - use a d3 scale?
                d.r = (d.type == 'query') ? (Math.log(d.n_sites_on + 2) * r) : (Math.log(d.n_sites_degree + 2) * r);
                if(d.r > maxRadius) {
                    maxRadius = d.r;
                }
                return d.r;
            })
            .attr('cx', 0)
            .attr('cy', 0);

        shape
            .on('mouseover', function(d) {
                tooltip
                    .style('left', (d3.event.pageX + 10) + 'px')
                    .style('top', (d3.event.pageY + 10) + 'px')
                    .style('display', 'inline')
                    .html(nodeDescription(d));
            })
            .on('mousemove', function(d) {
                    tooltip
                    .style('left', (d3.event.pageX + 10) + 'px')
                    .style('top', (d3.event.pageY + 10) + 'px')
            })
            .on('mouseout', function(d) {
                tooltip.style('display', 'none');
            })
            .on('click', function(d) {
                if(d3.event.defaultPrevented) {
                    return;
                } 

                if(d.type != 'query' && d.type != 'friend') {
                    return;
                }

                console.log("d.url = '" + d.url + "'");
                window.open(d.url);
            })
            .on('contextmenu', function(d) { // 'contextmenu' = event name for right-click
                // remove node on right-click
                // FIXME - would be better to bring up a menu from which 'remove node' would be one of several options
                nodeShow[d.idx] = 'hide';
                linkShowUpdate();
                networkUpdate();

                // prevent browser menu from showing
                d3.event.preventDefault();
            });

        nodeEnter.append('text')
            .attr('text-anchor', 'middle')
            .attr('alignment-baseline', 'central')
            .attr('x', 0)
            .attr('y', 0)
            .text(function(d) { return d.name; });

        nodeEnter.attr('transform', function(d) { return nodeMove(d); });

        return nodeEnter;
    }

    function toggleNodes (type, textShow, textHide) {
        if(showTypes[type] == 1) {
            showTypes[type] = 0;
            togglesNodes[type].html(toggleText[type]['show']);
            togglesNodes[type].attr('class', 'off');

            if(type == 'unconnected') {
                jQuery.each(graph.nodes, function(index, d) {
                    if(d.degree == 0) {
                        nodeShow[d.idx] = 'hide';
                    }
                });
            }
            else if(type == 'nosites') {
                jQuery.each(graph.nodes, function(index, d) {
                    if((d.n_sites_on == 0) && (d.n_sites_in == 0)) {
                        nodeShow[d.idx] = 'hide';
                    }
                });
            }
            else {
                jQuery.each(graph.nodes, function(index, d) {
                    if(d.type == type) {
                        nodeShow[d.idx] = 'hide';
                    }
                });
            }
        }
        else {
            showTypes[type] = 1;
            togglesNodes[type].html(toggleText[type]['hide']);
            togglesNodes[type].attr('class', 'on');

            if(type == 'unconnected') {
                jQuery.each(graph.nodes, function(index, d) {
                    if(d.degree == 0) {
                        nodeShow[d.idx] = 'show';
                    }
                });
            }
            else if(type == 'nosites') {
                jQuery.each(graph.nodes, function(index, d) {
                    if((d.n_sites_on == 0) && (d.n_sites_in == 0)) {
                        nodeShow[d.idx] = 'show';
                    }
                });
            }
            else {
                jQuery.each(graph.nodes, function(index, d) {
                    if(d.type == type) {
                        nodeShow[d.idx] = 'show';
                    }
                });
            }
        }

        linkShowUpdate();
        networkUpdate();
    }

    function linkShowUpdate() {
        jQuery.each(graph.links, function(index, d) {
            if((nodeShow[d.source.idx] == 'hide') || (nodeShow[d.target.idx] == 'hide')) {
                if(linkShow[d.idx] == 'show') {
                    linkShow[d.idx] = 'hide';
                    d.source.degree--;
                    d.target.degree--;
                }
            }
            else if((nodeShow[d.source.idx] == 'show') && (nodeShow[d.target.idx] == 'show')) {
                if(linkShow[d.idx] == 'hide') {
                    linkShow[d.idx] = 'show';
                    d.source.degree++;
                    d.target.degree++;
                }
            }
        });
    }

    function networkUpdate() {
        var myNodes = graph.nodes.filter(function(d, i, a) { return((nodeShow[d.idx] == 'show') ? true : false); });
        var myLinks = graph.links.filter(function(d, i, a) { return((linkShow[d.idx] == 'show') ? true : false); });

        // update the links
        link = container.selectAll('.link').data(myLinks, function(d) { return d.idx; });
        link.exit().remove();
        linkUpdate(link);

        // update the nodes
        node = container.selectAll('.node').data(myNodes, function(d) { return d.idx; });
        node.exit().remove();
        nodeUpdate(node);
        label = node.selectAll('text');
        labelsVisible();

        force
            .nodes(myNodes)
            .links(myLinks);
    }

    function linkDescription(d) {
        //var html = d.source.name + ' - ' + d.target.name + ', ' + d.n_sites + (d.n_sites == 1 ? ' site' : ' sites') + ' in this interface';

        var n_ies = d.ies.length;
        var idx_max_ie = n_ies - 1;
        var html = '<h3>' + d.source.name + ' - ' + d.target.name + ((d.target.type == 'chemical') ? ' chemicals' : '') + '</h3>';

        if(d.n_sites > 0) {
            html += (d.n_sites + (d.n_sites == 1 ? ' site' : ' sites') + ' in this interface');
            if(n_ies > 0) {
                var ies = d.ies.sort(function(a, b) { return a.ie - b.ie; });
                if(ies[0].ie_class == 'disabling') {
                    if(ies[idx_max_ie].ie_class == 'enabling') {
                        html += ', both enabling (IE = ' + ies[idx_max_ie].ie + ') and disabling (IE = ' + ies[0].ie + ').';
                    }
                    else {
                        html += ', disabling (IE = ' + ies[0].ie + ').';
                    }
                }
                else if(ies[idx_max_ie].ie_class == 'enabling') {
                    html += ', enabling (IE = ' + ies[idx_max_ie].ie + ').';
                }
                else {
                    html += '.';
                }
            }
        }
        else {
            html += 'No sites in this interface.';
        }

        return html;
    }

    function nodeDescription(d) {
        var html;

        if(d.type == 'query') {
            html = [
                '<h3>', d.name, '</h3>',
                //d.n_sites_on  + (d.n_sites_on  == 1 ? ' site' : ' sites') + ' on this protein.<br/>',
                ((d.n_sites_on == 1) ? 'There is 1 site' : ('There are ' + d.n_sites_on + ' sites')) + ' on this protein.<br/>',
                d.n_sites_out + (d.n_sites_out == 1 ? ' site interacts' : ' sites interact') + ' with another molecule.<br/>',
                d.n_sites_in  + (d.n_sites_in  == 1 ? ' site on another protein interacts' : ' sites on other proteins interact') + ' with this protein.<br/>',
            ];
            html = html.join('');
        }
        else if(d.type == 'nucleic') {
            html = '<h3>DNA/RNA</h3>' + d.n_sites_degree + (d.n_sites_degree == 1 ? ' site interacts ' : ' sites interact ') + 'with DNA/RNA';
        }
        else if(d.type == 'chemical') {
            html = '<h3>' + d.name + ' chemicals</h3>' + d.n_sites_degree + (d.n_sites_degree == 1 ? ' site interacts ' : ' sites interact ') + 'with ' + d.name + ' chemicals';
        }
        else {
            html = '<h3>' + d.name + '</h3>' + d.n_sites_degree + (d.n_sites_degree == 1 ? ' site interacts ' : ' sites interact ') + 'with ' + d.name;
        }

        return html;
    }

    d3.select(window).on(('resize.' + id), function() { // need '+ id' to register multiple functions for the same event
        width = network.width();
        height = network.height(); //$j(window).height();
        if(height <= 0) {
            height = $j(window).height() - network.offset().top;
        }
        centre = [width / 2, height / 2];

        svg
            .attr('width', width)
            .attr('height', height);

        rect
            .attr('width', width)
            .attr('height', height);
    });
}
