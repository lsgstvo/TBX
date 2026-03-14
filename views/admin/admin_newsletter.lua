-- views/admin/admin_newsletter.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    div({ class = "section-header" }, function()
      h2("📧 Newsletter")
      span({ class = "stat-badge" },
        tostring(self.total or 0) .. " inscritos")
    end)

    if self.inscritos and #self.inscritos > 0 then
      element("table", { class = "admin-table" }, function()
        thead(function()
          tr(function()
            th("E-mail"); th("Cadastrado em"); th("Token"); th("Ação")
          end)
        end)
        tbody(function()
          for _, s in ipairs(self.inscritos) do
            tr(function()
              td({ class = "titulo-col" }, s.email)
              td({ class = "data-col" },   s.criado_em:sub(1, 10))
              td({ class = "data-col",
                   style = "font-size:.75rem;color:var(--text-muted);font-family:monospace" },
                 s.token)
              td(function()
                form({ method = "POST",
                       action  = "/admin/newsletter/" .. s.id .. "/deletar",
                       onsubmit = "return confirm('Remover inscrito?')" }, function()
                  button({ type = "submit", class = "btn-deletar" }, "🗑")
                end)
              end)
            end)
          end
        end)
      end)
    else
      p({ class = "sem-dados" }, "Nenhum inscrito ainda.")
    end
  end)
end)