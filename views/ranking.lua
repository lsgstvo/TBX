-- views/ranking.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "shadow-card" }, function()
    h2("🏆 Ranking de Jogos Populares")

    if self.jogos and #self.jogos > 0 then
      element("table", { class = "ranking-table" }, function()
        thead(function()
          tr(function()
            th("#")
            th("Jogo")
            th("Gênero")
            th("Base de Jogadores")
          end)
        end)
        tbody(function()
          for _, jogo in ipairs(self.jogos) do
            tr(function()
              td({ class = "posicao" }, tostring(jogo.posicao))
              td({ class = "nome-jogo" }, function()
                -- Link para a página de detalhe do jogo
                a({ href = "/jogos/" .. jogo.nome }, jogo.nome)
              end)
              td({ class = "genero" }, jogo.genero)
              td(jogo.players)
            end)
          end
        end)
      end)
    else
      p({ class = "sem-dados" }, "Nenhum jogo cadastrado ainda.")
    end
  end)
end)