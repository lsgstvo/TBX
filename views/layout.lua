-- views/layout.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  html_5(function()
    head(function()
      meta({ charset = "UTF-8" })
      meta({ name = "viewport", content = "width=device-width, initial-scale=1.0" })
      title("Portal Gamer")
      -- Roda ANTES do CSS para evitar flash de tema errado
      script(function()
        raw([[
        (function() {
          var tema = localStorage.getItem('tema') || 'dark';
          document.documentElement.setAttribute('data-tema', tema);
        })();
        ]])
      end)
      link({ rel = "stylesheet", href = "/static/style.css?v=2" })
      link({ rel   = "alternate", type  = "application/rss+xml",
             title = "Portal Gamer RSS", href = "/rss" })
      link({ href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;600;800&display=swap",
             rel  = "stylesheet" })
    end)
    body(function()
      header({ class = "site-header" }, function()
        div({ class = "container header-inner" }, function()
          a({ href = "/", class = "site-brand" }, "🎮 Portal Gamer")
          nav(function()
            a({ href = "/" },         "Início")
            a({ href = "/noticias" }, "Notícias")
            a({ href = "/ranking" },  "Ranking")
            a({ href = "/sobre" },    "Sobre")
            a({ href = "/admin" },    "Admin")
          end)
          button({ id      = "tema-toggle",
                   class   = "tema-btn",
                   title   = "Alternar tema",
                   onclick = "toggleTema()" }, "☀️")
        end)
      end)

      main({ class = "container content-area" }, function()
        self:content_for("inner")
      end)

      footer({ class = "site-footer" }, function()
        div({ class = "container footer-inner" }, function()
          p("© 2026 Portal Gamer — Desenvolvido em Lua com Lapis")
          div({ class = "footer-links" }, function()
            a({ href = "/sobre" }, "Sobre")
            a({ href = "/rss" },   "RSS Feed")
            a({ href = "/admin" }, "Admin")
          end)
        end)
      end)

      -- Script no fim do body: atualiza ícone e expõe toggleTema()
      script(function()
        raw([[
        (function() {
          var tema = localStorage.getItem('tema') || 'dark';
          var btn  = document.getElementById('tema-toggle');
          if (btn) btn.textContent = tema === 'dark' ? '\u2600\uFE0F' : '\uD83C\uDF19';
        })();

        function toggleTema() {
          var atual = document.documentElement.getAttribute('data-tema') || 'dark';
          var novo  = atual === 'dark' ? 'light' : 'dark';
          document.documentElement.setAttribute('data-tema', novo);
          localStorage.setItem('tema', novo);
          var btn = document.getElementById('tema-toggle');
          if (btn) btn.textContent = novo === 'dark' ? '\u2600\uFE0F' : '\uD83C\uDF19';
        }
        ]])
      end)
    end)
  end)
end)