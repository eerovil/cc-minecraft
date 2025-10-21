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
