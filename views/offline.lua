-- views/offline.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "shadow-card erro-page" }, function()
    h2("📵 Sem Conexão")
    p("Você está offline. Verifique sua conexão com a internet.")
    p({ style = "margin-top:.5rem;font-size:.9rem;color:var(--text-muted)" },
      "Algumas páginas visitadas anteriormente podem estar disponíveis no cache.")
    a({ href = "/", class = "btn-voltar", onclick = "location.reload()" },
      "🔄 Tentar novamente")
  end)
end)