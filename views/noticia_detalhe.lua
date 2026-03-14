-- views/noticia_detalhe.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "detalhe-layout" }, function()

    -- ── Coluna principal ──────────────────────────────────────────────────
    div({ class = "detalhe-main" }, function()

      article({ class = "shadow-card noticia-detalhe" }, function()
        div({ class = "noticia-header" }, function()
          if self.noticia.categoria and self.noticia.categoria ~= "" then
            a({ href = "/noticias?categoria=" .. self.noticia.categoria, class = "tag" },
              self.noticia.categoria)
          end
          if self.noticia.jogo and self.noticia.jogo ~= "" then
            a({ href = "/jogos/" .. self.noticia.jogo, class = "tag tag-jogo" },
              self.noticia.jogo)
          end
          if self.noticia.destaque == 1 then
            span({ class = "badge-destaque" }, "⭐ Destaque")
          end
          span({ class = "data-noticia" }, self.noticia.criado_em:sub(1, 10))
        end)

        h2(self.noticia.titulo)

        -- Imagem de capa (se houver)
        if self.noticia.imagem_url and self.noticia.imagem_url ~= "" then
          div({ class = "noticia-capa" }, function()
            img({ src   = self.noticia.imagem_url,
                  alt   = self.noticia.titulo,
                  class = "noticia-capa-img" })
          end)
        end

        div({ class = "noticia-meta" }, function()
          span({ class = "meta-item" },
            "👁 " .. tostring(self.noticia.views or 0) .. " visualizações")
          span({ class = "meta-sep" }, "·")
          span({ class = "meta-item" },
            "💬 " .. tostring(#(self.comentarios or {})) .. " comentários")
        end)

        div({ class = "noticia-corpo" }, function()
          p(self.noticia.conteudo)
        end)

        -- Tags da notícia
        if self.tags and #self.tags > 0 then
          div({ class = "noticia-tags" }, function()
            span({ class = "tags-label" }, "🏷 Tags:")
            for _, t in ipairs(self.tags) do
              a({ href  = "/tag/" .. t.nome,
                  class = "tag tag-item" }, "#" .. t.nome)
            end
          end)
        end

        div({ class = "noticia-footer" }, function()
          a({ href = "/noticias", class = "btn-voltar" }, "← Voltar para notícias")
        end)
      end)

      -- Notícias relacionadas
      if self.relacionadas and #self.relacionadas > 0 then
        section({ class = "shadow-card mt-2" }, function()
          h3("🔗 Notícias Relacionadas")
          div({ class = "noticias-grid grid-2col" }, function()
            for _, n in ipairs(self.relacionadas) do
              article({ class = "noticia-card" }, function()
                div({ class = "noticia-header" }, function()
                  a({ href = "/noticias?categoria=" .. n.categoria, class = "tag" },
                    n.categoria)
                  if n.jogo and n.jogo ~= "" then
                    a({ href = "/jogos/" .. n.jogo, class = "tag tag-jogo" }, n.jogo)
                  end
                  span({ class = "data-noticia" }, n.criado_em:sub(1, 10))
                end)
                h3(function()
                  a({ href = "/noticias/" .. n.id }, n.titulo)
                end)
                p({ class = "noticia-resumo" }, n.conteudo:sub(1, 100) .. "...")
                a({ href = "/noticias/" .. n.id, class = "btn-ler-mais" }, "Ler mais →")
              end)
            end
          end)
        end)
      end

      -- Comentários
      section({ id = "comentarios", class = "shadow-card mt-2 comentarios-section" }, function()
        h3("💬 Comentários (" .. tostring(#(self.comentarios or {})) .. ")")
        if self.erro_coment then
          div({ class = "alert alert-erro" }, self.erro_coment)
        end
        if self.comentarios and #self.comentarios > 0 then
          div({ class = "comentarios-lista" }, function()
            for _, c in ipairs(self.comentarios) do
              div({ class = "comentario" }, function()
                div({ class = "comentario-header" }, function()
                  span({ class = "comentario-autor" }, c.autor)
                  span({ class = "comentario-data" },  c.criado_em:sub(1, 16))
                end)
                p({ class = "comentario-texto" }, c.conteudo)
              end)
            end
          end)
        else
          p({ class = "sem-dados" }, "Seja o primeiro a comentar!")
        end
        div({ class = "comentario-form-wrapper" }, function()
          h4("Deixe seu comentário")
          form({ method = "POST",
                 action = "/noticias/" .. self.noticia.id .. "/comentar",
                 class  = "comentario-form" }, function()
            div({ class = "form-group" }, function()
              label({ ["for"] = "autor" }, "Nome (opcional)")
              input({ type = "text", id = "autor", name = "autor",
                      placeholder = "Seu nome ou apelido", maxlength = "60" })
            end)
            div({ class = "form-group" }, function()
              label({ ["for"] = "conteudo" }, "Comentário *")
              textarea({ id = "conteudo", name = "conteudo", rows = "4",
                         placeholder = "Escreva seu comentário...",
                         maxlength = "800", required = true })
            end)
            button({ type = "submit", class = "btn-comentar" }, "Enviar comentário →")
          end)
        end)
      end)
    end)

    -- ── Sidebar ───────────────────────────────────────────────────────────
    aside({ class = "detalhe-sidebar" }, function()
      if self.jogos_populares and #self.jogos_populares > 0 then
        div({ class = "sidebar-widget shadow-card" }, function()
          h3("🏆 Jogos Populares")
          ul({ class = "sidebar-jogos" }, function()
            for i, j in ipairs(self.jogos_populares) do
              li(function()
                span({ class = "sj-pos" }, "#" .. i)
                div({ class = "sj-info" }, function()
                  a({ href = "/jogos/" .. j.nome, class = "sj-nome" }, j.nome)
                  span({ class = "sj-genero" }, j.genero)
                end)
              end)
            end
          end)
          a({ href = "/ranking", class = "sidebar-ver-mais" }, "Ver ranking completo →")
        end)
      end
      if self.mais_vistas and #self.mais_vistas > 0 then
        div({ class = "sidebar-widget shadow-card" }, function()
          h3("🔥 Mais Lidas")
          ul({ class = "sidebar-noticias" }, function()
            for _, n in ipairs(self.mais_vistas) do
              if n.id ~= self.noticia.id then
                li(function()
                  a({ href = "/noticias/" .. n.id }, function()
                    span({ class = "sn-titulo" }, n.titulo)
                    span({ class = "sn-views" }, "👁 " .. tostring(n.views or 0))
                  end)
                end)
              end
            end
          end)
        end)
      end
    end)
  end)
end)