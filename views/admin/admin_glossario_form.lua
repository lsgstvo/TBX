local Widget = require("lapis.html").Widget

local CATEGORIAS_GLOSSARIO = {
  "Geral", "FPS", "MOBA", "RPG", "MMO",
  "Estratégia", "Battle Royale", "Hardware", "E-Sports", "Cultura Gamer"
}

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    h2("📖 Novo Termo")
    if self.erro then div({ class = "alert alert-erro" }, self.erro) end

    form({ method = "POST", action = "/admin/glossario/novo",
           class  = "admin-form" }, function()

      div({ class = "form-row" }, function()
        div({ class = "form-group form-grow" }, function()
          label({ ["for"] = "termo" }, "Termo *")
          input({ type = "text", id = "termo", name = "termo",
                  placeholder = "Ex: DPS, Gank, Nerf, GG...",
                  required = true })
        end)
        div({ class = "form-group" }, function()
          label({ ["for"] = "categoria" }, "Categoria")
          element("select", { id = "categoria", name = "categoria" }, function()
            for _, c in ipairs(CATEGORIAS_GLOSSARIO) do
              option({ value = c }, c)
            end
          end)
        end)
      end)

      div({ class = "form-group" }, function()
        label({ ["for"] = "definicao" }, "Definição *")
        textarea({ id = "definicao", name = "definicao", rows = "5",
                   placeholder = "Explique o termo de forma clara e direta...",
                   required = true })
      end)

      div({ class = "form-actions" }, function()
        a({ href = "/admin/glossario", class = "btn-cancelar" }, "Cancelar")
        button({ type = "submit", class = "btn-salvar" }, "💾 Salvar Termo")
      end)
    end)
  end)
end)