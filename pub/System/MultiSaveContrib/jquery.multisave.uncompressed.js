/*
 * jQuery MultiSave plugin 1.00
 *
 * Copyright (c) 2013-2022 Michael Daum http://michaeldaumconsulting.com
 *
 * Licensed under the GPL license http://www.gnu.org/licenses/gpl.html
 *
 */
"use strict";
jQuery(function($) {
  
  $(".jqMultiSave").livequery(function() {
    var $form = $(this), 
        $results = $("<div class='jqMultiSaveResults'></div>").appendTo($form),
        url = foswiki.getPreference("SCRIPTURL")+"/jsonrpc/MultiSaveContrib/save",
        formName = $form.attr("name");
       
    $results.hide();
    $form.attr("action", url).attr("method","post");
    $form.prepend("<input type='hidden' name='formName' value='"+formName+"' />");

    $form.ajaxForm({
      dataType:"json",

      beforeSerialize: function() {
        if (typeof(foswikiStrikeOne) !== 'undefined') {
          foswikiStrikeOne($form[0]);
        }
      },

      beforeSubmit: function() { 
        $results.hide();
        $.blockUI({message:'<h1>Saving ...</h1>'}); 
      },

      error: function(xhr, status) { 
        var json = $.parseJSON(xhr.responseText); 
        $.unblockUI(); 
        $results.show().html("<div class='foswikiErrorMessage'>Error: "+status+" "+json.error.message+"</div>"); 
      },

      success: function(data) { 
        var changes = 0; 

        $.unblockUI(); 
        $results.empty(); 

        if (typeof(data.result.success) !== 'undefined') { 
          $.each(data.result.success, function() { 
            changes++;
          }); 
        } 

        if (typeof(data.result.error) !== 'undefined') { 
          $.each(data.result.error, function(i, elem) { 
            $results.append("<div class='foswikiErrorMessage'>"+i+": "+elem+"</div>"); 
          }); 
        } 

        $results.show().append("<div class='foswikiSuccessMessage'>"+changes+" record(s) changed</div>"); 
      }
    });
  });
});
