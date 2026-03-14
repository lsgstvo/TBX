-- views/admin/admin_autor_editar.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    h2("✏️ Editar Autor")
    if self.erro then div({ class = "alert alert-erro" }, self.erro) end
    form({ method = "POST",
           action = "/admin/autores/" .. self.autor.id .. "/editar",
           class  = "admin-form" }, function()
      div({ class = "form-group" }, function()
        label({ ["for"] = "nome" }, "Nome *")
        input({ type = "text", id = "nome", name = "nome",
                value = self.autor.nome, required = true })
      end)
      div({ class = "form-group" }, function()
        label({ ["for"] = "avatar_url" }, "URL do Avatar")
        input({ type = "url", id = "avatar_url", name = "avatar_url",
                value = self.autor.avatar_url or "" })
        if self.autor.avatar_url and self.autor.avatar_url ~= "" then
          div({ class = "img-preview", style = "margin-top:.5rem" }, function()
            img({ src   = self.autor.avatar_url,
                  alt   = self.autor.nome,
                  class = "autor-avatar",
                  style = "width:60px;height:60px;border-radius:50%;object-fit:cover" })
          end)
        end
      end)
      div({ class = "form-group" }, function()
        label({ ["for"] = "bio" }, "Bio")
        textarea({ id = "bio", name = "bio", rows = "3" }, self.autor.bio or "")
      end)
      div({ class = "form-actions" }, function()
        a({ href = "/admin/autores", class = "btn-cancelar" }, "Cancelar")
        button({ type = "submit", class = "btn-salvar" }, "💾 Salvar Alterações")
      end)
    end)
  end)
end)