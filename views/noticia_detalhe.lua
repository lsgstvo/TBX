-- views/noticia_detalhe.lua
-- Exibe o conteúdo completo de uma notícia individual

local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  article({ class = "shadow-card noticia-detalhe" }, function()
    -- Cabeçalho com tag do jogo e data
    div({ class = "noticia-header" }, function()
      span({ class = "tag" }, self.noticia.jogo)
      span({ class = "data-noticia" }, self.noticia.criado_em:sub(1, 10))
    end)

    h2(self.noticia.titulo)

    div({ class = "noticia-corpo" }, function()
      p(self.noticia.conteudo)
    end)

    div({ class = "noticia-footer" }, function()
      a({ href = "/noticias", class = "btn-voltar" }, "← Voltar para notícias")
    end)
  end)
end)