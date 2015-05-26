function create_parameter_sets_list(selector, default_length) {
  var oPsTable = $(selector).DataTable({
    processing: true,
    serverSide: true,
    searching: false,
    order: [[ 3, "desc" ]],
    autoWidth: false,
    pageLength: default_length,
    ajax: $(selector).data('source')
  });
  $(selector+'_length').append(
    '<i class="fa fa-refresh padding-8 clickable" id="params_list_refresh"></i>'
  );
  $('#params_list_length').children('#params_list_refresh').on('click', function() {
    oPsTable.ajax.reload(null, false);
  });

  if( window.bEnableAutoReload ) {
    setInterval( function() {
      var num_open = $(selector + ' img.treebtn[state="open"]').length;
      if( num_open == 0 ) { oPsTable.ajax.reload(null, false); }
    }, 5000);
  }

  $(selector).on("click", "i.fa.fa-plus-square-o[parameter_set_id]", function() {
    var param_id = $(this).attr("parameter_set_id");
    $('#runs_list_modal').modal("show", {
      parameter_set_id: param_id
    });
  });
  return oPsTable;
}

$(function() {
  $("#runs_list_modal").on('show.bs.modal', function (event) {
    var param_id = event.relatedTarget.parameter_set_id;
    $.get("/parameter_sets/"+param_id+"/_runs_and_analyses", function(data) {
      toggle_auto_reload_runs_table(true);
      toggle_auto_reload_analyses_table(true);
      $("#runs_list_modal_page").html("");
      $("#runs_list_modal_page").append(data);
    });
  });

  $("#runs_list_modal").on('hidden.bs.modal', function (event) {
    $('#runs_list_modal_page').empty();
    toggle_auto_reload_runs_table(false);
    toggle_auto_reload_analyses_table(false);
  });
});
