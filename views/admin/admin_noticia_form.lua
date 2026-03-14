-- views/admin/admin_noticia_form.lua
-- (igual ao anterior, mas com campo de imagem + upload via AJAX)
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    h2("➕ Nova Notícia")
    if self.erro then div({ class = "alert alert-erro" }, self.erro) end

    div({ class = "form-preview-layout" }, function()

      -- Formulário
      div({ class = "form-col" }, function()
        form({ method  = "POST", action = "/admin/noticias/nova",
               class   = "admin-form", id = "form-noticia",
               enctype = "multipart/form-data" }, function()

          div({ class = "form-group" }, function()
            label({ ["for"] = "titulo" }, "Título *")
            input({ type = "text", id = "titulo", name = "titulo",
                    placeholder = "Ex: Novo update de Valorant!",
                    required = true, oninput = "atualizarPreview()" })
          end)

          div({ class = "form-row" }, function()
            div({ class = "form-group" }, function()
              label({ ["for"] = "jogo" }, "Jogo relacionado")
              element("select", { id = "jogo", name = "jogo",
                                  onchange = "atualizarPreview()" }, function()
                option({ value = "" }, "— Selecione —")
                for _, j in ipairs(self.jogos or {}) do
                  option({ value = j.nome }, j.nome)
                end
              end)
            end)
            div({ class = "form-group" }, function()
              label({ ["for"] = "categoria" }, "Categoria")
              element("select", { id = "categoria", name = "categoria",
                                  onchange = "atualizarPreview()" }, function()
                for _, c in ipairs(self.categorias or {}) do
                  option({ value = c.nome }, c.nome)
                end
              end)
            end)
          end)

          div({ class = "form-group" }, function()
            label({ ["for"] = "conteudo" }, "Conteúdo *")
            textarea({ id = "conteudo", name = "conteudo", rows = "10",
                       placeholder = "Escreva o conteúdo completo...",
                       required = true, oninput = "atualizarPreview()" })
          end)

          -- Campo de imagem com upload AJAX
          div({ class = "form-group" }, function()
            label({}, "Imagem de Capa")
            div({ class = "upload-wrapper" }, function()
              input({ type        = "file",
                      id          = "upload-arquivo",
                      accept      = "image/jpeg,image/png,image/gif,image/webp",
                      class       = "upload-input",
                      onchange    = "fazerUpload(this)" })
              div({ id = "upload-status", class = "upload-status" })
              div({ id = "upload-preview", class = "upload-img-preview" })
            end)
            -- Campo hidden que recebe a URL após upload
            input({ type = "hidden", id = "imagem_url", name = "imagem_url" })
          end)

          div({ class = "form-check" }, function()
            input({ type = "checkbox", id = "destaque", name = "destaque",
                    value = "1", onchange = "atualizarPreview()" })
            label({ ["for"] = "destaque" }, "⭐ Marcar como destaque na home")
          end)

          div({ class = "form-actions" }, function()
            a({ href = "/admin", class = "btn-cancelar" }, "Cancelar")
            button({ type = "submit", class = "btn-salvar" }, "💾 Salvar Notícia")
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
          div({ class = "preview-empty" }, "Preencha o formulário para ver o preview →")
        end)
      end)
    end)
  end)

  script(function()
    raw([[
      // ── Upload de imagem ──────────────────────────────────────────────
      function fazerUpload(input) {
        var arquivo = input.files[0];
        if (!arquivo) return;

        var status  = document.getElementById('upload-status');
        var preview = document.getElementById('upload-preview');
        var hidden  = document.getElementById('imagem_url');

        status.textContent  = '⏳ Enviando...';
        status.className    = 'upload-status upload-enviando';
        preview.innerHTML   = '';

        var formData = new FormData();
        formData.append('imagem', arquivo);

        fetch('/admin/upload/imagem', { method: 'POST', body: formData })
          .then(function(r) { return r.json(); })
          .then(function(data) {
            if (data.status === 'ok') {
              hidden.value       = data.url;
              status.textContent = '✅ Upload concluído!';
              status.className   = 'upload-status upload-ok';
              preview.innerHTML  =
                '<img src="' + data.url + '" class="upload-thumb" alt="Preview"/>';
            } else {
              status.textContent = '❌ ' + (data.mensagem || 'Erro no upload.');
              status.className   = 'upload-status upload-erro';
            }
          })
          .catch(function() {
            status.textContent = '❌ Erro de conexão.';
            status.className   = 'upload-status upload-erro';
          });
      }

      // ── Preview ao vivo ───────────────────────────────────────────────
      function atualizarPreview() {
        var titulo    = document.getElementById('titulo').value;
        var conteudo  = document.getElementById('conteudo').value;
        var jogo      = document.getElementById('jogo').value;
        var categoria = document.getElementById('categoria').value;
        var destaque  = document.getElementById('destaque').checked;
        var imgUrl    = document.getElementById('imagem_url').value;
        var box       = document.getElementById('preview-box');

        if (!titulo && !conteudo) {
          box.innerHTML =
            '<div class="preview-empty">Preencha o formulário para ver o preview →</div>';
          return;
        }

        var hoje = new Date().toISOString().split('T')[0];
        var html = '<article class="noticia-detalhe preview-article">';
        html += '<div class="noticia-header">';
        if (categoria) html += '<span class="tag">'       + categoria + '</span>';
        if (jogo)      html += '<span class="tag tag-jogo">' + jogo  + '</span>';
        if (destaque)  html += '<span class="badge-destaque">⭐ Destaque</span>';
        html += '<span class="data-noticia">' + hoje + '</span>';
        html += '</div>';
        if (imgUrl) {
          html += '<img src="' + imgUrl +
                  '" style="width:100%;border-radius:8px;margin:.8rem 0;max-height:200px;object-fit:cover"/>';
        }
        if (titulo) html += '<h2>' + titulo + '</h2>';
        html += '<div class="noticia-corpo"><p>' +
                (conteudo || '').replace(/\n/g, '</p><p>') +
                '</p></div></article>';
        box.innerHTML = html;
      }
    ]])
  end)
end)