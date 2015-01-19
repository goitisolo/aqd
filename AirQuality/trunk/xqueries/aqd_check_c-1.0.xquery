xquery version "1.0" encoding "UTF-8";
(:
 : Module Name: Implementing Decision 2011/850/EU: AQ info exchange & reporting (Library module)
 :
 : Version:     $Id$
 : Created:     13 September 2013
 : Copyright:   European Environment Agency
 :)
(:~
 : XQuery script implements dataflow C tier-1 checks as documented in http://taskman.eionet.europa.eu/documents/3 .
 :
 : @author Enriko Käsper
 :)

module namespace xmlconv = "http://converters.eionet.europa.eu/dataflowC";

declare namespace aqd = "http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0";
declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace am = "http://inspire.ec.europa.eu/schemas/am/3.0";
declare namespace ef = "http://inspire.ec.europa.eu/schemas/ef/3.0";
declare namespace base = "http://inspire.ec.europa.eu/schemas/base/3.3";
declare namespace gn = "urn:x-inspire:specification:gmlas:GeographicalNames:3.0";
declare namespace base2 = "http://inspire.ec.europa.eu/schemas/base2/1.0";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace xlink = "http://www.w3.org/1999/xlink";

(:~ declare Content Registry SPARQL endpoint:)
declare variable $xmlconv:CR_SPARQL_URL := "http://cr.eionet.europa.eu/sparql";

declare variable $xmlconv:ISO2_CODES as xs:string* := ("AL","AT","BA","BE","BG","CH","CY","CZ","DE","DK","DZ","EE","EG","ES","FI",
    "FR","GB","GR","HR","HU","IE","IL","IS","IT","JO","LB","LI","LT","LU","LV","MA","ME","MK","MT","NL","NO","PL","PS","PT",
     "RO","RS","SE","SI","SK","TN","TR","XK","UK");
(:===================================================================:)
(: Variable given as an external parameter by the QA service                                                 :)
(:===================================================================:)

declare variable $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C11 as xs:string* := ("aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV aqd:reportingMetric xlink:href attribute  shall  resolve  to  one  of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove-3yr aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H","or",
"aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LTO aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/daysAbove aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H","or","or
aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV
aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AOT40c-5yr aqd:protectionTarget
xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V","or","aqd:objectiveType xlink:href attribute shall resolve to one of
http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LTO
aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AOT40c
aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V");

declare variable $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C10 as xs:string* := ("aqd:objectiveType xlink:href attribute shall resolve to one of
http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV aqd:reportingMetric
xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove
aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H",
"or","aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV
aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/daysAbove
aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H",
"or","aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL
aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean
aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V",
"or","aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL
aqd:reportingMetric xlink:href attribute shall resolve to one of
http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/wMean aqd:protectionTarget
xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V");

declare variable $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C12 as xs:string* := ("aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objective
type/LV aqd:reportingMetric
xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hoursAbove
aqd:protectionTarget
xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H","or","
http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV
aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/a
Mean aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H");

declare variable $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C13 as xs:string* := ("aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V");

declare variable $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C14 as xs:string* := ("aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV
aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove
aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H",
"or","
http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV
aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean
aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H");

declare variable $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C15 as xs:string* := ("aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ECO
aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AEI
aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H",
"or"," http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H");

declare variable $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C16 as xs:string* := ("http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/daysAbove aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H");
declare variable $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C17 as xs:string* := ("http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H");




declare variable $xmlconv:VALID_POLLUTANT_IDS as xs:string* := ("1", "7", "8", "9", "5", "6001", "10","20", "5012", "5014", "5015", "5018", "5029");

declare variable $xmlconv:VALID_POLLUTANT_IDS_18 as xs:string* := ("5014", "5015", "5018", "5029");

declare variable $xmlconv:VALID_POLLUTANT_IDS_8  as xs:string* := ("1","7","8","9","5","6001","10","20","5012","5014","5015","5018","5029");

declare variable $xmlconv:VALID_POLLUTANT_IDS_9  as xs:string* := ("1045","1046","1047","1771","1772","1629","1659","1657","1668","1631","2012","2014","2015","2018","7013","4013","4813","653","5013","5610","5617",
"5759","5626","5655","5763","7029","611","618","760","627","656","7419","20","428","430","432","503","505","394","447","6005","6006","6007","24","486","316","6008","6009",
"451","443","316","441","475","449","21","431","464","482","6011","6012","32","25");

declare variable $xmlconv:VALID_POLLUTANT_IDS_19  as xs:string* := ("1045","1046","1047","1771","1772","1629","1659","1657","1668","1631","2012","2014","2015","2018","7013","4013","4813","653","5013","5610","5617",
"5759","5626","5655","5763","7029","611","618","760","627","656","7419","20","428","430","432","503","505","394","447","6005","6006","6007","24","486","316","6008","6009","451","443","441","475","449","21","431","464",
"482","6011","6012","32","25");

declare variable $xmlconv:VALID_POLLUTANT_IDS_27 as xs:string* := ('1045','1046','1047','1771','1772','1629','1659','1657','1668','1631','2012','2014','2015','2018','7013','4013','4813','653','5013','5610','5617',
'5759','5626','5655','5763','7029','611','618','760','627','656','7419','20','428','430','432','503','505','394','447','6005','6006','6007','24','486','316','6008','6009',
'451','443','316','441','475','449','21','431','464','482','6011','6012','32','25','6001');

declare variable $xmlconv:VALID_POLLUTANT_IDS_40 as xs:string* := ('1045','1046','1047','1771','1772','1629','1659','1657','1668','1631','2012','2014','2015','2018','7013','4013','4813','653','5013','5610','5617',
'5759','5626','5655','5763','7029','611','618','760','627','656','7419','20','428','430','432','503','505','394','447','6005','6006','6007','24','486','316','6008','6009',
'451','443','316','441','475','449','21','431','464','482','6011','6012','32','25');

declare variable $xmlconv:VALID_POLLUTANT_IDS_21 as xs:string* := ("1","8","9","10","5","6001","5014","5018","5015","5029","5012","20");

declare variable $xmlconv:POLLUTANT_VOCABULARY as xs:string := "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/";

(:
declare variable $source_url as xs:string external;
:)
(:
declare variable $source_url := "../test/C_GB_AssessmentRegime.xml";
declare variable $source_url as xs:untypedAtomic external;
Change it for testing locally:
declare variable $source_url as xs:string external;
declare variable $source_url := "http://cdr.eionet.europa.eu/gb/eu/aqd/e2a/colutn32a/envubnpvw/B_GB_Zones.xml";
:)

(: removes the file part from the end of URL and appends 'xml' for getting the envelope xml description :)
declare function xmlconv:getEnvelopeXML($url as xs:string) as xs:string{

        let $col := fn:tokenize($url,'/')
        let $col := fn:remove($col, fn:count($col))
        let $ret := fn:string-join($col,'/')
        let $ret := fn:concat($ret,'/xml')
        return
            if(fn:doc-available($ret)) then
                $ret
            else
                (:)    "http://cdr.eionet.europa.eu/fr/eu/aqd/b/":)
   "http://cdrtest.eionet.europa.eu/ee/eu/art17/envriytkg/xml"
}
;


(:~
: JavaScript
:)
declare function xmlconv:javaScript(){

    let $js :=
           <script type="text/javascript">
               <![CDATA[
    function toggle(divName, linkName, checkId) {{
         toggleItem(divName, linkName, checkId, 'record');
    }}

   function toggleItem(divName, linkName, checkId, itemLabel) {{
        divName = divName + "-" + checkId;
        linkName = linkName + "-" + checkId;

        var elem = document.getElementById(divName);
        var text = document.getElementById(linkName);
        if(elem.style.display == "inline") {{
            elem.style.display = "none";
            text.innerHTML = "Show " + itemLabel + "s";
            }}
            else {{
              elem.style.display = "inline";
              text.innerHTML = "Hide " + itemLabel + "s";
            }}
      }}

      function toggleComb(divName, linkName, checkId, itemLabel) {{
        divName = divName + "-" + checkId;
        linkName = linkName + "-" + checkId;

        var elem = document.getElementById(divName);
        var text = document.getElementById(linkName);
        if(elem.style.display == "inline") {{
            elem.style.display = "none";
            text.innerHTML = "Show " + itemLabel + "s";
            }}
            else {{
              elem.style.display = "inline";
              text.innerHTML = "Hide " + itemLabel + "s";
            }}
      }}

                ]]>
           </script>
    return
        <script type="text/javascript">{normalize-space($js)}</script>
};

declare function xmlconv:getErrorTD($errValue,  $element as xs:string, $showMissing as xs:boolean)
as element(td)
{
    let $val := if ($showMissing and string-length($errValue)=0) then "-blank-" else $errValue
    return
        <td title="{ $element }" style="color:red">{
            $val
        }
        </td>
};

(:
 : ======================================================================
 :              SPARQL HELPER methods
 : ======================================================================
 :)
(:~ Function executes given SPARQL query and returns result elements in SPARQL result format.
 : URL parameters will be correctly encoded.
 : @param $sparql SPARQL query.
 : @return sparql:results element containing zero or more sparql:result subelements in SPARQL result format.
 :)
declare function xmlconv:executeSparqlQuery($sparql as xs:string)
as element(sparql:results)
{
    let $uri := xmlconv:getSparqlEndpointUrl($sparql, "xml")

    return
        fn:doc($uri)//sparql:results
};


(:~
 : Get the SPARQL endpoint URL.
 : @param $sparql SPARQL query.
 : @param $format xml or html.
 : @param $inference use inference when executing sparql query.
 : @return link to sparql endpoint
 :)
declare function xmlconv:getSparqlEndpointUrl($sparql as xs:string, $format as xs:string)
as xs:string
{
    let $sparql := fn:encode-for-uri(fn:normalize-space($sparql))
    let $resultFormat :=
        if ($format = "xml") then
            "application/xml"
        else if ($format = "html") then
            "text/html"
        else
            $format
    let $defaultGraph := ""
    let $uriParams := concat("query=", $sparql, "&amp;format=", $resultFormat, $defaultGraph)
    let $uri := concat($xmlconv:CR_SPARQL_URL, "?", $uriParams)
    return $uri
};
declare function xmlconv:getAqdusedAQD($countryCode as xs:string)
as xs:string
{concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

SELECT ?zone ?usedAQD ?inspireId ?inspireLabel
WHERE {
?zone a aqd:AQD_SamplingPoint ;
aqd:inspireId ?inspireId .
?inspireId rdfs:label ?inspireLabel .
?zone aqd:usedAQD ?usedAQD .
FILTER (STRSTARTS(str(?zone), 'http://cdr.eionet.europa.eu/",$countryCode,"/eu/aqd/d/')and xsd:boolean(?usedAQD))
}")
};

declare function xmlconv:getProtectionTarget($countryCode as xs:string)
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
         FILTER (STRSTARTS(str(?zone), 'http://cdr.eionet.europa.eu/",$countryCode,"/eu/aqd/b/'))
} ")
};

declare function xmlconv:getSamplingPointInspireLabel($countryCode as xs:string)
as xs:string

{concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
         PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
         PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

SELECT ?zone ?inspireId ?inspireLabel ?relevantEmissions ?stationClassification
  WHERE {
         ?zone a aqd:AQD_SamplingPoint ;
          aqd:inspireId ?inspireId .
         ?inspireId rdfs:label ?inspireLabel .
         ?zone aqd:relevantEmissions ?relevantEmissions .
         ?relevantEmissions aqd:stationClassification ?stationClassification
  FILTER (STRSTARTS(str(?zone), 'http://cdr.eionet.europa.eu/", $countryCode,"/eu/aqd/d/') and str(?stationClassification)!='http://dd.eionet.europa.eu/vocabulary/aq/stationclassification/background')
  }")
};

declare function xmlconv:getPollutantCode($countryCode as xs:string)
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
         FILTER (STRSTARTS(str(?zone), 'http://cdr.eionet.europa.eu/",$countryCode,"/eu/aqd/b/'))
} ")
};

declare function xmlconv:getAqdModelID($countryCode as xs:string)
as xs:string
{
   concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

       SELECT ?zone ?inspireId ?inspireLabel
         WHERE {
              ?zone a aqd:AQD_Model;
              aqd:inspireId ?inspireId .
              ?inspireId rdfs:label ?inspireLabel .
         FILTER (STRSTARTS(str(?zone), 'http://cdr.eionet.europa.eu/",$countryCode,"/eu/aqd/d/'))
}")
};

declare function xmlconv:getModelEndPosition ($countryCode as xs:string)
as xs:string
{
concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

    SELECT ?zone ?inspireId ?inspireLabel ?endPosition
    WHERE {
        ?zone a aqd:AQD_Model ;
        aqd:inspireId ?inspireId .
        ?inspireId rdfs:label ?inspireLabel .
        ?zone aqd:observingCapability ?observingCapability .
        ?observingCapability aqd:observingTime ?observingTime .
        ?observingTime aqd:beginPosition ?endPosition
    FILTER (STRSTARTS(str(?zone), 'http://cdr.eionet.europa.eu/",$countryCode,"/eu/aqd/d/'))
}")
};

declare function xmlconv:getSamplingPointEndPosition ($countryCode as xs:string)
as xs:string
{
concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

    SELECT ?zone ?inspireId ?inspireLabel ?endPosition
    WHERE {
        ?zone a aqd:AQD_SamplingPoint ;
        aqd:inspireId ?inspireId .
        ?inspireId rdfs:label ?inspireLabel .
        ?zone aqd:observingCapability ?observingCapability .
        ?observingCapability aqd:observingTime ?observingTime .
        ?observingTime aqd:beginPosition ?endPosition
    FILTER (STRSTARTS(str(?zone), 'http://cdr.eionet.europa.eu/",$countryCode,"/eu/aqd/d/'))
}")
};

declare function xmlconv:getAssessmentTypeModel($countryCode as xs:string)
as xs:string
{concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
         PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
         PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

    SELECT ?zone ?inspireId ?inspireLabel ?assessmentType
        WHERE {
         ?zone a aqd:AQD_Model ;
         aqd:inspireId ?inspireId .
         ?inspireId rdfs:label ?inspireLabel .
         ?zone aqd:assessmentType ?assessmentType
       FILTER (STRSTARTS(str(?zone), 'http://cdr.eionet.europa.eu/",$countryCode,"/eu/aqd/d/'))
   }")
};

declare function xmlconv:getAssessmentType($countryCode as xs:string)
as xs:string
{concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
         PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
         PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

    SELECT ?zone ?inspireId ?inspireLabel ?assessmentType
        WHERE {
         ?zone a aqd:AQD_SamplingPoint ;
         aqd:inspireId ?inspireId .
         ?inspireId rdfs:label ?inspireLabel .
         ?zone aqd:assessmentType ?assessmentType
       FILTER (STRSTARTS(str(?zone), 'http://cdr.eionet.europa.eu/",$countryCode,"/eu/aqd/d/'))
   }")
};

declare function xmlconv:getInspireLabelD($countryCode as xs:string)
as xs:string
{
concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
    PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

    SELECT ?zone ?inspireId ?inspireLabel
      WHERE {
          ?zone a aqd:AQD_SamplingPoint ;
          aqd:inspireId ?inspireId .
          ?inspireId rdfs:label ?inspireLabel .
      FILTER (STRSTARTS(str(?zone), 'http://cdr.eionet.europa.eu/", $countryCode, "/eu/aqd/d/'))
}")
};

declare function xmlconv:getInspireId($countryCode as xs:string)
as xs:string
{
concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

  SELECT ?zone ?inspireId ?inspireLabel
   WHERE {
        ?zone a aqd:AQD_Zone ;
        aqd:inspireId ?inspireId .
        ?inspireId rdfs:label ?inspireLabel .
   FILTER (STRSTARTS(str(?zone), 'http://cdr.eionet.europa.eu/", $countryCode, "/eu/aqd/b/'))
  }")
};

declare function xmlconv:getPollutantCodeAndProtectionTarge($countryCode as xs:string)
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
      FILTER (STRSTARTS(str(?zone), 'http://cdr.eionet.europa.eu/", $countryCode, "/eu/aqd/b/'))
    }")
};


declare function xmlconv:getBullet($text as xs:string, $level as xs:string)
as element(div) {

    let $color :=
        if ($level = "error") then
            "red"
        else if ($level = "warning") then
            "orange"
        else if ($level = "skipped") then
            "gray"
        else
            "deepskyblue"


return
    <div class="{$level}" style="background-color: { $color }; font-size: 0.8em; color: white; padding-left:5px;padding-right:5px;margin-right:5px;margin-top:2px;text-align:center">{ $text }</div>
};

declare function xmlconv:checkLink($text as xs:string*)
as element(span)*{
    for $c at $pos in $text
    return
        <span>{
            if (starts-with($c, "http://")) then <a href="{$c}">{$c}</a> else $c
        }{  if ($pos < count($text)) then ", " else ""
        }</span>

}
;

(:
    Builds HTML table rows for rules.
:)
declare function xmlconv:buildResultRows($ruleCode as xs:string, $text, $invalidStrValues as xs:string*, $invalidValues as element()*,
    $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $recordDetails as element(tr)*)
as element(tr)*{
    let $countInvalidValues := count($invalidStrValues) + count($invalidValues)

    let $recordDetails := if (count($invalidValues) > 0) then $invalidValues else $recordDetails

    let $bulletType := if (string-length($skippedMsg) > 0) then "skipped" else if ($countInvalidValues = 0) then "info" else "error"
let $result :=
    (
        <tr style="border-top:1px solid #666666;">
            <td style="padding-top:3px;vertical-align:top;">{ xmlconv:getBullet($ruleCode, $bulletType) }</td>
            <th style="padding-top:3px;vertical-align:top;text-align:left;">{ $text }</th>
            <td style="padding-top:3px;vertical-align:top;"><span style="font-size:1.3em;">{
                if (string-length($skippedMsg) > 0) then
                    $skippedMsg
                else if ($countInvalidValues = 0) then
                    $validMsg
                else
                    concat($countInvalidValues, $invalidMsg, substring("s ", number(not($countInvalidValues > 1)) * 2) ,"found") }
                </span>{
                if ($countInvalidValues > 0 or count($recordDetails)>0) then
                    <a id='feedbackLink-{$ruleCode}' href='javascript:toggle("feedbackRow","feedbackLink", "{$ruleCode}")' style="padding-left:10px;">Show records</a>
                else
                    ()
                }
             </td>
             <td></td>
        </tr>,
            if (count($recordDetails)>0) then
                <tr>
                    <td></td>
                    <td colspan="3">
                        <table class="datatable" style="font-size: 0.9em;text-align:left;vertical-align:top;display:none;border:0px;" id="feedbackRow-{$ruleCode}">
                            <tr>{
                                for $th in $recordDetails[1]//td return <th>{ data($th/@title) }</th>
                            }</tr>
                            {$recordDetails}
                        </table>
                    </td>
                </tr>
            else if (count($invalidStrValues)  > 0) then
                <tr>
                    <td></td>
                    <td colspan="3">
                        <table style="display:none;margin-top:1em;" id="feedbackRow-{$ruleCode}">
                            <tr style="font-size: 0.9em;color:#666666;">
                                <td></td>
                                <th colspan="3" style="text-align:right;vertical-align:top;background-color:#F6F6F6;font-weight: bold;">{ $valueHeading}</th>
                                <td style="font-style:italic;vertical-align:top;">{ string-join($invalidStrValues, ", ")}</td>
                            </tr>
                        </table>
                    </td>
                </tr>

            else
                ()
    )
return $result

};


(:
    Rule implementations
:)
declare function xmlconv:checkReport($source_url as xs:string, $countryCode as xs:string)
as element(table) {

let $envelopeUrl := xmlconv:getEnvelopeXML($source_url)

let $docRoot := doc($source_url)
(: C1 :)
let $countRegimes := count($docRoot//aqd:AQD_AssessmentRegime)
let $tblAllRegimes :=
    for $rec in $docRoot//aqd:AQD_AssessmentRegime
    return
        <tr>
            <td title="gml:id">{data($rec/@gml:id)}</td>
            <td title="base:localId">{data($rec/aqd:inspireId/base:Identifier/base:localId)}</td>
            <td title="base:namespace">{data($rec/aqd:inspireId/base:Identifier/base:namespace)}</td>
            <td title="aqd:zone">{xmlconv:checkLink(data($rec/aqd:zone/@xlink:href))}</td>
            <td title="aqd:pollutant">{xmlconv:checkLink(data($rec/aqd:pollutant/@xlink:href))}</td>
            <td title="aqd:protectionTarget">{xmlconv:checkLink(data($rec/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href))}</td>
        </tr>


(: C4 duplicate @gml:ids :)
let $gmlIds := $docRoot//aqd:AQD_AssessmentRegime/lower-case(normalize-space(@gml:id))
let $invalidDuplicateGmlIds :=
    for $id in $docRoot//aqd:AQD_AssessmentRegime/@gml:id
    where count(index-of($gmlIds, lower-case(normalize-space($id)))) > 1
    return
        $id

(: C5 duplicate ./aqd:inspireId/base:Identifier/base:localId :)
let $localIds := $docRoot//aqd:AQD_AssessmentRegime/aqd:inspireId/base:Identifier/lower-case(normalize-space(base:localId))
let $invalidDuplicateLocalIds :=
    for $id in $docRoot//aqd:inspireId/base:Identifier/base:localId
    where count(index-of($localIds, lower-case(normalize-space($id)))) > 1
    return
        $id

(: C6 :)
let $allBaseNamespace := distinct-values($docRoot//aqd:AQD_AssessmentRegime/aqd:inspireId/base:Identifier/base:namespace)
let  $tblC6 :=
    for $id in $allBaseNamespace
    let $localId := $docRoot//aqd:AQD_AssessmentRegime/aqd:inspireId/base:Identifier[base:namespace = $id]/base:localId
    return
        <tr>
            <td title="base:namespace">{$id}</td>
            <td title="base:localId">{count($localId)}</td>
        </tr>
(: C7 :)

let $invalidAssessmentRegim :=
    for $aqdAQD_AssessmentRegim in $docRoot//aqd:AQD_AssessmentRegime
    where $aqdAQD_AssessmentRegim[count(aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href)=0]
    return $aqdAQD_AssessmentRegim/@gml:id

(: C8 :)

let $invalidPollutantC8 :=
    for $aqdPollutantC8 in $docRoot//aqd:AQD_AssessmentRegime
    let $pollutantXlinkC8 := fn:substring-after(data($aqdPollutantC8/aqd:pollutant/@xlink:href),"pollutant/")
where empty(index-of(('1','7','8','9','5','6001','10','20','5012','5014','5015','5018','5029'),$pollutantXlinkC8))
return $aqdPollutantC8/@gml:id

(: C9 :)

let $invalidPollutantC9 :=
    for $aqdPollutantC9 in $docRoot//aqd:AQD_AssessmentRegime
    let $pollutantXlinkC9 := fn:substring-after(data($aqdPollutantC9/aqd:pollutant/@xlink:href),"pollutant/")
    where empty(index-of(('1045','1046','1047','1771','1772','1629','1659','1657','1668','1631','2012','2014','2015','2018','7013','4013','4813','653','5013','5610','5617',
    '5759','5626','5655','5763','7029','611','618','760','627','656','7419','20','428','430','432','503','505','394','447','6005','6006','6007','24','486','316','6008','6009',
    '451','443','316','441','475','449','21','431','464','482','6011','6012','32','25'),$pollutantXlinkC9))
    return $aqdPollutantC9/@gml:id

(: C10 :)

let $invalidAqdAssessmentRegimeAqdPollutant :=
    for $aqdPollutantC10 in  $docRoot//aqd:AQD_AssessmentRegime[count(aqd:pollutant)>0 and aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/1"]/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
    where (($aqdPollutantC10/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
           or ($aqdPollutantC10/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove")
           or ($aqdPollutantC10/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
      and
            (($aqdPollutantC10/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
                   or ($aqdPollutantC10/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove")
                   or ($aqdPollutantC10/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
      and
            (($aqdPollutantC10/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL")
                   or ($aqdPollutantC10/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
                   or ($aqdPollutantC10/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V"))
      and
            (($aqdPollutantC10/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL")
                   or ($aqdPollutantC10/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/wMean")
                   or ($aqdPollutantC10/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V"))
return $aqdPollutantC10/../../../../@gml:id

(: C11 :)

let $invalidAqdAssessmentRegimeAqdPollutantC11 :=
    for $aqdPollutantC11 in  $docRoot//aqd:AQD_AssessmentRegime[count(aqd:pollutant)>0 and aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/7"]/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
    where (($aqdPollutantC11/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV")
            or ($aqdPollutantC11/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove-3yr")
            or ($aqdPollutantC11/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
        and
            (($aqdPollutantC11/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LTO")
            or ($aqdPollutantC11/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove")
            or ($aqdPollutantC11/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
        and
           (($aqdPollutantC11/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV")
            or ($aqdPollutantC11/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AOT40c-5yr")
            or ($aqdPollutantC11/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V" ))
        and
           (($aqdPollutantC11/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LTO")
            or ($aqdPollutantC11/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AOT40c")
            or ($aqdPollutantC11/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V"))
    return $aqdPollutantC11/../../../../@gml:id

(: C12 :)

let $invalidAqdAssessmentRegimeAqdPollutantC12 :=
    for $aqdPollutantC12 in  $docRoot//aqd:AQD_AssessmentRegime[count(aqd:pollutant)>0 and aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/8"]/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
    where (($aqdPollutantC12/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
            or ($aqdPollutantC12/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hoursAbove")
            or ($aqdPollutantC12/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
       and
            (($aqdPollutantC12/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
                    or ($aqdPollutantC12/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
                    or ($aqdPollutantC12/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
    return $aqdPollutantC12/../../../../@gml:id

(: C13 :)

let $invalidAqdAssessmentRegimeAqdPollutantC13 :=
    for $aqdPollutantC13 in  $docRoot//aqd:AQD_AssessmentRegime[count(aqd:pollutant)>0 and aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/9"]/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
    where ($aqdPollutantC13/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL")
            or ($aqdPollutantC13/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
            or ($aqdPollutantC13/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V")
    return $aqdPollutantC13/../../../../@gml:id

(: C14 :)

let $invalidAqdAssessmentRegimeAqdPollutantC14 :=
    for $aqdPollutantC14 in  $docRoot//aqd:AQD_AssessmentRegime[count(aqd:pollutant)>0 and aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5"]/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
    where (($aqdPollutantC14/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
            or ($aqdPollutantC14/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove")
            or ($aqdPollutantC14/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
        and
            (($aqdPollutantC14/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
            or ($aqdPollutantC14/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
            or ($aqdPollutantC14/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
    return $aqdPollutantC14/../../../../@gml:id

(: C15 :)

let $invalidAqdAssessmentRegimeAqdPollutantC15 :=
    for $aqdPollutantC15 in  $docRoot//aqd:AQD_AssessmentRegime[count(aqd:pollutant)>0 and aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001"]/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
    where (($aqdPollutantC15/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ECO")
            or ($aqdPollutantC15/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AEI")
            or ($aqdPollutantC15/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
    and
            (($aqdPollutantC15/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
            or ($aqdPollutantC15/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
            or ($aqdPollutantC15/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
    return $aqdPollutantC15/../../../../@gml:id

    (: C16 :)

let $invalidAqdAssessmentRegimeAqdPollutantC16 :=
    for $aqdPollutantC16 in  $docRoot//aqd:AQD_AssessmentRegime[count(aqd:pollutant)>0 and aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/10"]/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
    where ($aqdPollutantC16/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
            or ($aqdPollutantC16/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove")
            or ($aqdPollutantC16/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
    return $aqdPollutantC16/../../../../@gml:id



(: C17 :)

let $invalidAqdAssessmentRegimeAqdPollutantC17 :=
    for $aqdPollutantC17 in  $docRoot//aqd:AQD_AssessmentRegime[count(aqd:pollutant)>0 and aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5012" or aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/20"]/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
     where ($aqdPollutantC17/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
        or ($aqdPollutantC17/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
        or  ($aqdPollutantC17/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
    return $aqdPollutantC17/../../../../@gml:id

(: C18 :)

let $invalidAqdAssessmentRegimeAqdPollutantC18 :=
    for $aqdPollutantC17 in  $docRoot//aqd:AQD_AssessmentRegime[count(aqd:pollutant)>0 and aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5014" or aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5018"
    or aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5015" or aqd:pollutant/@xlink:href="http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5029"]/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
    where ($aqdPollutantC17/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV")
            or ($aqdPollutantC17/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
            or  ($aqdPollutantC17/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
    return $aqdPollutantC17/../../../../@gml:id

(: 19 :)

let $invalidAqdAssessmentRegimeAqdPollutantC19 :=
    for $aqdPollutantC19 in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
    let $pollutantXlinkC19 := fn:substring-after(data($aqdPollutantC19/../../../../aqd:pollutant/@xlink:href),"pollutant/")
    where empty(index-of(('1045','1046','1047','1771','1772','1629','1659','1657','1668','1631','2012','2014','2015','2018','7013','4013','4813','653','5013','5610','5617',
    '5759','5626','5655','5763','7029','611','618','760','627','656','7419','20','428','430','432','503','505','394','447','6005','6006','6007','24','486','316','6008','6009',
    '451','443','316','441','475','449','21','431','464','482','6011','6012','32','25'),$pollutantXlinkC19))=false()
    return if (($aqdPollutantC19/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO")
    or ($aqdPollutantC19/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
    or  ($aqdPollutantC19/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/NA"))
    then $aqdPollutantC19/../../../../@gml:id else ()

(: 20 :)

let $invalidAqdAssessmentRegimeAqdPollutantC20 :=
     for $aqdPollutantC20 in  $docRoot//aqd:AQD_AssessmentRegime[count(aqd:pollutant)>0 and aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/7"]/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
     where ($aqdPollutantC20/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LTO")
            or(($aqdPollutantC20/../../aqd:exceedanceAttainment/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/assessmentthresholdexceedance/aboveLTO")
            and ($aqdPollutantC20/../../aqd:exceedanceAttainment/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/assessmentthresholdexceedance/belowLTO"))
    return  $aqdPollutantC20/../../../../@gml:id

(:21:)

let $invalidAqdAssessmentRegimeAqdPollutantC21 :=
    for $aqdPollutantC21 in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
    let $pollutantXlinkC21 := fn:substring-after(data($aqdPollutantC21/../../../../aqd:pollutant/@xlink:href),"pollutant/")
    where empty(index-of(('1','8','9','10','5','6001','5014','5018','5015','5029','5012','20'),$pollutantXlinkC21))=false()
    return if (($aqdPollutantC21/../../aqd:exceedanceAttainment/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/assessmentthresholdexceedance/aboveUAT")
            and ($aqdPollutantC21/../../aqd:exceedanceAttainment/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/assessmentthresholdexceedance/belowLAT")
            and  ($aqdPollutantC21/../../aqd:exceedanceAttainment/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/assessmentthresholdexceedance/LAT-UAT"))
    then $aqdPollutantC21/../../../../@gml:id else ()



(: C22 :)

let $invalidAqdAssessmentRegimeAqdPollutantC22 :=
    for $aqdPollutantC22 in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
    let $pollutantXlinkC22 := fn:substring-after(data($aqdPollutantC22/../../../../aqd:pollutant/@xlink:href),"pollutant/")
    where empty(index-of(('1045','1046','1047','1771','1772','1629','1659','1657','1668','1631','2012','2014','2015','2018','7013','4013','4813','653','5013','5610','5617',
    '5759','5626','5655','5763','7029','611','618','760','627','656','7419','20','428','430','432','503','505','394','447','6005','6006','6007','24','486','316','6008','6009',
    '451','443','316','441','475','449','21','431','464','482','6011','6012','32','25'),$pollutantXlinkC22))=false()
    return if ($aqdPollutantC22/../../aqd:exceedanceAttainment/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/assessmentthresholdexceedance/NA")
    then $aqdPollutantC22/../../../../@gml:id else ()

(: 23 :)

let $invalidAqdAssessmentType :=
    for $aqdAssessment in $docRoot//aqd:AQD_AssessmentRegime[count(aqd:assessmentMethods/aqd:AssessmentMethods/aqd:assessmentType/@xlink:href)>0]/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:assessmentType
where   $aqdAssessment/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/fixed"
    and $aqdAssessment/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/model"
    and $aqdAssessment/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/indicative"
    and $aqdAssessment/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/objective"
return  $aqdAssessment/../../../@gml:id


(:TODO: C24, C25, C26, C27 :)
(: 24 :)
let $resultXml := if (fn:string-length($countryCode) = 2) then xmlconv:getAqdModelID($countryCode) else ""
let $isInspireLebelCodesAvailable := string-length($resultXml) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultXml, "xml"))
let $aqdModelID := if($isInspireLebelCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='inspireLabel']/sparql:literal)) else ""
let $isInspireLebelCodesAvailable := count($resultXml) > 0

let $invalidModelAssessmentMetadata :=
    for $x in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:modelAssessmentMetadata
    where $isInspireLebelCodesAvailable
    return    if (empty(index-of($aqdModelID, $x/normalize-space(@xlink:href)))) then $x/../../../@gml:id else ()


(: C25:)

let $resultXml := if (fn:string-length($countryCode) = 2) then xmlconv:getInspireLabelD($countryCode) else ""
let $isInspireLebelCodesAvailable := string-length($resultXml) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultXml, "xml"))
let $inspireLebelD := if($isInspireLebelCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='inspireLabel']/sparql:literal)) else ""
let $isInspireLebelCodesAvailable := count($resultXml) > 0

let $invalidSamplingPointAssessmentMetadata :=
    for $x in distinct-values($docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata/normalize-space(@xlink:href))
    where $isInspireLebelCodesAvailable
return    if (empty(index-of($inspireLebelD, $x))) then $x else ()

(: 26 :)

let $resultXml := if (fn:string-length($countryCode) = 2) then xmlconv:getModelEndPosition($countryCode) else ""
let $isModelEndPositionCodesAvailable := string-length($resultXml) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultXml, "xml"))
let $modelEndPosition := if($isInspireLebelCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='endPosition']/sparql:literal)) else ""
let $modelInspireLebelD := if($isInspireLebelCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='inspireLabel']/sparql:literal)) else ""
let $isModelEndPositionCodesAvailable := count($resultXml) > 0

let $resultXml := if (fn:string-length($countryCode) = 2) then xmlconv:getSamplingPointEndPosition($countryCode) else ""
let $isEndPositionCodesAvailable := string-length($resultXml) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultXml, "xml"))
let $samplinPointEndPosition := if($isInspireLebelCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='endPosition']/sparql:literal)) else ""
let $samplingPointInspireLebelD := if($isInspireLebelCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='inspireLabel']/sparql:literal)) else ""
let $isEndPositionCodesAvailable := count($resultXml) > 0

let $invalidGmlEndPosition :=
    for $gmlEndPosition in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata
    where (empty(fn:index-of($samplingPointInspireLebelD,$gmlEndPosition/normalize-space(@xlink:href)))=false() or empty(fn:index-of($modelInspireLebelD,$gmlEndPosition/normalize-space(@xlink:href)))=false()) and empty($docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:endPosition)=false()
    return  if (empty(index-of($samplinPointEndPosition,$docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:endPosition)) or empty(index-of($modelEndPosition,$docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:endPosition)) ) then $docRoot//aqd:AQD_ReportingHeader/@gml:id else ()

(: 27 :)

let $resultXml := if (fn:string-length($countryCode) = 2) then xmlconv:getInspireId($countryCode) else ""
let $isInspireIdCodesAvailable := string-length($resultXml) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultXml, "xml"))
let $inspireId := if($isInspireIdCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='inspireLabel']/sparql:literal)) else ""
let $isInspireIdCodesAvailable := count($resultXml) > 0

let $resultSparql := if (fn:string-length($countryCode) = 2) then xmlconv:getPollutantCodeAndProtectionTarge($countryCode) else ""
let $isProtectionTargetAvailable := string-length($resultSparql) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultSparql, "xml"))
let $protectionTarget:= if($isProtectionTargetAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultSparql)//sparql:result/concat(sparql:binding[@name='inspireLabel']/sparql:literal,"|",sparql:binding[@name='pollutantCode']/sparql:uri,"|",sparql:binding[@name='protectionTarget']/sparql:uri,"||"))) else ""
let $isProtectionTargetAvailable := count($resultSparql) > 0

let $exceptionZone :=
for $x in  $docRoot//aqd:AQD_AssessmentRegime
let $pollutantXlinkC27 := fn:substring-after(data($x/aqd:pollutant/@xlink:href),"pollutant/")
where $x/aqd:zone/@nilReason="inapplicable"
return if (empty(index-of($xmlconv:VALID_POLLUTANT_IDS_27,$pollutantXlinkC27))) then $pollutantXlinkC27 else ()


let $aqdAQD_AssessmentRegime :=
for $concatStr in $docRoot//aqd:AQD_AssessmentRegime
    let $str := concat(normalize-space($concatStr/aqd:zone/@xlink:href),"|",$concatStr/aqd:pollutant/normalize-space(@xlink:href),"|",$concatStr/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/normalize-space(@xlink:href),"||")
where empty(index-of($inspireId,fn:substring-before($str,"|")))=false()
    return if (empty(index-of($protectionTarget, $str)) or empty($exceptionZone)=false()) then $str else ()

let $invalidAqdAssessmentRegimeZone := $aqdAQD_AssessmentRegime (:)if ($isInspireIdCodesAvailable and $isPollutantCodesAvailable and $isProtectionTargetAvailable) then
    distinct-values($docRoot//aqd:AQD_AssessmentRegime[string-length(normalize-space(aqd:zone/@xlink:href)) > 0 and
            empty(index-of($inspireId, normalize-space(aqd:zone/@xlink:href))) and empty(index-of($pollutansCode, aqd:pollutant/normalize-space(@xlink:href)))
            or empty(index-of($protectionTarget, aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/normalize-space(@xlink:href)))]/@gml:id)
else
    ():)

(: C28 If ./aqd:zone xlink:href shall be current, then ./AQD_zone/aqd:operationActivityPeriod/gml:endPosition shall be equal to “9999-12-31 23:59:59Z” or nulled (blank)  :)
let $invalidZoneGmlEndPosition :=
    for $zone in $docRoot//aqd:zone[@xlink:href='.']/aqd:AQD_Zone
    let $endPosition := normalize-space($zone/aqd:operationActivityPeriod/gml:endPosition)
    where upper-case($endPosition) != '9999-12-31 23:59:59Z' and $endPosition !=''
    return
        <tr>
            <td title="aqd:AQD_AssessmentRegime/ @gml:id">{data($zone/../../@gml:id)}</td>
            <td title="aqd:AQD_Zone/@gml:id">{data($zone/@gml:id)}</td>{
                xmlconv:getErrorTD(data($endPosition), "gml:endPosition", fn:true())
            }
        </tr>




(: 29 :)

let $resultXml := if (fn:string-length($countryCode) = 2) then xmlconv:getInspireId($countryCode) else ""
let $isInspireIdCodesAvailable := string-length($resultXml) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultXml, "xml"))
let $zoneId := if($isInspireIdCodesAvailable) then count(distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='inspireLabel']/sparql:literal))) else 0
let $isInspireIdCodesAvailable := count($resultXml) > 0

let $aqdAssessmentRegimeZone := count($docRoot//aqd:AQD_AssessmentRegime/aqd:zone)
let $invalidEqual := if ($aqdAssessmentRegimeZone != $zoneId) then concat("aqd:AQD_AssessmentRegime ",$aqdAssessmentRegimeZone," aqd:AQD_Zone ",$zoneId) else ()

(: 30 :)

(: 31 :)

let $resultXml := if (fn:string-length($countryCode) = 2) then xmlconv:getProtectionTarget($countryCode) else ""
let $isInspireIdCodesAvailable := string-length($resultXml) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultXml, "xml"))
let $aqdProtectionTarget := if($isInspireIdCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='protectionTarget']/sparql:uri)) else ()
let $isProtectionTargetCodesAvailable := count($resultXml) > 0

let $resultXml := if (fn:string-length($countryCode) = 2) then xmlconv:getPollutantCode($countryCode) else ""
let $isInspireIdCodesAvailable := string-length($resultXml) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultXml, "xml"))
let $aqdPollutantCode := if($isInspireIdCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='pollutantCode']/sparql:uri)) else ()
let $isPollutantCodesAvailable := count($resultXml) > 0

let $resultXml := if (fn:string-length($countryCode) = 2) then xmlconv:getInspireId($countryCode) else ""
let $isInspireIdCodesAvailable := string-length($resultXml) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultXml, "xml"))
let $aqdZone := if($isInspireIdCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='inspireLabel']/sparql:literal)) else ()
let $isInspireIdCodesAvailable := count($resultXml) > 0


let $aqdEnvironmentalObjective :=
for $x in  $docRoot//aqd:AQD_AssessmentRegime
let $aqdProtectionTargetLink:= $x/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/fn:normalize-space(@xlink:href)
let $aqdPollutant := $x/aqd:pollutant/fn:normalize-space(@xlink:href)
where empty(fn:index-of($aqdZone, $x/aqd:zone/fn:normalize-space(@xlink:href)))=false()
return if(empty(fn:index-of($aqdProtectionTarget, $aqdProtectionTargetLink)) or empty(fn:index-of($aqdPollutantCode,$aqdPollutant))) then $x/@gml:id else ()

(: C32 :)
let $resultXml := if (fn:string-length($countryCode) = 2) then xmlconv:getAssessmentType($countryCode) else ""
let $resultXmlModel := if (fn:string-length($countryCode) = 2) then xmlconv:getAssessmentTypeModel($countryCode) else ""
let $isSamplingPointaqdAssessmentTypeAvailable := string-length($resultXml) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultXml, "xml"))
let $isModelAssessmentTypeAvailable := string-length($resultXml) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultXmlModel, "xml"))
let $aqdSamplingPointInspireLabel  := if($isSamplingPointaqdAssessmentTypeAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='inspireLabel']/sparql:literal)) else ""
let $aqdSamplingPointAssessmentType  := if($isSamplingPointaqdAssessmentTypeAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:result/concat(sparql:binding[@name='inspireLabel']/sparql:literal,"|",sparql:binding[@name='assessmentType']/sparql:uri))) else ""
let $aqdModelInspireLabel  := if($isModelAssessmentTypeAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXmlModel)//sparql:binding[@name='inspireLabel']/sparql:literal)) else ""
let $aqdModelAssessmentType  := if($isModelAssessmentTypeAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXmlModel)//sparql:result/concat(sparql:binding[@name='inspireLabel']/sparql:literal,"|",sparql:binding[@name='assessmentType']/sparql:uri))) else ""

let $isSamplingPointaqdAssessmentTypeAvailable := count($resultXml) > 0

let $invalidAssessmentType:=
    for $x in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata/@xlink:href
let $str := concat($x,"|",$x/../../aqd:assessmentType/@xlink:href)
where (empty(index-of($aqdSamplingPointInspireLabel,fn:substring-before($str,"|")))=false() or empty(index-of($aqdModelInspireLabel,fn:substring-before($str,"|")))=false()) and fn:substring-after($str,"|")!="http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/objective"
return if (empty(index-of($aqdSamplingPointAssessmentType,$str)) and empty($aqdSamplingPointAssessmentType)=false()) then $str else
       if (empty(index-of($aqdModelAssessmentType,$str)) and empty($aqdModelAssessmentType)=false()) then $str else ()

(: C33 If The lifecycle information of ./aqd:assessmentMethods/aqd:AssessmentMethods/aqd:*AssessmentMetadata xlink:href shall be current,
    then /AQD_SamplingPoint/aqd:operationActivityPeriod/gml:endPosition or /AQD_ModelType/aqd:operationActivityPeriod/gml:endPosition shall be equal to “9999-12-31 23:59:59Z” or nulled (blank):)
let $invalidAssessmentGmlEndPosition :=
    for $assessmentMetadata in $docRoot//aqd:assessmentMethods/aqd:AssessmentMethods/*[ends-with(local-name(), 'AssessmentMetadata') and @xlink:href='.']

    let $endPosition :=
        if ($assessmentMetadata/local-name() = 'modelAssessmentMetadata') then
            normalize-space($assessmentMetadata/aqd:AQD_Model/aqd:operationActivityPeriod/gml:endPosition)
        else if ($assessmentMetadata/local-name() = 'samplingPointAssessmentMetadata') then
            normalize-space($assessmentMetadata/aqd:AQD_SamplingPoint/aqd:operationActivityPeriod/gml:endPosition)
        else
            ""

        where upper-case($endPosition) != '9999-12-31 23:59:59Z' and $endPosition != ''
    return
        <tr>
            <td title="aqd:AQD_AssessmentRegime/ @gml:id">{data($assessmentMetadata/../../../@gml:id)}</td>{
                if ($assessmentMetadata/local-name() = 'modelAssessmentMetadata') then
                    (<td title="aqd:AQD_Model/ @gml:id">{data($assessmentMetadata/aqd:AQD_Model/@gml:id)}</td>,
                        xmlconv:getErrorTD(data($endPosition), "gml:endPosition", fn:true())
                    ,<td title="aqd:AQD_SamplingPoint/ @gml:id"/>, <td title="gml:endPosition"/>)
                else if ($assessmentMetadata/local-name() = 'samplingPointAssessmentMetadata') then
                    (<td title="aqd:AQD_Model/ @gml:id"/>, <td title="gml:endPosition"/>,
                        <td title="aqd:AQD_SamplingPoint/ @gml:id">{data($assessmentMetadata/aqd:AQD_SamplingPoint/@gml:id)}</td>,
                        xmlconv:getErrorTD(data($endPosition), "gml:endPosition", fn:true())
                    )
                else
                    ()
            }

        </tr>

(: 34 :)

let $resultXml := if (fn:string-length($countryCode) = 2) then xmlconv:getInspireLabelD($countryCode) else ""
let $isSamplingPointaqdZoneCodesAvailable := string-length($resultXml) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultXml, "xml"))
let $aqdSamplingPointaqdZone  := if($isSamplingPointaqdZoneCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='inspireLabel']/sparql:literal)) else ""
let $isSamplingPointaqdZoneCodesAvailable := count($resultXml) > 0

let $resultXml := if (fn:string-length($countryCode) = 2) then xmlconv:getAqdModelID($countryCode) else ""
let $isAqdModelCodesAvailable := string-length($resultXml) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultXml, "xml"))
let $aqdAqdModelZone  := if($isAqdModelCodesAvailable ) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='inspireLabel']/sparql:literal)) else ""
let $isAqdModelCodesAvailable := count($resultXml) > 0

let $invalidSamplingPointAqdModelZone :=
    for $x in distinct-values($docRoot//aqd:AQD_AssessmentRegime/aqd:zone/fn:normalize-space(@xlink:href))
    where $isSamplingPointaqdZoneCodesAvailable and $isAqdModelCodesAvailable
    return    if (empty(index-of($aqdSamplingPointaqdZone, $x)) and empty(index-of($aqdAqdModelZone, $x))) then $x else ()

(: C35 /aqd:AQD_SamplingPoint/aqd:usedAQD or /aqd:AQD_ModelType/aqd:used shall EQUAL “true” for all ./aqd:assessmentMethods/aqd:AssessmentMethods/aqd:*AssessmentMetadata xlink:href citations :)
let $invalidAssessmentUsed :=
    for $assessmentMetadata in $docRoot//aqd:assessmentMethods/aqd:AssessmentMethods/*[ends-with(local-name(), 'AssessmentMetadata') and @xlink:href='.']

    let $used :=
        if ($assessmentMetadata/local-name() = 'modelAssessmentMetadata') then
            normalize-space($assessmentMetadata/aqd:AQD_Model/aqd:used)
        else if ($assessmentMetadata/local-name() = 'samplingPointAssessmentMetadata') then
            normalize-space($assessmentMetadata/aqd:AQD_SamplingPoint/aqd:usedAQD)
        else
            ""

        where $used != 'true'
    return
        <tr>
            <td title="aqd:AQD_AssessmentRegime/ @gml:id">{data($assessmentMetadata/../../../@gml:id)}</td>{
                if ($assessmentMetadata/local-name() = 'modelAssessmentMetadata') then
                    (<td title="aqd:AQD_Model/ @gml:id">{data($assessmentMetadata/aqd:AQD_Model/@gml:id)}</td>,
                        xmlconv:getErrorTD(data($used), "aqd:used", fn:true())
                    ,<td title="aqd:AQD_SamplingPoint/ @gml:id"/>, <td title="aqd:usedAQD"/>)
                else if ($assessmentMetadata/local-name() = 'samplingPointAssessmentMetadata') then
                    (<td title="aqd:AQD_Model/ @gml:id"/>, <td title="aqd:used"/>,
                        <td title="aqd:AQD_SamplingPoint/ @gml:id">{data($assessmentMetadata/aqd:AQD_SamplingPoint/@gml:id)}</td>,
                        xmlconv:getErrorTD(data($used), "aqd:usedAQD", fn:true())
                    )
                else
                    ()
            }

        </tr>


    (:)let $resultXmls := if (fn:string-length($countryCode) = 2 ) then xmlconv:getAqdusedAQD($countryCode) else ()
let $isAqdusedAQDCodesAvailable := fn:string-length($resultXmls) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultXmls, "xml"))
let $aqdUsedAQD  := if($isAqdusedAQDCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXmls)//sparql:binding[@name='inspireLabel']/sparql:literal)) else ()
let $isAqdusedAQDCodesAvailable := count($resultXmls) > 0

let $invalidAqdUsedAQD :=
    for $assessmentMethods in distinct-values($docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata/fn:normalize-space(@xlink:href))
    where $isAqdusedAQDCodesAvailable
    return if(empty(index-of($aqdUsedAQD,$assessmentMethods))) then $assessmentMethods else ():)

(: 37 :)

let $reportingMetric := $docRoot//aqd:AQD_AssessmentRegime[aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AEI"]/@gml:id
let $invalidAqdReportingMetric := if (count($reportingMetric)>1) then $reportingMetric else ()

(: 38 :)

let $resultXml := if (fn:string-length($countryCode) = 2) then xmlconv:getSamplingPointInspireLabel($countryCode) else ""
let $isInspireLebelCodesAvailable := string-length($resultXml) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultXml, "xml"))
let $aqdSamplingPointID := if($isInspireLebelCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='inspireLabel']/sparql:literal)) else distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='inspireLabel']/sparql:literal))
let $isInspireLebelCodesAvailable := count($resultXml) > 0


    let $aqdSamplingPointAssessmentMetadata :=
    for $aqdAssessmentRegime in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric
    where $aqdAssessmentRegime/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AEI"
return  $aqdAssessmentRegime/../../../../../aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata/fn:normalize-space(@xlink:href)

let $invalidAqdReportingMetricTest :=
for $x in $aqdSamplingPointAssessmentMetadata
where empty(index-of($aqdSamplingPointID, $x)) != false()
return $x


(: 40 :)

let $invalidsamplingPointAssessmentMetadata :=
    for $aqdPollutantC40 in $docRoot//aqd:AQD_AssessmentRegime
    let $pollutantXlinkC40 := fn:substring-after(data($aqdPollutantC40/aqd:pollutant/@xlink:href),"pollutant/")
    where empty(index-of(('1045','1046','1047','1771','1772','1629','1659','1657','1668','1631','2012','2014','2015','2018','7013','4013','4813','653','5013','5610','5617',
    '5759','5626','5655','5763','7029','611','618','760','627','656','7419','20','428','430','432','503','505','394','447','6005','6006','6007','24','486','316','6008','6009',
    '451','443','316','441','475','449','21','431','464','482','6011','6012','32','25'),$pollutantXlinkC40))
   return if (count($aqdPollutantC40/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata)>=1) then () else $aqdPollutantC40/@gml:id

return
    <table style="border-collapse:collapse;display:inline">
        <colgroup>
            <col width="15px" style="text-align:center"/>
            <col width="450px" style="text-align:left"/>
            <col width="350px" style="text-align:left"/>
            <col width="*"/>
        </colgroup>
        {xmlconv:buildResultRows("C1", "Total number of AQ Assessment Regime feature types",
            (), (), "", string($countRegimes), "", "", $tblAllRegimes)}
        {xmlconv:buildResultRows("C4", "All gml:id attributes shall have unique content within the document or namespace",
            $invalidDuplicateGmlIds, (), "@gml:id", "No duplicates found", " duplicate", "", ())}
        {xmlconv:buildResultRows("C5", "./aqd:inspireId/base:Identifier/base:localId shall be an unique code for the assessment regime.",
            $invalidDuplicateLocalIds, (), "base:localId", "No duplicates found", " duplicate", "", ())}
        {xmlconv:buildResultRows("C6", "./aqd:inspireId/base:Identifier/base:namespace List base:namespace and  count the number of base:localId assigned to each base:namespace. ",
            (), (), "", string(count($tblC6)), "", "",$tblC6)}
        {xmlconv:buildResultRows("C7", "Each of the number of /aqd:AQD_AssessmentRegime records shall contain a maximum of 1 ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmental Objective records per /aqd:AQD_AssessmentRegime element",
                $invalidAssessmentRegim,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C8", <span>./aqd:pollutant xlink:href attribute may resolve to one of
            {xmlconv:buildVocItemsList("C8", $xmlconv:POLLUTANT_VOCABULARY, $xmlconv:VALID_POLLUTANT_IDS_8)}</span>,
                $invalidPollutantC8, (), "aqd:reportingMetric", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C9", <span>./aqd:pollutant xlink:href attribute may resolve to one of
            {xmlconv:buildVocItemsList("C9",$xmlconv:POLLUTANT_VOCABULARY, $xmlconv:VALID_POLLUTANT_IDS_9)}</span>,
                $invalidPollutantC9, (), "aqd:reportingMetric", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C10", <span>Where ./aqd:pollutant resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/1 the 3 elements within ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/may only resolve to the following combinations {xmlconv:buildItemsList("C10","", $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C10)}</span>,
                $invalidAqdAssessmentRegimeAqdPollutant,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C11",  <span> Where ./aqd:pollutant resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/7 the 3 elements within ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/may only resolve to the following combinations {xmlconv:buildItemsList("C11","", $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C11)}</span>,
                $invalidAqdAssessmentRegimeAqdPollutantC11,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C12", <span>Where ./aqd:pollutant resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/8 the 3 elements within ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/may only resolve to the following combinations {xmlconv:buildItemsList("C12","", $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C12)}</span>,
                $invalidAqdAssessmentRegimeAqdPollutantC12,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C13", <span>Where ./aqd:pollutant resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/9 the 3 elements within ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/may only resolve to the following combinations {xmlconv:buildItemsList("C13","", $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C13)}</span>,
                $invalidAqdAssessmentRegimeAqdPollutantC13,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C14", <span>Where ./aqd:pollutant resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5 the 3 elements within ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/may only resolve to the following combinations {xmlconv:buildItemsList("C14","", $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C14)}</span>,
                $invalidAqdAssessmentRegimeAqdPollutantC14,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C15", <span>Where ./aqd:pollutant resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001 the 3 elements within ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/may only resolve to the following combinations {xmlconv:buildItemsList("C15","", $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C15)}</span>,
                $invalidAqdAssessmentRegimeAqdPollutantC15,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C16", <span>Where ./aqd:pollutant resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/10 the 3 elements within ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/may only resolve to the following combinations {xmlconv:buildItemsList("C16","", $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C16)}</span>,
                $invalidAqdAssessmentRegimeAqdPollutantC16,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C17", <span>Where ./aqd:pollutant resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5012  or http://dd.eionet.europa.eu/vocabulary/aq/pollutant/20 the 3 elements within ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/may only resolve to the following combinations{xmlconv:buildItemsList("C17","", $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C17)}</span>,
            $invalidAqdAssessmentRegimeAqdPollutantC17,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C18", <span>The 3  elements  within ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/ may  only resolve  to  the  following  combination
            http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV aqd:reportingMetric xlink:href attribute  shall  resolve  to  one  of
            http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean
            aqd:protectionTarget xlink:href attribute  shall  resolve  to  one  of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H where
            <a href="{ $xmlconv:POLLUTANT_VOCABULARY }">{ $xmlconv:POLLUTANT_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("C18", $xmlconv:POLLUTANT_VOCABULARY, $xmlconv:VALID_POLLUTANT_IDS_18)}</span>,
                $invalidAqdAssessmentRegimeAqdPollutantC18, (), "aqd:reportingMetric", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C19", <span>The 3  elements  within ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/ may  only resolve  to  the  following  combination
            aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean aqd:protectionTarget xlink:href attribute  shall  resolve  to  one  of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/NA where
            <a href="{ $xmlconv:POLLUTANT_VOCABULARY }">{ $xmlconv:POLLUTANT_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("C19", $xmlconv:POLLUTANT_VOCABULARY, $xmlconv:VALID_POLLUTANT_IDS_19)}</span>,
                $invalidAqdAssessmentRegimeAqdPollutantC19, (), "aqd:reportingMetric", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C20", "Where ./aqd:pollutant resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/7 and ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType xlink:href attribute resolve to http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LTO ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:exceedanceAttainment xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/assessmentthresholdexceedance/aboveLTO http://dd.eionet.europa.eu/vocabulary/aq/assessmentthresholdexceedance/belwLTO",
            $invalidAqdAssessmentRegimeAqdPollutantC20,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C21", <span>./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:exceedanceAttainment xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/assessmentthresholdexceedance/aboveUAT http://dd.eionet.europa.eu/vocabulary/aq/assessmentthresholdexceedance/belowLAT http://dd.eionet.europa.eu/vocabulary/aq/assessmentthresholdexceedance/LAT-UAT where
            <a href="{ $xmlconv:POLLUTANT_VOCABULARY }">{ $xmlconv:POLLUTANT_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("C21", $xmlconv:POLLUTANT_VOCABULARY, $xmlconv:VALID_POLLUTANT_IDS_21)}</span>,
                $invalidAqdAssessmentRegimeAqdPollutantC21, (), "aqd:reportingMetric", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C22", "Where ./aqd:pollutant resolves to the list in C9 ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:exceedanceAttainment xlink:href attribute shall resolve to http://dd.eionet.europa.eu/vocabulary/aq/assessmentthresholdexceedance/NA",
                $invalidAqdAssessmentRegimeAqdPollutantC22,(), "aqd:AQD_AssesmentRegime", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C23", "./aqd:assessmentMethods/aqd:AssessmentMethods/aqd:assessmentType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/[concept]Current options in the codelist are:http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/fixed http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/model http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/indicative http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/objective",
                $invalidAqdAssessmentType,(), "aqd:AQD_AssesmentRegime", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C24", "The assessment methods referenced by ./aqd:assessmentMethods/aqd:AssessmentMethods/aqd:modelAssessmentMeta data xlink:href attribute shall resolve to a traversable link to an assessment method /aqd:AQD_Model reported under cdr.eionet.europa.eu/ZZ/eu/aqd/d/... ",
                $invalidModelAssessmentMetadata,(), "aqd:AQD_AssesmentRegime", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C25", "The assessment methods referenced by ./aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata xlink:href attribute shall resolve to a traversable link to an assessment method /aqd:AQD_SamplingPoint reported under cdr.eionet.europa.eu/ZZ/eu/aqd/d/...",
                $invalidSamplingPointAssessmentMetadata,(),  "aqd:samplingPointAssessmentMetadata", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C26", "The assessment methods referenced by ./aqd:assessmentMethods/aqd:AssessmentMethods/aqd:modelAssessmentMeta data or ./aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata xlink:href attribute  shall  contain one  element /aqd:AQD_Model/ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:endPosition or /aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:endPosition that is operational within the aqd:reportingPeriod  included  in  the  ReportingHead",
                $invalidGmlEndPosition,(),  "aqd:AQD_SamplingPoint", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C27", "aqd:zone xlink:href attribute shall resolve to a traversable link to an AQ zone in /aqd:AQD_Zone reported under cdr.eionet.europa.eu/ZZ/eu/aqd/b/...  The ./aqd:pollutant and ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget within the Assessment Regime shall equal one combination /aqd:AQD_Zone/aqd:pollutants/aqd:Pollutant/aqd:pollutantCode and /aqd:AQD_Zone/aqd:pollutants/aqd:Pollutant/aqd:protectionTarget within  the  linked  zone  aqd:AQD_Zone/aqd:pollutants
Exception : Where ./aqd:pollutant resolves to the list in  C9 and http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001 ./aqd:zone xlink:href attribute MAY resolve to <aqd:zone nilReason='inapplicable'/>",
                $invalidAqdAssessmentRegimeZone,(),  "aqd:AQD_Model or aqd:AQD_SamplingPoint", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C28", "The number of unique zones cited by ./aqd:AQD_AssessmentRegime shall be EQUAL to the number of unique zones in ./aqd:AQD_Zone",
                $invalidZoneGmlEndPosition,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C29", "The  number of unique zones cited by /aqd:AQD_AssessmentRegime shall be EQUAL to the number of unique zones in ./aqd:AQD_Zone",
            $invalidEqual, (), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C31", "./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget and ./aqd:pollutant combinations  shall  reconcile  to  corresponding  information  within /aqd:AQD_Zone/aqd:pollutants/aqd:Pollutant for  the  zone  cited  by ./aqd:zone",
                $aqdEnvironmentalObjective, (), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C32", "./aqd:assessmentMethods/aqd:AssessmentMethods/aqd:assessmentType shall be compared with the /aqd:AQD_SamplingPoint/aqd:assessmentType for assessment method cited by ./aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPoint Assessm entMetadata xlink:href attribute and/ or /aqd:AQD_Model /aqd:assessmentType for  assessment  method  cited  by ./aqd:assessmentMet hods/aqd:AssessmentMethods/aqd:samplingPoint Assessm entMetadata xlink:href attribute",
                $invalidAssessmentType,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C33", "If The lifecycle information of ./aqd:assessmentMethods/aqd:AssessmentMethods/aqd:*AssessmentMetadata xlink:href shall be current, then /AQD_SamplingPoint/aqd:operationActivityPeriod/gml:endPosition or /AQD_ModelType/aqd:operationActivityPeriod/gml:endPosition shall be equal to “9999-12-31 23:59:59Z” or nulled (blank)",
                $invalidAssessmentGmlEndPosition,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C34", "The  number of unique zones cited by /aqd:AQD_AssessmentRegime shall be EQUAL to the number of unique zones in ./aqd:AQD_Zone",
            $invalidSamplingPointAqdModelZone, (), "aqd:zone", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C35", "/aqd:AQD_SamplingPoint/aqd:usedAQD or /aqd:AQD_ModelType/aqd:used shall EQUAL “true” for all ./aqd:assessmentMethods/aqd:AssessmentMethods/aqd:*AssessmentMetadata xlink:href citations",
                $invalidAssessmentUsed,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C37", "There shall be only 1 record per MS where ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmental Objective/aqd:EnvironmentalObjective/aqd:reportingMetric xlink:href attribute resolves to http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AEI",
                $invalidAqdReportingMetric,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C38", "Where./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric xlink:href attribute resolves to http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AEI the /aqd:AQD_SamplingPoint/aqd:relevantEmissions/aqd:RelevantEmissions/aqd:stationClassification xlink:href attribute shall resolve to http://dd.eionet.europa.eu/vocabulary/aq/stationclassification/background for all aqd:AQD_SamplingPoint linked via aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods /aqd:samplingPointAssessmentMetadata citations",
                $invalidAqdReportingMetricTest,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C40", <span>The total number of /aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata citations within a MS (delivery) shall be GREATER THAN OR EQUAL to 1 where ./aqd:pollutant xlink:href attribute resolves to{xmlconv:buildVocItemsList("C40", $xmlconv:POLLUTANT_VOCABULARY, $xmlconv:VALID_POLLUTANT_IDS_40)}</span>,
                $invalidsamplingPointAssessmentMetadata,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "", ())}

    </table>
}
;

declare function xmlconv:buildItemsList($ruleId as xs:string, $vocabularyUrl as xs:string, $ids as xs:string*)
as element(div) {
    let $list :=
        for $id in $ids
        let $refUrl := concat($vocabularyUrl, $id)
        return
            <p>{ $refUrl }</p>


    return
        <div>
            <a id='vocLink-{$ruleId}' href='javascript:toggleItem("vocValuesDiv","vocLink", "{$ruleId}", "combination")'>Show combinations</a>
            <div id="vocValuesDiv-{$ruleId}" style="display:none">{ $list }</div>
        </div>
};

declare function xmlconv:buildVocItemsList($ruleId as xs:string, $vocabularyUrl as xs:string, $ids as xs:string*)
as element(div) {
    let $list :=
        for $id in $ids
        let $refUrl := concat($vocabularyUrl, $id)
        return
            <li><a href="{ $refUrl }">{ $refUrl } </a></li>


    return
        <div>
            <a id='vocLink-{$ruleId}' href='javascript:toggleItem("vocValuesDiv","vocLink", "{$ruleId}", "item")'>Show items</a>
            <div id="vocValuesDiv-{$ruleId}" style="display:none"><ul>{ $list }</ul></div>
        </div>
};

(:
 : ======================================================================
 : Main function
 : ======================================================================
 :)
declare function xmlconv:proceed($source_url as xs:string, $countryCode as xs:string) {

let $countZones := count(doc($source_url)//aqd:AQD_AssessmentRegime)
let $result := if ($countZones > 0) then xmlconv:checkReport($source_url, $countryCode) else ()

return
    <div>
        <h2>Check air quality assessment regimes - Dataflow C</h2>
        {
        if ( $countZones = 0) then
            <p>No aqd:AQD_AssessmentRegime elements found from this XML.</p>
        else
        <div>
            {
                if ($result//div/@class = 'error') then
                    <p>This XML file did NOT pass the following crucial checks: {string-join($result//div[@class = 'error'], ',')}</p>
                else
                    <p>This XML file passed all crucial checks which in this case are: C4,C5,C6,C7,C8,C9,C10,C11,C12,C13,C14,C16,C17,C18,C20,C21,C23,C28,C32,C33,C34,C35,C38 as well as cross-checks: C24,C25,C26,C27,C31</p>
            }
            <p>This check evaluated the delivery by executing tier-1 tests on air quality assessment regimes data in Dataflow C as specified in <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a>.</p>
            <div><a id='legendLink' href="javascript: showLegend()" style="padding-left:10px;">How to read the test results?</a></div>
            <fieldset style="font-size: 90%; display:none" id="legend">
                <legend>How to read the test results</legend>
                All test results are labeled with coloured bullets. The number in the bullet reffers to the rule code. The background colour of the bullets means:
                <ul style="list-style-type: none;">
                    <li><div style="width:50px; display:inline-block;margin-left:10px">{xmlconv:getBullet('Blue', 'info')}</div> - the data confirms to the rule, but additional feedback could be provided in QA result.</li>
                    <li><div style="width:50px; display:inline-block;margin-left:10px">{xmlconv:getBullet('Red', 'error')}</div> - the crucial check did NOT pass and errenous records found from the delivery.</li>
                    <li><div style="width:50px; display:inline-block;margin-left:10px">{xmlconv:getBullet('Orange', 'warning')}</div> - the non-crucial check did NOT pass.</li>
                    <li><div style="width:50px; display:inline-block;margin-left:10px">{xmlconv:getBullet('Grey', 'skipped')}</div> - the check was skipped due to no relevant values found to check.</li>
                </ul>
                <p>Click on the "Show records" link to see more details about the test result.</p>
            </fieldset>
            <h3>Test results</h3>
            {$result}
        </div>
        }
    </div>
};
(:
xmlconv:proceed( $source_url )
:)

