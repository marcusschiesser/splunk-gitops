FROM splunk/splunk:8.2.6 

# Apps that will be generated and added to the Splunk instance
ARG APPS="Splunk_ML_Toolkit my_app"
# TODO: dynamically generate SPLUNK_APPS_URL using a modified entrypoint
ENV SPLUNK_APPS_URL=/tmp/apps/Splunk_ML_Toolkit.tgz,/tmp/apps/my_app.tgz

USER root
# get splunkbase downloader
RUN pip install $(curl -s https://raw.githubusercontent.com/marcusschiesser/splunkbase-download/v1.0.0/requirements.txt)
RUN wget https://raw.githubusercontent.com/marcusschiesser/splunkbase-download/v1.0.0/download-splunkbase.py -O /bin/download-splunkbase.py && chmod +x /bin/download-splunkbase.py
# get dependencies from Splunkbase
# TODO: add support for dependencies from other sources, e.g. Github Releases
RUN --mount=type=secret,id=SPLUNKBASE_USERNAME --mount=type=secret,id=SPLUNKBASE_PASSWORD mkdir -p /tmp/apps && cd /tmp/apps && \
    # get Splunk_ML_Toolkit 
    download-splunkbase.py $(cat /run/secrets/SPLUNKBASE_USERNAME) $(cat /run/secrets/SPLUNKBASE_PASSWORD) 2890 5.3.1
# unpack dependencies (so we can reconfigure them if needed)
RUN cd /tmp/apps && \
    for f in *.tgz; do \
    tar xzf "$f"; \
    rm -f "$f"; \
    done
# copy system configuration to /tmp/defaults folder (ansible expects it there)
COPY ./config/system /tmp/defaults
# copy apps to /tmp/apps folder
COPY ./apps /tmp/apps
# add app configurations to the /tmp/apps folder
COPY ./config/apps /tmp/apps
# create tar balls for all apps (with configurations) so they can be used by SPLUNK_APPS_URL
RUN cd /tmp/apps && \
    for app in $APPS; do \
    tar czf "$app.tgz" "$app"; \
    rm -rf "$app"; \
    done
USER ansible
ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["start-service"]
