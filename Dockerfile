ARG SPLUNK_VERSION=8.2.6

FROM ghcr.io/marcusschiesser/splunk-gitops-builder:v1.0.2 as builder
ARG SPLUNKBASE_USERNAME
ARG SPLUNKBASE_PASSWORD
ARG GITHUB_PAT 

# Use 'download-github-releases.sh' to download tar balls from your public Github Releases
RUN download-github-releases.sh "https://api.github.com/repos/marcusschiesser/splunk-root-config/releases/tags/v1.0.0"
# You can also use 'download-github-releases.sh' to download tar balls from your private Github Releases by adding a [PAT](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) as first argument:
# RUN download-github-releases.sh "${GITHUB_PAT}" "https://api.github.com/repos/marcusschiesser/splunk-root-config/releases/tags/v1.0.0"
# Use 'download-splunkbase.sh' to download apps from Splunkbase - here as an example, get Splunk_SA_Scientific_Python_linux_x86_64, Splunk_ML_Toolkit and Splunk App for Data Science and Deep Learning 
# This is commented out for copyright reasons in the example build
# RUN download-splunkbase.sh "${SPLUNKBASE_USERNAME}" "${SPLUNKBASE_PASSWORD}" "2882-3.0.2 2890-5.3.1 4607-3.9.0"
# copy local apps
COPY ./apps /tmp/apps
# add app configurations to the /tmp/apps folder
COPY ./config/apps /tmp/apps
RUN create-tarballs.sh

FROM splunk/splunk:${SPLUNK_VERSION}
# Apps that will be generated and added to the Splunk instance
ENV SPLUNK_APPS_URL="SPLUNK_APPS_URL=/tmp/apps/splunk_root_config.tgz,/tmp/apps/my_app.tgz"
# Use this version if you add the splunkbase apps
# ENV SPLUNK_APPS_URL="SPLUNK_APPS_URL=/tmp/apps/splunk_root_config.tgz,/tmp/apps/my_app.tgz,/tmp/apps/Splunk_SA_Scientific_Python_linux_x86_64.tgz,/tmp/apps/Splunk_ML_Toolkit.tgz,/tmp/apps/mltk-container.tgz"
USER ansible
COPY --from=builder /tmp/apps /tmp/apps
ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["start-service"]
