local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    div({ class = "section-header" }, function()
      h2("🔍 SEO Global — Todas as Notícias")
      div({ class = "seo-global-filtros" }, function()
        local ordens = {
          { "score_asc",  "⬇️ Pior SEO primeiro" },
          { "score_desc", "⬆️ Melhor SEO primeiro" },
          { "recente",    "📅 Mais recentes" },
        }
        for _, o in ipairs(ordens) do
          a({ href  = "/admin/seo-global?ordem=" .. o[1],
              class = "janela-btn" .. (self.ordem == o[1] and " janela-ativa" or "") },
            o[2])
        end
      end)
    end)

    -- Resumo de distribuição de grades
    if self.noticias and #self.noticias > 0 then
      local dist = { A=0, B=0, C=0, D=0, F=0 }
      for _, n in ipairs(self.noticias) do
        if n.seo_grade then dist[n.seo_grade.letra] = (dist[n.seo_grade.letra] or 0) + 1 end
      end
      div({ class = "seo-global-dist" }, function()
        for _, letra in ipairs({"A","B","C","D","F"}) do
          local cores = { A="#4ade80", B="#a3e635", C="#f59e0b", D="#f97316", F="#f43f5e" }
          div({ class = "seo-dist-item" }, function()
            span({ class  = "seo-grade-mini",
                   style  = "background:" .. (cores[letra] or "#94a3b8") },
                 letra)
            span({ class = "seo-dist-num" }, tostring(dist[letra] or 0))
          end)
        end
        span({ class = "seo-dist-total", style = "color:var(--text-muted);font-size:.82rem" },
          "de " .. tostring(self.total or 0) .. " notícias")
      end)
    end

    -- Tabela
    element("table", { class = "admin-table" }, function()
      thead(function()
        tr(function()
          th("Grade"); th("Notícia"); th("Score"); th("Avisos"); th("Views"); th("Ações")
        end)
      end)
      tbody(function()
        for _, n in ipairs(self.noticias or {}) do
          local g = n.seo_grade or { letra = "?", cor = "#94a3b8", label = "?" }
          tr(function()
            td(function()
              span({ class  = "seo-grade-mini",
                     style  = "background:" .. g.cor,
                     title  = g.label }, g.letra)
            end)
            td({ class = "titulo-col" }, n.titulo)
            td({ style = "font-weight:700;color:" .. g.cor },
              tostring(n.seo_score or 0) .. "/100")
            td(function()
              if (n.seo_avisos or 0) > 0 then
                span({ style = "color:var(--gold-color);font-weight:700" },
                  "⚠️ " .. tostring(n.seo_avisos))
              else
                span({ style = "color:#4ade80" }, "✅ ok")
              end
            end)
            td({ class = "views-col" }, "👁 " .. tostring(n.views or 0))
            td({ class = "acoes-col" }, function()
              a({ href  = "/admin/noticias/" .. n.id .. "/seo",
                  class = "btn-seo" }, "🔍 Detalhes")
              a({ href  = "/admin/noticias/" .. n.id .. "/editar",
                  class = "btn-editar" }, "✏️")
            end)
          end)
        end
      end)
    end)

    -- Paginação
    if (self.total_pag or 1) > 1 then
      div({ class = "paginacao paginacao-sm" }, function()
        local extra = "&ordem=" .. (self.ordem or "score_asc")
        if self.pagina > 1 then
          a({ href  = "/admin/seo-global?pagina=" .. (self.pagina-1) .. extra,
              class = "pag-btn" }, "←")
        end
        for i = 1, self.total_pag do
          if i == self.pagina then
            span({ class = "pag-btn pag-atual" }, tostring(i))
          else
            a({ href  = "/admin/seo-global?pagina=" .. i .. extra,
                class = "pag-btn" }, tostring(i))
          end
        end
        if self.pagina < self.total_pag then
          a({ href  = "/admin/seo-global?pagina=" .. (self.pagina+1) .. extra,
              class = "pag-btn" }, "→")
        end
      end)
    end
  end)
end)