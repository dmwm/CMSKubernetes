Before you start:
   * helm --help
   * helm plugin install https://github.com/chartmuseum/helm-push.git
     * this will install helm push plugin (sometimes called cm-push)
   * helm repo add cmsweb https://registry.cern.ch/chartrepo/cmsweb
   * helm repo list
   * helm search repo cmsweb
   * helm repo update

To adjust existing repo:

   * make changes to your helm package area
     * change version number of the chart (directory/Chart.yaml)
   * git commit -m "small fixes" <helm-package>
   * visit https://registry.cern.ch/harbor/projects to obtain your token
     password from your `<Name>->User Profile->CLI secret`
   * `helm cm-push --username=<name> --password=<secret> <pkg> <repo>`

To add to the repo:

   * adapt the version number the chart (directory/Chart.yaml)
   * helm package rucio-statsd-exporter
   * helm repo index .
   * git add [new .tgz files] # NO LONGER required for CERN registry
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
