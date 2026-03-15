-- views/admin/admin_seo.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  local s = self.seo or {}
  local g = s.grade or { letra = "?", cor = "#94a3b8", label = "?" }

  div({ class = "admin-section shadow-card" }, function()
    -- Cabeçalho
    div({ class = "seo-header" }, function()
      div({ class = "seo-grade-badge", style = "background:" .. g.cor }, function()
        span({ class = "seo-grade-letra" }, g.letra)
        span({ class = "seo-grade-label" }, g.label)
      end)
      div({ class = "seo-header-info" }, function()
        h2("🔍 Análise SEO")
        p({ class = "seo-noticia-titulo" }, self.noticia.titulo)
        div({ class = "seo-score-wrapper" }, function()
          span({ class = "seo-score-num",
                 style = "color:" .. g.cor }, tostring(s.score or 0))
          span({ class = "seo-score-max" }, "/100")
        end)
      end)
      -- Botões de ação
      div({ class = "seo-acoes" }, function()
        a({ href  = "/admin/noticias/" .. self.noticia.id .. "/editar",
            class = "btn-editar" }, "✏️ Editar Notícia")
        a({ href  = "/noticias/" .. self.noticia.id,
            target = "_blank", class = "btn-editar" }, "👁 Ver Pública")
      end)
    end)

    -- Barra de progresso do score
    div({ class = "seo-barra-wrapper" }, function()
      div({ class  = "seo-barra",
            style  = "width:" .. tostring(s.score or 0) .. "%;background:" .. g.cor })
    end)

    -- Checklist
    div({ class = "seo-checks" }, function()
      h3("✅ Checklist")
      for _, check in ipairs(s.checks or {}) do
        div({ class = "seo-check-item" .. (check.ok and " check-ok" or " check-fail") }, function()
          span({ class = "check-ico" }, check.ok and "✅" or "❌")
          span({ class = "check-texto" }, check.texto)
        end)
      end
    end)

    -- Avisos e sugestões
    if s.avisos and #s.avisos > 0 then
      div({ class = "seo-avisos" }, function()
        h3("💡 Sugestões de melhoria")
        ul(function()
          for _, av in ipairs(s.avisos) do
            li({ class = "seo-aviso" }, av)
          end
        end)
      end)
    end

    -- Estatísticas rápidas
    div({ class = "seo-stats" }, function()
      local items = {
        { "📝", "Palavras",      tostring(s.palavras or 0) },
        { "🏷", "Tags",          tostring(s.tags or 0) },
        { "👁", "Views",         tostring(self.noticia.views or 0) },
        { "👍", "Curtidas",      tostring(self.noticia.likes or 0) },
      }
      for _, it in ipairs(items) do
        div({ class = "seo-stat" }, function()
          span({ class = "seo-stat-ico" }, it[1])
          span({ class = "seo-stat-val" }, it[3])
          span({ class = "seo-stat-lab" }, it[2])
        end)
      end
    end)
  end)
end)