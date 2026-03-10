local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "hero-section shadow-card" }, function()
    h2("Bem-vindo ao Portal Gamer!")
    p("Fique por dentro das últimas novidades do mundo dos games.")
  end)

  section({ class = "news-section shadow-card mt-2" }, function()
    h3("🔥 Notícias Recentes")
    ul({ class = "news-list" }, function()
      li("Novo update de Valorant lançado!")
      li("League of Legends anuncia novo campeão.")
      li("CS2 bate recorde de jogadores.")
    end)
  end)
end)