/*
 * jQuery MultiSave plugin 0.04
 *
 * Copyright (c) 2013-2014 Michael Daum http://michaeldaumconsulting.com
 *
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 */
jQuery(function($) {
"use strict";
  
  $(".jqMultiSave:not(.jqMultiSaveInited)").livequery(function() {
    var $form = $(this), 
        $results = $("<div class='jqMultiSaveResults'></div>").appendTo($form),
        url = foswiki.getPreference("SCRIPTURL")+"/jsonrpc/MultiSaveContrib/save",
        formName = $form.attr("name");
       
    $results.hide();
    $form.attr("action", url).attr("method","post");
    $form.prepend("<input type='hidden' name='formName' value='"+formName+"' />");

    $form.addClass("jqMultiSaveInited").ajaxForm({
      dataType:"json",

      beforeSubmit: function() { 
        $results.hide();
        $.blockUI({message:'<h1>Saving ...</h1>'}); 
      },

      error: function(xhr, status, error) { 
        var json = $.parseJSON(xhr.responseText); 
        $.unblockUI(); 
        $results.show().html("<div class='foswikiErrorMessage'>Error: "+status+" "+json.error.message+"</div>"); 
      },

      success: function(data, status, xhr) { 
        var changes = 0; 

        $.unblockUI(); 
        $results.empty(); 

        if (typeof(data.result.success) !== 'undefined') { 
          $.each(data.result.success, function(key) { 
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
