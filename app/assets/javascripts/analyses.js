$(function () {
  $(".has_analysis_modal").on("click", "i.fa.fa-search[analysis_id]", function() {
    var analysis_id = $(this).attr("analysis_id");
    $('#analyses_list_modal').modal("show", {
      analysis_id: analysis_id
    });
  });
  $("#analyses_list_modal").on('show.bs.modal', function (event) {
    var analysis_id = event.relatedTarget.analysis_id;
    $.get("/analyses/"+analysis_id+"/_result", function(data) {
      $("#analyses_list_modal_page").append(data);
    });
  });

  $("#analyses_list_modal").on('hidden.bs.modal', function (event) {
    $('#analyses_list_modal_page').empty();
  });
});

$(function() {
  var datatables_for_analyses_table = function() {
    var oTable = $('#analyses_list').DataTable({
      processing: true,
      serverSide: true,
      bFilter: false,
      order: [[6, "desc"]],
      destroy: true,
      "columnDefs": [{
        "searchable": false,
        "orderable": false,
        "targets": [0, -1]
      }],
      ajax: $('#analyses_list').data('source')
    });
    $('#analyses_list_length').append(
      '<i class="fa fa-refresh clickable padding-half-em" id="analyses_list_refresh"></i>'
    );
    var refresh_icon = $('#analyses_list_length').children('#analyses_list_refresh');
    refresh_icon.on('click', function() { oTable.ajax.reload(null, false); });
    return oTable;
  };

  window.datatables_for_analyses_table = datatables_for_analyses_table;
});
