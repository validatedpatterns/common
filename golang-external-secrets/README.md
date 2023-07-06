# Subchart Update

When updating this sub-chart, please remember to tweak the image tag in values.yaml.
That is because we want to use -ubi images if possible and there is no suffix option, so
we just override the tag with the version + "-ubi"

The charts/ folder contains the ./charts/<subchart>-<version>.tgz that gets created by
the helm dependency commands. The subchart code lives in the 'subcharts/<name>'
folder and contains the extracted subchart yaml files.

## Steps

1. Edit the version in Chart.yaml
2. Run `./update-helm-dependency.sh`
3. Run `make test`
4. Check the commit size and diff
5. Commit to git
