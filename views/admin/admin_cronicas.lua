local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    div({ class = "section-header" }, function()
      h2("✍️ Crônicas & Editoriais")
      a({ href = "/admin/cronicas/nova", class = "btn-novo" }, "+ Nova Crônica")
    end)

    if self.cronicas and #self.cronicas > 0 then
      element("table", { class = "admin-table" }, function()
        thead(function()
          tr(function()
            th("Título"); th("Autor"); th("Dest.")
            th("Views"); th("Data"); th("Ações")
          end)
        end)
        tbody(function()
          for _, c in ipairs(self.cronicas) do
            tr(function()
              td({ class = "titulo-col" }, c.titulo)
              td({ class = "data-col" }, c.autor_nome or "—")
              td(c.destaque == 1 and "⭐" or "—")
              td({ class = "views-col" }, "👁 " .. tostring(c.views or 0))
              td({ class = "data-col" }, c.criado_em:sub(1, 10))
              td({ class = "acoes-col" }, function()
                a({ href   = "/cronicas/" .. c.id,
                    target = "_blank",
                    class  = "btn-editar" }, "👁")
                a({ href  = "/admin/cronicas/" .. c.id .. "/editar",
                    class = "btn-editar" }, "✏️")
                form({ method   = "POST",
                       action   = "/admin/cronicas/" .. c.id .. "/deletar",
                       onsubmit = "return confirm('Deletar crônica?')",
                       style    = "display:inline" }, function()
                  button({ type = "submit", class = "btn-deletar" }, "🗑")
                end)
              end)
            end)
          end
        end)
      end)
    else
      p({ class = "sem-dados" }, "Nenhuma crônica cadastrada ainda.")
    end
  end)
end)