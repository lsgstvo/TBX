-- views/admin/admin_log.lua
local Widget = require("lapis.html").Widget

-- Mapa de ícones por tipo de ação
local icones = {
  login             = "🔑",
  logout            = "🚪",
  criar_noticia     = "➕",
  editar_noticia    = "✏️",
  deletar_noticia   = "🗑",
  criar_jogo        = "🎮",
  editar_jogo       = "✏️",
  deletar_jogo      = "🗑",
  aprovar_comentario= "✅",
  deletar_comentario= "🗑",
  criar_autor       = "✍️",
  editar_autor      = "✍️",
  deletar_autor     = "🗑",
  limpar_log        = "🧹",
  publicar_agendada = "⏰",
}

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    div({ class = "section-header" }, function()
      h2("📋 Log de Atividades")
      div({ class = "log-header-actions" }, function()
        if self.log_total and self.log_total > 0 then
          span({ class = "stat-badge" },
            tostring(self.log_total) .. " registros")
        end
        -- Formulário de limpeza
        form({ method  = "POST",
               action  = "/admin/log/limpar",
               class   = "log-limpar-form",
               onsubmit = "return confirm('Limpar logs antigos?')" }, function()
          element("select", { name = "dias", class = "log-select" }, function()
            option({ value = "30"  }, "Manter últimos 30 dias")
            option({ value = "60"  }, "Manter últimos 60 dias")
            option({ value = "90", selected = true }, "Manter últimos 90 dias")
          end)
          button({ type = "submit", class = "btn-deletar" }, "🧹 Limpar")
        end)
      end)
    end)

    if self.log_rows and #self.log_rows > 0 then
      element("table", { class = "admin-table" }, function()
        thead(function()
          tr(function()
            th(""); th("Ação"); th("Entidade"); th("Detalhe"); th("IP"); th("Quando")
          end)
        end)
        tbody(function()
          for _, entry in ipairs(self.log_rows) do
            tr(function()
              td({ class = "log-ico" }, icones[entry.acao] or "📌")
              td({ class = "log-acao" }, entry.acao:gsub("_", " "))
              td(function()
                span({ class = "tag" }, entry.entidade ~= "" and entry.entidade or "—")
              end)
              td({ class = "log-detalhe" },
                entry.detalhe ~= "" and entry.detalhe or "—")
              td({ class = "log-ip",
                   style = "font-size:.78rem;font-family:monospace;color:var(--text-muted)" },
                entry.ip)
              td({ class = "data-col" }, entry.criado_em:sub(1, 16))
            end)
          end
        end)
      end)

      -- Paginação
      if self.log_total_pag and self.log_total_pag > 1 then
        div({ class = "paginacao paginacao-sm" }, function()
          if self.log_pagina > 1 then
            a({ href  = "/admin/log?pagina=" .. (self.log_pagina - 1),
                class = "pag-btn" }, "← Anterior")
          end
          for i = 1, self.log_total_pag do
            if i == self.log_pagina then
              span({ class = "pag-btn pag-atual" }, tostring(i))
            else
              a({ href  = "/admin/log?pagina=" .. i,
                  class = "pag-btn" }, tostring(i))
            end
          end
          if self.log_pagina < self.log_total_pag then
            a({ href  = "/admin/log?pagina=" .. (self.log_pagina + 1),
                class = "pag-btn" }, "Próxima →")
          end
        end)
      end
    else
      p({ class = "sem-dados" }, "Nenhuma atividade registrada ainda.")
    end
  end)
end)