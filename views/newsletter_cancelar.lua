-- views/newsletter_cancelar.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "shadow-card erro-page" }, function()
    if self.cancelado then
      h2("✅ Inscrição cancelada")
      p("Você foi removido da nossa newsletter. Sentiremos sua falta!")
      p({ style = "margin-top:.5rem;font-size:.9rem;color:var(--text-muted)" },
        "Se mudar de ideia, basta se cadastrar novamente na home.")
    else
      h2("❌ Link inválido")
      p("Este link de cancelamento é inválido ou já foi utilizado.")
    end
    a({ href = "/", class = "btn-voltar" }, "← Voltar para o início")
  end)
end)