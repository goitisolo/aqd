xquery version "3.0" encoding "UTF-8";

(:~
: User: George Sofianos
: Date: 6/21/2016
: Time: 6:37 PM
:)

module namespace query = "aqd-query";
import module namespace sparqlx = "aqd-sparql" at "aqd-sparql.xquery";
import module namespace common = "aqd-common" at "aqd-common.xquery";
import module namespace functx = "http://www.functx.com" at "functx-1.0-doc-2007-01.xq";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";

(: Normal InspireId Fetch - This should be the default :)
(: B :)
(:declare function query:getZone($url as xs:string?) as xs:string {
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
};:)

declare function query:getZone($url as xs:string?) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
  PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
  PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
  PREFIX dcterms: <http://purl.org/dc/terms/>
  PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

  SELECT DISTINCT ?inspireLabel
  WHERE {
  
  values ?envelope { <" || $url || "> }
  ?graph dcterms:isPartOf ?envelope .
  ?graph contreg:xmlSchema ?xmlSchema .
  
  GRAPH ?graph {
?zone a aqd:AQD_Zone .
?zone aqd:inspireId ?inspireId .
?inspireId rdfs:label ?inspireLabel .
} 
     
  }"
};

(: C :)
(:declare function query:getAssessmentRegime($url as xs:string) as xs:string {
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
};:)

declare function query:getAssessmentRegime($url as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX dcterms: <http://purl.org/dc/terms/>
  PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

   SELECT DISTINCT ?localId ?inspireLabel
   WHERE {
  values ?envelope { <" || $url || "> }
  ?graph dcterms:isPartOf ?envelope .
  ?graph contreg:xmlSchema ?xmlSchema .
  GRAPH ?graph {
  ?regime a aqd:AQD_AssessmentRegime .
  ?regime aqd:inspireId ?inspireId .
  }
   
   ?inspireId rdfs:label ?inspireLabel .
          ?inspireId aqd:localId ?localId .
         
         
   }"
};

(: D :)
(:declare function query:getSamplingPointProcess($url as xs:string) as xs:string {
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
};:)
declare function query:getSamplingPointProcess($url as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX dcterms: <http://purl.org/dc/terms/>
  PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

   SELECT DISTINCT ?samplingPointProcess ?inspireId ?inspireLabel ?localId ?namespace
   WHERE {
    FILTER(STRSTARTS(str(?graph), 'http://"|| $url ||"'))  
      GRAPH ?graph {
      ?samplingPointProcess a aqd:AQD_SamplingPointProcess.}
      ?samplingPointProcess aqd:inspireId ?inspireId .
      
              
               ?inspireId rdfs:label ?inspireLabel .
               ?inspireId aqd:localId ?localId .
               ?inspireId aqd:namespace ?namespace .
     
   }"
};

(:declare function query:getModelProcess($url as xs:string) as xs:string {
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
};:)
declare function query:getModelProcess($url as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX dcterms: <http://purl.org/dc/terms/>
  PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

   SELECT DISTINCT ?samplingPointProcess ?inspireId ?inspireLabel ?localId ?namespace
   WHERE {
   
     
      FILTER(STRSTARTS(str(?graph), 'http://"|| $url ||"'))  
        GRAPH ?graph {
        ?samplingPointProcess a aqd:AQD_ModelProcess.
         ?samplingPointProcess aqd:inspireId ?inspireId .
        }
                 
                 ?inspireId rdfs:label ?inspireLabel .
                 ?inspireId aqd:localId ?localId .
                 ?inspireId aqd:namespace ?namespace .
         
   }"
};

(:declare function query:getSample($url as xs:string) as xs:string {
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
};:)

declare function query:getSample($url as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX dcterms: <http://purl.org/dc/terms/>
   PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

   SELECT DISTINCT ?sample ?inspireId ?inspireLabel ?localId ?namespace
   WHERE {  
       
    values ?envelope { <" || $url || "> }
    ?graph dcterms:isPartOf ?envelope .
    ?graph contreg:xmlSchema ?xmlSchema .
    GRAPH ?graph {
     ?sample a aqd:AQD_Sample.
         ?sample aqd:inspireId ?inspireId .
    } 
   
           ?inspireId rdfs:label ?inspireLabel .
           ?inspireId aqd:localId ?localId .
           ?inspireId aqd:namespace ?namespace .
   
   }"
};

(: declare function query:getModelArea($url as xs:string) as xs:string {
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

OPTIMIZED FUNCTION BUT NOT TESTED AS THE ORIGINAL BRINGS NO RESULTS !!!!!
:)
declare function query:getModelArea($url as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX dcterms: <http://purl.org/dc/terms/>
PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

   SELECT DISTINCT ?sample ?inspireId ?inspireLabel ?localId ?namespace
   WHERE {
   
    values ?envelope { <" || $url || "> }
    ?graph dcterms:isPartOf ?envelope .
    ?graph contreg:xmlSchema ?xmlSchema .
    GRAPH ?graph {
    ?sample a aqd:AQD_ModelArea.
    ?sample aqd:inspireId ?inspireId .
    }
   
           ?inspireId rdfs:label ?inspireLabel .
           ?inspireId aqd:localId ?localId .
           ?inspireId aqd:namespace ?namespace .
   
   }"
};

(:declare function query:getSamplingPoint($cdrUrl as xs:string) as xs:string {
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
:)
declare function query:getSamplingPoint($cdrUrl as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
PREFIX dcterms: <http://purl.org/dc/terms/>
PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

SELECT DISTINCT ?localId ?inspireLabel
WHERE {

values ?envelope { <" || $cdrUrl || "> }
?graph dcterms:isPartOf ?envelope .
?graph contreg:xmlSchema ?xmlSchema .
GRAPH ?graph {
?samplingPoint a aqd:AQD_SamplingPoint .
?samplingPoint aqd:inspireId ?inspireId .
}
?inspireId rdfs:label ?inspireLabel .
?inspireId aqd:localId ?localId .
?inspireId aqd:namespace ?namespace .
}" 
};


(:declare function query:getC27($url as xs:string?) as xs:string {
    "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
  PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
  PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>

  SELECT ?inspireLabel ?beginPosition ?endPosition
  WHERE {
      ?zone a aqd:AQD_Zone ;
      aqd:inspireId ?inspireId .
      ?inspireId rdfs:label ?inspireLabel .
      ?zone aqd:designationPeriod ?period .
      ?period aqd:beginPosition ?beginPosition .
      OPTIONAL { ?period aqd:endPosition ?endPosition } .
      FILTER (CONTAINS(str(?zone), '" || $url || "'))
  }"
};:)

declare function query:getC27($url as xs:string?) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
    PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
    PREFIX dcterms: <http://purl.org/dc/terms/>
    PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

    SELECT DISTINCT  ?inspireLabel ?beginPosition ?endPosition
    WHERE {
    values ?envelope { <" || $url || "> }
    ?graph dcterms:isPartOf ?envelope .
    ?graph contreg:xmlSchema ?xmlSchema .
    GRAPH ?graph {
    ?zone a aqd:AQD_Zone .
      ?zone  aqd:inspireId ?inspireId .
    }  
     
      ?inspireId rdfs:label ?inspireLabel .
      ?zone aqd:designationPeriod ?period .
      ?period aqd:beginPosition ?beginPosition .
      OPTIONAL { ?period aqd:endPosition ?endPosition } .
     
    }"
};



(: M :)
(:declare function query:getModel($url as xs:string) as xs:string {
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
};:)

declare function query:getModel($url as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX dcterms: <http://purl.org/dc/terms/>
  PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

   SELECT DISTINCT ?model ?inspireId ?inspireLabel ?localId ?namespace
   WHERE {   
   
    values ?envelope { <" || $url || "> }
    ?graph dcterms:isPartOf ?envelope .
    ?graph contreg:xmlSchema ?xmlSchema .
    GRAPH ?graph {
     ?model a aqd:AQD_Model .
     ?model aqd:inspireId ?inspireId .
    }
     
      ?inspireId rdfs:label ?inspireLabel .
      ?inspireId aqd:localId ?localId .
      ?inspireId aqd:namespace ?namespace .
      
      }"
};

(: Checks if X references an existing Y via namespace/localid :)
(: TODO: look at this for inspiration on how to find the AQD_Attainment for a AQD_SourceApportionment :)
declare function query:existsViaNameLocalId(
        $label as xs:string,
        $name as xs:string,
        $latestEnvelopes as xs:string*
) as xs:boolean {
    (:let $query := "
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

SELECT ?subject
WHERE {
    ?subject a aq:" || $name ||";
    aq:inspireId ?inspireId.
    ?inspireId rdfs:label ?label.
    ?inspireId aq:namespace ?name.
    ?inspireId aq:localId ?localId
    FILTER (?label = '" || $label || "')
}"

    let $results := sparqlx:run($query) :)
    let $results := sparqlx:run(query:existsViaNameLocalIdQuery($label, $name, $latestEnvelopes))
    let $envelopes :=
        for $result in $results
        return functx:substring-before-last($result/sparql:binding[@name="subject"]/sparql:uri, "/")

    return common:isLatestEnvelope($envelopes, $latestEnvelopes)
};

declare function query:existsViaNameLocalIdQuery(
        $label as xs:string,
        $name as xs:string,
        $latestEnvelopes as xs:string*
) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
  
  SELECT ?subject
  WHERE {
      ?subject a aq:" || $name ||";
      aq:inspireId ?inspireId.
      ?inspireId rdfs:label ?label.
      ?inspireId aq:namespace ?name.
      ?inspireId aq:localId ?localId
      FILTER (?label = '" || $label || "')
  }"

 (: solution proposed by Mauro, pending test and approval, change by @goititer) 

 "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#> 
   PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/> 

    SELECT ?subject ?label 

    WHERE { 
    BIND(xsd:string(<'" || $label || "'>) AS ?label)

    ?subject a aq:AQD_Measures; 
    aq:inspireId ?inspireId. 
    ?inspireId rdfs:label ?label. 
    ?inspireId aq:namespace ?name. 
    ?inspireId aq:localId ?localId 

}":)
};

(:11/01/2021:) declare function query:existsViaNameLocalIdJ02(
        $localId as xs:string,
        $name as xs:string,
        $latestEnvelopes as xs:string*
) as xs:boolean {
    let $results := sparqlx:run(query:existsViaNameLocalIdQueryFilteringBySubject($localId, $name, $latestEnvelopes))
    let $envelopes :=
        for $result in $results
        return functx:substring-before-last($result/sparql:binding[@name="subject"]/sparql:uri, "/")

    return common:isLatestEnvelope($envelopes, $latestEnvelopes)
};

(:11/01/2021:) declare function query:existsViaNameLocalIdQueryFilteringBySubject(
        $localId as xs:string,
        $name as xs:string,
        $latestEnvelopes as xs:string*
) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
  PREFIX dcterms: <http://purl.org/dc/terms/>
  PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>
  
  SELECT distinct ?subject year(?startOfPeriod) as ?reportingYear ?envelope ?localId
  WHERE {
    VALUES ?localId { '" || $localId || "' }
    GRAPH ?source {
      ?subject a aq:AQD_EvaluationScenario;
      aq:inspireId ?inspireId.
     }   
      ?inspireId rdfs:label ?label.
      ?inspireId aq:namespace ?name.
      ?inspireId aq:localId ?localId .

    ?source dcterms:isPartOf ?envelope .
    ?envelope rod:startOfPeriod ?startOfPeriod .
  }"
};

declare function query:existsViaNameLocalIdGeneral(
        $results as xs:string,
        $latestEnvelopes as xs:string*
) as xs:boolean {
    
    let $envelopes := functx:substring-before-last($results, "/")

    return common:isLatestEnvelope($envelopes, $latestEnvelopes)
};

declare function query:existsViaNameLocalIdGeneralQuery(
        
        $name as xs:string,
        $latestEnvelopes as xs:string*
) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
  
  SELECT ?subject ?label
  WHERE {
      ?subject a aq:" || $name ||";
      aq:inspireId ?inspireId.
      ?inspireId rdfs:label ?label.
      ?inspireId aq:namespace ?name.
      ?inspireId aq:localId ?localId
  }"
};

(: Checks if X references an existing Y via namespace/localid and reporting year :)
(:declare function query:existsViaNameLocalIdYear(
    $label as xs:string,
    $type as xs:string,
    $year as xs:string,
    $latestEnvelopes as xs:string*
    ) as xs:boolean {
    let $query := "
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
      PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>

      SELECT ?subject
      WHERE {
          ?subject a aqd:" || $type ||";
          aqd:inspireId ?inspireId.
          ?inspireId rdfs:label ?label.
          ?inspireId aqd:namespace ?name.
          ?inspireId aqd:localId ?localId.
          ?subject aqd:declarationFor ?declaration.
          ?declaration aq:reportingBegin ?reportingYear.
          FILTER (?label = '" || $label || "')
          FILTER (CONTAINS(str(?reportingYear), '" || $year || "'))
      }
      "
    let $results := sparqlx:run($query)

    let $envelopes :=
        for $result in $results
        return functx:substring-before-last($result/sparql:binding[@name="subject"]/sparql:uri, "/")

    return common:isLatestEnvelope($envelopes, $latestEnvelopes) 
};:)

(: declare function query:existsViaNameLocalIdYear(
    $label as xs:string,
    $type as xs:string,
    $year as xs:string,
    $latestEnvelopes as xs:string*
    ) as xs:boolean {
    let $query := "
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
      PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
      PREFIX dcterms: <http://purl.org/dc/terms/>
      PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>

      SELECT ?subject ?declaration year(?startOfPeriod) as ?reportingYear
        WHERE {
          VALUES ?label { '" || $label || "' } 
            GRAPH ?source {
              ?subject a aqd:" || $type ||" .
              ?subject aqd:inspireId ?inspireId.
              ?inspireId rdfs:label ?label.
              ?inspireId aqd:namespace ?name.
              ?inspireId aqd:localId ?localId.
            } 
            ?source dcterms:isPartOf ?envelope .
            ?envelope rod:startOfPeriod ?startOfPeriod .
            ?subject aqd:declarationFor ?declaration .

      FILTER ( year(?startOfPeriod) = " || $year || " )
    }
      "
    let $results := sparqlx:run($query)

    let $envelopes :=
        for $result in $results
        return functx:substring-before-last($result/sparql:binding[@name="subject"]/sparql:uri, "/")

    return common:isLatestEnvelope($envelopes, $latestEnvelopes) 
}; :)

declare function query:existsViaNameLocalIdYear(
    $label as xs:string,
    $type as xs:string,
    $year as xs:string,
    $latestEnvelopes as xs:string*
    ) as xs:boolean {

    let $results := sparqlx:run(query:existsViaNameLocalIdYearQuery($label, $type, $year, $latestEnvelopes))

    let $envelopes :=
        for $result in $results
        return functx:substring-before-last($result/sparql:binding[@name="subject"]/sparql:uri, "/")

    return common:isLatestEnvelope($envelopes, $latestEnvelopes) 
};

declare function query:existsViaNameLocalIdYearQuery(
    $label as xs:string,
    $type as xs:string,
    $year as xs:string,
    $latestEnvelopes as xs:string*
    ) as xs:string {
    "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
      PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
      PREFIX dcterms: <http://purl.org/dc/terms/>
      PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>

      SELECT ?subject ?declaration year(?startOfPeriod) as ?reportingYear
        WHERE {
          VALUES ?label { '" || $label || "' } 
            GRAPH ?source {
              ?subject a aqd:" || $type ||" .
              ?subject aqd:inspireId ?inspireId.
              ?inspireId rdfs:label ?label.
              ?inspireId aqd:namespace ?name.
              ?inspireId aqd:localId ?localId.
            } 
            ?source dcterms:isPartOf ?envelope .
            ?envelope rod:startOfPeriod ?startOfPeriod .
            ?subject aqd:declarationFor ?declaration .

      FILTER ( year(?startOfPeriod) = " || $year || " )
    }" 
};

declare function query:existsViaNameLocalIdYear1(
   
    $subject as xs:string,
    
    $latestEnvelopes as xs:string*
    ) as xs:boolean {

   (:let $results := sparqlx:run(query:existsViaNameLocalIdYearGeneral( $type, $year, $latestEnvelopes)):)

    let $envelopes :=
        (:for $result in $results
        return :)functx:substring-before-last($subject, "/")

    return common:isLatestEnvelope($envelopes, $latestEnvelopes) 
};

declare function query:existsViaNameLocalIdYearGeneral(
   
    $type as xs:string,
    $year as xs:string
   
    ) as xs:string {
    "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
      PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
      PREFIX dcterms: <http://purl.org/dc/terms/>
      PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>

      SELECT ?label ?subject ?declaration year(?startOfPeriod) as ?reportingYear
        WHERE {
          
            GRAPH ?source {
              ?subject a aqd:" || $type ||" .
              ?subject aqd:inspireId ?inspireId.
              ?inspireId rdfs:label ?label.
              ?inspireId aqd:namespace ?name.
              ?inspireId aqd:localId ?localId.
            } 
            ?source dcterms:isPartOf ?envelope .
            ?envelope rod:startOfPeriod ?startOfPeriod .
            ?subject aqd:declarationFor ?declaration .

      FILTER ( year(?startOfPeriod) = " || $year || " )
    }" 
};

declare function query:existsViaNameLocalIdYearGeneralWithoutYearFilter(
   
    $type as xs:string,
    $year as xs:string
   
    ) as xs:string {
    "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
      PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
      PREFIX dcterms: <http://purl.org/dc/terms/>
      PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>

      SELECT distinct ?label ?subject ?declaration year(?startOfPeriod) as ?reportingYear
        WHERE {
          
            GRAPH ?source {
              ?subject a aqd:" || $type ||" .
              ?subject aqd:inspireId ?inspireId.
              ?inspireId rdfs:label ?label.
              ?inspireId aqd:namespace ?name.
              ?inspireId aqd:localId ?localId.
            } 
            ?source dcterms:isPartOf ?envelope .
            ?envelope rod:startOfPeriod ?startOfPeriod .
            ?subject aqd:declarationFor ?declaration .
    }" 
};

declare function query:existsViaNameLocalIdYearGeneralWithoutYearFilter(
    $label as xs:string,
    $type as xs:string,
    $year as xs:string

    ) as xs:string {
    "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
      PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
      PREFIX dcterms: <http://purl.org/dc/terms/>
      PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>

      SELECT distinct ?label ?subject ?declaration year(?startOfPeriod) as ?reportingYear
        WHERE {
          VALUES ?label { '" || $label || "' }
            GRAPH ?source {
              ?subject a aqd:" || $type ||" .
              ?subject aqd:inspireId ?inspireId.
              ?inspireId rdfs:label ?label.
              ?inspireId aqd:namespace ?name.
              ?inspireId aqd:localId ?localId.
            } 
            ?source dcterms:isPartOf ?envelope .
            ?envelope rod:startOfPeriod ?startOfPeriod .
            ?subject aqd:declarationFor ?declaration .
    }" 
};


(:for C28 function:)
declare function query:getZonesDates(
   
    $cdrUrl as xs:string
   
    ) as xs:string {

"   PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
    PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
    PREFIX dcterms: <http://purl.org/dc/terms/>
    PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

   SELECT  
    ?beginPosition   
    ?zoneURI
    ?label

    

    WHERE {
    values ?envelope { <" || $cdrUrl || "> }

    ?graph dcterms:isPartOf ?envelope .
    ?graph contreg:xmlSchema ?xmlSchema .
    
    GRAPH ?graph {
      ?zoneURI a aqd:AQD_Zone;
       aqd:zoneCode ?Zone;
       aqd:pollutants ?polltargetURI;
       aqd:inspireId ?inspireId;

       aqd:designationPeriod ?designationPeriod .
       ?designationPeriod aqd:beginPosition ?beginPosition .       
       ?designationPeriod rdfs:label ?label.
    }  
     
}"
};

(: Checks if X references an existing Y via namespace/localid and reporting year :)
(: declare function query:existsViaNameLocalIdYearI11(
    $label as xs:string,
    $type as xs:string,
    $year as xs:string,
    $latestEnvelopes as xs:string*
    ) as xs:boolean {
    let $query := "

      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>
      PREFIX obligation: <http://rod.eionet.europa.eu/obligations/>
      PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

      SELECT DISTINCT
      ?Country
      ?reportingYear
      ?PlanId
      ?envelope
      WHERE 
      {
        {
        SELECT DISTINCT
          ?Country
          YEAR(?endOfPeriod) as ?reportingYear
          max(?released) as ?released
          ?PlanId
          ?envelope
        WHERE 
          {
            ?envelope rod:released ?released .
            ?envelope rod:endOfPeriod ?endOfPeriod .
            ?envelope rod:obligation ?obligation .
            ?envelope rod:hasFile ?source .
            ?envelope rod:locality ?locality .
            FILTER (?obligation = obligation:680) 
            ?locality rod:localityName ?Country .

            {
              SELECT 
              ?XMLURI
              ?PlanId 
              (IRI(substr(str(?XMLURI),1,bif:strchr(str(?XMLURI),'#'))) AS ?source) 

              WHERE 
              {
                ?XMLURI a aq:" || $type ||" ;
                          aq:inspireId ?inspireURI .
                ?inspireURI aq:localId ?PlanId .
              }
            }

          } GROUP BY ?Country YEAR(?endOfPeriod) ?PlanId ?envelope
        }
          ?envelope rod:released ?released .
          ?envelope rdf:type rod:Delivery .
          FILTER (?PlanId = '" || $label || "')
          FILTER (?reportingYear = " || $year || ")
      }
      "
    let $results := sparqlx:run($query)

    let $envelopes :=
        for $result in $results
        return $result/sparql:binding[@name="envelope"]/sparql:uri

    return common:isLatestEnvelope($envelopes, $latestEnvelopes) 
}; :)

declare function query:existsViaNameLocalIdYearI11(
    $label as xs:string,
    $type as xs:string,
    $year as xs:string,
    $latestEnvelopes as xs:string*
    ) as xs:boolean {
    let $results := sparqlx:run(query:existsViaNameLocalIdYearI11Query($label,$type,$year,$latestEnvelopes))

    let $envelopes :=
        for $result in $results
        return $result/sparql:binding[@name="envelope"]/sparql:uri

    return common:isLatestEnvelope($envelopes, $latestEnvelopes) 
};

declare function query:existsViaNameLocalIdYearI11General(
    $envelope as xs:string,
    $latestEnvelopes as xs:string*
    ) as xs:boolean {
    let $envelopes := $envelope
    return common:isLatestEnvelope($envelopes, $latestEnvelopes) 
};
(:declare function query:existsViaNameLocalIdYearI11Query(
    $label as xs:string,
    $type as xs:string,
    $year as xs:string,
    $latestEnvelopes as xs:string*
    ) as xs:string {
    "PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>
      PREFIX obligation: <http://rod.eionet.europa.eu/obligations/>
      PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

      SELECT DISTINCT
      ?Country
      ?reportingYear
      ?PlanId
      ?envelope
      WHERE 
      {
        {
        SELECT DISTINCT
          ?Country
          YEAR(?endOfPeriod) as ?reportingYear
          max(?released) as ?released
          ?PlanId
          ?envelope
        WHERE 
          {
            ?envelope rod:released ?released .
            ?envelope rod:endOfPeriod ?endOfPeriod .
            ?envelope rod:obligation ?obligation .
            ?envelope rod:hasFile ?source .
            ?envelope rod:locality ?locality .
            FILTER (?obligation = obligation:680) 
            ?locality rod:localityName ?Country .

            {
              SELECT 
              ?XMLURI
              ?PlanId 
              (IRI(substr(str(?XMLURI),1,bif:strchr(str(?XMLURI),'#'))) AS ?source) 

              WHERE 
              {
                ?XMLURI a aq:" || $type ||" ;
                          aq:inspireId ?inspireURI .
                ?inspireURI aq:localId ?PlanId .
              }
            }

          } GROUP BY ?Country YEAR(?endOfPeriod) ?PlanId ?envelope
        }
          ?envelope rod:released ?released .
          ?envelope rdf:type rod:Delivery .
          FILTER (?PlanId = '" || $label || "')
          FILTER (?reportingYear = " || $year || ")
      }" 
};:)


declare function query:existsViaNameLocalIdYearI11Query(
    $label as xs:string,
    $type as xs:string,
    $year as xs:string,
    $latestEnvelopes as xs:string*
    ) as xs:string {
    "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
      PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
      PREFIX dcterms: <http://purl.org/dc/terms/>
      PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>

      SELECT 
        ?Country
        YEAR(?endOfPeriod) as ?reportingYear
        ?localId
        ?envelope
          
        
        WHERE {
          VALUES ?localId{ '" || $label || "' } 
            GRAPH ?source {
              ?subject a aqd:" || $type ||" .
              ?subject aqd:inspireId ?inspireId.
              ?inspireId rdfs:label ?label.
              ?inspireId aqd:namespace ?name.
              ?inspireId aqd:localId ?localId.           
            } 
            ?source dcterms:isPartOf ?envelope .
            ?envelope rod:startOfPeriod ?startOfPeriod .
            ?envelope rod:endOfPeriod ?endOfPeriod .
            ?envelope rod:locality ?locality.
            ?locality rod:localityName ?Country .

      FILTER ( year(?startOfPeriod) = " || $year || " )
    }" 
};

(: #carraand 17/11/2020 To make more eficcient used a more general query to get general data and filter in the XQuery side.:)

declare function query:existsViaNameLocalIdYearI11QueryGeneral(
    $type as xs:string,
    $year as xs:string
    ) as xs:string {
    "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
      PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
      PREFIX dcterms: <http://purl.org/dc/terms/>
      PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>

      SELECT 
        ?Country
        YEAR(?endOfPeriod) as ?reportingYear
        ?localId
        ?envelope
        ?label

        WHERE {
            GRAPH ?source {
              ?subject a aqd:" || $type ||" .
              ?subject aqd:inspireId ?inspireId.
              ?inspireId rdfs:label ?label.
              ?inspireId aqd:namespace ?name.
              ?inspireId aqd:localId ?localId.           
            } 
            ?source dcterms:isPartOf ?envelope .
            ?envelope rod:startOfPeriod ?startOfPeriod .
            ?envelope rod:endOfPeriod ?endOfPeriod .
            ?envelope rod:locality ?locality.
            ?locality rod:localityName ?Country .

      FILTER ( year(?startOfPeriod) = " || $year || " )
    }" 
};

declare function query:existsViaNameLocalIdYearI12aQueryGeneral(
    $type as xs:string,
    $year as xs:string,
    $countryCode as xs:string
    ) as xs:string {
    "
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
      PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
      PREFIX dcterms: <http://purl.org/dc/terms/>
      PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>

      SELECT 
        ?Country
        YEAR(?endOfPeriod) as ?reportingYear
        ?localId
        ?envelope
        ?label
        ?exceedanceSituation

        WHERE {
            GRAPH ?source {
              ?subject a aqd:" || $type ||" .
              ?subject aqd:exceedanceSituation ?exceedanceSituation.
              ?subject aqd:inspireId ?inspireId.
              ?inspireId rdfs:label ?label.
              ?inspireId aqd:namespace ?name.
              ?inspireId aqd:localId ?localId.           
            } 
            ?source dcterms:isPartOf ?envelope .
            ?envelope rod:startOfPeriod ?startOfPeriod .
            ?envelope rod:endOfPeriod ?endOfPeriod .
            ?envelope rod:locality ?locality.
            ?locality rod:localityName ?Country .
            ?locality rod:loccode ?Countrycode .

      FILTER ( year(?startOfPeriod) = " || $year || " )
      FILTER (?Countrycode = '" || $countryCode ||"')
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

(: G 
declare function query:getAttainment($url as xs:string) as xs:string {
  "PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

   SELECT ?inspireLabel
   WHERE {
     GRAPH ?file {
      ?attainment a aqd:AQD_Attainment;
      aqd:inspireId ?inspireId .
      ?inspireId rdfs:label ?inspireLabel .
  }
     '" || $url || "' rod:hasFile ?file
             
   }"
};:)

(: G 
declare function query:getAttainmentNew($countryCode as xs:string,$obligation as xs:string) as xs:string {
  "PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

       SELECT ?inspireLabel
       WHERE {
         GRAPH ?file {
          ?attainment a aqd:AQD_Attainment;
          aqd:inspireId ?inspireId .
          ?inspireId rdfs:label ?inspireLabel .
      }
       ?envelope rod:hasFile ?file;
                 rod:obligation <" || $obligation || ">;
                 rod:locality _:locurl .
       _:locurl rod:loccode '" || $countryCode || "'.
       
       }"
};:)

(: G89 :)
declare function query:getAssessmentMethodsC($envelope as xs:string, $assessment as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

   SELECT DISTINCT replace(str(?samplingPointAssessmentMetadata),'http://reference.eionet.europa.eu/aq/','') as ?samplingPointAssessmentMetadata
   WHERE {
      ?assessmentRegime a aqd:AQD_AssessmentRegime;
      aqd:inspireId ?inspireId;
      aqd:assessmentMethods ?assessmentMethods .
      ?inspireId aqd:localId ?localId .
      OPTIONAL { ?assessmentMethods aqd:samplingPointAssessmentMetadata ?samplingPointAssessmentMetadata } .
      OPTIONAL { ?assessmentMethods aqd:modelAssessmentMetadata ?modelAssessmentMetadata } .
      FILTER (?localId = '" || $assessment || "') .
      FILTER CONTAINS(str(?assessmentRegime),'" || $envelope || "') .
   }"
};

declare function query:getAssessmentMethodsCSamplingPoint($envelope as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
    PREFIX dcterms: <http://purl.org/dc/terms/>
    PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

   SELECT DISTINCT replace(str(?samplingPointAssessmentMetadata),'http://reference.eionet.europa.eu/aq/','') as ?samplingPointAssessmentMetadata ?localId

      WHERE {
    values ?envelope { <" || $envelope || "> }
    ?graph dcterms:isPartOf ?envelope .
    ?graph contreg:xmlSchema ?xmlSchema .

  GRAPH ?graph {  
      
      ?assessmentRegime a aqd:AQD_AssessmentRegime;
      aqd:inspireId ?inspireId;
      aqd:assessmentMethods ?assessmentMethods .
      ?inspireId aqd:localId ?localId .   
      ?assessmentMethods aqd:samplingPointAssessmentMetadata ?samplingPointAssessmentMetadata  .
 }
}"
};

declare function query:getAssessmentMethodsCSamplingPoint($envelope as xs:string, $assessment as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

   SELECT DISTINCT replace(str(?samplingPointAssessmentMetadata),'http://reference.eionet.europa.eu/aq/','') as ?samplingPointAssessmentMetadata
   WHERE {
      ?assessmentRegime a aqd:AQD_AssessmentRegime;
      aqd:inspireId ?inspireId;
      aqd:assessmentMethods ?assessmentMethods .
      ?inspireId aqd:localId ?localId .
      ?assessmentMethods aqd:samplingPointAssessmentMetadata ?samplingPointAssessmentMetadata  .
      FILTER (?localId = '" || $assessment || "') .
      FILTER CONTAINS(str(?assessmentRegime),'" || $envelope || "') .
   }"
};

declare function query:getAssessmentMethodsCModels($envelope as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
    PREFIX dcterms: <http://purl.org/dc/terms/>
    PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

   SELECT DISTINCT replace(str(?modelAssessmentMetadata),'http://reference.eionet.europa.eu/aq/','') as ?modelAssessmentMetadata ?localId
   WHERE {
    values ?envelope { <" || $envelope || "> }
    ?graph dcterms:isPartOf ?envelope .
    ?graph contreg:xmlSchema ?xmlSchema .

  GRAPH ?graph {                     
      ?assessmentRegime a aqd:AQD_AssessmentRegime;
      aqd:inspireId ?inspireId;
      aqd:assessmentMethods ?assessmentMethods .
      ?inspireId aqd:localId ?localId .
      ?assessmentMethods aqd:modelAssessmentMetadata ?modelAssessmentMetadata  .
 
}
   }"
};

declare function query:getAssessmentMethodsCModels($envelope as xs:string, $assessment as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

   SELECT DISTINCT replace(str(?modelAssessmentMetadata),'http://reference.eionet.europa.eu/aq/','') as ?modelAssessmentMetadata
   WHERE {
      ?assessmentRegime a aqd:AQD_AssessmentRegime;
      aqd:inspireId ?inspireId;
      aqd:assessmentMethods ?assessmentMethods .
      ?inspireId aqd:localId ?localId .
      ?assessmentMethods aqd:modelAssessmentMetadata ?modelAssessmentMetadata  .
      FILTER (?localId = '" || $assessment || "') .
      FILTER CONTAINS(str(?assessmentRegime),'" || $envelope || "') .
   }"
};


declare function query:getAssessmentMethodsE($envelope as xs:string) {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX om: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

   SELECT DISTINCT replace(str(?assessmentMethod),'http://reference.eionet.europa.eu/aq/','') as ?assessmentMethod
   WHERE {
      ?observation a om:OM_Observation;
      om:parameter ?parameter .
      ?parameter om:value ?assessmentMethod .
      FILTER CONTAINS(str(?observation),'" || $envelope || "') .
   }"
};


(: E35 :)
declare function query:getAssessmentMethodsAndDates($url as xs:string, $year as xs:string, $regex as xs:string, $time1 as xs:string, $time2 as xs:string) as xs:string {
  
  
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
PREFIX om: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
PREFIX purl: <http://purl.org/dc/terms/>

SELECT DISTINCT
   replace(str(?assessmentMethod),'http://reference.eionet.europa.eu/aq/','') as ?assessmentMethod
   ?beginPosition
  
(if(regex(str(?endPosition), '"|| $regex ||"'), xsd:dateTime(replace(?endPosition, '"||$time1||"', '"||$time2||"')), ?endPosition) as ?endPosition)
   ?timePosition as ?resultTime

   WHERE {
      VALUES ?url  { <" || $url || "> }
     
      FILTER(CONTAINS(str(?g), str(?url)))
      GRAPH ?g {
        ?observation a om:OM_Observation .

      ?observation om:parameter ?parameter .
      ?observation om:phenomenonTime ?phenomenonTime .
      ?observation om:resultTime ?resultTime .
      ?resultTime om:timePosition ?timePosition .
      ?phenomenonTime om:beginPosition ?beginPosition .
      ?phenomenonTime om:endPosition ?endPosition .
      ?parameter om:value ?assessmentMethod .
      }

FILTER(?beginPosition >= xsd:dateTime('" || $year || "')) 

   }
ORDER BY DESC(?resultTime )
LIMIT 1"
};

declare function query:getSamplingsAndDates($countryCode as xs:string,  $year as xs:string) as xs:string {
  
  
  "PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
PREFIX obligations: <http://rod.eionet.europa.eu/obligations/>

SELECT DISTINCT
  (?startOfPeriod) AS ?startOfPeriod
  MAX(?timePosition) AS ?timePosition
  ?samplingPoint
?timePosition as ?resultTime

WHERE 
  {

      VALUES ?countryCode  { '" || $countryCode || "' }
      VALUES ?startOfPeriodFilter  { " || $year || " }
      {
        SELECT DISTINCT 
          ?samplingPoint_inner AS ?samplingPointOriginal

 

          if(bound(?samplingPointType_inner),  ?samplingPoint_inner, URI(concat('http://reference.eionet.europa.eu/aq/',?samplingPoint_inner))) AS ?samplingPoint
        WHERE {
          GRAPH ?file {
            ?observation_inner a aqd:OM_Observation .
            ?observation_inner aqd:parameter ?parameter_inner .
            ?parameter_inner aqd:value ?samplingPoint_inner .
          }
        OPTIONAL { ?samplingPoint_inner a ?samplingPointType_inner . }
        }
      }
      GRAPH ?file {
        ?observation a aqd:OM_Observation .
        ?observation aqd:resultTime ?resultTime . 
        ?resultTime aqd:timePosition ?timePosition .
        ?observation aqd:parameter ?parameter .
        ?parameter aqd:value ?samplingPointOriginal .
        
      }
      ?file dcterms:isPartOf ?envelope .
      ?envelope rod:startOfPeriod ?startOfPeriod .
      FILTER (YEAR(?startOfPeriod) = ?startOfPeriodFilter)

      ?samplingPoint a aq:SamplingPoint .
      ?file cr:xmlSchema ?xmlschema .
      ?samplingPoint aq:broader ?broader .
      ?broader dcterms:spatial ?spatial .
      ?spatial rod:loccode ?countryCode .
   }"
};

(: E35 :)
declare function query:getAllAssessmentMethodsAndDates($url as xs:string, $year as xs:string, $regex as xs:string, $time1 as xs:string, $time2 as xs:string) as xs:string {
  
  
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
PREFIX om: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
PREFIX purl: <http://purl.org/dc/terms/>

SELECT DISTINCT
   replace(str(?assessmentMethod),'http://reference.eionet.europa.eu/aq/','') as ?assessmentMethod
   ?beginPosition
  
(if(regex(str(?endPosition), '"|| $regex ||"'), xsd:dateTime(replace(?endPosition, '"||$time1||"', '"||$time2||"')), ?endPosition) as ?endPosition)
   ?timePosition as ?resultTime

   WHERE {
      VALUES ?url  { <" || $url || "> }
     
      FILTER(CONTAINS(str(?g), str(?url)))
      GRAPH ?g {
        ?observation a om:OM_Observation .

      ?observation om:parameter ?parameter .
      ?observation om:phenomenonTime ?phenomenonTime .
      ?observation om:resultTime ?resultTime .
      ?resultTime om:timePosition ?timePosition .
      ?phenomenonTime om:beginPosition ?beginPosition .
      ?phenomenonTime om:endPosition ?endPosition .
      ?parameter om:value ?assessmentMethod .
      }

FILTER(?beginPosition >= xsd:dateTime('" || $year || "')) 

   }
"
};
(: H :)
(: H24 :)
declare function query:getPollutants(
        $type as xs:string,
        $label as xs:string
) as xs:string* {
    (:let $query := "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
       SELECT distinct ?pollutant
       WHERE {
?scenariosXMLURI a aq:" || $type ||";
aq:inspireId ?inspireId ;
aq:pollutant ?pollutant .
?inspireId rdfs:label ?label .
?inspireId aq:namespace ?name .
?inspireId aq:localId ?localId .
FILTER (?label = '" || $label || "')
   }"
    let $res := sparqlx:run($query):)
    let $res := sparqlx:run(query:getPollutantsQuery($type, $label))
    return data($res//sparql:binding[@name='pollutant']/sparql:uri)
};

declare function query:getPollutantsQuery(
        $type as xs:string,
        $label as xs:string
) as xs:string* {
"PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
       SELECT distinct ?pollutant
       WHERE {
?scenariosXMLURI a aq:" || $type ||";
aq:inspireId ?inspireId ;
aq:pollutant ?pollutant .
?inspireId rdfs:label ?label .
?inspireId aq:namespace ?name .
?inspireId aq:localId ?localId .
FILTER (?label = '" || $label || "')
   }"
};

declare function query:getPollutants(
        $type as xs:string
) as xs:string* {
    let $res := sparqlx:run(query:getPollutantsQuery($type))
    return $res
};
declare function query:getPollutantsQuery(
        $type as xs:string
) as xs:string* {
  
"PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
 SELECT distinct ?pollutant ?label
 WHERE {
        GRAPH ?graph{
              ?scenariosXMLURI a aq:" || $type ||";
              aq:inspireId ?inspireId ;
              aq:pollutant ?pollutant .
        }
              ?inspireId rdfs:label ?label .
              ?inspireId aq:namespace ?name .
              ?inspireId aq:localId ?localId .
   }"
};

(:~ Creates a SPARQL query string to query all objects of given type in a URL

The result is a list of inspireLabels

Used for dataflow I, can be used for any other

TODO: reuse in other workflows
:)
declare function query:sparql-objects-in-subject(
    $url as xs:string,
    $type as xs:string
) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

   SELECT ?inspireLabel
   WHERE {
      ?s a " || $type || ";
      aqd:inspireId ?inspireId .
      ?inspireId rdfs:label ?inspireLabel .
      FILTER (CONTAINS(str(?s), '" || $url || "'))
   }"
};

declare function query:getAllEnvelopesForObjectViaLabel(
        $label as xs:string,
        $type as xs:string
) as element()* {
    (: let $query :="
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

    SELECT ?s
    WHERE {
        ?s a aqd:" || $type || ";
        aqd:inspireId ?inspireId .
        ?inspireId rdfs:label ?label .
        FILTER(?label = '" || $label || "')
    }"
    let $res := sparqlx:run($query) :)
    let $res := sparqlx:run(query:getAllEnvelopesForObjectViaLabelQuery($label, $type))
    return $res
} ;

declare function query:getAllEnvelopesForObjectViaLabelQuery(
        $label as xs:string,
        $type as xs:string
) as xs:string {
    "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

    SELECT ?s
    WHERE {
        ?s a aqd:" || $type || ";
        aqd:inspireId ?inspireId .
        ?inspireId rdfs:label ?label .
        FILTER(?label = '" || $label || "')
    }"
} ;

(:~ Creates a SPARQL query to return all inspireIds for given aqd:namespace

Used for dataflow I, can be used for any other

TODO: reuse in other workflows
:)
(: declare function query:sparql-objects-ids(
    $namespaces as xs:string*,
    $type as xs:string
) as xs:string* {
  let $query := "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>

   SELECT *
   WHERE {
        ?attainment a " || $type || ";
        aqd:inspireId ?inspireId .
        ?inspireId rdfs:label ?inspireLabel .
        ?inspireId aqd:namespace ?namespace
        FILTER(str(?namespace) in ('" || string-join($namespaces, "','") || "'))
  }"
  return data(sparqlx:run($query)//sparql:binding[@name='inspireLabel']/sparql:literal)
}; :)

declare function query:sparql-objects-ids(
    $namespaces as xs:string*,
    $type as xs:string
) as xs:string* {
  let $query := query:sparql-objects-ids-query($namespaces,$type)
  return data(sparqlx:run($query)//sparql:binding[@name='inspireLabel']/sparql:literal)
};

declare function query:sparql-objects-ids-query(
    $namespaces as xs:string*,
    $type as xs:string
) as xs:string {
   "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>

   SELECT *
   WHERE {
        ?attainment a " || $type || ";
        aqd:inspireId ?inspireId .
        ?inspireId rdfs:label ?inspireLabel .
        ?inspireId aqd:namespace ?namespace
        FILTER(str(?namespace) in ('" || string-join($namespaces, "','") || "'))
  }"
};


(: J :)
declare function query:getEvaluationScenarios($url as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

   SELECT ?inspireLabel
   WHERE {
      ?EvaluationScenario a aqd:AQD_EvaluationScenario;
      aqd:inspireId ?inspireId .
      ?inspireId rdfs:label ?inspireLabel .
      FILTER (CONTAINS(str(?EvaluationScenario), '" || $url || "'))
   }"
};

(: J22 :)
(: declare function query:isTimePositionValid(
    $object as xs:string,
    $label as xs:string,
    $timePosition as xs:integer,
    $latestEnvelopes as xs:string*
) as xs:boolean {
    let $query := "
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

SELECT ?subject
WHERE {
?subject a aq:" || $object || ";
    aq:inspireId ?inspireId;
    aq:referenceYear ?referenceYear.
?referenceYear aq:timePosition ?timePosition.
?inspireId rdfs:label ?label.
?inspireId aq:namespace ?name.
?inspireId aq:localId ?localId
FILTER (?label = '" || $label || "')
FILTER(?timePosition = " || $timePosition || ")
}
"
    let $results := sparqlx:run($query)

    let $envelopes :=
        for $result in $results
        return functx:substring-before-last($result/sparql:binding[@name="subject"]/sparql:uri, "/")

    return common:isLatestEnvelope($envelopes, $latestEnvelopes)

}; :)

declare function query:isTimePositionValid(
    $object as xs:string,
    $label as xs:string,
    $timePosition as xs:integer,
    $latestEnvelopes as xs:string*
) as xs:boolean {
    let $results := sparqlx:run(query:isTimePositionValidQuery($object, $label, $timePosition, $latestEnvelopes))

    let $envelopes :=
        for $result in $results
        return functx:substring-before-last($result/sparql:binding[@name="subject"]/sparql:uri, "/")

    return common:isLatestEnvelope($envelopes, $latestEnvelopes)

};

declare function query:isTimePositionValidQuery(
    $object as xs:string,
    $label as xs:string,
    $timePosition as xs:integer,
    $latestEnvelopes as xs:string*
) as xs:string {
    "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

    SELECT ?subject
    WHERE {
    ?subject a aq:" || $object || ";
        aq:inspireId ?inspireId;
        aq:referenceYear ?referenceYear.
    ?referenceYear aq:timePosition ?timePosition.
    ?inspireId rdfs:label ?label.
    ?inspireId aq:namespace ?name.
    ?inspireId aq:localId ?localId
    FILTER (?label = '" || $label || "')
    FILTER(?timePosition = " || $timePosition || ")
    }"
};

(: K :)
declare function query:getMeasures($url as xs:string) as xs:string {
 (:) "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

   SELECT ?inspireLabel
   WHERE {
      ?measure a aqd:AQD_Measures;
      aqd:inspireId ?inspireId .
      ?inspireId rdfs:label ?inspireLabel .
      FILTER (CONTAINS(str(?measure), '" || $url || "'))
   }":)
   "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
    PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
    PREFIX dcterms: <http://purl.org/dc/terms/>
    PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

   SELECT DISTINCT ?localId 
   WHERE {
   values ?envelope { <" || $url || "> }
    ?graph dcterms:isPartOf ?envelope .
    ?graph contreg:xmlSchema ?xmlSchema .

    GRAPH ?graph {
        ?measure a aqd:AQD_Measures ;
        aqd:inspireId ?inspireId .
        ?inspireId rdfs:label ?inspireLabel .
        ?inspireId aqd:localId ?localId  
    }    

  }
   "
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

(:declare function query:getAllFeatureIds($featureTypes as xs:string*, $latestEnvelopeD as xs:string, $namespaces as xs:string*) as xs:string {
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
      FILTER (CONTAINS(STR(?zone), '" || $latestEnvelopeD || "'))
     }", " UNION ")
  let $end := "}"
  return $pre || $mid || $end
};:)

declare function query:getAllFeatureIds($featureTypes as xs:string*, $latestEnvelopeD as xs:string, $namespaces as xs:string*) as xs:string {
  let $pre := "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
    PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
    PREFIX dcterms: <http://purl.org/dc/terms/>
    PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

    SELECT distinct ?inspireLabel WHERE {

    values ?envelope { <" || $latestEnvelopeD || "> }
    ?graph dcterms:isPartOf ?envelope .
    ?graph contreg:xmlSchema ?xmlSchema .

  GRAPH ?graph {  "
      
      (:FILTER (CONTAINS(STR(?zone), '')):)
  let $mid := string-join(
    for $featureType in $featureTypes
    return "
    {
      ?zone a " || $featureType || ";
      aqd:inspireId ?inspireid .
      ?inspireid rdfs:label ?inspireLabel .
      ?inspireid aqd:namespace ?namespace
     }", " UNION ")
  let $end := "}FILTER (?namespace in ('" || string-join($namespaces, "' , '") || "'))
  }"
  return $pre || $mid || $end
};


(: Generic queries :)
(: declare function query:deliveryExists(
    $obligations as xs:string*,
    $countryCode as xs:string,
    $dir as xs:string,
    $reportingYear as xs:string
) as xs:boolean {
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
}; :)

declare function query:deliveryExists(
    $obligations as xs:string*,
    $countryCode as xs:string,
    $dir as xs:string,
    $reportingYear as xs:string
) as xs:boolean {
   let $query := query:deliveryExistsQuery($obligations, $countryCode, $dir, $reportingYear)
   return count(sparqlx:run($query)//sparql:binding[@name = 'envelope']/sparql:uri) > 0
};

declare function query:deliveryExistsQuery(
    $obligations as xs:string*,
    $countryCode as xs:string,
    $dir as xs:string,
    $reportingYear as xs:string
) as xs:string {
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
declare function query:getModelEndPosition(
    $latestDEnvelopes as xs:string*,
    $startDate as xs:string,
    $endDate as xs:string
) as xs:string {
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
    concat("


PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
PREFIX dct: <http://purl.org/dc/terms/>
PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>

        SELECT DISTINCT ?inspireLabel
        WHERE {
        GRAPH ?file {
            ?zone a aqd:AQD_Model . 
         }
         <", $latestDEnvelopes ,"> rod:hasFile ?file.
            ?zone aqd:inspireId ?inspireId .
            ?inspireId rdfs:label ?inspireLabel .
            ?zone aqd:observingCapability ?observingCapability .
            ?observingCapability aqd:observingTime ?observingTime .
            ?observingTime aqd:beginPosition ?beginPosition .
            optional {?observingTime aqd:endPosition ?endPosition }
            FILTER(xsd:date(SUBSTR(xsd:string(?beginPosition),1,10)) <= xsd:date('", $endDate, "')) .
            FILTER(!bound(?endPosition) or (xsd:date(SUBSTR(xsd:string(?endPosition),1,10)) > xsd:date('", $startDate, "'))) .
            FILTER(", $filters ,")
}


")
};

declare function query:getSamplingPointEndPosition(
    $latestDEnvelopes as xs:string*,
    $startDate as xs:string,
    $endDate as xs:string
) as xs:string {
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
    concat("
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
PREFIX dct: <http://purl.org/dc/terms/>
PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>

        SELECT DISTINCT ?inspireLabel
        WHERE {
        GRAPH ?file {
            ?zone a aqd:AQD_SamplingPoint . 
         }
         <", $latestDEnvelopes ,"> rod:hasFile ?file.
            ?zone aqd:inspireId ?inspireId .
            ?inspireId rdfs:label ?inspireLabel .
            ?zone aqd:observingCapability ?observingCapability .
            ?observingCapability aqd:observingTime ?observingTime .
            ?observingTime aqd:beginPosition ?beginPosition .
            optional {?observingTime aqd:endPosition ?endPosition }
            FILTER(xsd:date(SUBSTR(xsd:string(?beginPosition),1,10)) <= xsd:date('", $endDate, "')) .
            FILTER(!bound(?endPosition) or (xsd:date(SUBSTR(xsd:string(?endPosition),1,10)) > xsd:date('", $startDate, "'))) .

}
    ")
};

(: Returns latest report envelope for this country and Year 
declare function query:getLatestEnvelope(
    $cdrUrl as xs:string,
    $reportingYear as xs:string
) as xs:string {
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
:)
(: Returns latest report envelope for this country and Year :)
(:@goititer changed FILTER STRSTARTS with FILTER(CONTAINS, it didn´t return results with STRSTARTS :)
declare function query:getLatestEnvelope(
    $cdrUrl as xs:string,
    $reportingYear as xs:string
) as xs:string {
  let $url := "http://" || $cdrUrl ||""
  let $query := concat("
PREFIX aqd: <http://rod.eionet.europa.eu/schema.rdf#>
     SELECT *
     WHERE {
       FILTER(CONTAINS(str(?graph), '", $url,"')) 
       GRAPH ?graph {
        ?envelope a aqd:Delivery ;
        aqd:released ?date ;
        aqd:hasFile ?file ;
        aqd:period ?period
  } 
  FILTER(CONTAINS(str(?period), '", $reportingYear, "'))
 } 
 order by desc(?date)
 limit 1
")
  let $result := data(sparqlx:run($query)//sparql:binding[@name='envelope']/sparql:uri)
  return if ($result) then $result else "FILENOTFOUND"
};

(: Returns latest report envelope for this country 
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
:)

(: Returns latest report envelope for this country :)
declare function query:getLatestEnvelope($cdrUrl as xs:string) as xs:string {
  let $url := "http://" || $cdrUrl ||""
  let $query :=
    "PREFIX aqd: <http://rod.eionet.europa.eu/schema.rdf#>
     SELECT *
     WHERE {
       FILTER(STRSTARTS(str(?graph), '" || $url ||"'))
       GRAPH ?graph {
        ?envelope a aqd:Delivery ;
        aqd:released ?date ;
        aqd:hasFile ?file ;
        aqd:period ?period
  } 
 } 
 order by desc(?date)
 limit 1"
  let $result := data(sparqlx:run($query)//sparql:binding[@name='envelope']/sparql:uri)
  return if ($result) then $result else "FILENOTFOUND"
};

(:declare function query:getEnvelopes(
    $cdrUrl as xs:string
) as xs:string* {
  let $query :=
    "PREFIX aqd: <http://rod.eionet.europa.eu/schema.rdf#>
     SELECT *
     WHERE {
        ?envelope a aqd:Delivery ;
        aqd:released ?date ;
        aqd:hasFile ?file ;
        aqd:period ?period
        FILTER(CONTAINS(str(?envelope), '" || $cdrUrl || "'))
     } order by desc(?date)"
     let $result := data(sparqlx:run($query)//sparql:binding[@name='envelope']/sparql:uri)
  return $result
};:)

declare function query:getEnvelopes(
    $cdrUrl as xs:string
) as xs:string* {
  let $url := "http://" || $cdrUrl ||""
  let $query :=
    "PREFIX aqd: <http://rod.eionet.europa.eu/schema.rdf#>
     SELECT *
     WHERE {
       FILTER(STRSTARTS(str(?graph), '"|| $url ||"'))
       GRAPH ?graph {
        ?envelope a aqd:Delivery ;
        aqd:released ?date ;
        aqd:hasFile ?file ;
        aqd:period ?period
  } 
 } 
 order by desc(?date)"
     let $result := data(sparqlx:run($query)//sparql:binding[@name='envelope']/sparql:uri)
  return $result
};

(:declare function query:getEnvelopes(
    $cdrUrl as xs:string,
    $reportingYear as xs:string
) as xs:string* {
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
};:)

declare function query:getEnvelopes(
    $cdrUrl as xs:string,
    $reportingYear as xs:string
) as xs:string* {
  let $url := "http://" || $cdrUrl ||""
  let $query :=
    "PREFIX aqd: <http://rod.eionet.europa.eu/schema.rdf#>
     SELECT *
     WHERE {
       FILTER(STRSTARTS(str(?graph), '" || $url ||"'))
       GRAPH ?graph{
        ?envelope a aqd:Delivery ;
        aqd:released ?date ;
        aqd:hasFile ?file ;
        aqd:period ?period
       }
       FILTER(STRSTARTS(str(?period), '"|| $reportingYear ||"'))
      } order by desc(?date)
     "
     let $result := data(sparqlx:run($query)//sparql:binding[@name='envelope']/sparql:uri)
  return $result
};

(: declare function query:getAllRegimeIds($namespaces as xs:string*) as xs:string* {
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
        FILTER(!(CONTAINS(str(?regime), 'c_preliminary')))
        FILTER(str(?namespace) in ('" || string-join($namespaces, "','") || "'))
  }"
  return data(sparqlx:run($query)//sparql:binding[@name='inspireLabel']/sparql:literal)
}; :)

declare function query:getAllRegimeIds($namespaces as xs:string*) as xs:string* {
  let $query := query:getAllRegimeIdsQuery($namespaces)
  return data(sparqlx:run($query)//sparql:binding[@name='inspireLabel']/sparql:literal)
};

declare function query:getAllRegimeIdsQuery($namespaces as xs:string*) as xs:string* {
   "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>

SELECT 
*
WHERE {
  VALUES ?namespace { '" || string-join($namespaces, " ") || "' }
  GRAPH ?file {
    ?inspireId aqd:namespace ?namespace .
  }
  ?regime a aqd:AQD_AssessmentRegime .
  ?regime aqd:inspireId ?inspireId .
  ?inspireId rdfs:label ?inspireLabel .
  FILTER(!(CONTAINS(str(?regime), 'c_preliminary')))
  }"
};

(:declare function query:getAllRegimeIdsQuery($namespaces as xs:string*) as xs:string* {
   "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>

   SELECT *
   WHERE {
        ?regime a aqd:AQD_AssessmentRegime ;
        aqd:inspireId ?inspireId .
        ?inspireId rdfs:label ?inspireLabel .
        ?inspireId aqd:namespace ?namespace
        FILTER(!(CONTAINS(str(?regime), 'c_preliminary')))
        FILTER(str(?namespace) in ('" || string-join($namespaces, "','") || "'))
  }"
};:)

(: declare function query:getAllAttainmentIds2($namespaces as xs:string*) as xs:string* {
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
}; :)

declare function query:getAllAttainmentIds2($namespaces as xs:string*) as xs:string* {
  let $query := query:getAllAttainmentIds2Query($namespaces) 
  return data(sparqlx:run($query)//sparql:binding[@name='inspireLabel']/sparql:literal)
};

declare function query:getAllAttainmentIds2Query($namespaces as xs:string*) as xs:string {
   "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
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
};

(:~ Returns the pollutants for an attainment
:)
(: declare function query:get-pollutant-for-attainment(
    $url as xs:string?
) as xs:string? {
    let $query := "
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

SELECT distinct(?pollutant)
WHERE {
?sourceApportionment a aq:AQD_Attainment;
    aq:pollutant ?pollutant;
    aq:inspireId ?inspireId.
?inspireId rdfs:label ?label
FILTER(?label = '" || $url || "')
}
"
  let $res := sparqlx:run($query)

  return 
    if(empty($res)) then
      ""
    else
      data($res//sparql:binding[@name='pollutant']/sparql:uri)
}; :)

declare function query:get-pollutant-for-attainment(
    $url as xs:string?
) as xs:string? {
  let $res := sparqlx:run(query:get-pollutant-for-attainment-query($url))

  return 
    if(empty($res)) then
      ""
    else
      data($res//sparql:binding[@name='pollutant']/sparql:uri)
};

declare function query:get-pollutant-for-attainment-query(
    $url as xs:string?
) as xs:string? {
    "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
    
    SELECT distinct(?pollutant)
    WHERE {
    ?sourceApportionment a aq:AQD_Attainment;
        aq:pollutant ?pollutant;
        aq:inspireId ?inspireId.
    ?inspireId rdfs:label ?label
    FILTER(?label = '" || $url || "')
    }"
};


declare function query:get-pollutant-for-attainmentI41(
    $url as xs:string?,
    $year as xs:string,
    $latestEnvelopes as xs:string*
) as xs:string? {
  let $res := sparqlx:run(query:get-pollutant-for-attainment-queryI41($url,$year))

   
        for $result in $res
        return
        if (common:isLatestEnvelope( substring($result/sparql:binding[@name="envelope"]/sparql:uri, 1), $latestEnvelopes))  then

           if(empty($res)) then
              ""
            else
               fn:string($result//sparql:binding[@name='pollutant']/sparql:uri)

  
};
declare function query:get-pollutant-for-attainment-queryI41(
    $url as xs:string?,
     $year as xs:string
) as xs:string? {

  " PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
    PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>
    PREFIX dcterms: <http://purl.org/dc/terms/>
      
      SELECT distinct(?pollutant)?label year(?startOfPeriod) ?envelope
      WHERE {
        GRAPH ?source {
         ?sourceApportionment a aq:AQD_Attainment;
          aq:pollutant ?pollutant;
          aq:inspireId ?inspireId.
          ?inspireId rdfs:label ?label
          }
   
          ?source dcterms:isPartOf ?envelope .
          ?envelope rod:startOfPeriod ?startOfPeriod .
          ?envelope rod:endOfPeriod ?endOfPeriod .   
          ?envelope rod:startOfPeriod ?startOfPeriod.
      
      FILTER(?label='" || $url || "').
      FILTER ( year(?startOfPeriod) = " || $year || " )
    }"

};

declare function query:getPollutantCodeAndProtectionTarge(
    $cdrUrl as xs:string,
    $bDir as xs:string
) as xs:string {
  concat(
"PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

      SELECT distinct ?zone ?inspireId ?inspireLabel ?pollutants ?pollutantCode ?protectionTarget

        WHERE {

       FILTER (STRSTARTS(STR(?graph), 'http://", $cdrUrl, $bDir, "'))
       GRAPH ?graph {  
    
              ?zone a aqd:AQD_Zone ;
              aqd:inspireId ?inspireId .
              ?inspireId rdfs:label ?inspireLabel .}
              ?zone aqd:pollutants ?pollutants .
              ?pollutants aqd:pollutantCode ?pollutantCode .
              ?pollutants aqd:protectionTarget ?protectionTarget .

      
    }"
    )
};

(:declare function query:getPollutantCodeAndProtectionTarge(
    $cdrUrl as xs:string,
    $bDir as xs:string
) as xs:string {
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
};:)


declare function query:getC03a($cdrUrl as xs:string) as xs:string* {
   (: let $query :=
   "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>

   SELECT ?localId 
   WHERE {
          ?assessmentRegime a aqd:AQD_AssessmentRegime;
          aqd:inspireId ?inspireId .
          ?inspireId rdfs:label ?inspireLabel .
          ?inspireId aqd:localId ?localId           
          FILTER CONTAINS(str(?assessmentRegime),'" || $cdrUrl || "')
    }"
    let $result := sparqlx:run($query) :)
    let $result := sparqlx:run(query:getC03aQuery($cdrUrl))
    for $x in $result
    return string-join(($x/sparql:binding[@name = 'localId']/sparql:literal, $x/sparql:binding[@name = 'samplingPoint']/sparql:literal), "###")
};

declare function query:getC03aQuery($cdrUrl as xs:string) as xs:string* {
   "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
    PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
    PREFIX dcterms: <http://purl.org/dc/terms/>
    PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

   SELECT DISTINCT ?localId 
   WHERE {
    values ?envelope { <" || $cdrUrl || "> }
    ?graph dcterms:isPartOf ?envelope .
    ?graph contreg:xmlSchema ?xmlSchema .
    
    GRAPH ?graph {
        ?assessmentRegime a aqd:AQD_AssessmentRegime ;
        aqd:inspireId ?inspireId .
        ?inspireId rdfs:label ?inspireLabel .
        ?inspireId aqd:localId ?localId  
    }    
    
  }"
};

declare function query:getC03b($cdrUrl as xs:string) as xs:string* {
   (: let $query :=
   "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>

   SELECT ?localId ?samplingPoint
   WHERE {
          ?assessmentRegime a aqd:AQD_AssessmentRegime;
          aqd:inspireId ?inspireId .
          ?inspireId rdfs:label ?inspireLabel .
          ?inspireId aqd:localId ?localId .
          ?assessmentRegime aqd:assessmentMethods ?assessmentMethods .
          ?assessmentMethods aqd:samplingPointAssessmentMetadata ?samplingPointMetadata .
          ?samplingPointMetadata aq:hasDeclaration ?declaration .
          ?declaration aqd:inspireId ?samplingPointId .
          ?samplingPointId aqd:localId ?samplingPoint
          FILTER CONTAINS(str(?assessmentRegime),'" || $cdrUrl || "')
    }"
    let $result := sparqlx:run($query) :)
    let $result := sparqlx:run(query:getC03bquery($cdrUrl))
    for $x in $result
    return string-join(($x/sparql:binding[@name = 'localId']/sparql:literal, $x/sparql:binding[@name = 'samplingPoint']/sparql:literal), "###")
};

declare function query:getC03bquery($cdrUrl as xs:string) as xs:string* {
   "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
  PREFIX dcterms: <http://purl.org/dc/terms/>
  PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

   SELECT DISTINCT ?localId ?samplingPoint
   WHERE {
    values ?envelope { <" || $cdrUrl || "> }
    ?graph dcterms:isPartOf ?envelope .
    ?graph contreg:xmlSchema ?xmlSchema .
  
  GRAPH ?graph {
          ?assessmentRegime a aqd:AQD_AssessmentRegime .
          ?assessmentRegime aqd:inspireId ?inspireId .
          ?inspireId rdfs:label ?inspireLabel .
          ?inspireId aqd:localId ?localId .
}
          ?assessmentRegime aqd:assessmentMethods ?assessmentMethods .
          ?assessmentMethods aqd:samplingPointAssessmentMetadata ?samplingPointMetadata .
          ?samplingPointMetadata aq:hasDeclaration ?declaration .
          ?declaration aqd:inspireId ?samplingPointId .
          ?samplingPointId aqd:localId ?samplingPoint .
    
}"
};

(:
declare function query:getC03c($cdrUrl as xs:string) as xs:string* {inspireLabel
    
   "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>

   SELECT ?localId ?samplingPoint ?assessmentType
   WHERE {
          ?assessmentRegime a aqd:AQD_AssessmentRegime;
          aqd:inspireId ?inspireId .
          ?inspireId rdfs:label ?inspireLabel .
          ?inspireId aqd:localId ?localId .
          ?assessmentRegime aqd:assessmentMethods ?assessmentMethods .
          ?assessmentMethods aqd:samplingPointAssessmentMetadata ?samplingPointMetadata .
          ?assessmentMethods aqd:assessmentType ?assessmentType .
          ?samplingPointMetadata aq:hasDeclaration ?declaration .
          ?declaration aqd:inspireId ?samplingPointId .
          ?samplingPointId aqd:localId ?samplingPoint
          FILTER CONTAINS(str(?assessmentRegime),'" || $cdrUrl || "')
    }"
   
};:)

declare function query:getC03c($cdrUrl as xs:string) as xs:string* {
    
   "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
  PREFIX dcterms: <http://purl.org/dc/terms/>
  PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

   SELECT DISTINCT
    ?localId ?samplingPoint ?assessmentType
   WHERE {
    values ?envelope { <" || $cdrUrl || "> }
    ?graph dcterms:isPartOf ?envelope .
    ?graph contreg:xmlSchema ?xmlSchema .
  
      GRAPH ?graph {
              ?assessmentRegime a aqd:AQD_AssessmentRegime;
              aqd:inspireId ?inspireId .
              ?inspireId rdfs:label ?inspireLabel .
              ?inspireId aqd:localId ?localId .
              }  
    ?assessmentRegime aqd:assessmentMethods ?assessmentMethods .
    ?assessmentMethods aqd:samplingPointAssessmentMetadata ?samplingPointMetadata .
    ?assessmentMethods aqd:assessmentType ?assessmentType .
    ?samplingPointMetadata aq:hasDeclaration ?declaration .
    ?declaration aqd:inspireId ?samplingPointId .
    ?samplingPointId aqd:localId ?samplingPoint
        
}"
   
};
(:declare function query:getC31($cdrUrl as xs:string, $reportingYear as xs:string) as xs:string {
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
  FILTER (((xsd:date(substr(str(?beginPosition),1,10)) <= xsd:date('" || $reportingYear || "-01-01')) AND (!(bound(?endPosition)) ||
xsd:date(substr(str(?endPosition),1,10)) >= xsd:date('" || $reportingYear || "-12-31')))) .
  FILTER CONTAINS(str(?zoneURI),'" || $cdrUrl || "') .
  }"
};:)

declare function query:getC31($cdrUrl as xs:string, $reportingYear as xs:string) as xs:string {
  " 
  PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
  PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
  PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
  PREFIX dcterms: <http://purl.org/dc/terms/>
  PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

   SELECT DISTINCT
    ?Pollutant
    ?ProtectionTarget
    count(distinct bif:concat(str(?Zone), str(?pollURI), str(?ProtectionTarget))) AS ?countOnB

   WHERE {
    values ?envelope { <" || $cdrUrl || "> }
    ?graph dcterms:isPartOf ?envelope .
    ?graph contreg:xmlSchema ?xmlSchema .
    
      GRAPH ?graph {
              ?zoneURI a aqd:AQD_Zone;
              aqd:zoneCode ?Zone;
              aqd:pollutants ?polltargetURI;
              aqd:inspireId ?inspireId;

              aqd:designationPeriod ?designationPeriod .
              ?designationPeriod aqd:beginPosition ?beginPosition .
              OPTIONAL { ?designationPeriod aqd:endPosition ?endPosition . }
              ?inspireId aqd:namespace ?Namespace .
      }  
    ?polltargetURI aqd:protectionTarget ?ProtectionTarget .
    ?polltargetURI aqd:pollutantCode ?pollURI .
    ?pollURI rdfs:label ?Pollutant .
    FILTER regex(?pollURI,'') .
    FILTER (((xsd:date(substr(str(?beginPosition),1,10)) <= xsd:date('" || $reportingYear || "-01-01')) AND (!(bound(?endPosition)) ||
    xsd:date(substr(str(?endPosition),1,10)) >= xsd:date('" || $reportingYear || "-12-31')))) .
   
  }"
};


(:declare function query:getC31b($cdrUrl as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
  PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

  SELECT DISTINCT
  ?Pollutant
  ?ProtectionTarget
  count(distinct bif:concat(str(?Zone), str(?pollURI), str(?ProtectionTarget))) AS ?countOnPrelimC

  WHERE {
  ?assessmentRegime a aqd:AQD_AssessmentRegime;
  aqd:zone ?Zone;
  aqd:pollutant ?pollURI;
  aqd:assessmentThreshold ?assessmentThreshold .
  
  ?assessmentThreshold aqd:environmentalObjective ?environmentalObjective .
  ?environmentalObjective aqd:protectionTarget ?ProtectionTarget .
  ?pollURI rdfs:label ?Pollutant .
  FILTER regex(?pollURI,'') .
  FILTER CONTAINS(str(?assessmentRegime),'" || $cdrUrl || "') .
  }"
};:)

declare function query:getC31b($cdrUrl as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
  PREFIX dcterms: <http://purl.org/dc/terms/>
  PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

   SELECT   DISTINCT
    ?Pollutant
    ?ProtectionTarget
    count(distinct bif:concat(str(?Zone), str(?pollURI), str(?ProtectionTarget))) AS ?countOnPrelimC

    WHERE {
    values ?envelope { <" || $cdrUrl || "> }
    ?graph dcterms:isPartOf ?envelope .
    ?graph contreg:xmlSchema ?xmlSchema .
    
    GRAPH ?graph {
              ?assessmentRegime a aqd:AQD_AssessmentRegime;
      aqd:zone ?Zone;
      aqd:pollutant ?pollURI;
      aqd:assessmentThreshold ?assessmentThreshold .
    }  
      ?assessmentThreshold aqd:environmentalObjective ?environmentalObjective .
      ?environmentalObjective aqd:protectionTarget ?ProtectionTarget .
      ?pollURI rdfs:label ?Pollutant .

    FILTER regex(?pollURI,'') .   
}"
};



   declare function query:getE26b($url as xs:string*) as xs:string {
    let $filters :=
        for $x in $url
        return "STRSTARTS(str(?samplingPoint), '" || $x || "')"
    let $filters := "FILTER(" || string-join($filters, " OR ") || ")"
    return
        "
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
    PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
    PREFIX dcterms: <http://purl.org/dc/terms/>
    PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>


   SELECT ?localId ?featureOfInterest ?procedure ?observedProperty ?inspireLabel ?beginPosition ?endPosition
   WHERE {
        values ?envelope { <" || $url || "> } 
        ?graph dcterms:isPartOf ?envelope .
        ?graph contreg:xmlSchema ?xmlSchema .
       GRAPH ?graph {

         ?samplingPoint a aqd:AQD_SamplingPoint;
         aqd:observingCapability ?observingCapability;
         aqd:inspireId ?inspireId .}
         ?inspireId rdfs:label ?inspireLabel .
         ?inspireId aqd:localId ?localId .
         ?inspireId aqd:namespace ?namespace .
         ?observingCapability aqd:observingTime ?observingTime .
         ?observingTime aqd:beginPosition ?beginPosition .
         OPTIONAL { ?observingTime aqd:endPosition ?endPosition } .
         ?observingCapability aqd:featureOfInterest ?featureOfInterest .
         ?observingCapability aqd:procedure ?procedure .
         ?observingCapability aqd:observedProperty ?observedProperty . 

   }"
};


declare function query:getE26b($url as xs:string*, $pollutant as xs:string*) as xs:string {
        "
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
    PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
    PREFIX dcterms: <http://purl.org/dc/terms/>
    PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>


   SELECT ?localId ?featureOfInterest ?procedure ?observedProperty ?inspireLabel ?beginPosition ?endPosition
   WHERE {
        values ?envelope { <" || $url || "> } 
        ?graph dcterms:isPartOf ?envelope .
        ?graph contreg:xmlSchema ?xmlSchema .
       GRAPH ?graph {

         ?samplingPoint a aqd:AQD_SamplingPoint;
         aqd:observingCapability ?observingCapability;
         aqd:inspireId ?inspireId .}
         ?inspireId rdfs:label ?inspireLabel .
         ?inspireId aqd:localId ?localId .
         ?inspireId aqd:namespace ?namespace .
         ?observingCapability aqd:observingTime ?observingTime .
         ?observingTime aqd:beginPosition ?beginPosition .
         OPTIONAL { ?observingTime aqd:endPosition ?endPosition } .
         ?observingCapability aqd:featureOfInterest ?featureOfInterest .
         ?observingCapability aqd:procedure ?procedure .
         ?observingCapability aqd:observedProperty ?observedProperty . 
     FILTER(?observedProperty in (" || $pollutant || "))
   }"
};
(:
declare function query:getE26b($url as xs:string*) as xs:string {
    let $filters :=
        for $x in $url
        return "STRSTARTS(str(?samplingPoint), '" || $x || "')"
    let $filters := "FILTER(" || string-join($filters, " OR ") || ")"
    return
        "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

   SELECT ?localId ?featureOfInterest ?procedure ?observedProperty ?inspireLabel ?beginPosition ?endPosition
   WHERE {
         ?samplingPoint a aqd:AQD_SamplingPoint;
         aqd:observingCapability ?observingCapability;
         aqd:inspireId ?inspireId .
         ?inspireId rdfs:label ?inspireLabel .
         ?inspireId aqd:localId ?localId .
         ?inspireId aqd:namespace ?namespace .
         ?observingCapability aqd:observingTime ?observingTime .
         ?observingTime aqd:beginPosition ?beginPosition .
         OPTIONAL { ?observingTime aqd:endPosition ?endPosition } .
         ?observingCapability aqd:featureOfInterest ?featureOfInterest .
         ?observingCapability aqd:procedure ?procedure .
         ?observingCapability aqd:observedProperty ?observedProperty . " || $filters ||"
   }"
};:)

(: declare function query:getE34($countryCode as xs:string, $reportingYear as xs:string) {
    let $reportingYear := xs:integer($reportingYear) - 1
    return
    "PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX dcterms: <http://purl.org/dc/terms/>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
    PREFIX aqr: <http://reference.eionet.europa.eu/aq/ontology/>
    PREFIX dd: <http://dd.eionet.europa.eu/property/>

    SELECT DISTINCT

    replace(replace(replace(str(?SamplingPointLocalId_URI),'http://reference.eionet.europa.eu/aq/',''),?Namespace,''),'/','') as ?SamplingPointLocalId
    ?AQValue
    WHERE {
      ?statsURI aqr:inspireNamespace ?Namespace .
      ?statsURI aqr:samplingPoint ?SamplingPointLocalId_URI .
      ?statsURI aqr:aggregationType ?AggregationType_URI .
      ?statsURI aqr:airqualityValue ?AQValue .
      ?statsURI aqr:beginPosition ?BeginPosition .
      ?statsURI aqr:observationValidity ?Validity_URI .
      ?Validity_URI rdfs:label ?Validity .
      FILTER (?Validity = 'Valid') .
      FILTER (year(xsd:dateTime(?BeginPosition)) = " || $reportingYear || ") .

      ?AggregationType_URI rdfs:label ?AggregationType .
      ?AggregationType_URI skos:notation ?DataAggregationType .
      FILTER (?DataAggregationType = 'P1Y' || ?DataAggregationType = 'P1Y-WA-avg') .

      ?namespaces rdfs:label ?Namespace .
      ?namespaces skos:inScheme <http://dd.eionet.europa.eu/vocabulary/aq/namespace/> .
      ?namespaces dd:inCountry ?cntry_URI .
      FILTER (STRENDS(STR(?cntry_URI), '/" || upper-case($countryCode) || "')) .
    }"
}; :)

declare function query:getE34($countryCode as xs:string, $reportingYear as xs:string) {
    let $reportingYear := xs:integer($reportingYear) - 1
    return
    "PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
PREFIX aqr: <http://reference.eionet.europa.eu/aq/ontology/>
PREFIX dd: <http://dd.eionet.europa.eu/property/>
PREFIX countries: <http://dd.eionet.europa.eu/vocabulary/common/countries/>
PREFIX aggregationprocess: <http://dd.eionet.europa.eu/vocabulary/aq/aggregationprocess/>

SELECT DISTINCT
  REPLACE(REPLACE(REPLACE(STR(?SamplingPointLocalId_URI),'http://reference.eionet.europa.eu/aq/',''),?Namespace,''),'/','') as ?SamplingPointLocalId
  ?AQValue
  WHERE {
    GRAPH ?g { ?statsURI aqr:inspireNamespace ?Namespace . 
      ?statsURI aqr:samplingPoint ?SamplingPointLocalId_URI .
      ?statsURI aqr:aggregationType ?AggregationType_URI .
      FILTER (?AggregationType_URI IN (aggregationprocess:P1Y, aggregationprocess:P1Y-WA-avg)) .
      ?statsURI aqr:airqualityValue ?AQValue .
      ?statsURI aqr:beginPosition ?BeginPosition .
      FILTER (YEAR(?BeginPosition) = " || $reportingYear || ")
      ?statsURI aqr:observationValidity <http://dd.eionet.europa.eu/vocabulary/aq/observationvalidity/1> .
    }
    ?namespaces rdfs:label ?Namespace .
    ?namespaces skos:inScheme <http://dd.eionet.europa.eu/vocabulary/aq/namespace/> .
    ?namespaces dd:inCountry countries:" || upper-case($countryCode) || " .
  }" 
};

(: declare function query:getE34Sampling($countryCode as xs:string, $reportingYear as xs:string, $samplingPoint as xs:string) as xs:string {
    let $reportingYear := xs:integer($reportingYear) - 1
    return
    "
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
    PREFIX aqr: <http://reference.eionet.europa.eu/aq/ontology/>

    SELECT DISTINCT

    ?AQValue
    WHERE {
      ?statsURI aqr:inspireNamespace ?Namespace .
      ?statsURI aqr:samplingPoint ?SamplingPointLocalId_URI .
      ?statsURI aqr:aggregationType ?AggregationType_URI .
      ?statsURI aqr:airqualityValue ?AQValue .
      ?statsURI aqr:beginPosition ?BeginPosition .
      ?statsURI aqr:observationValidity ?Validity_URI .
      ?Validity_URI rdfs:label ?Validity .
      FILTER(replace(replace(replace(str(?SamplingPointLocalId_URI),'http://reference.eionet.europa.eu/aq/',''),?Namespace,''),'/','') = '"|| $samplingPoint ||"')

      FILTER (?Validity = 'Valid') .
      FILTER (year(xsd:dateTime(?BeginPosition)) = " || $reportingYear || ") .

      ?AggregationType_URI rdfs:label ?AggregationType .
      ?AggregationType_URI skos:notation ?DataAggregationType .
      FILTER (?DataAggregationType = 'P1Y' ) .

    }"
};  :)

(: declare function query:getE34Sampling($countryCode as xs:string, $reportingYear as xs:string, $samplingPoint as xs:string) as xs:string {
    let $reportingYear := xs:integer($reportingYear) - 1
    return
    "PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
    PREFIX aqr: <http://reference.eionet.europa.eu/aq/ontology/>
    PREFIX dcterms: <http://purl.org/dc/terms/>
    PREFIX aggregationprocess: <http://dd.eionet.europa.eu/vocabulary/aq/aggregationprocess/>

    SELECT DISTINCT

    ?AQValue
    WHERE {
      
      FILTER(replace(replace(replace(str(?SamplingPointLocalId_URI),'http://reference.eionet.europa.eu/aq/',''),?Namespace,''),'/','') = '"|| $samplingPoint ||"') 
      
      GRAPH ?g {
        ?statsURI aqr:inspireNamespace ?Namespace .
        ?statsURI aqr:samplingPoint ?SamplingPointLocalId_URI .
        ?statsURI aqr:aggregationType ?AggregationType_URI .
        FILTER (?AggregationType_URI IN (aggregationprocess:P1Y)) .
  
        ?statsURI aqr:airqualityValue ?AQValue .
        ?statsURI aqr:beginPosition ?BeginPosition .
        
        FILTER (YEAR(?BeginPosition) = " || $reportingYear || ") . 
        
        ?statsURI aqr:observationValidity <http://dd.eionet.europa.eu/vocabulary/aq/observationvalidity/1> .
      } 
    }"
}; :)

declare function query:getE34Sampling($countryCode as xs:string, $reportingYear as xs:string, $samplingPoint as xs:string) as xs:string {
    let $reportingYear := xs:integer($reportingYear) - 1
    return
    "PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
    PREFIX aqr: <http://reference.eionet.europa.eu/aq/ontology/>
    PREFIX dcterms: <http://purl.org/dc/terms/>
    PREFIX aggregationprocess: <http://dd.eionet.europa.eu/vocabulary/aq/aggregationprocess/>

    SELECT DISTINCT

    ?AQValue
    WHERE {
     
      FILTER(replace(str(?SamplingPointLocalId_URI),concat('http://reference.eionet.europa.eu/aq/', ?Namespace,'/'),'') = '"|| $samplingPoint ||"') 
      
      GRAPH ?g {
        ?statsURI aqr:inspireNamespace ?Namespace .
        ?statsURI aqr:samplingPoint ?SamplingPointLocalId_URI .
        ?statsURI aqr:aggregationType ?AggregationType_URI .
        FILTER (?AggregationType_URI IN (aggregationprocess:P1Y)) .}
  
        ?statsURI aqr:airqualityValue ?AQValue .
        ?statsURI aqr:beginPosition ?BeginPosition .
        
        FILTER (YEAR(?BeginPosition) = " || $reportingYear || ") . 
        
        ?statsURI aqr:observationValidity <http://dd.eionet.europa.eu/vocabulary/aq/observationvalidity/1> .
      
    }"
};

(:declare function query:getG14(
    $envelopeB as xs:string,
    $envelopeC as xs:string,
    $reportingYear as xs:string
) as xs:string {
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
       FILTER (((xsd:date(substr(str(?beginPosition),1,10)) <= xsd:date('" || $reportingYear || "-01-01')) AND (!(bound(?endPosition)) ||
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
};:)




declare function query:getG14(
    $envelopeB as xs:string,
    $envelopeC as xs:string,
    $reportingYear as xs:string
) as xs:string {
"PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
PREFIX prop: <http://dd.eionet.europa.eu/property/>
  PREFIX dcterms: <http://purl.org/dc/terms/>
  PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

  SELECT *

  WHERE {{
  SELECT DISTINCT
  str(?Pollutant) as ?Pollutant
  str(?ProtectionTarget) as ?ProtectionTarget
  count(distinct bif:concat(str(?Zone), str(?pollURI), str(?ProtectionTarget))) AS ?countOnB

  WHERE {
      values ?envelope {<" || $envelopeB || ">}
      ?graph dcterms:isPartOf ?envelope .
      ?graph contreg:xmlSchema ?xmlSchema .
      GRAPH ?graph {
       ?zoneURI a aqd:AQD_Zone;
       aqd:zoneCode ?Zone;
       aqd:pollutants ?polltargetURI;
       aqd:inspireId ?inspireId;
       aqd:designationPeriod ?designationPeriod .
       ?designationPeriod aqd:beginPosition ?beginPosition .
       OPTIONAL { ?designationPeriod aqd:endPosition ?endPosition . }
       ?inspireId aqd:namespace ?Namespace .
       ?polltargetURI aqd:protectionTarget ?ProtectionTarget .
       ?polltargetURI aqd:pollutantCode ?pollURI .}
       ?pollURI rdfs:label ?Pollutant
              FILTER (((xsd:date(substr(str(?beginPosition),1,10)) <= xsd:date('" || $reportingYear || "-01-01')) AND (!(bound(?endPosition)) ||
xsd:date(substr(str(?endPosition),1,10)) >= xsd:date('" || $reportingYear || "-12-31')))) .
       FILTER CONTAINS(str(?zoneURI),'" || $envelopeB || "') .
  }}
    {
  SELECT DISTINCT
  str(?Pollutant) as ?Pollutant
  str(?ProtectionTarget) as ?ProtectionTarget
  count(distinct bif:concat(str(?Zone), str(?pollURI), str(?ProtectionTarget))) AS ?countOnC

  WHERE {

      values ?envelope {<" || $envelopeC || ">}
      ?graph dcterms:isPartOf ?envelope .
      ?graph contreg:xmlSchema ?xmlSchema .
      GRAPH ?graph {
    ?areURI a aqd:AQD_AssessmentRegime;
       aqd:zone ?Zone;
       aqd:pollutant ?pollURI;
       aqd:assessmentThreshold ?areThre ;
       aqd:inspireId ?inspireId .
       ?inspireId aqd:namespace ?Namespace .
       ?areThre aqd:environmentalObjective ?envObj .}
       ?envObj aqd:protectionTarget ?ProtectionTarget .
       ?pollURI rdfs:label ?Pollutant .
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




declare function query:getG66($cdrUrl as xs:string, $reportingYear as xs:string) as xs:string* {
    
   "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>

   SELECT ?localId ?assessment
   WHERE {
          ?assessmentRegime a aqd:AQD_AssessmentRegime;
          aqd:inspireId ?inspireId .
          ?inspireId rdfs:label ?inspireLabel .
          ?inspireId aqd:localId ?localId .
          ?assessmentRegime aqd:assessmentMethods ?assessmentMethods .
          ?assessmentMethods aqd:modelAssessmentMetadata ?assessment            
          FILTER CONTAINS(str(?assessmentRegime),'" || $cdrUrl || "')
    }"
   
};

declare function query:getAssessmentMethods() as xs:string {
  "PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
  PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
  PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>

  SELECT 
  ?assessmentRegime 
  ?inspireId 
  ?localId 
  ?inspireLabel 
  ?assessmentMethods  
  ?assessmentMetadata 
  ?assessmentMetadataNamespace 
  ?assessmentMetadataId 
  ?samplingPointAssessmentMetadata 
  ?metadataId 
  ?metadataNamespace

     WHERE {
            ?assessmentRegime a aqd:AQD_AssessmentRegime .
            ?assessmentRegime aqd:inspireId ?inspireId .
            ?inspireId rdfs:label ?inspireLabel .
            ?inspireId aqd:localId ?localId .
            ?assessmentRegime aqd:assessmentMethods ?assessmentMethods .
            ?assessmentMethods aqd:modelAssessmentMetadata ?assessmentMetadata .
            ?assessmentMetadata aq:inspireNamespace ?assessmentMetadataNamespace .
            ?assessmentMetadata aq:inspireId ?assessmentMetadataId .
            OPTIONAL { 
                       ?assessmentMethods aqd:samplingPointAssessmentMetadata ?samplingPointAssessmentMetadata. 
                       ?samplingPointAssessmentMetadata aq:inspireId ?metadataId.                                     
                       ?samplingPointAssessmentMetadata aq:inspireNamespace ?metadataNamespace . 
            }
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

declare function query:getSamplingPointAssessmentMetadata2($countryCode as xs:string) as xs:string {
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
          FILTER(CONTAINS(str(?localId), '" || common:getCdrUrl($countryCode) || "'))
          }"
};

(: returns a list of assessment methods for the inspireid :)
(: declare function query:get-assessment-methods-for-inspireid() as xs:string {
  let $query := "
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>

SELECT ?assessmentRegime ?inspireId ?localId ?inspireLabel ?assessmentMethods
WHERE {
      ?assessmentRegime a aqd:AQD_AssessmentRegime ;
      aqd:inspireId ?inspireId .
      ?inspireId rdfs:label ?inspireLabel .
      ?inspireId aqd:localId ?localId .
      ?assessmentRegime aqd:assessmentMethods ?assessmentMethods .
      FILTER()
      }"
    return sparqlx:run($query)
}; :)

declare function query:get-assessment-methods-for-inspireid() as xs:string {
    let $query := query:get-assessment-methods-for-inspireid-query()
    return sparqlx:run($query)
};

declare function query:get-assessment-methods-for-inspireid-query() as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
  PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
  PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
  
  SELECT ?assessmentRegime ?inspireId ?localId ?inspireLabel ?assessmentMethods
  WHERE {
        ?assessmentRegime a aqd:AQD_AssessmentRegime ;
        aqd:inspireId ?inspireId .
        ?inspireId rdfs:label ?inspireLabel .
        ?inspireId aqd:localId ?localId .
        ?assessmentRegime aqd:assessmentMethods ?assessmentMethods .
        FILTER()
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

(: declare function query:getSamplingPointFromFiles($url as xs:string*) as xs:string {
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
}; :)

declare function query:getSamplingPointFromFiles($url as xs:string*) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
  PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
  
  SELECT ?samplingPoint ?inspireLabel
  WHERE {
    BIND (IRI(CONCAT(STR('" || $url || "'), '/rdf')) AS ?g)
    GRAPH ?g {
      ?s cr:xmlSchema <http://dd.eionet.europa.eu/schemas/id2011850eu-1.0/AirQualityReporting.xsd> .
    }
    GRAPH ?s {
      ?samplingPoint a aqd:AQD_SamplingPoint .
      ?samplingPoint aqd:inspireId ?inspireId .
      ?inspireId rdfs:label ?inspireLabel .
      ?inspireId aqd:localId ?localId .
      ?inspireId aqd:namespace ?namespace .  
    }
  }"
};

(:declare function query:getModelSampling($url as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

   SELECT ?samplingPoint ?inspireLabel
   WHERE {
         ?samplingPoint a aqd:AQD_Model;
         aqd:inspireId ?inspireId .
         ?inspireId rdfs:label ?inspireLabel .
         ?inspireId aqd:localId ?localId .
         ?inspireId aqd:namespace ?namespace .
   FILTER(CONTAINS(str(?samplingPoint), '" || $url || "'))
   }"
};:)

declare function query:getModelSampling($url as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
   PREFIX dcterms: <http://purl.org/dc/terms/>
   PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

   SELECT ?samplingPoint ?inspireLabel
   WHERE {
       FILTER (STRSTARTS(STR(?graph), 'http://"||  $url ||"'))
       GRAPH ?graph {
         ?samplingPoint a aqd:AQD_Model;
         aqd:inspireId ?inspireId .
         ?inspireId rdfs:label ?inspireLabel .
         ?inspireId aqd:localId ?localId .
         ?inspireId aqd:namespace ?namespace .
       }
   }"
};

(:
declare function query:getModelSampling2($url as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

   SELECT ?inspireLabel
   WHERE {
         ?samplingPoint a aqd:AQD_Model;
         aqd:inspireId ?inspireId .
         ?inspireId rdfs:label ?inspireLabel .
         ?inspireId aqd:localId ?localId .
         ?inspireId aqd:namespace ?namespace .
   FILTER(CONTAINS(str(?samplingPoint), '" || $url || "'))
   }"
};:)

declare function query:getModelSampling2($url as xs:string) as xs:string {
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
  PREFIX dcterms: <http://purl.org/dc/terms/>
  PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

  SELECT DISTINCT
    ?inspireLabel

    WHERE {
      values ?envelope { <" || $url || "> }
      ?graph dcterms:isPartOf ?envelope .
      ?graph contreg:xmlSchema ?xmlSchema .
      
      GRAPH ?graph {
            ?samplingPoint a aqd:AQD_Model;
            aqd:inspireId ?inspireId .
            ?inspireId rdfs:label ?inspireLabel .
            ?inspireId aqd:localId ?localId .
            ?inspireId aqd:namespace ?namespace .
        }
    }  "
};

declare function query:getAllYear($url as xs:string) as xs:string {

 "PREFIX aqd: <http://rod.eionet.europa.eu/schema.rdf#>
SELECT DISTINCT SUBSTR(?period, 1, 4)
   WHERE {
        ?envelope a aqd:Delivery ;
        aqd:released ?date ;
        aqd:hasFile ?file ;
        aqd:period ?period
        FILTER(CONTAINS(str(?envelope), '" || $url ||"'))
  } order by desc(?period)"
};


(:declare function query:getModelMetadataSampling($url as xs:string*) as xs:string {
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
         ?observingCapability aqd:observedProperty ?observedProperty . 
         FILTER(CONTAINS(str(?samplingPoint), '" || $url || "'))
   }"
};:)

declare function query:getModelMetadataSampling($url as xs:string*) as xs:string {

  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
   PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
   PREFIX dcterms: <http://purl.org/dc/terms/>
   PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

  SELECT 
    ?localId ?featureOfInterest ?procedure ?observedProperty ?inspireLabel

  WHERE {

       FILTER (STRSTARTS(STR(?graph), 'http://"|| $url ||"'))
    GRAPH ?graph {
      ?samplingPoint a aqd:AQD_Model;
      aqd:observingCapability ?observingCapability;
      aqd:inspireId ?inspireId .
      ?inspireId rdfs:label ?inspireLabel .
      ?inspireId aqd:localId ?localId .
      ?inspireId aqd:namespace ?namespace .
          
    }  
         
    ?observingCapability aqd:featureOfInterest ?featureOfInterest .
    ?observingCapability aqd:procedure ?procedure .
    ?observingCapability aqd:observedProperty ?observedProperty .      
       
  }"
};

(:declare function query:getModelFromFiles($url as xs:string*) as xs:string {
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
};:)

declare function query:getModelFromFiles($url as xs:string*) as xs:string {
  let $filters :=
    for $x in $url
    return "<" || $x || ">"
  let $filters := string-join($filters, "  ")
  return
   "
  PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
  PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
  PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
  PREFIX dcterms: <http://purl.org/dc/terms/>
  PREFIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

  SELECT DISTINCT
    ?samplingPoint ?inspireLabel
  WHERE {
    values ?envelope { " || $filters || " }
    ?graph dcterms:isPartOf ?envelope .
    ?graph contreg:xmlSchema ?xmlSchema .
  
    GRAPH ?graph {
      ?samplingPoint a aqd:AQD_Model;
          aqd:inspireId ?inspireId .
          ?inspireId rdfs:label ?inspireLabel .
          ?inspireId aqd:localId ?localId .
          ?inspireId aqd:namespace ?namespace . 
            
    }      
  }"
};

(:declare function query:getSamplingPointMetadataFromFiles($url as xs:string*) as xs:string {
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
};:)

declare function query:getSamplingPointMetadataFromFiles($url as xs:string*) as xs:string {
  let $filters :=
    for $x in $url
    return "<" || $x || ">"
  let $filters := string-join($filters, "  ")
  return
   "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
    PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
    PREFIX dcterms: <http://purl.org/dc/terms/>
    PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

    SELECT DISTINCT
        ?localId ?featureOfInterest ?procedure ?observedProperty ?inspireLabel

      WHERE {
        values ?envelope { " || $filters || " } 
        ?graph dcterms:isPartOf ?envelope .
        ?graph contreg:xmlSchema ?xmlSchema .
        
        GRAPH ?graph {
          ?samplingPoint a aqd:AQD_SamplingPoint;
              aqd:observingCapability ?observingCapability;
              aqd:inspireId ?inspireId .
              ?inspireId rdfs:label ?inspireLabel .
              ?inspireId aqd:localId ?localId .
              ?inspireId aqd:namespace ?namespace .
              
                
        }      
            ?observingCapability aqd:featureOfInterest ?featureOfInterest .
            ?observingCapability aqd:procedure ?procedure .
            ?observingCapability aqd:observedProperty ?observedProperty .
      }"
};


declare function query:getSamplingPointMetadataFromFiles($url as xs:string*, $pollutant as xs:string*) as xs:string {
  let $filters :=
    for $x in $url
    return "<" || $x || ">"
  let $filters := string-join($filters, "  ")
  return
   "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
    PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>
    PREFIX dcterms: <http://purl.org/dc/terms/>
    PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

    SELECT DISTINCT
        ?localId ?featureOfInterest ?procedure ?observedProperty ?inspireLabel

      WHERE {
        values ?envelope { " || $filters || " } 
        ?graph dcterms:isPartOf ?envelope .
        ?graph contreg:xmlSchema ?xmlSchema .
        
        GRAPH ?graph {
          ?samplingPoint a aqd:AQD_SamplingPoint;
              aqd:observingCapability ?observingCapability;
              aqd:inspireId ?inspireId .
              ?inspireId rdfs:label ?inspireLabel .
              ?inspireId aqd:localId ?localId .
              ?inspireId aqd:namespace ?namespace .
              
                
        }      
            ?observingCapability aqd:featureOfInterest ?featureOfInterest .
            ?observingCapability aqd:procedure ?procedure .
            ?observingCapability aqd:observedProperty ?observedProperty .
         FILTER(?observedProperty in (" ||  $pollutant ||"))
      }"
};

declare function query:getModelMetadataFromFiles($url as xs:string*) as xs:string {
  let $filters :=
    for $x in $url
    return "<" || $x || ">"
  let $filters := string-join($filters, "  ")
  return
    "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>

SELECT DISTINCT
?localId 
?featureOfInterest 
?procedure 
?observedProperty 
?inspireLabel
WHERE {
  VALUES ?envelope { " || $filters || " }
  ?envelope rod:hasFile ?file .
  ?file cr:xmlSchema ?xmlSchema .
  GRAPH ?file {
    ?samplingPoint a aqd:AQD_Model .
    ?samplingPoint aqd:observingCapability ?observingCapability .
    ?samplingPoint aqd:inspireId ?inspireId .
  }
  ?inspireId rdfs:label ?inspireLabel .
  ?inspireId aqd:localId ?localId .
  ?inspireId aqd:namespace ?namespace .
  ?observingCapability aqd:featureOfInterest ?featureOfInterest .
  ?observingCapability aqd:procedure ?procedure .
  ?observingCapability aqd:observedProperty ?observedProperty .
}"
};

(:declare function query:getModelMetadataFromFiles($url as xs:string*) as xs:string {
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
};:)
(:
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

   FILTER (year(?released) >  2014) .
   } ORDER BY ?countryCode ?ReportingYear ?obligation_nr"
};:)
declare function query:getObligationYears() {
  "PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX dct: <http://purl.org/dc/terms/>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>

SELECT DISTINCT 
?obligation 
?obligation_nr 
?deadline 

bif:either(xsd:int(?obligation_nr) < 680 or xsd:int(?obligation_nr) = 742,(year(?deadline) - 2),bif:either(xsd:int(?obligation_nr) < 690,(year(?deadline) - 2),(year(?deadline))) ) as ?minimum
bif:either(xsd:int(?obligation_nr) < 680 or xsd:int(?obligation_nr) = 742,(year(?deadline) - 1),bif:either(xsd:int(?obligation_nr) < 690,(year(?deadline) - 1),(year(?deadline)+1)) ) as ?maximum

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

} ORDER BY ?countryCode ?ReportingYear ?obligation_nr"
};

declare function query:getObligationYearsObligations($obligation) {
  "PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX dct: <http://purl.org/dc/terms/>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>

SELECT DISTINCT 
?obligation 
?obligation_nr 
?deadline 

bif:either(xsd:int(?obligation_nr) < 680 or xsd:int(?obligation_nr) = 742,(year(?deadline) - 2),bif:either(xsd:int(?obligation_nr) < 690,(year(?deadline) - 2),(year(?deadline))) ) as ?minimum
bif:either(xsd:int(?obligation_nr) < 680 or xsd:int(?obligation_nr) = 742,(year(?deadline) - 1),bif:either(xsd:int(?obligation_nr) < 690,(year(?deadline) - 1),(year(?deadline)+1)) ) as ?maximum

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

FILTER (?obligation_nr = '" || $obligation ||"')

} ORDER BY ?countryCode ?ReportingYear ?obligation_nr"
};
(:
declare function query:getObligationYearsByEnvelope($url as xs:string) {
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

   FILTER (year(?released) >  2014) 
   FILTER(CONTAINS(str(?samplingPoint), '" || $url || "')).
   } ORDER BY ?countryCode ?ReportingYear ?obligation_nr"
};
:)
declare function query:getObligationYearsByEnvelope($url as xs:string) {
    let $urlwhitoutHTTPS :=  if(fn:contains($url, "https:")) then 
                            fn:replace($url, "https:", "http:")
                            else $url
                            return 
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

   FILTER (year(?released) >  2014) 
   
   FILTER(CONTAINS(str(?delivery), '" || $urlwhitoutHTTPS || "')).
   
   } ORDER BY ?countryCode ?ReportingYear ?obligation_nr"
};

(:~ Returns the URIs for the aqd:modelUsed used for the given Attainment

/aqd:AQD_Attainment/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription
    /aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed
:)
(: declare function query:get-used-model-for-attainment(
    $uri as xs:string
) as item()* {

    let $query := "
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

SELECT ?model_used ?attainment ?source_apportionment
WHERE {
    ?aqd_attainment a aqd:AQD_Attainment .

    ?aqd_attainment aqd:declarationFor ?attainment .
    ?aqd_attainment aqd:exceedanceDescriptionFinal ?desc_final .
    ?desc_final aqd:exceedanceArea ?exceedance_area .
    ?exceedance_area aqd:modelUsed ?model_used .

    # only for development
    ?source_apportionment aqd:parentExceedanceSituation ?attainment .

    filter(contains(str(?attainment), '" || $uri || "'))
}
"
    let $res := sparqlx:run($query)
    return data($res//sparql:binding[@name='model_used']/sparql:uri)

(: http://environment.data.gov.uk/air-quality/so/GB_Attainment_4934 :)
}; :)

declare function query:get-used-model-for-attainment(
    $uri as xs:string
) as item()* {

    let $res := sparqlx:run(query:get-used-model-for-attainment-query($uri))
    return data($res//sparql:binding[@name='model_used']/sparql:uri)

(: http://environment.data.gov.uk/air-quality/so/GB_Attainment_4934 :)
};

declare function query:get-used-model-for-attainment-query(
    $uri as xs:string
) as item()* {

    "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
    
    SELECT ?model_used ?attainment ?source_apportionment
    WHERE {
        ?aqd_attainment a aqd:AQD_Attainment .
    
        ?aqd_attainment aqd:declarationFor ?attainment .
        ?aqd_attainment aqd:exceedanceDescriptionFinal ?desc_final .
        ?desc_final aqd:exceedanceArea ?exceedance_area .
        ?exceedance_area aqd:modelUsed ?model_used .
    
        # only for development
        ?source_apportionment aqd:parentExceedanceSituation ?attainment .
    
        filter(contains(str(?attainment), '" || $uri || "'))
    }"
};


declare function query:getAttainmentForExceedanceArea(
    $uri as xs:string,
    $objectName as xs:string,
    $objectlUsed as xs:string
) as item()* {
    (:let $query := "
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

SELECT ?attainment
WHERE {

?sourceApportionment a aq:AQD_SourceApportionment;
    aq:parentExceedanceSituation ?parentExceedanceSituation;
    aq:macroExceedanceSituation ?macroExceedanceSituation.
?macroExceedanceSituation aq:exceedanceArea ?exceedanceArea.
?exceedanceArea aq:" || $objectName || " ?modelUsed.

?attainment a aq:AQD_Attainment;
    aq:exceedanceDescriptionFinal ?exceedanceDescriptionFinal;
    aq:inspireId ?inspireId.
?inspireId rdfs:label ?label.
?exceedanceDescriptionFinal aq:exceedanceArea ?exceedanceAreaAttainment.
?exceedanceAreaAttainment aq:" || $objectName || " ?modelUsedAttainment.

FILTER(regex(?parentExceedanceSituation, ?label))
FILTER(?modelUsedAttainment = ?modelUsed)
FILTER(regex(?modelUsedAttainment, '" || $objectlUsed || "'))
FILTER(?label = '" || $uri || "')
}
"
    return data(sparqlx:run($query)//sparql:binding[@name='attainment']/sparql:uri) :)
    let $res := data(sparqlx:run(query:getAttainmentForExceedanceAreaQuery($uri,$objectName,$objectlUsed))//sparql:binding[@name='attainment']/sparql:uri)
    return $res
};

(:declare function query:getAttainmentForExceedanceAreaQuery(
    $uri as xs:string,
    $objectName as xs:string,
    $objectlUsed as xs:string
) as item()* {
"
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

SELECT ?attainment
WHERE {

?sourceApportionment a aq:AQD_SourceApportionment;
    aq:parentExceedanceSituation ?parentExceedanceSituation;
    aq:macroExceedanceSituation ?macroExceedanceSituation.
?macroExceedanceSituation aq:exceedanceArea ?exceedanceArea.
?exceedanceArea aq:" || $objectName || " ?modelUsed.

?attainment a aq:AQD_Attainment;
    aq:exceedanceDescriptionFinal ?exceedanceDescriptionFinal;
    aq:inspireId ?inspireId.
?inspireId rdfs:label ?label.
?exceedanceDescriptionFinal aq:exceedanceArea ?exceedanceAreaAttainment.
?exceedanceAreaAttainment aq:" || $objectName || " ?modelUsedAttainment.

FILTER(regex(?parentExceedanceSituation, ?label))
FILTER(?modelUsedAttainment = ?modelUsed)
FILTER(regex(?modelUsedAttainment, '" || $objectlUsed || "'))
FILTER(?label = '" || $uri || "')
}
"
};:)

declare function query:getAttainmentForExceedanceAreaQuery( (:changed by goititer 21/12/2020 Ref.#116742 :)
    $uri as xs:string,
    $objectName as xs:string,
    $objectlUsed as xs:string
) as item()* {
"
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX aq: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

SELECT 
?attainment
#?stationUsed
WHERE {
  GRAPH ?a {
    ?inspireId rdfs:label '" || $uri || "' 
    
  }
  GRAPH ?a {
    ?attainment a aq:AQD_Attainment .
    ?attainment aq:exceedanceDescriptionFinal ?exceedanceDescriptionFinal .
    ?attainment aq:inspireId ?inspireId .
    ?exceedanceDescriptionFinal aq:exceedanceArea ?exceedanceAreaAttainment.
    ?exceedanceAreaAttainment aq:stationUsed ?stationUsed.
  }

FILTER(regex(?stationUsed, '" ||$objectlUsed|| "'))

} 
      
"
};

declare function query:getLatestEnvelopesForObligation(
    $obligation as xs:string
) as item()* {
    let $query := "
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>
PREFIX obligation: <http://rod.eionet.europa.eu/obligations/>

SELECT DISTINCT
?envelope
WHERE {{
  SELECT DISTINCT
    ?Country
    YEAR(?startOfPeriod) as ?reportingYear
    max(?released) as ?released
  WHERE {
    ?envelope rod:released ?released .
    ?envelope rod:startOfPeriod ?startOfPeriod .
    ?envelope rod:obligation ?obligation .
    ?envelope rod:locality ?locality .
    FILTER (?obligation = obligation:" || $obligation || ")
    ?locality rod:localityName ?Country .
  } GROUP BY ?Country YEAR(?startOfPeriod)
}
?envelope rod:released ?released .
?envelope rdf:type rod:Delivery .
}
"
    return data(sparqlx:run($query)//sparql:binding[@name='envelope']/sparql:uri)
};


(:~ Returns the URIs for the aqd:stationUsed used for the given Attainment

/aqd:AQD_Attainment/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription
    /aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationUsed
:)
(: declare function query:get-used-station-for-attainment(
    $uri as xs:string
) as item()* {

    let $query := "
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

SELECT ?station_used ?attainment ?source_apportionment
WHERE {
    ?aqd_attainment a aqd:AQD_Attainment .

    ?aqd_attainment aqd:declarationFor ?attainment .
    ?aqd_attainment aqd:exceedanceDescriptionFinal ?desc_final .
    ?desc_final aqd:exceedanceArea ?exceedance_area .
    ?exceedance_area aqd:stationUsed ?station_used .

    # only for development
    ?source_apportionment aqd:parentExceedanceSituation ?attainment .

    filter(contains(str(?attainment), '" || $uri || "'))
}
"
    let $res := sparqlx:run($query)
    return data($res//sparql:binding[@name='station_used']/sparql:literal)

(: http://environment.data.gov.uk/air-quality/so/GB_Attainment_4934 :)
}; :)

declare function query:get-used-station-for-attainment(
    $uri as xs:string
) as item()* {

    let $res := sparqlx:run(query:get-used-station-for-attainment-query($uri))
    return data($res//sparql:binding[@name='station_used']/sparql:literal)

(: http://environment.data.gov.uk/air-quality/so/GB_Attainment_4934 :)
};

declare function query:get-used-station-for-attainment-query(
    $uri as xs:string
) as xs:string {

    "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
    
    SELECT ?station_used ?attainment ?source_apportionment
    WHERE {
        ?aqd_attainment a aqd:AQD_Attainment .
    
        ?aqd_attainment aqd:declarationFor ?attainment .
        ?aqd_attainment aqd:exceedanceDescriptionFinal ?desc_final .
        ?desc_final aqd:exceedanceArea ?exceedance_area .
        ?exceedance_area aqd:stationUsed ?station_used .
    
        # only for development
        ?source_apportionment aqd:parentExceedanceSituation ?attainment .
    
        filter(contains(str(?attainment), '" || $uri || "'))
    }"
};

declare function query:getSamplingNetworkLatAndLong($cdrUrl as xs:string) as xs:string {

    "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
PREFIX dcterms: <http://purl.org/dc/terms/>
PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREfIX geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>

SELECT DISTINCT ?lat ?long ?broader ?inspireLabel ?localId
  WHERE {
   
    values ?envelope {<"||$cdrUrl||">}
    ?graph dcterms:isPartOf ?envelope .
    ?graph contreg:xmlSchema ?xmlSchema .
      GRAPH ?graph {
      ?samplingPoint a aqd:AQD_SamplingPoint .
      ?samplingPoint aqd:inspireId ?inspireId .
      ?samplingPoint geo:lat ?lat.
      ?samplingPoint geo:long ?long.
      ?samplingPoint aqd:broader ?broader
      }
    ?inspireId rdfs:label ?inspireLabel .
    ?inspireId aqd:localId ?localId .
    ?inspireId aqd:namespace ?namespace .
}"
};

(:~ Returns the areaClassification for a given attainment

/aqd:AQD_Attainment/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/
    aqd:exceedanceArea/aqd:ExceedanceArea/aqd:areaClassification
:)
declare function query:get-area-classifications-for-attainment(
    $uri as xs:string?
) as element()* {

    (:let $query := "
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

SELECT DISTINCT ?aqd_attainment, ?areaClassification
WHERE {
    ?aqd_attainment a aqd:AQD_Attainment .
    ?aqd_attainment aqd:inspireId ?inspireId.
    ?aqd_attainment aqd:exceedanceDescriptionFinal ?exceedanceDescriptionFinal .
    ?inspireId rdfs:label ?label.
    ?exceedanceDescriptionFinal aqd:exceedanceArea ?exceedanceArea .
    ?exceedanceArea aqd:areaClassification ?areaClassification .
    FILTER(?label = '" || $uri || "')
}"
    let $res := sparqlx:run($query) :)
    let $res := sparqlx:run(query:get-area-classifications-for-attainment-query($uri))
    return $res
};

declare function query:get-area-classifications-for-attainment-query($uri as xs:string?) as xs:string {
    "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
    
    SELECT DISTINCT ?aqd_attainment, ?areaClassification
    WHERE {
        ?aqd_attainment a aqd:AQD_Attainment .
        ?aqd_attainment aqd:inspireId ?inspireId.
        ?aqd_attainment aqd:exceedanceDescriptionFinal ?exceedanceDescriptionFinal .
        ?inspireId rdfs:label ?label.
        ?exceedanceDescriptionFinal aqd:exceedanceArea ?exceedanceArea .
        ?exceedanceArea aqd:areaClassification ?areaClassification .
        FILTER(?label = '" || $uri || "')
    }"
};


declare function query:getNowTime(){
  let $query := "select ?time
    where { 
  bind( now() as ?time)
}"
    let $res := sparqlx:run($query)
    return data($res//sparql:binding[@name='time']/sparql:literal)
};






