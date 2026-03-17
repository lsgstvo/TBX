local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "shadow-card feed-hero" }, function()
    h2("⚡ Meu Feed")
    if self.tem_historico then
      p({ class = "feed-desc" },
        "Notícias selecionadas com base no que você lê. Quanto mais você navega, melhor fica.")
    else
      p({ class = "feed-desc" },
        "Ainda não temos seu histórico. Comece a ler e seu feed vai se personalizar!")
    end
    div({ class = "feed-acoes" }, function()
      a({ href = "/noticias", class = "btn-ver-mais" }, "📰 Ver todas as notícias")
      a({ href = "/perfil",   class = "btn-ver-mais" }, "👤 Meu perfil")
    end)
  end)

  if self.noticias and #self.noticias > 0 then
    div({ class = "shadow-card mt-2" }, function()
      if self.tem_historico then
        h3({ class = "feed-secao-titulo" }, "✨ Recomendado para você")
      else
        h3({ class = "feed-secao-titulo" }, "🔥 Em destaque no portal")
      end
      div({ class = "noticias-grid" }, function()
        for _, n in ipairs(self.noticias) do
          article({ class = "noticia-card" }, function()
            div({ class = "noticia-header" }, function()
              a({ href  = "/noticias?categoria=" .. n.categoria,
                  class = "tag" }, n.categoria)
              if n.jogo and n.jogo ~= "" then
                a({ href  = "/jogos/" .. n.jogo,
                    class = "tag tag-jogo" }, n.jogo)
              end
              span({ class = "data-noticia" }, n.criado_em:sub(1, 10))
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
              if n.tempo_leitura then
                span({ class = "tempo-leitura-badge" },
                  "⏱ " .. tostring(n.tempo_leitura) .. " min")
              end
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
      p({ class = "sem-dados" }, "Nenhuma notícia disponível no momento.")
    end)
  end
end)