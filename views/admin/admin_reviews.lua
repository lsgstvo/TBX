local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    div({ class = "section-header" }, function()
      h2("🎮 Reviews & Análises")
      div({ style = "display:flex;gap:.5rem" }, function()
        a({ href = "/reviews", target = "_blank", class = "btn-editar" }, "👁 Ver público")
        a({ href = "/admin/reviews/novo", class = "btn-novo" }, "+ Nova Review")
      end)
    end)
    if self.reviews and #self.reviews > 0 then
      element("table", { class = "admin-table" }, function()
        thead(function()
          tr(function()
            th("Jogo"); th("Título"); th("Nota"); th("Dest."); th("Views"); th("Data"); th("Ações")
          end)
        end)
        tbody(function()
          for _, r in ipairs(self.reviews) do
            local nota = tonumber(r.nota_geral) or 0
            local cor  = nota >= 8 and "color:#4ade80" or nota >= 6 and "color:var(--gold-color)" or "color:#f43f5e"
            tr(function()
              td(function() span({ class = "tag tag-jogo" }, r.jogo_nome) end)
              td({ class = "titulo-col" }, r.titulo)
              td({ style = cor .. ";font-weight:800;font-size:1.1rem" },
                string.format("%.1f", nota))
              td(r.destaque == 1 and "⭐" or "—")
              td({ class = "views-col" }, "👁 " .. tostring(r.views or 0))
              td({ class = "data-col" }, r.criado_em:sub(1,10))
              td({ class = "acoes-col" }, function()
                a({ href  = "/reviews/" .. r.id, target = "_blank",
                    class = "btn-editar" }, "👁")
                a({ href  = "/admin/reviews/" .. r.id .. "/editar",
                    class = "btn-editar" }, "✏️")
                form({ method   = "POST",
                       action   = "/admin/reviews/" .. r.id .. "/deletar",
                       onsubmit = "return confirm('Deletar review?')",
                       style    = "display:inline" }, function()
                  button({ type = "submit", class = "btn-deletar" }, "🗑")
                end)
              end)
            end)
          end
        end)
      end)
    else
      p({ class = "sem-dados" }, "Nenhuma review cadastrada ainda.")
    end
  end)
end)