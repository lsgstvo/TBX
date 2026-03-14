-- views/index.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  -- Hero
  div({ class = "hero-section shadow-card" }, function()
    h2("Bem-vindo ao Portal Gamer!")
    p("Fique por dentro das últimas novidades do mundo dos games.")
  end)

  -- Destaques
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
            h3(function() a({ href = "/noticias/" .. n.id }, n.titulo) end)
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

  -- ── Widget: Notícias por Jogo ─────────────────────────────────────────────
  if self.jogos_com_noticias and #self.jogos_com_noticias > 0 then
    section({ class = "shadow-card mt-2" }, function()
      h3("🎮 Por Jogo")
      div({ class = "jogos-widget-grid" }, function()
        for _, j in ipairs(self.jogos_com_noticias) do
          div({ class = "jogo-widget-card" }, function()
            -- Cabeçalho do card com nome do jogo
            div({ class = "jogo-widget-header" }, function()
              if j.imagem_url and j.imagem_url ~= "" then
                img({ src   = j.imagem_url,
                      alt   = j.nome,
                      class = "jogo-widget-img" })
              else
                div({ class = "jogo-widget-placeholder" }, j.nome:sub(1,2))
              end
              a({ href  = "/jogos/" .. j.nome,
                  class = "jogo-widget-nome" }, j.nome)
            end)

            -- Lista de notícias do jogo
            if j.noticias and #j.noticias > 0 then
              ul({ class = "jogo-widget-noticias" }, function()
                for _, n in ipairs(j.noticias) do
                  li(function()
                    a({ href = "/noticias/" .. n.id }, function()
                      span({ class = "jwn-titulo" }, n.titulo)
                      span({ class = "jwn-data" },   n.criado_em:sub(1,10))
                    end)
                  end)
                end
              end)
            else
              p({ class = "sem-dados" }, "Sem notícias ainda.")
            end

            a({ href  = "/jogos/" .. j.nome,
                class = "sidebar-ver-mais" },
              "Ver tudo sobre " .. j.nome .. " →")
          end)
        end
      end)
    end)
  end
end)