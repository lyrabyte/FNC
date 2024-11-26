-- xml.lua
-- Adapted from https://github.com/jonathanpoelen/lua-xmlparser

xml = xml or {}  -- Use existing table or create a new one

local string, pairs = string, pairs

local slashchar = string.byte('/', 1)
local E = string.byte('E', 1)

function xml.defaultEntityTable()
  return { quot='"', apos="'", lt='<', gt='>', amp='&', tab='\t', nbsp=' ' }
end

function xml.replaceEntities(s, entities)
  return s:gsub('&([^;]+);', entities)
end

function xml.createEntityTable(docEntities, resultEntities)
  local entities = resultEntities or xml.defaultEntityTable()
  for _, e in pairs(docEntities) do
    e.value = xml.replaceEntities(e.value, entities)
    entities[e.name] = e.value
  end
  return entities
end

function xml.parse(s, evalEntities)
  -- Remove comments
  s = s:gsub('<!%-%-(.-)%-%->', '')

  local entities = {}
  local tentities = nil

  if evalEntities then
    local pos = s:find('<[_%w]')
    if pos then
      s:sub(1, pos):gsub('<!ENTITY%s+([_%w]+)%s+(.)(.-)%2', function(name, _, entity)
        entities[#entities + 1] = { name = name, value = entity }
      end)
      tentities = xml.createEntityTable(entities)
      s = xml.replaceEntities(s:sub(pos), tentities)
    end
  end

  local t, l = {}, {}

  local addtext = function(txt)
    txt = txt:match('^%s*(.*%S)') or ''
    if #txt ~= 0 then
      t[#t + 1] = { text = txt }
    end
  end

  s:gsub('<([?!/]?)([-:_%w]+)%s*(/?>?)([^<]*)', function(type, name, closed, txt)
    -- Open tag
    if #type == 0 then
      local attrs, orderedattrs = {}, {}
      if #closed == 0 then
        local len = 0
        for all, aname, _, value, starttxt in string.gmatch(txt, "(.-([-_%w]+)%s*=%s*(.)(.-)%3%s*(/?>?))") do
          len = len + #all
          attrs[aname] = value
          orderedattrs[#orderedattrs + 1] = { name = aname, value = value }
          if #starttxt ~= 0 then
            txt = txt:sub(len + 1)
            closed = starttxt
            break
          end
        end
      end
      t[#t + 1] = { tag = name, attrs = attrs, children = {}, orderedattrs = orderedattrs }

      if closed:byte(1) ~= slashchar then
        l[#l + 1] = t
        t = t[#t].children
      end

      addtext(txt)
    -- Close tag
    elseif '/' == type then
      t = l[#l]
      l[#l] = nil
      addtext(txt)
    -- ENTITY declaration
    elseif '!' == type then
      if E == name:byte(1) then
        txt:gsub('([_%w]+)%s+(.)(.-)%2', function(name, _, entity)
          entities[#entities + 1] = { name = name, value = entity }
        end, 1)
      end
    end
  end)

  return { children = t, entities = entities, tentities = tentities }
end

function xml.parseFile(filename, evalEntities)
  local file = playdate.file.open(filename, playdate.file.kFileRead)
  if file then
    local content = ""
    while true do
      local line = file:readline()
      if not line then break end
      content = content .. line .. "\n"
    end
    file:close()
    return xml.parse(content, evalEntities), nil
  else
    return nil, "Could not open file: " .. filename
  end
end

-- No return statement needed
