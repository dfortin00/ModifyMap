--[[
    collision.lua v0.1

    Copyright (c) 2020 Dennis Fortin

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction,
    including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all copies or substantial
        portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    example:
        Collision = require 'collision'
        local collides = Collision.pointPoint(100, 200, 150, 300)
]]

local collision = {}

local function distance(x1, y1, x2, y2)
    local distX = x2 - x1
    local distY = y2 - y1
    return math.sqrt((distX * distX) + (distY * distY))
end

--[[ Collision detection between two points. ]]
collision.pointPoint = function(x1, y1, x2, y2)
    if (x1 == x2) and (y1 == y2) then
        return true
    end

    return false
end

--[[ Collision detection between a point and a circle. ]]
collision.pointCircle = function(px, py, cx, cy, r)
    -- Get the distance between the point (px, py) and the circle's center (cx, cy).
    local dist = distance(px, py, cx, cy)

    -- Check if the distance of the point is less than the circle's radius.
    if dist <= r then
        return true
    end

    return false
end

--[[ Collision detection between a point and a rectangle.
     Note: Rectangle must be axis-aligned with screen coordinates. ]]
collision.pointRect = function(px, py, rx, ry, rw, rh)
    local rEdge = rx + rw -- Right edge
    local bEdge = ry + rh -- Bottom edge

    -- Check if the point is inside the rectangle bounds.
    if px >= rx and px <= rEdge and py >= ry and py <= bEdge then
        return true
    end

    return false
end

-- [[ Collision detection between two circles. ]]
collision.circleCircle = function(c1x, c1y, c1r, c2x, c2y, c2r)
    -- Get the distance between the two circles' centres.
    local dist = distance(c1x, c1y, c2x, c2y)

    -- Check if the distance is less than the sum of the two circles' radii.
    if dist <= (c1r + c2r) then
        return true
    end

    return false
end

--[[ Collision between a circle and a rectangle.
     Note: Rectangle must be axis-aligned with screen coordinates. ]]
collision.circleRect = function(cx, cy, radius, rx, ry, rw, rh)
    -- Temporary variables for edge testing.
    local testX = cx
    local testY = cy

    -- Check which edge is the circle is closest too.
    if cx < rx then            testX = rx           -- Left edge
    elseif cx > (rx + rw) then testX = rx + rw end  -- Right edge

    if cy < ry then            testY = ry           -- Top edge
    elseif cy > (ry + rh) then testY = ry + rh end  -- Bottom edge

    -- Get the distance from the closest edges.
    local dist = distance(cx, cy, testX, testY)

    -- Check if the distance is less than the radius of the circle.
    if dist <= radius then
        return true
    end

    return false, testX, testY, dist
end

--[[ Collision detection between two rectangles.
     Note: Both rectangles must be axis-aligned to screen coordinates. ]]
collision.rectRect = function(r1x, r1y, r1w, r1h, r2x, r2y, r2w, r2h)
    -- Check if any of the sides are touching each other.
    if (r1x + r1w) >= r2x and r1x <= (r2x + r2w) and (r1y + r1h) >= r2y and r1y <= (r2y + r2h) then
        return true
    end

    return false
end

--[[ Collision detection between a point and a line. ]]
collision.linePoint = function(x1, y1, x2, y2, px, py)
    -- Get the distance from the point to the two end points of the line.
    local d1 = distance(px, py, x1, y1)
    local d2 = distance(px, py, x2, y2)

    -- Get the length of the line.
    local lineLen = distance(x1, y1, x2, y2)

    -- Since floating point numbers are minutely accurate, add a buffer zone in the collision test.
    local buffer = 0.1

    -- Check if the distances of the point to each endpoint for the line equals the line's length.
    if (d1 + d2) >= (lineLen - buffer) and (d1 + d2) <= (lineLen + buffer) then
        return true
    end

    return false
end

--[[ Collision detection between a line and a circle. ]]
collision.lineCircle = function(x1, y1, x2, y2, cx, cy, r)
    -- Check if either endpoint of the line is inside the circle.
    local inside1 = collision.pointCircle(x1, y1, cx, cy, r)
    local inside2 = collision.pointCircle(x2, y2, cx, cy, r)
    if inside1 or inside2 then return true end

    -- Get the length of the line.
    local len = distance(x1, y1, x2, y2)

    -- There are two vectors: 1) The line segment, and 2) the vector from endpoint (x1, y1) to the center of the circle.
    -- Get the dot product between the two vectors, and then project vector 2 onto vector 1.
    local dot = ((cx - x1) * (x2 - x1)) + ((cy - y1) * (y2 - y1))
    local proj = dot / (len * len)

    -- Using the projection value, we can determine the (x, y) of the point on the line closest to the center of the circle.
    local closestX = x1 + (proj * (x2 - x1))
    local closestY = y1 + (proj * (y2 - y1))

    -- Check if the closest point is on the line inside the line segment endpoints.
    local onSegment = collision.linePoint(x1, y1, x2, y2, closestX, closestY)
    if not onSegment then return false end

    -- Get the distance to the closest point from the center of the circle.
    local dist = distance(closestX, closestY, cx, cy)

    -- Check if the distance is less than the radius of the circle.
    if dist <= r then
        return true
    end

    return false
end

--[[ Collision detection for the intersection between two lines.
     Note: This function will also return the (x, y) of the intersection, but only if the collision
           isn't coincidental. ]]
collision.lineLine = function(x1, y1, x2, y2, x3, y3, x4, y4)
    -- Calculate the distance to the intersection point.
    local numeratorA = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3))
    local numeratorB = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3))
    local denominator = ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1))

    -- Check if the lines are coincidental.
    if numeratorA == 0 and numeratorB == 0 and denominator == 0 then
        local minXA = math.min(x1, x2)
        local minXB = math.min(x3, x4)
        local maxXA = math.max(x1, x2)
        local maxXB = math.max(x3, x4)

        local minYA = math.min(y1, y2)
        local minYB = math.min(y3, y4)
        local maxYA = math.max(y1, y2)
        local maxYB = math.max(y3, y4)

        -- Check if the line segments are overlapping.
        if ((maxXB > minXA or maxXA < minXB) and (maxXA > minXB or maxXB < minXA)) or
            ((maxYB > minYA or maxYA < minYB) and (maxYA > minYB or maxYB < minYA)) then
            return true
        end

        return false
    end

    local uA = numeratorA / denominator
    local uB = numeratorB / denominator

    -- Check if uA and uB are between 0 and 1.
    if (uA >= 0 and uA <=1 and uB >= 0 and uB <= 1) then
        intersectionX = x1 + (uA * (x2 - x1))
        intersectionY = y1 + (uA * (y2 - y1))

        return true, intersectionX, intersectionY
    end

    return false
end

--[[ Collision detection between a line and a rectangle.
     Note: This will work for rectangles with any rotation. ]]
collision.lineRect = function(x1, y1, x2, y2, rx, ry, rw, rh)
    -- Check if the line has collided with any of the sides on the rectangle.
    local left = collision.lineLine  (x1, y1, x2, y2, rx, ry, rx, ry+rh)
    local right = collision.lineLine (x1, y1, x2, y2, rx+rw, ry, rx+rw, ry+rh)
    local top = collision.lineLine   (x1, y1, x2, y2, rx, ry, rx+rw, ry)
    local bottom = collision.lineLine(x1, y1, x2, y2, rx, ry+rh, rx+rw, ry+rh)

    if left or right or top or bottom then
        return true
    end

    -- Check if the line is entirely inside the rectangle.
    local p1Inside = collision.pointRect(x1, y1, rx, ry, rw, rh)
    local p2Inside = collision.pointRect(x2, y2, rx, ry, rw, rh)

    if p1Inside and p2Inside then
        return true
    end

    return false
end

--[[ Note: For all proceeding polygon collision functions below, the 'vertices' parameter must be an
           array with each element containing a table of x, y coordinates.

     Example:
        table: 0x39df94c0 {
            [1] => table: 0x39df94c0 {
                    [y] => 100
                    [x] => 200
                    }
            [2] => table: 0x39df94c0 {
                    [y] => 130
                    [x] => 400
                    }
            [3] => table: 0x39df94c0 {
                    [y] => 300
                    [x] => 350
                    }
            [4] => table: 0x39df94c0 {
                    [y] => 300
                    [x] => 250
                    }
        }
]]

--[[ Collision detection between a polygon and a point. ]]
collision.polyPoint = function(vertices, px, py)
    local collides = false
    local next = 0

    for current = 1, #vertices do
        next = current + 1
        if next > #vertices then next = 1 end

        -- Get the vertices at the current position.
        local vc = vertices[current]
        local vn = vertices[next]

        -- Compare the position of the point to the vertices.
        if ((vc.y >= py and vn.y < py) or (vc.y < py and vn.y >= py)) and
            (px < (vn.x - vc.x) * (py - vc.y) / (vn.y - vc.y) + vc.x) then
                collides = not collides
        end
    end

    return collides
end

--[[ Collision detection between a polygon and a circle.
     Note: Returns a boolean if there is a collision between the circle and an edge of the polygon,
           along with a second boolean if the circle is entirely inside the polygon.
     Note: The 'inside' parameter is a flag that determines whether the test will be done to check if
           the  center of the circle is inside the polygon. Note this can cause performance issues
           with polgons that have large numbers of vertices, so it's best to leave this flag as 'false'
           or 'nil' unless you really need it. ]]
collision.polyCircle = function(vertices, cx, cy, r, inside)
    local next = 0

    for current = 1, #vertices do
        next = current + 1
        if next > #vertices then next = 1 end

        local vc = vertices[current]
        local vn = vertices[next]

        -- Check the collisions between the circle and the line formed by the two vertices.
        local collides = collision.lineCircle(vc.x, vc.y, vn.x, vn.y, cx, cy, r)
        if collides then return true, false end
    end

    -- The above algorithm only checks if the circle is touching the edges of the polygon.
    -- The following tests if the entire circle is inside the polygon, but isn't touching any of the sides.
    if inside then
        local centerInside = collision.polyPoint(vertices, cx, cy)
        if centerInside then return true, true end
    end

    return false, false
end

--[[ Collision detection between a polygon and a rectangle.
     Note: Returns a boolean if there is a collision between the rectangle and an edge of the polygon,
           along with a second boolean if the rectangle is entirely inside the polygon.
     Note: The 'inside' parameter is a flag that determines whether the test will be done to check if
           the rectangle is inside the polygon. Note this can cause performance issues
           with polgons that have large numbers of vertices, so it's best to leave this flag as 'false'
           or 'nil' unless you really need it. ]]
collision.polyRect = function(vertices, rx, ry, rw, rh, inside)
    local next = 0

    for current = 1, #vertices do
        next = current + 1
        if next > #vertices then next = 1 end

        local vc = vertices[current]
        local vn = vertices[next]

        -- Check the collisions between the circle and the line formed by the two vertices.
        local collides = collision.lineRect(vc.x, vc.y, vn.x, vn.y, rx, ry, rw, rh)
        if collides then return true, false end
    end

    -- The above algorithm only checks if the circle is touching the edges of the polygon.
    -- The following tests if the entire circle is inside the polygon, but isn't touching any of the sides.
    if inside then
        local centerInside = collision.polyPoint(vertices, rx, ry)
        if centerInside then return true, true end
    end

    return false, false
end

--[[ Collision detection between a polygon and a line.
     Note: The 'inside' parameter is a flag that determines whether the test will be done to check if
           the first polygon is inside the second polygon. Note this can cause performance issues
           with polgons that have large numbers of vertices, so it's best to leave this flag as 'false'
           or 'nil' unless you really need it. ]]
collision.polyLine = function(vertices, x1, y1, x2, y2, inside)
    if inside then
        -- Check if either endpoint is inside the polygon.
        local inside1 = collision.polyPoint(vertices, x1, y1)
        local inside2 = collision.polyPoint(vertices, x2, y2)
        if inside1 or inside2 then return true end
    end

    -- Otherwise, cycle through all the edges and look for any intersections.
    local next = 0
    for current = 1, #vertices do
        next = current + 1
        if next > #vertices then next = 1 end

        local x3 = vertices[current].x
        local y3 = vertices[current].y
        local x4 = vertices[next].x
        local y4 = vertices[next].y

        local hit = collision.lineLine(x1, y1, x2, y2, x3, y3, x4, y4)
        if hit then return true end
    end

    return false
end

--[[ Collision detection between a polygon and another polygon.
     Note: The 'inside' parameter is a flag that determines whether the test will be done to check if
           the first polygon is inside the second polygon. Note this can cause performance issues
           with polgons that have large numbers of vertices, so it's best to leave this flag as 'false'
           or 'nil' unless you really need it. ]]
collision.polyPoly = function(vertices1, vertices2, inside)
    local next = 0

    for current = 1, #vertices1 do
        next = current + 1
        if next > #vertices1 then next = 1 end

        local vc = vertices1[current]
        local vn = vertices1[next]

        -- Check if the line from the two points intersect with the
        -- any of the edges on the second polygon.
        local collides = collision.polyLine(vertices2, vc.x, vc.y, vn.x, vn.y)
        if collides then return true end

        if inside then
            collides = collision.polyPoint(vertices1, vertices2[1].x, vertices2[1].y)
            if collides then return true end
        end
    end

    return false
end

--[[ Collision detection between a triangle and a point.
     Note: This is a much faster version for triangle polygons than using the polyPoint() function. ]]
collision.triPoint = function(x1, y1, x2, y2, x3, y3, px, py)
    -- Get the area of the triangle using the determinant.
    local origArea = math.abs((x2 - x1) * (y3 - y1) - (x3 - x1) * (y2 - y1))

    -- Get the area of the three triangles formed between the point and the corners of the triangle.
    local area1 = math.abs((x1 - px) * (y2 - py) - (x2 - px) * (y1 - py))
    local area2 = math.abs((x2 - px) * (y3 - py) - (x3 - px) * (y2 - py))
    local area3 = math.abs((x3 - px) * (y1 - py) - (x1 - px) * (y3 - py))

    -- Check if the sum of the three areas equals the area of the original triangle.
    if (area1 + area2 + area3) == origArea then
        return true
    end

    return false
end

return collision