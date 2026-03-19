local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "shadow-card" }, function()
    h2("🎮 Próximos Lançamentos")
    p({ class = "lancamentos-desc" },
      "Fique por dentro dos jogos mais aguardados.")
  end)

  if self.lancamentos and #self.lancamentos > 0 then
    -- Separa futuros dos já lançados
    local hoje      = os.date("%Y-%m-%d")
    local futuros   = {}
    local lancados  = {}
    for _, l in ipairs(self.lancamentos) do
      if l.data_lancamento >= hoje then
        table.insert(futuros, l)
      else
        table.insert(lancados, l)
      end
    end

    if #futuros > 0 then
      div({ class = "shadow-card mt-2" }, function()
        h3("⏳ Em breve")
        div({ class = "lancamentos-grid" }, function()
          for _, l in ipairs(futuros) do
            div({ class = "lancamento-card" }, function()
              if l.imagem_url ~= "" then
                img({ src = l.imagem_url, alt = l.nome,
                      class = "lancamento-img" })
              else
                div({ class = "lancamento-placeholder" }, l.nome:sub(1,2))
              end
              div({ class = "lancamento-info" }, function()
                h3(function()
                  if l.site_url ~= "" then
                    a({ href = l.site_url, target = "_blank",
                        class = "lancamento-nome" }, l.nome)
                  else
                    span({ class = "lancamento-nome" }, l.nome)
                  end
                end)
                div({ class = "lancamento-meta" }, function()
                  if l.genero ~= "" then
                    span({ class = "tag" }, l.genero)
                  end
                  if l.plataformas ~= "" then
                    span({ class = "lancamento-plat" }, l.plataformas)
                  end
                end)
                if l.data_lancamento ~= "" then
                  div({ class = "lancamento-data" }, function()
                    span({ class = "lancamento-ico" }, "📅")
                    span(l.data_lancamento)
                    -- Calcula dias restantes
                    -- (SQLite retorna string YYYY-MM-DD)
                    span({ class = "lancamento-countdown",
                           ["data-date"] = l.data_lancamento })
                  end)
                end
                if l.descricao ~= "" then
                  p({ class = "lancamento-desc-txt" }, l.descricao)
                end
              end)
            end)
          end
        end)
      end)
    end

    if #lancados > 0 then
      div({ class = "shadow-card mt-2" }, function()
        h3("✅ Já lançados")
        div({ class = "lancamentos-grid lancamentos-lancados" }, function()
          for _, l in ipairs(lancados) do
            div({ class = "lancamento-card lancamento-passado" }, function()
              if l.imagem_url ~= "" then
                img({ src = l.imagem_url, alt = l.nome,
                      class = "lancamento-img" })
              else
                div({ class = "lancamento-placeholder" }, l.nome:sub(1,2))
              end
              div({ class = "lancamento-info" }, function()
                h3(function()
                  if l.site_url ~= "" then
                    a({ href = l.site_url, target = "_blank",
                        class = "lancamento-nome" }, l.nome)
                  else
                    span({ class = "lancamento-nome" }, l.nome)
                  end
                end)
                div({ class = "lancamento-meta" }, function()
                  if l.genero ~= "" then span({ class = "tag" }, l.genero) end
                  if l.plataformas ~= "" then
                    span({ class = "lancamento-plat" }, l.plataformas)
                  end
                  span({ class = "tag-jogo" }, "✅ Lançado em " .. l.data_lancamento)
                end)
              end)
            end)
          end
        end)
      end)
    end
  else
    div({ class = "shadow-card mt-2" }, function()
      p({ class = "sem-dados" }, "Nenhum lançamento cadastrado ainda.")
    end)
  end

  -- Script: countdown avançado (anos/meses/dias, atualiza à meia-noite)
  script(function()
    raw([[
      (function() {
        function calcularCountdown(dataStr) {
          var hoje = new Date(); hoje.setHours(0,0,0,0);
          var alvo = new Date(dataStr + 'T00:00:00');
          var diff = Math.round((alvo - hoje) / (1000*60*60*24));
          if (diff < 0)  return null;
          if (diff === 0) return { hoje: true };

          var anos = 0, meses = 0, dias = diff;
          if (dias >= 365) { anos = Math.floor(dias/365); dias = dias % 365; }
          if (dias >= 30)  { meses = Math.floor(dias/30); dias = dias % 30; }
          return { anos: anos, meses: meses, dias: dias };
        }

        function renderizar() {
          document.querySelectorAll('.lancamento-countdown').forEach(function(el) {
            var cd = calcularCountdown(el.dataset.date);
            if (!cd) { el.textContent = ''; return; }
            if (cd.hoje) {
              el.innerHTML = '<span class="cd-hoje">🎉 Hoje!</span>';
              return;
            }
            var partes = [];
            if (cd.anos  > 0) partes.push('<b>' + cd.anos  + '</b> ano'  + (cd.anos>1?'s':''));
            if (cd.meses > 0) partes.push('<b>' + cd.meses + '</b> mês'  + (cd.meses>1?'es':''));
            partes.push('<b>' + cd.dias + '</b> dia' + (cd.dias!==1?'s':''));
            el.innerHTML = '(' + partes.join(' ') + ')';
          });
        }

        renderizar();
        // Atualiza à meia-noite
        var agora = new Date();
        var msMeiaNoite = new Date(agora.getFullYear(), agora.getMonth(), agora.getDate()+1) - agora;
        setTimeout(function() { renderizar(); setInterval(renderizar, 86400000); }, msMeiaNoite);
      })();
    ]])
  end)
end)