To add to the repo:

   * adapt the version number the chart (directory/Chart.yaml)
   * helm package rucio-statsd-exporter
   * helm repo index .
   * git add [new .tgz files]
   * git commit and push

Full process should we want to adopt gh-pages is:

   * git checkout master
   * git pull
   * git checkout gh-pages
   * adapt the version number the chart (directory/Chart.yaml)
   * helm package [directory]
   * helm repo index .
   * git add ...
   * git commit ...
   * git push origin -f gh-pages
