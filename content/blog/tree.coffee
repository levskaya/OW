---
extends: false
uses_template: false
---

# Recursive Tree Drawing Example

# bring in the maths
rnd=Math.random
log=Math.log
floor=Math.floor
sin=Math.sin
cos=Math.cos
abs=Math.abs
pi=Math.PI
sqrt2=Math.SQRT2

# grab handles to element, context
canvas=$('#canvas')
ctxH=canvas.height()
ctxW=canvas.width()
ctx = canvas[0].getContext("2d")

# global vars
curlx = 0
curly = 0
f = sqrt2/2
delay = 1
growth = 0
growthTarget = 0
# global event vars
mouseX=0
mouseY=0

# draws a line in ctx from (x0,y0) to (x1,y1)
line = (ctx,x0,y0,x1,y1) ->
  ctx.beginPath()
  ctx.moveTo(x0,y0)
  ctx.lineTo(x1,y1)
  ctx.closePath()
  ctx.stroke()

# recursive branch drawing routine
branch = (len, num) ->
  len *= f
  num -= 1
  if len>1 and num>0
    ctx.save()
    ctx.rotate(curlx)
    line(ctx,0,0,0,-len)
    ctx.translate(0,-len)
    branch(len,num)
    ctx.restore()

    len *= growth
    ctx.save()
    ctx.rotate(curlx-curly)
    line(ctx,0,0,0,-len)
    ctx.translate(0,-len)
    branch(len,num)
    ctx.restore()

# Main Drawing Loop
draw = () ->
    # precompute the parameter deltas
    dgrowth = (growthTarget/10-growth+1)/delay
    dcurlx = ((2*pi/ctxW*mouseX)-curlx)/delay
    dcurly = ((2*pi/ctxH*mouseY)-curly)/delay

    # if nothing needs updating don't waste CPU redrawing scene
    if abs(dgrowth) >.001 or abs(dcurlx) >.001 or abs(dcurly)>.001

      ctx.save()
      ctx.fillStyle='#ffffff'
      #ctx.fillRect(0,0,ctxW,ctxH)
      ctx.clearRect(0,0,ctxW,ctxH)

      curlx += dcurlx
      curly += dcurly

      ctx.translate(ctxW/2,ctxH/3*2)
      line(ctx,0,0,0,ctxH/2)
      branch(ctxH/4,17)

      growth += dgrowth

      ctx.restore()

    # better/worse than setinterval?
    setTimeout(draw,100)

# Event Handlers
canvas.mousemove(
  (e) ->
    mouseX = e.pageX-this.offsetLeft
    mouseY = e.pageY-this.offsetTop
    $('#foo1').text(sprintf("%2.2f",2*pi/ctxW*mouseX))
    $('#foo2').text(sprintf("%2.2f",2*pi/ctxH*mouseY))
  )
canvas.mousewheel(
  (e,d,dX,dY) ->
   growthTarget += d
   e.preventDefault()
)

# Kick it off
draw()


