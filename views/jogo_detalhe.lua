-- views/jogo_detalhe.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  local aval = self.avaliacao or { media = 0, total = 0 }

  -- Card principal do jogo
  div({ class = "shadow-card jogo-detalhe" }, function()
    div({ class = "jogo-header" }, function()
      if self.jogo.imagem_url and self.jogo.imagem_url ~= "" then
        div({ class = "jogo-capa" }, function()
          img({ src = self.jogo.imagem_url, alt = self.jogo.nome, class = "jogo-img" })
        end)
      else
        div({ class = "jogo-capa jogo-capa-placeholder" }, function()
          span("#" .. tostring(self.jogo.posicao))
        end)
      end

      div({ class = "jogo-info" }, function()
        h2(self.jogo.nome)
        div({ class = "jogo-meta" }, function()
          span({ class = "tag" }, self.jogo.genero)
          span({ class = "jogo-players" }, "👥 " .. self.jogo.players)
          span({ class = "jogo-rank" }, "🏆 #" .. tostring(self.jogo.posicao))
        end)
        if self.jogo.descricao and self.jogo.descricao ~= "" then
          p({ class = "jogo-descricao" }, self.jogo.descricao)
        end

        -- Avaliação
        div({ class = "jogo-avaliacao" }, function()
          div({ class = "estrelas-display" }, function()
            local media = tonumber(aval.media) or 0
            for i = 1, 5 do
              local cls = i <= math.floor(media) and "estrela cheia"
                       or (i - 0.5 <= media    and "estrela meia"
                                                or  "estrela vazia")
              span({ class = cls }, "★")
            end
            span({ class = "aval-info" },
              string.format(" %.1f  (%d avaliação%s)",
                media, aval.total, aval.total == 1 and "" or "ões"))
          end)

          -- Widget de votar
          div({ id = "votar-box", class = "votar-box" }, function()
            p({ class = "votar-label" }, "Avalie este jogo:")
            div({ class = "estrelas-input", id = "estrelas-input" }, function()
              for i = 1, 5 do
                span({ class    = "estrela-btn",
                       ["data-nota"] = tostring(i),
                       onclick  = "votar(" .. i .. ")" }, "★")
              end
            end)
            span({ id = "votar-msg", class = "votar-msg" })
          end)
        end)
      end)
    end)
  end)

  -- Notícias relacionadas
  div({ class = "shadow-card mt-2" }, function()
    h3("📰 Notícias sobre " .. self.jogo.nome)
    if self.noticias and #self.noticias > 0 then
      div({ class = "noticias-grid" }, function()
        for _, n in ipairs(self.noticias) do
          article({ class = "noticia-card" .. (n.destaque == 1 and " card-destaque" or "") }, function()
            div({ class = "noticia-header" }, function()
              a({ href = "/noticias?categoria=" .. n.categoria, class = "tag" }, n.categoria)
              if n.destaque == 1 then span({ class = "badge-destaque" }, "⭐") end
              span({ class = "data-noticia" }, n.criado_em:sub(1, 10))
            end)
            h3(function() a({ href = "/noticias/" .. n.id }, n.titulo) end)
            p({ class = "noticia-resumo" }, n.conteudo:sub(1, 120) .. "...")
            a({ href = "/noticias/" .. n.id, class = "btn-ler-mais" }, "Ler mais →")
          end)
        end
      end)
    else
      p({ class = "sem-dados" }, "Nenhuma notícia sobre este jogo ainda.")
    end
  end)

  div({ class = "mt-2" }, function()
    a({ href = "/ranking", class = "btn-voltar" }, "← Voltar para o Ranking")
  end)

  -- Script de avaliação
  script(function()
    raw(string.format([[
      var JOGO_NOME = %s;

      // Hover nas estrelas
      var btns = document.querySelectorAll('.estrela-btn');
      btns.forEach(function(btn, idx) {
        btn.addEventListener('mouseenter', function() {
          btns.forEach(function(b, i) {
            b.style.color = i <= idx ? '#f59e0b' : '#334155';
          });
        });
        btn.addEventListener('mouseleave', function() {
          btns.forEach(function(b) { b.style.color = ''; });
        });
      });

      function votar(nota) {
        var msg = document.getElementById('votar-msg');
        msg.textContent = '⏳ Enviando...';
        fetch('/jogos/' + encodeURIComponent(JOGO_NOME) + '/avaliar', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: 'nota=' + nota
        })
        .then(function(r) { return r.json(); })
        .then(function(data) {
          if (data.status === 'ok') {
            msg.textContent = '✅ Obrigado! Média: ' + data.media + ' (' + data.total + ' votos)';
            msg.style.color = '#4ade80';
            document.getElementById('votar-box').style.opacity = '0.6';
            document.getElementById('votar-box').style.pointerEvents = 'none';
          } else {
            msg.textContent = '❌ ' + (data.mensagem || 'Erro.');
            msg.style.color = '#fb7185';
          }
        })
        .catch(function() {
          msg.textContent = '❌ Erro de conexão.';
          msg.style.color = '#fb7185';
        });
      }
    ]], string.format("%q", self.jogo.nome)))
  end)
end)