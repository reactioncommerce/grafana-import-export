# grafana-import-export

Simple scripts for import/export dashboards, datasources and alerts to
[Grafana](http://grafana.org/)

Support organizations.

Example was taken from https://gist.github.com/crisidev/bd52bdcc7f029be2f295 

## Dependencies
**[JQ](https://stedolan.github.io/jq/)** - to process .json

## Configuration
`config.sh` is used at runtime to configure the tools. An example file is
provided. Copy the configuration file that you'd like to use to `config.sh`.
Then you don't have to commit secrets in your config to the project.

Example: `cp config.example.sh config.sh`

### Configuration Contents
Replace **HOST** and **FILE_DIR** variables at `config.sh` with your own.
Also fill **ORGS** array with pairs ORGANIZATION:API_KEY. 

Two `CF_ACCESS_*` variables are available for use if you use CloudFlare Access
to protect your Grafana instance.

### Storing your dashboards
Remove the line `data/*` from `.gitignore` if you would like to store them in
source control.

## exporter
Run:
```
# Modify for your own source config file.
cp config.example.sh config.sh
./exporter.sh
```

Expected output:
```
./exporter.sh
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 21102    0 21102    0     0  53000      0 --:--:-- --:--:-- --:--:-- 53020

```

Look for exported .json dashboards and datasources at **FILE_DIR** path

## importer
To import all .json files from **FILE_DIR** to your Grafana:
```
# Modify for your own source config file.
cp config.example.sh config.sh
./importer.sh
```

To import only some of them:
```
./importer.sh organization/dashboards/dashboard.json organization/datasources/datasource.json
```

To import all for organization:
```
./importer.sh organization/dashboards/*.json organization/datasources/*.json
```
