
# returns a (M,N) zero array
zeroarray = (N,M) -> ((0 for col in [M..1]) for row in [N..1])
zerovec = (N,M) -> (0 for col in [1..N*M])

# converts a RLE GOL rep into {1,0} array
#  - helper function
rlesplit = (str) ->
  splitatoms=str.match(/([0-9]*(b|o))/g)
  _.map(splitatoms,
      (str) ->
        if str.length>1
          [ Number(str[0..-2]), str[-1..] ]
        else
          [ 1, str ]
      )
NROWS = 0
NCOLS = 0
# - main routine
rletoarray = (rlestring) ->
  lines = rlestring.split("\n")
  #console.log lines.length, lines[0],lines[1]
  header=lines[0].match(/x\s*=\s*(\d+),\s*y\s*=\s*(\d+)/)
  cols = Number header[1]
  rows = Number header[2]
  NROWS = rows
  NCOLS = cols
  console.log cols, rows
  rlelines = lines[1..].join("").split('$')
  golarray = zeroarray(rows,cols)
  #console.log rlelines.length, rows, cols
  for i in [0..rlelines.length-1]
    #console.log i, "of", rlelines.length
    thisline=rlesplit(rlelines[i])
    j=0
    for op in thisline
      if op[1]=='b'
        j+=op[0]
      else
        for k in [0..op[0]-1]
          golarray[i][j+k]=1
        j+=op[0]

  golarray


vert_shader='''
  attribute vec3 aPos;
  attribute vec2 aTexCoord;
  varying   vec2 vTexCoord;
void main(void) {
   gl_Position = vec4(aPos, 1.);
   vTexCoord = aTexCoord;
}'''

frag_shader = (n)->
  """
  precision highp float;
    uniform sampler2D uTexSamp;
    varying vec2 vTexCoord;
    const float d = 1./#{n}.;
  void main(void) {
    float c = texture2D(uTexSamp, vTexCoord).x;
    int s = 0;
     if (texture2D(uTexSamp, vTexCoord + vec2(0., d)).x > 0.) s++;
     if (texture2D(uTexSamp, vTexCoord - vec2(0., d)).x > 0.) s++;
     if (texture2D(uTexSamp, vTexCoord + vec2(d, 0.)).x > 0.) s++;
     if (texture2D(uTexSamp, vTexCoord - vec2(d, 0.)).x > 0.) s++;
     if (texture2D(uTexSamp, vTexCoord + vec2(d,  d)).x > 0.) s++;
     if (texture2D(uTexSamp, vTexCoord - vec2(d,  d)).x > 0.) s++;
     if (texture2D(uTexSamp, vTexCoord + vec2(d, -d)).x > 0.) s++;
     if (texture2D(uTexSamp, vTexCoord - vec2(d, -d)).x > 0.) s++;
     if (c > 0.){
       if ((s == 2) || (s == 3)) gl_FragColor = vec4(1.);
       else gl_FragColor = vec4(vec3(0.),1.);}
     else if (s == 3) gl_FragColor = vec4(1.);
      else gl_FragColor = vec4(vec3(0.),1.);
  }"""

frag_shader_show = '''
precision highp float;
  uniform sampler2D uTexSamp;
  varying vec2 vTexCoord;
void main(void) {
  float c = texture2D(uTexSamp, vTexCoord).x;
  if(c>0.) {
    gl_FragColor = vec4(0.0,0.,0.,1.);
    }
  else {
    gl_FragColor = vec4(0.,0.,0.,0.);
  }
}'''

gl = {}
prog = {}
prog_show = {}
FBO = {}
FBO2 = {}
texture = {}
texture2 = {}
animation = {}
delay = 10
density = .04
it = 1
frames = 0
time = {}
timer = {}

PATTERN = rletoarray gunRLE


getShader = (gl, code, type) ->
  if type is "fragment"
    #console.log "[frag"
    shader = gl.createShader(gl.FRAGMENT_SHADER)
  else if type is "vertex"
    #console.log "[vert"
    shader = gl.createShader(gl.VERTEX_SHADER)

  gl.shaderSource(shader, code)
  gl.compileShader(shader)

  #console.log(gl.getShaderParameter(shader, gl.COMPILE_STATUS))
  #console.log("]")
  shader

requestAnimFrame = (->
  window.webkitRequestAnimationFrame or \
  window.mozRequestAnimationFrame or \
  (callback, element) -> setTimeout callback, 1000 / 60
)()

main = ->
  clearInterval timer
  c = document.getElementById("c")
  try
    gl = c.getContext("experimental-webgl", depth: false )
  unless gl
    alert "Your browser does not support WebGL"
    return

  prog = gl.createProgram()
  gl.attachShader prog, getShader(gl, vert_shader, "vertex")
  gl.attachShader prog, getShader(gl, frag_shader(1024), "fragment")
  gl.linkProgram prog

  prog_show = gl.createProgram()
  gl.attachShader prog_show, getShader(gl, vert_shader, "vertex")
  gl.attachShader prog_show, getShader(gl, frag_shader_show, "fragment")
  gl.linkProgram prog_show

  posBuffer = gl.createBuffer()
  gl.bindBuffer gl.ARRAY_BUFFER, posBuffer
  vertices = new Float32Array([ -1, -1, 0, 1, -1, 0, -1, 1, 0, 1, 1, 0 ])

  aPosLoc = gl.getAttribLocation(prog, "aPos")
  gl.enableVertexAttribArray aPosLoc

  aTexLoc = gl.getAttribLocation(prog, "aTexCoord")
  gl.enableVertexAttribArray aTexLoc

  texCoords = new Float32Array([ 0, 0, 1, 0, 0, 1, 1, 1 ])
  texCoordOffset = vertices.byteLength

  gl.bufferData gl.ARRAY_BUFFER, texCoordOffset + texCoords.byteLength, gl.STATIC_DRAW
  gl.bufferSubData gl.ARRAY_BUFFER, 0, vertices
  gl.bufferSubData gl.ARRAY_BUFFER, texCoordOffset, texCoords

  gl.vertexAttribPointer aPosLoc, 3, gl.FLOAT, gl.FALSE, 0, 0
  gl.vertexAttribPointer aTexLoc, 2, gl.FLOAT, gl.FALSE, 0, texCoordOffset

  texture = gl.createTexture()
  gl.bindTexture gl.TEXTURE_2D, texture
  gl.pixelStorei gl.UNPACK_ALIGNMENT, 1

  pixels = []#new Array(4194304)# []#zerovec(1024*4,1024)
  console.log pixels.length

  tSize = 1024
  for i in [0..tSize-1]
    for j in [0..tSize-1]
      idx = i*tSize*4+j*4
      if i<NROWS and j<NCOLS and PATTERN[i][j] >0
        pixels[idx+0] = 255
        pixels[idx+1] = 0
        pixels[idx+2] = 0
        pixels[idx+3] = 0
        #pixels.push 255,0,0,0
      else
        #pixels.push 0,0,0,0
        pixels[idx+0] = 0
        pixels[idx+1] = 0
        pixels[idx+2] = 0
        pixels[idx+3] = 0

  console.log pixels.length

  gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, tSize, tSize, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array(pixels)
  gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST
  gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST
  texture2 = gl.createTexture()
  gl.bindTexture gl.TEXTURE_2D, texture2
  gl.pixelStorei gl.UNPACK_ALIGNMENT, 1
  gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, tSize, tSize, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array(pixels)
  gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST
  gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST

  FBO = gl.createFramebuffer()
  gl.bindFramebuffer gl.FRAMEBUFFER, FBO
  gl.framebufferTexture2D gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0

  FBO2 = gl.createFramebuffer()
  gl.bindFramebuffer gl.FRAMEBUFFER, FBO2
  gl.framebufferTexture2D gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture2, 0

  timer = setInterval(fr, 500)
  time = new Date().getTime()
  animation = "animate"
  anim()
  #draw()
  #draw()

anim = ->
  draw()
  switch animation
    when "animate"
      setTimeout "requestAnimFrame(anim)", delay
    when "reset"
      main()

draw = ->
  gl.useProgram(prog)
  if it > 0
    gl.bindTexture gl.TEXTURE_2D, texture
    gl.bindFramebuffer gl.FRAMEBUFFER, FBO2
  else
    gl.bindTexture gl.TEXTURE_2D, texture2
    gl.bindFramebuffer gl.FRAMEBUFFER, FBO
  gl.drawArrays gl.TRIANGLE_STRIP, 0, 4

  gl.flush()
  gl.useProgram(prog_show)
  gl.bindFramebuffer gl.FRAMEBUFFER, null

  gl.drawArrays gl.TRIANGLE_STRIP, 0, 4
  gl.flush()
  it = -it
  frames++

setDelay = (v) ->
  delay = parseInt(v)
setDensity = (v) ->
  density = v.valueOf()
  animation = "reset"

fr = ->
  ti = new Date().getTime()
  fps = Math.round(1000 * frames / (ti - time))
  document.getElementById("framerate").value = fps
  frames = 0
  time = ti


#exports

window.main = main
window.anim = anim
window.requestAnimFrame = requestAnimFrame

