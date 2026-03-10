-- views/erro.lua
-- Página de erro genérico (ex: notícia não encontrada)

local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "shadow-card erro-page" }, function()
    h2("😕 Página não encontrada")
    p("O conteúdo que você procura não existe ou foi removido.")
    a({ href = "/", class = "btn-voltar" }, "← Voltar para o início")
end)