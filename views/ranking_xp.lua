-- views/ranking_xp.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "shadow-card" }, function()
    h2("🏅 Ranking de Leitores")
    p({ class = "feed-desc" },
      "Os leitores mais ativos do Portal Gamer, rankeados por XP acumulado.")
    div({ class = "feed-acoes" }, function()
      a({ href = "/perfil",   class = "btn-ver-mais" }, "👤 Meu perfil →")
      a({ href = "/torneios", class = "btn-ver-mais" }, "🏆 Torneios →")
    end)
  end)

  -- Legenda de níveis
  div({ class = "shadow-card mt-2" }, function()
    h3("📊 Níveis")
    div({ class = "niveis-grid" }, function()
      for _, n in ipairs(self.niveis_def or {}) do
        div({ class = "nivel-badge-card" }, function()
          span({ class = "nivel-ico" }, n.ico)
          span({ class = "nivel-nome" }, n.nome)
          span({ class = "nivel-xp" }, n.xp_min .. "+ XP")
        end)
      end
    end)
  end)

  -- Ranking
  if self.ranking and #self.ranking > 0 then
    div({ class = "shadow-card mt-2" }, function()
      h3("🏆 Top Leitores")
      div({ class = "ranking-xp-lista" }, function()
        for pos, r in ipairs(self.ranking) do
          local info = r.nivel_info or { nivel = { ico = "🌱", nome = "Novato" }, pct_proximo = 0 }
          div({ class = "ranking-xp-item" }, function()
            -- Posição
            div({ class = "ranking-xp-pos" .. (pos <= 3 and " ranking-hist-top" or "") }, function()
              if     pos == 1 then span("🥇")
              elseif pos == 2 then span("🥈")
              elseif pos == 3 then span("🥉")
              else   span({ class = "trending-num" }, tostring(pos)) end
            end)
            -- Avatar + info
            span({ class = "ranking-xp-avatar" }, r.avatar or "👤")
            div({ class = "ranking-xp-info" }, function()
              p({ class = "ranking-xp-nome" },
                r.nome ~= "" and r.nome or ("Leitor #" .. r.leitor_id:sub(1,6)))
              div({ class = "ranking-xp-nivel" }, function()
                span({ class = "nivel-ico-sm" }, info.nivel.ico)
                span({ class = "nivel-nome-sm" }, info.nivel.nome)
              end)
              -- Barra de progresso para próximo nível
              div({ class = "ranking-xp-barra-bg" }, function()
                div({ class  = "ranking-xp-barra",
                      style  = "width:" .. tostring(info.pct_proximo) .. "%" })
              end)
            end)
            -- XP total
            span({ class = "ranking-xp-total" },
              tostring(r.xp) .. " XP")
          end)
        end
      end)
    end)
  else
    div({ class = "shadow-card mt-2" }, function()
      p({ class = "sem-dados" }, "Nenhum leitor com XP ainda.")
      p({ style = "font-size:.85rem;color:var(--text-muted);margin-top:.5rem" },
        "Leia notícias, comente e curta para acumular XP!")
    end)
  end
end)