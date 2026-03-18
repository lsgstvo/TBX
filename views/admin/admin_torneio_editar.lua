local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  local t = self.torneio or {}
  div({ class = "admin-section shadow-card" }, function()
    h2("✏️ Editar Torneio")
    if self.erro then div({ class = "alert alert-erro" }, self.erro) end
    form({ method="POST", action="/admin/torneios/"..t.id.."/editar",
           class="admin-form" }, function()

      div({ class = "form-group" }, function()
        label({ ["for"] = "nome" }, "Nome *")
        input({ type="text", id="nome", name="nome", value=t.nome or "", required=true })
      end)
      div({ class = "form-row" }, function()
        div({ class = "form-group form-grow" }, function()
          label({ ["for"] = "jogo" }, "Jogo")
          input({ type="text", id="jogo", name="jogo", value=t.jogo or "" })
        end)
        div({ class = "form-group" }, function()
          label({ ["for"] = "status" }, "Status")
          element("select", { id="status", name="status" }, function()
            for _, s in ipairs({ {"upcoming","⏳ Em Breve"}, {"live","🔴 Ao Vivo"}, {"finished","✅ Encerrado"} }) do
              local attrs = { value=s[1] }
              if t.status == s[1] then attrs.selected = true end
              option(attrs, s[2])
            end
          end)
        end)
        div({ class = "form-group form-grow" }, function()
          label({ ["for"] = "premiacao" }, "Premiação")
          input({ type="text", id="premiacao", name="premiacao", value=t.premiacao or "" })
        end)
      end)
      div({ class = "form-row" }, function()
        div({ class = "form-group" }, function()
          label({ ["for"] = "data_inicio" }, "Data de Início")
          input({ type="date", id="data_inicio", name="data_inicio", value=t.data_inicio or "" })
        end)
        div({ class = "form-group" }, function()
          label({ ["for"] = "data_fim" }, "Data de Fim")
          input({ type="date", id="data_fim", name="data_fim", value=t.data_fim or "" })
        end)
        div({ class = "form-group form-grow" }, function()
          label({ ["for"] = "imagem_url" }, "Imagem/Banner")
          input({ type="url", id="imagem_url", name="imagem_url", value=t.imagem_url or "" })
          if t.imagem_url and t.imagem_url ~= "" then
            div({ style="margin-top:.4rem" }, function()
              img({ src=t.imagem_url, alt=t.nome, style="max-width:120px;border-radius:6px" })
            end)
          end
        end)
      end)
      div({ class = "form-group" }, function()
        label({ ["for"] = "descricao" }, "Descrição")
        textarea({ id="descricao", name="descricao", rows="4" }, t.descricao or "")
      end)

      div({ class = "form-actions" }, function()
        a({ href="/admin/torneios", class="btn-cancelar" }, "Cancelar")
        button({ type="submit", class="btn-salvar" }, "💾 Salvar Alterações")
      end)
    end)
  end)
end)