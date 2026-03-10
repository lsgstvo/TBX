local lapis = require("lapis")
local app = lapis.Application()
app.layout = require("views.layout")

-- Página principal
app:get("/", function()
  return { render = "index" }
end)

-- Página de ranking
app:get("/ranking", function()
  local jogos = {
    { nome = "Valorant", players = "Milhões" },
    { nome = "League of Legends", players = "Milhões" },
    { nome = "Counter-Strike 2", players = "Milhões" }
  }

  return { render = "ranking", jogos = jogos }
end)

return app