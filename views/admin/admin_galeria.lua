local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    div({ class = "section-header" }, function()
      h2("🖼 Galeria de Jogos")
      a({ href = "/galeria", target = "_blank", class = "btn-editar" }, "👁 Ver pública")
    end)

    -- Formulário para adicionar imagem
    div({ class = "ab-form-card shadow-card" }, function()
      h3("+ Adicionar Imagem")
      form({ method = "POST", action = "/admin/galeria/adicionar",
             class  = "admin-form" }, function()
        div({ class = "form-row" }, function()
          div({ class = "form-group form-grow" }, function()
            label({ ["for"] = "jogo_id" }, "Jogo *")
            element("select", { id = "jogo_id", name = "jogo_id",
                                 required = true,
                                 onchange = "previewImg()" }, function()
              option({ value = "" }, "— Selecione —")
              for _, j in ipairs(self.jogos or {}) do
                option({ value = tostring(j.id) },
                  "#" .. j.posicao .. " " .. j.nome)
              end
            end)
          end)
          div({ class = "form-group form-grow" }, function()
            label({ ["for"] = "url" }, "URL da Imagem *")
            input({ type = "url", id = "url", name = "url",
                    placeholder = "https://...",
                    required = true,
                    oninput = "previewImg()" })
          end)
          div({ class = "form-group form-grow" }, function()
            label({ ["for"] = "legenda" }, "Legenda")
            input({ type = "text", id = "legenda", name = "legenda",
                    placeholder = "Ex: Screenshot do mapa Bind" })
          end)
        end)
        div({ id = "galeria-preview", class = "galeria-admin-preview" })
        div({ class = "form-actions" }, function()
          button({ type = "submit", class = "btn-salvar" }, "💾 Adicionar")
        end)
      end)
    end)

    script(function()
      raw([[
        function previewImg() {
          var url = document.getElementById('url').value;
          var box = document.getElementById('galeria-preview');
          if (url && url.startsWith('http')) {
            box.innerHTML = '<img src="' + url + '" class="galeria-admin-thumb" onerror="this.style.display=\'none\'">';
          } else { box.innerHTML = ''; }
        }
      ]])
    end)

    -- Listagem de imagens cadastradas
    if self.imagens and #self.imagens > 0 then
      h3({ style = "margin:1.5rem 0 .8rem" },
        "📋 Imagens cadastradas (" .. #self.imagens .. ")")
      div({ class = "galeria-admin-grid" }, function()
        for _, img_item in ipairs(self.imagens) do
          div({ class = "galeria-admin-card" }, function()
            img({ src     = img_item.url,
                  alt     = img_item.legenda or "",
                  class   = "galeria-admin-img",
                  loading = "lazy",
                  onerror = "this.style.opacity='.3'" })
            div({ class = "galeria-admin-info" }, function()
              span({ class = "tag tag-jogo" }, img_item.jogo_nome or "—")
              if img_item.legenda and img_item.legenda ~= "" then
                p({ class = "galeria-admin-legenda" }, img_item.legenda:sub(1, 40))
              end
            end)
            form({ method   = "POST",
                   action   = "/admin/galeria/" .. img_item.id .. "/deletar",
                   onsubmit = "return confirm('Remover esta imagem?')",
                   class    = "galeria-admin-del" }, function()
              button({ type = "submit", class = "btn-deletar" }, "🗑")
            end)
          end)
        end
      end)
    else
      p({ class = "sem-dados", style = "margin-top:1rem" },
        "Nenhuma imagem cadastrada ainda.")
    end
  end)
end)