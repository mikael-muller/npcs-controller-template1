local asset = game.ReplicatedStorage.Assets.Customization
local validParts = {
    "Right Arm",
    "Left Arm",
    "Head",
    "Torso",
    "Right Leg",
    "Left Leg"
}

local function getAssetForIndex(representFolder: Folder, index: number)
    return representFolder:FindFirstChild(tostring(index))
end

local function setHairWeld(model: Model, head, color)
    local c0 = model:GetAttribute("C0")
    model.Parent = head.Parent

    local weld = Instance.new("Weld", head)
    weld.Part0 = model.PrimaryPart
    weld.Part1 = head
	
	if tonumber(model.Name) > 20 then
		weld.C1 = c0
	else
		weld.C0 = c0
	end
	
    model.PrimaryPart.Color = color or Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255))
end

local function RandomFrom(folder)
    local maxAssets = #folder:GetChildren()

    return math.random(1, maxAssets)
end

local function LoadApparence(character, ignore_cloth: boolean)
    local BodyColor = getAssetForIndex(asset.BodyColors, RandomFrom(asset.BodyColors)) :: Color3Value
    local Shirt = getAssetForIndex(asset.Shirts,RandomFrom(asset.Shirts)):Clone() :: Shirt
    local Pants = getAssetForIndex(asset.Pants, RandomFrom(asset.Pants)):Clone() :: Pants
    local Mounth = getAssetForIndex(asset.Mouths, RandomFrom(asset.Mouths)):Clone() :: Decal
    local Eyes = getAssetForIndex(asset.Eyes, RandomFrom(asset.Eyes)):Clone() :: Decal
    local Hair = getAssetForIndex(asset.Hairs, RandomFrom(asset.Hairs)):Clone() :: Model
    local Hair2 = getAssetForIndex(asset.Hairs, RandomFrom(asset.Hairs)):Clone() :: Model

    for _, part in character:GetChildren() do
        if table.find(validParts, part.Name) then
            part.Color = BodyColor.Value
        end
	end
	
	if not ignore_cloth then
	    Shirt.Parent = character
	    Pants.Parent = character
	end
	
    Mounth.Parent = character.Head
    Eyes.Parent = character.Head
    
    local color = Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255))
	
    setHairWeld(Hair, character.Head, color)
    setHairWeld(Hair2, character.Head, color)
end

return LoadApparence