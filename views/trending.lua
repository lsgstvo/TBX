-- views/trending.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  -- Seletor de janela de tempo
  div({ class = "shadow-card trending-hero" }, function()
    div({ class = "trending-header" }, function()
      h2("🔥 Trending — Notícias em Alta")
      div({ class = "janela-selector" }, function()
        local janelas = { {1,"1h"}, {6,"6h"}, {24,"24h"}, {48,"48h"}, {168,"7d"} }
        for _, j in ipairs(janelas) do
          local ativo = (self.janela == j[1])
          a({ href  = "/trending?h=" .. j[1],
              class = "janela-btn" .. (ativo and " janela-ativa" or "") },
            j[2])
        end
      end)
    end)
    p({ class = "trending-desc" },
      string.format("As %d notícias mais quentes das últimas %s",
        #(self.noticias or {}),
        self.janela == 1 and "1 hora"
        or self.janela == 168 and "7 dias"
        or tostring(self.janela) .. " horas"))
  end)

  -- Lista de notícias em trending
  if self.noticias and #self.noticias > 0 then
    div({ class = "shadow-card mt-2" }, function()
      div({ class = "trending-lista" }, function()
        for pos, n in ipairs(self.noticias) do
          local score = n.score or 0

          article({ class = "trending-item" }, function()
            -- Posição
            div({ class = "trending-pos" .. (pos <= 3 and " trending-top" or "") }, function()
              if pos == 1 then span("🥇")
              elseif pos == 2 then span("🥈")
              elseif pos == 3 then span("🥉")
              else span({ class = "trending-num" }, tostring(pos))
              end
            end)

            -- Imagem de capa (se houver)
            if n.imagem_url and n.imagem_url ~= "" then
              a({ href = "/noticias/" .. n.id, class = "trending-thumb" }, function()
                img({ src = n.imagem_url, alt = n.titulo, class = "trending-img" })
              end)
            end

            -- Conteúdo
            div({ class = "trending-content" }, function()
              div({ class = "trending-meta" }, function()
                a({ href = "/noticias?categoria=" .. n.categoria, class = "tag" }, n.categoria)
                if n.jogo and n.jogo ~= "" then
                  a({ href = "/jogos/" .. n.jogo, class = "tag tag-jogo" }, n.jogo)
                end
                if n.destaque == 1 then
                  span({ class = "badge-destaque" }, "⭐")
                end
                span({ class = "data-noticia" }, n.criado_em:sub(1, 10))
              end)

              h3(function()
                a({ href = "/noticias/" .. n.id }, n.titulo)
              end)

              -- Autor
              if n.autor_nome and n.autor_nome ~= "" then
                div({ class = "noticia-autor-mini" }, function()
                  if n.autor_avatar and n.autor_avatar ~= "" then
                    img({ src = n.autor_avatar, class = "autor-avatar-mini",
                          alt = n.autor_nome })
                  end
                  a({ href = "/autor/" .. (n.autor_id or ""),
                      class = "autor-mini-nome" }, n.autor_nome)
                end)
              end

              -- Métricas de score
              div({ class = "trending-scores" }, function()
                span({ class = "score-item" },
                  "👁 " .. tostring(n.views or 0))
                span({ class = "score-sep" }, "·")
                span({ class = "score-item score-hoje",
                       title = "Views nas últimas " .. self.janela .. "h" },
                  "📈 " .. tostring(n.views_recentes or 0) .. " recentes")
                span({ class = "score-sep" }, "·")
                span({ class = "score-item" },
                  "💬 " .. tostring(n.coments_recentes or 0) .. " novos coments")
              end)
            end)

            -- Barra de score visual
            div({ class = "trending-bar-wrapper" }, function()
              -- Normaliza para 0-100 usando o score máximo (primeiro item)
              local max_score = self.noticias[1] and (self.noticias[1].score or 1) or 1
              local pct = max_score > 0
                and math.floor((score / max_score) * 100) or 0
              div({ class  = "trending-bar",
                    style  = "width:" .. pct .. "%",
                    title  = string.format("Score: %.1f", score) })
            end)
          end)
        end
      end)
    end)
  else
    div({ class = "shadow-card mt-2" }, function()
      p({ class = "sem-dados" },
        "Nenhuma notícia em alta neste período. Tente uma janela maior.")
      a({ href = "/trending?h=168", class = "btn-ver-mais" }, "Ver últimos 7 dias →")
    end)
  end
end)