-- views/admin/admin_performance.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    div({ class = "section-header" }, function()
      h2("⚡ Performance")
      div({ class = "perf-header-acoes" }, function()
        -- Seletor de janela
        div({ class = "janela-selector" }, function()
          for _, h in ipairs({ {1,"1h"},{6,"6h"},{24,"24h"},{168,"7d"} }) do
            a({ href  = "/admin/performance?h=" .. h[1],
                class = "janela-btn" .. (self.horas == h[1] and " janela-ativa" or "") },
              h[2])
          end
        end)
        -- Limpar
        form({ method = "POST", action = "/admin/performance/limpar",
               onsubmit = "return confirm('Limpar logs antigos?')",
               style = "display:inline" }, function()
          input({ type = "hidden", name = "horas", value = "168" })
          button({ type = "submit", class = "btn-deletar",
                   style = "font-size:.82rem" }, "🧹 Limpar 7d+")
        end)
      end)
    end)

    -- Gráfico de requests por hora
    if self.por_hora and #self.por_hora > 0 then
      div({ class = "perf-chart-section" }, function()
        h3("📈 Requests por Hora (24h)")
        div({ id = "perf-chart", class = "dash-bars perf-bars" })
        local dados_json = "["
        for i, d in ipairs(self.por_hora) do
          dados_json = dados_json .. string.format(
            '{"hora":"%s","req":%d,"ms":%s}%s',
            d.hora, d.requests, tostring(d.avg_ms or 0),
            i < #self.por_hora and "," or ""
          )
        end
        dados_json = dados_json .. "]"
        script(function()
          raw(string.format([[
            (function(){
              var dados=%s;
              var chart=document.getElementById('perf-chart');
              if(!chart||dados.length===0) return;
              var maxReq=Math.max.apply(null,dados.map(function(d){return d.req;}))||1;
              var html='';
              dados.forEach(function(d){
                var pct=Math.max(Math.round((d.req/maxReq)*100),2);
                var cor = d.ms > 500 ? '#f43f5e' : d.ms > 200 ? '#f59e0b' : '#6366f1';
                html+='<div class="dash-bar-col" title="'+d.hora+'h: '+d.req+' req, '+d.ms+'ms avg">'+
                  '<div class="dash-bar-wrap"><div class="dash-bar" style="height:'+pct+'%%;background:'+cor+'"></div></div>'+
                  '<span class="dash-bar-label">'+d.hora+'h</span></div>';
              });
              chart.innerHTML=html;
            })();
          ]], dados_json))
        end)
      end)
    end

    -- Tabela de rotas
    if self.stats and #self.stats > 0 then
      h3({ style = "margin:1.5rem 0 .8rem" },
        "🗺 Rotas — últimas " .. tostring(self.horas) .. "h")
      element("table", { class = "admin-table" }, function()
        thead(function()
          tr(function()
            th("Rota"); th("Requests"); th("Avg ms"); th("Max ms")
            th("Erros"); th("Lentas >500ms")
          end)
        end)
        tbody(function()
          for _, s in ipairs(self.stats) do
            local avg = tonumber(s.avg_ms) or 0
            local cor = avg > 500 and "color:#f43f5e"
                     or avg > 200 and "color:#f59e0b" or ""
            tr(function()
              td({ style = "font-family:monospace;font-size:.82rem" }, s.rota)
              td({ class = "views-col" }, tostring(s.requests))
              td({ style = cor .. ";font-weight:700" }, tostring(s.avg_ms) .. "ms")
              td({ class = "data-col" }, tostring(s.max_ms) .. "ms")
              td({ style = (tonumber(s.erros) or 0) > 0 and "color:#f43f5e;font-weight:700" or "" },
                tostring(s.erros))
              td({ style = (tonumber(s.lentas) or 0) > 0 and "color:#f59e0b" or "" },
                tostring(s.lentas))
            end)
          end
        end)
      end)
    else
      p({ class = "sem-dados" }, "Nenhum dado de performance ainda. Navegue pelo site para gerar dados.")
    end

    -- Erros recentes
    if self.erros_recentes and #self.erros_recentes > 0 then
      h3({ style = "margin:1.5rem 0 .8rem" }, "🚨 Erros Recentes")
      element("table", { class = "admin-table" }, function()
        thead(function()
          tr(function() th("Rota"); th("Status"); th("ms"); th("Quando") end)
        end)
        tbody(function()
          for _, e in ipairs(self.erros_recentes) do
            tr(function()
              td({ style = "font-family:monospace;font-size:.82rem" }, e.rota)
              td({ style = "color:#f43f5e;font-weight:700" }, tostring(e.status))
              td(tostring(e.ms) .. "ms")
              td({ class = "data-col" }, e.criado_em:sub(1, 16))
            end)
          end
        end)
      end)
    end
  end)
end)