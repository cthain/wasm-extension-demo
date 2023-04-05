Kind = "service-defaults"
Name = "api"
Protocol = "http"
EnvoyExtensions = [
  {
    Name = "builtin/wasm"
    Arguments = {
      Protocol = "http"
      ListenerType = "inbound"
      PluginConfig = {
        VmConfig = {
          Code = {
            Remote = {
              HttpURI = {
                Service = {
                  Name = "file-server"
                }
                URI = "https://file-server/waf.wasm"
              }
              SHA256  = "c9ef17f48dcf0738b912111646de6d30575718ce16c0cbde3e38b21bb1771807"
            }
          }
        }
      Configuration =  <<EOF
{
  "rules": [
    "Include @demo-conf",
    "Include @crs-setup-demo-conf",
    "SecDebugLogLevel 9",
    "SecRuleEngine On",
    "Include @owasp_crs/*.conf"
  ]
}
EOF
      }
    }
  }
]
