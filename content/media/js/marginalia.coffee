###
<script type="text/javascript">
console.log($("#margin1").offset().top);

margintop=$("#margin1").offset().top;

$(".leftcolumn").append('<div class="marginnote" id="marginnote1">There has long been need of an ability to easily add marignal notes to complicated descriptions and such</div>');

preleft=$("#marginnote1").offset().left;

$("#marginnote1").offset({top: margintop, left: preleft});

</script>
###

sidebar = $(".leftcolumn")
ltmp=sidebar.offset().left

marginnotes=[]

$(".marginmarker").each(
  (index)->
    $(this).attr('id','marker'+index)
    notediv=$(this).children(".marginnote")
    notediv.attr('id', 'note'+index)
    notediv.detach()
    sidebar.append(notediv)
    ttmp=$(this).offset().top
    notediv.offset({top: ttmp, left: ltmp})
    notediv.removeClass("hidden")
)
