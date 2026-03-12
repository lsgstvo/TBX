-- views/admin/admin_jogo_editar.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    h2("✏️ Editar Jogo")
    if self.erro then div({ class = "alert alert-erro" }, self.erro) end

    form({ method = "POST",
           action = "/admin/jogos/" .. self.jogo.id .. "/editar",
           class  = "admin-form" }, function()

      div({ class = "form-row" }, function()
        div({ class = "form-group form-grow" }, function()
          label({ ["for"] = "nome" }, "Nome do Jogo *")
          input({ type = "text", id = "nome", name = "nome",
                  value = self.jogo.nome, required = true })
        end)
        div({ class = "form-group" }, function()
          label({ ["for"] = "posicao" }, "Posição no Ranking")
          input({ type = "number", id = "posicao", name = "posicao",
                  value = tostring(self.jogo.posicao), min = "1" })
        end)
      end)

      div({ class = "form-row" }, function()
        div({ class = "form-group form-grow" }, function()
          label({ ["for"] = "genero" }, "Gênero")
          input({ type = "text", id = "genero", name = "genero", value = self.jogo.genero })
        end)
        div({ class = "form-group form-grow" }, function()
          label({ ["for"] = "players" }, "Base de Jogadores *")
          input({ type = "text", id = "players", name = "players",
                  value = self.jogo.players, required = true })
        end)
      end)

      div({ class = "form-group" }, function()
        label({ ["for"] = "imagem_url" }, "URL da Imagem / Capa")
        input({ type = "url", id = "imagem_url", name = "imagem_url",
                value = self.jogo.imagem_url or "" })
      end)

      div({ class = "form-group" }, function()
        label({ ["for"] = "descricao" }, "Descrição")
        textarea({ id = "descricao", name = "descricao", rows = "4" },
                 self.jogo.descricao or "")
      end)

      -- Preview da imagem atual
      if self.jogo.imagem_url and self.jogo.imagem_url ~= "" then
        div({ class = "img-preview" }, function()
          p({ class = "preview-label" }, "Imagem atual:")
          img({ src = self.jogo.imagem_url, alt = self.jogo.nome, class = "preview-img" })
        end)
      end

      div({ class = "form-actions" }, function()
        a({ href = "/admin", class = "btn-cancelar" }, "Cancelar")
        button({ type = "submit", class = "btn-salvar" }, "💾 Salvar Alterações")
      end)
    end)
  end)
end)