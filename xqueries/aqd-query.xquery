xquery version "3.0";

(:~
: User: dev-gso
: Date: 6/21/2016
: Time: 6:37 PM
: To change this template use File | Settings | File Templates.
:)

module namespace query = "aqd-query";

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
