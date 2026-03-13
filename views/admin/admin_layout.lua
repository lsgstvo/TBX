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
      link({ href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;600;800&display=swap", rel = "stylesheet" })
    end)
    body({ class = "admin-body" }, function()
      nav({ class = "admin-sidebar" }, function()
        div({ class = "admin-brand" }, function()
          span("⚙️"); span("Admin")
        end)
        ul(function()
          li(function() a({ href = "/admin" },                  "📋 Painel")       end)
          li(function() a({ href = "/admin/noticias/nova" },    "➕ Nova Notícia")  end)
          li(function() a({ href = "/admin/jogos/novo" },       "🎮 Novo Jogo")     end)
          li(function() a({ href = "/" },                       "🌐 Ver site")      end)
          li(function() a({ href = "/admin/logout", class = "logout-link" }, "🚪 Sair") end)
          li(function() 
            button({ id      = "tema-toggle",
                     class   = "tema-btn",
                     title   = "Alternar tema",
                     onclick = "toggleTema()",
                     style   = "width: 100%; text-align: left; margin-top: 1rem;" }, "☀️ Alternar Tema")
          end)
        end)
      end)
      main({ class = "admin-main" }, function()
        self:content_for("inner")
      end)

      script(function()
        raw([[
        (function() {
          var tema = localStorage.getItem('tema') || 'dark';
          var btn  = document.getElementById('tema-toggle');
          if (btn) btn.textContent = tema === 'dark' ? '☀️ Alternar Tema' : '🌙 Alternar Tema';
        })();

        function toggleTema() {
          var atual = document.documentElement.getAttribute('data-tema') || 'dark';
          var novo  = atual === 'dark' ? 'light' : 'dark';
          document.documentElement.setAttribute('data-tema', novo);
          localStorage.setItem('tema', novo);
          var btn = document.getElementById('tema-toggle');
          if (btn) btn.textContent = novo === 'dark' ? '☀️ Alternar Tema' : '🌙 Alternar Tema';
        }
        ]])
      end)
    end)
  end)
end)