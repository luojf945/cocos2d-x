local size = cc.Director:getInstance():getWinSize()
local MATERIAL_DEFAULT = cc.PhysicsMaterial(0.1, 0.5, 0.5)
local curLayer = nil
local STATIC_COLOR = cc.c4f(1.0, 0.0, 0.0, 1.0)
local DRAG_BODYS_TAG = 0x80

local function range(from, to, step)
  step = step or 1
  return function(_, lastvalue)
    local nextvalue = lastvalue + step
    if step > 0 and nextvalue <= to or step < 0 and nextvalue >= to or
       step == 0
    then
      return nextvalue
    end
  end, nil, from - step
end

local function initWithLayer(layer, callback)
   curLayer = layer
   layer.spriteTexture = cc.SpriteBatchNode:create("Images/grossini_dance_atlas.png", 100):getTexture()

   local debug = false
   local function toggleDebugCallback(sender)
      debug = not debug
      cc.Director:getInstance():getRunningScene():getPhysicsWorld():setDebugDrawMask(debug and cc.PhysicsWorld.DEBUGDRAW_ALL or cc.PhysicsWorld.DEBUGDRAW_NONE)
   end

   layer.toggleDebug = toggleDebugCallback;
   cc.MenuItemFont:setFontSize(18)
   local item = cc.MenuItemFont:create("Toogle debug")
   item:registerScriptTapHandler(toggleDebugCallback)
   local menu = cc.Menu:create(item)
   layer:addChild(menu)
   menu:setPosition(size.width - 50, size.height - 10)
   Helper.initWithLayer(layer)

   local function onNodeEvent(event)
        if "enter" == event then
            callback()
        end
    end
    layer:registerScriptHandler(onNodeEvent)
end

local function addGrossiniAtPosition(layer, p, scale)
   scale = scale or 1.0

   local posx = math.random() * 200.0
   local posy = math.random() * 100.0
   posx = (math.floor(posx) % 4) * 85
   posy = (math.floor(posy) % 3) * 121

   local sp = cc.Sprite:createWithTexture(layer.spriteTexture, cc.rect(posx, posy, 85, 121))
   sp:setScale(scale)
   sp:setPhysicsBody(cc.PhysicsBody:createBox(cc.size(48.0*scale, 108.0*scale)))
   layer:addChild(sp)
   sp:setPosition(p)
   return sp
end

local function onTouchBegan(touch, event)
    local location = touch:getLocation()
    local arr = cc.Director:getInstance():getRunningScene():getPhysicsWorld():getShapes(location)
    
    local body
    for _, obj in ipairs(arr) do
        if bit.band(obj:getBody():getTag(), DRAG_BODYS_TAG) ~= 0 then
            body = obj:getBody();
            break;
        end
    end
    
    if body then
        local mouse = cc.Node:create();
        mouse:setPhysicsBody(cc.PhysicsBody:create(PHYSICS_INFINITY, PHYSICS_INFINITY));
        mouse:getPhysicsBody():setDynamic(false);
        mouse:setPosition(location);
        curLayer:addChild(mouse);
        local joint = cc.PhysicsJointPin:construct(mouse:getPhysicsBody(), body, location);
        joint:setMaxForce(5000.0 * body:getMass());
        cc.Director:getInstance():getRunningScene():getPhysicsWorld():addJoint(joint);
        touch.mouse = mouse
        
        return true;
    end
    
    return false;
end

local function onTouchMoved(touch, event)
    if touch.mouse then
        touch.mouse:setPosition(touch:getLocation());
    end
end

local function onTouchEnded(touch, event)
    if touch.mouse then
        curLayer:removeChild(touch.mouse)
        touch.mouse = nil
    end
end

local function makeBall(layer, point, radius, material)
    material = material or MATERIAL_DEFAULT

    local ball
    if layer.ball then
       ball = cc.Sprite:createWithTexture(layer.ball:getTexture())
    else
       ball = cc.Sprite:create("Images/ball.png")
    end

    ball:setScale(0.13 * radius)

    local body = cc.PhysicsBody:createCircle(radius, material)
    ball:setPhysicsBody(body)
    ball:setPosition(point)

    return ball
end

local function makeBox(point, size, material)
    material = material or DEFAULT_MATERIAL
    local box = math.random() > 0.5 and cc.Sprite:create("Images/YellowSquare.png") or cc.Sprite:create("Images/CyanSquare.png");
    
    box:setScaleX(size.width/100.0);
    box:setScaleY(size.height/100.0);
    
    local body = cc.PhysicsBody:createBox(size);
    box:setPhysicsBody(body);
    box:setPosition(cc.p(point.x, point.y));
    
    return box;
end

local function makeTriangle(point, size, material)
    material = material or DEFAULT_MATERIAL
    local triangle = math.random() > 0.5 and cc.Sprite:create("Images/YellowTriangle.png") or cc.Sprite:create("Images/CyanTriangle.png");
    
    if size.height == 0 then
        triangle:setScale(size.width/100.0);
    else
        triangle:setScaleX(size.width/50.0)
        triangle:setScaleY(size.height/43.5)
    end
    
     vers = { cc.p(0, size.height/2), cc.p(size.width/2, -size.height/2), cc.p(-size.width/2, -size.height/2)};
    
    local body = cc.PhysicsBody:createPolygon(vers);
    triangle:setPhysicsBody(body);
    triangle:setPosition(point);
    
    return triangle;
end

local function PhysicsDemoClickAdd()
    local layer = cc.Layer:create()
    local function onEnter()
       local function onTouchEnded(touch, event)
	  local location = touch:getLocation();
	  addGrossiniAtPosition(layer, location)
       end
       
       local touchListener = cc.EventListenerTouchOneByOne:create()
       touchListener:registerScriptHandler(function() return true end, cc.Handler.EVENT_TOUCH_BEGAN) 
       touchListener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
       local eventDispatcher = layer:getEventDispatcher()
       eventDispatcher:addEventListenerWithSceneGraphPriority(touchListener, layer)

       addGrossiniAtPosition(layer, VisibleRect:center())
       
       local node = cc.Node:create()
       node:setPhysicsBody(cc.PhysicsBody:createEdgeBox(cc.size(VisibleRect:getVisibleRect().width, VisibleRect:getVisibleRect().height)))
       node:setPosition(VisibleRect:center())
       layer:addChild(node)
    end
    initWithLayer(layer, onEnter)
    Helper.titleLabel:setString("Grossini")
    Helper.subtitleLabel:setString("multi touch to add grossini")

    return layer
end

local function PhysicsDemoLogoSmash()
    local layer = cc.Layer:create()

    local function onEnter()
       local logo_width = 188.0
       local logo_height = 35.0
       local logo_raw_length = 24.0
       local logo_image = {
	  15,-16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,-64,15,63,-32,-2,0,0,0,0,0,0,0,
	  0,0,0,0,0,0,0,0,0,0,0,31,-64,15,127,-125,-1,-128,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	  0,0,0,127,-64,15,127,15,-1,-64,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,-1,-64,15,-2,
	  31,-1,-64,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,-1,-64,0,-4,63,-1,-32,0,0,0,0,0,0,
	  0,0,0,0,0,0,0,0,0,0,1,-1,-64,15,-8,127,-1,-32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	  1,-1,-64,0,-8,-15,-1,-32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,-31,-1,-64,15,-8,-32,
	     -1,-32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,-15,-1,-64,9,-15,-32,-1,-32,0,0,0,0,0,
	  0,0,0,0,0,0,0,0,0,0,31,-15,-1,-64,0,-15,-32,-1,-32,0,0,0,0,0,0,0,0,0,0,0,0,0,
	  0,0,63,-7,-1,-64,9,-29,-32,127,-61,-16,63,15,-61,-1,-8,31,-16,15,-8,126,7,-31,
	     -8,31,-65,-7,-1,-64,9,-29,-32,0,7,-8,127,-97,-25,-1,-2,63,-8,31,-4,-1,15,-13,
	     -4,63,-1,-3,-1,-64,9,-29,-32,0,7,-8,127,-97,-25,-1,-2,63,-8,31,-4,-1,15,-13,
	     -2,63,-1,-3,-1,-64,9,-29,-32,0,7,-8,127,-97,-25,-1,-1,63,-4,63,-4,-1,15,-13,
	     -2,63,-33,-1,-1,-32,9,-25,-32,0,7,-8,127,-97,-25,-1,-1,63,-4,63,-4,-1,15,-13,
	     -1,63,-33,-1,-1,-16,9,-25,-32,0,7,-8,127,-97,-25,-1,-1,63,-4,63,-4,-1,15,-13,
	     -1,63,-49,-1,-1,-8,9,-57,-32,0,7,-8,127,-97,-25,-8,-1,63,-2,127,-4,-1,15,-13,
	     -1,-65,-49,-1,-1,-4,9,-57,-32,0,7,-8,127,-97,-25,-8,-1,63,-2,127,-4,-1,15,-13,
	     -1,-65,-57,-1,-1,-2,9,-57,-32,0,7,-8,127,-97,-25,-8,-1,63,-2,127,-4,-1,15,-13,
	     -1,-1,-57,-1,-1,-1,9,-57,-32,0,7,-1,-1,-97,-25,-8,-1,63,-1,-1,-4,-1,15,-13,-1,
	     -1,-61,-1,-1,-1,-119,-57,-32,0,7,-1,-1,-97,-25,-8,-1,63,-1,-1,-4,-1,15,-13,-1,
	     -1,-61,-1,-1,-1,-55,-49,-32,0,7,-1,-1,-97,-25,-8,-1,63,-1,-1,-4,-1,15,-13,-1,
	     -1,-63,-1,-1,-1,-23,-49,-32,127,-57,-1,-1,-97,-25,-1,-1,63,-1,-1,-4,-1,15,-13,
	     -1,-1,-63,-1,-1,-1,-16,-49,-32,-1,-25,-1,-1,-97,-25,-1,-1,63,-33,-5,-4,-1,15,
	     -13,-1,-1,-64,-1,-9,-1,-7,-49,-32,-1,-25,-8,127,-97,-25,-1,-1,63,-33,-5,-4,-1,
	  15,-13,-1,-1,-64,-1,-13,-1,-32,-49,-32,-1,-25,-8,127,-97,-25,-1,-2,63,-49,-13,
	     -4,-1,15,-13,-1,-1,-64,127,-7,-1,-119,-17,-15,-1,-25,-8,127,-97,-25,-1,-2,63,
	     -49,-13,-4,-1,15,-13,-3,-1,-64,127,-8,-2,15,-17,-1,-1,-25,-8,127,-97,-25,-1,
	     -8,63,-49,-13,-4,-1,15,-13,-3,-1,-64,63,-4,120,0,-17,-1,-1,-25,-8,127,-97,-25,
	     -8,0,63,-57,-29,-4,-1,15,-13,-4,-1,-64,63,-4,0,15,-17,-1,-1,-25,-8,127,-97,
	     -25,-8,0,63,-57,-29,-4,-1,-1,-13,-4,-1,-64,31,-2,0,0,103,-1,-1,-57,-8,127,-97,
	     -25,-8,0,63,-57,-29,-4,-1,-1,-13,-4,127,-64,31,-2,0,15,103,-1,-1,-57,-8,127,
	     -97,-25,-8,0,63,-61,-61,-4,127,-1,-29,-4,127,-64,15,-8,0,0,55,-1,-1,-121,-8,
	  127,-97,-25,-8,0,63,-61,-61,-4,127,-1,-29,-4,63,-64,15,-32,0,0,23,-1,-2,3,-16,
	  63,15,-61,-16,0,31,-127,-127,-8,31,-1,-127,-8,31,-128,7,-128,0,0
       };

       local function get_pixel(x, y)
	  return bit.band(bit.rshift(logo_image[bit.rshift(x, 3) + y*logo_raw_length + 1], bit.band(bit.bnot(x), 0x07)), 1)
       end

       cc.Director:getInstance():getRunningScene():getPhysicsWorld():setGravity(cc.p(0, 0));
       cc.Director:getInstance():getRunningScene():getPhysicsWorld():setUpdateRate(5.0);
       
       layer.ball = cc.SpriteBatchNode:create("Images/ball.png", #logo_image);
       layer:addChild(layer.ball);
       for y in range(0, logo_height-1) do
	  for x in range(0, logo_width-1) do
	     if get_pixel(x, y) == 1 then
                local x_jitter = 0.05*math.random();
                local y_jitter = 0.05*math.random();
                
                local ball = makeBall(layer, cc.p(2*(x - logo_width/2 + x_jitter) + VisibleRect:getVisibleRect().width/2,
					       2*(logo_height-y + y_jitter) + VisibleRect:getVisibleRect().height/2 - logo_height/2),
                                      0.95, cc.PhysicsMaterial(0.01, 0.0, 0.0));
                
                ball:getPhysicsBody():setMass(1.0);
                ball:getPhysicsBody():setMoment(PHYSICS_INFINITY);

                layer.ball:addChild(ball);
	     end
	  end
       end

       local bullet = makeBall(layer, cc.p(400, 0), 10, cc.PhysicsMaterial(PHYSICS_INFINITY, 0, 0));
       bullet:getPhysicsBody():setVelocity(cc.p(200, 0));
       bullet:setPosition(cc.p(-500, VisibleRect:getVisibleRect().height/2))
       layer.ball:addChild(bullet);
    end

    initWithLayer(layer, onEnter)
    Helper.titleLabel:setString("Logo Smash")
    
    return layer
end

local function PhysicsDemoJoints()
   local layer = cc.Layer:create()
   local function onEnter()
    layer:toggleDebug();
    
    local touchListener = cc.EventListenerTouchOneByOne:create()
    touchListener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN) 
    touchListener:registerScriptHandler(onTouchMoved, cc.Handler.EVENT_TOUCH_MOVED) 
    touchListener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
    local eventDispatcher = layer:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(touchListener, layer)
    
    local width = (VisibleRect:getVisibleRect().width - 10) / 4;
    local height = (VisibleRect:getVisibleRect().height - 50) / 4;
    
    local node = cc.Node:create();
    local box = cc.PhysicsBody:create();
    node:setPhysicsBody(box);
    box:setDynamic(false);
    node:setPosition(cc.p(0, 0));
    layer:addChild(node);

    local scene = cc.Director:getInstance():getRunningScene();
    for i in range(0, 3) do
       for j in range(0, 3) do
            local offset = cc.p(VisibleRect:leftBottom().x + 5 + j * width + width/2, VisibleRect:leftBottom().y + 50 + i * height + height/2);
            box:addShape(cc.PhysicsShapeEdgeBox:create(cc.size(width, height), cc.PHYSICSSHAPE_MATERIAL_DEFAULT, 1, offset));
            print("i,j")
	    print(i)
	    print(j)
            local index = i*4 + j
            if index == 0 then
	            local sp1 = makeBall(layer, cc.p(offset.x - 30, offset.y), 10);
                    sp1:getPhysicsBody():setTag(DRAG_BODYS_TAG);
                    local sp2 = makeBall(layer, cc.p(offset.x + 30, offset.y), 10);
                    sp2:getPhysicsBody():setTag(DRAG_BODYS_TAG);
                    
                    local joint = cc.PhysicsJointPin:construct(sp1:getPhysicsBody(), sp2:getPhysicsBody(), offset);
                    cc.Director:getInstance():getRunningScene():getPhysicsWorld():addJoint(joint);
                    
                    layer:addChild(sp1);
                    layer:addChild(sp2);
            elseif  index == 1 then
                    local sp1 = makeBall(layer, cc.p(offset.x - 30, offset.y), 10);
                    sp1:getPhysicsBody():setTag(DRAG_BODYS_TAG);
                    local sp2 = makeBox(cc.p(offset.x + 30, offset.y), cc.size(30, 10));
                    sp2:getPhysicsBody():setTag(DRAG_BODYS_TAG);
                    
                    local joint = cc.PhysicsJointFixed:construct(sp1:getPhysicsBody(), sp2:getPhysicsBody(), offset);
                    scene:getPhysicsWorld():addJoint(joint);
                    
                    layer:addChild(sp1);
                    layer:addChild(sp2);
            elseif index == 2 then
                    local sp1 = makeBall(layer, cc.p(offset.x - 30, offset.y), 10);
                    sp1:getPhysicsBody():setTag(DRAG_BODYS_TAG);
                    local sp2 = makeBox(cc.p(offset.x + 30, offset.y), cc.size(30, 10));
                    sp2:getPhysicsBody():setTag(DRAG_BODYS_TAG);
                    
                     local joint = cc.PhysicsJointDistance:construct(sp1:getPhysicsBody(), sp2:getPhysicsBody(), cc.p(0, 0), cc.p(0, 0));
                    scene:getPhysicsWorld():addJoint(joint);
                    
                    layer:addChild(sp1);
                    layer:addChild(sp2);
             elseif index == 3 then
                    local sp1 = makeBall(layer, cc.p(offset.x - 30, offset.y), 10);
                    sp1:getPhysicsBody():setTag(DRAG_BODYS_TAG);
                    local sp2 = makeBox(cc.p(offset.x + 30, offset.y), cc.size(30, 10));
                    sp2:getPhysicsBody():setTag(DRAG_BODYS_TAG);
                    
                    local joint = cc.PhysicsJointLimit:construct(sp1:getPhysicsBody(), sp2:getPhysicsBody(), cc.p(0, 0), cc.p(0, 0), 30.0, 60.0);
                    scene:getPhysicsWorld():addJoint(joint);
                    
                    layer:addChild(sp1);
                    layer:addChild(sp2);
              elseif index == 4 then
                    local sp1 = makeBall(layer, cc.p(offset.x - 30, offset.y), 10);
                    sp1:getPhysicsBody():setTag(DRAG_BODYS_TAG);
                    local sp2 = makeBox(cc.p(offset.x + 30, offset.y), cc.size(30, 10));
                    sp2:getPhysicsBody():setTag(DRAG_BODYS_TAG);
                    
                    local joint = cc.PhysicsJointSpring:construct(sp1:getPhysicsBody(), sp2:getPhysicsBody(), cc.p(0, 0), cc.p(0, 0), 500.0, 0.3);
                    scene:getPhysicsWorld():addJoint(joint);
                    
                    layer:addChild(sp1);
                    layer:addChild(sp2);
              elseif index == 5 then
                    local sp1 = makeBall(layer, cc.p(offset.x - 30, offset.y), 10);
                    sp1:getPhysicsBody():setTag(DRAG_BODYS_TAG);
                    local sp2 = makeBox(cc.p(offset.x + 30, offset.y), cc.size(30, 10));
                    sp2:getPhysicsBody():setTag(DRAG_BODYS_TAG);
                    
                    local joint = cc.PhysicsJointGroove:construct(sp1:getPhysicsBody(), sp2:getPhysicsBody(), cc.p(30, 15), cc.p(30, -15), cc.p(-30, 0))
                    scene:getPhysicsWorld():addJoint(joint);
                    
                    layer:addChild(sp1);
                    layer:addChild(sp2);
               elseif index == 6 then
                    local sp1 = makeBox(cc.p(offset.x - 30, offset.y), cc.size(30, 10));
                    sp1:getPhysicsBody():setTag(DRAG_BODYS_TAG);
                    local sp2 = makeBox(cc.p(offset.x + 30, offset.y), cc.size(30, 10));
                    sp2:getPhysicsBody():setTag(DRAG_BODYS_TAG);
                    scene:getPhysicsWorld():addJoint(cc.PhysicsJointPin:construct(sp1:getPhysicsBody(), box, cc.p(sp1:getPosition())));
                    scene:getPhysicsWorld():addJoint(cc.PhysicsJointPin:construct(sp2:getPhysicsBody(), box, cc.p(sp2:getPosition())));
                    local joint = cc.PhysicsJointRotarySpring:construct(sp1:getPhysicsBody(), sp2:getPhysicsBody(), 3000.0, 60.0);
                    scene:getPhysicsWorld():addJoint(joint);
                    
                    layer:addChild(sp1);
                    layer:addChild(sp2);
               elseif index == 7 then
                    local sp1 = makeBox(cc.p(offset.x - 30, offset.y), cc.size(30, 10));
                    sp1:getPhysicsBody():setTag(DRAG_BODYS_TAG);
                    local sp2 = makeBox(cc.p(offset.x + 30, offset.y), cc.size(30, 10));
                    sp2:getPhysicsBody():setTag(DRAG_BODYS_TAG);
                    
                    scene:getPhysicsWorld():addJoint(cc.PhysicsJointPin:construct(sp1:getPhysicsBody(), box, cc.p(sp1:getPosition())));
                    scene:getPhysicsWorld():addJoint(cc.PhysicsJointPin:construct(sp2:getPhysicsBody(), box, cc.p(sp2:getPosition())));
                    local joint = cc.PhysicsJointRotaryLimit:construct(sp1:getPhysicsBody(), sp2:getPhysicsBody(), 0.0, math.pi/2);
                    scene:getPhysicsWorld():addJoint(joint);
                    
                    layer:addChild(sp1);
                    layer:addChild(sp2);
               elseif index == 8 then
                    local sp1 = makeBox(cc.p(offset.x - 30, offset.y), cc.size(30, 10));
                    sp1:getPhysicsBody():setTag(DRAG_BODYS_TAG);
                    local sp2 = makeBox(cc.p(offset.x + 30, offset.y), cc.size(30, 10));
                    sp2:getPhysicsBody():setTag(DRAG_BODYS_TAG);
                    
                    scene:getPhysicsWorld():addJoint(cc.PhysicsJointPin:construct(sp1:getPhysicsBody(), box, cc.p(sp1:getPosition())));
                    scene:getPhysicsWorld():addJoint(cc.PhysicsJointPin:construct(sp2:getPhysicsBody(), box, cc.p(sp2:getPosition())));
                    local joint = cc.PhysicsJointRatchet:construct(sp1:getPhysicsBody(), sp2:getPhysicsBody(), 0.0, math.pi/2);
                    scene:getPhysicsWorld():addJoint(joint);
                    
                    layer:addChild(sp1);
                    layer:addChild(sp2);
               elseif index == 9 then
                    local sp1 = makeBox(cc.p(offset.x - 30, offset.y), cc.size(30, 10));
                    sp1:getPhysicsBody():setTag(DRAG_BODYS_TAG);
                    local sp2 = makeBox(cc.p(offset.x + 30, offset.y), cc.size(30, 10));
                    sp2:getPhysicsBody():setTag(DRAG_BODYS_TAG);
                    
                    scene:getPhysicsWorld():addJoint(cc.PhysicsJointPin:construct(sp1:getPhysicsBody(), box, cc.p(sp1:getPosition())));
                    scene:getPhysicsWorld():addJoint(cc.PhysicsJointPin:construct(sp2:getPhysicsBody(), box, cc.p(sp2:getPosition())));
                    local joint = cc.PhysicsJointGear:construct(sp1:getPhysicsBody(), sp2:getPhysicsBody(), 0.0, 2.0);
                    scene:getPhysicsWorld():addJoint(joint);
                    
                    layer:addChild(sp1);
                    layer:addChild(sp2);
               elseif index == 10 then
                    local sp1 = makeBox(cc.p(offset.x - 30, offset.y), cc.size(30, 10));
                    sp1:getPhysicsBody():setTag(DRAG_BODYS_TAG);
                    local sp2 = makeBox(cc.p(offset.x + 30, offset.y), cc.size(30, 10));
                    sp2:getPhysicsBody():setTag(DRAG_BODYS_TAG);
                    
                    scene:getPhysicsWorld():addJoint(cc.PhysicsJointPin:construct(sp1:getPhysicsBody(), box, cc.p(sp1:getPosition())));
                    scene:getPhysicsWorld():addJoint(cc.PhysicsJointPin:construct(sp2:getPhysicsBody(), box, cc.p(sp2:getPosition())));
                    local joint = cc.PhysicsJointMotor:construct(sp1:getPhysicsBody(), sp2:getPhysicsBody(), math.pi/2);
                    scene:getPhysicsWorld():addJoint(joint);
                    
                    layer:addChild(sp1);
                    layer:addChild(sp2);
               end
          end
      end
  end

    initWithLayer(layer, onEnter)
    Helper.titleLabel:setString("Joints")
    return layer
end

local function PhysicsDemoPyramidStack()
    local layer = cc.Layer:create()

    local function onEnter()
       local touchListener = cc.EventListenerTouchOneByOne:create();
       touchListener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN);
       touchListener:registerScriptHandler(onTouchMoved, cc.Handler.EVENT_TOUCH_MOVED);
       touchListener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED);
       local eventDispatcher = layer:getEventDispatcher()
       eventDispatcher:addEventListenerWithSceneGraphPriority(touchListener, layer);
       
       local node = cc.Node:create();
       node:setPhysicsBody(cc.PhysicsBody:createEdgeSegment(cc.p(VisibleRect:leftBottom().x, VisibleRect:leftBottom().y + 50), cc.p(VisibleRect:rightBottom().x, VisibleRect:rightBottom().y + 50)));
       layer:addChild(node);
       
       local ball = cc.Sprite:create("Images/ball.png");
       ball:setScale(1);
       ball:setPhysicsBody(cc.PhysicsBody:createCircle(10));
       ball:getPhysicsBody():setTag(DRAG_BODYS_TAG);
       ball:setPosition(cc.p(VisibleRect:bottom().x, VisibleRect:bottom().y + 60));
       layer:addChild(ball);

       for i in range(0, 13) do
	  for j in range(0, i) do
	     local x = VisibleRect:bottom().x + (i/2 - j) * 11
	     local y = VisibleRect:bottom().y + (14 - i) * 23 + 100
	     local sp = addGrossiniAtPosition(layer, cc.p(x, y), 0.2);
	     sp:getPhysicsBody():setTag(DRAG_BODYS_TAG);
	  end
       end
    end

    initWithLayer(layer, onEnter)
    Helper.titleLabel:setString("Pyramid Stack")

    return layer
end

local function PhysicsDemoRayCast()
    local layer = cc.Layer:create()

    local function onEnter()
       local function onTouchEnded(touch, event)
	  local location = touch:getLocation();
	  
	  local r = math.random(3);
	  if r ==1 then
	     layer:addChild(makeBall(layer, location, 5 + math.random()*10));
	  elseif r == 2 then
	     layer:addChild(makeBox(location, cc.size(10 + math.random()*15, 10 + math.random()*15)));
	  elseif r == 3 then
	     layer:addChild(makeTriangle(location, cc.size(10 + math.random()*20, 10 + math.random()*20)));
	  end
       end
       
       local touchListener = cc.EventListenerTouchOneByOne:create();
       touchListener:registerScriptHandler(function() return true end, cc.Handler.EVENT_TOUCH_BEGAN);
       touchListener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED);
       local eventDispatcher = layer:getEventDispatcher()
       eventDispatcher:addEventListenerWithSceneGraphPriority(touchListener, layer);
       
       cc.Director:getInstance():getRunningScene():getPhysicsWorld():setGravity(cc.p(0,0));
       
       local node = cc.DrawNode:create();
       node:setPhysicsBody(cc.PhysicsBody:createEdgeSegment(cc.p(VisibleRect:leftBottom().x, VisibleRect:leftBottom().y + 50), cc.p(VisibleRect:rightBottom().x, VisibleRect:rightBottom().y + 50)))
       node:drawSegment(cc.p(VisibleRect:leftBottom().x, VisibleRect:leftBottom().y + 50), cc.p(VisibleRect:rightBottom().x, VisibleRect:rightBottom().y + 50), 1, STATIC_COLOR);
       layer:addChild(node);

       local mode = 0
       cc.MenuItemFont:setFontSize(18);
       local item = cc.MenuItemFont:create("Toogle debugChange Mode(any)")
       local function changeModeCallback(sender)
	  mode = (mode + 1) % 3;
	  
	  if mode == 0 then
	     item:setString("Change Mode(any)");
	  elseif mode == 1 then
	     item:setString("Change Mode(nearest)");
	  elseif mode == 2 then
	     item:setString("Change Mode(multiple)");
	  end
       end
       
       item:registerScriptTapHandler(changeModeCallback)
       
       local menu = cc.Menu:create(item);
       layer:addChild(menu);
       menu:setPosition(cc.p(VisibleRect:left().x+100, VisibleRect:top().y-10));

       local angle = 0
       local drawNode = nil
       local function update(delta)
	  local L = 150.0;
	  local point1 = VisibleRect:center()
	  local d = cc.p(L * math.cos(angle), L * math.sin(angle));
	  local point2 = cc.p(point1.x + d.x, point1.y + d.y)
    
          if drawNode then layer:removeChild(drawNode); end
          drawNode = cc.DrawNode:create();
          if mode == 0 then
	     local point3 = cc.p(point2.x, point2.y)
	     local function func(world, info)
		point3 = info.contact
		return false
	     end

            cc.Director:getInstance():getRunningScene():getPhysicsWorld():rayCast(func, point1, point2);
            drawNode:drawSegment(point1, point3, 1, STATIC_COLOR);
            
            if point2.x ~= point3.x or point2.y ~= point3.y then
	       drawNode:drawDot(point3, 2, cc.c4f(1.0, 1.0, 1.0, 1.0));
            end
            layer:addChild(drawNode);
	  elseif mode == 1 then
	    local point3 = cc.p(point2.x, point2.y)
            local friction = 1.0;
            local function func(world, info)
                if friction > info.fraction then
                    point3 = info.contact;
                    friction = info.fraction;
		end
                return true;
            end
            
            cc.Director:getInstance():getRunningScene():getPhysicsWorld():rayCast(func, point1, point2);
            drawNode:drawSegment(point1, point3, 1, STATIC_COLOR);
            
            if point2.x ~= point3.x or point2.y ~= point3.y then
                drawNode:drawDot(point3, 2, cc.c4f(1.0, 1.0, 1.0, 1.0));
            end
            layer:addChild(drawNode);
          elseif mode == 2 then
	    local points = {}
            
            local function func(world, info)
                points[#points + 1] = info.contact;
                return true;
            end
            
            cc.Director:getInstance():getRunningScene():getPhysicsWorld():rayCast(func, point1, point2);
            drawNode:drawSegment(point1, point2, 1, STATIC_COLOR);
            
            for _, p in ipairs(points) do
                drawNode:drawDot(p, 2, cc.c4f(1.0, 1.0, 1.0, 1.0));
            end
            
            layer:addChild(drawNode);
          end
    
       angle = angle + 0.25 * math.pi / 180.0;

       end

       layer:scheduleUpdateWithPriorityLua(update, 0);
    end

    initWithLayer(layer, onEnter)
    Helper.titleLabel:setString("Ray Cast")

    return layer
end

local function registerOnEnter()
   layer:registerOn(PhysicsDemoLogoSmash)
end

function PhysicsTest()
   cclog("PhysicsTest")
   local scene = cc.Scene:createWithPhysics()

   Helper.usePhysics = true
   Helper.createFunctionTable = {
      PhysicsDemoLogoSmash,
      PhysicsDemoPyramidStack,
      PhysicsDemoClickAdd,
      PhysicsDemoRayCast,
      PhysicsDemoJoints,
   }

   scene:addChild(Helper.createFunctionTable[1]())
   scene:addChild(CreateBackMenuItem())
   return scene
end
