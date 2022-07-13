FROM cmscloud/cc7-cvmfs:latest

# Install xrootd and it's dependencies & clone repository
WORKDIR /home/cmsusr/
ADD install.sh /home/cmsusr/
RUN sudo bash /home/cmsusr/install.sh
WORKDIR /home/cmsusr/dqmgui/

# Add Kerberos and run configuration
ADD run.sh /home/cmsusr/
ADD monitor.sh /home/cmsusr/

CMD sudo bash /home/cmsusr/run.sh