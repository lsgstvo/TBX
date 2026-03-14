-- ════════════════════════════════════════════════════════════════════
-- views/admin/admin_autor_form.lua  (novo autor)
-- ════════════════════════════════════════════════════════════════════
local Widget = require("lapis.html").Widget

-- SALVE ESTE BLOCO COMO: views/admin/admin_autor_form.lua
local AutorForm = Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    h2("✍️ Novo Autor")
    if self.erro then div({ class = "alert alert-erro" }, self.erro) end
    form({ method = "POST", action = "/admin/autores/novo", class = "admin-form" }, function()
      div({ class = "form-group" }, function()
        label({ ["for"] = "nome" }, "Nome *")
        input({ type = "text", id = "nome", name = "nome",
                placeholder = "Ex: João Silva", required = true })
      end)
      div({ class = "form-group" }, function()
        label({ ["for"] = "avatar_url" }, "URL do Avatar")
        input({ type = "url", id = "avatar_url", name = "avatar_url",
                placeholder = "https://exemplo.com/foto.jpg" })
      end)
      div({ class = "form-group" }, function()
        label({ ["for"] = "bio" }, "Bio")
        textarea({ id = "bio", name = "bio", rows = "3",
                   placeholder = "Breve descrição do autor..." })
      end)
      div({ class = "form-actions" }, function()
        a({ href = "/admin/autores", class = "btn-cancelar" }, "Cancelar")
        button({ type = "submit", class = "btn-salvar" }, "💾 Salvar Autor")
      end)
    end)
  end)
end)

return AutorForm