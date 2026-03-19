-- Inclui editor Markdown com preview ao vivo via marked.js (CDN)
local Widget = require("lapis.html").Widget

local function campos_notas(vals)
  vals = vals or {}
  div({ class = "review-notas-form" }, function()
    local campos = {
      { "nota_geral",    "⭐ Nota Geral (0-10) *" },
      { "nota_gameplay", "🕹 Gameplay" },
      { "nota_graficos", "🖼 Gráficos" },
      { "nota_historia", "📖 História" },
      { "nota_audio",    "🎵 Áudio" },
    }
    for _, c in ipairs(campos) do
      div({ class = "nota-input-group" }, function()
        label({ ["for"] = c[1] }, c[2])
        div({ class = "nota-slider-row" }, function()
          input({ type  = "range", id = c[1], name = c[1],
                  min   = "0", max = "10", step = "0.5",
                  value = tostring(vals[c[1]] or 0),
                  oninput = "atualizarNota('" .. c[1] .. "', this.value)" })
          span({ id    = c[1] .. "_val",
                 class = "nota-slider-val" },
               string.format("%.1f", tonumber(vals[c[1]] or 0)))
        end)
      end)
    end
  end)
end

return Widget:extend(function(self)
  local vals = self.review or {}
  local is_edit = vals.id ~= nil
  local action  = is_edit
    and "/admin/reviews/" .. (vals.id or "") .. "/editar"
    or  "/admin/reviews/novo"

  div({ class = "admin-section shadow-card" }, function()
    h2(is_edit and "✏️ Editar Review" or "🎮 Nova Review")
    if self.erro then div({ class = "alert alert-erro" }, self.erro) end

    div({ class = "form-preview-layout" }, function()
      div({ class = "form-col" }, function()
        form({ method = "POST", action = action, class = "admin-form" }, function()

          div({ class = "form-row" }, function()
            div({ class = "form-group form-grow" }, function()
              label({ ["for"] = "jogo_id" }, "Jogo *")
              element("select", { id = "jogo_id", name = "jogo_id", required = true }, function()
                option({ value = "" }, "— Selecione —")
                for _, j in ipairs(self.jogos or {}) do
                  local attrs = { value = tostring(j.id) }
                  if vals.jogo_id == j.id then attrs.selected = true end
                  option(attrs, j.nome)
                end
              end)
            end)
            div({ class = "form-group form-grow" }, function()
              label({ ["for"] = "autor_id" }, "Autor")
              element("select", { id = "autor_id", name = "autor_id" }, function()
                option({ value = "" }, "— Selecione —")
                for _, a in ipairs(self.autores or {}) do
                  local attrs = { value = tostring(a.id) }
                  if vals.autor_id == a.id then attrs.selected = true end
                  option(attrs, a.nome)
                end
              end)
            end)
          end)

          div({ class = "form-group" }, function()
            label({ ["for"] = "titulo" }, "Título da Review *")
            input({ type = "text", id = "titulo", name = "titulo",
                    value = vals.titulo or "",
                    placeholder = "Ex: Valorant — O FPS mais equilibrado do mercado",
                    required = true, oninput = "atualizarPreview()" })
          end)

          -- Editor Markdown
          div({ class = "form-group" }, function()
            label({}, "Conteúdo *")
            div({ class = "md-editor-wrapper" }, function()
              div({ class = "md-toolbar" }, function()
                local btns = {
                  {"**texto**","B","Negrito"},{"*texto*","I","Itálico"},
                  {"## Título","H","Cabeçalho"},{"- item","≡","Lista"},
                  {"> texto","❝","Citação"}
                }
                for _, b in ipairs(btns) do
                  button({ type    = "button", class = "md-btn",
                           title   = b[3],
                           onclick = "inserirMd('" .. b[1]:gsub("'","\\'") .. "')" },
                         b[2])
                end
                button({ type    = "button",
                         class   = "md-btn md-preview-toggle",
                         onclick = "togglePreviewMd()",
                         id      = "md-toggle-btn" }, "👁 Preview")
              end)
              textarea({ id   = "conteudo", name = "conteudo", rows = "12",
                         class = "md-textarea",
                         placeholder = "Escreva a análise em Markdown...\n\n## Introdução\n\nO jogo...",
                         required = true,
                         oninput = "atualizarPreview()" },
                       vals.conteudo or "")
              div({ id    = "md-preview",
                    class = "md-preview" })
            end)
          end)

          -- Notas
          h3({ style = "margin:.8rem 0 .5rem" }, "📊 Notas (0 a 10)")
          campos_notas({
            nota_geral    = vals.nota_geral,
            nota_gameplay = vals.nota_gameplay,
            nota_graficos = vals.nota_graficos,
            nota_historia = vals.nota_historia,
            nota_audio    = vals.nota_audio,
          })

          -- Prós e contras
          div({ class = "form-row" }, function()
            div({ class = "form-group form-grow" }, function()
              label({ ["for"] = "pros" }, "✅ Pontos Positivos (um por linha)")
              textarea({ id = "pros", name = "pros", rows = "4",
                         placeholder = "Gameplay fluido\nGráficos impressionantes" },
                       vals.pros or "")
            end)
            div({ class = "form-group form-grow" }, function()
              label({ ["for"] = "contras" }, "❌ Pontos Negativos (um por linha)")
              textarea({ id = "contras", name = "contras", rows = "4",
                         placeholder = "Falta conteúdo solo\nServidores instáveis" },
                       vals.contras or "")
            end)
          end)

          div({ class = "form-group" }, function()
            label({ ["for"] = "veredicto" }, "⚖️ Veredicto Final")
            textarea({ id = "veredicto", name = "veredicto", rows = "2",
                       placeholder = "Uma frase resumindo sua opinião geral..." },
                     vals.veredicto or "")
          end)

          div({ class = "form-group" }, function()
            label({ ["for"] = "imagem_url" }, "Imagem de Capa (opcional)")
            input({ type = "url", id = "imagem_url", name = "imagem_url",
                    value = vals.imagem_url or "", placeholder = "https://..." })
          end)

          div({ class = "form-check" }, function()
            local attrs = { type="checkbox", id="destaque", name="destaque", value="1" }
            if vals.destaque == 1 then attrs.checked = true end
            input(attrs)
            label({ ["for"] = "destaque" }, "⭐ Editor's Choice (destaque na listagem)")
          end)

          div({ class = "form-actions" }, function()
            a({ href = "/admin/reviews", class = "btn-cancelar" }, "Cancelar")
            button({ type = "submit", class = "btn-salvar" },
              is_edit and "💾 Salvar Alterações" or "💾 Publicar Review")
          end)
        end)
      end)

      -- Preview coluna
      div({ class = "preview-col" }, function()
        div({ class = "preview-header" }, function()
          span({ class = "preview-label" }, "👁 Preview")
        end)
        div({ id = "preview-box", class = "preview-box" }, function()
          div({ class = "preview-empty" }, "Preencha para ver o preview →")
        end)
      end)
    end)
  end)

  -- Carrega marked.js para renderizar Markdown
  element("script", { src = "https://cdnjs.cloudflare.com/ajax/libs/marked/9.1.6/marked.min.js" })

  script(function()
    raw([[
      var mdVisible = false;

      function togglePreviewMd() {
        mdVisible = !mdVisible;
        var ta  = document.getElementById('conteudo');
        var pre = document.getElementById('md-preview');
        var btn = document.getElementById('md-toggle-btn');
        if (mdVisible) {
          pre.innerHTML = typeof marked !== 'undefined'
            ? marked.parse(ta.value || '')
            : '<p style="color:var(--text-muted)">Carregando parser...</p>';
          pre.style.display = 'block';
          ta.style.display  = 'none';
          if (btn) btn.textContent = '✏️ Editar';
        } else {
          pre.style.display = 'none';
          ta.style.display  = 'block';
          if (btn) btn.textContent = '👁 Preview';
        }
      }

      function inserirMd(snippet) {
        var ta    = document.getElementById('conteudo');
        var start = ta.selectionStart;
        var end_  = ta.selectionEnd;
        var sel   = ta.value.substring(start, end_);
        var ins   = sel ? snippet.replace('texto', sel) : snippet;
        ta.value  = ta.value.substring(0, start) + ins + ta.value.substring(end_);
        ta.focus();
        ta.selectionStart = ta.selectionEnd = start + ins.length;
        atualizarPreview();
      }

      function atualizarNota(campo, val) {
        var el = document.getElementById(campo + '_val');
        if (el) el.textContent = parseFloat(val).toFixed(1);
        atualizarPreview();
      }

      function atualizarPreview() {
        var titulo  = document.getElementById('titulo') ? document.getElementById('titulo').value : '';
        var conteudo = document.getElementById('conteudo') ? document.getElementById('conteudo').value : '';
        var nota    = document.getElementById('nota_geral') ? document.getElementById('nota_geral').value : '0';
        var box     = document.getElementById('preview-box');
        if (!box) return;
        if (!titulo && !conteudo) {
          box.innerHTML = '<div class="preview-empty">Preencha para ver o preview →</div>';
          return;
        }
        var notaN   = parseFloat(nota) || 0;
        var corNota = notaN >= 8 ? '#4ade80' : notaN >= 6 ? '#f59e0b' : '#f43f5e';
        var html    = '<article class="review-artigo preview-article">';
        html += '<span class="cronica-tipo-badge">🎮 Review</span>';
        if (titulo) html += '<h1 class="review-artigo-titulo">' + titulo + '</h1>';
        html += '<div class="review-nota-hero" style="margin:1rem 0">';
        html += '<div class="review-nota-circulo" style="border-color:' + corNota + '">';
        html += '<span class="review-nota-num" style="color:' + corNota + '">' + notaN.toFixed(1) + '</span>';
        html += '<span class="review-nota-max">/10</span></div></div>';
        if (conteudo && typeof marked !== 'undefined') {
          html += '<div class="review-artigo-corpo cronica-artigo-corpo">' + marked.parse(conteudo.substring(0,600)) + '</div>';
        }
        html += '</article>';
        box.innerHTML = html;
      }

      window.addEventListener('DOMContentLoaded', atualizarPreview);
    ]])
  end)
end)