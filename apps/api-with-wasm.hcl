Kind = "service-defaults"
Name = "api"
Protocol = "http"
EnvoyExtensions = [
  {
    Name = "builtin/wasm"
    Arguments = {
      SourceURL = "/consul/extensions/plugin.wasm"
      Config =  <<EOF
{
  "sqlKeywords": [
    "select", "where", " or ", " and ", "--", "1=1", " not ", "join", "union"
  ],
  "rateLimitRequests": "5",
  "rateLimitInterval": "10s"
}
EOF
    }
  }
]
