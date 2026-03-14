-- views/admin/admin_painel.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  local n_dest = 0
  local total_views = 0
  for _, n in ipairs(self.noticias or {}) do
    if n.destaque == 1 then n_dest = n_dest + 1 end
    total_views = total_views + (n.views or 0)
  end

  -- ── Stats ──────────────────────────────────────────────────────────────────
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
      span({ class = "stat-numero" }, tostring(self.coment_total or 0))
      span({ class = "stat-label" }, "Comentários")
    end)
    div({ class = "stat-card" }, function()
      span({ class = "stat-numero" }, tostring(total_views))
      span({ class = "stat-label" }, "Views")
    end)
    div({ class = "stat-card" }, function()
      span({ class = "stat-numero" }, tostring(#(self.autores or {})))
      span({ class = "stat-label" }, "Autores")
    end)
  end)

  -- ── Dashboard: Gráfico de views por dia + Top semana ──────────────────────
  div({ class = "admin-dashboard-row shadow-card" }, function()
    -- Gráfico de views (últimos 30 dias)
    div({ class = "dashboard-chart-col" }, function()
      h3("📈 Views por Dia (últimos 30 dias)")
      div({ id = "chart-views", class = "dashboard-chart" })
      -- Dados passados via JSON inline para o JS
      local dados_json = "["
      local views_dia = self.views_por_dia or {}
      for i, d in ipairs(views_dia) do
        dados_json = dados_json .. string.format(
          '{"data":"%s","total":%d}%s',
          d.data, d.total, i < #views_dia and "," or ""
        )
      end
      dados_json = dados_json .. "]"

      script(function()
        raw(string.format([[
          (function() {
            var dados = %s;
            var chart = document.getElementById('chart-views');
            if (!chart || dados.length === 0) {
              if (chart) chart.innerHTML =
                '<p style="color:var(--text-muted);padding:1rem">Sem dados ainda.</p>';
              return;
            }
            var max = Math.max.apply(null, dados.map(function(d){ return d.total; }));
            if (max === 0) max = 1;
            var html = '<div class="dash-bars">';
            dados.forEach(function(d) {
              var pct = Math.max(Math.round((d.total / max) * 100), 2);
              var dia = d.data.slice(5); // MM-DD
              html += '<div class="dash-bar-col" title="' + d.data + ': ' + d.total + ' views">' +
                '<div class="dash-bar-wrap">' +
                  '<div class="dash-bar" style="height:' + pct + '%%"></div>' +
                '</div>' +
                '<span class="dash-bar-label">' + dia + '</span>' +
              '</div>';
            });
            html += '</div>';
            chart.innerHTML = html;
          })();
        ]], dados_json))
      end)
    end)

    -- Top notícias da semana
    div({ class = "dashboard-top-col" }, function()
      h3("🔥 Top Notícias (7 dias)")
      if self.top_semana and #self.top_semana > 0 then
        ul({ class = "top-noticias-lista" }, function()
          for i, n in ipairs(self.top_semana) do
            li(function()
              span({ class = "top-pos" }, tostring(i))
              div({ class = "top-info" }, function()
                a({ href = "/noticias/" .. n.id, target = "_blank",
                    class = "top-titulo" }, n.titulo)
                span({ class = "top-views" },
                  "👁 " .. tostring(n.views_periodo) .. " views")
              end)
            end)
          end
        end)
      else
        p({ class = "sem-dados" }, "Sem dados de views ainda.")
      end
    end)
  end)

  -- ── Notícias ────────────────────────────────────────────────────────────────
  div({ class = "admin-section shadow-card" }, function()
    div({ class = "section-header" }, function()
      h2("📰 Notícias")
      a({ href = "/admin/noticias/nova", class = "btn-novo" }, "+ Nova Notícia")
    end)
    if self.noticias and #self.noticias > 0 then
      element("table", { class = "admin-table" }, function()
        thead(function()
          tr(function()
            th("ID"); th("Título"); th("Autor"); th("Cat."); th("Dest.")
            th("Views"); th("Data"); th("Ações")
          end)
        end)
        tbody(function()
          for _, n in ipairs(self.noticias) do
            tr(function()
              td(tostring(n.id))
              td({ class = "titulo-col" }, n.titulo)
              td({ class = "data-col" }, n.autor_nome or "—")
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

  -- ── Jogos ───────────────────────────────────────────────────────────────────
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

  -- ── Comentários (paginados) ──────────────────────────────────────────────
  div({ id = "comentarios", class = "admin-section shadow-card" }, function()
    div({ class = "section-header" }, function()
      h2("💬 Comentários")
      if self.coment_total and self.coment_total > 0 then
        span({ class = "stat-badge" }, tostring(self.coment_total) .. " total")
      end
    end)
    if self.comentarios and #self.comentarios > 0 then
      element("table", { class = "admin-table" }, function()
        thead(function()
          tr(function()
            th("Autor"); th("Notícia"); th("Comentário"); th("Data"); th("Ação")
          end)
        end)
        tbody(function()
          for _, c in ipairs(self.comentarios) do
            tr(function()
              td(c.autor)
              td({ class = "titulo-col" }, function()
                a({ href = "/noticias/" .. c.noticia_id },
                  (c.noticia_titulo or ""):sub(1, 35) .. "...")
              end)
              td({ class = "coment-col" },
                c.conteudo:sub(1, 80) .. (c.conteudo:len() > 80 and "..." or ""))
              td({ class = "data-col" }, c.criado_em:sub(1, 10))
              td(function()
                form({ method = "POST",
                       action  = "/admin/comentarios/" .. c.id .. "/deletar",
                       onsubmit = "return confirm('Deletar comentário?')" }, function()
                  button({ type = "submit", class = "btn-deletar" }, "🗑")
                end)
              end)
            end)
          end
        end)
      end)
      if self.coment_total_pag and self.coment_total_pag > 1 then
        div({ class = "paginacao paginacao-sm" }, function()
          if self.coment_pagina > 1 then
            a({ href = "/admin?pagina_coment=" .. (self.coment_pagina-1) .. "#comentarios",
                class = "pag-btn" }, "← Anterior")
          end
          for i = 1, self.coment_total_pag do
            if i == self.coment_pagina then
              span({ class = "pag-btn pag-atual" }, tostring(i))
            else
              a({ href = "/admin?pagina_coment=" .. i .. "#comentarios",
                  class = "pag-btn" }, tostring(i))
            end
          end
          if self.coment_pagina < self.coment_total_pag then
            a({ href = "/admin?pagina_coment=" .. (self.coment_pagina+1) .. "#comentarios",
                class = "pag-btn" }, "Próxima →")
          end
        end)
      end
    else
      p({ class = "sem-dados" }, "Nenhum comentário ainda.")
    end
  end)
end)