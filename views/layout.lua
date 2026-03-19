local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  html_5(function()
    head(function()
      meta({ charset = "UTF-8" })
      meta({ name = "viewport", content = "width=device-width, initial-scale=1.0" })
      local titulo_pag = self.og_titulo
        and (self.og_titulo .. " — Portal Gamer") or "Portal Gamer"
      title(titulo_pag)
      local og_titulo = self.og_titulo     or "Portal Gamer"
      local og_desc   = self.og_descricao
        or "Fique por dentro das últimas notícias, rankings e atualizações do mundo dos games."
      local og_url    = self.og_url    or "http://localhost:8080"
      local og_img    = self.og_imagem or "http://localhost:8080/static/og-default.png"
      local og_tipo   = self.og_tipo   or "website"
      meta({ name = "description", content = og_desc })
      meta({ name = "robots",      content = "index, follow" })
      meta({ property = "og:type",        content = og_tipo })
      meta({ property = "og:site_name",   content = "Portal Gamer" })
      meta({ property = "og:title",       content = og_titulo })
      meta({ property = "og:description", content = og_desc })
      meta({ property = "og:url",         content = og_url })
      meta({ property = "og:image",       content = og_img })
      meta({ property = "og:locale",      content = "pt_BR" })
      meta({ name = "twitter:card",        content = "summary_large_image" })
      meta({ name = "twitter:title",       content = og_titulo })
      meta({ name = "twitter:description", content = og_desc })
      meta({ name = "twitter:image",       content = og_img })
      link({ rel = "canonical", href = og_url })
      -- Aplica tema antes do CSS para evitar flash branco
      script(function()
        raw([[
          (function() {
            var c = JSON.parse(localStorage.getItem('custom_tema') || '{}');
            var tema = c.tema || localStorage.getItem('tema') || 'dark';
            document.documentElement.setAttribute('data-tema', tema);
            if (c.accent) document.documentElement.style.setProperty('--primary-color', c.accent);
            if (c.fonte)  document.documentElement.style.fontSize = c.fonte;
          })();
        ]])
      end)
      link({ rel = "stylesheet", href = "/static/style.css?v=5" })
      link({ rel = "alternate", type = "application/rss+xml",
             title = "Portal Gamer RSS", href = "/rss" })
      link({ rel = "manifest", href = "/manifest.json" })
      meta({ name = "theme-color", content = "#6366f1" })
      meta({ name = "mobile-web-app-capable", content = "yes" })
      meta({ name = "apple-mobile-web-app-capable", content = "yes" })
      meta({ name = "apple-mobile-web-app-status-bar-style", content = "black-translucent" })
      meta({ name = "apple-mobile-web-app-title", content = "Portal Gamer" })
      link({ href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;600;800&display=swap",
             rel  = "stylesheet" })
    end)

    body(function()

      -- ── Header: UMA linha ─────────────────────────────────────────────────
      header({ class = "site-header" }, function()
        div({ class = "container header-inner" }, function()
          button({ id = "drawer-toggle", class = "drawer-toggle-btn",
                   title = "Menu", onclick = "toggleDrawer()" }, "☰")

          a({ href = "/", class = "site-brand" }, function()
            img({ src = "/static/icon-192.png", class = "brand-logo", alt = "Logo" })
            span("Portal Gamer")
          end)

          div({ class = "header-actions" }, function()
            div({ class = "header-busca visible", id = "header-busca" }, function()
              button({ id = "voice-btn", class = "search-toggle-btn voice-btn",
                       title = "Busca por voz", onclick = "iniciarBuscaVoz()" }, "🎤")
              input({ type = "text", id = "busca-global", class = "busca-global-input",
                      placeholder = "Buscar...", autocomplete = "off" })
              div({ id = "busca-resultados", class = "busca-resultados" })
            end)

            if self.leitor_nivel_info then
              local niv = self.leitor_nivel_info
              div({ class = "header-xp-badge",
                    title = string.format("Nível %d: %s (%d/%d XP)",
                      niv.nivel.nivel, niv.nivel.nome,
                      niv.xp, niv.proximo and niv.proximo.xp_min or niv.xp) }, function()
                span({ class = "xp-ico" }, niv.nivel.ico)
                span({ class = "xp-num" }, tostring(niv.nivel.nivel))
                div({ class = "xp-progress-mini" }, function()
                  div({ class = "xp-bar-mini",
                        style = "width:" .. niv.pct_proximo .. "%" })
                end)
              end)
            end

            a({ href = "/notificacoes", class = "header-icon-btn",
                title = "Notificações" }, function()
              text("🔔")
              if self.notificacoes_count and self.notificacoes_count > 0 then
                span({ id = "notificacoes-badge", class = "header-badge" },
                  tostring(self.notificacoes_count))
              end
            end)

            button({ id = "tema-toggle", class = "tema-btn",
                     title = "Alternar claro/escuro",
                     onclick = "toggleTema()" }, "☀️")

            button({ id = "custom-tema-btn", class = "tema-btn",
                     title = "Personalizar cores",
                     onclick = "toggleCustomTema()" }, "🎨")
          end)
        end)
      end)

      -- ── Painel flutuante de tema — OCULTO POR PADRÃO ─────────────────────
      -- Aparece apenas ao clicar no botão 🎨
      div({ id = "custom-tema-panel", class = "custom-tema-panel" }, function()
        div({ class = "custom-tema-header" }, function()
          span("🎨 Personalizar Tema")
          button({ class = "custom-tema-fechar",
                   onclick = "toggleCustomTema()" }, "✕")
        end)
        div({ class = "custom-tema-body" }, function()
          p({ class = "custom-tema-label" }, "Esquema de cores:")
          div({ id = "tema-presets", class = "tema-presets" })
          p({ class = "custom-tema-label", style = "margin-top:.8rem" },
            "Cor de destaque:")
          div({ class = "tema-accent-row" }, function()
            input({ type = "color", id = "accent-picker", class = "accent-picker",
                    value = "#6366f1", oninput = "aplicarAccent(this.value)" })
            button({ class = "accent-reset", onclick = "resetAccent()" }, "Resetar")
          end)
          p({ class = "custom-tema-label", style = "margin-top:.8rem" },
            "Tamanho da fonte:")
          div({ class = "fonte-row" }, function()
            for _, f in ipairs({ "14px", "16px", "18px", "20px" }) do
              button({ class = "fonte-btn", ["data-size"] = f,
                       onclick = "aplicarFonte('" .. f .. "')" }, f)
            end
          end)
        end)
      end)

      -- ── Drawer lateral ────────────────────────────────────────────────────
      div({ id = "drawer-overlay", class = "drawer-overlay",
            onclick = "toggleDrawer()" })
      div({ id = "side-drawer", class = "side-drawer" }, function()
        div({ class = "drawer-header" }, function()
          span({ class = "drawer-title" }, "Navegação")
          button({ class = "drawer-close", onclick = "toggleDrawer()" }, "✕")
        end)
        div({ class = "drawer-profile" }, function()
          a({ href = "/perfil", class = "drawer-perfil-card" }, function()
            span({ class = "drawer-avatar" }, self.leitor_icon or "👤")
            div({ class = "drawer-user-info" }, function()
              span({ class = "drawer-username" }, self.leitor_nome or "Visitante")
              span({ class = "drawer-view-profile" }, "Ver perfil →")
            end)
          end)
        end)
        nav({ class = "drawer-nav" }, function()
          a({ href = "/" },         "🏠 Início")
          a({ href = "/noticias" }, "📰 Notícias")
          a({ href = "/trending" }, "🔥 Trending")
          a({ href = "/ranking" },  "🏆 Ranking")
          a({ href = "/reviews" },  "🎮 Reviews")
          a({ href = "/torneios" }, "⚔️ Torneios")
          a({ href = "/feed" },     "⚡ Feed")
          a({ href = "/glossario" },"📖 Glossário")
          a({ href = "/sobre" },    "ℹ️ Sobre")
          a({ href = "/admin" },    "⚙️ Admin")
          button({ id = "pwa-install-btn", onclick = "instalarPWA()",
                   style = "margin-top:1.5rem;display:none;" }, function()
            span("📲 Instalar App")
          end)
        end)
      end)

      if self.flash_newsletter_msg then
        div({ class = "container" }, function()
          div({ class = "newsletter-flash" }, self.flash_newsletter_msg)
        end)
      end
      if self.flash_coment_ok then
        div({ class = "container" }, function()
          div({ class = "newsletter-flash coment-ok-flash" }, self.flash_coment_ok)
        end)
      end

      main({ class = "container content-area" }, function()
        self:content_for("inner")
      end)

      footer({ class = "site-footer" }, function()
        div({ class = "container" }, function()
          div({ class = "footer-newsletter" }, function()
            div({ class = "newsletter-texto" }, function()
              span({ class = "newsletter-titulo" }, "📧 Fique por dentro!")
              span({ class = "newsletter-sub" },
                "Receba as novidades do Portal Gamer no seu e-mail.")
            end)
            form({ method = "POST", action = "/newsletter/cadastrar",
                   class = "newsletter-form" }, function()
              input({ type = "hidden", name = "origem", value = self.og_url or "/" })
              input({ type = "email", name = "email", placeholder = "seu@email.com",
                      class = "newsletter-input", required = true })
              button({ type = "submit", class = "newsletter-btn" }, "Inscrever →")
            end)
          end)

          div({ id = "citacao-widget", class = "footer-citacao" }, function()
            div({ class = "citacao-aspas" }, "“")
            p({ id = "citacao-texto", class = "citacao-texto" }, "Carregando citação...")
            p({ id = "citacao-fonte", class = "citacao-fonte" })
          end)

          div({ class = "footer-inner" }, function()
            p("© 2026 Portal Gamer — Desenvolvido em Lua com Lapis")
            div({ class = "footer-links" }, function()
              a({ href = "/sobre" },    "Sobre")
              a({ href = "/trending" }, "Trending")
              a({ href = "/rss" },      "RSS Feed")
              a({ href = "/perfil" },   "\xF0\x9F\x91\xA4 Perfil")
              a({ href = "/admin" },    "Admin")
            end)
          end)
        end)
      end)

      script(function()
        raw([[
          // ── Tema: inicializa ícone ────────────────────────────────────────
          (function() {
            var c   = JSON.parse(localStorage.getItem('custom_tema') || '{}');
            var btn = document.getElementById('tema-toggle');
            var tema = c.tema || localStorage.getItem('tema') || 'dark';
            if (btn) btn.textContent = tema === 'dark' ? '\u2600\uFE0F' : '\uD83C\uDF19';
          })();

          // ── Toggle claro/escuro ───────────────────────────────────────────
          function toggleTema() {
            var atual = document.documentElement.getAttribute('data-tema') || 'dark';
            var novo  = atual === 'dark' ? 'light' : 'dark';
            document.documentElement.setAttribute('data-tema', novo);
            var c = JSON.parse(localStorage.getItem('custom_tema') || '{}');
            c.tema = novo;
            localStorage.setItem('custom_tema', JSON.stringify(c));
            localStorage.setItem('tema', novo);
            var btn = document.getElementById('tema-toggle');
            if (btn) btn.textContent = novo === 'dark' ? '\u2600\uFE0F' : '\uD83C\uDF19';
          }

          // ── Painel de customização ────────────────────────────────────────
          (function() {
            var PRESETS = [
              { nome:'Escuro',   tema:'dark',  accent:'#6366f1', ico:'🌙' },
              { nome:'Claro',    tema:'light', accent:'#4f46e5', ico:'☀️' },
              { nome:'Roxo',     tema:'dark',  accent:'#8b5cf6', ico:'💜' },
              { nome:'Verde',    tema:'dark',  accent:'#10b981', ico:'💚' },
              { nome:'Vermelho', tema:'dark',  accent:'#f43f5e', ico:'❤️' },
              { nome:'Laranja',  tema:'dark',  accent:'#f97316', ico:'🔶' },
              { nome:'Rosa',     tema:'dark',  accent:'#ec4899', ico:'🩷' },
              { nome:'Azul',     tema:'light', accent:'#0ea5e9', ico:'💙' },
            ];

            var presetsEl = document.getElementById('tema-presets');
            if (presetsEl) {
              presetsEl.innerHTML = PRESETS.map(function(p, i) {
                return '<button class="tema-preset-btn" onclick="aplicarPreset(' + i + ')" '
                  + 'title="' + p.nome + '" style="--p-accent:' + p.accent + '">'
                  + p.ico + '<span>' + p.nome + '</span></button>';
              }).join('');
            }

            var saved = JSON.parse(localStorage.getItem('custom_tema') || '{}');
            if (saved.accent) {
              var pk = document.getElementById('accent-picker');
              if (pk) pk.value = saved.accent;
            }
            if (saved.fonte) {
              document.querySelectorAll('.fonte-btn').forEach(function(b) {
                b.classList.toggle('fonte-ativa', b.dataset.size === saved.fonte);
              });
            }

            window.toggleCustomTema = function() {
              var panel = document.getElementById('custom-tema-panel');
              var btn   = document.getElementById('custom-tema-btn');
              if (!panel || !btn) return;
              var abrindo = !panel.classList.contains('custom-tema-visivel');
              panel.classList.toggle('custom-tema-visivel', abrindo);
              btn.classList.toggle('tema-btn-ativo', abrindo);
              if (abrindo) {
                var rect = btn.getBoundingClientRect();
                panel.style.top   = (rect.bottom + 8) + 'px';
                panel.style.right = (window.innerWidth - rect.right) + 'px';
                panel.style.left  = 'auto';
              }
            };

            document.addEventListener('click', function(e) {
              var panel = document.getElementById('custom-tema-panel');
              var btn   = document.getElementById('custom-tema-btn');
              if (!panel || !btn) return;
              if (!panel.contains(e.target) && !btn.contains(e.target)) {
                panel.classList.remove('custom-tema-visivel');
                btn.classList.remove('tema-btn-ativo');
              }
            });

            window.aplicarPreset = function(i) {
              var p = PRESETS[i];
              var s = JSON.parse(localStorage.getItem('custom_tema') || '{}');
              s.tema = p.tema; s.accent = p.accent;
              document.documentElement.setAttribute('data-tema', p.tema);
              document.documentElement.style.setProperty('--primary-color', p.accent);
              localStorage.setItem('custom_tema', JSON.stringify(s));
              localStorage.setItem('tema', p.tema);
              var b = document.getElementById('tema-toggle');
              if (b) b.textContent = p.tema === 'dark' ? '\u2600\uFE0F' : '\uD83C\uDF19';
              var pk = document.getElementById('accent-picker');
              if (pk) pk.value = p.accent;
            };

            window.aplicarAccent = function(cor) {
              document.documentElement.style.setProperty('--primary-color', cor);
              var s = JSON.parse(localStorage.getItem('custom_tema') || '{}');
              s.accent = cor;
              localStorage.setItem('custom_tema', JSON.stringify(s));
            };

            window.resetAccent = function() {
              document.documentElement.style.removeProperty('--primary-color');
              var s = JSON.parse(localStorage.getItem('custom_tema') || '{}');
              delete s.accent;
              localStorage.setItem('custom_tema', JSON.stringify(s));
              var tema = document.documentElement.getAttribute('data-tema') || 'dark';
              var cor  = tema === 'dark' ? '#6366f1' : '#4f46e5';
              var pk = document.getElementById('accent-picker');
              if (pk) pk.value = cor;
            };

            window.aplicarFonte = function(t) {
              document.documentElement.style.fontSize = t;
              var s = JSON.parse(localStorage.getItem('custom_tema') || '{}');
              s.fonte = t;
              localStorage.setItem('custom_tema', JSON.stringify(s));
              document.querySelectorAll('.fonte-btn').forEach(function(b) {
                b.classList.toggle('fonte-ativa', b.dataset.size === t);
              });
            };
          })();

          // ── Drawer ────────────────────────────────────────────────────────
          function toggleDrawer() {
            var drawer  = document.getElementById('side-drawer');
            var overlay = document.getElementById('drawer-overlay');
            drawer.classList.toggle('aberto');
            overlay.classList.toggle('aberto');
            document.body.style.overflow = drawer.classList.contains('aberto') ? 'hidden' : '';
          }

          // ── Busca AJAX ────────────────────────────────────────────────────
          (function() {
            var input = document.getElementById('busca-global');
            var res   = document.getElementById('busca-resultados');
            if (!input) return;
            var timer = null;
            input.addEventListener('input', function() {
              clearTimeout(timer);
              var termo = input.value.trim();
              if (termo.length < 2) { res.innerHTML = ''; res.classList.remove('aberto'); return; }
              timer = setTimeout(function() {
                fetch('/api/busca?q=' + encodeURIComponent(termo))
                  .then(function(r) { return r.json(); })
                  .then(function(data) {
                    if (!data.data || data.data.length === 0) {
                      res.innerHTML = '<div class="busca-item busca-vazio">Nenhum resultado.</div>';
                    } else {
                      res.innerHTML = data.data.map(function(n) {
                        return '<a class="busca-item" href="/noticias/' + n.id + '">'
                          + '<span class="busca-item-titulo">' + n.titulo + '</span>'
                          + '<span class="busca-item-meta">'
                          + '<span class="tag">' + n.categoria + '</span>'
                          + (n.jogo ? '<span class="tag tag-jogo">' + n.jogo + '</span>' : '')
                          + '</span></a>';
                      }).join('');
                    }
                    res.classList.add('aberto');
                  }).catch(function() { res.classList.remove('aberto'); });
              }, 280);
            });
            document.addEventListener('click', function(e) {
              var c = document.getElementById('header-busca');
              if (c && !c.contains(e.target)) {
                res.classList.remove('aberto'); input.value = '';
              }
            });
            input.addEventListener('keydown', function(e) {
              if (e.key === 'Escape') { res.classList.remove('aberto'); input.blur(); }
            });
          })();

          // ── Busca por Voz ─────────────────────────────────────────────────
          (function() {
            var btn = document.getElementById('voice-btn');
            if (!btn) return;
            var SR = window.SpeechRecognition || window.webkitSpeechRecognition;
            if (!SR) { btn.style.display = 'none'; return; }
            var rec = new SR();
            rec.lang = 'pt-BR'; rec.interimResults = false; rec.maxAlternatives = 1;
            btn.addEventListener('click', function() {
              btn.classList.add('voice-ouvindo'); btn.textContent = '🔴'; rec.start();
            });
            rec.onresult = function(e) {
              var termo = e.results[0][0].transcript;
              btn.classList.remove('voice-ouvindo'); btn.textContent = '🎤';
              var inp = document.getElementById('busca-global');
              inp.value = termo; inp.dispatchEvent(new Event('input')); inp.focus();
            };
            rec.onerror = rec.onend = function() {
              btn.classList.remove('voice-ouvindo');
              if (btn.textContent === '🔴') btn.textContent = '🎤';
            };
            window.iniciarBuscaVoz = function() { rec.start(); };
          })();

          // ── Citação ───────────────────────────────────────────────────────
          (function() {
            var w = document.getElementById('citacao-widget');
            if (!w) return;
            fetch('/api/citacao')
              .then(function(r) { return r.json(); })
              .then(function(d) {
                if (d.status !== 'ok') { w.style.display = 'none'; return; }
                var t = document.getElementById('citacao-texto');
                var f = document.getElementById('citacao-fonte');
                if (t) t.textContent = d.texto;
                if (f) {
                  var s = '';
                  if (d.personagem && d.personagem !== '') s += d.personagem;
                  if (d.jogo && d.jogo !== '') s += (s ? ' · ' : '') + d.jogo;
                  f.textContent = s ? '— ' + s : '';
                }
              }).catch(function() { w.style.display = 'none'; });
          })();

          // ── PWA ───────────────────────────────────────────────────────────
          if ('serviceWorker' in navigator) {
            navigator.serviceWorker.register('/sw.js').catch(function() {});
          }
          var _dp;
          window.addEventListener('beforeinstallprompt', function(e) {
            e.preventDefault(); _dp = e;
            var b = document.getElementById('pwa-install-btn');
            if (b) b.style.display = 'flex';
          });
          window.instalarPWA = function() {
            if (!_dp) return;
            _dp.prompt();
            _dp.userChoice.then(function() { _dp = null; });
          };
        ]])
      end)
    end)
  end)
end)