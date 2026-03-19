local Widget = require("lapis.html").Widget

-- Função para renderizar estrelas (0-10)
local function estrelas(nota)
  nota = tonumber(nota) or 0
  local cheia  = math.floor(nota / 2)
  local meia   = (nota % 2) >= 1 and 1 or 0
  local vazia  = 5 - cheia - meia
  return string.rep("★", cheia) .. string.rep("✦", meia) .. string.rep("☆", vazia)
end

return Widget:extend(function(self)
  div({ class = "shadow-card reviews-hero" }, function()
    h2("🎮 Reviews & Análises")
    p({ class = "reviews-desc" },
      "Análises editoriais aprofundadas — gameplay, gráficos, história e muito mais.")
  end)

  if self.reviews and #self.reviews > 0 then
    div({ class = "reviews-grid mt-2" }, function()
      for i, r in ipairs(self.reviews) do
        local cls = (i == 1 or r.destaque == 1)
          and "review-card review-destaque" or "review-card"
        article({ class = cls }, function()
          -- Capa
          local capa = r.imagem_url ~= "" and r.imagem_url or r.jogo_img
          if capa and capa ~= "" then
            a({ href = "/reviews/" .. r.id }, function()
              img({ src = capa, alt = r.jogo_nome, class = "review-capa" })
            end)
          end

          div({ class = "review-info" }, function()
            -- Badges
            div({ class = "review-meta" }, function()
              span({ class = "tag tag-jogo" }, r.jogo_nome)
              if r.genero and r.genero ~= "" then
                span({ class = "tag" }, r.genero)
              end
              if r.destaque == 1 then
                span({ class = "badge-destaque" }, "⭐ Editor's Choice")
              end
            end)

            -- Título
            h2(function()
              a({ href = "/reviews/" .. r.id, class = "review-titulo" }, r.titulo)
            end)

            -- Nota geral em destaque
            div({ class = "review-nota-hero" }, function()
              div({ class = "review-nota-circulo" .. (
                    tonumber(r.nota_geral) >= 8 and " nota-excelente"
                    or tonumber(r.nota_geral) >= 6 and " nota-bom"
                    or " nota-regular") }, function()
                span({ class = "review-nota-num" },
                  string.format("%.1f", tonumber(r.nota_geral) or 0))
                span({ class = "review-nota-max" }, "/10")
              end)
              div({ class = "review-nota-info" }, function()
                p({ class = "review-estrelas" }, estrelas(r.nota_geral))
                if r.veredicto and r.veredicto ~= "" then
                  p({ class = "review-veredicto" }, r.veredicto)
                end
              end)
            end)

            -- Autor
            if r.autor_nome and r.autor_nome ~= "" then
              div({ class = "noticia-autor-mini" }, function()
                if r.autor_avatar and r.autor_avatar ~= "" then
                  img({ src = r.autor_avatar, alt = r.autor_nome,
                        class = "autor-avatar-mini" })
                end
                span({ class = "autor-mini-nome" }, r.autor_nome)
                span({ class = "data-noticia" }, r.criado_em:sub(1,10))
              end)
            end

            a({ href  = "/reviews/" .. r.id,
                class = "btn-ler-mais", style = "margin-top:.6rem;display:inline-block" },
              "Ler análise completa →")
          end)
        end)
      end
    end)
  else
    div({ class = "shadow-card mt-2" }, function()
      p({ class = "sem-dados" }, "Nenhuma análise publicada ainda.")
    end)
  end
end)