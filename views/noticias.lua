-- views/noticias.lua
-- Listagem completa de todas as notícias do banco

local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "shadow-card" }, function()
    h2("📰 Todas as Notícias")

    if self.noticias and #self.noticias > 0 then
      div({ class = "noticias-grid" }, function()
        for _, noticia in ipairs(self.noticias) do
          article({ class = "noticia-card" }, function()
            div({ class = "noticia-header" }, function()
              span({ class = "tag" }, noticia.jogo)
              span({ class = "data-noticia" }, noticia.criado_em:sub(1, 10))
            end)
            h3(function()
              a({ href = "/noticias/" .. noticia.id }, noticia.titulo)
            end)
            p({ class = "noticia-resumo" }, noticia.conteudo:sub(1, 120) .. "...")
            a({ href = "/noticias/" .. noticia.id, class = "btn-ler-mais" }, "Ler mais →")
          end)
        end
      end)
    else
      p({ class = "sem-dados" }, "Nenhuma notícia disponível.")
    end
  end)
end)