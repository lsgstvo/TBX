local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  local mes_ant_ano = self.mes == 1 and self.ano - 1 or self.ano
  local mes_ant     = self.mes == 1 and 12 or self.mes - 1
  local mes_prox_ano = self.mes == 12 and self.ano + 1 or self.ano
  local mes_prox    = self.mes == 12 and 1 or self.mes + 1

  div({ class = "admin-section shadow-card" }, function()
    -- Cabeçalho do calendário
    div({ class = "cal-header" }, function()
      a({ href  = string.format("/admin/calendario?ano=%d&mes=%d", mes_ant_ano, mes_ant),
          class = "cal-nav-btn" }, "←")
      h2({ class = "cal-titulo" },
        self.mes_nome .. " " .. tostring(self.ano))
      a({ href  = string.format("/admin/calendario?ano=%d&mes=%d", mes_prox_ano, mes_prox),
          class = "cal-nav-btn" }, "→")
      a({ href  = string.format("/admin/calendario?ano=%d&mes=%d",
              os.date("*t").year, os.date("*t").month),
          class = "cal-hoje-btn" }, "Hoje")
    end)

    -- Legenda
    div({ class = "cal-legenda" }, function()
      div({ class = "cal-legenda-item" }, function()
        div({ class = "cal-dot cal-dot-publicada" })
        span("Publicada")
      end)
      div({ class = "cal-legenda-item" }, function()
        div({ class = "cal-dot cal-dot-agendada" })
        span("Agendada")
      end)
    end)

    -- Grid do calendário
    div({ class = "cal-grid" }, function()
      -- Cabeçalho dos dias da semana
      local dias_semana = { "Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb" }
      for _, d in ipairs(dias_semana) do
        div({ class = "cal-dia-header" }, d)
      end

      -- Células vazias antes do 1º
      local inicio = self.dia_semana_inicio or 0
      for _ = 1, inicio do
        div({ class = "cal-cel cal-cel-vazia" })
      end

      -- Dias do mês
      for dia = 1, self.dias_no_mes do
        local is_hoje = (dia == self.hoje_dia
          and self.mes == self.hoje_mes
          and self.ano == self.hoje_ano)
        local eventos_dia = self.eventos and self.eventos[dia] or {}
        local cls = "cal-cel" .. (is_hoje and " cal-hoje" or "")
          .. (#eventos_dia > 0 and " cal-tem-evento" or "")

        div({ class = cls }, function()
          span({ class = "cal-num" }, tostring(dia))
          if #eventos_dia > 0 then
            div({ class = "cal-eventos" }, function()
              for _, ev in ipairs(eventos_dia) do
                local tipo_cls = ev._tipo == "agendada"
                  and "cal-evento cal-evento-agendada"
                  or  "cal-evento cal-evento-publicada"
                a({ href  = "/admin/noticias/" .. ev.id .. "/editar",
                    class = tipo_cls,
                    title = ev.titulo }, function()
                  span(ev.titulo:sub(1, 22) ..
                    (ev.titulo:len() > 22 and "…" or ""))
                end)
              end
            end)
          end
        end)
      end
    end)
  end)

  -- Painel lateral: resumo do mês
  div({ class = "shadow-card mt-2" }, function()
    h3("📋 Resumo de " .. self.mes_nome)
    local total_pub  = self.publicadas and #self.publicadas or 0
    local total_agen = self.agendadas  and #self.agendadas  or 0
    div({ class = "cal-resumo-stats" }, function()
      div({ class = "stat-card" }, function()
        span({ class = "stat-numero" }, tostring(total_pub))
        span({ class = "stat-label" }, "Publicadas")
      end)
      div({ class = "stat-card" }, function()
        span({ class = "stat-numero" }, tostring(total_agen))
        span({ class = "stat-label" }, "Agendadas")
      end)
    end)

    -- Lista das agendadas
    if total_agen > 0 then
      h4({ style = "margin:1rem 0 .5rem" }, "⏰ Agendadas este mês")
      element("table", { class = "admin-table" }, function()
        thead(function()
          tr(function() th("Data/Hora"); th("Título"); th("Ação") end)
        end)
        tbody(function()
          for _, n in ipairs(self.agendadas) do
            tr(function()
              td({ class = "data-col agendada-data" }, n.publicar_em:sub(1, 16))
              td({ class = "titulo-col" }, n.titulo)
              td(function()
                a({ href  = "/admin/noticias/" .. n.id .. "/editar",
                    class = "btn-editar" }, "✏️")
              end)
            end)
          end
        end)
      end)
    end
  end)
end)