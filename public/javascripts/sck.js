
$(document).ready(function() {
    $('ul.tabs a').click(function(e) {
        e.preventDefault();
        var sel = $('ul.tabs a.selected');
        var nextSel = $(this);
        //select new tab
        sel.removeClass('selected');
        $(nextSel).addClass('selected');
        //fadeIn and fadeOut new content
        $(sel.attr('href')).fadeOut('fast', function() {
            $(nextSel.attr('href')).fadeIn('fast');
        });
    });
    
});
