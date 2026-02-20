--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                   SolarisIcons v1.0                          ║
    ║         Local Icon Library Loader for SolarisUI              ║
    ║                                                              ║
    ║  Self-hosted replacement for Nebula-Icon-Library.             ║
    ║  No HttpGetAsync or loadstring needed — all data is local.   ║
    ╚══════════════════════════════════════════════════════════════╝

    Setup:
        Place each .luau icon file as a ModuleScript inside a folder.

        ReplicatedStorage/
          └── SolarisIcons/           (this ModuleScript)
              ├── MaterialIcons       (ModuleScript — paste MaterialIcons.luau)
              ├── LucideIcons         (ModuleScript — paste LucideIcons.luau)
              ├── Phosphor            (ModuleScript — paste Phosphor.luau)
              ├── PhosphorFilled      (ModuleScript — paste PhosphorFilled.luau)
              ├── SFSymbols           (ModuleScript — paste SFSymbols.luau)
              ├── Symbols             (ModuleScript — paste Symbols.luau)
              ├── SymbolsFilled       (ModuleScript — paste SymbolsFilled.luau)
              ├── LucideLab           (ModuleScript — paste LucideLab.luau)
              └── Fluency             (ModuleScript — paste Fluency.luau)

    Usage:
        local Icons = require(ReplicatedStorage.SolarisIcons)

        -- Get an icon asset ID
        local id = Icons:GetIcon("home", "MaterialIcons")
        -- id = 6026568195

        -- Use it in an ImageLabel
        imageLabel.Image = "rbxassetid://" .. id

        -- Default source is "Symbols" if you omit the second argument
        local id2 = Icons:GetIcon("star")
]]

local ContentProvider = game:GetService("ContentProvider")

local module = {}

-- Icon sources mapped to their child ModuleScript names.
-- Each key matches the original Nebula naming convention.
local SOURCE_MAP = {
    Material          = "MaterialIcons",
    MaterialIcons     = "MaterialIcons",
    Lucide            = "LucideIcons",
    LucideIcons       = "LucideIcons",
    Phosphor          = "Phosphor",
    ["Phosphor-Filled"] = "PhosphorFilled",
    PhosphorFilled    = "PhosphorFilled",
    SF                = "SFSymbols",
    SFSymbols         = "SFSymbols",
    Symbols           = "Symbols",
    ["Symbols-Filled"]  = "SymbolsFilled",
    SymbolsFilled     = "SymbolsFilled",
    Lab               = "LucideLab",
    LucideLab         = "LucideLab",
    Fluency           = "Fluency",
}

-- Lazy-load cache: icon tables are only require()'d when first accessed
local _cache = {}

local function getSource(sourceName)
    sourceName = sourceName or "Symbols"

    -- Resolve alias
    local moduleName = SOURCE_MAP[sourceName]
    if not moduleName then
        warn("[SolarisIcons] Unknown source: " .. tostring(sourceName) .. ". Falling back to Symbols.")
        moduleName = "Symbols"
    end

    -- Return cached if already loaded
    if _cache[moduleName] then
        return _cache[moduleName]
    end

    -- Require the child ModuleScript
    local thisModule = script
    local child = thisModule:FindFirstChild(moduleName)
    if not child then
        warn("[SolarisIcons] ModuleScript '" .. moduleName .. "' not found as a child of SolarisIcons. Did you add it?")
        return {}
    end

    local ok, data = pcall(require, child)
    if not ok then
        warn("[SolarisIcons] Failed to require '" .. moduleName .. "': " .. tostring(data))
        return {}
    end

    _cache[moduleName] = data
    return data
end

--- Get an icon's asset ID by name.
--- @param name string — the icon name (e.g. "home", "star", "check")
--- @param source string? — the icon library to search (default "Symbols")
--- @return number? — the Roblox asset ID, or nil if not found
function module:GetIcon(name, source)
    local icons = getSource(source)
    local assetId = icons[name]

    if not assetId then
        warn("[SolarisIcons] Icon '" .. tostring(name) .. "' not found in source '" .. tostring(source or "Symbols") .. "'")
        return nil
    end

    -- Preload the image asset so it's ready when displayed
    pcall(function()
        ContentProvider:PreloadAsync({ "rbxassetid://" .. assetId })
    end)

    return assetId
end

--- Get the full rbxassetid:// string for direct use in Image properties.
--- @param name string
--- @param source string?
--- @return string?
function module:GetIconImage(name, source)
    local id = self:GetIcon(name, source)
    if id then
        return "rbxassetid://" .. id
    end
    return nil
end

--- List all icon names in a source (useful for building icon browsers).
--- @param source string?
--- @return {string}
function module:ListIcons(source)
    local icons = getSource(source)
    local names = {}
    for name in pairs(icons) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

--- Search for icons whose name contains the query string.
--- @param query string
--- @param source string?
--- @return {[string]: number} — matching name -> assetId pairs
function module:SearchIcons(query, source)
    local icons = getSource(source)
    local results = {}
    local lowerQuery = string.lower(query)
    for name, id in pairs(icons) do
        if string.find(string.lower(name), lowerQuery, 1, true) then
            results[name] = id
        end
    end
    return results
end

--- Get the count of icons in a source.
--- @param source string?
--- @return number
function module:CountIcons(source)
    local icons = getSource(source)
    local count = 0
    for _ in pairs(icons) do
        count = count + 1
    end
    return count
end

--- List all available source names.
--- @return {string}
function module:ListSources()
    -- Return unique module names
    local seen = {}
    local sources = {}
    for alias, moduleName in pairs(SOURCE_MAP) do
        if not seen[moduleName] then
            seen[moduleName] = true
            table.insert(sources, alias)
        end
    end
    table.sort(sources)
    return sources
end

return module
