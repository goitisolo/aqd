ENV=--stringparam envelopeurl http://cdr.eionet.europa.eu/gb/envsaou

all: B_GB_Zones.ttl C_GB_AssessmentRegime.ttl D_GB_Sample.ttl \
D_GB_SamplingPoint.ttl D_GB_StationProcess.ttl D_GB_Station.ttl \
E2a_GB2013032713version4.ttl GB_e-ReportingHeader.ttl G_GB_attainment_16_Jan.ttl

%.rdf: %.xml aqd2rdf.xsl
	xsltproc $(ENV) --stringparam filename $< aqd2rdf.xsl $< > $@

%.n3: %.rdf
	rapper -I urn:x: $< > $@

%.ttl: %.rdf
	rapper -I urn:x: -o turtle $< > $@

clean:
	rm -f *.rdf *.html *.n3 *.ttl

