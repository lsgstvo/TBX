-- views/jogo_detalhe.lua
-- Página de detalhes de um jogo com suas notícias relacionadas

local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  -- Card de informações do jogo
  div({ class = "shadow-card jogo-hero" }, function()
    div({ class = "jogo-badge" }, function()
      span({ class = "jogo-posicao" }, "#" .. tostring(self.jogo.posicao))
      span({ class = "tag" }, self.jogo.genero)
    end)
    h2(self.jogo.nome)
    div({ class = "jogo-stats" }, function()
      div({ class = "jogo-stat" }, function()
        span({ class = "stat-label" }, "Jogadores")
        span({ class = "stat-valor" }, self.jogo.players)
      end)
      div({ class = "jogo-stat" }, function()
        span({ class = "stat-label" }, "Gênero")
        span({ class = "stat-valor" }, self.jogo.genero)
      end)
      div({ class = "jogo-stat" }, function()
        span({ class = "stat-label" }, "Ranking")
        span({ class = "stat-valor" }, "#" .. tostring(self.jogo.posicao))
      end)
    end)
  end)

  -- Notícias relacionadas ao jogo
  div({ class = "shadow-card mt-2" }, function()
    h3("📰 Notícias sobre " .. self.jogo.nome)

    if self.noticias and #self.noticias > 0 then
      div({ class = "noticias-grid" }, function()
        for _, noticia in ipairs(self.noticias) do
          article({ class = "noticia-card" }, function()
            div({ class = "noticia-header" }, function()
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
      p({ class = "sem-dados" }, "Nenhuma notícia cadastrada para este jogo ainda.")
    end
  end)

  -- Voltar pro ranking
  div({ class = "mt-2" }, function()
    a({ href = "/ranking", class = "btn-voltar" }, "← Voltar ao Ranking")
  end)
end)