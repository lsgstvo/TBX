local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  local s = self.saude or {}

  div({ class = "admin-section shadow-card" }, function()
    div({ class = "section-header" }, function()
      h2("🏥 Saúde do Banco de Dados")
      div({ style = "display:flex;gap:.5rem" }, function()
        button({ class   = "btn-salvar",
                 onclick = "executarVacuum()",
                 id      = "btn-vacuum" }, "🧹 VACUUM")
        button({ class   = "btn-editar",
                 onclick = "executarAnalyze()",
                 id      = "btn-analyze" }, "🔍 ANALYZE")
      end)
    end)

    -- Cards de métricas gerais
    div({ class = "saude-cards" }, function()
      local tamanho_kb = s.tamanho_kb or 0
      local tamanho_str
      if tamanho_kb >= 1024 then
        tamanho_str = string.format("%.1f MB", tamanho_kb / 1024)
      else
        tamanho_str = tostring(tamanho_kb) .. " KB"
      end
      local cards = {
        { "💾", "Tamanho", tamanho_str },
        { "📄", "Páginas", tostring(s.page_count or 0) },
        { "📏", "Page Size", tostring(s.page_size or 4096) .. " B" },
        { "🗑", "Páginas Livres", tostring(s.freelist or 0) },
      }
      for _, c in ipairs(cards) do
        div({ class = "saude-card" }, function()
          span({ class = "saude-ico" }, c[1])
          span({ class = "saude-val" }, c[3])
          span({ class = "saude-lab" }, c[2])
        end)
      end
    end)

    -- Aviso se há muitas páginas livres (fragmentação)
    if (s.freelist or 0) > 100 then
      div({ class = "saude-aviso" }, function()
        p("⚠️ O banco tem " .. tostring(s.freelist) ..
          " páginas livres. Execute VACUUM para recuperar espaço.")
      end)
    end

    -- Tabela de contagens por tabela
    h3({ style = "margin:1.5rem 0 .8rem" }, "📊 Registros por Tabela")
    if s.tabelas and s.contagens then
      -- Ordena por quantidade desc
      local tabelas_sorted = {}
      for _, t in ipairs(s.tabelas) do
        table.insert(tabelas_sorted, { nome = t, total = s.contagens[t] or 0 })
      end
      table.sort(tabelas_sorted, function(a, b) return a.total > b.total end)
      local max_total = tabelas_sorted[1] and tabelas_sorted[1].total or 1

      element("table", { class = "admin-table" }, function()
        thead(function()
          tr(function() th("Tabela"); th("Registros"); th("Proporção") end)
        end)
        tbody(function()
          for _, t in ipairs(tabelas_sorted) do
            local pct = max_total > 0
              and math.floor((t.total / max_total) * 100) or 0
            tr(function()
              td({ style = "font-family:monospace;font-size:.82rem" }, t.nome)
              td({ class = "views-col", style = "font-weight:700" },
                tostring(t.total))
              td({ style = "min-width:160px" }, function()
                div({ class = "saude-barra-bg" }, function()
                  div({ class  = "saude-barra",
                        style  = "width:" .. pct .. "%" })
                end)
              end)
            end)
          end
        end)
      end)
    end
  end)

  script(function()
    raw([[
      function executarVacuum() {
        var btn = document.getElementById('btn-vacuum');
        btn.textContent = '⏳ Executando...';
        btn.disabled = true;
        fetch('/admin/saude-db/vacuum', { method: 'POST' })
          .then(function(r){ return r.json(); })
          .then(function(data){
            btn.textContent = data.status==='ok' ? '✅ VACUUM ok' : '❌ Erro';
            setTimeout(function(){ location.reload(); }, 1500);
          })
          .catch(function(){ btn.textContent='❌ Erro'; btn.disabled=false; });
      }
      function executarAnalyze() {
        var btn = document.getElementById('btn-analyze');
        btn.textContent = '⏳ Analisando...';
        btn.disabled = true;
        fetch('/admin/saude-db/analyze', { method: 'POST' })
          .then(function(r){ return r.json(); })
          .then(function(data){
            btn.textContent = data.status==='ok' ? '✅ ANALYZE ok' : '❌ Erro';
            setTimeout(function(){ btn.textContent='🔍 ANALYZE'; btn.disabled=false; }, 2000);
          })
          .catch(function(){ btn.textContent='❌ Erro'; btn.disabled=false; });
      }
    ]])
  end)
end)