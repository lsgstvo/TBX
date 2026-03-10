local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "shadow-card" }, function()
    h2("🏆 Ranking de Jogos Populares")
    table({ class = "ranking-table" }, function()
      thead(function()
        tr(function()
          th("Jogo")
          th("Base de Jogadores")
        end)
      end)
      tbody(function()
        for _, jogo in ipairs(self.jogos or {}) do
          tr(function()
            td(jogo.nome)
            td(jogo.players)
          end)
        end
      end)
    end)
  end)
end)