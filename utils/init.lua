--- func description
---@generic T
---@param needle T
---@param haystack T[]
---@return number
local function indexOf(needle, haystack)
  for i, value in ipairs(haystack) do
    if value == needle then
      return i
    end
  end
  return -1
end

return {
  indexOf = indexOf
}