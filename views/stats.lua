-- views/stats.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  local s = self.stats or {}

  -- ── Cards de totais ───────────────────────────────────────────────────────
  div({ class = "shadow-card" }, function()
    h2("📊 Estatísticas do Portal")
    div({ class = "stats-grid" }, function()
      local cards = {
        { ico = "📰", val = s.total_noticias,  lab = "Notícias"   },
        { ico = "🎮", val = s.total_jogos,      lab = "Jogos"      },
        { ico = "💬", val = s.total_coments,    lab = "Comentários"},
        { ico = "👁",  val = s.total_views,      lab = "Views"      },
        { ico = "🏷",  val = s.total_tags,       lab = "Tags"       },
        { ico = "⭐",  val = s.total_destaques,  lab = "Destaques"  },
      }
      for _, c in ipairs(cards) do
        div({ class = "stats-card" }, function()
          span({ class = "stats-ico" }, c.ico)
          span({ class = "stats-num" }, tostring(c.val or 0))
          span({ class = "stats-lab" }, c.lab)
        end)
      end
    end)
  end)

  -- ── Notícia mais vista ────────────────────────────────────────────────────
  if s.mais_vista then
    div({ class = "shadow-card mt-2" }, function()
      h3("🥇 Notícia Mais Vista")
      div({ class = "mais-vista-card" }, function()
        a({ href = "/noticias/" .. s.mais_vista.id,
            class = "mais-vista-titulo" }, s.mais_vista.titulo)
        span({ class = "mais-vista-views" },
          "👁 " .. tostring(s.mais_vista.views) .. " visualizações")
      end)
    end)
  end

  -- ── Linha: Top jogos + Top categorias ────────────────────────────────────
  div({ class = "stats-row mt-2" }, function()

    -- Top jogos por notícias
    if s.top_jogos and #s.top_jogos > 0 then
      div({ class = "shadow-card stats-col" }, function()
        h3("🎮 Jogos com mais notícias")
        div({ class = "bar-chart" }, function()
          local max = s.top_jogos[1].total
          for _, j in ipairs(s.top_jogos) do
            local pct = max > 0 and math.floor((j.total / max) * 100) or 0
            div({ class = "bar-row" }, function()
              a({ href  = "/jogos/" .. j.jogo,
                  class = "bar-label" }, j.jogo)
              div({ class = "bar-track" }, function()
                div({ class = "bar-fill bar-primary",
                      style = "width:" .. pct .. "%" })
              end)
              span({ class = "bar-val" }, tostring(j.total))
            end)
          end
        end)
      end)
    end

    -- Top categorias por notícias
    if s.top_categorias and #s.top_categorias > 0 then
      div({ class = "shadow-card stats-col" }, function()
        h3("🗂 Categorias mais usadas")
        div({ class = "bar-chart" }, function()
          local max = s.top_categorias[1].total
          for _, c in ipairs(s.top_categorias) do
            local pct = max > 0 and math.floor((c.total / max) * 100) or 0
            div({ class = "bar-row" }, function()
              a({ href  = "/noticias?categoria=" .. c.categoria,
                  class = "bar-label" }, c.categoria)
              div({ class = "bar-track" }, function()
                div({ class = "bar-fill bar-gold",
                      style = "width:" .. pct .. "%" })
              end)
              span({ class = "bar-val" }, tostring(c.total))
            end)
          end
        end)
      end)
    end
  end)

  -- ── Publicações por mês ───────────────────────────────────────────────────
  if s.por_mes and #s.por_mes > 0 then
    div({ class = "shadow-card mt-2" }, function()
      h3("📅 Publicações por Mês")
      local max_mes = 1
      for _, m in ipairs(s.por_mes) do
        if m.total > max_mes then max_mes = m.total end
      end
      -- Inverte para ordem cronológica
      local meses = {}
      for i = #s.por_mes, 1, -1 do table.insert(meses, s.por_mes[i]) end
      div({ class = "mes-chart" }, function()
        for _, m in ipairs(meses) do
          local pct = math.floor((m.total / max_mes) * 100)
          div({ class = "mes-col" }, function()
            div({ class = "mes-bar-wrapper" }, function()
              div({ class  = "mes-bar",
                    style  = "height:" .. math.max(pct, 4) .. "%",
                    title  = m.total .. " notícias" })
            end)
            span({ class = "mes-val" }, tostring(m.total))
            span({ class = "mes-label" }, m.mes:sub(6))  -- só MM
          end)
        end
      end)
    end)
  end

  -- ── Nuvem de tags ─────────────────────────────────────────────────────────
  if s.top_tags and #s.top_tags > 0 then
    div({ class = "shadow-card mt-2" }, function()
      h3("🏷 Tags mais usadas")
      div({ class = "tag-cloud" }, function()
        local max_t = s.top_tags[1] and s.top_tags[1].total or 1
        for _, t in ipairs(s.top_tags) do
          local tam = 0.8 + (t.total / max_t) * 0.8  -- entre 0.8rem e 1.6rem
          a({ href  = "/tag/" .. t.nome,
              class = "tag tag-cloud-item",
              style = "font-size:" .. string.format("%.1f", tam) .. "rem" },
            "#" .. t.nome .. " (" .. t.total .. ")")
        end
      end)
    end)
  end
end)