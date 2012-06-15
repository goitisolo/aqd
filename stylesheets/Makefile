all: zones.html observations.html

zones.html: aqd2html.xsl example_B.xml
	xsltproc aqd2html.xsl example_B.xml >zones.html

observations.html: aqd2html.xsl example_E2a.xml
	xsltproc aqd2html.xsl example_E2a.xml  >observations.html
