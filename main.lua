----------------------------------------------------------------
-- Copyright (c) 2013 Microcosm Studios, LLC 
-- All Rights Reserved. 
----------------------------------------------------------------
require 'string'
require 'math'

hershey = require 'hershey'   -- pull in hershey fonts

function init_all()
    -- initialize graphics context
    MOAISim.openWindow ( "test", 1280, 720 )
    -- get the frame buffer object and clear it out
    framebuffer = MOAIGfxDevice.getFrameBuffer()
    framebuffer:setClearDepth(true)
    framebuffer:setClearColor(0,0,0,1)

    viewport = MOAIViewport.new ()
    viewport:setSize ( 1280, 720 )
    viewport:setScale ( 1280, 720 )

    ---------------------------------
    ---- initialize sound system ----
    ---------------------------------
    
    MOAIUntzSystem.initialize ()
    MOAIUntzSystem.setVolume(0.5)

    -- create a view layer
    layer = MOAILayer.new ()
    layer:setViewport ( viewport )
    layer:setSortMode ( MOAILayer.SORT_NONE ) -- don't need layer sort
    
    -- render across layer
    MOAISim.pushRenderPass ( layer )

    -- create the standard vertex format --
    vertexFormat = MOAIVertexFormat.new ()

    vertexFormat:declareCoord ( 1, MOAIVertexFormat.GL_FLOAT, 3 )
    vertexFormat:declareUV ( 2, MOAIVertexFormat.GL_FLOAT, 2 )
    vertexFormat:declareColor ( 3, MOAIVertexFormat.GL_UNSIGNED_BYTE )

    -- create a color spectrum texture --
    lineTexture = MOAITexture.new()
    lineTexture:load("white.png")

    --- create font test vector strings ---
    banner = ' !"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~'
    banner = banner .. string.char(127)

    line1 = banner:sub(1,32)
    line2 = banner:sub(33,60)
    line3 = banner:sub(61,127)

    vStr1 = vectorString(line1)
    vStr2 = vectorString(line2)
    vStr3 = vectorString(line3)

    -- create a primitive sign --
    -- a bare transform node represents the origin of the signs model space --
    sign = MOAITransform.new()
    
    -- create the sign label / title and color --
    vStr4 = vectorString("VCS: Vector Construction Set");  vStr4:setColor(0,1,0);
    vStr5 = vectorString("subsystem test"); vStr5:setColor(1,0,0)
    
    -- bind the label to the sign space and position it at center --
    vStr4:setParent(sign); vStr4:setLoc(-415,-12.5,0); vStr4:setScl(2)
    vStr5:setParent(sign); vStr5:setLoc(-105,-30,0);  
    
    -- set the locations and scale of the demo text --
    vStr1:setLoc(50,0,375); vStr1:setColor(1,.75,0); 
    vStr2:setLoc(50,0,550); vStr2:setColor(0,1,1); 
    vStr3:setLoc(50,0,725); vStr3:setColor(1,0,1); 
    sign:setLoc(300,0,1000); --sign:setScl(2);

    -- set default colors --
    defColor(vStr1,1,.75,0); defColor(vStr2,0,1,1); defColor(vStr3,1,0,1); defColor(vStr4,0,1,0); defColor(vStr5,1,0,0)

    -- set brightness (attenuation) --
    vStr1.brite = true; vStr2.brite = true; vStr3.brite = true; vStr4.brite = true; vStr5.brite = true
    switchLites(vStr1); switchLites(vStr2); switchLites(vStr3); switchLites(vStr4); switchLites(vStr5)

    -- put them in the rendering layer
    layer:insertProp ( vStr1 )
    layer:insertProp ( vStr2 )
    layer:insertProp ( vStr3 )
    layer:insertProp ( vStr4 )
    layer:insertProp ( vStr5 )
    
    --- create the hex sprites ---

    -- hex sprite, so compute hexagon
    radius = 25
    -- create the hexagon geometry
    hexagon = makePoly(6,radius,0)
    -- generate a geometry mesh with pen width 1
    hMesh = vMesh(hexagon,1)

    -- create the "hextile" from the mesh template --
    --     (automatically inserts into layer)      --
    hxsprites = hexTile(hexagon,hMesh,radius,layer)

    -- configure the RGB hexagon group colors --
    for i=0,2 do
        for j=1,9 do
            hxsprites[3*i+1][j]:setColor(1,0,0)  -- red
            hxsprites[3*i+1][j].color = {1,0,0}  -- red
            --- rotate the green rows about the y-axis ---
            hxsprites[3*i+2][j]:setColor(0,1,0)  -- green
            hxsprites[3*i+2][j].color = {0,1,0}  -- green
            --- rotate the blue rows about the x-axis ---
            hxsprites[3*i+3][j]:setColor(0,.25,1)  -- blue
            hxsprites[3*i+3][j].color = {0,.25,1}  -- blue
        end
    end

    --- how about some friends from asteroids? ---

    rocketPoly = { {0,0,0}, {-17.5, -15, 0}, {0, 30, 0}, {17.5, -15, 0} }
    thrustPoly = { {0,-2,0}, {4.375, -5.75, 0}, {0, -13.25, 0}, {-4.375, -5.75,0} }
    rocket = makeSprite(vMesh(rocketPoly,1), 0,0,0)
    thruster = makeSprite(vMesh(thrustPoly,2), 0,0,0)
    thruster:setParent(rocket)
    rocket:setColor(.7,.7,.7)
    thruster:setColor(0,.2, .4)
    layer:insertProp(rocket)
    layer:insertProp(thruster)

    -- setup "thruster" sound effect for onscreen text --
    retro = MOAIUntzSound.new()
    retro:load("retro-fire.wav")
    retro:setVolume(1)
    retro:setLooping(false)

    --- now setup the proscenium ---
    
    -- the vanishing point --
    hlateral = 200000
    hdist = 100000

    -- and the horizon --
    hpoly = { {-hlateral, 0, -hdist}, {hlateral,0,-hdist}, {hlateral,0,-hdist}, {-hlateral, 0, -hdist }}
    horizon = makeSprite(vMesh(hpoly,4),0,0,0)
    horizon:setColor ( .05, .05, .05 )
    layer:insertProp ( horizon )

    -- create the road to nowhere --
    rwid = 600
    rlen = 110000

    rpoly = { {0, -5, -hdist}, {0,-5, rlen - hdist}, {rwid, -5, rlen - hdist}, {rwid, -5, -hdist} }
    road = makeSprite(vMesh(rpoly,1), 0,0,0)
    road:setColor ( .25, .25, .25 )
    --road:setParent ( horizon )
    layer:insertProp ( road )

    -- attach the font demos to the road --
    --vStr1:setParent ( road )
    --vStr2:setParent ( road )
    --vStr3:setParent ( road )

    -- setup initial camera view
    camera = MOAICamera.new ()
    near = camera:getFocalLength ( 1280 )
    camera:setLoc ( 50, -20, 0)
    camera:setFarPlane( 120000 )
    layer:setCamera ( camera )

end 

function makeSprite(mesh,x,y,z)
    local sprite = MOAIProp.new ()
    sprite:setDeck ( mesh )
    sprite:setCullMode ( MOAIProp.CULL_NONE )
    sprite:setDepthTest ( MOAIProp.DEPTH_TEST_LESS_EQUAL )
    sprite:setBlendMode ( MOAIProp.BLEND_ADD )
    sprite:setLoc(x,y,z)
    return sprite   
end

-- generates a polygon coordinate list given #sides, radius & start angle
function makePoly(sides, radius, start)
    local theta = start
    local delta = (2*math.pi)/sides

    local poly = {}
    for vertex = 1, sides do
        poly[vertex] = {radius * math.cos(theta), radius * math.sin(theta), 0}
        theta = theta + delta
    end
    
    return poly
end


-- creates a vector mesh from the polygon coord list
function vMesh(poly, pen)
    -- need a vertex buffer to image the polygon vectors into
    local vbo = MOAIVertexBuffer.new ()

    -- define the vertex type
    --local vertexFormat = MOAIVertexFormat.new ()

    -- our sprites are 3D because they might need to be rotated in 3space for special effects
    -- coordinates are 3 GL floats, UV vector is 2 GL floats and color is (unsigned byte?)
    vbo:setFormat ( vertexFormat )

    -- reserve enough space for this poly
    vbo:reserveVerts ( #poly )

    -- store the polygon into the vertex buffer
    for i=1,#poly do
        -- write vertex
        vbo:writeFloat ( poly[i][1], poly[i][2], poly[i][3] )
        vbo:writeFloat ( 0, 1 )
        vbo:writeColor32 ( 1, 1, 1 )
    end

    -- sync vertex buffer with GPU (probably)
    vbo:bless ()

    -- generate a mesh to hold the VBO geometry and attributes
    -- set the u,v color map and mesh type
    local mesh = MOAIMesh.new ()
    local txt = mesh:setTexture ( lineTexture )

    -- drop the VBO into the mesh
    mesh:setVertexBuffer ( vbo )
    mesh:setPrimType ( MOAIMesh.GL_LINE_LOOP )
    mesh:setPenWidth ( pen )

    return mesh
end

-- generates an array of hexagon sprites into layer
-- returns the sprite (prop2D) array
function hexTile(hexagon,mesh,radius,layer)
    -- compute tiling metrics
    -- start tiling at 1/2 height and width

    -- retrieve the row and col offset parameters --
    local x1 = hexagon[2][1]
    local y1 = hexagon[2][2]

    local x_off = 2 * radius + x1
    local cury = 0
    local curx = 0
    local tile = {}

    local nextrow = y1
    local coloffset = radius + x1
    local nextcol = 2 * coloffset

    for row=1,9 do
        tile[row] = {}
        -- alternate tiling offset
        if x_off ~= radius then
            x_off = radius
        else
            x_off = 2* radius + x1
        end
        curx = -radius

        for col=1,9 do
            local sprite = makeSprite(mesh,x_off + curx, cury, 0)
            -- insert the new hexagon sprite prop into the layer
            layer:insertProp ( sprite )

            -- save original x,y,z in sprite to return home --
            sprite.homeX = x_off + curx
            sprite.homeY = cury
            sprite.homeZ = 0
            tile[row][col] = sprite
            curx = curx + nextcol
        end
        cury = cury + nextrow
    end
    return tile
end


-- function takes a string and renders it as a static VBO/Mesh and returns sprite prop
function vectorString(str)

    -- compute the total number of vectors required    
    local vectors = 0
	for i=1,#str do
        vectors = vectors + #hershey.rowmans[string.byte(str:sub(i,i)) - 31].glyph / 2
    end

    -- reserve the space
    local svbo = MOAIVertexBuffer.new ()
    svbo:setFormat ( vertexFormat )
    svbo:reserveVerts ( vectors )

    -- render the string
    local xoff = 0

    for i=1,#str do
        -- extract glyph for this character
        local chr = string.byte(str:sub(i,i)) - 31

        local glyph = hershey.rowmans[chr]

        -- paint the glyph
        for j=0, (#(glyph.glyph) -2) / 2 do
            -- x,y,z; uv and color --
            local x = glyph.glyph[2*j+1]
            local y = hershey.rowmans.height - glyph.glyph[2*j+2]
            svbo:writeFloat(x+xoff,y, 0)
            svbo:writeFloat(0,1)
            svbo:writeColor32 ( 1, 1, 1)
        end

        -- heuristic to spread the characters out
        if glyph.realwidth < hershey.rowmans.height*.09 then
            xoff = xoff + glyph.width / 2 + 1
        else
            xoff = xoff + glyph.realwidth + 4
        end
        
    end

    -- sync vbo to gpu
    svbo:bless()

    -- now create the line mesh
    local smesh = MOAIMesh.new ()
    smesh:setTexture ( lineTexture  )
    smesh:setVertexBuffer ( svbo )
    smesh:setPrimType ( MOAIMesh.GL_LINES )
    smesh:setPenWidth ( 1 )

    -- sprite-i-fy
    local sprop = MOAIProp.new ()
    sprop:setDeck ( smesh )
    sprop:setCullMode ( MOAIProp.CULL_NONE )
    sprop:setDepthTest ( MOAIProp.DEPTH_TEST_LESS_EQUAL )
    sprop:setBlendMode ( MOAIProp.BLEND_ADD )
    return sprop
end

function defColor(sprite,r,g,b)
    sprite.iR = r
    sprite.iG = g
    sprite.iB = b
end

function switchLites(sprite)
    if sprite.brite then 
        sprite:setColor(sprite.iR / 2, sprite.iG / 2, sprite.iB / 2)
        sprite.brite = false
    else
        sprite:setColor(sprite.iR, sprite.iG, sprite.iB)
        sprite.brite = true
    end
end




--------------- animation coroutines ---------------

--------------------------------------------------------
--              camera dolly / crane                  --
--------------------------------------------------------
function camDolly()
    camera:moveLoc(240,150,near, 10)
    MOAICoroutine.blockOnAction(camera:moveRot(-4,0,0,8))
    while true do
        camera:moveRot(-15,0,0,11)
        MOAICoroutine.blockOnAction(camera:moveLoc(0,150,0,11))
        coroutine.yield()
        camera:moveRot(15,0,0,11)
        MOAICoroutine.blockOnAction(camera:moveLoc(0,-150,0,11))
        coroutine.yield()
    end
end


--------------------------------------------------------
--                hextile animation                   --
--------------------------------------------------------
function hexRotation()
    local pausetime = 0
    while true do
        -- increment total time
        pausetime = pausetime + .01

        --- rotate the hex grid ---
        for i=0,2 do
            for j=1,9 do
                --- rotate the red rows about the x-axis ---
                hxsprites[3*i+1][j]:setRot( 360*pausetime,0,0 )

                --- rotate the green rows about the y-axis ---
                hxsprites[3*i+2][j]:setRot( 0,360*pausetime,0 )

                --- rotate the blue rows about the x-axis ---
                hxsprites[3*i+3][j]:setRot( -360*pausetime,0,0 )
            end
        end
        coroutine.yield()
    end          
end

--------------------------------------------------------
--          galactic space patrol animation           --
--------------------------------------------------------
function spacePatrol()
    local sprite
    local timer = MOAITimer.new ()
    local function onEnd()
        timer:stop()    
    end

    timer:setListener ( MOAITimer.EVENT_TIMER_END_SPAN, onEnd )

    -- compute y-axis rotation components for x and z
    local sides = 12
    local side = 0
    local dtheta = 0             -- destination start angle
    local rtheta = math.pi      -- return start angle
    local delta = (2*math.pi)/sides
    local radius = 8000

    -- then do space patrol --
    while true do
        -- wait 10s to send them on patrol --
        timer:setSpan ( 10 )
        timer:start ()
        MOAICoroutine.blockOnAction(timer)
        
        -- send them on patrol in row, col order to computed vector
        for row = 1,9 do
            for col = 1,9 do
                sprite = hxsprites[row][col]
                sprite:moveRot(3600,0,0,1)
                sprite:seekLoc(radius * math.cos(dtheta),sprite.homeY*4,radius * math.sin(dtheta),1,MOAIEaseType.EASE_OUT)
                -- make it fade into distance --
                sprite:seekColor(0,0,0,1,1,MOAIEaseType.EASE_OUT)
                coroutine.yield()  
           end
        end

        -- explore for 2s --
        timer:setSpan ( 2 )
        timer:start ()
        MOAICoroutine.blockOnAction(timer)

        -- return them to base in row, col order
        for row = 1,9 do
            for col = 1,9 do
                sprite = hxsprites[row][col]
                sprite:setLoc(radius * math.cos(rtheta),sprite.homeY*4,radius * math.sin(rtheta))
                sprite:moveRot(3600,0,0,1)
                sprite:seekLoc(sprite.homeX,sprite.homeY,sprite.homeZ,1,MOAIEaseType.EASE_IN)
                -- bring back the original color
                sprite:seekColor(sprite.color[1],sprite.color[2],sprite.color[3],1,1,MOAIEaseType.EASE_IN)
                coroutine.yield()  
            end
        end

        -- compute new exploration heading --
        side = side + 1
        if side == sides then
            side = 0
            dtheta = 0
            rtheta = math.pi
        end

        dtheta = dtheta + delta
        rtheta = rtheta + delta
    end
end

--------------------------------------------------------
--                open road animation                 --
--------------------------------------------------------
function openRoad()
    while true do
            MOAICoroutine.blockOnAction( sign:moveLoc(0, 500, 0, 30) )
            coroutine.yield()
            MOAICoroutine.blockOnAction( sign:moveLoc(0, 0, 0, 30) )
            coroutine.yield()
    end
end
        
--------------------------------------------------------
--                  christmas lites                   --
--------------------------------------------------------
function briteLites()
    local c1=0; local c2=0; local c3=0; local c4=0; 
    while true do
        c1 = c1 + 1; c2 = c2 + 1; c3 = c3 + 1; c4 = c4 + 1;
         -- flip the light switches --
        if c1 == 25 then switchLites(vStr1); c1=0; end
        if c2 == 50 then switchLites(vStr2); c2=0; end
        if c3 == 75 then switchLites(vStr3); c3=0; end
        if c4 == 100 then
            switchLites(vStr4)
            switchLites(vStr5)
            c4 = 0
        end
        coroutine.yield()
    end
end

--------------------------------------------------------
--                title sign rotation                 --
--------------------------------------------------------
function rollTitle()
    local timer = MOAITimer.new ()
    local function onEnd()
        timer:stop()    
    end
    timer:setListener ( MOAITimer.EVENT_TIMER_END_SPAN, onEnd )

    -- fly the title in --
    MOAICoroutine.blockOnAction( sign:seekLoc(300,250,-100,12) )

    -- pause the title for 10s --
    while true do
        timer:setSpan ( 10 )
        timer:start ()
        MOAICoroutine.blockOnAction(timer)

        -- roll the title on Y axis
        MOAICoroutine.blockOnAction( sign:moveRot(360, 0, 0, 1.5) )
        MOAICoroutine.blockOnAction( sign:moveRot(0, 360, 0, 1.5) ) 
        coroutine.yield()
    end
end

--------------------------------------------------------
--              rocket ride animation                 --
--------------------------------------------------------
function rocketRide()
    local dx,dy,dz
    local hx,hy,hz

    while true do
        -- pick a destination to vector to --
        dx = math.random(600) 
        dy = math.random(450)
        dz = 0
        dt = math.random(10)  
        -- pick a destination heading to rotate to --
        hx = 0
        hy = 0
        hz = math.random(360)
        ht = math.random(10)   
        -- do it and wait --
        rocket:seekLoc(dx,dy,dz,dt)
        -- lite up thrust for 1/10th of the travel time
        retro:play()
        MOAICoroutine.blockOnAction(thruster:seekColor(.2,.9,1,1,dt/5,MOAIEaseType.EASE_IN))   
        --MOAICoroutine.blockOnAction(thruster:seekColor(.2,.9,1,1,dt/5))   
        -- turn it off again
        retro:stop()
        thruster:setColor(0,.2,.4)   
        MOAICoroutine.blockOnAction(rocket:moveRot(hx,hy,hz,ht))
        coroutine.yield()
    end
end



--------------------------------------------------------
--                  attract mode                      --
--------------------------------------------------------

function attractMode()
    -- turn on the xmas lights --
    local brite_lites = MOAICoroutine.new()
    brite_lites:run( briteLites )

    -- then start the hex rotation --
    local hex_rotation = MOAICoroutine.new()
    hex_rotation:run( hexRotation ) 

    -- start dollying the camera --
    local cam_dolly = MOAICoroutine.new()
    cam_dolly:run( camDolly )

    -- attract tasks --
    local space_patrol = MOAICoroutine.new()
    local roll_title = MOAICoroutine.new()
    local open_road = MOAICoroutine.new()
    local rocket_ride = MOAICoroutine.new()

    space_patrol:run(spacePatrol)
    roll_title:run(rollTitle) 
    --open_road:run(openRoad)
    rocket_ride:run(rocketRide)


end

--------- mainline ----------

init_all()

attract_mode = MOAICoroutine.new()
attract_mode:run ( attractMode )

 
