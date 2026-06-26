storage "raft" {
  path    = "/vault/data"
  node_id = "vault-node-1"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/vault/certs/vault.crt"
  tls_key_file  = "/vault/certs/vault.key"
}

api_addr     = "https://192.168.50.200:8200"
cluster_addr = "https://192.168.50.200:8201"
ui           = true
disable_mlock = true