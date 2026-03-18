-- views/torneios.lua
local Widget = require("lapis.html").Widget

local STATUS_LABEL = {
  live     = { label = "🔴 Ao Vivo",   cls = "torneio-live"     },
  upcoming = { label = "⏳ Em Breve",  cls = "torneio-upcoming" },
  finished = { label = "✅ Encerrado", cls = "torneio-finished" },
}

return Widget:extend(function(self)
  div({ class = "shadow-card torneios-hero" }, function()
    h2("🏆 Torneios de E-Sports")
    p({ class = "torneios-desc" },
      "Campeonatos, torneios e competições do mundo dos games.")
    a({ href = "/ranking/xp", class = "btn-ver-mais" },
      "🏅 Ver ranking de leitores →")
  end)

  if self.torneios and #self.torneios > 0 then
    -- Separa por status
    local live, upcoming, finished = {}, {}, {}
    for _, t in ipairs(self.torneios) do
      if t.status == "live"     then table.insert(live, t)
      elseif t.status == "upcoming" then table.insert(upcoming, t)
      else table.insert(finished, t) end
    end

    local function render_grupo(lista, titulo)
      if #lista == 0 then return end
      div({ class = "shadow-card mt-2" }, function()
        h3(titulo)
        div({ class = "torneios-grid" }, function()
          for _, t in ipairs(lista) do
            local st = STATUS_LABEL[t.status] or STATUS_LABEL.upcoming
            div({ class = "torneio-card " .. st.cls }, function()
              if t.imagem_url ~= "" then
                a({ href = "/torneios/" .. t.id }, function()
                  img({ src = t.imagem_url, alt = t.nome,
                        class = "torneio-img" })
                end)
              end
              div({ class = "torneio-info" }, function()
                div({ class = "torneio-meta" }, function()
                  span({ class = "torneio-status-badge " .. st.cls .. "-badge" },
                    st.label)
                  if t.jogo ~= "" then
                    span({ class = "tag tag-jogo" }, t.jogo)
                  end
                end)
                h3(function()
                  a({ href = "/torneios/" .. t.id,
                      class = "torneio-nome" }, t.nome)
                end)
                if t.premiacao ~= "" then
                  p({ class = "torneio-premiacao" }, "🏆 " .. t.premiacao)
                end
                div({ class = "torneio-datas" }, function()
                  if t.data_inicio ~= "" then
                    span({ class = "torneio-data" }, "📅 " .. t.data_inicio)
                  end
                  if t.data_fim ~= "" then
                    span({ class = "torneio-data" }, "→ " .. t.data_fim)
                  end
                end)
                div({ class = "torneio-footer" }, function()
                  span({ class = "torneio-inscritos" },
                    "👥 " .. tostring(t.total_inscritos or 0) .. " inscritos")
                  if t.status ~= "finished" then
                    if self.inscricoes and self.inscricoes[t.id] then
                      span({ class = "torneio-inscrito-badge" }, "✅ Inscrito")
                    else
                      a({ href  = "/torneios/" .. t.id,
                          class = "btn-inscrever" }, "Inscrever-se →")
                    end
                  end
                end)
              end)
            end)
          end
        end)
      end)
    end

    render_grupo(live,     "🔴 Acontecendo Agora")
    render_grupo(upcoming, "⏳ Em Breve")
    render_grupo(finished, "✅ Encerrados")
  else
    div({ class = "shadow-card mt-2" }, function()
      p({ class = "sem-dados" }, "Nenhum torneio cadastrado ainda.")
      p({ style = "font-size:.85rem;color:var(--text-muted);margin-top:.5rem" },
        "Torneios podem ser criados em Admin → Torneios.")
    end)
  end
end)