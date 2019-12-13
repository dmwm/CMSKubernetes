#! /bin/sh

voms-proxy-init -voms cms -rfc
export X509_USER_PROXY=/tmp/x509up_u`id -u`
curl -k -vvv --key $X509_USER_PROXY --cert $X509_USER_PROXY -H "X-Rucio-Account:ewv" -A "rucio-clients/1.20.5" https://cms-rucio-auth-int.cern.ch:443/auth/x509
export token="ewv-/DC=ch/DC=cern/OU=Organic Units/OU=Users/CN=ewv/CN=644876/CN=Eric Wayne Vaandering-unknown-8cd70f4926774d8db144015f2e888136"


/afs/cern.ch/user/v/valya/public/hey_linux -n 1000 -H "X-Rucio-Auth-Token: $token" http://cms-rucio-int.cern.ch/whoami
curl -O -k  -H "X-Rucio-Auth-Token: $token" http://cms-rucio-int.cern.ch/rses/T3_US_NERSC
curl -O -k  -H "X-Rucio-Auth-Token: $token" http://cms-rucio-int.cern.ch/rses/T2_US_Nebraska
/afs/cern.ch/user/v/valya/public/hey_linux -n 10 -N 3 -c 2  -H "X-Rucio-Auth-Token: $token"  -U stress_test_urls.txt



curl -O -k  -H "X-Rucio-Auth-Token: $token" http://cms-rucio-int.cern.ch/accounts/whoami
curl -O -k  -H "X-Rucio-Auth-Token: $token" http://cms-rucio-int.cern.ch/accounts/whoami
curl -O -k  -H "X-Rucio-Auth-Token: $token" http://cms-rucio-int.cern.ch/rses/
curl -O -k  -H "X-Rucio-Auth-Token: $token" http://cms-rucio-int.cern.ch/accounts/whoami/
