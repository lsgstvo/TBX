-- views/mapa.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "shadow-card" }, function()
    h2("🗺 Mapa do Site")
    p({ class = "mapa-desc" },
      "Todas as páginas e seções do Portal Gamer em um só lugar.")
  end)

  div({ class = "mapa-grid mt-2" }, function()

    -- ── Seção Principal ─────────────────────────────────────────────────────
    div({ class = "mapa-secao shadow-card" }, function()
      h3("🏠 Principal")
      ul({ class = "mapa-lista" }, function()
        local paginas = {
          { "/",            "Início",            "Últimas notícias e destaques" },
          { "/noticias",    "Notícias",          "Todas as notícias" },
          { "/ranking",     "Ranking",           "Jogos mais populares" },
          { "/trending",    "Trending",          "Notícias em alta" },
          { "/busca",       "Busca Avançada",    "Filtros combinados" },
          { "/sobre",       "Sobre",             "Sobre o portal" },
          { "/about",       "About",             "Timeline e números" },
          { "/conquistas",  "Conquistas",        "Seus badges de leitor" },
          { "/lancamentos", "Lançamentos",       "Próximos jogos" },
          { "/stats",       "Estatísticas",      "Dados e gráficos" },
          { "/mapa",        "Mapa do Site",      "Esta página" },
          { "/rss",         "RSS Feed",          "Feed de notícias" },
        }
        for _, p in ipairs(paginas) do
          li(function()
            a({ href = p[1], class = "mapa-link" }, function()
              span({ class = "mapa-link-nome" }, p[2])
              span({ class = "mapa-link-desc" }, p[3])
            end)
          end)
        end
      end)
    end)

    -- ── Categorias ──────────────────────────────────────────────────────────
    div({ class = "mapa-secao shadow-card" }, function()
      h3("🗂 Categorias")
      ul({ class = "mapa-lista" }, function()
        for _, c in ipairs(self.categorias or {}) do
          li(function()
            a({ href  = "/noticias?categoria=" .. c.nome,
                class = "mapa-link" }, function()
              span({ class = "tag" }, c.nome)
            end)
          end)
        end
      end)
    end)

    -- ── Jogos ────────────────────────────────────────────────────────────────
    div({ class = "mapa-secao shadow-card" }, function()
      h3("🎮 Jogos no Ranking")
      ul({ class = "mapa-lista" }, function()
        for _, j in ipairs(self.jogos or {}) do
          li(function()
            a({ href = "/jogos/" .. j.nome, class = "mapa-link" }, function()
              span({ class = "mapa-link-nome" },
                "#" .. j.posicao .. " " .. j.nome)
              span({ class = "tag" }, j.genero)
            end)
          end)
        end
      end)
    end)

    -- ── Tags ─────────────────────────────────────────────────────────────────
    if self.tags_pop and #self.tags_pop > 0 then
      div({ class = "mapa-secao shadow-card" }, function()
        h3("🏷 Tags Populares")
        div({ class = "tag-cloud" }, function()
          for _, t in ipairs(self.tags_pop) do
            a({ href  = "/tag/" .. t.nome,
                class = "tag tag-cloud-item" },
              "#" .. t.nome .. " (" .. t.total .. ")")
          end
        end)
      end)
    end

    -- ── Autores ──────────────────────────────────────────────────────────────
    if self.autores and #self.autores > 0 then
      div({ class = "mapa-secao shadow-card" }, function()
        h3("✍️ Autores")
        ul({ class = "mapa-lista" }, function()
          for _, a in ipairs(self.autores) do
            li(function()
              element("a", { href = "/autor/" .. a.id, class = "mapa-link" }, function()
                if a.avatar_url ~= "" then
                  img({ src = a.avatar_url, class = "autor-avatar-mini",
                        alt = a.nome })
                end
                span({ class = "mapa-link-nome" }, a.nome)
              end)
            end)
          end
        end)
      end)
    end

    -- ── Notícias recentes ─────────────────────────────────────────────────────
    div({ class = "mapa-secao mapa-secao-wide shadow-card" }, function()
      h3("📰 Notícias (" .. #(self.noticias or {}) .. " no total)")
      div({ class = "mapa-noticias-grid" }, function()
        for i, n in ipairs(self.noticias or {}) do
          if i > 30 then break end  -- limita para não ficar gigante
          a({ href = "/noticias/" .. n.id, class = "mapa-noticia-item" }, function()
            span({ class = "tag", style = "font-size:.7rem" }, n.categoria)
            span({ class = "mapa-noticia-titulo" }, n.titulo)
            span({ class = "mapa-noticia-data" }, n.criado_em:sub(1, 10))
          end)
        end
        if #(self.noticias or {}) > 30 then
          div({ class = "mapa-mais" }, function()
            a({ href = "/noticias", class = "btn-ver-mais" },
              "+ " .. (#self.noticias - 30) .. " notícias →")
          end)
        end
      end)
    end)

  end)
end)