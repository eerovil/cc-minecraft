-- startup.lua
-- Kysyy nimen jos ei ole, ajaa update.lua, ja lopuksi ohjelman nimen perusteella.

local function ensureLabel()
  local label = os.getComputerLabel()
  if not label or label == "" then
    shell.run("newname")
  end
  print("Turtlen nimi on: " .. label)
  return label
end

local function runUpdate()
  if fs.exists("update.lua") then
    print("Ajetaan päivitys...")
    local ok, err = pcall(function() shell.run("update") end)
    if not ok then
      print("Päivitys epäonnistui:", err)
      return false
    else
      print("Päivitys valmis.")
      return true
    end
  else
    print("update.lua puuttuu — ohitetaan.")
    return false
  end
end

local function runRoleProgram(label)
  -- Erotetaan rooli nimestä ennen ensimmäistä alaviivaa
  local role = label:match("^([^_]+)")
  if not role or role == "" then
    print("Ei voitu päätellä roolia nimestä.")
    return
  end

  local program = role .. ".lua"
  if fs.exists(program) then
    print("Ajetaan ohjelma: " .. program)
    shell.run(program)
  else
    print("Ohjelmaa '" .. program .. "' ei löytynyt.")
  end
end

-- ===== Pääohjelma =====
local label = ensureLabel()
runUpdate()
runRoleProgram(label)
