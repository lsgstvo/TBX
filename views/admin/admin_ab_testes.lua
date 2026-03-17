local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    div({ class = "section-header" }, function()
      h2("🧪 A/B Test de Títulos")
      p({ class = "field-hint", style = "margin:0" },
        "Compare dois títulos para a mesma notícia e veja qual gera mais cliques.")
    end)

    -- Formulário para criar novo teste
    div({ class = "ab-form-card shadow-card" }, function()
      h3("+ Novo Teste")
      form({ method = "POST", action = "/admin/ab-testes/novo",
             class  = "admin-form" }, function()
        div({ class = "form-group" }, function()
          label({ ["for"] = "noticia_id" }, "Notícia")
          element("select", { id = "noticia_id", name = "noticia_id",
                               required = true }, function()
            option({ value = "" }, "— Selecione uma notícia —")
            for _, n in ipairs(self.noticias or {}) do
              option({ value = tostring(n.id) },
                "#" .. n.id .. " — " .. n.titulo:sub(1, 60))
            end
          end)
          p({ class = "field-hint" }, "Este será o Título A (original).")
        end)
        div({ class = "form-group" }, function()
          label({ ["for"] = "titulo_b" }, "Título B (variante)")
          input({ type = "text", id = "titulo_b", name = "titulo_b",
                  placeholder = "Escreva um título alternativo para testar",
                  required = true })
        end)
        div({ class = "form-actions" }, function()
          button({ type = "submit", class = "btn-salvar" }, "🧪 Iniciar Teste")
        end)
      end)
    end)

    -- Testes ativos e resultados
    if self.testes and #self.testes > 0 then
      h3({ style = "margin:1.5rem 0 .8rem" }, "📊 Testes em Andamento")
      for _, teste in ipairs(self.testes) do
        local total   = (teste.views_a or 0) + (teste.views_b or 0)
        local pct_a   = total > 0 and math.floor((teste.views_a / total) * 100) or 50
        local pct_b   = 100 - pct_a
        local vence_a = teste.views_a >= teste.views_b
        local ativo   = teste.ativo == 1

        div({ class = "ab-card shadow-card" .. (not ativo and " ab-inativo" or "") }, function()
          div({ class = "ab-card-header" }, function()
            span({ class = "ab-status" }, ativo and "🟢 Ativo" or "⏸ Pausado")
            span({ class = "data-col" }, teste.criado_em:sub(1, 10))
            form({ method = "POST",
                   action  = "/admin/ab-testes/" .. teste.id .. "/deletar",
                   onsubmit = "return confirm('Encerrar este teste?')",
                   style   = "display:inline" }, function()
              button({ type = "submit", class = "btn-deletar" }, "🗑 Encerrar")
            end)
          end)

          -- Comparação visual
          div({ class = "ab-comparacao" }, function()
            -- Variante A
            div({ class = "ab-variante" .. (vence_a and " ab-lidera" or "") }, function()
              div({ class = "ab-variante-label" }, function()
                span({ class = "ab-letra ab-letra-a" }, "A")
                span({ class = "ab-variante-hint" }, "Original")
                if vence_a and total > 0 then
                  span({ class = "ab-winner-badge" }, "🏆 Lidera")
                end
              end)
              p({ class = "ab-titulo" }, teste.titulo_a or "—")
              div({ class = "ab-barra-wrapper" }, function()
                div({ class  = "ab-barra ab-barra-a",
                      style  = "width:" .. pct_a .. "%" })
              end)
              div({ class = "ab-stats" }, function()
                span({ class = "ab-views" },
                  "👁 " .. tostring(teste.views_a or 0) .. " views")
                span({ class = "ab-pct" }, "(" .. pct_a .. "%)")
              end)
            end)

            div({ class = "ab-vs" }, "VS")

            -- Variante B
            div({ class = "ab-variante" .. (not vence_a and total > 0 and " ab-lidera" or "") }, function()
              div({ class = "ab-variante-label" }, function()
                span({ class = "ab-letra ab-letra-b" }, "B")
                span({ class = "ab-variante-hint" }, "Variante")
                if not vence_a and total > 0 then
                  span({ class = "ab-winner-badge" }, "🏆 Lidera")
                end
              end)
              p({ class = "ab-titulo" }, teste.titulo_b)
              div({ class = "ab-barra-wrapper" }, function()
                div({ class  = "ab-barra ab-barra-b",
                      style  = "width:" .. pct_b .. "%" })
              end)
              div({ class = "ab-stats" }, function()
                span({ class = "ab-views" },
                  "👁 " .. tostring(teste.views_b or 0) .. " views")
                span({ class = "ab-pct" }, "(" .. pct_b .. "%)")
              end)
            end)
          end)

          -- Total
          div({ class = "ab-total" }, function()
            if total == 0 then
              span({ class = "sem-dados" }, "Aguardando visitantes...")
            else
              span({ class = "ab-total-txt" },
                "Total: " .. total .. " impressões")
              span({ class = "meta-sep" }, "·")
              a({ href   = "/noticias/" .. (teste.noticia_id or ""),
                  target = "_blank",
                  class  = "meta-item" }, "Ver notícia →")
            end
          end)
        end)
      end
    else
      p({ class = "sem-dados", style = "margin-top:1rem" },
        "Nenhum teste criado ainda.")
    end
  end)
end)