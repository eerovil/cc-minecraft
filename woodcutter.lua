local function safeForward()
  while not turtle.forward() do
    turtle.dig()      -- try to clear block in front
    sleep(0.2)
  end
end

local function line(n)
  for i = 1, n do safeForward() end
end

print("Going for a short walk...")
line(5)
print("Done!")

