-- Página principal — exibe as notícias recentes vindas do banco de dados

local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "hero-section shadow-card" }, function()
    h2("Bem-vindo ao Portal Gamer!")
    p("Fique por dentro das últimas novidades do mundo dos games.")
  end)

  section({ class = "news-section shadow-card mt-2" }, function()
    h3("🔥 Notícias Recentes")

    if self.noticias and #self.noticias > 0 then
      ul({ class = "news-list" }, function()
        for _, noticia in ipairs(self.noticias) do
          li(function()
            -- Link para a página de detalhe da notícia
            a({ href = "/noticias/" .. noticia.id }, function()
              span({ class = "noticia-titulo" }, noticia.titulo)
              span({ class = "noticia-jogo tag" }, noticia.jogo)
            end)
          end)
        end
      end)
    else
      p({ class = "sem-dados" }, "Nenhuma notícia disponível no momento.")
    end

    div({ class = "ver-mais" }, function()
      a({ href = "/noticias", class = "btn-ver-mais" }, "Ver todas as notícias →")
    end)
  end)
end)