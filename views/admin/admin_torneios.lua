local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    div({ class = "section-header" }, function()
      h2("🏆 Torneios de E-Sports")
      div({ style = "display:flex;gap:.5rem" }, function()
        a({ href = "/torneios", target = "_blank", class = "btn-editar" }, "👁 Ver público")
        a({ href = "/admin/torneios/novo", class = "btn-novo" }, "+ Novo Torneio")
      end)
    end)
    if self.torneios and #self.torneios > 0 then
      element("table", { class = "admin-table" }, function()
        thead(function()
          tr(function()
            th("Nome"); th("Jogo"); th("Status"); th("Inscritos"); th("Datas"); th("Ações")
          end)
        end)
        tbody(function()
          local STATUS = { live="🔴 Ao Vivo", upcoming="⏳ Em Breve", finished="✅ Encerrado" }
          for _, t in ipairs(self.torneios) do
            tr(function()
              td({ class = "titulo-col" }, t.nome)
              td(function()
                if t.jogo ~= "" then span({ class = "tag tag-jogo" }, t.jogo) end
              end)
              td(STATUS[t.status] or t.status)
              td({ class = "views-col" }, "👥 " .. tostring(t.total_inscritos or 0))
              td({ class = "data-col", style = "font-size:.78rem" }, function()
                if t.data_inicio ~= "" then p(t.data_inicio) end
                if t.data_fim    ~= "" then p("→ " .. t.data_fim) end
              end)
              td({ class = "acoes-col" }, function()
                a({ href = "/torneios/" .. t.id, target="_blank", class = "btn-editar" }, "👁")
                a({ href = "/admin/torneios/" .. t.id .. "/editar", class = "btn-editar" }, "✏️")
                form({ method="POST", action="/admin/torneios/" .. t.id .. "/deletar",
                       onsubmit="return confirm('Deletar torneio?')",
                       style="display:inline" }, function()
                  button({ type="submit", class="btn-deletar" }, "🗑")
                end)
              end)
            end)
          end
        end)
      end)
    else
      p({ class = "sem-dados" }, "Nenhum torneio cadastrado.")
    end
  end)
end)