$("#school_town_id").empty().append("<%= escape_javascript(render(:partial => @towns)) %>")