-- views/layout.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  html_5(function()
    head(function()
      meta({ charset = "UTF-8" })
      meta({ name = "viewport", content = "width=device-width, initial-scale=1.0" })

      -- ── Título dinâmico ──────────────────────────────────────────────────
      local titulo_pag = self.og_titulo
        and (self.og_titulo .. " — Portal Gamer")
        or  "Portal Gamer"
      title(titulo_pag)

      -- ── Open Graph / SEO ─────────────────────────────────────────────────
      local og_titulo = self.og_titulo or "Portal Gamer"
      local og_desc   = self.og_descricao
        or "Fique por dentro das últimas notícias, rankings e atualizações do mundo dos games."
      local og_url    = self.og_url    or "http://localhost:8080"
      local og_img    = self.og_imagem or "http://localhost:8080/static/og-default.png"
      local og_tipo   = self.og_tipo   or "website"

      -- Meta SEO básico
      meta({ name = "description", content = og_desc })
      meta({ name = "robots",      content = "index, follow" })

      -- Open Graph
      meta({ property = "og:type",        content = og_tipo })
      meta({ property = "og:site_name",   content = "Portal Gamer" })
      meta({ property = "og:title",       content = og_titulo })
      meta({ property = "og:description", content = og_desc })
      meta({ property = "og:url",         content = og_url })
      meta({ property = "og:image",       content = og_img })
      meta({ property = "og:locale",      content = "pt_BR" })

      -- Twitter Card
      meta({ name = "twitter:card",        content = "summary_large_image" })
      meta({ name = "twitter:title",       content = og_titulo })
      meta({ name = "twitter:description", content = og_desc })
      meta({ name = "twitter:image",       content = og_img })

      -- Canonical
      link({ rel = "canonical", href = og_url })

      -- Tema: roda antes do CSS para evitar flash
      script(function()
        raw([[
          (function() {
            var tema = localStorage.getItem('tema') || 'dark';
            document.documentElement.setAttribute('data-tema', tema);
          })();
        ]])
      end)

      link({ rel = "stylesheet", href = "/static/style.css?v=3" })
      link({ rel   = "alternate", type  = "application/rss+xml",
             title = "Portal Gamer RSS", href = "/rss" })
      link({ href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;600;800&display=swap",
             rel  = "stylesheet" })
    end)

    body(function()
      header({ class = "site-header" }, function()
        div({ class = "container header-inner" }, function()
          a({ href = "/", class = "site-brand" }, "🎮 Portal Gamer")

          -- ── Busca global AJAX ──────────────────────────────────────────
          div({ class = "header-busca", id = "header-busca" }, function()
            input({ type        = "text",
                    id          = "busca-global",
                    class       = "busca-global-input",
                    placeholder = "Buscar notícias...",
                    autocomplete = "off" })
            div({ id = "busca-resultados", class = "busca-resultados" })
          end)

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

      script(function()
        raw([[
          // ── Toggle de tema ────────────────────────────────────────────
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

          // ── Busca global AJAX ─────────────────────────────────────────
          (function() {
            var input     = document.getElementById('busca-global');
            var resultados = document.getElementById('busca-resultados');
            if (!input) return;

            var timer = null;

            input.addEventListener('input', function() {
              clearTimeout(timer);
              var termo = input.value.trim();

              if (termo.length < 2) {
                resultados.innerHTML = '';
                resultados.classList.remove('aberto');
                return;
              }

              timer = setTimeout(function() {
                fetch('/api/busca?q=' + encodeURIComponent(termo))
                  .then(function(r) { return r.json(); })
                  .then(function(data) {
                    if (!data.data || data.data.length === 0) {
                      resultados.innerHTML =
                        '<div class="busca-item busca-vazio">Nenhum resultado encontrado.</div>';
                    } else {
                      resultados.innerHTML = data.data.map(function(n) {
                        return '<a class="busca-item" href="/noticias/' + n.id + '">' +
                          '<span class="busca-item-titulo">' + n.titulo + '</span>' +
                          '<span class="busca-item-meta">' +
                            '<span class="tag">' + n.categoria + '</span>' +
                            (n.jogo ? '<span class="tag tag-jogo">' + n.jogo + '</span>' : '') +
                          '</span>' +
                        '</a>';
                      }).join('');
                    }
                    resultados.classList.add('aberto');
                  })
                  .catch(function() {
                    resultados.innerHTML = '';
                    resultados.classList.remove('aberto');
                  });
              }, 280);
            });

            // Fecha ao clicar fora
            document.addEventListener('click', function(e) {
              if (!document.getElementById('header-busca').contains(e.target)) {
                resultados.classList.remove('aberto');
              }
            });

            // Fecha ao pressionar Escape
            input.addEventListener('keydown', function(e) {
              if (e.key === 'Escape') {
                resultados.classList.remove('aberto');
                input.blur();
              }
            });
          })();
        ]])
      end)
    end)
  end)
end)