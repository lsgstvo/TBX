-- views/notificacoes.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "shadow-card notificacoes-hero" }, function()
    div({ class = "section-header" }, function()
      h2("🔔 Minhas Notificações")
      div({ class = "header-acoes" }, function()
        if #self.notificacoes > 0 then
          form({ method = "POST", action = "/notificacoes/ler-todas", style = "display:inline" }, function()
            button({ type = "submit", class = "btn-secondary" }, "Marcar todas como lidas")
          end)
          form({ method = "POST", action = "/notificacoes/limpar", style = "display:inline; margin-left: 10px" }, function()
            button({ type = "submit", class = "btn-perigo", 
                     onclick = "return confirm('Deseja limpar todas as notificações?')" }, "Excluir todas")
          end)
        end
      end)
    end)
    p({ class = "feed-desc" }, "Fique por dentro das suas conquistas, novidades e interações.")
  end)

  if #self.notificacoes == 0 then
    div({ class = "shadow-card mt-2 text-center py-5" }, function()
      span({ style = "font-size: 3rem; display: block; margin-bottom: 1rem; opacity: 0.3" }, "📭")
      p({ class = "text-muted" }, "Você não tem notificações no momento.")
      a({ href = "/", class = "btn-secondary mt-2" }, "Voltar para o Início")
    end)
  else
    div({ class = "notificacoes-lista mt-2" }, function()
      for _, n in ipairs(self.notificacoes) do
        local cls = "notificacao-card shadow-card" .. (n.lida == 0 and " notificacao-nova" or "")
        div({ class = cls, id = "notif-" .. n.id }, function()
          div({ class = "notif-header" }, function()
            div({ class = "notif-meta" }, function()
              local ico = ({ achievement="🏆", info="ℹ️", system="⚙️", alert="⚠️" })[n.tipo] or "🔔"
              span({ class = "notif-ico" }, ico)
              span({ class = "notif-tipo" }, n.tipo:upper())
              span({ class = "notif-data" }, n.criado_em:sub(1,16))
            end)
            if n.lida == 0 then
              button({ class = "btn-lida", onclick = "marcarLida(" .. n.id .. ")" }, "Marcar como lida")
            end
          end)
          h3({ class = "notif-titulo" }, n.titulo)
          p({ class = "notif-msg" }, n.mensagem)
          if n.link ~= "" then
            a({ href = n.link, class = "notif-link" }, "Ver mais →")
          end
        end)
      end
    end)
  end

  script(function()
    raw([[
      function marcarLida(id) {
        fetch('/notificacoes/' + id + '/lida', { method: 'POST' })
          .then(r => r.json())
          .then(data => {
            if (data.success) {
              const card = document.getElementById('notif-' + id);
              card.classList.remove('notificacao-nova');
              const btn = card.querySelector('.btn-lida');
              if (btn) btn.remove();
              
              // Atualiza o contador no header se existir
              const badge = document.getElementById('notificacoes-badge');
              if (badge) {
                let count = parseInt(badge.textContent) - 1;
                if (count <= 0) {
                  badge.remove();
                } else {
                  badge.textContent = count;
                }
              }
            }
          });
      }
    ]])
  end)
end)
