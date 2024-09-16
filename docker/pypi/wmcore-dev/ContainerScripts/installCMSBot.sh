git clone https://github.com/cms-sw/cms-bot
pushd cms-bot/

wget https://pypi.python.org/packages/source/r/requests/requests-2.3.0.tar.gz#md5=7449ffdc8ec9ac37bbcd286003c80f00
tar -xvf requests-2.3.0.tar.gz
rm -rf requests || true
mv requests-2.3.0/requests/ requests

popd
