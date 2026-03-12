-- views/sobre.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  -- Sobre o portal
  div({ class = "shadow-card sobre-hero" }, function()
    h2("🎮 Sobre o Portal Gamer")
    p("O Portal Gamer é um site dedicado às últimas notícias, rankings e atualizações do mundo dos games. Nosso objetivo é manter a comunidade gamer informada com conteúdo de qualidade sobre os jogos mais populares.")
  end)

  -- Cards de info
  div({ class = "sobre-grid mt-2" }, function()
    div({ class = "sobre-card" }, function()
      span({ class = "sobre-icon" }, "📰")
      h3("Notícias")
      p("Cobertura das últimas atualizações, lançamentos e eventos do mundo dos games.")
    end)
    div({ class = "sobre-card" }, function()
      span({ class = "sobre-icon" }, "🏆")
      h3("Rankings")
      p("Acompanhe os jogos mais populares do momento com dados atualizados de base de jogadores.")
    end)
    div({ class = "sobre-card" }, function()
      span({ class = "sobre-icon" }, "💬")
      h3("Comunidade")
      p("Comente nas notícias e participe das discussões com outros jogadores.")
    end)
  end)

  -- Tecnologia
  div({ class = "shadow-card mt-2" }, function()
    h3("⚙️ Tecnologia")
    p("Este portal foi desenvolvido com:")
    ul({ class = "tech-list" }, function()
      li(function()
        span({ class = "tech-badge" }, "Lua")
        span("Linguagem de programação principal")
      end)
      li(function()
        span({ class = "tech-badge" }, "Lapis")
        span("Framework web para OpenResty/Nginx")
      end)
      li(function()
        span({ class = "tech-badge" }, "SQLite")
        span("Banco de dados leve e eficiente")
      end)
      li(function()
        span({ class = "tech-badge" }, "OpenResty")
        span("Servidor Nginx com suporte a Lua")
      end)
    end)
  end)

  -- Contato
  div({ class = "shadow-card mt-2" }, function()
    h3("📬 Contato")
    p({ class = "contato-texto" },
      "Tem sugestões, encontrou algum erro ou quer contribuir com o portal? Entre em contato:")
    div({ class = "contato-links" }, function()
      a({ href  = "https://github.com/tibull",
          class = "contato-btn",
          target = "_blank" }, "🐙 GitHub")
      a({ href = "/rss", class = "contato-btn" }, "📡 RSS Feed")
    end)
  end)
end)