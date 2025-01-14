/*
 * jQuery MultiSave plugin 1.02
 *
 * Copyright (c) 2013-2025 Michael Daum http://michaeldaumconsulting.com
 *
 * Licensed under the GPL license http://www.gnu.org/licenses/gpl.html
 *
 */
"use strict";
jQuery(function($) {

  var defaults = {
    redirect: null,
    showMessage: true,
    message: "Saving ..."
  };
  
  $(".jqMultiSave").livequery(function() {
    var $form = $(this), 
        opts = $.extend({}, defaults, $form.data()),
        redirect = $form.find("[name=redirect]").val() || opts.redirect,
        $results = $("<div class='jqMultiSaveResults'></div>").appendTo($form),
        url = foswiki.getScriptUrlPath("jsonrpc", "MultiSaveContrib", "save"),
        formName = $form.attr("name");
       
    $results.hide();
    $form.attr("action", url).attr("method","post");

    if (formName) {
        $form.prepend("<input type='hidden' name='formName' value='"+formName+"' />");
    }

    $form.ajaxForm({
      dataType:"json",

      beforeSerialize: function() {
        if (typeof(foswikiStrikeOne) !== 'undefined') {
          foswikiStrikeOne($form[0]);
        }
      },

      beforeSubmit: function() { 
        $results.hide();
        $.blockUI({message:'<h1 class="i18n">'+opts.message+'</h1>'}); 
      },

      error: function(xhr, status) { 
        var json = $.parseJSON(xhr.responseText); 
        $.unblockUI(); 

        console.error(json.error.message);
        if (opts.showMessage) {
          $results.show().html("<div class='foswikiErrorMessage'>Error: "+status+" "+json.error.message+"</div>"); 
        } 
      },

      success: function(data) { 
        var changes = 0; 

        $.unblockUI(); 
        $results.empty(); 

        if (typeof(data.result.error) !== 'undefined') {
          console.error(data.result.error);
          if (opts.showMessage) {
            $.each(data.result.error, function(i, elem) { 
              $results.append("<div class='foswikiErrorMessage'>"+i+": "+elem+"</div>"); 
            }); 
          }
        } else {

          if (typeof(data.result.success) !== 'undefined') { 
            $.each(data.result.success, function() { 
              changes++;
            }); 
          } 

          if (opts.showMessage) {
            $results.show().append("<div class='foswikiSuccessMessage'>"+changes+" record(s) changed</div>"); 
          }

          if (redirect) {
            if (redirect === "reload") {
              window.location.reload();
            } else {
              window.location.href = redirect;
            }
          } 
        }
      }
    });
  });
});
