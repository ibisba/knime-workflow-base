#!/usr/bin/python

import sys
import xml.etree.ElementTree as ET

file=sys.argv[1]

tree = ET.parse(file)
root = tree.getroot()

knime_version = None

for child in root:
        if child.attrib['key'] == 'created_by':
            knime_version = child.attrib['value']
            break


#print 'version\t' + knime_version[0:knime_version.rfind(".")]
#print 'update_site\t' + 'http://update.knime.org/analytics-platform/' \
#        + knime_version[0:knime_version.find(".", knime_version.find(".") + 1)] + "/"

print  knime_version[0:knime_version.rfind(".")]
