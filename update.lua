-- update.lua  — GitHub SHA-safe updater CC:Tweakedille
-- Lataa valitut tiedostot GitHubista commit-SHA:lla (ei välimuistiongelmia)

-- ===== CONFIG =====
local REPO_OWNER = "eerovil"
local REPO_NAME  = "cc-minecraft"
local BRANCH     = "main"                  -- esim. "main" tai "master"
local FILES = {                            -- src_path_in_repo -> dest_path_on_turtle
  ["lib/utils.lua"]   = "lib/utils.lua",
  ["startup.lua"]     = "startup.lua",
  ["rename.lua"]      = "rename.lua",
  ["update.lua"]      = "update.lua",
}
local STATE_FILE = ".last_sha"             -- minne viimeisin SHA tallennetaan
local UA = "CC-Tweaked-Updater"            -- GitHub API vaatii User-Agentin
-- ===== END CONFIG =====

local label = os.getComputerLabel()
if label then
  local role = label:match("^([^_]+)")
  if not role or role == "" then
    print("Ei voitu päätellä roolia nimestä.")
    return
  end

  -- lisää role.lua päivitettäviin tiedostoihin
  FILES[role .. ".lua"] = role .. ".lua"
end

local function get(url, headers)
  local ok, res = pcall(function() return http.get(url, headers) end)
  if not ok or not res then return nil, "HTTP GET failed: "..tostring(res) end
  local body = res.readAll()
  local hdrs = res.getResponseHeaders() or {}
  res.close()
  return body, nil, hdrs
end

local function save(path, data)
  fs.makeDir(fs.getDir(path))
  local h = fs.open(path, "wb")
  if not h then error("Cannot open "..path.." for writing") end
  h.write(data)
  h.close()
end

local function load(path)
  if not fs.exists(path) then return nil end
  local h = fs.open(path, "r")
  local s = h.readAll()
  h.close()
  return s
end

local function get_latest_sha(owner, repo, branch)
  local url = ("https://api.github.com/repos/%s/%s/commits/%s"):format(owner, repo, branch)
  local body, err = get(url, {["User-Agent"]=UA})
  if not body then return nil, err end
  local ok, json = pcall(textutils.unserializeJSON, body)
  if not ok or not json or not json.sha then
    return nil, "Failed to parse commit JSON"
  end
  return json.sha
end

local function download_file_at_sha(owner, repo, sha, repo_path)
  local raw = ("https://raw.githubusercontent.com/%s/%s/%s/%s"):format(owner, repo, sha, repo_path)
  local body, err = get(raw, {["User-Agent"]=UA})
  if not body then return nil, err end
  return body
end

local function main()
  print("Fetching latest SHA for "..REPO_OWNER.."/"..REPO_NAME.."@"..BRANCH.."...")
  local sha, err = get_latest_sha(REPO_OWNER, REPO_NAME, BRANCH)
  if not sha then
    print("Error:", err)
    return
  end
  local prev = load(STATE_FILE)
  if prev == sha then
    print("Already up-to-date at", sha:sub(1,7))
    return
  end

  print("New commit:", sha)
  for src, dst in pairs(FILES) do
    io.write("  -> "..src.."  ")
    local body, derr = download_file_at_sha(REPO_OWNER, REPO_NAME, sha, src)
    if not body then
      print("FAIL: "..tostring(derr))
      return
    end
    save(dst, body)
    print("ok  ->  "..dst)
  end

  save(STATE_FILE, sha)
  print("Updated to", sha:sub(1,7))
end

local ok, e = pcall(main)
if not ok then
  print("Update failed:", e)
end
