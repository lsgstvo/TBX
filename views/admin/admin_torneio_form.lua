local Widget = require("lapis.html").Widget

local function campos_torneio(vals)
  vals = vals or {}
  div({ class = "form-group" }, function()
    label({ ["for"] = "nome" }, "Nome do Torneio *")
    input({ type="text", id="nome", name="nome",
            value=vals.nome or "", required=true,
            placeholder="Ex: Copa Portal Gamer 2026" })
  end)
  div({ class = "form-row" }, function()
    div({ class = "form-group form-grow" }, function()
      label({ ["for"] = "jogo" }, "Jogo")
      input({ type="text", id="jogo", name="jogo",
              value=vals.jogo or "", placeholder="Ex: Valorant" })
    end)
    div({ class = "form-group" }, function()
      label({ ["for"] = "status" }, "Status")
      element("select", { id="status", name="status" }, function()
        for _, s in ipairs({ {"upcoming","⏳ Em Breve"}, {"live","🔴 Ao Vivo"}, {"finished","✅ Encerrado"} }) do
          local attrs = { value=s[1] }
          if vals.status == s[1] then attrs.selected = true end
          option(attrs, s[2])
        end
      end)
    end)
    div({ class = "form-group form-grow" }, function()
      label({ ["for"] = "premiacao" }, "Premiação")
      input({ type="text", id="premiacao", name="premiacao",
              value=vals.premiacao or "", placeholder="Ex: R$ 5.000 em prêmios" })
    end)
  end)
  div({ class = "form-row" }, function()
    div({ class = "form-group" }, function()
      label({ ["for"] = "data_inicio" }, "Data de Início")
      input({ type="date", id="data_inicio", name="data_inicio",
              value=vals.data_inicio or "" })
    end)
    div({ class = "form-group" }, function()
      label({ ["for"] = "data_fim" }, "Data de Fim")
      input({ type="date", id="data_fim", name="data_fim",
              value=vals.data_fim or "" })
    end)
    div({ class = "form-group form-grow" }, function()
      label({ ["for"] = "imagem_url" }, "Imagem/Banner")
      input({ type="url", id="imagem_url", name="imagem_url",
              value=vals.imagem_url or "", placeholder="https://..." })
    end)
  end)
  div({ class = "form-group" }, function()
    label({ ["for"] = "descricao" }, "Descrição")
    textarea({ id="descricao", name="descricao", rows="4",
               placeholder="Regras, formato, informações gerais..." },
             vals.descricao or "")
  end)
end

-- ── Formulário Novo ──────────────────────────────────────────────────────────
return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    h2("🏆 Novo Torneio")
    if self.erro then div({ class = "alert alert-erro" }, self.erro) end
    form({ method="POST", action="/admin/torneios/novo", class="admin-form" }, function()
      campos_torneio({})
      div({ class = "form-actions" }, function()
        a({ href="/admin/torneios", class="btn-cancelar" }, "Cancelar")
        button({ type="submit", class="btn-salvar" }, "💾 Criar Torneio")
      end)
    end)
  end)
end)