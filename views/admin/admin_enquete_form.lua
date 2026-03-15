-- views/admin/admin_enquete_form.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    h2("📊 Nova Enquete")
    if self.erro then div({ class = "alert alert-erro" }, self.erro) end

    form({ method = "POST", action = "/admin/enquetes/nova",
           class  = "admin-form" }, function()

      div({ class = "form-group" }, function()
        label({ ["for"] = "pergunta" }, "Pergunta *")
        input({ type = "text", id = "pergunta", name = "pergunta",
                placeholder = "Ex: Qual jogo você mais quer ver no ranking?",
                required = true })
      end)

      div({ class = "form-group" }, function()
        label({ ["for"] = "noticia_id" }, "Notícia relacionada (opcional)")
        element("select", { id = "noticia_id", name = "noticia_id" }, function()
          option({ value = "" }, "— Enquete global (sem notícia) —")
          for _, n in ipairs(self.noticias or {}) do
            option({ value = tostring(n.id) },
              "#" .. n.id .. " — " .. n.titulo:sub(1, 60))
          end
        end)
      end)

      div({ class = "form-group" }, function()
        label({}, "Opções (mínimo 2, máximo 6)")
        for i = 1, 6 do
          div({ class = "opcao-input-wrapper" }, function()
            span({ class = "opcao-num" }, tostring(i) .. ".")
            input({ type        = "text",
                    name        = "opcao_" .. i,
                    placeholder = i <= 2 and "Opção " .. i .. " *" or "Opção " .. i .. " (opcional)",
                    required    = i <= 2 })
          end)
        end
      end)

      div({ class = "form-actions" }, function()
        a({ href = "/admin/enquetes", class = "btn-cancelar" }, "Cancelar")
        button({ type = "submit", class = "btn-salvar" }, "💾 Criar Enquete")
      end)
    end)
  end)
end)