-- views/autor.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  -- Card do autor
  div({ class = "shadow-card autor-perfil" }, function()
    div({ class = "autor-header" }, function()
      if self.autor.avatar_url and self.autor.avatar_url ~= "" then
        img({ src   = self.autor.avatar_url,
              alt   = self.autor.nome,
              class = "autor-avatar" })
      else
        div({ class = "autor-avatar-placeholder" }, self.autor.nome:sub(1, 1):upper())
      end
      div({ class = "autor-info" }, function()
        h2(self.autor.nome)
        if self.autor.bio and self.autor.bio ~= "" then
          p({ class = "autor-bio" }, self.autor.bio)
        end
        span({ class = "autor-total" },
          tostring(#(self.noticias or {})) .. " notícias publicadas")
      end)
    end)
  end)

  -- Notícias do autor
  div({ class = "shadow-card mt-2" }, function()
    h3("📰 Notícias de " .. self.autor.nome)
    if self.noticias and #self.noticias > 0 then
      div({ class = "noticias-grid" }, function()
        for _, n in ipairs(self.noticias) do
          article({ class = "noticia-card" .. (n.destaque == 1 and " card-destaque" or "") }, function()
            div({ class = "noticia-header" }, function()
              a({ href = "/noticias?categoria=" .. n.categoria, class = "tag" }, n.categoria)
              if n.jogo and n.jogo ~= "" then
                a({ href = "/jogos/" .. n.jogo, class = "tag tag-jogo" }, n.jogo)
              end
              span({ class = "data-noticia" }, n.criado_em:sub(1, 10))
            end)
            h3(function() a({ href = "/noticias/" .. n.id }, n.titulo) end)
            p({ class = "noticia-resumo" }, n.conteudo:sub(1, 120) .. "...")
            a({ href = "/noticias/" .. n.id, class = "btn-ler-mais" }, "Ler mais →")
          end)
        end
      end)
    else
      p({ class = "sem-dados" }, "Nenhuma notícia publicada ainda.")
    end
  end)
end)