-- views/admin/admin_layout.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  html_5(function()
    head(function()
      meta({ charset = "UTF-8" })
      meta({ name = "viewport", content = "width=device-width, initial-scale=1.0" })
      title("Admin — Portal Gamer")
      script(function()
        raw([[
          (function() {
            var tema = localStorage.getItem('tema') || 'dark';
            document.documentElement.setAttribute('data-tema', tema);
          })();
        ]])
      end)
      link({ rel = "stylesheet", href = "/static/style.css" })
      link({ rel = "stylesheet", href = "/static/admin.css" })
      link({ href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;600;800&display=swap",
             rel  = "stylesheet" })
    end)
    body({ class = "admin-body" }, function()
      nav({ class = "admin-sidebar" }, function()
        div({ class = "admin-brand" }, function()
          span("⚙️"); span("Admin")
        end)
        ul(function()
          li(function() a({ href = "/admin" },               "📋 Painel") end)
          li(function() a({ href = "/admin/noticias/nova" }, "➕ Nova Notícia") end)
          li(function() a({ href = "/admin/jogos/novo" },    "🎮 Novo Jogo") end)
          li(function()
            -- Link de comentários com badge de notificação
            a({ href = "/admin#comentarios", id = "link-comentarios" }, function()
              raw('💬 Comentários <span id="badge-coment" class="badge-notif" style="display:none">0</span>')
            end)
          end)
          li(function() a({ href = "/api/docs" },            "📖 API Docs") end)
          li(function() a({ href = "/" },                    "🌐 Ver site") end)
          li(function()
            a({ href = "/admin/logout", class = "logout-link" }, "🚪 Sair")
          end)
          li(function()
            button({ id      = "tema-toggle",
                     class   = "tema-btn",
                     title   = "Alternar tema",
                     onclick = "toggleTema()",
                     style   = "width:100%; text-align:left; margin-top:1rem;" },
                   "☀️ Alternar Tema")
          end)
        end)
      end)

      main({ class = "admin-main" }, function()
        self:content_for("inner")
      end)

      script(function()
        raw([[
          // ── Toggle de tema ──────────────────────────────────────────
          (function() {
            var tema = localStorage.getItem('tema') || 'dark';
            var btn  = document.getElementById('tema-toggle');
            if (btn) btn.textContent =
              tema === 'dark' ? '\u2600\uFE0F Alternar Tema' : '\uD83C\uDF19 Alternar Tema';
          })();

          function toggleTema() {
            var atual = document.documentElement.getAttribute('data-tema') || 'dark';
            var novo  = atual === 'dark' ? 'light' : 'dark';
            document.documentElement.setAttribute('data-tema', novo);
            localStorage.setItem('tema', novo);
            var btn = document.getElementById('tema-toggle');
            if (btn) btn.textContent =
              novo === 'dark' ? '\u2600\uFE0F Alternar Tema' : '\uD83C\uDF19 Alternar Tema';
          }

          // ── Notificação de novos comentários ────────────────────────
          (function() {
            var CHAVE      = 'admin_coment_visto';
            var badge      = document.getElementById('badge-coment');
            if (!badge) return;

            function checarComentarios() {
              fetch('/admin/api/novos-comentarios')
                .then(function(r) { return r.json(); })
                .then(function(data) {
                  if (data.status !== 'ok') return;
                  var totalAtual  = data.total;
                  var totalVisto  = parseInt(localStorage.getItem(CHAVE) || '0', 10);
                  var novos       = totalAtual - totalVisto;

                  if (novos > 0) {
                    badge.textContent = novos > 99 ? '99+' : String(novos);
                    badge.style.display = 'inline-flex';
                  } else {
                    badge.style.display = 'none';
                  }
                })
                .catch(function() {});
            }

            // Marca como visto ao clicar no link
            var link = document.getElementById('link-comentarios');
            if (link) {
              link.addEventListener('click', function() {
                fetch('/admin/api/novos-comentarios')
                  .then(function(r) { return r.json(); })
                  .then(function(data) {
                    if (data.status === 'ok') {
                      localStorage.setItem(CHAVE, String(data.total));
                      badge.style.display = 'none';
                    }
                  });
              });
            }

            checarComentarios();
            // Verifica a cada 60 segundos
            setInterval(checarComentarios, 60000);
          })();
        ]])
      end)
    end)
  end)
end)