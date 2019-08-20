FROM ibisba/knime-base:4.0.1

# Build argument for the workflow directory
ONBUILD ARG WORKFLOW_DIR="workflow/"
# Build argument for additional update sites
ONBUILD ARG UPDATE_SITES

# Create workflow directory and copy from host
ONBUILD RUN mkdir -p /payload
ONBUILD COPY $WORKFLOW_DIR /payload/workflow

# Create metadata directory
ONBUILD RUN mkdir -p /payload/meta

# Copy necessary scripts onto the image
COPY getversion.py /scripts/getversion.py
COPY listvariables.py /scripts/listvariables.py
COPY listplugins.py /scripts/listplugins.py
COPY run.sh /scripts/run.sh

# Let anyone run the workflow
RUN chmod +x /scripts/run.sh

# Add KNIME update site and trusted community update site that fit the version the workflow was created with
ONBUILD RUN full_version=$(python /scripts/getversion.py /payload/workflow/) \
&& version=$(python /scripts/getversion.py /payload/workflow/ | awk '{split($0,a,"."); print a[1]"."a[2]}') \
&& echo "http://update.knime.org/analytics-platform/$version" >> /payload/meta/updatesites \
&& echo "http://update.knime.org/community-contributions/trusted/$version" >> /payload/meta/updatesites \
# Add user provided update sites
&& echo $UPDATE_SITES | tr ',' '\n' >> /payload/meta/updatesites

# Save the workflow's variables in a file
ONBUILD RUN find /payload/workflow -name settings.xml -exec python /scripts/listplugins.py {} \; | sort -u | awk '!a[$0]++' > /payload/meta/features

ONBUILD RUN python /scripts/listvariables.py /payload/workflow

# Install required features
ONBUILD RUN "$KNIME_DIR/knime" -application org.eclipse.equinox.p2.director \
-r "$(cat /payload/meta/updatesites | tr '\n' ',' | sed 's/,*$//' | sed 's/^,*//')" \
-p2.arch x86_64 \
-profileProperties org.eclipse.update.install.features=true \
-i "$(cat /payload/meta/features | tr '\n' ',' | sed 's/,*$//' | sed 's/^,*//')" \
-p KNIMEProfile \
-nosplash

# Cleanup
ONBUILD RUN rm /scripts/getversion.py && rm /scripts/listvariables.py && rm /scripts/listplugins.py

ENTRYPOINT ["/scripts/run.sh"]
