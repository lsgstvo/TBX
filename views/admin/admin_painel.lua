-- views/admin/admin_painel.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  -- Stats
  local n_dest = 0
  local total_views = 0
  for _, n in ipairs(self.noticias or {}) do
    if n.destaque == 1 then n_dest = n_dest + 1 end
    total_views = total_views + (n.views or 0)
  end

  div({ class = "admin-stats" }, function()
    div({ class = "stat-card" }, function()
      span({ class = "stat-numero" }, tostring(#(self.noticias or {})))
      span({ class = "stat-label" }, "Notícias")
    end)
    div({ class = "stat-card" }, function()
      span({ class = "stat-numero" }, tostring(#(self.jogos or {})))
      span({ class = "stat-label" }, "Jogos")
    end)
    div({ class = "stat-card" }, function()
      span({ class = "stat-numero" }, tostring(n_dest))
      span({ class = "stat-label" }, "Destaques")
    end)
    div({ class = "stat-card" }, function()
      span({ class = "stat-numero" }, tostring(#(self.comentarios or {})))
      span({ class = "stat-label" }, "Comentários")
    end)
    div({ class = "stat-card" }, function()
      span({ class = "stat-numero" }, tostring(total_views))
      span({ class = "stat-label" }, "Views")
    end)
  end)

  -- ── Notícias ─────────────────────────────────────────────────────────────
  div({ class = "admin-section shadow-card" }, function()
    div({ class = "section-header" }, function()
      h2("📰 Notícias")
      a({ href = "/admin/noticias/nova", class = "btn-novo" }, "+ Nova Notícia")
    end)
    if self.noticias and #self.noticias > 0 then
      element("table", { class = "admin-table" }, function()
        thead(function()
          tr(function()
            th("ID"); th("Título"); th("Categoria"); th("Dest."); th("Views"); th("Data"); th("Ações")
          end)
        end)
        tbody(function()
          for _, n in ipairs(self.noticias) do
            tr(function()
              td(tostring(n.id))
              td({ class = "titulo-col" }, n.titulo)
              td(function() span({ class = "tag" }, n.categoria) end)
              td(n.destaque == 1 and "⭐" or "—")
              td({ class = "views-col" }, "👁 " .. tostring(n.views or 0))
              td({ class = "data-col" }, n.criado_em:sub(1, 10))
              td({ class = "acoes-col" }, function()
                a({ href = "/admin/noticias/" .. n.id .. "/editar", class = "btn-editar" }, "✏️")
                form({ method = "POST", action = "/admin/noticias/" .. n.id .. "/deletar",
                       onsubmit = "return confirm('Deletar?')", style = "display:inline" }, function()
                  button({ type = "submit", class = "btn-deletar" }, "🗑")
                end)
              end)
            end)
          end
        end)
      end)
    else
      p({ class = "sem-dados" }, "Nenhuma notícia cadastrada.")
    end
  end)

  -- ── Jogos ─────────────────────────────────────────────────────────────────
  div({ class = "admin-section shadow-card" }, function()
    div({ class = "section-header" }, function()
      h2("🎮 Jogos")
      a({ href = "/admin/jogos/novo", class = "btn-novo" }, "+ Novo Jogo")
    end)
    if self.jogos and #self.jogos > 0 then
      element("table", { class = "admin-table" }, function()
        thead(function()
          tr(function() th("#"); th("Nome"); th("Gênero"); th("Players"); th("Ações") end)
        end)
        tbody(function()
          for _, j in ipairs(self.jogos) do
            tr(function()
              td(tostring(j.posicao))
              td({ class = "titulo-col" }, j.nome)
              td(function() span({ class = "tag" }, j.genero) end)
              td(j.players)
              td({ class = "acoes-col" }, function()
                a({ href = "/admin/jogos/" .. j.id .. "/editar", class = "btn-editar" }, "✏️")
                form({ method = "POST", action = "/admin/jogos/" .. j.id .. "/deletar",
                       onsubmit = "return confirm('Deletar?')", style = "display:inline" }, function()
                  button({ type = "submit", class = "btn-deletar" }, "🗑")
                end)
              end)
            end)
          end
        end)
      end)
    else
      p({ class = "sem-dados" }, "Nenhum jogo cadastrado.")
    end
  end)

  -- ── Comentários ───────────────────────────────────────────────────────────
  div({ id = "comentarios", class = "admin-section shadow-card" }, function()
    h2("💬 Comentários Recentes")
    if self.comentarios and #self.comentarios > 0 then
      element("table", { class = "admin-table" }, function()
        thead(function()
          tr(function() th("Autor"); th("Notícia"); th("Comentário"); th("Data"); th("Ação") end)
        end)
        tbody(function()
          for _, c in ipairs(self.comentarios) do
            tr(function()
              td({ class = "autor-col" }, c.autor)
              td({ class = "titulo-col" }, function()
                a({ href = "/noticias/" .. c.noticia_id }, c.noticia_titulo:sub(1, 40) .. "...")
              end)
              td({ class = "coment-col" }, c.conteudo:sub(1, 80) .. (c.conteudo:len() > 80 and "..." or ""))
              td({ class = "data-col" }, c.criado_em:sub(1, 10))
              td(function()
                form({ method = "POST", action = "/admin/comentarios/" .. c.id .. "/deletar",
                       onsubmit = "return confirm('Deletar comentário?')" }, function()
                  button({ type = "submit", class = "btn-deletar" }, "🗑")
                end)
              end)
            end)
          end
        end)
      end)
    else
      p({ class = "sem-dados" }, "Nenhum comentário ainda.")
    end
  end)
end)