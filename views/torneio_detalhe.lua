-- views/torneio_detalhe.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  local t  = self.torneio
  local st = ({ live="🔴 Ao Vivo", upcoming="⏳ Em Breve", finished="✅ Encerrado" })[t.status] or "⏳"

  div({ class = "shadow-card torneio-detalhe-hero" }, function()
    if t.imagem_url ~= "" then
      img({ src = t.imagem_url, alt = t.nome, class = "torneio-detalhe-capa" })
    end
    div({ class = "torneio-detalhe-header" }, function()
      div({ class = "torneio-meta" }, function()
        span({ class = "tag" }, st)
        if t.jogo ~= "" then
          span({ class = "tag tag-jogo" }, t.jogo)
        end
      end)
      h1({ class = "torneio-detalhe-titulo" }, t.nome)
      if t.premiacao ~= "" then
        p({ class = "torneio-premiacao" }, "🏆 Premiação: " .. t.premiacao)
      end
      div({ class = "torneio-datas" }, function()
        if t.data_inicio ~= "" then
          span({ class = "torneio-data" }, "📅 Início: " .. t.data_inicio)
        end
        if t.data_fim ~= "" then
          span({ class = "torneio-data" }, "🏁 Fim: " .. t.data_fim)
        end
      end)
      if t.descricao ~= "" then
        p({ class = "torneio-detalhe-desc" }, t.descricao)
      end
    end)
  end)

  -- Inscrição
  if t.status ~= "finished" then
    div({ class = "shadow-card mt-2 torneio-inscricao-card" }, function()
      if self.is_inscrito then
        div({ class = "torneio-ja-inscrito" }, function()
          span({ class = "torneio-inscrito-badge" }, "✅ Você está inscrito neste torneio!")
          a({ href = "/torneios", class = "btn-ver-mais" }, "← Voltar para torneios")
        end)
      else
        h3("📋 Inscrever-se")
        form({ method = "POST",
               action  = "/torneios/" .. t.id .. "/inscrever",
               class   = "admin-form" }, function()
          div({ class = "form-group" }, function()
            label({ ["for"] = "nome_time" }, "Nome do Time / Jogador")
            input({ type = "text", id = "nome_time", name = "nome_time",
                    placeholder = "Ex: Team Fluxo, Solo Player...",
                    maxlength   = "60" })
          end)
          button({ type = "submit", class = "btn-salvar" }, "🎮 Confirmar Inscrição")
        end)
      end
    end)
  end

  -- Lista de participantes
  div({ class = "shadow-card mt-2" }, function()
    h3("👥 Participantes (" .. #(self.participantes or {}) .. ")")
    if self.participantes and #self.participantes > 0 then
      div({ class = "participantes-grid" }, function()
        for i, p in ipairs(self.participantes) do
          div({ class = "participante-card" }, function()
            span({ class = "participante-pos" }, tostring(i))
            span({ class = "participante-avatar" }, p.avatar or "👤")
            div({ class = "participante-info" }, function()
              p({ class = "participante-time" },
                p.nome_time ~= "" and p.nome_time or "Solo Player")
              p({ class = "participante-data" },
                "Inscrito em " .. p.inscrito_em:sub(1, 10))
            end)
          end)
        end
      end)
    else
      p({ class = "sem-dados" }, "Nenhum participante inscrito ainda. Seja o primeiro!")
    end
  end)
end)