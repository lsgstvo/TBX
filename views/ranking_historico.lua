local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  local mes_ant_ano  = self.mes == 1  and self.ano - 1 or self.ano
  local mes_ant      = self.mes == 1  and 12 or self.mes - 1
  local mes_prox_ano = self.mes == 12 and self.ano + 1 or self.ano
  local mes_prox     = self.mes == 12 and 1  or self.mes + 1

  -- Hero com navegação
  div({ class = "shadow-card ranking-hist-hero" }, function()
    div({ class = "cal-header" }, function()
      a({ href  = string.format("/ranking/historico?ano=%d&mes=%d", mes_ant_ano, mes_ant),
          class = "cal-nav-btn" }, "←")
      h2({ class = "cal-titulo" }, "📊 " .. self.mes_nome .. " " .. tostring(self.ano))
      a({ href  = string.format("/ranking/historico?ano=%d&mes=%d", mes_prox_ano, mes_prox),
          class = "cal-nav-btn" }, "→")
    end)
    -- Seletor rápido de meses com dados
    if self.meses_disponiveis and #self.meses_disponiveis > 0 then
      div({ class = "hist-meses-selector" }, function()
        for _, m in ipairs(self.meses_disponiveis) do
          local ativo = (tostring(m.ano) == tostring(self.ano) and
                         tostring(tonumber(m.mes)) == tostring(self.mes))
          a({ href  = "/ranking/historico?ano=" .. m.ano .. "&mes=" .. tonumber(m.mes),
              class = "janela-btn" .. (ativo and " janela-ativa" or "") },
            m.ano_mes)
        end
      end)
    end
  end)

  -- Gráfico de views mensais (série histórica)
  if self.serie_mensal and #self.serie_mensal > 0 then
    div({ class = "shadow-card mt-2" }, function()
      h3("📈 Views por Mês (histórico)")
      div({ id = "hist-chart", class = "dashboard-chart" })
      local dados_json = "["
      for i, d in ipairs(self.serie_mensal) do
        dados_json = dados_json .. string.format(
          '{"mes":"%s","total":%d}%s', d.mes, d.total, i < #self.serie_mensal and "," or "")
      end
      dados_json = dados_json .. "]"
      script(function()
        raw(string.format([[
          (function(){
            var dados=%s, chart=document.getElementById('hist-chart');
            if(!chart||dados.length===0) return;
            var max=Math.max.apply(null,dados.map(function(d){return d.total;}))||1;
            var html='<div class="dash-bars">';
            dados.forEach(function(d){
              var pct=Math.max(Math.round((d.total/max)*100),2);
              var mesAtual=%q;
              var ativo = d.mes===mesAtual;
              html+='<div class="dash-bar-col" title="'+d.mes+': '+d.total+' views">'+
                '<div class="dash-bar-wrap">'+
                '<div class="dash-bar" style="height:'+pct+'%%;background:'+(ativo?'var(--gold-color)':'var(--primary-color)')+'"></div>'+
                '</div><span class="dash-bar-label">'+d.mes.slice(5)+'</span></div>';
            });
            html+='</div>';
            chart.innerHTML=html;
          })();
        ]], dados_json, string.format("%04d-%02d", self.ano, self.mes)))
      end)
    end)
  end

  local sem_dados = (not self.top_noticias or #self.top_noticias == 0)
  if sem_dados then
    div({ class = "shadow-card mt-2" }, function()
      p({ class = "sem-dados" },
        "Sem dados de views para " .. self.mes_nome .. " " .. tostring(self.ano) .. ".")
      p({ style = "font-size:.85rem;color:var(--text-muted);margin-top:.5rem" },
        "Os dados de views são registrados diariamente conforme o portal recebe visitas.")
    end)
    return
  end

  -- Top notícias do mês
  div({ class = "shadow-card mt-2" }, function()
    h3("🏆 Top Notícias — " .. self.mes_nome)
    div({ class = "ranking-hist-lista" }, function()
      for pos, n in ipairs(self.top_noticias) do
        div({ class = "ranking-hist-item" }, function()
          div({ class = "ranking-hist-pos" .. (pos <= 3 and " ranking-hist-top" or "") }, function()
            if     pos == 1 then span("🥇")
            elseif pos == 2 then span("🥈")
            elseif pos == 3 then span("🥉")
            else   span({ class = "trending-num" }, tostring(pos)) end
          end)
          if n.imagem_url and n.imagem_url ~= "" then
            a({ href = "/noticias/" .. n.id, class = "ranking-hist-thumb" }, function()
              img({ src = n.imagem_url, alt = n.titulo, class = "ranking-hist-img" })
            end)
          end
          div({ class = "ranking-hist-info" }, function()
            div({ class = "noticia-header" }, function()
              span({ class = "tag" }, n.categoria)
              if n.jogo and n.jogo ~= "" then
                a({ href = "/jogos/" .. n.jogo, class = "tag tag-jogo" }, n.jogo)
              end
            end)
            h3(function()
              a({ href = "/noticias/" .. n.id }, n.titulo)
            end)
            span({ class = "ranking-hist-views" },
              "👁 " .. tostring(n.views_mes) .. " views neste mês")
          end)
        end)
      end
    end)
  end)

  -- Top categorias
  if self.top_categorias and #self.top_categorias > 0 then
    div({ class = "shadow-card mt-2" }, function()
      h3("🗂 Categorias em Destaque — " .. self.mes_nome)
      local max_views = self.top_categorias[1] and self.top_categorias[1].views_mes or 1
      div({ class = "ranking-hist-cats" }, function()
        for _, c in ipairs(self.top_categorias) do
          local pct = max_views > 0
            and math.floor((c.views_mes / max_views) * 100) or 0
          div({ class = "cat-hist-item" }, function()
            div({ class = "cat-hist-header" }, function()
              a({ href  = "/noticias?categoria=" .. c.categoria,
                  class = "tag" }, c.categoria)
              span({ class = "cat-hist-views" },
                "👁 " .. tostring(c.views_mes) .. " views · " ..
                tostring(c.noticias) .. " notícia(s)")
            end)
            div({ class = "cat-hist-barra-bg" }, function()
              div({ class = "cat-hist-barra",
                    style = "width:" .. pct .. "%" })
            end)
          end)
        end
      end)
    end)
  end
end)