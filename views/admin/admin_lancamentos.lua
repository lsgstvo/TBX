-- views/admin/admin_lancamentos.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    div({ class = "section-header" }, function()
      h2("🎮 Lançamentos")
      a({ href = "/admin/lancamentos/novo", class = "btn-novo" }, "+ Novo Lançamento")
    end)
    if self.lancamentos and #self.lancamentos > 0 then
      element("table", { class = "admin-table" }, function()
        thead(function()
          tr(function()
            th("Jogo"); th("Plataformas"); th("Data"); th("Gênero"); th("Ações")
          end)
        end)
        tbody(function()
          local hoje = os.date("%Y-%m-%d")
          for _, l in ipairs(self.lancamentos) do
            local passado = l.data_lancamento ~= "" and l.data_lancamento < hoje
            tr({ class = passado and "lancamento-row-passado" or "" }, function()
              td({ class = "titulo-col" }, function()
                if l.imagem_url ~= "" then
                  img({ src = l.imagem_url, class = "lancamento-thumb-mini",
                        alt = l.nome })
                end
                span(l.nome)
              end)
              td(l.plataformas ~= "" and l.plataformas or "—")
              td({ class = passado and "data-col" or "data-col agendada-data" },
                l.data_lancamento ~= "" and l.data_lancamento or "—")
              td(function()
                if l.genero ~= "" then span({ class = "tag" }, l.genero) end
              end)
              td({ class = "acoes-col" }, function()
                a({ href = "/admin/lancamentos/" .. l.id .. "/editar",
                    class = "btn-editar" }, "✏️")
                form({ method = "POST",
                       action  = "/admin/lancamentos/" .. l.id .. "/deletar",
                       onsubmit = "return confirm('Deletar lançamento?')",
                       style   = "display:inline" }, function()
                  button({ type = "submit", class = "btn-deletar" }, "🗑")
                end)
              end)
            end)
          end
        end)
      end)
    else
      p({ class = "sem-dados" }, "Nenhum lançamento cadastrado.")
    end
  end)
end)