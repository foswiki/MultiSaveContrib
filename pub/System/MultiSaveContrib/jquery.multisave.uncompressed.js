/*
 * jQuery MultiSave plugin 0.03
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

    $form.find("select, input, textarea").each(function() {
      var $this = $(this), origVal, 
          name = $this.attr("name");

      if ($this.is("[type='radio'],[type='checkbox']")) {
        origVal = $form.find("[name='"+name+"']:checked").val();
      } else {
        origVal = $this.val();
      }
      $this.data("origVal", origVal);

      $this.change(function() { 
        var origVal = $this.data("origVal"),
            newVal = $this.val();

        $form.find("[name='"+name+"']").parents("td").removeClass("jqMultiSaveChanged"); 
        if (origVal != newVal) {
          $(this).parents("td:first").addClass("jqMultiSaveChanged"); 
        }
      });
    });

    $form.addClass("jqMultiSaveInited").ajaxForm({
      dataType:"json",

      beforeSerialize: function() { 
        $form.find("select, input, textarea").each(function() { 
          $(this).attr("disabled", "disabled").addClass("jqMultiSaveDisabled");
        }); 
        $form.find(".jqMultiSaveChanged")
          .find("select, input, textarea")
          .removeAttr("disabled")
          .removeClass("jqMultiSaveDisabled");
      },

      beforeSubmit: function() { 
        $results.hide();
        $.blockUI({message:'<h1>Saving ...</h1>'}); 
      },

      error: function(xhr, status, error) { 
        var json = $.parseJSON(xhr.responseText); 
        $.unblockUI(); 
        $form.find(".jqMultiSaveDisabled").removeClass("jqMultiSaveDisabled").removeAttr("disabled");
        $results.show().html("<div class='foswikiErrorMessage'>Error: "+status+" "+json.error.message+"</div>"); 
      },

      success: function(data, status, xhr) { 
        var changes = 0; 

        $.unblockUI(); 
        $results.empty(); 
        $form.find(".jqMultiSaveDisabled").removeClass("jqMultiSaveDisabled").removeAttr("disabled");

        if (typeof(data.result.success) !== 'undefined') { 
          $.each(data.result.success, function(key) { 
            var selector = "[name^='multisave{"+key+"}{']";
            $form.find(selector).parents("td").removeClass("jqMultiSaveChanged");
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
