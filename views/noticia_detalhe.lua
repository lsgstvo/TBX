-- views/noticia_detalhe.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  article({ class = "shadow-card noticia-detalhe" }, function()
    -- Cabeçalho
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

    -- Meta: views e comentários
    div({ class = "noticia-meta" }, function()
      span({ class = "meta-item" }, "👁 " .. tostring(self.noticia.views or 0) .. " visualizações")
      span({ class = "meta-sep" }, "·")
      span({ class = "meta-item" }, "💬 " .. tostring(#(self.comentarios or {})) .. " comentários")
    end)

    div({ class = "noticia-corpo" }, function()
      p(self.noticia.conteudo)
    end)

    div({ class = "noticia-footer" }, function()
      a({ href = "/noticias", class = "btn-voltar" }, "← Voltar para notícias")
    end)
  end)

  -- ── Seção de comentários ────────────────────────────────────────────────
  section({ id = "comentarios", class = "shadow-card mt-2 comentarios-section" }, function()
    h3("💬 Comentários (" .. tostring(#(self.comentarios or {})) .. ")")

    -- Mensagem de erro
    if self.erro_coment then
      div({ class = "alert alert-erro" }, self.erro_coment)
    end

    -- Lista de comentários
    if self.comentarios and #self.comentarios > 0 then
      div({ class = "comentarios-lista" }, function()
        for _, c in ipairs(self.comentarios) do
          div({ class = "comentario" }, function()
            div({ class = "comentario-header" }, function()
              span({ class = "comentario-autor" }, c.autor)
              span({ class = "comentario-data" }, c.criado_em:sub(1, 16))
            end)
            p({ class = "comentario-texto" }, c.conteudo)
          end)
        end
      end)
    else
      p({ class = "sem-dados" }, "Seja o primeiro a comentar!")
    end

    -- Formulário de comentário
    div({ class = "comentario-form-wrapper" }, function()
      h4("Deixe seu comentário")
      form({ method  = "POST",
             action  = "/noticias/" .. self.noticia.id .. "/comentar",
             class   = "comentario-form" }, function()
        div({ class = "form-group" }, function()
          label({ ["for"] = "autor" }, "Nome (opcional)")
          input({ type        = "text",
                  id          = "autor",
                  name        = "autor",
                  placeholder = "Seu nome ou apelido",
                  maxlength   = "60" })
        end)
        div({ class = "form-group" }, function()
          label({ ["for"] = "conteudo" }, "Comentário *")
          textarea({ id          = "conteudo",
                     name        = "conteudo",
                     rows        = "4",
                     placeholder = "Escreva seu comentário...",
                     maxlength   = "800",
                     required    = true })
        end)
        button({ type = "submit", class = "btn-comentar" }, "Enviar comentário →")
      end)
    end)
  end)
end)