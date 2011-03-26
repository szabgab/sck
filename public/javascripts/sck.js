var SCK = function () {
    return {
        'closetabs' : function(){
            var sel = $('ul.tabs a.selected')
            sel.removeClass('selected');
            return sel;
        },
        'opentabs' : function(tab) {
            tab.addClass('selected');
            return tab;
        },
        'switchtab' : function(to) {
            //fadeIn and fadeOut new content
            var from = [];
            $('ul.tabs a').each(function(i,e) {
                from.push($(e).attr('href')+":visible");
            }); 

            $(from.join(',')).fadeOut('fast', function() {
                $(to).fadeIn('fast');
        });

        }
    }
}();

$('ul.tabs a').live('click', function(e) {
    e.preventDefault();
    var sel = SCK.closetabs();
    var nextsel = SCK.opentabs($(this));
    SCK.switchtab(nextsel.attr('href'));
});

$('input.readonly').live('keypress',function(e) {
    e.preventDefault();
});

$('button[href]').live('click',function(e) {
    e.preventDefault();
    var obj = $(this);
    window.open(obj.attr('href'), obj.attr('target'));
});

$('div#shortenform form').live('submit',function(e) {
    e.preventDefault();
    var data = $('div#shortenform form').serializeArray();
    var params={x:1};
    for(var i=0; i<data.length; i+=1) {
        params[data[i].name]=data[i].value;
    }
    console.log(params);
    $('div#shortenlinks').load('/', params, function() {
        SCK.switchtab($('div#shortenlinks'));
    });
});

$('div#shortenlinks form').live('submit',function(e) {
    e.preventDefault();
    SCK.switchtab($('div#shortenform'));
});

