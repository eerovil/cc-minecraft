
-- try to get input from args
local args = {...}
if args[1] and args[1] ~= "" then
    local name = args[1]
    os.setComputerLabel(name)
    print("Nimi asetettu: " .. name)
    return name
end

print("Anna turtlen nimi (esim. farmer_1):")

io.write("> ")
local name = read()
if name and name ~= "" then
    os.setComputerLabel(name)
    print("Nimi asetettu: " .. name)
    return name
else
    print("Ei nimeä annettu, käytetään tilapäistä nimeä.")
    return "unnamed"
end
