-- views/admin/admin_jogo_form.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    h2("🎮 Novo Jogo")
    if self.erro then div({ class = "alert alert-erro" }, self.erro) end

    form({ method = "POST", action = "/admin/jogos/novo", class = "admin-form" }, function()

      div({ class = "form-row" }, function()
        div({ class = "form-group form-grow" }, function()
          label({ ["for"] = "nome" }, "Nome do Jogo *")
          input({ type = "text", id = "nome", name = "nome",
                  placeholder = "Ex: Elden Ring", required = true })
        end)
        div({ class = "form-group" }, function()
          label({ ["for"] = "posicao" }, "Posição no Ranking")
          input({ type = "number", id = "posicao", name = "posicao",
                  placeholder = "Ex: 6", min = "1" })
        end)
      end)

      div({ class = "form-row" }, function()
        div({ class = "form-group form-grow" }, function()
          label({ ["for"] = "genero" }, "Gênero")
          input({ type = "text", id = "genero", name = "genero",
                  placeholder = "Ex: RPG de Ação" })
        end)
        div({ class = "form-group form-grow" }, function()
          label({ ["for"] = "players" }, "Base de Jogadores *")
          input({ type = "text", id = "players", name = "players",
                  placeholder = "Ex: 12 milhões reg.", required = true })
        end)
      end)

      div({ class = "form-group" }, function()
        label({ ["for"] = "imagem_url" }, "URL da Imagem / Capa")
        input({ type = "url", id = "imagem_url", name = "imagem_url",
                placeholder = "https://exemplo.com/imagem.jpg" })
      end)

      div({ class = "form-group" }, function()
        label({ ["for"] = "descricao" }, "Descrição")
        textarea({ id = "descricao", name = "descricao", rows = "4",
                   placeholder = "Breve descrição do jogo..." })
      end)

      div({ class = "form-actions" }, function()
        a({ href = "/admin", class = "btn-cancelar" }, "Cancelar")
        button({ type = "submit", class = "btn-salvar" }, "💾 Salvar Jogo")
      end)
    end)
  end)
end)