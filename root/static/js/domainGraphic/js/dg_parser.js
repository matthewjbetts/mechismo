var $j=jQuery.noConflict();

var parser={

    colorPos:-1,

    parse: function (jsObj) {
	var pfam_dg=new Object();
	pfam_dg.length=jsObj.length;
	
	
	// domain
	if (typeof jsObj.domains != 'undefined') {
	    pfam_dg.regions=[];
	    $j.each(jsObj.domains,function(index,value) {
		var color;
		if (typeof value.colour === 'undefined' || value.colour==='auto') {
		    color=parser.getColorAt(value.title);

		} else {
		    color=value.colour;
		}
		
		var startStyle;
		if (typeof value.start_complete === 'undefined' ||
		    value.start_complete) {
		    startStyle='curved';
		} else {
		    startStyle='jagged';
		}

		var endStyle;
		if (typeof value.end_complete === 'undefined' || 
		    value.end_complete) {
		    endStyle='curved';
		} else {
		    endStyle='jagged';
		}
		
		
		pfam_dg.regions.push(
		    {
			'start':value.start||0,
			'end':value.end||0,
			'text':value.title||'',
			'type':'pfama',
			'display':value.display||true,
			'colour':color,
			'startStyle':startStyle,
			'endStyle':endStyle,
			'metadata': {
			    'type': 'domain',
			    'description': value.tt_desc||'',
			    'start': value.start||0,
			    'end':value.end||0
			}
		    });

	    });
	}
	
	
	// region for example IUPred disordered regions
	// this will be shown as a pfam motif due to the opacity
	if (typeof jsObj.regions != 'undefined') {
	    
	    pfam_dg.motifs=[];

	    if (typeof pfam_dg.regions === 'undefined') {
		pfam_dg.regions=[];
	    }
	    
	    $j.each(jsObj.regions,function(index,value) {
		var color;
		if (typeof value.colour === 'undefined' || 
		    value.colour==='auto') {
		    color=parser.getColorAt(value.title);

		} else {
		    color=value.colour;
		}
		
		pfam_dg.motifs.push(
		    {
			'start':value.start||0,
			'end':value.end||0,
			'type':value.title||'',
			'display':value.display||true,
			'colour':color,
			'metadata': {
			    'type': 'region',
			    'description': value.tt_desc||'',
			    'start': value.start||0,
			    'end':value.end||0
			}
		    });

	    });
	}
	
	
	// motifs
	// are going to shown as pfam region
	if (typeof jsObj.motifs != 'undefined') {
	    
	    
	    $j.each(jsObj.motifs,function(index,value) {
		var color;
		if (typeof value.colour === 'undefined' || 
		    value.colour==='auto') {
		    color=parser.getColorAt(value.title);

		} else {
		    color=value.colour;
		}
		
		var startStyle;
		if (typeof value.start_complete === 'undefined' ||
		    value.start_complete) {
		    startStyle='straight';
		} else {
		    startStyle='jagged';
		}

		var endStyle;
		if (typeof value.end_complete === 'undefined' || 
		    value.end_complete) {
		    endStyle='straight';
		} else {
		    endStyle='jagged';
		}
		
		
		pfam_dg.regions.push(
		    {
			'start':value.start||0,
			'end':value.end||0,
			'text':value.title||'',
			'type':'pfama',
			'display':value.display||true,
			'colour':color,
			'startStyle':startStyle,
			'endStyle':endStyle,
			'metadata': {
			    'type': 'motif',
			    'description': (value.title+'<br>'+value.tt_desc)||'',
			    'start': value.start||0,
			    'end':value.end||0
			}
		    });

	    });
	}
	


	//frameshift
	if(typeof jsObj.frameshift !== 'undefined') {

	    pfam_dg.markups=[];

	    $j.each(jsObj.frameshift, function(index, value) {
		var linecolor;
		if (typeof value.lineColour === 'undefined' || value.lineColour==='') {
		    linecolor='#A51A1A'; // wine red
		}
		else {
		    linecolor=value.lineColor;
		}

		pfam_dg.markups.push({
		    'v_align': 'top',
		    'start': value.position||0,
		    'end': pfam_dg.length,
		    'lineColour': linecolor,
		    'colour': linecolor,
		    // 'type': 'frameshift',
		    'display': value.display||true,
		    'metadata': {
			'type': 'frameshift',
			'start': value.position,
			'description': value.tt_desc||'',
		    }
		    
		});
		
	    });
	}
	
	// site_up
	if (typeof jsObj.sites_up !== 'undefined') {
	    
	    if (typeof pfam_dg.markups === 'undefined') {
		pfam_dg.markups=[];
	    }
	    
	    $j.each(jsObj.sites_up,function(index,value) {
		var linecolor;
		if (typeof value.lineColour === 'undefined' || value.lineColour==='') {
		    linecolor='#000000';
		}
		else {
		    linecolor=value.lineColor;
		}
		
		var headcolor;
		if (typeof value.headColour === 'undefined' || value.headColour==='') {
		    headcolor='#000000';
		}
		else {
		    headcolor=value.headColour;
		}
		
		pfam_dg.markups.push(
		    {
			'v_align':'top',
			'start':value.position||0,
			'score':value.popHeight,
			'type':value.tt_type||'',
			'display':value.display||true,
			'lineColour':linecolor,
			'colour':headcolor,
			'headStyle':value.headStyle||'diamand',
			'metadata': {
			    'type': value.tt_type,
			    'description': value.tt_desc||'',
			    'start': value.position||0,
			    'end':value.position||0
			}
		    });

	    });
	}
	
	// site_down
	if (typeof jsObj.sites_down != 'undefined') {
	    
	    if (typeof pfam_dg.markups === 'undefined') {
		pfam_dg.markups=[];
	    }
	    
	    $j.each(jsObj.sites_down,function(index,value) {
		var linecolor;
		if (typeof value.lineColour === 'undefined' || value.lineColour==='') {
		    linecolor='#000000';
		}
		else {
		    linecolor=value.lineColor;
		}
		
		var headcolor;
		if (typeof value.headColour === 'undefined' || value.headColour==='') {
		    headcolor='#000000';
		}
		else {
		    headcolor=value.headColour;
		}
		
		pfam_dg.markups.push(
		    {
			'v_align':'bottom',
			'start':value.position||0,
			'type':value.tt_type||'',
			'display':value.display||true,
			'lineColour':linecolor,
			'colour':headcolor,
			'headStyle':value.headStyle||'diamand',
			'metadata': {
			    'type': value.tt_type,
			    'description': value.tt_desc||'',
			    'start': value.position||0,
			    'end':value.position||0
			}
		    });

	    });
	}
	return pfam_dg;
	
    },
    
    draw: function (jsObj, divTag, scale) {
	var pfam_obj=parser.parse(jsObj);
	var pg=new PfamGraphic();
	var scale=scale||1;
	pg.setParent(divTag);
	//console.log(pfam_obj);
	pg.setImageParams({xscale:scale, yscale: scale});
	pg.setSequence(pfam_obj);
	pg.render();
    },
    
    getColorAt: function (key) {
	var c=parser.thecolors;
	var pos;
	if (!parser.existingDomain.hasOwnProperty(key) || parser.colorPos <0) {
	    parser.colorPos=++parser.colorPos%c.length;
	    parser.existingDomain[key]=parser.colorPos;
	    pos=parser.colorPos;
	}
	else {
	    pos=parser.existingDomain[key];
	}
	return c[pos].substring(0,c[pos].indexOf(' '));
    },
    
    existingDomain: new Object(),
    
    thecolors:new Array(
	 '#0000FF blue'
	,'#000000 black'
	,'#8A2BE2 blueviolet'
	,'#A52A2A brown'
	,'#5F9EA0 cadetblue'
	,'#6495ED cornflowerblue'
	,'#DC143C crimson'
	,'#00FFFF cyan'
	,'#00008B darkblue'
	,'#008B8B darkcyan'
	,'#B8860B darkgoldenrod'
	,'#A9A9A9 darkgray'
	,'#006400 darkgreen'
	,'#BDB76B darkkhaki'
	,'#FF00FF magenta' 
	,'#800000 maroon' 
	,'#66CDAA mediumaquamarine' 
	,'#0000CD mediumblue' 
	,'#BA55D3 mediumorchid' 
	,'#9370DB mediumpurple' 
	,'#3CB371 mediumseagreen' 
	,'#7B68EE mediumslateblue' 
	,'#00FA9A mediumspringgreen' 
	,'#48D1CC mediumturquoise' 
	,'#C71585 mediumvioletred' 
	,'#191970 midnightblue' 
	// '#F0F8FF aliceblue'
	,'#FAEBD7 antiquewhite'
	,'#00FFFF aqua'
	,'#7FFFD4 aquamarine'
	// ,'#F0FFFF azure'
	,'#F5F5DC beige'
	,'#FFE4C4 bisque'
	// ,'#FFEBCD blanchedalmond'
	,'#FF7F50 coral'
	// ,'#FFF8DC cornsilk'
	,'#7FFF00 chartreuse'
	,'#D2691E chocolate'
	,'#8B008B darkmagenta'
	,'#556B2F darkolivegreen'
	,'#FF8C00 darkorange'
	,'#9932CC darkorchid'
	,'#8B0000 darkred'
	,'#E9967A darksalmon'
	,'#8FBC8F darkseagreen'
	,'#483D8B darkslateblue'
	,'#2F4F4F darkslategray'
	,'#00CED1 darkturquoise'
	,'#9400D3 darkviolet'
	,'#FFD700 gold'
	,'#FF1493 deeppink'
	,'#00BFFF deepskyblue'
	,'#696969 dimgray'
	,'#1E90FF dodgerblue'
	,'#B22222 firebrick'
	// ,'#FFFAF0 floralwhite'
	,'#228B22 forestgreen'
	,'#FF00FF fuchsia'
	// ,'#DCDCDC gainsboro'
	// ,'#F8F8FF ghostwhite'
	,'#DAA520 goldenrod'
	,'#808080 gray'
	,'#008000 green'
	// ,'#ADFF2F greenyellow'
	// ,'#F0FFF0 honeydew'
	,'#FF69B4 hotpink'
	,'#4B0082 indigo'
	// ,'#FFFFF0 ivory'
	,'#F0E68C khaki'
	,'#DEB887 burlywood'
	// ,'#E6E6FA lavender'
	// ,'#FFF0F5 lavenderblush' 
	,'#7CFC00 lawngreen'
	,'#FFFACD lemonchiffon'
	,'#CD5C5C indianred'
	,'#6B8E23 olivedrab'
	,'#ADD8E6 lightblue'
	,'#F08080 lightcoral'
	// ,'#E0FFFF lightcyan'
	,'#FAFAD2 lightgoldenrodyellow'
	,'#90EE90 lightgreen' 
	,'#D3D3D3 lightgrey' 
	,'#FFB6C1 lightpink' 
	,'#32CD32 limegreen' 
	,'#FFA07A lightsalmon' 
	,'#20B2AA lightseagreen' 
	,'#87CEFA lightskyblue' 
	,'#778899 lightslategray' 
	,'#B0C4DE lightsteelblue' 
	// ,'#FFFFE0 lightyellow' 
	,'#00FF00 lime' 
	// ,'#FAF0E6 linen' 
	// ,'#F5FFFA mintcream' 
	,'#FFE4E1 mistyrose' 
	,'#FFE4B5 moccasin' 
	// ,'#FFDEAD navajowhite' 
	,'#000080 navy' 
	// ,'#FDF5E6 oldlace' 
	,'#808000 olive'
	,'#FFA500 orange'
	,'#FF4500 orangered'
	,'#DA70D6 orchid'
	,'#EEE8AA palegoldenrod'
	,'#98FB98 palegreen'
	,'#AFEEEE paleturquoise'
	,'#DB7093 palevioletred'
	// ,'#FFEFD5 papayawhip'
	,'#FFDAB9 peachpuff'
	,'#CD853F peru'
	,'#FFC0CB pink'
	,'#DDA0DD plum'
	,'#B0E0E6 powderblue'
	,'#800080 purple'
	,'#FF0000 red'
	,'#BC8F8F rosybrown'
	,'#4169E1 royalblue'
	,'#8B4513 saddlebrown'
	,'#FA8072 salmon'
	// ,'#FAA460 sandybrown'
	,'#2E8B57 seagreen'
	// ,'#FFF5EE seashell'
	,'#A0522D sienna'
	,'#C0C0C0 silver'
	,'#87CEEB skyblue'
	,'#6A5ACD slateblue'
	,'#708090 slategray'
	// ,'#FFFAFA snow'
	,'#00FF7F springgreen'
	,'#4682B4 steelblue'
	,'#D2B48C tan'
	,'#008080 teal'
	,'#D8BFD8 thistle'
	,'#FF6347 tomato'
	,'#40E0D0 turquoise'
	,'#EE82EE violet'
	,'#F5DEB3 wheat'
	// ,'#FFFFFF white'
	// ,'#F5F5F5 whitesmoke'
	,'#FFFF00 yellow'
	,'#9ACD32 yellowgreen'
    )
}
