local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  local s   = self.stats or {}
  local niv = self.nivel_info or {}

  -- Hero
  div({ class = "shadow-card perfil-stats-hero" }, function()
    div({ class = "stats-hero-esquerda" }, function()
      span({ class = "stats-avatar" }, self.leitor_avatar or "👤")
      div(function()
        h2(self.leitor_nome or "Meu Perfil")
        if niv.nivel then
          p({ class = "stats-nivel" }, function()
            span({ class = "nivel-ico" }, niv.nivel.ico)
            span({ class = "nivel-nome" }, niv.nivel.nome)
            span({ class = "stats-xp" }, " · " .. tostring(niv.xp or 0) .. " XP")
          end)
          -- Barra de progresso para próximo nível
          div({ class = "stats-xp-bar-wrapper" }, function()
            div({ class  = "stats-xp-bar",
                  style  = "width:" .. tostring(niv.pct_proximo or 0) .. "%" })
          end)
          if niv.proximo then
            p({ class = "stats-xp-prox" },
              tostring(niv.pct_proximo or 0) .. "% para " ..
              niv.proximo.ico .. " " .. niv.proximo.nome)
          end
        end
      end)
    end)
    div({ class = "feed-acoes" }, function()
      a({ href = "/perfil",       class = "btn-ver-mais" }, "← Voltar ao perfil")
      a({ href = "/ranking/xp",   class = "btn-ver-mais" }, "🏅 Ranking →")
    end)
  end)

  -- Cards de métricas
  div({ class = "shadow-card mt-2" }, function()
    h3("📊 Resumo Geral")
    div({ class = "stats-cards-grid" }, function()
      local cards = {
        { ico="📰", num=tostring(s.total_lidas   or 0), label="Notícias lidas"   },
        { ico="🔖", num=tostring(s.total_favoritos or 0), label="Favoritos"     },
        { ico="💬", num=tostring(s.total_coments or 0), label="Comentários"      },
        { ico="🏅", num=tostring(s.total_conquistas or 0), label="Conquistas"   },
        { ico="🔥", num=tostring(s.streak or 0),        label="Dias seguidos"   },
      }
      for _, c in ipairs(cards) do
        div({ class = "stats-card" }, function()
          span({ class = "stats-card-ico" }, c.ico)
          span({ class = "stats-card-num" }, c.num)
          span({ class = "stats-card-lbl" }, c.label)
        end)
      end
    end)
  end)

  -- Gráfico de leituras por dia
  div({ class = "shadow-card mt-2" }, function()
    h3("📈 Leituras nos Últimos 30 Dias")
    if self.leituras_graf and #self.leituras_graf > 0 then
      div({ id = "grafico-leituras", class = "dashboard-chart" })
      local dados_json = "["
      for i, d in ipairs(self.leituras_graf) do
        dados_json = dados_json .. string.format(
          '{"data":"%s","total":%d}%s',
          d.data, d.total, i < #self.leituras_graf and "," or "")
      end
      dados_json = dados_json .. "]"
      script(function()
        raw(string.format([[
          (function(){
            var dados = %s;
            var chart = document.getElementById('grafico-leituras');
            if (!chart || dados.length === 0) return;
            var max = Math.max.apply(null, dados.map(function(d){return d.total;})) || 1;
            var html = '<div class="dash-bars">';
            dados.forEach(function(d) {
              var pct = Math.max(Math.round((d.total/max)*100), 4);
              var dia = d.data.slice(8); // DD
              html += '<div class="dash-bar-col" title="' + d.data + ': ' + d.total + ' leituras">'
                    + '<div class="dash-bar-wrap">'
                    + '<div class="dash-bar" style="height:' + pct + '%%"></div>'
                    + '</div>'
                    + '<span class="dash-bar-label">' + dia + '</span>'
                    + '</div>';
            });
            html += '</div>';
            chart.innerHTML = html;
          })();
        ]], dados_json))
      end)
    else
      p({ class = "sem-dados" }, "Ainda sem dados de leitura registrados. Comece a ler!")
    end
  end)

  -- Categorias preferidas
  if s.categorias and #s.categorias > 0 then
    div({ class = "shadow-card mt-2" }, function()
      h3("🗂 Categorias Favoritas")
      div({ class = "stats-cats" }, function()
        for _, c in ipairs(s.categorias) do
          div({ class = "stats-cat-item" }, function()
            div({ class = "stats-cat-header" }, function()
              a({ href = "/noticias?categoria=" .. c.categoria,
                  class = "tag" }, c.categoria)
              span({ class = "stats-cat-num" },
                tostring(c.total) .. " lida" .. (c.total > 1 and "s" or "") ..
                " · " .. tostring(c.pct) .. "%")
            end)
            div({ class = "stats-cat-barra-bg" }, function()
              div({ class = "stats-cat-barra",
                    style = "width:" .. tostring(c.pct) .. "%" })
            end)
          end)
        end
      end)
    end)
  end

  -- Dia mais ativo
  if s.dia_ativo then
    div({ class = "shadow-card mt-2 stats-dia-ativo" }, function()
      h3("⚡ Dia Mais Ativo")
      p({ class = "stats-dia-val" }, function()
        span({ style = "font-size:1.4rem" }, "📅 ")
        span({ style = "font-size:1.3rem;font-weight:800" }, s.dia_ativo.data)
        span({ class = "stats-xp" },
          " — " .. tostring(s.dia_ativo.total) .. " leitura" ..
          (s.dia_ativo.total > 1 and "s" or ""))
      end)
    end)
  end
end)