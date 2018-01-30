local conf = {}

conf.version = "v0.0.1"
conf.apkindex_list = "apkindex.list"
-- private.yaml is taken from alpine mirrors repo
conf.mirrors_yaml = "/path/to/private.yaml"
conf.master_url = "http://rsync.alpinelinux.org/alpine/"
conf.outdir = "_out"
conf.mirrors_html = "index.html"
conf.status_json = "status.json"
conf.http_timeout = 3
conf.archs = { "x86", "x86_64", "armhf", "aarch64", "ppc64le", "s390x" }
conf.repos = { "main", "community", "testing", "backports" }

return conf
