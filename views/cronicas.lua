local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "shadow-card cronicas-hero" }, function()
    h2("✍️ Crônicas & Editoriais")
    p({ class = "cronicas-desc" },
      "Análises aprofundadas, opiniões e reflexões sobre o universo dos games.")
  end)

  if self.cronicas and #self.cronicas > 0 then
    div({ class = "cronicas-grid mt-2" }, function()
      for i, c in ipairs(self.cronicas) do
        local cls = (i == 1 or c.destaque == 1)
          and "cronica-card cronica-destaque" or "cronica-card"
        article({ class = cls }, function()
          if c.imagem_url ~= "" then
            a({ href = "/cronicas/" .. c.id }, function()
              img({ src = c.imagem_url, alt = c.titulo, class = "cronica-capa" })
            end)
          end
          div({ class = "cronica-corpo" }, function()
            div({ class = "cronica-meta" }, function()
              span({ class = "cronica-tipo" }, "✍️ Editorial")
              if c.destaque == 1 then
                span({ class = "badge-destaque" }, "⭐ Destaque")
              end
              span({ class = "data-noticia" }, c.criado_em:sub(1, 10))
            end)
            h2(function()
              a({ href = "/cronicas/" .. c.id, class = "cronica-titulo" }, c.titulo)
            end)
            if c.subtitulo and c.subtitulo ~= "" then
              p({ class = "cronica-subtitulo" }, c.subtitulo)
            end
            if c.autor_nome and c.autor_nome ~= "" then
              div({ class = "noticia-autor-mini" }, function()
                if c.autor_avatar and c.autor_avatar ~= "" then
                  img({ src = c.autor_avatar, alt = c.autor_nome,
                        class = "autor-avatar-mini" })
                end
                a({ href = "/autor/" .. (c.autor_id or ""),
                    class = "autor-mini-nome" }, c.autor_nome)
              end)
            end
            div({ class = "cronica-footer" }, function()
              p({ class = "noticia-resumo" }, c.conteudo:sub(1, 180) .. "...")
              div({ class = "cronica-footer-meta" }, function()
                local palavras = 0
                for _ in c.conteudo:gmatch("%S+") do palavras = palavras + 1 end
                local mins = math.max(1, math.ceil(palavras / 200))
                span({ class = "tempo-leitura-badge" },
                  "⏱ " .. tostring(mins) .. " min")
                a({ href = "/cronicas/" .. c.id, class = "btn-ler-mais" },
                  "Ler crônica →")
              end)
            end)
          end)
        end)
      end
    end)
  else
    div({ class = "shadow-card mt-2" }, function()
      p({ class = "sem-dados" }, "Nenhuma crônica publicada ainda.")
    end)
  end
end)