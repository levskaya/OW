# Margin Note Aligner
#
# Vertically aligns margin notes with their place markers in
# the text. The form left by the markdown plugin looks like:
#
# <span class="marginmarker">
#   <div class="marginnote">
#     the text of note
#   </div>
# </span>
#

sidebar = $(".leftcolumn")
gutterH=5

marginnotes=[]

# Find all of the temporary marginnote inline markers
$(".marginmarker").each(
  (index)->
    $(this).removeClass("hidden")
    # give out unique IDs
    $(this).attr('id','marker'+index)
    # wrap contents in new div and get the jquery obj for that
    # note: wrap() returns original contents for chaining, not the new div!
    $(this).contents().wrapAll('<div class="marginnote clearfix">')
    notediv=$(this).children(".marginnote")

    # give out unique IDs to link back to marker
    notediv.attr('id', 'note'+index)
    # pull it out of this marker span and save it for positioning loop
    # record the position of the marker
    notediv.detach()
    # have to add some content to get it laid out within surrounding element,
    # --> use hack to avoid leaving any trace by setting
    #     visibility to hidden and making font-size 0px
    $(this).text(".").addClass("placeholder")
    vpos=$(this).offset().top
    marginnotes.push([notediv,vpos])
  )

# go through divs, append to sidebar and add spacer elements to insure that they:
# 1 - line up with their markers and
# 2 - don't overlap with previous margin notes
currentPosition=sidebar.offset().top
for [note,markerPosition] in marginnotes
  # no overlap
  if markerPosition > currentPosition+gutterH
    sidebar.append($('<div class="marginspacer clearfix"> </div>').height(markerPosition-currentPosition))
    sidebar.append(note)
  # overlap occured, add a minimal "gutter" spacer
  else
    sidebar.append($('<div class="marginspacer clearfix"> </div>').height(gutterH))
    sidebar.append(note)

  # calculate new position
  currentPosition = note.offset().top + note.height()




