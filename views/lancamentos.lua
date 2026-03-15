-- views/lancamentos.lua
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

  -- Script: countdown em dias
  script(function()
    raw([[
      document.querySelectorAll('.lancamento-countdown').forEach(function(el) {
        var data  = new Date(el.dataset.date + 'T00:00:00');
        var hoje  = new Date(); hoje.setHours(0,0,0,0);
        var diff  = Math.round((data - hoje) / (1000*60*60*24));
        if (diff > 0)
          el.textContent = '(' + diff + ' dias)';
        else if (diff === 0)
          el.textContent = '(hoje!)';
      });
    ]])
  end)
end)