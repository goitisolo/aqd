xquery version "3.0" encoding "UTF-8";

(:~
: User: George Sofianos
: Date: 6/21/2016
: Time: 6:37 PM
:)

module namespace query = "aqd-query";
import module namespace sparqlx = "aqd-sparql" at "aqd-sparql.xquery";
import module namespace common = "aqd-common" at "aqd-common.xquery";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";

(: Normal InspireId Fetch - This should be the default :)
(: B :)
declare function query:getZone($url as xs:string?) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
  PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
  PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>

  SELECT ?inspireLabel
  WHERE {
      ?zone a aqd:AQD_Zone ;
      aqd:inspireId ?inspireId .
      ?inspireId rdfs:label ?inspireLabel .
  FILTER (CONTAINS(str(?zone), '" || $url || "'))
  }"   
};

(: C :)
declare function query:getAssessmentRegime($url as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

   SELECT ?localId ?inspireLabel
   WHERE {
          ?regime a aqd:AQD_AssessmentRegime ;
          aqd:inspireId ?inspireId .
          ?inspireId rdfs:label ?inspireLabel .
          ?inspireId aqd:localId ?localId .
          FILTER (CONTAINS(str(?regime), '" || $url || "'))
   }"
};

(: D :)
declare function query:getSamplingPointProcess($url as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

   SELECT ?samplingPointProcess ?inspireId ?inspireLabel ?localId ?namespace
   WHERE {
           ?samplingPointProcess a aqd:AQD_SamplingPointProcess;
           aqd:inspireId ?inspireId .
           ?inspireId rdfs:label ?inspireLabel .
           ?inspireId aqd:localId ?localId .
           ?inspireId aqd:namespace ?namespace .
   FILTER(CONTAINS(str(?samplingPointProcess), '" || $url || "'))
   }"
};

declare function query:getModelProcess($url as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

   SELECT ?samplingPointProcess ?inspireId ?inspireLabel ?localId ?namespace
   WHERE {
           ?samplingPointProcess a aqd:AQD_ModelProcess;
           aqd:inspireId ?inspireId .
           ?inspireId rdfs:label ?inspireLabel .
           ?inspireId aqd:localId ?localId .
           ?inspireId aqd:namespace ?namespace .
   FILTER(CONTAINS(str(?samplingPointProcess), '" || $url || "'))
   }"
};

declare function query:getSample($url as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

   SELECT ?sample ?inspireId ?inspireLabel ?localId ?namespace
   WHERE {
           ?sample a aqd:AQD_Sample;
           aqd:inspireId ?inspireId .
           ?inspireId rdfs:label ?inspireLabel .
           ?inspireId aqd:localId ?localId .
           ?inspireId aqd:namespace ?namespace .
   FILTER(CONTAINS(str(?sample), '" || $url || "'))
   }"
};

declare function query:getModelArea($url as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

   SELECT ?sample ?inspireId ?inspireLabel ?localId ?namespace
   WHERE {
           ?sample a aqd:AQD_modelArea;
           aqd:inspireId ?inspireId .
           ?inspireId rdfs:label ?inspireLabel .
           ?inspireId aqd:localId ?localId .
           ?inspireId aqd:namespace ?namespace .
   FILTER(CONTAINS(str(?sample), '" || $url || "'))
   }"
};

declare function query:getSamplingPoint($cdrUrl as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

   SELECT ?localId ?inspireLabel
   WHERE {
         ?samplingPoint a aqd:AQD_SamplingPoint;
         aqd:inspireId ?inspireId .
         ?inspireId rdfs:label ?inspireLabel .
         ?inspireId aqd:localId ?localId .
         ?inspireId aqd:namespace ?namespace .
   FILTER(CONTAINS(str(?samplingPoint), '" || $cdrUrl || "'))
   }"
};

(: M :)
declare function query:getModel($url as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

   SELECT ?model ?inspireId ?inspireLabel ?localId ?namespace
   WHERE {
      ?model a aqd:AQD_Model ;
      aqd:inspireId ?inspireId .
      ?inspireId rdfs:label ?inspireLabel .
      ?inspireId aqd:localId ?localId .
      ?inspireId aqd:namespace ?namespace .
      FILTER(CONTAINS(str(?model), '" || $url || "'))
      }"
};

(: G :)
declare function query:getAttainment($url as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

   SELECT ?inspireLabel
   WHERE {
      ?attainment a aqd:AQD_Attainment;
      aqd:inspireId ?inspireId .
      ?inspireId rdfs:label ?inspireLabel .
      FILTER (CONTAINS(str(?attainment), '" || $url || "'))
   }"
};








(: Feature Types queries - These queries return all ids of the specified feature type :)
declare function query:getAllZoneIds($namespaces as xs:string*) as xs:string {
  "PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    SELECT ?inspireLabel
    WHERE {
      ?zone a aqd:AQD_Zone;
      aqd:inspireId ?inspireid .
      ?inspireid rdfs:label ?inspireLabel .
      ?inspireid aqd:namespace ?namespace
      FILTER (?namespace in ('" || string-join($namespaces, "' , '") || "'))
     }"
};

declare function query:getAllFeatureIds($featureTypes as xs:string*, $namespaces as xs:string*) as xs:string {
  let $pre := "PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    SELECT ?inspireLabel WHERE {"
  let $mid := string-join(
    for $featureType in $featureTypes
    return "
    {
      ?zone a " || $featureType || ";
      aqd:inspireId ?inspireid .
      ?inspireid rdfs:label ?inspireLabel .
      ?inspireid aqd:namespace ?namespace
      FILTER (?namespace in ('" || string-join($namespaces, "' , '") || "'))
     }", " UNION ")
  let $end := "}"
  return $pre || $mid || $end
};

(: Generic queries :)
declare function query:deliveryExists($obligations as xs:string*, $countryCode as xs:string, $dir as xs:string, $reportingYear as xs:string) as xs:boolean {
  let $query :=
      "PREFIX aqd: <http://rod.eionet.europa.eu/schema.rdf#>
       SELECT ?envelope
       WHERE {
          ?envelope a aqd:Delivery ;
          aqd:obligation ?obligation ;
          aqd:released ?date ;
          aqd:hasFile ?file ;
          aqd:period ?period
          FILTER(str(?obligation) in ('" || string-join($obligations, "','") || "'))
          FILTER(CONTAINS(str(?envelope), '" || common:getCdrUrl($countryCode) || $dir || "'))
          FILTER(STRSTARTS(str(?period), '" || $reportingYear || "'))
       }"
   return count(sparqlx:run($query)//sparql:binding[@name = 'envelope']/sparql:uri) > 0
};

declare function query:getLangCodesSparql() as xs:string {
  "PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
   SELECT distinct ?code ?label ?concepturl
   WHERE {
      ?concepturl a skos:Concept .
      {?concepturl skos:inScheme <http://dd.eionet.europa.eu/vocabulary/common/iso639-3/>;
                  skos:prefLabel ?label;
                  skos:notation ?code}
      UNION
      {?concepturl skos:inScheme <http://dd.eionet.europa.eu/vocabulary/common/iso639-5/>;
                  skos:prefLabel ?label;
                  skos:notation ?code}

    }"
};

(: C - Remove comment after migration :)
declare function query:getModelEndPosition($latestDEnvelopes as xs:string*, $startDate as xs:string, $endDate as xs:string) as xs:string {
  let $last := count($latestDEnvelopes)
  let $filters :=
    for $x at $pos in $latestDEnvelopes
    return
      if (not($pos = $last)) then
        concat("CONTAINS(str(?zone), '", $x , "') || ")
      else
        concat("CONTAINS(str(?zone), '", $x , "')")
  let $filters := string-join($filters, "")
  return
    concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

SELECT DISTINCT ?inspireLabel
    WHERE {
        ?zone a aqd:AQD_Model ;
        aqd:inspireId ?inspireId .
        ?inspireId rdfs:label ?inspireLabel .
        ?zone aqd:observingCapability ?observingCapability .
        ?observingCapability aqd:observingTime ?observingTime .
        ?observingTime aqd:beginPosition ?beginPosition .
        optional {?observingTime aqd:endPosition ?endPosition} .
        FILTER(xsd:date(SUBSTR(xsd:string(?beginPosition),1,10)) <= xsd:date('", $endDate, "')) .
        FILTER(!bound(?endPosition) or (xsd:date(SUBSTR(xsd:string(?endPosition),1,10)) > xsd:date('", $startDate, "'))) .
        FILTER(", $filters, ")
}")
};

declare function query:getSamplingPointEndPosition($latestDEnvelopes as xs:string*, $startDate as xs:string, $endDate as xs:string) as xs:string {
  let $last := count($latestDEnvelopes)
  let $filters :=
    for $x at $pos in $latestDEnvelopes
    return
      if (not($pos = $last)) then
        concat("CONTAINS(str(?zone), '", $x , "') || ")
      else
        concat("CONTAINS(str(?zone), '", $x , "')")
  let $filters := string-join($filters, "")
  return
    concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
        PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

        SELECT DISTINCT ?inspireLabel
        WHERE {
            ?zone a aqd:AQD_SamplingPoint ;
            aqd:inspireId ?inspireId .
            ?inspireId rdfs:label ?inspireLabel .
            ?zone aqd:observingCapability ?observingCapability .
            ?observingCapability aqd:observingTime ?observingTime .
            ?observingTime aqd:beginPosition ?beginPosition .
            optional {?observingTime aqd:endPosition ?endPosition }
            FILTER(xsd:date(SUBSTR(xsd:string(?beginPosition),1,10)) <= xsd:date('", $endDate, "')) .
            FILTER(!bound(?endPosition) or (xsd:date(SUBSTR(xsd:string(?endPosition),1,10)) > xsd:date('", $startDate, "'))) .
            FILTER(", $filters, ")
    }")
};

(: Returns latest report envelope for this country and Year :)
declare function query:getLatestEnvelope($cdrUrl as xs:string, $reportingYear as xs:string) as xs:string {
  let $query := concat("PREFIX aqd: <http://rod.eionet.europa.eu/schema.rdf#>
  SELECT *
   WHERE {
        ?envelope a aqd:Delivery ;
        aqd:released ?date ;
        aqd:hasFile ?file ;
        aqd:period ?period
        FILTER(CONTAINS(str(?envelope), '", $cdrUrl, "'))
        FILTER(STRSTARTS(str(?period), '", $reportingYear, "'))
  } order by desc(?date)
limit 1")
  let $result := data(sparqlx:run($query)//sparql:binding[@name='envelope']/sparql:uri)
  return if ($result) then $result else "FILENOTFOUND"
};

(: Returns latest report envelope for this country :)
declare function query:getLatestEnvelope($cdrUrl as xs:string) as xs:string {
  let $query :=
    "PREFIX aqd: <http://rod.eionet.europa.eu/schema.rdf#>
     SELECT *
     WHERE {
        ?envelope a aqd:Delivery ;
        aqd:released ?date ;
        aqd:hasFile ?file ;
        aqd:period ?period
        FILTER(CONTAINS(str(?envelope), '" || $cdrUrl || "'))
  } order by desc(?date)
limit 1"
  let $result := data(sparqlx:run($query)//sparql:binding[@name='envelope']/sparql:uri)
  return if ($result) then $result else "FILENOTFOUND"
};

declare function query:getEnvelopes($cdrUrl as xs:string, $reportingYear as xs:string) as xs:string* {
  let $query :=
    "PREFIX aqd: <http://rod.eionet.europa.eu/schema.rdf#>
     SELECT *
     WHERE {
        ?envelope a aqd:Delivery ;
        aqd:released ?date ;
        aqd:hasFile ?file ;
        aqd:period ?period
        FILTER(CONTAINS(str(?envelope), '" || $cdrUrl || "'))
        FILTER(STRSTARTS(str(?period), '" || $reportingYear || "'))
     } order by desc(?date)"
     let $result := data(sparqlx:run($query)//sparql:binding[@name='envelope']/sparql:uri)
  return $result
};

declare function query:getAllRegimeIds($namespaces as xs:string*) as xs:string* {
  let $query := "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>

   SELECT *
   WHERE {
        ?regime a aqd:AQD_AssessmentRegime ;
        aqd:inspireId ?inspireId .
        ?inspireId rdfs:label ?inspireLabel .
        ?inspireId aqd:namespace ?namespace
        FILTER(NOT(CONTAINS(str(?regime), 'c_preliminary')))
        FILTER(str(?namespace) in ('" || string-join($namespaces, "','") || "'))
  }"
  return data(sparqlx:run($query)//sparql:binding[@name='inspireLabel']/sparql:literal)
};

declare function query:getAllAttainmentIds2($namespaces as xs:string*) as xs:string* {
  let $query := "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>

   SELECT *
   WHERE {
        ?attainment a aqd:AQD_Attainment ;
        aqd:inspireId ?inspireId .
        ?inspireId rdfs:label ?inspireLabel .
        ?inspireId aqd:namespace ?namespace
        FILTER(str(?namespace) in ('" || string-join($namespaces, "','") || "'))
  }"
  return data(sparqlx:run($query)//sparql:binding[@name='inspireLabel']/sparql:literal)
};

declare function query:getPollutantCodeAndProtectionTarge($cdrUrl as xs:string, $bDir as xs:string) as xs:string {
  concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

      SELECT ?zone ?inspireId ?inspireLabel ?pollutants ?pollutantCode ?protectionTarget
        WHERE {
              ?zone a aqd:AQD_Zone ;
              aqd:inspireId ?inspireId .
              ?inspireId rdfs:label ?inspireLabel .
              ?zone aqd:pollutants ?pollutants .
              ?pollutants aqd:pollutantCode ?pollutantCode .
              ?pollutants aqd:protectionTarget ?protectionTarget .
      FILTER (CONTAINS(str(?zone), '", $cdrUrl, $bDir, "'))
    }")
};

declare function query:getC31($cdrUrl as xs:string, $reportingYear as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
  PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

  SELECT DISTINCT
  ?Pollutant
  ?ProtectionTarget
  count(distinct bif:concat(str(?Zone), str(?pollURI), str(?ProtectionTarget))) AS ?countOnB

  WHERE {
  ?zoneURI a aqd:AQD_Zone;
  aqd:zoneCode ?Zone;
  aqd:pollutants ?polltargetURI;
  aqd:inspireId ?inspireId;
  aqd:designationPeriod ?designationPeriod .
  ?designationPeriod aqd:beginPosition ?beginPosition .
  OPTIONAL { ?designationPeriod aqd:endPosition ?endPosition . }
  ?inspireId aqd:namespace ?Namespace .

  ?polltargetURI aqd:protectionTarget ?ProtectionTarget .
  ?polltargetURI aqd:pollutantCode ?pollURI .
  ?pollURI rdfs:label ?Pollutant .
  FILTER regex(?pollURI,'') .
  FILTER (((xsd:date(substr(str(?beginPosition),1,10)) <= xsd:date('" || $reportingYear || "-01-01')) AND (not(bound(?endPosition)) ||
xsd:date(substr(str(?endPosition),1,10)) >= xsd:date('" || $reportingYear || "-12-31')))) .
  FILTER CONTAINS(str(?zoneURI),'" || $cdrUrl || "') .
  }"
};

declare function query:getG14($envelopeB as xs:string, $envelopeC as xs:string, $reportingYear as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
PREFIX prop: <http://dd.eionet.europa.eu/property/>

  SELECT *

  WHERE {{
  SELECT DISTINCT
  str(?Pollutant) as ?Pollutant
  str(?ProtectionTarget) as ?ProtectionTarget
  count(distinct bif:concat(str(?Zone), str(?pollURI), str(?ProtectionTarget))) AS ?countOnB

  WHERE {
    ?zoneURI a aqd:AQD_Zone;
       aqd:zoneCode ?Zone;
       aqd:pollutants ?polltargetURI;
       aqd:inspireId ?inspireId;
       aqd:designationPeriod ?designationPeriod .
       ?designationPeriod aqd:beginPosition ?beginPosition .
       OPTIONAL { ?designationPeriod aqd:endPosition ?endPosition . }
       ?inspireId aqd:namespace ?Namespace .
       ?polltargetURI aqd:protectionTarget ?ProtectionTarget .
       ?polltargetURI aqd:pollutantCode ?pollURI .
       ?pollURI rdfs:label ?Pollutant
       FILTER (((xsd:date(substr(str(?beginPosition),1,10)) <= xsd:date('" || $reportingYear || "-01-01')) AND (not(bound(?endPosition)) ||
xsd:date(substr(str(?endPosition),1,10)) >= xsd:date('" || $reportingYear || "-12-31')))) .
       FILTER CONTAINS(str(?zoneURI),'" || $envelopeB || "') .
  }}
  {
  SELECT DISTINCT
  str(?Pollutant) as ?Pollutant
  str(?ProtectionTarget) as ?ProtectionTarget
  count(distinct bif:concat(str(?Zone), str(?pollURI), str(?ProtectionTarget))) AS ?countOnC

  WHERE {
    ?areURI a aqd:AQD_AssessmentRegime;
       aqd:zone ?Zone;
       aqd:pollutant ?pollURI;
       aqd:assessmentThreshold ?areThre ;
       aqd:inspireId ?inspireId .
       ?inspireId aqd:namespace ?Namespace .
       ?areThre aqd:environmentalObjective ?envObj .
       ?envObj aqd:protectionTarget ?ProtectionTarget .
       ?pollURI rdfs:label ?Pollutant .
  FILTER CONTAINS(str(?areURI),'" || $envelopeC || "') .
  }}
  }"
};

(: ---- SPARQL methods --- :)
declare function query:getTimeExtensionExemption($cdrUrl as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
        PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

        SELECT ?zone ?timeExtensionExemption ?localId
        WHERE {
                ?zone a aqd:AQD_Zone ;
                aqd:timeExtensionExemption ?timeExtensionExemption .
                ?zone aqd:inspireId ?inspireid .
                ?inspireid aqd:localId ?localId
        FILTER (CONTAINS(str(?zone), '" || $cdrUrl || "b/') and (?timeExtensionExemption != 'http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/none'))
      }"
};

declare function query:getG13($envelopeUrl as xs:string, $reportingYear as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>

           SELECT ?inspireLabel ?pollutant ?objectiveType ?reportingMetric ?protectionTarget
           WHERE {
                  ?regime a aqd:AQD_AssessmentRegime ;
                  aqd:assessmentThreshold ?assessmentThreshold ;
                  aqd:pollutant ?pollutant ;
                  aqd:inspireId ?inspireId .
                  ?inspireId rdfs:label ?inspireLabel .
                  ?inspireId aqd:localId ?localId .
                  ?regime aqd:declarationFor ?declaration .
                  ?declaration aq:reportingBegin ?reportingYear .
                  ?assessmentThreshold aq:objectiveType ?objectiveType .
                  ?assessmentThreshold aq:reportingMetric ?reportingMetric .
                  ?assessmentThreshold aq:protectionTarget ?protectionTarget .
           FILTER (CONTAINS(str(?regime), '" || $envelopeUrl || "c/'))
           FILTER (strstarts(str(?reportingYear), '" || $reportingYear || "'))

       }"
};

declare function query:getAssessmentMethods() as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>

   SELECT ?assessmentRegime ?inspireId ?localId ?inspireLabel ?assessmentMethods  ?assessmentMetadata ?assessmentMetadataNamespace ?assessmentMetadataId ?samplingPointAssessmentMetadata ?metadataId ?metadataNamespace
   WHERE {
          ?assessmentRegime a aqd:AQD_AssessmentRegime ;
          aqd:inspireId ?inspireId .
          ?inspireId rdfs:label ?inspireLabel .
          ?inspireId aqd:localId ?localId .
          ?assessmentRegime aqd:assessmentMethods ?assessmentMethods .
          ?assessmentMethods aqd:modelAssessmentMetadata ?assessmentMetadata .
          ?assessmentMetadata aq:inspireNamespace ?assessmentMetadataNamespace .
          ?assessmentMetadata aq:inspireId ?assessmentMetadataId .
          OPTIONAL { ?assessmentMethods aqd:samplingPointAssessmentMetadata ?samplingPointAssessmentMetadata. }
          OPTIONAL {?samplingPointAssessmentMetadata aq:inspireId ?metadataId. }
          OPTIONAL {?samplingPointAssessmentMetadata aq:inspireNamespace ?metadataNamespace . }
         }"
};

declare function query:getSamplingPointAssessmentMetadata() as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>

   SELECT ?assessmentRegime ?inspireId ?localId ?inspireLabel ?assessmentMethods  ?samplingPointAssessmentMetadata ?metadataId ?metadataNamespace
   WHERE {
          ?assessmentRegime a aqd:AQD_AssessmentRegime ;
          aqd:inspireId ?inspireId .
          ?inspireId rdfs:label ?inspireLabel .
          ?inspireId aqd:localId ?localId .
          ?assessmentRegime aqd:assessmentMethods ?assessmentMethods .
          ?assessmentMethods aqd:samplingPointAssessmentMetadata ?samplingPointAssessmentMetadata.
          ?samplingPointAssessmentMetadata aq:inspireId ?metadataId.
          ?samplingPointAssessmentMetadata aq:inspireNamespace ?metadataNamespace.
          }"
};
(: TODO fix this to look at latest envelope :)
declare function query:getPollutantlD($cdrUrl as xs:string) as xs:string {
  concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
            PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
            PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

          SELECT distinct concat(?inspireLabel, '#', str(?pollutantCode)) as ?key
          WHERE {
                 ?zone a aqd:AQD_Zone ;
                  aqd:inspireId ?inspireId .
                 ?inspireId rdfs:label ?inspireLabel .
                 ?zone aqd:pollutants ?pollutants .
                 ?pollutants aqd:pollutantCode ?pollutantCode .
          FILTER (CONTAINS(str(?zone), '", $cdrUrl, "b/'))
          }")
};

declare function query:getSamplingPointFromFiles($url as xs:string*) as xs:string {
  let $filters :=
    for $x in $url
    return "STRSTARTS(str(?samplingPoint), '" || $x || "')"
  let $filters := "FILTER(" || string-join($filters, " OR ") || ")"
  return
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

   SELECT ?samplingPoint ?inspireLabel
   WHERE {
         ?samplingPoint a aqd:AQD_SamplingPoint;
         aqd:inspireId ?inspireId .
         ?inspireId rdfs:label ?inspireLabel .
         ?inspireId aqd:localId ?localId .
         ?inspireId aqd:namespace ?namespace . " || $filters ||"
   }"
};

declare function query:getModelFromFiles($url as xs:string*) as xs:string {
  let $filters :=
    for $x in $url
    return "STRSTARTS(str(?samplingPoint), '" || $x || "')"
  let $filters := "FILTER(" || string-join($filters, " OR ") || ")"
  return
    "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

   SELECT ?samplingPoint ?inspireLabel
   WHERE {
         ?samplingPoint a aqd:AQD_Model;
         aqd:inspireId ?inspireId .
         ?inspireId rdfs:label ?inspireLabel .
         ?inspireId aqd:localId ?localId .
         ?inspireId aqd:namespace ?namespace . " || $filters ||"
   }"
};

declare function query:getSamplingPointMetadataFromFiles($url as xs:string*) as xs:string {
  let $filters :=
    for $x in $url
    return "STRSTARTS(str(?samplingPoint), '" || $x || "')"
  let $filters := "FILTER(" || string-join($filters, " OR ") || ")"
  return
   "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

   SELECT ?localId ?featureOfInterest ?procedure ?observedProperty ?inspireLabel
   WHERE {
         ?samplingPoint a aqd:AQD_SamplingPoint;
         aqd:observingCapability ?observingCapability;
         aqd:inspireId ?inspireId .
         ?inspireId rdfs:label ?inspireLabel .
         ?inspireId aqd:localId ?localId .
         ?inspireId aqd:namespace ?namespace .
         ?observingCapability aqd:featureOfInterest ?featureOfInterest .
         ?observingCapability aqd:procedure ?procedure .
         ?observingCapability aqd:observedProperty ?observedProperty . " || $filters ||"
   }"
};

declare function query:getModelMetadataFromFiles($url as xs:string*) as xs:string {
  let $filters :=
    for $x in $url
    return "STRSTARTS(str(?samplingPoint), '" || $x || "')"
  let $filters := "FILTER(" || string-join($filters, " OR ") || ")"
  return
    "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

   SELECT ?localId ?featureOfInterest ?procedure ?observedProperty ?inspireLabel
   WHERE {
         ?samplingPoint a aqd:AQD_Model;
         aqd:observingCapability ?observingCapability;
         aqd:inspireId ?inspireId .
         ?inspireId rdfs:label ?inspireLabel .
         ?inspireId aqd:localId ?localId .
         ?inspireId aqd:namespace ?namespace .
         ?observingCapability aqd:featureOfInterest ?featureOfInterest .
         ?observingCapability aqd:procedure ?procedure .
         ?observingCapability aqd:observedProperty ?observedProperty . " || $filters ||"
   }"
};

declare function query:getObligationYears() {
  "PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
   PREFIX dct: <http://purl.org/dc/terms/>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>

   SELECT DISTINCT
   ?countryCode
   ?delivery
   year(?start) as ?ReportingYear
   ?obligation
   ?obligation_nr
   ?deadline
   bif:either(xsd:int(?obligation_nr) < 680,(year(?deadline) - 2),bif:either(xsd:int(?obligation_nr) < 690,(year(?deadline) - 3),(year(?deadline))) ) as ?minimum
   bif:either(xsd:int(?obligation_nr) < 680,(year(?deadline) - 1),bif:either(xsd:int(?obligation_nr) < 690,(year(?deadline) - 2),(year(?deadline)+1)) ) as ?maximum

   WHERE {
   ?delivery rod:released ?released ;
              rod:obligation ?obluri ;
              rod:startOfPeriod ?start ;
              rod:locality ?locality .

   ?locality rod:loccode ?countryCode .
   ?obluri rod:instrument <http://rod.eionet.europa.eu/instruments/650> ;
           skos:notation ?obligation_nr ;
           rod:nextdeadline  ?deadline ;
           dct:title ?obligation .

   FILTER (year(?released) > 2014) .
   } ORDER BY ?countryCode ?ReportingYear ?obligation_nr"
};
