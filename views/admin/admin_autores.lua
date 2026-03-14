-- ════════════════════════════════════════════════════════════════════
-- views/admin/admin_autores.lua
-- ════════════════════════════════════════════════════════════════════
-- (salve como views/admin/admin_autores.lua)

local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    div({ class = "section-header" }, function()
      h2("✍️ Autores")
      a({ href = "/admin/autores/novo", class = "btn-novo" }, "+ Novo Autor")
    end)
    if self.autores and #self.autores > 0 then
      element("table", { class = "admin-table" }, function()
        thead(function()
          tr(function() th("Avatar"); th("Nome"); th("Bio"); th("Ações") end)
        end)
        tbody(function()
          for _, a in ipairs(self.autores) do
            tr(function()
              td(function()
                if a.avatar_url ~= "" then
                  img({ src = a.avatar_url, class = "autor-avatar-mini", alt = a.nome })
                else
                  div({ class = "autor-avatar-placeholder-sm" }, a.nome:sub(1,1):upper())
                end
              end)
              td({ class = "titulo-col" }, a.nome)
              td({ class = "bio-col" },
                a.bio ~= "" and a.bio:sub(1, 60) .. (a.bio:len() > 60 and "..." or "") or "—")
              td({ class = "acoes-col" }, function()
                element("a", { href = "/autor/" .. a.id, class = "btn-editar", target = "_blank" }, "👁")
                element("a", { href = "/admin/autores/" .. a.id .. "/editar", class = "btn-editar" }, "✏️")
                form({ method = "POST", action = "/admin/autores/" .. a.id .. "/deletar",
                       onsubmit = "return confirm('Deletar autor?')", style = "display:inline" }, function()
                  button({ type = "submit", class = "btn-deletar" }, "🗑")
                end)
              end)
            end)
          end
        end)
      end)
    else
      p({ class = "sem-dados" }, "Nenhum autor cadastrado.")
    end
  end)
end)