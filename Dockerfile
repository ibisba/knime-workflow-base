FROM knime/knime:3.6.1

USER root
WORKDIR $HOME_DIR

# Create workflow directory and copy from host
ONBUILD RUN mkdir -p workflow
ONBUILD COPY workflow workflow/

# Copy necessary scripts onto the image
COPY listplugins.py listplugins.py
COPY getversion.py getversion.py
COPY listvariables.py listvariables.py
COPY run.sh run.sh

# Let user knime run the workflow
RUN chmod 755 run.sh

# Add KNIME update site and trusted community update site that fit the version the workflow was created with
ONBUILD RUN echo "http://update.knime.org/analytics-platform/$(python getversion.py workflow/workflow.knime | awk '{split($0,a,"."); print a[1]"."a[2]}')" >> updatesites
ONBUILD RUN echo "http://update.knime.org/community-contributions/trusted/$(python getversion.py workflow/workflow.knime | awk '{split($0,a,"."); print a[1]"."a[2]}')" >> updatesites

ONBUILD RUN cat updatesites

# Save the workflow's variables in a file
ONBUILD RUN python listvariables.py workflow/workflow.knime > meta

# Find required features
ONBUILD RUN find workflow -name settings.xml -exec python listplugins.py {} \; | sort -u > features

# Update org.knime.product.desktop
#RUN $KNIME_DIR/knime -application org.eclipse.equinox.p2.director \
#-r $(cat updatesites | tr '\n' ',' | sed 's/,*$//' | sed 's/^,*//') \
#-p2.arch x86_64 \
#-profileProperties org.eclipse.update.install.features=true \
#-i "org.knime.product.desktop" \
#-u "org.knime.product.desktop" \
#-p KNIMEProfile \
#-nosplash

# Install required features
ONBUILD RUN $KNIME_DIR/knime -application org.eclipse.equinox.p2.director \
-r $(cat updatesites | tr '\n' ',' | sed 's/,*$//' | sed 's/^,*//') \
-p2.arch x86_64 \
-profileProperties org.eclipse.update.install.features=true \
-i "$(cat features | tr '\n' ',' | sed 's/,*$//' | sed 's/^,*//')" \
-p KNIMEProfile \
-nosplash

# Cleanup
ONBUILD RUN rm listplugins.py && rm getversion.py

# For inspection of the log file.
# RUN tail -n 30 -f $(find /usr/local/knime_3.1.2/configuration/*.log -printf "%T@ %p\n" | sort -n | tail -n 1 | cut -d' ' -f 2-)

ENTRYPOINT ["/home/knime/run.sh"]
