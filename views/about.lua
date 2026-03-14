-- views/about.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  local d = self.dados or {}
  local t = d.totais   or {}

  -- Hero
  div({ class = "shadow-card about-hero" }, function()
    div({ class = "about-brand" }, function()
      span({ class = "about-logo" }, "🎮")
      div(function()
        h2("Portal Gamer")
        p({ class = "about-tagline" },
          "O seu portal de notícias, rankings e análises do mundo dos games.")
      end)
    end)
    if d.primeira then
      p({ class = "about-nascimento" }, function()
        raw("✨ Online desde ")
        strong(d.primeira.criado_em:sub(1, 10))
      end)
    end
  end)

  -- Cards de números
  div({ class = "shadow-card mt-2" }, function()
    h3("📊 Portal em Números")
    div({ class = "about-numeros" }, function()
      local nums = {
        { t.noticias   or 0, "Notícias publicadas", "📰" },
        { t.jogos      or 0, "Jogos no ranking",    "🎮" },
        { t.autores    or 0, "Autores",              "✍️"  },
        { t.comentarios or 0, "Comentários",         "💬" },
        { t.curtidas   or 0, "Curtidas recebidas",  "👍" },
        { t.inscritos  or 0, "Inscritos newsletter","📧" },
      }
      for _, n in ipairs(nums) do
        div({ class = "about-num-card" }, function()
          span({ class = "about-num-ico" }, n[3])
          span({ class = "about-num-val" }, tostring(n[1]))
          span({ class = "about-num-lab" }, n[2])
        end)
      end
    end)
  end)

  -- Notícia mais popular
  if d.mais_popular then
    div({ class = "shadow-card mt-2" }, function()
      h3("🏆 Notícia Mais Popular de Todos os Tempos")
      div({ class = "mais-vista-card" }, function()
        a({ href  = "/noticias/" .. d.mais_popular.id,
            class = "mais-vista-titulo" }, d.mais_popular.titulo)
        div({ style = "display:flex;gap:.8rem;align-items:center" }, function()
          span({ class = "mais-vista-views" },
            "👁 " .. tostring(d.mais_popular.views) .. " visualizações")
          span({ class = "mais-vista-views" },
            "👍 " .. tostring(d.mais_popular.likes or 0) .. " curtidas")
        end)
      end)
    end)
  end

  -- Timeline
  div({ class = "shadow-card mt-2" }, function()
    h3("📅 Timeline do Portal")
    div({ class = "about-timeline" }, function()

      -- Marco: criação
      if d.primeira then
        div({ class = "timeline-item" }, function()
          div({ class = "timeline-dot timeline-dot-primary" })
          div({ class = "timeline-content" }, function()
            span({ class = "timeline-data" }, d.primeira.criado_em:sub(1, 7))
            p({ class  = "timeline-titulo" }, "🚀 Portal Gamer no ar!")
            p({ class  = "timeline-desc" },
              "Primeira notícia publicada. Começo de uma jornada no mundo dos games.")
          end)
        end)
      end

      -- Marcos dos meses mais ativos
      for i, m in ipairs(d.por_mes or {}) do
        div({ class = "timeline-item" }, function()
          div({ class = "timeline-dot timeline-dot-gold" })
          div({ class = "timeline-content" }, function()
            span({ class = "timeline-data" }, m.mes)
            p({ class = "timeline-titulo" },
              (i == 1 and "🔥 Mês recorde!" or "📈 Mês forte"))
            p({ class = "timeline-desc" },
              tostring(m.total) .. " notícias publicadas neste mês.")
          end)
        end)
      end

      -- Marco: jogos mais cobertos
      if d.top_jogos and #d.top_jogos > 0 then
        div({ class = "timeline-item" }, function()
          div({ class = "timeline-dot timeline-dot-purple" })
          div({ class = "timeline-content" }, function()
            span({ class = "timeline-data" }, "Destaque")
            p({ class = "timeline-titulo" }, "🎮 Jogos mais cobertos")
            div({ class = "timeline-tags" }, function()
              for _, j in ipairs(d.top_jogos) do
                a({ href  = "/jogos/" .. j.jogo,
                    class = "tag tag-jogo" },
                  j.jogo .. " (" .. j.total .. ")")
              end
            end)
          end)
        end)
      end

    end)
  end)

  -- Equipe / Autores
  if d.top_autores and #d.top_autores > 0 then
    div({ class = "shadow-card mt-2" }, function()
      h3("✍️ Nossa Equipe")
      div({ class = "about-autores" }, function()
        for _, a in ipairs(d.top_autores) do
          div({ class = "about-autor-card" }, function()
            if a.avatar_url and a.avatar_url ~= "" then
              img({ src = a.avatar_url, alt = a.nome,
                    class = "autor-avatar" })
            else
              div({ class = "autor-avatar-placeholder" },
                a.nome:sub(1,1):upper())
            end
            p({ class = "about-autor-nome" }, a.nome)
            p({ class = "about-autor-total" },
              tostring(a.total) .. " notícias")
          end)
        end
      end)
    end)
  end

  -- Stack tecnológico
  div({ class = "shadow-card mt-2" }, function()
    h3("⚙️ Feito com")
    div({ class = "about-stack" }, function()
      local stack = {
        { "Lua",        "Linguagem principal" },
        { "Lapis",      "Framework web"       },
        { "SQLite",     "Banco de dados"      },
        { "OpenResty",  "Servidor Nginx+Lua"  },
        { "Vanilla JS", "Frontend leve"       },
      }
      for _, s in ipairs(stack) do
        div({ class = "stack-badge" }, function()
          span({ class = "tech-badge" }, s[1])
          span({ class = "stack-desc" }, s[2])
        end)
      end
    end)
  end)
end)