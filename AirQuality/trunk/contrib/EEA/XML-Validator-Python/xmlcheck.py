# -*- coding: utf-8 -*-

# This script opens an XML file called example.xml then runs through all
# elements until an exception happens or the end of file.

from xml.dom import pulldom

myfile = open("example.xml")
events = pulldom.parse( myfile )
for (event,node) in events:
    pass
myfile.close()
