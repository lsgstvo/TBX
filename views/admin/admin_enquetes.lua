-- views/admin/admin_enquetes.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    div({ class = "section-header" }, function()
      h2("📊 Enquetes")
      a({ href = "/admin/enquetes/nova", class = "btn-novo" }, "+ Nova Enquete")
    end)
    if self.enquetes and #self.enquetes > 0 then
      element("table", { class = "admin-table" }, function()
        thead(function()
          tr(function()
            th("Pergunta"); th("Notícia"); th("Votos"); th("Status"); th("Criada"); th("Ação")
          end)
        end)
        tbody(function()
          for _, e in ipairs(self.enquetes) do
            tr(function()
              td({ class = "titulo-col" }, e.pergunta)
              td({ class = "data-col" }, function()
                if e.noticia_titulo then
                  a({ href = "/noticias/" .. (e.noticia_id or ""),
                      style = "font-size:.82rem" },
                    e.noticia_titulo:sub(1, 35) .. "...")
                else
                  span({ style = "color:var(--text-muted)" }, "Global")
                end
              end)
              td({ class = "views-col" }, tostring(e.total_votos or 0))
              td(function()
                if e.ativa == 1 then
                  span({ class = "status-aprovado" }, "✅ Ativa")
                else
                  span({ class = "status-pendente" }, "⏸ Inativa")
                end
              end)
              td({ class = "data-col" }, e.criado_em:sub(1, 10))
              td(function()
                form({ method = "POST",
                       action  = "/admin/enquetes/" .. e.id .. "/deletar",
                       onsubmit = "return confirm('Deletar enquete?')" }, function()
                  button({ type = "submit", class = "btn-deletar" }, "🗑")
                end)
              end)
            end)
          end
        end)
      end)
    else
      p({ class = "sem-dados" }, "Nenhuma enquete criada ainda.")
    end
  end)
end)