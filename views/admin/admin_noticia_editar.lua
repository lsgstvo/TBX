-- views/admin/admin_noticia_editar.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    h2("✏️ Editar Notícia")
    if self.erro then div({ class = "alert alert-erro" }, self.erro) end

    form({ method = "POST",
           action = "/admin/noticias/" .. self.noticia.id .. "/editar",
           class  = "admin-form" }, function()

      div({ class = "form-group" }, function()
        label({ ["for"] = "titulo" }, "Título *")
        input({ type = "text", id = "titulo", name = "titulo",
                value = self.noticia.titulo, required = true })
      end)

      div({ class = "form-row" }, function()
        div({ class = "form-group" }, function()
          label({ ["for"] = "jogo" }, "Jogo relacionado")
          element("select", { id = "jogo", name = "jogo" }, function()
            option({ value = "" }, "— Selecione —")
            for _, j in ipairs(self.jogos or {}) do
              local attrs = { value = j.nome }
              if j.nome == self.noticia.jogo then attrs.selected = true end
              option(attrs, j.nome)
            end
          end)
        end)
        div({ class = "form-group" }, function()
          label({ ["for"] = "categoria" }, "Categoria")
          element("select", { id = "categoria", name = "categoria" }, function()
            for _, c in ipairs(self.categorias or {}) do
              local attrs = { value = c.nome }
              if c.nome == self.noticia.categoria then attrs.selected = true end
              option(attrs, c.nome)
            end
          end)
        end)
      end)

      div({ class = "form-group" }, function()
        label({ ["for"] = "conteudo" }, "Conteúdo *")
        textarea({ id = "conteudo", name = "conteudo", rows = "10", required = true },
                 self.noticia.conteudo)
      end)

      div({ class = "form-check" }, function()
        local attrs = { type = "checkbox", id = "destaque", name = "destaque", value = "1" }
        if self.noticia.destaque == 1 then attrs.checked = true end
        input(attrs)
        label({ ["for"] = "destaque" }, "⭐ Marcar como destaque na home")
      end)

      div({ class = "form-actions" }, function()
        a({ href = "/admin", class = "btn-cancelar" }, "Cancelar")
        button({ type = "submit", class = "btn-salvar" }, "💾 Salvar Alterações")
      end)
    end)
  end)
end)