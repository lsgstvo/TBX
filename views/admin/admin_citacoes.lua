local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    div({ class = "section-header" }, function()
      h2("💬 Citações de Games")
      p({ class = "field-hint", style = "margin:0" },
        "Aparecem aleatoriamente no rodapé do site.")
    end)

    -- Formulário inline de criação
    div({ class = "ab-form-card shadow-card" }, function()
      h3("+ Nova Citação")
      form({ method = "POST", action = "/admin/citacoes/nova",
             class  = "admin-form" }, function()
        div({ class = "form-group" }, function()
          label({ ["for"] = "texto" }, "Citação *")
          textarea({ id = "texto", name = "texto", rows = "3",
                     placeholder = "Ex: It's dangerous to go alone! Take this.",
                     required = true })
        end)
        div({ class = "form-row" }, function()
          div({ class = "form-group form-grow" }, function()
            label({ ["for"] = "personagem" }, "Personagem")
            input({ type = "text", id = "personagem", name = "personagem",
                    placeholder = "Ex: Old Man" })
          end)
          div({ class = "form-group form-grow" }, function()
            label({ ["for"] = "jogo" }, "Jogo")
            input({ type = "text", id = "jogo", name = "jogo",
                    placeholder = "Ex: The Legend of Zelda" })
          end)
        end)
        div({ class = "form-actions" }, function()
          button({ type = "submit", class = "btn-salvar" }, "💾 Salvar Citação")
        end)
      end)
    end)

    -- Lista de citações cadastradas
    if self.citacoes and #self.citacoes > 0 then
      h3({ style = "margin:1.5rem 0 .8rem" },
        "📋 Cadastradas (" .. #self.citacoes .. ")")
      div({ class = "citacoes-lista" }, function()
        for _, c in ipairs(self.citacoes) do
          div({ class = "citacao-admin-card" }, function()
            p({ class = "citacao-admin-texto" },
              "\u201c" .. c.texto .. "\u201d")
            div({ class = "citacao-admin-meta" }, function()
              if c.personagem ~= "" then
                span({ class = "tag" }, c.personagem)
              end
              if c.jogo ~= "" then
                span({ class = "tag tag-jogo" }, c.jogo)
              end
              form({ method   = "POST",
                     action   = "/admin/citacoes/" .. c.id .. "/deletar",
                     onsubmit = "return confirm('Deletar citação?')",
                     style    = "display:inline;margin-left:auto" }, function()
                button({ type = "submit", class = "btn-deletar" }, "🗑")
              end)
            end)
          end)
        end
      end)
    else
      p({ class = "sem-dados", style = "margin-top:1rem" },
        "Nenhuma citação cadastrada. Adicione algumas para aparecerem no footer!")
    end
  end)
end)