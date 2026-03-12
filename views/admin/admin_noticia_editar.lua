-- views/admin/admin_noticia_editar.lua
-- Formulário para editar uma notícia existente

local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    h2("✏️ Editar Notícia")

    if self.erro then
      div({ class = "alert alert-erro" }, self.erro)
    end

    form({ method = "POST", action = "/admin/noticias/" .. self.noticia.id .. "/editar", class = "admin-form" }, function()

      div({ class = "form-group" }, function()
        label({ ["for"] = "titulo" }, "Título *")
        input({ type = "text", id = "titulo", name = "titulo",
                value = self.noticia.titulo, required = true })
      end)

      div({ class = "form-group" }, function()
        label({ ["for"] = "jogo" }, "Jogo relacionado")
        element("select", { id = "jogo", name = "jogo" }, function()
          option({ value = "" }, "— Selecione um jogo —")
          for _, j in ipairs(self.jogos or {}) do
            local attrs = { value = j.nome }
            -- Marca o jogo atual como selecionado
            if j.nome == self.noticia.jogo then
              attrs.selected = "selected"
            end
            option(attrs, j.nome)
          end
        end)
      end)

      div({ class = "form-group" }, function()
        label({ ["for"] = "conteudo" }, "Conteúdo *")
        textarea({ id = "conteudo", name = "conteudo", rows = "8", required = true },
          self.noticia.conteudo)
      end)

      div({ class = "form-actions" }, function()
        a({ href = "/admin", class = "btn-cancelar" }, "Cancelar")
        button({ type = "submit", class = "btn-salvar" }, "💾 Salvar Alterações")
      end)
    end)
  end)
end)