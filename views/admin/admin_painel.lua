-- Painel principal: lista notícias e jogos com opção de deletar

local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  -- Cards de resumo
  div({ class = "admin-stats" }, function()
    div({ class = "stat-card" }, function()
      span({ class = "stat-numero" }, tostring(#(self.noticias or {})))
      span({ class = "stat-label" }, "Notícias")
    end)
    div({ class = "stat-card" }, function()
      span({ class = "stat-numero" }, tostring(#(self.jogos or {})))
      span({ class = "stat-label" }, "Jogos no Ranking")
    end)
  end)

  -- Tabela de notícias
  div({ class = "admin-section shadow-card" }, function()
    div({ class = "section-header" }, function()
      h2("📰 Notícias")
      a({ href = "/admin/noticias/nova", class = "btn-novo" }, "+ Nova Notícia")
    end)

    if self.noticias and #self.noticias > 0 then
      table({ class = "admin-table" }, function()
        thead(function()
          tr(function()
            th("ID")
            th("Título")
            th("Jogo")
            th("Data")
            th("Ações")
          end)
        end)
        tbody(function()
          for _, n in ipairs(self.noticias) do
            tr(function()
              td(tostring(n.id))
              td({ class = "titulo-col" }, n.titulo)
              td(function() span({ class = "tag" }, n.jogo) end)
              td({ class = "data-col" }, n.criado_em:sub(1, 10))
              td(function()
                -- Botão deletar via formulário POST
                form({ method = "POST",
                       action = "/admin/noticias/" .. n.id .. "/deletar",
                       onsubmit = "return confirm('Deletar esta notícia?')" }, function()
                  button({ type = "submit", class = "btn-deletar" }, "🗑 Deletar")
                end)
              end)
            end)
          end
        end)
      end)
    else
      p({ class = "sem-dados" }, "Nenhuma notícia cadastrada ainda.")
    end
  end)
end)