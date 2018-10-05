#!/usr/bin/python

import sys
import xml.etree.ElementTree as ET

file=sys.argv[1]

TYPES = {
    'STRING' : 'String',
    'INTEGER' : 'int',
    'DOUBLE' : 'double'
}

tree = ET.parse(file)
root = tree.getroot()

for child in root:
        if child.attrib['key'] == 'workflow_variables':
            for var in child:
                name = None
                typ = None
                for entry in var:
                    if entry.attrib['key'] == 'name':
                        name = entry.attrib['value']
                    elif entry.attrib['key'] == 'class':
                        typ = entry.attrib['value']
                print name + ' ' + TYPES[typ]
            break
