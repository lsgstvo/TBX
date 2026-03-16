local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    h2("✍️ Nova Crônica")
    if self.erro then div({ class = "alert alert-erro" }, self.erro) end

    div({ class = "form-preview-layout" }, function()

      div({ class = "form-col" }, function()
        form({ method = "POST", action = "/admin/cronicas/nova",
               class  = "admin-form" }, function()

          div({ class = "form-group" }, function()
            label({ ["for"] = "titulo" }, "Título *")
            input({ type = "text", id = "titulo", name = "titulo",
                    placeholder = "Título da crônica", required = true,
                    oninput = "atualizarPreview()" })
          end)

          div({ class = "form-group" }, function()
            label({ ["for"] = "subtitulo" }, "Subtítulo / Linha fina")
            input({ type = "text", id = "subtitulo", name = "subtitulo",
                    placeholder = "Uma frase que complementa o título",
                    oninput = "atualizarPreview()" })
          end)

          div({ class = "form-group" }, function()
            label({ ["for"] = "autor_id" }, "Autor")
            element("select", { id = "autor_id", name = "autor_id" }, function()
              option({ value = "" }, "— Selecione —")
              for _, a in ipairs(self.autores or {}) do
                option({ value = tostring(a.id) }, a.nome)
              end
            end)
          end)

          div({ class = "form-group" }, function()
            label({ ["for"] = "conteudo" }, "Conteúdo *")
            textarea({ id = "conteudo", name = "conteudo", rows = "14",
                       placeholder = "Escreva a crônica...\n\nSepare parágrafos com linha em branco.",
                       required = true, oninput = "atualizarPreview()" })
          end)

          div({ class = "form-row" }, function()
            div({ class = "form-group form-grow" }, function()
              label({ ["for"] = "imagem_url" }, "Imagem de Capa")
              input({ type = "url", id = "imagem_url", name = "imagem_url",
                      placeholder = "https://..." })
            end)
            div({ class = "form-group form-grow" }, function()
              label({ ["for"] = "tags_str" }, "Tags")
              input({ type = "text", id = "tags_str", name = "tags_str",
                      placeholder = "ex: opinião, análise, fps" })
            end)
          end)

          div({ class = "form-group" }, function()
            label({ ["for"] = "publicar_em" }, "⏰ Agendar (opcional)")
            input({ type = "datetime-local", id = "publicar_em",
                    name = "publicar_em" })
            p({ class = "field-hint" }, "Deixe vazio para publicar imediatamente.")
          end)

          div({ class = "form-check" }, function()
            input({ type = "checkbox", id = "destaque",
                    name = "destaque", value = "1" })
            label({ ["for"] = "destaque" }, "⭐ Destaque na listagem")
          end)

          div({ class = "form-actions" }, function()
            a({ href = "/admin/cronicas", class = "btn-cancelar" }, "Cancelar")
            button({ type = "submit", class = "btn-salvar" }, "💾 Publicar Crônica")
          end)
        end)
      end)

      -- Preview ao vivo
      div({ class = "preview-col" }, function()
        div({ class = "preview-header" }, function()
          span({ class = "preview-label" }, "👁 Preview")
          span({ class = "preview-hint" }, "Atualiza em tempo real")
        end)
        div({ id = "preview-box", class = "preview-box" }, function()
          div({ class = "preview-empty" }, "Preencha para ver o preview →")
        end)
      end)
    end)
  end)

  script(function()
    raw([[
      function atualizarPreview() {
        var titulo    = document.getElementById('titulo').value;
        var subtitulo = document.getElementById('subtitulo').value;
        var conteudo  = document.getElementById('conteudo').value;
        var box       = document.getElementById('preview-box');
        if (!titulo && !conteudo) {
          box.innerHTML = '<div class="preview-empty">Preencha para ver o preview →</div>';
          return;
        }
        var hoje = new Date().toISOString().split('T')[0];
        var palavras = (conteudo || '').split(/\s+/).filter(Boolean).length;
        var mins = Math.max(1, Math.ceil(palavras / 200));
        var html = '<article class="cronica-artigo preview-article">';
        html += '<span class="cronica-tipo-badge">✍️ Crônica & Editorial</span>';
        if (titulo)    html += '<h1 class="cronica-artigo-titulo">' + titulo + '</h1>';
        if (subtitulo) html += '<p class="cronica-artigo-subtitulo">' + subtitulo + '</p>';
        html += '<div class="cronica-artigo-meta">';
        html += '<span class="meta-item">' + hoje + '</span>';
        html += '<span class="meta-sep">·</span>';
        html += '<span class="meta-item tempo-leitura-badge">⏱ ' + mins + ' min</span>';
        html += '</div>';
        if (conteudo) {
          html += '<div class="cronica-artigo-corpo">';
          conteudo.split(/\n\s*\n/).forEach(function(par) {
            par = par.trim();
            if (par) html += '<p class="cronica-par">' + par + '</p>';
          });
          html += '</div>';
        }
        html += '</article>';
        box.innerHTML = html;
      }
    ]])
  end)
end)