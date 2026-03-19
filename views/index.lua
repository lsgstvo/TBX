local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  -- Hero
  div({ class = "hero-section shadow-card" }, function()
    h2("Bem-vindo ao TBX!")
    p("Fique por dentro das últimas novidades do mundo dos games.")
  end)

  -- Destaques (só aparece se houver)
  if self.destaques and #self.destaques > 0 then
    section({ class = "shadow-card mt-2 destaque-section" }, function()
      h3("⭐ Em Destaque")
      div({ class = "destaque-grid" }, function()
        for _, n in ipairs(self.destaques) do
          article({ class = "destaque-card" }, function()
            div({ class = "destaque-meta" }, function()
              span({ class = "tag" }, n.categoria)
              if n.jogo and n.jogo ~= "" then
                a({ href = "/jogos/" .. n.jogo, class = "tag tag-jogo" }, n.jogo)
              end
            end)
            h3(function()
              a({ href = "/noticias/" .. n.id }, n.titulo)
            end)
            p({ class = "noticia-resumo" }, n.conteudo:sub(1, 140) .. "...")
            a({ href = "/noticias/" .. n.id, class = "btn-ler-mais" }, "Ler mais →")
          end)
        end
      end)
    end)
  end

  -- Notícias recentes
  section({ class = "news-section shadow-card mt-2" }, function()
    h3("🔥 Notícias Recentes")
    if self.noticias and #self.noticias > 0 then
      ul({ class = "news-list" }, function()
        for _, n in ipairs(self.noticias) do
          li(function()
            a({ href = "/noticias/" .. n.id }, function()
              span({ class = "noticia-titulo" }, n.titulo)
              span({ class = "tag" }, n.categoria)
              if n.jogo and n.jogo ~= "" then
                span({ class = "tag tag-jogo" }, n.jogo)
              end
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