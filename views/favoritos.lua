local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "shadow-card" }, function()
    h2("🔖 Meus Favoritos")
    p({ class = "feed-desc" },
      "Notícias que você salvou para ler depois.")
    div({ class = "feed-acoes" }, function()
      span({ class = "stat-badge" },
        tostring(self.total or 0) .. " salvo(s)")
      if (self.total or 0) > 0 then
        form({ method = "POST", action = "/favoritos/limpar",
               onsubmit = "return confirm('Remover todas as notícias dos favoritos?')",
               style = "display:inline" }, function()
          button({ type = "submit", class = "btn-limpar-perfil" }, "🗑 Limpar Tudo")
        end)
      end
      a({ href = "/noticias", class = "btn-ver-mais" }, "📰 Explorar notícias →")
    end)
  end)

  if self.favoritos and #self.favoritos > 0 then
    div({ class = "shadow-card mt-2" }, function()
      div({ class = "noticias-grid" }, function()
        for _, n in ipairs(self.favoritos) do
          article({ class = "noticia-card" }, function()
            div({ class = "noticia-header" }, function()
              a({ href  = "/noticias?categoria=" .. n.categoria,
                  class = "tag" }, n.categoria)
              if n.jogo and n.jogo ~= "" then
                a({ href  = "/jogos/" .. n.jogo,
                    class = "tag tag-jogo" }, n.jogo)
              end
              span({ class = "data-noticia" }, n.criado_em:sub(1, 10))
              button({ class = "btn-remover-favorito", 
                       title = "Remover",
                       onclick = "removerFavorito(" .. n.id .. ", this)" }, "✕")
            end)

            if n.imagem_url and n.imagem_url ~= "" then
              a({ href = "/noticias/" .. n.id }, function()
                img({ src   = n.imagem_url,
                      alt   = n.titulo,
                      class = "noticia-card-img" })
              end)
            end

            h3(function()
              a({ href = "/noticias/" .. n.id }, n.titulo)
            end)

            p({ class = "noticia-resumo" }, n.conteudo:sub(1, 120) .. "...")

            div({ class = "noticia-card-footer" }, function()
              span({ class = "meta-item" },
                "🔖 Salvo em " .. n.favoritado_em:sub(1, 10))
              span({ class = "meta-item" },
                "👁 " .. tostring(n.views or 0))
              a({ href = "/noticias/" .. n.id, class = "btn-ler-mais" }, "Ler →")
            end)
          end)
        end
      end)
    end)
  else
    div({ class = "shadow-card mt-2" }, function()
      p({ class = "sem-dados" },
        "Você ainda não salvou nenhuma notícia.")
      p({ style = "font-size:.85rem;color:var(--text-muted);margin-top:.5rem" },
        "Clique no botão 📌 Salvar em qualquer notícia para adicioná-la aqui.")
      a({ href = "/noticias", class = "btn-ver-mais",
          style = "display:inline-block;margin-top:1rem" },
        "Explorar notícias →")
    end)
  end
end)