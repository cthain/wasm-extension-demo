Kind = "service-defaults"
Name = "api"
Protocol = "http"
EnvoyExtensions = [
  {
    Name = "builtin/wasm"
    Arguments = {
      Source = {
        URL     = "http://file-server/waf.wasm"
        SHA256  = "c9ef17f48dcf0738b912111646de6d30575718ce16c0cbde3e38b21bb1771807"
        Timeout = 3
      }
      Config =  <<EOF
{
  "rules": [
    "SecDebugLogLevel 3",
    "SecRuleEngine On",
    "SecRule REQUEST_URI \"@streq /admin\" \"id:101,phase:1,t:lowercase,deny\""
  ]
}
EOF
    }
  }
]
