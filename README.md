# alpine-mirror-status

Scripts to generate Alpine mirror statistics.

## Dependencies

```bash
apk add lua5.3-cjson lua5.3-http lua5.3-lustache lua5.3-lyaml
```

## Usage

### List of APKINDEX.tar.gz files

The base for checking all APKINDEX files is the provided apkindex.list file. This file is generated from the master mirror ie:

```bash
cd /var/www/localhost/htdocs
find alpine -name APKINDEX.tar.gz > apkindex.list
```

### Create a config file

Copy the sample config to a new file called config.lua and change the defaults if needed (ie the output directory).

### Generate json file

```bash
./generate-json.lua
```

Which will iterate over earch mirror/apkindex combination and make an http request to fetch the last-modified header.

### Generate html file

```bash
./genereate-html.lua
```

Which will generate two parts:

1. Generate a list of mirrors take from official mirrors.yaml file.
2. Compare all mirrors with master and generate a health report table per mirror.
