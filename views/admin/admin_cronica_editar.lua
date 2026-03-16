local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  local c = self.cronica or {}

  div({ class = "admin-section shadow-card" }, function()
    h2("✏️ Editar Crônica")
    if self.erro then div({ class = "alert alert-erro" }, self.erro) end

    div({ class = "form-preview-layout" }, function()

      div({ class = "form-col" }, function()
        form({ method = "POST",
               action  = "/admin/cronicas/" .. c.id .. "/editar",
               class   = "admin-form" }, function()

          div({ class = "form-group" }, function()
            label({ ["for"] = "titulo" }, "Título *")
            input({ type = "text", id = "titulo", name = "titulo",
                    value = c.titulo or "", required = true,
                    oninput = "atualizarPreview()" })
          end)

          div({ class = "form-group" }, function()
            label({ ["for"] = "subtitulo" }, "Subtítulo")
            input({ type = "text", id = "subtitulo", name = "subtitulo",
                    value = c.subtitulo or "",
                    oninput = "atualizarPreview()" })
          end)

          div({ class = "form-group" }, function()
            label({ ["for"] = "autor_id" }, "Autor")
            element("select", { id = "autor_id", name = "autor_id" }, function()
              option({ value = "" }, "— Selecione —")
              for _, a in ipairs(self.autores or {}) do
                local attrs = { value = tostring(a.id) }
                if c.autor_id == a.id then attrs.selected = true end
                option(attrs, a.nome)
              end
            end)
          end)

          div({ class = "form-group" }, function()
            label({ ["for"] = "conteudo" }, "Conteúdo *")
            textarea({ id = "conteudo", name = "conteudo", rows = "14",
                       required = true, oninput = "atualizarPreview()" },
                     c.conteudo or "")
          end)

          div({ class = "form-row" }, function()
            div({ class = "form-group form-grow" }, function()
              label({ ["for"] = "imagem_url" }, "Imagem de Capa")
              input({ type = "url", id = "imagem_url", name = "imagem_url",
                      value = c.imagem_url or "" })
              if c.imagem_url and c.imagem_url ~= "" then
                div({ style = "margin-top:.4rem" }, function()
                  img({ src   = c.imagem_url, alt = c.titulo,
                        style = "max-width:120px;border-radius:6px" })
                end)
              end
            end)
            div({ class = "form-group form-grow" }, function()
              label({ ["for"] = "tags_str" }, "Tags")
              input({ type = "text", id = "tags_str", name = "tags_str",
                      value = c.tags_str or "" })
            end)
          end)

          div({ class = "form-group" }, function()
            label({ ["for"] = "publicar_em" }, "⏰ Agendar")
            input({ type  = "datetime-local", id = "publicar_em",
                    name  = "publicar_em",
                    value = c.publicar_em or "" })
          end)

          div({ class = "form-check" }, function()
            local attrs = { type = "checkbox", id = "destaque",
                            name = "destaque", value = "1" }
            if c.destaque == 1 then attrs.checked = true end
            input(attrs)
            label({ ["for"] = "destaque" }, "⭐ Destaque na listagem")
          end)

          div({ class = "form-actions" }, function()
            a({ href = "/admin/cronicas", class = "btn-cancelar" }, "Cancelar")
            button({ type = "submit", class = "btn-salvar" }, "💾 Salvar Alterações")
          end)
        end)
      end)

      -- Preview ao vivo
      div({ class = "preview-col" }, function()
        div({ class = "preview-header" }, function()
          span({ class = "preview-label" }, "👁 Preview")
        end)
        div({ id = "preview-box", class = "preview-box" })
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
        var palavras  = (conteudo || '').split(/\s+/).filter(Boolean).length;
        var mins      = Math.max(1, Math.ceil(palavras / 200));
        var html = '<article class="cronica-artigo preview-article">';
        html += '<span class="cronica-tipo-badge">✍️ Crônica & Editorial</span>';
        if (titulo)    html += '<h1 class="cronica-artigo-titulo">'    + titulo    + '</h1>';
        if (subtitulo) html += '<p class="cronica-artigo-subtitulo">' + subtitulo + '</p>';
        html += '<div class="cronica-artigo-meta"><span class="meta-item tempo-leitura-badge">⏱ '
             + mins + ' min</span></div>';
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
      window.addEventListener('DOMContentLoaded', atualizarPreview);
    ]])
  end)
end)