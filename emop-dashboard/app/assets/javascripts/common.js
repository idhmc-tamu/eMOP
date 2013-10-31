/*global $, alert */

var showWaitPopup = function( message ) {
   $('#dim-overlay').show();
   $("#wait-spinner").show();
   $("#wait-msg").text(message);
   $("#wait-msg").show();
   $('#wait-popup').show();
};

var hideWaitPopup = function() {
   $('#dim-overlay').hide();
   $("#wait-popup").hide();
};


$.fn.hasScrollBar = function() {
   return this.get(0).scrollHeight > this.height();
};
$.fn.exists = function() {
   return this.length !== 0;
};

var batches = [];
var jobTypes = [];
var engines = [];
var createBatchHandler = null;
var rescheduleHandler = null;

var setCreateBatchHandler = function( handler ) {
   createBatchHandler = handler;
};
var setRescheduleHandler = function( handler ) {
   rescheduleHandler = handler;
};

$(function() {
   // grab json batch info and convert into js objects/arrays
   batches = JSON.parse( $("#batches-json").text() );
   jobTypes = JSON.parse( $("#types-json").text() );
   engines = JSON.parse( $("#engines-json").text() );
   
   var updateFontColumn = function(works, fntName) {
      $.each(JSON.parse(works), function(idx, val) {
         $(".sel-cb[id^=sel-" + val+"]").each( function() {
            var row = $(this).parent().parent();
            row.find("td").each(function(index) {
               if (index === 8) {
                  $(this).text(fntName);
               }
            });
         });
      });
   }; 

   var setPrintFont = function() {
      data = {};
      data.works = $("#font-work-id-list").text();
      data.font_id = $("#new-print-font").val();
      var fntName = $("#new-print-font option:selected").text();
      if (fntName === "None") {
         fntName = "";
      }
      showWaitPopup("Setting Print Font");
      $.ajax({
         url : "fonts/print_font",
         type : 'POST',
         data : data,
         success : function(resp, textStatus, jqXHR) {
            if ( $("#results-detail").exists()) {
               $("#work-print-font").text(fntName);
            } else {
               updateFontColumn(data.works, fntName);
            }
            hideWaitPopup();
            $("#set-font-popup").dialog("close");
         },
         error : function(jqXHR, textStatus, errorThrown) {
            hideWaitPopup();
            alert(errorThrown + ":" + jqXHR.responseText);
         }
      });
   }; 
   
   var createPrintFont = function() {
      data = {};
      data.works = $("#font-work-id-list").text();
      data.new_font = $("#new-font-name").val();
      var fntName =  data.new_font;
      showWaitPopup("Creating Print Font");
      $.ajax({
         url : "fonts/print_font",
         type : 'POST',
         data : data,
         success : function(resp, textStatus, jqXHR) {
            if ( $("#results-detail").exists()) {
               $("#work-print-font").text(fntName);
            } else {
               updateFontColumn(data.works, fntName);
            }
            hideWaitPopup();
            $("#set-font-popup").dialog("close");
         },
         error : function(jqXHR, textStatus, errorThrown) {
            hideWaitPopup();
            alert(errorThrown + ":" + jqXHR.responseText);
         }
      });
   }; 
   
   // print font popup
   $("#set-font-popup").dialog({
      autoOpen : false,
      width : 250,
      resizable : false,
      modal : true,
      buttons : {
         "Cancel" : function() {
            if ( $("#sel-pf-div").is(":visible") ) {
               $(this).dialog("close");
            } else  {
               $("#sel-pf-div").show();
               $("#new-font-name").hide();
            }
         },
         "Set Font" : function() {
            if ( $("#sel-pf-div").is(":visible") ) {
               setPrintFont();
            } else {
               createPrintFont();
            }
         }
      }
   }); 
   
   // resubmit confirm popup
   $("#confirm-resubmit-popup").dialog({
      autoOpen : false,
      resizable : false,
      modal : true,
      buttons : {
         "Cancel" : function() {
            $(this).dialog("close");
         },
         "Reschedule" : function() {
            if ( rescheduleHandler !== null ) {
               rescheduleHandler();
            }
         },
         "New Batch" : function() {
            var json = $("#resubmit-data").text()
            var parsed = $.parseJSON(json);
            if ( parsed.type === 'page' ) {
               $("#batch-json").text( json );
            } else {
               workIds = [];
               $.each(parsed.detail, function(idx, val) {
                  workIds.push(val.work);
               });
               $("#batch-json").text( JSON.stringify({works: workIds}) );
            }
            $("#new-batch-popup").dialog("open");
            $(this).dialog("close");
         },
      }
   });

      
   // create new batch popup
   $("#new-batch-popup").dialog({
      autoOpen : false,
      width : 390,
      resizable : false,
      modal : true,
      buttons : {
         "Cancel" : function() {
            $(this).dialog("close");
         },
         "Create" : function() {
            if ( createBatchHandler !== null ) {
               createBatchHandler();
            }
         }
      },
      open : function() {
         $("#new-batch-error").text("");
         $("#new-name").val("");
         $("#new-params").val("");
         $("#new-notes").val("");
         $("#new-batch-error").hide();
         $("#new-ocr").val("2");
         $("#new-type").val("2");
      }
   }); 

   $("#new-type").on("change", function() {
       var idx = parseInt($("#new-type").val(),10)-1;
       if ( idx === 2 ) {
          $("#new-batch-popup .engine-row").hide();
          $("#new-batch-popup .font-row").hide();
          $("#new-batch-popup .font-detail").hide();
       } if ( idx === 0 ) {
          $("#new-batch-popup .engine-row").show();
          $("#new-ocr").val("1");
          $("#new-batch-popup .font-row").hide();
          $("#new-batch-popup .font-detail").hide();
       } else {
          $("#new-batch-popup .engine-row").show();
          $("#new-ocr").val("2");
          $("#new-batch-popup .font-row").show();
          $("#new-batch-popup .font-detail").show();
       }
   });
   
   
   // create new FONT popup
   $("#new-font-popup").dialog({
      autoOpen : false,
      width : 350,
      resizable : false,
      modal : true,
      buttons : {
         "Cancel" : function() {
            $(this).dialog("close");
         },
         "Create" : function() {
            if ( $("#font-name").val().length === 0) {
               alert("Name is required");
               return;
            }
            if ( $("#font-file").val().length === 0) {
               alert("A training font file is required");
               return;
            }
            $('#font-upload-form').submit();
         }
      },
      open : function() {
        $("#font-name").val("");
      }
   }); 
   $("#create-print-font").on("click", function() {
      $("#sel-pf-div").hide();
      $("#new-font-name").show();
   });
   
   var uploadFontSuccess = function(json, statusText, xhr, form) {
      hideWaitPopup();
      $("#new-font").append($("<option></option>")
         .attr("value",json.font_id)
         .attr('selected', 'selected')
         .text(json.font_name)); 
      $("#new-font-popup").dialog("close");
   };

   var uploadFontFailed = function(jqXHR, statusText, xhr, form) {
      hideWaitPopup();
      alert("Upload Font Failed:\n\n"+jqXHR.responseText);
   };
   
   // bind font create submit to an ajax submit with listeners
   // for pre and post submit events
   var options = {
      error : uploadFontFailed,
      success : uploadFontSuccess,
      dataType: "json" 
   };
   $('#font-upload-form').submit(function() {
      showWaitPopup("Creating font");
      $(this).ajaxSubmit(options);

      // !!! Important !!!
      // always return false to prevent standard browser submit and page navigation
      return false;
   });
   
   $("#upload-font").on("click", function() {
      $("#new-font-popup").dialog("open");
   });

});
