-- views/comparar_jogos.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "shadow-card" }, function()
    h2("⚔️ Comparar Jogos")
    p({ class = "comparar-desc" }, "Escolha dois jogos do ranking para comparar lado a lado.")

    -- Seletor
    form({ method = "GET", action = "/comparar", class = "comparar-form" }, function()
      div({ class = "form-row" }, function()
        div({ class = "form-group form-grow" }, function()
          label({ ["for"] = "a" }, "Jogo A")
          element("select", { id = "a", name = "a" }, function()
            option({ value = "" }, "— Selecione —")
            for _, j in ipairs(self.jogos or {}) do
              local attrs = { value = tostring(j.id) }
              if self.id_a == j.id then attrs.selected = true end
              option(attrs, "#" .. j.posicao .. " " .. j.nome)
            end
          end)
        end)
        div({ class = "comparar-vs" }, function() span("VS") end)
        div({ class = "form-group form-grow" }, function()
          label({ ["for"] = "b" }, "Jogo B")
          element("select", { id = "b", name = "b" }, function()
            option({ value = "" }, "— Selecione —")
            for _, j in ipairs(self.jogos or {}) do
              local attrs = { value = tostring(j.id) }
              if self.id_b == j.id then attrs.selected = true end
              option(attrs, "#" .. j.posicao .. " " .. j.nome)
            end
          end)
        end)
      end)
      button({ type = "submit", class = "btn-salvar" }, "⚔️ Comparar")
    end)
  end)

  -- Resultado da comparação
  if self.comparacao then
    local ja = self.comparacao.a
    local jb = self.comparacao.b

    -- Helper local: barra comparativa
    local function barra_comparativa(val_a, val_b, label)
      local total = (tonumber(val_a) or 0) + (tonumber(val_b) or 0)
      local pct_a = total > 0 and math.floor(((tonumber(val_a) or 0) / total) * 100) or 50
      local pct_b = 100 - pct_a

      div({ class = "comp-row" }, function()
        span({ class = "comp-val comp-val-a" }, tostring(val_a or 0))
        div({ class = "comp-barra-wrapper" }, function()
          div({ class = "comp-barra-a", style = "width:" .. pct_a .. "%" })
          div({ class = "comp-barra-b", style = "width:" .. pct_b .. "%" })
        end)
        span({ class = "comp-val comp-val-b" }, tostring(val_b or 0))
      end)
      div({ class = "comp-label" }, label)
    end

    div({ class = "shadow-card mt-2 comparar-resultado" }, function()

      -- Cabeçalhos dos jogos
      div({ class = "comp-headers" }, function()
        -- Jogo A
        div({ class = "comp-jogo comp-jogo-a" }, function()
          if ja.imagem_url ~= "" then
            img({ src = ja.imagem_url, alt = ja.nome, class = "comp-capa" })
          else
            div({ class = "comp-capa-placeholder" }, ja.nome:sub(1,2))
          end
          h3(ja.nome)
          div({ class = "comp-meta" }, function()
            span({ class = "tag" }, ja.genero)
            span({ class = "jogo-rank" }, "🏆 #" .. tostring(ja.posicao))
          end)
        end)

        div({ class = "comp-vs-badge" }, "VS")

        -- Jogo B
        div({ class = "comp-jogo comp-jogo-b" }, function()
          if jb.imagem_url ~= "" then
            img({ src = jb.imagem_url, alt = jb.nome, class = "comp-capa" })
          else
            div({ class = "comp-capa-placeholder" }, jb.nome:sub(1,2))
          end
          h3(jb.nome)
          div({ class = "comp-meta" }, function()
            span({ class = "tag" }, jb.genero)
            span({ class = "jogo-rank" }, "🏆 #" .. tostring(jb.posicao))
          end)
        end)
      end)

      -- Tabela de comparativos
      div({ class = "comp-tabela" }, function()
        h3({ class = "comp-secao-titulo" }, "📊 Comparativo")

        -- Ranking (menor = melhor)
        local rank_a = tonumber(ja.posicao) or 99
        local rank_b = tonumber(jb.posicao) or 99
        div({ class = "comp-item" }, function()
          span({ class = "comp-item-label" }, "🏆 Posição no Ranking")
          div({ class = "comp-item-vals" }, function()
            span({ class = "comp-iv" .. (rank_a < rank_b and " comp-winner" or "") },
              "#" .. tostring(ja.posicao))
            span({ class = "comp-sep" }, "·")
            span({ class = "comp-iv" .. (rank_b < rank_a and " comp-winner" or "") },
              "#" .. tostring(jb.posicao))
          end)
        end)

        -- Avaliação
        div({ class = "comp-item" }, function()
          span({ class = "comp-item-label" }, "⭐ Avaliação Média")
          div({ class = "comp-item-vals" }, function()
            local ma = tonumber(ja.media_aval) or 0
            local mb = tonumber(jb.media_aval) or 0
            span({ class = "comp-iv" .. (ma >= mb and " comp-winner" or "") },
              string.format("%.1f (%d votos)", ma, ja.total_avals or 0))
            span({ class = "comp-sep" }, "·")
            span({ class = "comp-iv" .. (mb > ma and " comp-winner" or "") },
              string.format("%.1f (%d votos)", mb, jb.total_avals or 0))
          end)
        end)

        -- Barras comparativas
        barra_comparativa(ja.total_noticias, jb.total_noticias,  "📰 Notícias publicadas")
        barra_comparativa(ja.views_noticias, jb.views_noticias,  "👁 Views nas notícias")
        barra_comparativa(ja.likes_noticias, jb.likes_noticias,  "👍 Curtidas nas notícias")

        -- Gênero
        div({ class = "comp-item" }, function()
          span({ class = "comp-item-label" }, "🎯 Gênero")
          div({ class = "comp-item-vals" }, function()
            span({ class = "tag" }, ja.genero ~= "" and ja.genero or "—")
            span({ class = "comp-sep" }, "·")
            span({ class = "tag" }, jb.genero ~= "" and jb.genero or "—")
          end)
        end)

        -- Base de jogadores
        div({ class = "comp-item" }, function()
          span({ class = "comp-item-label" }, "👥 Base de Jogadores")
          div({ class = "comp-item-vals" }, function()
            span({ class = "comp-iv" }, ja.players)
            span({ class = "comp-sep" }, "·")
            span({ class = "comp-iv" }, jb.players)
          end)
        end)

        -- Última notícia
        div({ class = "comp-item" }, function()
          span({ class = "comp-item-label" }, "📅 Última Notícia")
          div({ class = "comp-item-vals" }, function()
            if ja.ultima_noticia then
              span({ class = "comp-iv", style = "font-size:.82rem" },
                ja.ultima_noticia.criado_em:sub(1,10))
            else
              span({ class = "comp-iv", style = "color:var(--text-muted)" }, "—")
            end
            span({ class = "comp-sep" }, "·")
            if jb.ultima_noticia then
              span({ class = "comp-iv", style = "font-size:.82rem" },
                jb.ultima_noticia.criado_em:sub(1,10))
            else
              span({ class = "comp-iv", style = "color:var(--text-muted)" }, "—")
            end
          end)
        end)
      end)

      -- Links de ação
      div({ class = "comp-acoes" }, function()
        a({ href = "/jogos/" .. ja.nome, class = "btn-ver-mais" },
          "Ver tudo sobre " .. ja.nome .. " →")
        a({ href = "/jogos/" .. jb.nome, class = "btn-ver-mais" },
          "Ver tudo sobre " .. jb.nome .. " →")
      end)
    end)
  end
end)