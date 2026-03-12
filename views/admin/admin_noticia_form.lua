-- views/admin/admin_noticia_form.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    h2("➕ Nova Notícia")
    if self.erro then div({ class = "alert alert-erro" }, self.erro) end

    form({ method = "POST", action = "/admin/noticias/nova", class = "admin-form" }, function()

      div({ class = "form-row" }, function()
        div({ class = "form-group form-grow" }, function()
          label({ ["for"] = "titulo" }, "Título *")
          input({ type = "text", id = "titulo", name = "titulo",
                  placeholder = "Ex: Novo update de Valorant!", required = true })
        end)
      end)

      div({ class = "form-row" }, function()
        div({ class = "form-group" }, function()
          label({ ["for"] = "jogo" }, "Jogo relacionado")
          element("select", { id = "jogo", name = "jogo" }, function()
            option({ value = "" }, "— Selecione —")
            for _, j in ipairs(self.jogos or {}) do
              option({ value = j.nome }, j.nome)
            end
          end)
        end)
        div({ class = "form-group" }, function()
          label({ ["for"] = "categoria" }, "Categoria")
          element("select", { id = "categoria", name = "categoria" }, function()
            for _, c in ipairs(self.categorias or {}) do
              option({ value = c.nome }, c.nome)
            end
          end)
        end)
      end)

      div({ class = "form-group" }, function()
        label({ ["for"] = "conteudo" }, "Conteúdo *")
        textarea({ id = "conteudo", name = "conteudo", rows = "8",
                   placeholder = "Escreva o conteúdo completo...", required = true })
      end)

      div({ class = "form-check" }, function()
        input({ type = "checkbox", id = "destaque", name = "destaque", value = "1" })
        label({ ["for"] = "destaque" }, "⭐ Marcar como destaque na home")
      end)

      div({ class = "form-actions" }, function()
        a({ href = "/admin", class = "btn-cancelar" }, "Cancelar")
        button({ type = "submit", class = "btn-salvar" }, "💾 Salvar Notícia")
      end)
    end)
  end)
end)