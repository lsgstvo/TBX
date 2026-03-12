-- views/jogo_detalhe.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  -- Card principal do jogo
  div({ class = "shadow-card jogo-detalhe" }, function()
    div({ class = "jogo-header" }, function()

      -- Imagem do jogo (se houver)
      if self.jogo.imagem_url and self.jogo.imagem_url ~= "" then
        div({ class = "jogo-capa" }, function()
          img({ src = self.jogo.imagem_url, alt = self.jogo.nome, class = "jogo-img" })
        end)
      else
        div({ class = "jogo-capa jogo-capa-placeholder" }, function()
          span("#" .. tostring(self.jogo.posicao))
        end)
      end

      div({ class = "jogo-info" }, function()
        h2(self.jogo.nome)
        div({ class = "jogo-meta" }, function()
          span({ class = "tag" }, self.jogo.genero)
          span({ class = "jogo-players" }, "👥 " .. self.jogo.players)
          span({ class = "jogo-rank" }, "🏆 #" .. tostring(self.jogo.posicao) .. " no ranking")
        end)
        if self.jogo.descricao and self.jogo.descricao ~= "" then
          p({ class = "jogo-descricao" }, self.jogo.descricao)
        end
      end)
    end)
  end)

  -- Notícias relacionadas
  div({ class = "shadow-card mt-2" }, function()
    h3("📰 Notícias sobre " .. self.jogo.nome)
    if self.noticias and #self.noticias > 0 then
      div({ class = "noticias-grid" }, function()
        for _, n in ipairs(self.noticias) do
          article({ class = "noticia-card" .. (n.destaque == 1 and " card-destaque" or "") }, function()
            div({ class = "noticia-header" }, function()
              a({ href = "/noticias?categoria=" .. n.categoria, class = "tag" }, n.categoria)
              if n.destaque == 1 then span({ class = "badge-destaque" }, "⭐") end
              span({ class = "data-noticia" }, n.criado_em:sub(1, 10))
            end)
            h3(function()
              a({ href = "/noticias/" .. n.id }, n.titulo)
            end)
            p({ class = "noticia-resumo" }, n.conteudo:sub(1, 120) .. "...")
            a({ href = "/noticias/" .. n.id, class = "btn-ler-mais" }, "Ler mais →")
          end)
        end
      end)
    else
      p({ class = "sem-dados" }, "Nenhuma notícia sobre este jogo ainda.")
    end
  end)

  div({ class = "mt-2" }, function()
    a({ href = "/ranking", class = "btn-voltar" }, "← Voltar para o Ranking")
  end)
end)