-- views/admin/admin_painel.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  -- Stats
  div({ class = "admin-stats" }, function()
    div({ class = "stat-card" }, function()
      span({ class = "stat-numero" }, tostring(#(self.noticias or {})))
      span({ class = "stat-label" }, "Notícias")
    end)
    div({ class = "stat-card" }, function()
      span({ class = "stat-numero" }, tostring(#(self.jogos or {})))
      span({ class = "stat-label" }, "Jogos")
    end)
    -- Conta destaques
    local n_dest = 0
    for _, n in ipairs(self.noticias or {}) do
      if n.destaque == 1 then n_dest = n_dest + 1 end
    end
    div({ class = "stat-card" }, function()
      span({ class = "stat-numero" }, tostring(n_dest))
      span({ class = "stat-label" }, "Destaques")
    end)
  end)

  -- ── Tabela de notícias ────────────────────────────────────────────────────
  div({ class = "admin-section shadow-card" }, function()
    div({ class = "section-header" }, function()
      h2("📰 Notícias")
      a({ href = "/admin/noticias/nova", class = "btn-novo" }, "+ Nova Notícia")
    end)
    if self.noticias and #self.noticias > 0 then
      element("table", { class = "admin-table" }, function()
        thead(function()
          tr(function()
            th("ID"); th("Título"); th("Jogo"); th("Categoria"); th("Destaque"); th("Data"); th("Ações")
          end)
        end)
        tbody(function()
          for _, n in ipairs(self.noticias) do
            tr(function()
              td(tostring(n.id))
              td({ class = "titulo-col" }, n.titulo)
              td(function() if n.jogo ~= "" then span({ class = "tag tag-jogo" }, n.jogo) end end)
              td(function() span({ class = "tag" }, n.categoria) end)
              td(n.destaque == 1 and "⭐" or "—")
              td({ class = "data-col" }, n.criado_em:sub(1, 10))
              td({ class = "acoes-col" }, function()
                a({ href = "/admin/noticias/" .. n.id .. "/editar", class = "btn-editar" }, "✏️ Editar")
                form({ method = "POST", action = "/admin/noticias/" .. n.id .. "/deletar",
                       onsubmit = "return confirm('Deletar esta notícia?')", style = "display:inline" }, function()
                  button({ type = "submit", class = "btn-deletar" }, "🗑")
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

  -- ── Tabela de jogos ───────────────────────────────────────────────────────
  div({ class = "admin-section shadow-card" }, function()
    div({ class = "section-header" }, function()
      h2("🎮 Jogos do Ranking")
      a({ href = "/admin/jogos/novo", class = "btn-novo" }, "+ Novo Jogo")
    end)
    if self.jogos and #self.jogos > 0 then
      element("table", { class = "admin-table" }, function()
        thead(function()
          tr(function()
            th("#"); th("Nome"); th("Gênero"); th("Players"); th("Ações")
          end)
        end)
        tbody(function()
          for _, j in ipairs(self.jogos) do
            tr(function()
              td(tostring(j.posicao))
              td({ class = "titulo-col" }, j.nome)
              td(function() span({ class = "tag" }, j.genero) end)
              td(j.players)
              td({ class = "acoes-col" }, function()
                a({ href = "/admin/jogos/" .. j.id .. "/editar", class = "btn-editar" }, "✏️ Editar")
                form({ method = "POST", action = "/admin/jogos/" .. j.id .. "/deletar",
                       onsubmit = "return confirm('Deletar este jogo?')", style = "display:inline" }, function()
                  button({ type = "submit", class = "btn-deletar" }, "🗑")
                end)
              end)
            end)
          end
        end)
      end)
    else
      p({ class = "sem-dados" }, "Nenhum jogo cadastrado ainda.")
    end
  end)
end)