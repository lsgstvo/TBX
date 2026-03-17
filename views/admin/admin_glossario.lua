local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    div({ class = "section-header" }, function()
      h2("📖 Glossário Gamer")
      div({ style = "display:flex;gap:.5rem" }, function()
        a({ href = "/glossario", target = "_blank",
            class = "btn-editar" }, "👁 Ver público")
        a({ href = "/admin/glossario/novo", class = "btn-novo" }, "+ Novo Termo")
      end)
    end)

    if self.termos and #self.termos > 0 then
      element("table", { class = "admin-table" }, function()
        thead(function()
          tr(function()
            th("Termo"); th("Categoria"); th("Definição"); th("Ações")
          end)
        end)
        tbody(function()
          for _, t in ipairs(self.termos) do
            tr(function()
              td({ class = "titulo-col", style = "font-weight:700" }, t.termo)
              td(function() span({ class = "tag" }, t.categoria) end)
              td({ class = "log-detalhe" },
                t.definicao:sub(1, 80) .. (t.definicao:len() > 80 and "..." or ""))
              td({ class = "acoes-col" }, function()
                a({ href  = "/admin/glossario/" .. t.id .. "/editar",
                    class = "btn-editar" }, "✏️")
                form({ method   = "POST",
                       action   = "/admin/glossario/" .. t.id .. "/deletar",
                       onsubmit = "return confirm('Deletar este termo?')",
                       style    = "display:inline" }, function()
                  button({ type = "submit", class = "btn-deletar" }, "🗑")
                end)
              end)
            end)
          end
        end)
      end)
    else
      p({ class = "sem-dados" }, "Nenhum termo cadastrado ainda.")
    end
  end)
end)