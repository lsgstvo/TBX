local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    div({ class = "section-header" }, function()
      h2("👥 Leitores Registrados")
      span({ class = "stat-badge" }, tostring(self.total or 0) .. " leitores")
    end)

    if self.leitores and #self.leitores > 0 then
      element("table", { class = "admin-table" }, function()
        thead(function()
          tr(function()
            th("Leitor"); th("Nível"); th("XP")
            th("Lidas"); th("Favs"); th("Coments"); th("Conquistas")
          end)
        end)
        tbody(function()
          for i, l in ipairs(self.leitores) do
            local pos = ((self.pagina or 1) - 1) * 20 + i
            local niv = l.nivel_info or { nivel = { ico="🌱", nome="Novato" } }
            tr(function()
              -- Leitor
              td(function()
                div({ class = "leitor-cell" }, function()
                  span({ class = "leitor-avatar" }, l.avatar or "👤")
                  div(function()
                    span({ class = "leitor-nome" },
                      l.nome ~= "" and l.nome or ("Leitor #" .. l.leitor_id:sub(1,8)))
                    span({ class = "leitor-id" }, l.leitor_id:sub(1,12) .. "...")
                  end)
                end)
              end)
              -- Nível
              td(function()
                div({ class = "nivel-cell" }, function()
                  span({ class = "nivel-ico-sm" }, niv.nivel.ico)
                  span({ class = "nivel-nome-sm" }, niv.nivel.nome)
                  -- Barra de XP
                  div({ class = "nivel-barra-mini" }, function()
                    div({ class  = "nivel-barra-fill-mini",
                          style  = "width:" .. tostring((l.nivel_info or {}).pct_proximo or 0) .. "%" })
                  end)
                end)
              end)
              -- XP
              td({ style = "font-weight:700;color:var(--primary-color)" },
                tostring(l.xp or 0))
              -- Stats
              td({ class = "views-col" }, tostring(l.total_lidas   or 0))
              td({ class = "views-col" }, tostring(l.total_favoritos or 0))
              td({ class = "views-col" }, tostring(l.total_coments or 0))
              td({ class = "views-col" }, tostring(l.total_conquistas or 0))
            end)
          end
        end)
      end)

      -- Paginação
      if (self.total_pag or 1) > 1 then
        div({ class = "paginacao paginacao-sm" }, function()
          if self.pagina > 1 then
            a({ href  = "/admin/leitores?pagina=" .. (self.pagina-1),
                class = "pag-btn" }, "←")
          end
          for i = 1, self.total_pag do
            if i == self.pagina then
              span({ class = "pag-btn pag-atual" }, tostring(i))
            else
              a({ href  = "/admin/leitores?pagina=" .. i,
                  class = "pag-btn" }, tostring(i))
            end
          end
          if self.pagina < self.total_pag then
            a({ href  = "/admin/leitores?pagina=" .. (self.pagina+1),
                class = "pag-btn" }, "→")
          end
        end)
      end
    else
      p({ class = "sem-dados" }, "Nenhum leitor registrado ainda.")
    end
  end)
end)