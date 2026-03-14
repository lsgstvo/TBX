-- views/admin/admin_painel.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  local n_dest = 0; local total_views = 0
  for _, n in ipairs(self.noticias or {}) do
    if n.destaque == 1 then n_dest = n_dest + 1 end
    total_views = total_views + (n.views or 0)
  end

  -- ── Stats ──────────────────────────────────────────────────────────────
  div({ class = "admin-stats" }, function()
    local cards = {
      { tostring(#(self.noticias or {})), "Notícias" },
      { tostring(#(self.jogos or {})),    "Jogos"    },
      { tostring(n_dest),                 "Destaques"},
      { tostring(self.coment_total or 0), "Comentários"},
      { tostring(total_views),            "Views"    },
      { tostring(#(self.autores or {})),  "Autores"  },
      { tostring(self.newsletter_total or 0), "Newsletter"},
    }
    for _, c in ipairs(cards) do
      div({ class = "stat-card" }, function()
        span({ class = "stat-numero" }, c[1])
        span({ class = "stat-label" },  c[2])
      end)
    end
  end)

  -- ── Notícias Agendadas ─────────────────────────────────────────────────
  if self.agendadas and #self.agendadas > 0 then
    div({ class = "admin-section shadow-card agendadas-section" }, function()
      h2("⏰ Agendadas (" .. #self.agendadas .. ")")
      element("table", { class = "admin-table" }, function()
        thead(function()
          tr(function() th("Título"); th("Publicar em"); th("Ações") end)
        end)
        tbody(function()
          for _, n in ipairs(self.agendadas) do
            tr(function()
              td({ class = "titulo-col" }, n.titulo)
              td({ class = "data-col agendada-data" }, n.publicar_em:sub(1, 16))
              td({ class = "acoes-col" }, function()
                a({ href = "/admin/noticias/" .. n.id .. "/editar",
                    class = "btn-editar" }, "✏️ Editar")
              end)
            end)
          end
        end)
      end)
    end)
  end

  -- ── Dashboard ─────────────────────────────────────────────────────────
  div({ class = "admin-dashboard-row shadow-card" }, function()
    div({ class = "dashboard-chart-col" }, function()
      h3("📈 Views por Dia (30 dias)")
      div({ id = "chart-views", class = "dashboard-chart" })
      local dados_json = "["
      local vd = self.views_por_dia or {}
      for i, d in ipairs(vd) do
        dados_json = dados_json .. string.format(
          '{"data":"%s","total":%d}%s', d.data, d.total, i < #vd and "," or "")
      end
      dados_json = dados_json .. "]"
      script(function()
        raw(string.format([[
          (function(){
            var dados=%s, chart=document.getElementById('chart-views');
            if(!chart||dados.length===0){
              if(chart)chart.innerHTML='<p style="color:var(--text-muted);padding:1rem">Sem dados ainda.</p>';
              return;
            }
            var max=Math.max.apply(null,dados.map(function(d){return d.total;}))||1;
            var html='<div class="dash-bars">';
            dados.forEach(function(d){
              var pct=Math.max(Math.round((d.total/max)*100),2);
              html+='<div class="dash-bar-col" title="'+d.data+': '+d.total+' views">'+
                '<div class="dash-bar-wrap"><div class="dash-bar" style="height:'+pct+'%%"></div></div>'+
                '<span class="dash-bar-label">'+d.data.slice(5)+'</span></div>';
            });
            html+='</div>';
            chart.innerHTML=html;
          })();
        ]], dados_json))
      end)
    end)
    div({ class = "dashboard-top-col" }, function()
      h3("🔥 Top 7 dias")
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

  -- ── Notícias ───────────────────────────────────────────────────────────
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
                a({ href = "/admin/noticias/" .. n.id .. "/editar",
                    class = "btn-editar" }, "✏️")
                form({ method = "POST",
                       action  = "/admin/noticias/" .. n.id .. "/deletar",
                       onsubmit = "return confirm('Deletar?')",
                       style   = "display:inline" }, function()
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

  -- ── Jogos ──────────────────────────────────────────────────────────────
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
              td(tostring(j.posicao)); td({ class = "titulo-col" }, j.nome)
              td(function() span({ class = "tag" }, j.genero) end)
              td(j.players)
              td({ class = "acoes-col" }, function()
                a({ href = "/admin/jogos/" .. j.id .. "/editar",
                    class = "btn-editar" }, "✏️")
                form({ method = "POST",
                       action  = "/admin/jogos/" .. j.id .. "/deletar",
                       onsubmit = "return confirm('Deletar?')",
                       style   = "display:inline" }, function()
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

  -- ── Comentários com Moderação ──────────────────────────────────────────
  div({ id = "comentarios", class = "admin-section shadow-card" }, function()
    div({ class = "section-header" }, function()
      h2("💬 Comentários")
      div({ class = "coment-filtros" }, function()
        a({ href  = "/admin#comentarios",
            class = "filtro-btn" .. (not self.filtro_pendentes and " filtro-ativo" or "") },
          "Todos")
        a({ href  = "/admin?pendentes=1#comentarios",
            class = "filtro-btn" .. (self.filtro_pendentes and " filtro-ativo" or "") }, function()
          raw("Pendentes")
          if (self.pendentes_count or 0) > 0 then
            span({ class = "badge-notif",
                   style = "margin-left:.4rem" },
                 tostring(self.pendentes_count))
          end
        end)
      end)
    end)

    if self.comentarios and #self.comentarios > 0 then
      element("table", { class = "admin-table" }, function()
        thead(function()
          tr(function()
            th("Status"); th("Autor"); th("Notícia")
            th("Comentário"); th("Data"); th("Ações")
          end)
        end)
        tbody(function()
          for _, c in ipairs(self.comentarios) do
            tr(function()
              -- Status visual
              td(function()
                if c.aprovado == 1 then
                  span({ class = "status-aprovado" }, "✅")
                else
                  span({ class = "status-pendente" }, "⏳")
                end
              end)
              td(c.autor)
              td({ class = "titulo-col" }, function()
                a({ href = "/noticias/" .. c.noticia_id },
                  (c.noticia_titulo or ""):sub(1, 30) .. "...")
              end)
              td({ class = "coment-col" },
                c.conteudo:sub(1, 70) .. (c.conteudo:len() > 70 and "..." or ""))
              td({ class = "data-col" }, c.criado_em:sub(1, 10))
              td({ class = "acoes-col" }, function()
                -- Botão aprovar (só para pendentes)
                if c.aprovado == 0 then
                  form({ method  = "POST",
                         action   = "/admin/comentarios/" .. c.id .. "/aprovar",
                         style    = "display:inline" }, function()
                    button({ type = "submit", class = "btn-aprovar" }, "✅ Aprovar")
                  end)
                end
                form({ method  = "POST",
                       action   = "/admin/comentarios/" .. c.id .. "/deletar",
                       onsubmit = "return confirm('Deletar?')",
                       style    = "display:inline" }, function()
                  button({ type = "submit", class = "btn-deletar" }, "🗑")
                end)
              end)
            end)
          end
        end)
      end)

      -- Paginação
      if self.coment_total_pag and self.coment_total_pag > 1 then
        local extra = self.filtro_pendentes and "&pendentes=1" or ""
        div({ class = "paginacao paginacao-sm" }, function()
          if self.coment_pagina > 1 then
            a({ href  = "/admin?pagina_coment=" .. (self.coment_pagina-1) .. extra .. "#comentarios",
                class = "pag-btn" }, "← Anterior")
          end
          for i = 1, self.coment_total_pag do
            if i == self.coment_pagina then
              span({ class = "pag-btn pag-atual" }, tostring(i))
            else
              a({ href  = "/admin?pagina_coment=" .. i .. extra .. "#comentarios",
                  class = "pag-btn" }, tostring(i))
            end
          end
          if self.coment_pagina < self.coment_total_pag then
            a({ href  = "/admin?pagina_coment=" .. (self.coment_pagina+1) .. extra .. "#comentarios",
                class = "pag-btn" }, "Próxima →")
          end
        end)
      end
    else
      p({ class = "sem-dados" }, "Nenhum comentário.")
    end
  end)
end)