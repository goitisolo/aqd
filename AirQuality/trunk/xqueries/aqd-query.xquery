xquery version "3.0";

(:~
: User: dev-gso
: Date: 6/21/2016
: Time: 6:37 PM
: To change this template use File | Settings | File Templates.
:)

module namespace query = "aqd-query";
import module namespace sparqlx = "aqd-sparql" at "aqd-sparql.xquery";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";

(: B - remove comment after migration :)
declare function query:getNutsSparql($countryCode as xs:string) as xs:string {
  concat("PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    SELECT ?concepturl ?label ?code
    WHERE {
      ?concepturl skos:inScheme <http://dd.eionet.europa.eu/vocabulary/common/nuts/>;
                  skos:prefLabel ?label;
                  skos:notation ?code
                  FILTER regex(?code, '^", $countryCode, "', 'i')
    }")
};
declare function query:getLau2Sparql($countryCode as xs:string) as xs:string {
  concat("PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    SELECT ?concepturl ?label ?code
    WHERE {
      ?concepturl skos:inScheme <http://dd.eionet.europa.eu/vocabulary/lau2/", $countryCode, "/>;
                  skos:prefLabel ?label;
                  skos:notation ?code
    }")
};

declare function query:getLau1Sparql($countryCode as xs:string) as xs:string {
  concat("PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    SELECT ?concepturl ?label ?code
    WHERE {
      ?concepturl skos:inScheme <http://dd.eionet.europa.eu/vocabulary/lau1/", $countryCode, "/>;
                  skos:prefLabel ?label;
                  skos:notation ?code
    }")
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

declare function query:getZonesSparql($nameSpaces as xs:string*) as xs:string {
  let $nameSpacesStr :=
    for $nameSpace in $nameSpaces
    return concat("""", $nameSpace, """")

  let $nameSpacesStr :=
    fn:string-join($nameSpacesStr, ",")

  return concat(
          "PREFIX aqr: <http://reference.eionet.europa.eu/aq/ontology/>

        SELECT ?inspireid
        FROM <http://rdfdata.eionet.europa.eu/airquality/zones.ttl>
        WHERE {
          ?zoneuri a aqr:Zone ;
                    aqr:inspireNamespace ?namespace;
                     aqr:inspireId ?inspireid .
        filter (?namespace in (", $nameSpacesStr,  "))
        }"
  )
};

(: C - Remove comment after migration :)

declare function query:getAssessmentTypeModel($cdrUrl as xs:string) as xs:string {
  concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
         PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
         PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

    SELECT ?zone ?inspireId ?inspireLabel ?assessmentType
        WHERE {
         ?zone a aqd:AQD_Model ;
         aqd:inspireId ?inspireId .
         ?inspireId rdfs:label ?inspireLabel .
         ?zone aqd:assessmentType ?assessmentType
       FILTER (CONTAINS(str(?zone), '",$cdrUrl,"d/'))
   }")
};

declare function query:getAssessmentTypeSamplingPoint($cdrUrl as xs:string) as xs:string {
  concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
         PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
         PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

    SELECT ?zone ?inspireId ?inspireLabel ?assessmentType
        WHERE {
         ?zone a aqd:AQD_SamplingPoint ;
         aqd:inspireId ?inspireId .
         ?inspireId rdfs:label ?inspireLabel .
         ?zone aqd:assessmentType ?assessmentType
       FILTER (CONTAINS(str(?zone), '", $cdrUrl,  "d/'))
   }")
};

declare function query:getProtectionTarget($zonesUrl as xs:string) as xs:string {
  concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
         PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
         PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
         SELECT distinct  ?zoneId ?pollutantCode ?protectionTarget
         WHERE {
               ?zone a aqd:AQD_Zone;
               aqd:pollutants ?pollutants .
               ?zone aqd:inspireId ?ii .
               ?ii rdfs:label ?zoneId .
               ?pollutants aqd:pollutantCode ?pollutantCode .
               ?pollutants aqd:protectionTarget ?protectionTarget .
         FILTER (CONTAINS(str(?zone), '", $zonesUrl, "'))
} order by ?zone ")
};

declare function query:getSamplingPointInspireLabel($cdrUrl as xs:string) as xs:string {
  concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
         PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
         PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

SELECT ?zone ?inspireId ?inspireLabel ?relevantEmissions ?stationClassification
  WHERE {
         ?zone a aqd:AQD_SamplingPoint ;
          aqd:inspireId ?inspireId .
         ?inspireId rdfs:label ?inspireLabel .
         ?zone aqd:relevantEmissions ?relevantEmissions .
         ?relevantEmissions aqd:stationClassification ?stationClassification
  FILTER (CONTAINS(str(?zone), '", $cdrUrl, "d/') and str(?stationClassification)='http://dd.eionet.europa.eu/vocabulary/aq/stationclassification/background')
  }")(: order by ?zone"):)
};

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

declare function query:getLatestDEnvelope($cdrUrl as xs:string) {
  concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
    PREFIX ptype: <http://purl.org/dc/dcmitype/>
    PREFIX pterms: <http://purl.org/dc/terms/>
    SELECT ?dataset
    WHERE {
    ?dataset a ptype:Dataset .
            optional {?dataset pterms:isReplacedBy ?replacedBy} .
            FILTER(!bound(?replacedBy))
            FILTER(CONTAINS(str(?dataset), '", $cdrUrl, "d/'))
    }")
};

(:
declare function xmlconv:getPollutantCode($cdrUrl as xs:string)
as xs:string
{concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
         PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
         PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

               SELECT distinct ?zone ?pollutants ?pollutantCode ?protectionTarget
         WHERE {
               ?zone a aqd:AQD_Zone;
                aqd:pollutants ?pollutants .
               ?pollutants aqd:pollutantCode ?pollutantCode .
               ?pollutants aqd:protectionTarget ?protectionTarget .
         FILTER (CONTAINS(str(?zone), '", $cdrUrl, "b/'))
} order by ?zone")
};



declare function xmlconv:getAqdModelID($countryCode as xs:string)
as xs:string
{
let $countryCode := xmlconv:reChangeCountrycode($countryCode)
return
   concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

       SELECT ?zone ?inspireId ?inspireLabel
         WHERE {
              ?zone a aqd:AQD_Model;
              aqd:inspireId ?inspireId .
              ?inspireId rdfs:label ?inspireLabel .
         FILTER (CONTAINS(str(?zone), '", $cdrUrl, "d/'))
} order by ?zone")
};
:)

(:
declare function xmlconv:getInspireLabelD($countryCode as xs:string)
as xs:string
{
let $countryCode := xmlconv:reChangeCountrycode($countryCode)
return
concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

    SELECT ?zone ?inspireId ?inspireLabel
      WHERE {
          ?zone a aqd:AQD_SamplingPoint ;
          aqd:inspireId ?inspireId .
          ?inspireId rdfs:label ?inspireLabel .
      FILTER (CONTAINS(str(?zone), '", $cdrUrl, "d/'))
} order by ?zone")
};
:)

(: Returns latest zones envelope for this country:)
declare function query:getLatestZoneEnvelope($zonesUrl as xs:string, $reportingYear) as xs:string? {
  let $query := concat("PREFIX aqd: <http://rod.eionet.europa.eu/schema.rdf#>
  SELECT *
   WHERE {
        ?envelope a aqd:Delivery ;
        aqd:released ?date ;
        aqd:hasFile ?file ;
        aqd:period ?period
        FILTER(CONTAINS(str(?envelope), '", $zonesUrl, "'))
        FILTER(STRSTARTS(str(?period), '", $reportingYear, "'))
  } order by desc(?date)
limit 1")
  let $result := doc(sparqlx:getSparqlEndpointUrl($query, "xml"))//sparql:binding[@name='envelope']/sparql:uri
  return $result
};

declare function query:getInspireId($latestZonesUrl as xs:string)
as xs:string
{
  concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>

  SELECT ?zone ?inspireId ?inspireLabel ?reportingYear
   WHERE {
        ?zone a aqd:AQD_Zone ;
        aqd:inspireId ?inspireId .
        ?inspireId rdfs:label ?inspireLabel .
        ?zone aqd:residentPopulationYear ?yearElement .
        ?yearElement rdfs:label ?reportingYear
   FILTER (CONTAINS(str(?zone), '", $latestZonesUrl, "'))
  } order by ?zone")
};

declare function query:getPollutantCodeAndProtectionTarge($cdrUrl as xs:string, $bDir as xs:string)
as xs:string
{
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
    } order by ?zone")
};

declare function query:getC31($countryCode as xs:string) as xs:string {
  concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX aqr: <http://reference.eionet.europa.eu/aq/ontology/>
PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
PREFIX aqdd: <http://dd.eionet.europa.eu/property/>

SELECT DISTINCT
?Namespace
(year(xsd:dateTime(?reportingBegin)) as ?ReportingYear)
?Pollutant
count(distinct bif:concat(str(?Zone), str(?pollURI), str(?ProtectionTarget))) AS ?countOnB

WHERE {

?zoneURI a aqr:Zone;
aqr:zoneCode ?Zone;
aqr:pollutants ?polltargetURI;
aqr:reportingBegin ?reportingBegin ;
aqr:inspireNamespace ?Namespace .

?polltargetURI aqr:protectionTarget ?ProtectionTarget .
?polltargetURI aqr:pollutantCode ?pollURI .
?pollURI rdfs:label ?Pollutant .
FILTER regex(?pollURI,'') .
FILTER STRSTARTS(str(?Namespace),'", $countryCode, "') .
}")
};

declare function query:getG14($countryCode as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX aqr: <http://reference.eionet.europa.eu/aq/ontology/>
PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
PREFIX aqdd: <http://dd.eionet.europa.eu/property/>

SELECT DISTINCT
?Namespace
?Pollutant
?ReportingYear
?countOnB
?countOnC

WHERE {

{

SELECT DISTINCT
?Namespace
(year(?reportingBegin) as ?ReportingYear)
?pollURI
?countOnB
?countOnC

WHERE {

{
SELECT DISTINCT
?Namespace
?pollURI
count(distinct bif:concat(str(?Zone), str(?pollURI), str(?ProtectionTarget))) AS ?countOnB

WHERE {

  ?zoneURI a aqr:Zone;
           aqr:zoneCode ?Zone;
           aqr:pollutants ?polltargetURI;
           aqr:inspireNamespace ?Namespace .

?polltargetURI aqr:protectionTarget ?ProtectionTarget .
?polltargetURI aqr:pollutantCode ?pollURI .

} }
{
SELECT DISTINCT
?Namespace
?reportingBegin
?pollURI
count(distinct bif:concat(str(?Zone), str(?pollURI), str(?ProtectionTarget))) AS ?countOnC

WHERE {

  ?areURI a aqr:AssessmentRegime;
           aqr:zone ?Zone;
           aqr:reportingBegin ?reportingBegin ;
           aqr:pollutant ?pollURI;
           aqr:assessmentThreshold ?areThre ;
           aqr:inspireNamespace ?Namespace .

?areThre aqr:protectionTarget ?ProtectionTarget .

} }

}}

?pollURI rdfs:label ?Pollutant .

FILTER STRSTARTS(str(?Namespace),'" || $countryCode || "') .
FILTER regex(?pollURI, '') .

} ORDER BY ?Namespace ?ReportingYear ?Pollutant"
};

(: D :)
declare function query:getSamplingPointAssessment($inspireId as xs:string, $inspireNamespace as xs:string)
as xs:string
{
  concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
           PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
           PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
           PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>

        SELECT *
            where {
                    ?assessmentRegime a aqd:AQD_AssessmentRegime;
                    aqd:assessmentMethods  ?assessmentMethods .
                    ?assessmentMethods aqd:samplingPointAssessmentMetadata ?samplingPointAssessment .
                    ?samplingPointAssessment aq:inspireId ?inspireId.
                    ?samplingPointAssessment aq:inspireNamespace ?inspireNamespace.
                    FILTER(?inspireId='",$inspireId,"' and ?inspireNamespace='",$inspireNamespace,"')
                  }")
};
declare function query:getSamplingPointZone($zoneId as xs:string)
as xs:string
{
  concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
            PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
            PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

            SELECT *
            WHERE {
                    ?zone a aqd:AQD_Zone;
                    aqd:inspireId ?inspireId .
                    ?inspireId rdfs:label ?inspireLabel
                    FILTER(?inspireLabel = '",$zoneId,"')
                  }")
};

declare function query:getConceptUrlSparql($scheme as xs:string) as xs:string {
(: Quick fix for #69944. :)
  if ($scheme = "http://inspire.ec.europa.eu/codelist/MediaValue/") then
    concat("PREFIX dcterms: <http://purl.org/dc/terms/>
                PREFIX owl: <http://www.w3.org/2002/07/owl#>
                PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
                    SELECT ?concepturl ?label
                    WHERE {
                    {
                      ?concepturl skos:inScheme <", $scheme, ">;
                                  skos:prefLabel ?label
                    } UNION {
                      ?other skos:inScheme <", $scheme, ">;
                                  skos:prefLabel ?label;
                                  dcterms:replaces ?concepturl
                    }
                }")
  else
    concat("PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        SELECT ?concepturl ?label
        WHERE {
          ?concepturl skos:inScheme <", $scheme, ">;
                      skos:prefLabel ?label
        }")
};

(: This is used by B dataflow - Maybe remove if the above function is enough :)
declare function query:getConceptUrlSparqlB($scheme as xs:string) as xs:string {
  concat("PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    SELECT ?concepturl ?label
    WHERE {
      ?concepturl skos:inScheme <", $scheme, ">;
                  skos:prefLabel ?label
    }")
};


declare function query:getCollectionConceptUrlSparql($collection as xs:string) as xs:string {
  concat("PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    SELECT ?concepturl
    WHERE {
        GRAPH <", $collection, "> {
            <", $collection, "> skos:member ?concepturl .
            ?concepturl a skos:Concept
        }
    }")
};

(: G - remove comment after migration :)

(: ---- SPARQL methods --- :)
declare function query:getTimeExtensionExemption($cdrUrl as xs:string) as xs:string {
  concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
        PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

        SELECT ?zone ?timeExtensionExemption ?localId
        WHERE {
                ?zone a aqd:AQD_Zone ;
                aqd:timeExtensionExemption ?timeExtensionExemption .
                ?zone aqd:inspireId ?inspireid .
                ?inspireid aqd:localId ?localId
        FILTER (CONTAINS(str(?zone), '", $cdrUrl,  "'b/') and (?timeExtensionExemption != 'http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/none'))
      }")(: order by  ?zone "):)
};

(:
declare function query:getAqdZone($cdrUrl as xs:string)
as xs:string
{ concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
            PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
            PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

            SELECT ?zone ?timeExtensionExemption ?localId
            WHERE {
                ?zone a aqd:AQD_Zone ;
                aqd:timeExtensionExemption ?timeExtensionExemption .
                ?zone aqd:inspireId ?inspireid .
                ?inspireid aqd:localId ?localId
                FILTER (CONTAINS(str(?zone), '", $cdrUrl, "b/') and (?timeExtensionExemption != ""))
            } order by  ?zone ")

};
:)

declare function query:getG13($envelopeUrl as xs:string, $reportingYear as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>

           SELECT ?zone ?inspireId ?localId ?inspireLabel
           WHERE {
                  ?regime a aqd:AQD_AssessmentRegime ;
                  aqd:zone ?zone ;
                  aqd:inspireId ?inspireId .
                  ?zone aq:reportingBegin ?reportingYear .
                  ?inspireId rdfs:label ?inspireLabel .
                  ?inspireId aqd:localId ?localId .
           FILTER (CONTAINS(str(?regime), '" || $envelopeUrl || "c/'))
           FILTER (strstarts(str(?reportingYear), '" || $reportingYear || "'))
       }"
};

declare function query:getExistingAttainmentSqarql($cdrUrl as xs:string) as xs:string {
  concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
SELECT distinct concat(?inspireLabel,'#',
  str(?pollutant), '#',
  str(?objectiveType), '#',
  str(?reportingMetric), '#',
  str(?protectionTarget) ) as ?key
WHERE {
        ?attainment a aqd:AQD_Attainment;
       aqd:pollutant ?pollutant .
       ?attainment  aqd:inspireId ?inspireId .
       ?inspireId rdfs:label ?inspireLabel .
       ?attainment aqd:environmentalObjective ?envObjective .
?envObjective aqd:objectiveType ?objectiveType .
?envObjective aqd:reportingMetric  ?reportingMetric .
?envObjective aqd:protectionTarget  ?protectionTarget .
FILTER (CONTAINS(str(?attainment), '" , $cdrUrl,  "g/')) .
}") (: order by ?key"):)
};


declare function query:getInspireLabels($cdrUrl as xs:string) as xs:string {
  concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

SELECT distinct  ?inspireLabel
    WHERE {
        ?attainment a aqd:AQD_Attainment;
        aqd:inspireId ?inspireId .
        ?inspireId rdfs:label ?inspireLabel .
        FILTER (CONTAINS(str(?attainment), '", $cdrUrl, "g/')) .
}")(: order by ?inspireLabel"):)
};

declare function query:getLocallD($cdrUrl as xs:string) as xs:string {
  concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
            PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
            PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

           SELECT ?zone ?inspireId ?localId ?inspireLabel
           WHERE {
                  ?zone a aqd:AQD_AssessmentRegime ;
                  aqd:inspireId ?inspireId .
                  ?inspireId rdfs:label ?inspireLabel .
                  ?inspireId aqd:localId ?localId .
           FILTER (CONTAINS(str(?zone), '",$cdrUrl, "c/'))
       }")(:  order by  ?zone"):)
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
             }"(: order by DESC(?samplingPointAssessmentMetadata) ?assessmentRegime":)
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
              }"(: order by ?assessmentRegime":)
};

declare function query:getZoneLocallD($cdrUrl as xs:string) as xs:string {

  concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
        PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

       SELECT ?zone ?inspireId ?localId ?inspireLabel
       WHERE {
              ?zone a aqd:AQD_Zone ;
              aqd:inspireId ?inspireId .
              ?inspireId rdfs:label ?inspireLabel .
              ?inspireId aqd:localId ?localId .
       FILTER (CONTAINS(str(?zone), '",  $cdrUrl, "b/'))
   }")(:  order by ?zone"):)
};

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
          }")(:  order by ?key"):)
};

declare function query:getModel($cdrUrl as xs:string) as xs:string {
  concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
        PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

        SELECT ?model ?inspireId ?inspireLabel  ?localId ?namespace
        WHERE {
                ?model a aqd:AQD_Model ;
                 aqd:inspireId ?inspireId .
                 ?inspireId rdfs:label ?inspireLabel .
                 ?inspireId aqd:localId ?localId .
                 ?inspireId aqd:namespace ?namespace .
        FILTER(CONTAINS(str(?model), '", $cdrUrl , "d/'))
      }")(: order by ?model"):)
};

declare function query:getSamplingPoint($cdrUrl as xs:string) as xs:string {
  concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
        PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

        SELECT ?samplingPoint ?inspireId ?inspireLabel ?localId ?namespace
        WHERE {
                ?samplingPoint a aqd:AQD_SamplingPoint ;
                 aqd:inspireId ?inspireId .
                 ?inspireId rdfs:label ?inspireLabel .
                 ?inspireId aqd:localId ?localId .
                 ?inspireId aqd:namespace ?namespace .

        FILTER(CONTAINS(str(?samplingPoint), '", $cdrUrl, "d/'))
      }")(:  order by ?samplingPoint"):)
};

declare function query:getSamplingPointProcess($cdrUrl as xs:string) as xs:string {
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
   FILTER(CONTAINS(str(?samplingPointProcess), '" || $cdrUrl || "d/'))
   }"
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