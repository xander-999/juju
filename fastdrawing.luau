--!strict
--!nolint LocalShadow

--[[
    file: fastdrawing.luau
    author: techhog

    adapted from https://github.com/liam0999/Drawing2

    notes:
    values like Transparency are NOT clamped

    Transparency of 1 means visible; 0 means invisible
    Visible is default to false

    every line with a comment of PROD1 should be commented out for production
]]

-- TODO: getcustomasset cache

-- local crypt = crypt -- PROD1
-- if not crypt then -- PROD1
--     crypt = {base64 = {decode = function(a)return a end}} -- PROD1
-- end -- PROD1
local base64decode = crypt.base64.decode

local function remove<T>(t: { T }, offset: number, count: number)
    for i = offset, count - 1 do
        t[i] = t[i + 1]
    end
    t[count] = nil
end
local function removeValue<T>(t: { T }, value: T, count: number)
    for i = 1, count do
        if t[i] == value then
            return remove(t, i, count)
        end
    end
end

local COLOR_WHITE = Color3.new(1, 1, 1)
local COLOR_BLACK = Color3.new(0, 0, 0)
local VECTOR2_ZERO = Vector2.new(0, 0)
local FONT_DEFAULT_INTERNAL = Font.fromName("RobotoMono")
local FONT_DEFAULT = 0
local LINE_JOIN_MODE_MITER = Enum.LineJoinMode.Miter
local LINE_JOIN_MODE_ROUND = Enum.LineJoinMode.Round
local TEXT_X_ALIGNMENT_LEFT = Enum.TextXAlignment.Left
local TEXT_X_ALIGNMENT_CENTER = Enum.TextXAlignment.Center
local TEXT_Y_ALIGNMENT_TOP = Enum.TextYAlignment.Top

--[=[
local function hashTextBoundsInfo(params: GetTextBoundsParams): string
    local font = params.Font
    local size = params.Size
    local text = params.Text
    local width = params.Width

    local font_string = tostring(font)
    local blob = buffer.create(#font_string + 16 + #text + 32)
    buffer.writestring(blob, 0, font_string)
    buffer.writei16(blob, #font_string, size);
    buffer.writestring(blob, #font_string + 16, text)
    buffer.writei32(blob, #font_string + 16 + #text, width)
    return buffer.tostring(blob)
end
local text_bounds_map: { [string]: Vector2 } = {}

local TextService = game:GetService("TextService")
local function getTextBounds(font: Font, size: number, text: string, width: number): Vector2
    local params = Instance.new("GetTextBoundsParams")
    params.Font = font
    params.Size = size
    params.Text = text
    params.Width = width
    local hashed = hashTextBoundsInfo(params)

    local result = text_bounds_map[hashed]
    if not result then
        result = TextService:GetTextBoundsAsync(params)
        text_bounds_map[hashed] = result
    end
    return result
end
]=]

-- if not writefile then -- PROD1
--     writefile = function(...)end -- PROD1
--     getcustomasset = function(...) -- PROD1
--         -- return "http://www.roblox.com/asset/?id=15775401404" -- PROD1
--         return "rbxassetid://12187376545" -- PROD1
--     end -- PROD1
--     delfile = function(...)end -- PROD1
-- end -- PROD1

local data_asset_map: { [string]: string } = {}
local function getAsset(data: string, append: (".txt" | ".ttf")?): string
    local result = data_asset_map[data]
    if not result then
        local file = "asset" .. tick() .. (append or ".txt")
        writefile(file, data)
        result = getcustomasset(file)
        delfile(file)
        data_asset_map[data] = result
    end
    return result
end
local function getFontAsset(data: string): string
    local asset = getAsset(base64decode(data), ".ttf")
    return getAsset("{\"name\": \"\", \"faces\": [{\"name\": \"Regular\", \"weight\": 100, \"style\": \"normal\", \"assetId\": \"" .. asset .. "\"}]}")
end

type generic_map = { [string]: any }

type valid_class_name = "Line" | "Text" | "Image" | "Circle" |
    "Square" | "Triangle" | "Quad"

type DrawingFontAPI = {
    new: ( DrawingFontAPI, string ) -> number,

    _font_list: { Font },
    _font_cache: { [string]: number }
}

type DrawingAPI_generic_function = ( DrawingAPI ) -> ()
export type DrawingAPI = {
    root: ScreenGui?,
    setRoot: ( DrawingAPI, ScreenGui ) -> (),

    _addToDrawingList: ( DrawingAPI, Drawing, GuiObject, generic_map, generic_map, generic_map ) -> Drawing,

    _newLine: ( DrawingAPI ) -> DrawingLine,
    _newText: ( DrawingAPI ) -> DrawingText,
    _newImage: ( DrawingAPI ) -> DrawingImage,
    _newCircle: ( DrawingAPI ) -> DrawingCircle,
    _newSquare: ( DrawingAPI ) -> DrawingSquare,
    _newTriangle: ( DrawingAPI ) -> DrawingTriangle,
    _newQuad: ( DrawingAPI ) -> DrawingQuad,
    new: ( DrawingAPI, valid_class_name ) -> Drawing,

    Font: DrawingFontAPI,

    _drawing_list: { DrawingProxyGeneric },
    _drawing_list_count: number,

    clearDrawCache: DrawingAPI_generic_function,
    cleardrawcache: DrawingAPI_generic_function
}

local Drawing: DrawingAPI

type Drawing_destroy = ( DrawingProxyGeneric ) -> ()
type DrawingBase = {
    _alive: boolean,

    Visible: boolean,
    ZIndex: number,
    Transparency: number,
    Color: Color3,

    Destroy: Drawing_destroy
}
type base_property = "Visible" | "ZIndex"
type less_generic_base_property = "Transparency" | "Color"

export type DrawingLine = DrawingBase & {
    Thickness: number,
    From: Vector2,
    To: Vector2
}
type line_property = less_generic_base_property | "Thickness" | "From" | "To"
export type DrawingText = DrawingBase & {
    Text: string,
    TextBounds: Vector2,
    Size: number,
    Font: number,
    Centered: boolean,
    Outline: boolean,
    OutlineColor: Color3,
    Position: Vector2
}
type text_property = less_generic_base_property | "Text" | "TextBounds" | "Size" | "Font" | "Centered" |
    "Outline" | "OutlineColor" | "Position"
export type DrawingImage = DrawingBase & {
    Data: string,
    -- ImageSize: Vector2,
    Size: Vector2,
    Position: Vector2,
    Rounding: number
}
type image_property = less_generic_base_property | "Data" | --[[ "ImageSize" | ]] "Size" | "Position" | "Rounding"
export type DrawingCircle = DrawingBase & {
    Thickness: number,
    NumSides: number,
    Radius: number,
    Filled: boolean,
    Position: Vector2
}
type circle_property = less_generic_base_property | "Thickness" | "NumSides" | "Radius" | "Filled"| "Position"
export type DrawingSquare = DrawingBase & {
    Thickness: number,
    Size: Vector2,
    Position: Vector2,
    Filled: boolean
}
type square_property = less_generic_base_property | "Thickness" | "Size" | "Position" | "Filled"
export type DrawingTriangle = DrawingBase & {
    Thickness: number,
    PointA: Vector2,
    PointB: Vector2,
    PointC: Vector2,
    Filled: boolean
}
type triangle_property = less_generic_base_property | "Thickness" | "PointA" | "PointB" | "PointC" | "Filled"
export type DrawingQuad = DrawingBase & {
    Thickness: number,
    PointA: Vector2,
    PointB: Vector2,
    PointC: Vector2,
    PointD: Vector2,
    Filled: boolean
}
type quad_property = less_generic_base_property | "Thickness" | "PointA" | "PointB" | "PointC" | "PointD" |
    "Filled"

type DrawingProxyGeneric = { drawing: Drawing, instance: GuiObject }

type DrawingLineProxy = { drawing: DrawingLine, instance: Frame }
type DrawingTextProxy = {
    drawing: DrawingText,
    instance: TextLabel,
    stroke: UIStroke,
    text_bounds: Vector2
}
type DrawingImageProxy = {
    drawing: DrawingImage,
    instance: ImageLabel,
    ui_corner: UICorner,
    image_size: Vector2,
}
type DrawingCircleProxy = {
    drawing: DrawingCircle,
    instance: Frame,
    -- frame2: Frame,
    stroke: UIStroke,
    -- size: Vector2
}
type DrawingSquareProxy = {
    drawing: DrawingSquare,
    instance: Frame,
    frame2: Frame,
    stroke: UIStroke
}
type DrawingTriangleProxy = {
    drawing: DrawingTriangle,
    instance: Frame,
    pointa: Frame,
    pointb: Frame,
    pointc: Frame
}
type DrawingQuadProxy = {
    drawing: DrawingQuad,
    instance: Frame,
    pointa: Frame,
    pointb: Frame,
    pointc: Frame,
    pointd: Frame
}

export type Drawing = DrawingLine | DrawingText | DrawingImage |
    DrawingCircle | DrawingSquare | DrawingTriangle | DrawingQuad

local _destroy: Drawing_destroy

local function throwInvalidProperty(class_name: valid_class_name, property: string)
    -- error('\'' .. tostring(property) .. "' is not a valid property of " .. class_name, 2) -- PROD1
end

local function trySetBaseProperty(drawing: Drawing, instance: GuiObject, key: base_property, value: any): boolean
    if key == "Visible" then
        instance.Visible = value
    elseif key == "ZIndex" then
        instance.ZIndex = value
    else
        return true
    end

    (drawing::DrawingBase)[key] = value

    return false
end

local function updatePosition(instance: Frame, from: Vector2, to: Vector2, thickness: number)
    local center = (from + to) / 2
    local offset = to - from

    instance.Position = UDim2.fromOffset(center.X, center.Y)
    instance.Size = UDim2.fromOffset(offset.Magnitude, thickness)
    instance.Rotation = math.atan2(offset.Y, offset.X) * 180 / math.pi
end

local line_metatable = {
    __index = function(self: DrawingLine, key: string)
        throwInvalidProperty("Line", key)
    end
}
local line_proxy_metatable = {
    __index = function(self: DrawingLineProxy, key: line_property)
        return self.drawing[key]
    end,
    __newindex = function(self: DrawingLineProxy, key: line_property, value: any)
        local drawing = self.drawing
        local instance = self.instance

        if trySetBaseProperty(drawing, instance, key :: any, value) then
            if key == "Transparency" then
                drawing[key] = value
                instance.BackgroundTransparency = 1 - value
            elseif key == "Color" then
                drawing[key] = value
                instance.BackgroundColor3 = value
            elseif key == "Thickness" then
                drawing[key] = value
                updatePosition(instance, drawing.From, drawing.To, value)
            elseif key == "From" then
                drawing[key] = value
                updatePosition(instance, value, drawing.To, drawing.Thickness)
            elseif key == "To" then
                drawing[key] = value
                updatePosition(instance, drawing.From, value, drawing.Thickness)
            else
                throwInvalidProperty("Line", key)
            end
        end
    end
}
local text_metatable = {
    __index = function(self: DrawingText, key: string)
        throwInvalidProperty("Text", key)
    end
}
local text_proxy_metatable = {
    __index = function(self: DrawingTextProxy, key: text_property)
        if key == "TextBounds" then
            -- return self.text_bounds
            return self.instance.TextBounds
        end
        return self.drawing[key]
    end,
    __newindex = function(self: DrawingTextProxy, key: text_property, value: any)
        local drawing = self.drawing
        local instance = self.instance
        local stroke = self.stroke

        if trySetBaseProperty(drawing, instance, key :: any, value) then
            if key == "Transparency" then
                drawing[key] = value
                local transparency: number = 1 - value
                instance.TextTransparency = transparency
                stroke.Transparency = transparency
            elseif key == "Color" then
                drawing[key] = value
                instance.TextColor3 = value

            elseif key == "Text" then
                drawing[key] = value
                instance.Text = value
                -- task.defer(function() self.text_bounds = getTextBounds(drawing.Font, drawing.Size, value, 9e9) end)
            -- elseif key == "TextBounds" then -- PROD1
            --     error("TextBounds is read-only") -- PROD1
            elseif key == "Size" then
                drawing[key] = value
                instance.TextSize = value
                -- task.defer(function() self.text_bounds = getTextBounds(drawing.Font, value, drawing.Text, 9e9) end)
            elseif key == "Font" then
                drawing[key] = value
                instance.FontFace = Drawing.Font._font_list[value]
                -- task.defer(function() self.text_bounds = getTextBounds(value, drawing.Size, drawing.Text, 9e9) end)
            elseif key == "Centered" then
                drawing[key] = value
                instance.TextXAlignment =
                    if value then
                        TEXT_X_ALIGNMENT_CENTER
                    else
                        TEXT_X_ALIGNMENT_LEFT
            elseif key == "Outline" then
                drawing[key] = value
                stroke.Enabled = value
            elseif key == "OutlineColor" then
                drawing[key] = value
                stroke.Color = value
            elseif key == "Position" then
                drawing[key] = value
                instance.Position = UDim2.fromOffset(value.X, value.Y)
            else
                throwInvalidProperty("Text", key)
            end
        end
    end
}
local image_metatable = {
    __index = function(self: DrawingImage, key: string)
        throwInvalidProperty("Image", key)
    end
}
local image_proxy_metatable = {
    __index = function(self: DrawingImageProxy, key: image_property)
        -- if key == "ImageSize" then
        --     return self.image_size
        -- end
        return self.drawing[key]
    end,
    __newindex = function(self: DrawingImageProxy, key: image_property, value: any)
        local drawing = self.drawing
        local instance = self.instance
        local ui_corner = self.ui_corner

        if trySetBaseProperty(drawing, instance, key :: any, value) then
            if key == "Transparency" then
                drawing[key] = value
                instance.ImageTransparency = 1 - value
            elseif key == "Color" then
                drawing[key] = value
                instance.ImageColor3 = value

            elseif key == "Data" then
                drawing[key] = value
                instance.Image = getAsset(value)
            -- elseif key == "ImageSize" then -- PROD1
            --     error("ImageSize is read-only") -- PROD1
            elseif key == "Size" then
                drawing[key] = value
                instance.Size = UDim2.fromOffset(value.X, value.Y)
            elseif key == "Position" then
                drawing[key] = value
                instance.Position = UDim2.fromOffset(value.X, value.Y)
            elseif key == "Rounding" then
                drawing[key] = value
                ui_corner.CornerRadius = UDim.new(0, value)
            else
                throwInvalidProperty("Image", key)
            end
        end
    end
}

local function updateTransparencyWithStroke(filled: boolean, value: number, instance: Frame, stroke: UIStroke)
    local transparency: number = 1 - value
    if filled then
        instance.BackgroundTransparency = transparency
    end
    stroke.Transparency = transparency
end
local function updateFilledWithStroke(self: any, instance: Frame, value: number)
    if value then
        self.Transparency = self.Transparency
    else
        instance.BackgroundTransparency = 1
    end
end

local function updateFrame2Size(drawing: any, frame2: Frame, parent_size: Vector2)
    frame2.Size = UDim2.fromOffset(
        parent_size.X - drawing.Thickness,
        parent_size.Y - drawing.Thickness
    )
end
local function updateFrame2Position(frame2: Frame)
    local frame2_size = frame2.Size
    frame2.Position = UDim2.new(
        0.5,
        -frame2_size.X.Offset / 2,
        0.5,
        -frame2_size.Y.Offset / 2
    )
end
local circle_metatable = {
    __index = function(self: DrawingCircle, key: string)
        throwInvalidProperty("Circle", key)
    end
}
local circle_proxy_metatable = {
    __index = function(self: DrawingCircleProxy, key: circle_property)
        return self.drawing[key]
    end,
    __newindex = function(self: DrawingCircleProxy, key: circle_property, value: any)
        local drawing = self.drawing
        local instance = self.instance
        -- local frame2 = self.frame2
        local stroke = self.stroke
        -- local size = self.size

        if trySetBaseProperty(drawing, instance, key :: any, value) then
            if key == "Transparency" then
                drawing[key] = value
                updateTransparencyWithStroke(drawing.Filled, value, instance, stroke)
            elseif key == "Color" then
                drawing[key] = value
                instance.BackgroundColor3 = value
                stroke.Color = value

            elseif key == "Thickness" then
                drawing[key] = value
                stroke.Thickness = value
                -- updateFrame2Size(drawing, frame2, size)
            elseif key == "NumSides" then
                drawing[key] = value
            elseif key == "Radius" then
                local value = value :: number
                drawing[key] = value
                local size = Vector2.new(value * 2, value * 2)
                -- self.size = size
                instance.Size = UDim2.fromOffset(size.X, size.Y)
                -- updateFrame2Size(drawing, frame2, size)
                -- updateFrame2Position(frame2)
            elseif key == "Filled" then
                drawing[key] = value
                updateFilledWithStroke(self, instance, value)
            elseif key == "Position" then
                local value = value :: Vector2
                drawing[key] = value
                local radius = drawing.Radius
                instance.Position = UDim2.fromOffset(value.X - radius, value.Y - radius)
            else
                throwInvalidProperty("Circle", key)
            end
        end
    end
}

local function updateSquareInstanceSize(instance: Frame, square_size: Vector2)
    instance.Size = UDim2.fromOffset(square_size.X, square_size.Y)
end
local function updateSquareInstancePosition(instance: Frame, square_position: Vector2)
    instance.Position = UDim2.fromOffset(
        square_position.X,
        square_position.Y
    )
end
local square_metatable = {
    __index = function(self: DrawingSquare, key: string)
        throwInvalidProperty("Square", key)
    end
}
local square_proxy_metatable = {
    __index = function(self: DrawingSquareProxy, key: square_property)
        return self.drawing[key]
    end,
    __newindex = function(self: DrawingSquareProxy, key: square_property, value: any)
        local drawing = self.drawing
        local instance = self.instance
        local frame2 = self.frame2
        local stroke = self.stroke

        if trySetBaseProperty(drawing, instance, key :: any, value) then
            if key == "Transparency" then
                drawing[key] = value
                updateTransparencyWithStroke(drawing.Filled, value, instance, stroke)
            elseif key == "Color" then
                drawing[key] = value
                instance.BackgroundColor3 = value
                stroke.Color = value

            elseif key == "Thickness" then
                drawing[key] = value
                stroke.Thickness = value
                updateFrame2Size(drawing, frame2, drawing.Size)
            elseif key == "Size" then
                local value = value :: Vector2
                drawing[key] = value
                updateSquareInstanceSize(instance, value)
                updateFrame2Size(drawing, frame2, value)
                updateFrame2Position(frame2)
            elseif key == "Position" then
                local value = value :: Vector2
                drawing[key] = value
                updateSquareInstancePosition(instance, value)
            elseif key == "Filled" then
                drawing[key] = value
                updateFilledWithStroke(self, instance, value)
            else
                throwInvalidProperty("Square", key)
            end
        end
    end
}

local triangle_metatable = {
    __index = function(self: DrawingTriangle, key: string)
        throwInvalidProperty("Triangle", key)
    end
}
local triangle_proxy_metatable = {
    __index = function(self: DrawingTriangleProxy, key: triangle_property)
        return self.drawing[key]
    end,
    __newindex = function(self: DrawingTriangleProxy, key: triangle_property, value: any)
        local drawing = self.drawing
        local instance = self.instance
        local pointa = self.pointa
        local pointb = self.pointb
        local pointc = self.pointc

        if trySetBaseProperty(drawing, instance, key :: any, value) then
            if key == "Transparency" then
                drawing[key] = value
                local transparency = 1 - value
                pointa.BackgroundTransparency = transparency
                pointb.BackgroundTransparency = transparency
                pointc.BackgroundTransparency = transparency
            elseif key == "Color" then
                drawing[key] = value
                pointa.BackgroundColor3 = value
                pointb.BackgroundColor3 = value
                pointc.BackgroundColor3 = value

            elseif key == "Thickness" then
                drawing[key] = value
                -- im sorry
                ;(self::any).PointA = drawing.PointA
                ;(self::any).PointB = drawing.PointB
                ;(self::any).PointC = drawing.PointC
            elseif key == "PointA" then
                drawing[key] = value
                local thickness = drawing.Thickness
                updatePosition(pointa, value, drawing.PointB, thickness)
                updatePosition(pointc, drawing.PointC, value, thickness)
            elseif key == "PointB" then
                drawing[key] = value
                local thickness = drawing.Thickness
                updatePosition(pointa, drawing.PointA, value, thickness)
                updatePosition(pointb, value, drawing.PointC, thickness)
            elseif key == "PointC" then
                drawing[key] = value
                local thickness = drawing.Thickness
                updatePosition(pointb, drawing.PointB, value, thickness)
                updatePosition(pointc, value, drawing.PointA, thickness)
            elseif key == "Filled" then
                drawing[key] = value
            else
                throwInvalidProperty("Triangle", key)
            end
        end
    end
}
local quad_metatable = {
    __index = function(self: DrawingQuad, key: string)
        throwInvalidProperty("Quad", key)
    end
}
local quad_proxy_metatable = {
    __index = function(self: DrawingQuadProxy, key: quad_property)
        return self.drawing[key]
    end,
    __newindex = function(self: DrawingQuadProxy, key: quad_property, value: any)
        local drawing = self.drawing
        local instance = self.instance
        local pointa = self.pointa
        local pointb = self.pointb
        local pointc = self.pointc
        local pointd = self.pointd

        if trySetBaseProperty(drawing, instance, key :: any, value) then
            if key == "Transparency" then
                drawing[key] = value
                local transparency = 1 - value
                pointa.BackgroundTransparency = transparency
                pointb.BackgroundTransparency = transparency
                pointc.BackgroundTransparency = transparency
                pointd.BackgroundTransparency = transparency
            elseif key == "Color" then
                drawing[key] = value
                pointa.BackgroundColor3 = value
                pointb.BackgroundColor3 = value
                pointc.BackgroundColor3 = value
                pointd.BackgroundColor3 = value

            elseif key == "Thickness" then
                drawing[key] = value
                -- im sorry
                ;(self::any).PointA = drawing.PointA
                ;(self::any).PointB = drawing.PointB
                ;(self::any).PointC = drawing.PointC
                ;(self::any).PointD = drawing.PointD
            elseif key == "PointA" then
                drawing[key] = value
                local thickness = drawing.Thickness
                updatePosition(pointa, value, drawing.PointB, thickness)
                updatePosition(pointd, drawing.PointD, value, thickness)
            elseif key == "PointB" then
                drawing[key] = value
                local thickness = drawing.Thickness
                updatePosition(pointa, drawing.PointA, value, thickness)
                updatePosition(pointb, value, drawing.PointC, thickness)
            elseif key == "PointC" then
                drawing[key] = value
                local thickness = drawing.Thickness
                updatePosition(pointb, drawing.PointB, value, thickness)
                updatePosition(pointc, value, drawing.PointD, thickness)
            elseif key == "PointD" then
                drawing[key] = value
                local thickness = drawing.Thickness
                updatePosition(pointc, drawing.PointC, value, thickness)
                updatePosition(pointd, value, drawing.PointA, thickness)
            elseif key == "Filled" then
                drawing[key] = value
            else
                throwInvalidProperty("Quad", key)
            end
        end
    end
}

Drawing = {
    root = nil,
    setRoot = function(self: DrawingAPI, root: ScreenGui)
        self.root = root
    end,

    _addToDrawingList = function(self: DrawingAPI, drawing: Drawing, instance: GuiObject, drawing_metatable: generic_map, proxy_metatable: generic_map, extra: generic_map): Drawing
        local new_count = self._drawing_list_count + 1
        self._drawing_list_count = new_count

        local proxy = {
            drawing = setmetatable(drawing :: any, drawing_metatable),
            instance = instance
        }
        for k,v in extra do
            proxy[k] = v
        end
        self._drawing_list[new_count] = proxy

        local obj = setmetatable(proxy, proxy_metatable)
        for k,v in drawing :: any do
            -- TODO: verify if this is needed
            -- if it is, find another way cuz this is shitty
            if k == "_alive" or k == "Destroy" or k == "TextBounds"
                -- or k == "ImageSize"
            then
                continue
            end
            obj[k] = v
        end

        return obj :: any
    end,

    _newLine = function(self: DrawingAPI): DrawingLine
        local instance = Instance.new("Frame")
        instance.BorderSizePixel = 0
        instance.Parent = self.root

        return self:_addToDrawingList({
            _alive = true,

            Visible = false,
            ZIndex = 1,
            Transparency = 1,
            Color = COLOR_WHITE,

            Thickness = 1,
            From = VECTOR2_ZERO,
            To = VECTOR2_ZERO,

            Destroy = _destroy
        }, instance, line_metatable, line_proxy_metatable, {

        }) :: DrawingLine
    end,
    _newText = function(self: DrawingAPI): DrawingText
        local instance = Instance.new("TextLabel")
        instance.BackgroundTransparency = 1
        instance.TextXAlignment = TEXT_X_ALIGNMENT_LEFT
        instance.TextYAlignment = TEXT_Y_ALIGNMENT_TOP
        instance.Parent = self.root

        local stroke = Instance.new("UIStroke")
        stroke.LineJoinMode = LINE_JOIN_MODE_MITER
        stroke.Parent = instance

        return self:_addToDrawingList({
            _alive = true,

            Visible = false,
            ZIndex = 1,
            Transparency = 1,
            Color = COLOR_WHITE,

            Text = "🐷",
            TextBounds = VECTOR2_ZERO,
            Size = 0,
            Font = FONT_DEFAULT,
            Centered = false,
            Outline = false,
            OutlineColor = COLOR_BLACK,
            Position = VECTOR2_ZERO,

            Destroy = _destroy
        }, instance, text_metatable, text_proxy_metatable, {
            stroke = stroke,
            text_bounds = VECTOR2_ZERO
        }) :: DrawingText
    end,
    _newImage = function(self: DrawingAPI): DrawingImage
        local instance = Instance.new("ImageLabel")
        instance.BackgroundTransparency = 1
        instance.Parent = self.root

        local ui_corner = Instance.new("UICorner")
        ui_corner.Parent = instance

        return self:_addToDrawingList({
            _alive = true,

            Visible = false,
            ZIndex = 1,
            Transparency = 1,
            Color = COLOR_WHITE,

            Data = "",
            -- ImageSize = VECTOR2_ZERO,
            Size = VECTOR2_ZERO,
            Position = VECTOR2_ZERO,
            Rounding = 0,

            Destroy = _destroy
        }, instance, image_metatable, image_proxy_metatable, {
            ui_corner = ui_corner,
            image_size = VECTOR2_ZERO
        }) :: DrawingImage
    end,
    _newCircle = function(self: DrawingAPI): DrawingCircle
        local instance = Instance.new("Frame")
        instance.BorderSizePixel = 0
        instance.Parent = self.root

        local ui_corner = Instance.new("UICorner")
        ui_corner.CornerRadius = UDim.new(1, 0)
        ui_corner.Parent = instance

        -- local frame2 = Instance.new("Frame")
        -- frame2.BackgroundTransparency = 1
        -- frame2.Parent = instance

        -- ui_corner:Clone().Parent = frame2

        local stroke = Instance.new("UIStroke")
        stroke.LineJoinMode = LINE_JOIN_MODE_ROUND
        stroke.Parent = instance

        return self:_addToDrawingList({
            _alive = true,

            Visible = false,
            ZIndex = 1,
            Transparency = 1,
            Color = COLOR_WHITE,

            Thickness = 1,
            NumSides = 0,
            Radius = 0,
            Filled = false,
            Position = VECTOR2_ZERO,

            Destroy = _destroy
        }, instance, circle_metatable, circle_proxy_metatable, {
            -- frame2 = frame2,
            stroke = stroke,
            -- size = VECTOR2_ZERO
        }) :: DrawingCircle
    end,
    _newSquare = function(self: DrawingAPI): DrawingSquare
        local instance = Instance.new("Frame")
        instance.BorderSizePixel = 0
        instance.Parent = self.root

        local frame2 = Instance.new("Frame")
        frame2.BackgroundTransparency = 1
        frame2.Parent = instance

        local stroke = Instance.new("UIStroke")
        stroke.LineJoinMode = LINE_JOIN_MODE_MITER
        stroke.Parent = frame2

        return self:_addToDrawingList({
            _alive = true,

            Visible = false,
            ZIndex = 1,
            Transparency = 1,
            Color = COLOR_WHITE,

            Thickness = 1,
            Size = VECTOR2_ZERO,
            Position = VECTOR2_ZERO,
            Filled = false,

            Destroy = _destroy
        }, instance, square_metatable, square_proxy_metatable, {
            frame2 = frame2,
            stroke = stroke
        }) :: DrawingSquare
    end,
    _newTriangle = function(self: DrawingAPI): DrawingTriangle
        local instance = Instance.new("Frame")
        instance.BackgroundTransparency = 1
        instance.Parent = self.root

        local pointa = Instance.new("Frame")
        pointa.AnchorPoint = Vector2.new(0.5, 0.5)
        pointa.BorderSizePixel = 0
        pointa.Parent = instance

        local pointb = pointa:Clone()
        pointb.Parent = instance

        local pointc = pointa:Clone()
        pointc.Parent = instance

        return self:_addToDrawingList({
            _alive = true,

            Visible = false,
            ZIndex = 1,
            Transparency = 1,
            Color = COLOR_WHITE,

            Thickness = 1,
            PointA = VECTOR2_ZERO,
            PointB = VECTOR2_ZERO,
            PointC = VECTOR2_ZERO,
            Filled = false,

            Destroy = _destroy
        }, instance, triangle_metatable, triangle_proxy_metatable, {
            pointa = pointa,
            pointb = pointb,
            pointc = pointc
        }) :: DrawingTriangle
    end,
    _newQuad = function(self: DrawingAPI): DrawingQuad
        local instance = Instance.new("Frame")
        instance.Parent = self.root

        local pointa = Instance.new("Frame")
        pointa.AnchorPoint = Vector2.new(0.5, 0.5)
        pointa.BorderSizePixel = 0
        pointa.Parent = instance

        local pointb = pointa:Clone()
        pointb.Parent = instance

        local pointc = pointa:Clone()
        pointc.Parent = instance

        local pointd = pointa:Clone()
        pointd.Parent = instance

        return self:_addToDrawingList({
            _alive = true,

            Visible = false,
            ZIndex = 1,
            Transparency = 1,
            Color = COLOR_WHITE,

            Thickness = 1,
            PointA = VECTOR2_ZERO,
            PointB = VECTOR2_ZERO,
            PointC = VECTOR2_ZERO,
            PointD = VECTOR2_ZERO,
            Filled = false,

            Destroy = _destroy
        }, instance, quad_metatable, quad_proxy_metatable, {
            pointa = pointa,
            pointb = pointb,
            pointc = pointc,
            pointd = pointd
        }) :: DrawingQuad
    end,
    new = function(self: DrawingAPI, class_name: valid_class_name): Drawing
        if class_name == "Line" then
            return self:_newLine()
        elseif class_name == "Text" then
            return self:_newText()
        elseif class_name == "Image" then
            return self:_newImage()
        elseif class_name == "Circle" then
            return self:_newCircle()
        elseif class_name == "Square" then
            return self:_newSquare()
        elseif class_name == "Triangle" then
            return self:_newTriangle()
        elseif class_name == "Quad" then
            return self:_newQuad()
        else
            error("invalid class name '" .. tostring(class_name) .. '\'')
        end
    end,

    Font = {
        new = function(self: DrawingFontAPI, content: string): number
            local id = self._font_cache[content]
            if not id then
                id = #self._font_list + 1
                local id: number = id::any
                self._font_list[id] = Font.new(getFontAsset(content))
                self._font_cache[content] = id
            end
            return id :: number
        end,

        _font_list = {
            [0] = FONT_DEFAULT_INTERNAL
        },
        _font_cache = {}
    },

    _drawing_list = {},
    _drawing_list_count = 0,

    clearDrawCache = function(self: DrawingAPI)
        self:cleardrawcache()
    end,
    cleardrawcache = function(self: DrawingAPI)
        for i = 1, self._drawing_list_count do
            (self._drawing_list[i]::any):Destroy()
        end
        self._drawing_list = {}
    end
}

_destroy = function(drawing_proxy)
    local drawing = drawing_proxy.drawing
    if not drawing._alive then
        error("attempt to call Destroy on an unalive drawing")
    end
    (drawing::DrawingBase)._alive = false
    drawing_proxy.instance:Destroy()

    removeValue(Drawing._drawing_list, drawing_proxy, Drawing._drawing_list_count)
    Drawing._drawing_list_count -= 1
end

return Drawing