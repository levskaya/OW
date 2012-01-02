###
# Game of Life Routines for plotting GOL patterns in canvas elements
#
#
###

floor = Math.floor

#################################################################################################################
# Example Patterns

RLEexample = '''x = 87, y = 38
43bo$42bobo$41bo3bo$$35boob4o3b4oboo$35boo4booboo4boo$34bobbob3o3b3obo
bbo$$42bobo$40bobobobo$36boobo7boboo$36boo4bobo4boo$35bo3boo5boo3bo$
43bo$32bo9bobo9bo$24bo3b3ob3obo5bobo5bob3ob3o3bo$24boobo5boboo4booboo
4boobo5boboo$20b3obboobo3bo3bo4booboo4bo3bo3boboobb3o$20boobboob5obobb
o13bobbob5oboobboo$19bobbo5boboobobbooboobobobooboobboboobo5bobbo$24b
oo6b4ob3o7b3ob4o6boo$28bo4bo7bobobo7bo4bo$40booboboo$40boo3boo$5boboo
32booboo32boobo$b3obooboboo63booboboob3o$o6boobb4o24booboboboo24b4obb
oo6bo$boo3bo3bo4bo23bobbobobbo23bo4bo3bo3boo$13b3o5boo15bobobobobobo
15boo5b3o$19boboo16bobo3bobo16boobo$16boboo3boo5boo23boo5boo3boobo$15b
ooboobobo5boo9bo5bo9boo5bobobooboo$15boobo4boboobbooboobo6bobo6boboob
oobboobo4boboo$19boobobbob3obbobboo4booboo4boobbobb3obobboboo$25bo4bob
o3boobbo5bobboo3bobo4bo$26boboobb3obbo11bobb3obboobo$32boobobobbo5bobb
oboboo$33bobobob9obobobo!'''

RAWexample = '''.OOO...........OOO.
O.................O
.O..OOO.OOO.OOO..O.
...O..O.O.O.O..O...
.....OO.O.O.OO.....
.....O..O.O..O.....
....O...O.O...O....
........O.O........
......O.....O......
...................
......OOOOOOO......
.....OO.....OO.....'''


glider = '''...................
.......O...........
......O............
......OOO..........
...................
...................
...................
...................
...................'''


#################################################################################################################
# Crude Parsers
#
# at the moment these barely work, need to pre-strip whitespace, etc.
#

# returns a (M,N) zero array
zeroarray = (N,M) -> ((0 for col in [M..1]) for row in [N..1])
zerovec = (N,M) -> (0 for col in [N*M..1])

# returns a (M,N) ones array
onesarray = (N,M) -> ((1 for col in [M..1]) for row in [N..1])

# converts a raw GOL rep w. '.'=dead, "O"=live into {1,0} array
rawtoarray = (rawstring) ->
  lines = rawstring.split("\n")
  rows = lines.length
  cols = lines[0].length
  golarray = zeroarray(rows,cols)
  #console.log rows, cols, golarray
  for i in [0..rows-1]
    for j in [0..cols-1]
      if lines[i][j]=="O"
        golarray[i][j]=1
  golarray

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
# - main routine
rletoarray = (rlestring) ->
  lines = rlestring.split("\n")
  #console.log lines.length, lines[0],lines[1]
  header=lines[0].match(/x\s*=\s*(\d+),\s*y\s*=\s*(\d+)/)
  cols = Number header[1]
  rows = Number header[2]
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


#################################################################################################################
# Array Utility Functions

arraytovec = (ar) ->
  N=ar.length
  M=ar[0].length
  #console.log N,M, ar[0][0]
  newvec=zerovec(N*M)
  for i in [0..N-1]
    for j in [0..M-1]
      newvec[i*M+j] = ar[i][j]
  newvec

vectoarray = (vec,rowlen) ->
  N=vec.length/rowlen
  M=rowlen
  newar=zeroarray(N,M)
  for i in [0..N-1]
    for j in [0..M-1]
      newar[i][j] = vec[i*M+j]
  newar

# copies src into dest overwriting dest's cells
arraycopy = (src,dest,offsetx=0,offsety=0) ->
    srcN = src.length
    srcM = src[0].length
    for i in [0..srcN-1]
      for j in [0..srcM-1]
        dest[i+offsetx][j+offsety]=src[i][j]
    dest

# copies src into dest using arbitrary supplied fn(src bit, dest bit) -> new bit
# for xor, and, etc.
arraytodest = (src,dest,offsetx=0,offsety=0,fn = (s,d) -> s) ->
    srcN = src.length
    srcM = src[0].length
    for i in [0..srcN-1]
      for j in [0..srcM-1]
        dest[i+offsetx][j+offsety]=fn(src[i][j],dest[i+offsetx][j+offsety])
    dest

# prints array to console
logarray = (ar) ->
    console.log _.map(ar, (a)->a.join('')).join('\n')


#################################################################################################################
# Evolution Routines
#
# This is absolutely not meant for performance, obviously!  Just demoing small pieces.
# It can run up to 1024x1024 at about 5-10fps on a decent laptop.
#
# stupid optimizations don't do squat, the JIT is smarter than that.
# to get decent GOL performance you have to have pointers and careful
# control to data structures to take advantage of the cache.  it's
# super clever bit-twiddling, not JS's forte.
#

GOLevolve = (ar) ->
  N = ar.length
  M = ar[0].length

  #make new empty array for t+1 state
  newar = zeroarray(N,M)

  for i in [0..N-1]
    for j in [0..M-1]
      # count neighbors
      neighbors=0
      neighbors += ar[(i+N-1)%N][(j+M-1)%M]
      neighbors += ar[(i+N-1)%N][(j+M+0)%M]
      neighbors += ar[(i+N-1)%N][(j+M+1)%M]
      neighbors += ar[(i+N+0)%N][(j+M-1)%M]
      neighbors += ar[(i+N+0)%N][(j+M+1)%M]
      neighbors += ar[(i+N+1)%N][(j+M-1)%M]
      neighbors += ar[(i+N+1)%N][(j+M+0)%M]
      neighbors += ar[(i+N+1)%N][(j+M+1)%M]
      # this cell's state
      state = ar[i][j]

      # GOL rules
      if state is 0
        if neighbors is 3
          newar[i][j]=1
        else
          newar[i][j]=0

      if state is 1
        if (neighbors < 2 or neighbors > 3)
          newar[i][j]=0
        else
          newar[i][j]=1

  # return array
  newar

#################################################################################################################
# Test routine for "sparse update"

GOLarray=[]
GOLchangearray=[]
GOLinit=false
GOLevolve2 = (N,M) ->

  ar = GOLarray
  #N = ar.length
  #M = ar[0].length

  changes=[]

  if not GOLinit
    #make new empty array for t+1 state
    newar = zerovec(N*M)

    for i in [0..N-1]
      for j in [0..M-1]
        # count neighbors
        neighbors=0
        neighbors += ar[(i+N-1)%N*M + (j+M-1)%M]
        neighbors += ar[(i+N-1)%N*M + (j+M+0)%M]
        neighbors += ar[(i+N-1)%N*M + (j+M+1)%M]
        neighbors += ar[(i+N+0)%N*M + (j+M-1)%M]
        neighbors += ar[(i+N+0)%N*M + (j+M+1)%M]
        neighbors += ar[(i+N+1)%N*M + (j+M-1)%M]
        neighbors += ar[(i+N+1)%N*M + (j+M+0)%M]
        neighbors += ar[(i+N+1)%N*M + (j+M+1)%M]

        # this cell's state
        state = ar[i*M+j]

        changed=false
        # GOL rules
        if state is 0
          if neighbors is 3
            newar[i*M+j]=1
            changed=true
          else
            newar[i*M+j]=0

        if state is 1
          if (neighbors < 2 or neighbors > 3)
            newar[i*M+j]=0
            changed=true
          else
            newar[i*M+j]=1

        if changed
          changes.push (i-1)*M + j-1
          changes.push (i-1)*M + j
          changes.push (i-1)*M + j+1
          changes.push (i)*M + j-1
          changes.push (i)*M + j
          changes.push (i)*M + j+1
          changes.push (i+1)*M + j-1
          changes.push (i+1)*M + j
          changes.push (i+1)*M + j+1


    #console.log changes
    #GOLchangearray = _.uniq changes
    GOLchangearray = _.uniq(changes.sort(),true)

    GOLarray = newar
    GOLinit=true

  else
    newar = ar.slice(0)

    for change in GOLchangearray
      #[i,j] = change
      i=floor(change/M)
      j=change%M
      #console.log i,j, N, M
      # count neighbors
      neighbors=0
      neighbors += ar[(i+N-1)%N*M + (j+M-1)%M]
      neighbors += ar[(i+N-1)%N*M + (j+M+0)%M]
      neighbors += ar[(i+N-1)%N*M + (j+M+1)%M]
      neighbors += ar[(i+N+0)%N*M + (j+M-1)%M]
      neighbors += ar[(i+N+0)%N*M + (j+M+1)%M]
      neighbors += ar[(i+N+1)%N*M + (j+M-1)%M]
      neighbors += ar[(i+N+1)%N*M + (j+M+0)%M]
      neighbors += ar[(i+N+1)%N*M + (j+M+1)%M]
      # this cell's state
      state = ar[i*M+j]

      changed=false

      # GOL rules
      if state is 0
        if neighbors is 3
          newar[i*M+j]=1
          changed=true
        else
          newar[i*M+j]=0

      if state is 1
        if (neighbors < 2 or neighbors > 3)
          newar[i*M+j]=0
          changed=true
        else
          newar[i*M+j]=1

      if changed
        changes.push (i-1)*M + j-1
        changes.push (i-1)*M + j
        changes.push (i-1)*M + j+1
        changes.push (i)*M + j-1
        changes.push (i)*M + j
        changes.push (i)*M + j+1
        changes.push (i+1)*M + j-1
        changes.push (i+1)*M + j
        changes.push (i+1)*M + j+1

    GOLchangearray = _.uniq(changes.sort(),true)
    GOLarray = newar

    # return array
    #newar



#################################################################################################################
# Plotting Routines

plotarray = (ctx,ar,x,y,s,clr='black',clear=true) ->
  ctxH=ctx.canvas.height
  ctxW=ctx.canvas.width

  ctx.save()
  ctx.fillStyle=clr
  if clear then ctx.clearRect(0,0,ctxW,ctxH)
  for row in [0..ar.length-1]
    for col in [0..ar[0].length-1]
      if ar[row][col]==1
        ctx.fillRect(x+col*s,y+row*s,s,s)
  ctx.restore()

plotarray2 = (ctx,ar,x,y,s,clr='black',backclr='white') ->
  ctxH=ctx.canvas.height
  ctxW=ctx.canvas.width

  ctx.save()
  if backclr is 'clear'
    ctx.clearRect(0,0,ctxW,ctxH)
  else
    ctx.clearRect(0,0,ctxW,ctxH)
    ctx.fillStyle=backclr
    ctx.fillRect(0,0,ctxW,ctxH)
  ctx.fillStyle=clr
  for row in [0..ar.length-1]
    for col in [0..ar[0].length-1]
      if ar[row][col]==1
        ctx.fillRect(x+col*s,y+row*s,s,s)
  ctx.restore()


plotvec2 = (ctx,ar,rowlen,x,y,s,clr='black',backclr='white') ->
  ctxH=ctx.canvas.height
  ctxW=ctx.canvas.width

  N=ar.length/rowlen
  M=rowlen

  ctx.save()
  if backclr is 'clear'
    ctx.clearRect(0,0,ctxW,ctxH)
  else
    ctx.clearRect(0,0,ctxW,ctxH)
    ctx.fillStyle=backclr
    ctx.fillRect(0,0,ctxW,ctxH)
  ctx.fillStyle=clr
  for row in [0..N-1]
    for col in [0..M-1]
      if ar[row*M+col]==1
        ctx.fillRect(x+col*s,y+row*s,s,s)
  ctx.restore()


#################################################################################################################
# Driver Routine

# grab handles to element, context
canvas=$('#canvas')


#ctxH=canvas.height()
#ctxW=canvas.width()
ctx = canvas[0].getContext("2d")


#golexample = rawtoarray RAWexample
#golexample = rletoarray RLEexample
#golexample = rawtoarray glider
#golexample = arraycopy rletoarray(RLEexample), zeroarray(200,200), 30, 30

#GOLinit(golexample)


GOLarray = rletoarray gunRLE
N = GOLarray.length
M = GOLarray[0].length
#GOLarray = arraytovec(GOLarray)

#plotvec2(ctx,GOLarray,M,0,0,2,'rgb(100,100,100)','rgba(255,255,255,.3)')

#GOLbreak=false

canvas.mousedown(
  (e) ->
    #e.preventDefault()
    #golexample=GOLevolve(golexample)
    #GOLevolve2(N,M)
    #console.log GOLchangearray.length

    #plotarray2(ctx,GOLarray,0,0,2,'rgb(100,100,100)','rgba(255,255,255,.3)')
    #plotvec2(ctx,GOLarray,M,0,0,2,'rgb(100,100,100)','rgba(255,255,255,.3)')

    GOLbreak=true
)

GOLloop = () ->
    #GOLevolve2(N,M)
    #plotvec2(ctx,GOLarray,M,0,0,.5,'rgb(100,100,100)','rgba(255,255,255,.3)')
    #if not GOLbreak
    #  GOLloop()
    GOLarray=GOLevolve(GOLarray)
    plotarray2(ctx,GOLarray,0,0,.5,'rgb(100,100,100)','rgba(255,255,255,.3)')


window.setInterval(GOLloop,100);

#canvas2=$('#canvas2')
#ctx2 = canvas2[0].getContext("2d")
#golexample2 = rletoarray RLEexample
#plotarray2(ctx2,golexample2,0,0,1,'rgb(100,100,100)','rgba(255,255,255,.3)')
