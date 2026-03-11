-- Formulário para criar uma nova notícia

local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    h2("➕ Nova Notícia")

    -- Mensagem de erro de validação
    if self.erro then
      div({ class = "alert alert-erro" }, self.erro)
    end

    form({ method = "POST", action = "/admin/noticias/nova", class = "admin-form" }, function()

      div({ class = "form-group" }, function()
        label({ for = "titulo" }, "Título *")
        input({ type = "text", id = "titulo", name = "titulo",
                placeholder = "Ex: Novo update de Valorant!", required = true })
      end)

      div({ class = "form-group" }, function()
        label({ for = "jogo" }, "Jogo relacionado")
        -- Select com os jogos cadastrados no banco
        select({ id = "jogo", name = "jogo" }, function()
          option({ value = "" }, "— Selecione um jogo —")
          for _, j in ipairs(self.jogos or {}) do
            option({ value = j.nome }, j.nome)
          end
        end)
      end)

      div({ class = "form-group" }, function()
        label({ for = "conteudo" }, "Conteúdo *")
        textarea({ id = "conteudo", name = "conteudo", rows = "8",
                   placeholder = "Escreva o conteúdo completo da notícia...",
                   required = true })
      end)

      div({ class = "form-actions" }, function()
        a({ href = "/admin", class = "btn-cancelar" }, "Cancelar")
        button({ type = "submit", class = "btn-salvar" }, "💾 Salvar Notícia")
      end)
    end)
  end)
end)