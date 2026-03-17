local Widget = require("lapis.html").Widget

local CATEGORIAS_GLOSSARIO = {
  "Geral", "FPS", "MOBA", "RPG", "MMO",
  "Estratégia", "Battle Royale", "Hardware", "E-Sports", "Cultura Gamer"
}

return Widget:extend(function(self)
  local t = self.termo or {}
  div({ class = "admin-section shadow-card" }, function()
    h2("✏️ Editar Termo")
    if self.erro then div({ class = "alert alert-erro" }, self.erro) end

    form({ method = "POST",
           action  = "/admin/glossario/" .. t.id .. "/editar",
           class   = "admin-form" }, function()

      div({ class = "form-row" }, function()
        div({ class = "form-group form-grow" }, function()
          label({ ["for"] = "termo" }, "Termo *")
          input({ type = "text", id = "termo", name = "termo",
                  value = t.termo or "", required = true })
        end)
        div({ class = "form-group" }, function()
          label({ ["for"] = "categoria" }, "Categoria")
          element("select", { id = "categoria", name = "categoria" }, function()
            for _, c in ipairs(CATEGORIAS_GLOSSARIO) do
              local attrs = { value = c }
              if c == t.categoria then attrs.selected = true end
              option(attrs, c)
            end
          end)
        end)
      end)

      div({ class = "form-group" }, function()
        label({ ["for"] = "definicao" }, "Definição *")
        textarea({ id = "definicao", name = "definicao",
                   rows = "5", required = true },
                 t.definicao or "")
      end)

      div({ class = "form-actions" }, function()
        a({ href = "/admin/glossario", class = "btn-cancelar" }, "Cancelar")
        button({ type = "submit", class = "btn-salvar" }, "💾 Salvar Alterações")
      end)
    end)
  end)
end)