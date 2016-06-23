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
 : @author George Sofianos
 : small modification added by Jaume Targa (ETC/ACM) to align with QA document & polish some checks
 :)

module namespace xmlconv = "http://converters.eionet.europa.eu/dataflowC";
import module namespace common = "aqd-common" at "aqd_check_common.xquery";
import module namespace sparqlx = "aqd-sparql" at "aqd-sparql.xquery";
import module namespace labels = "aqd-labels" at "aqd-labels.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";
import module namespace vocabulary = "aqd-vocabulary" at "aqd-vocabulary.xquery";
import module namespace dd = "aqd-dd" at "aqd-dd.xquery";
import module namespace filter = "aqd-filter" at "aqd-filter.xquery";
import module namespace query = "aqd-query" at "aqd-query.xquery";

declare namespace aqd = "http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0";
declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace am = "http://inspire.ec.europa.eu/schemas/am/3.0";
declare namespace ef = "http://inspire.ec.europa.eu/schemas/ef/3.0";
declare namespace base = "http://inspire.ec.europa.eu/schemas/base/3.3";
declare namespace gn = "urn:x-inspire:specification:gmlas:GeographicalNames:3.0";
declare namespace base2 = "http://inspire.ec.europa.eu/schemas/base2/1.0";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace skos="http://www.w3.org/2004/02/skos/core#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace prop="http://dd.eionet.europa.eu/property/";

declare variable $xmlconv:ISO2_CODES as xs:string* := ("AL","AT","BA","BE","BG","CH","CY","CZ","DE","DK","DZ","EE","EG","ES","FI",
    "FR","GB","GR","HR","HU","IE","IL","IS","IT","JO","LB","LI","LT","LU","LV","MA","ME","MK","MT","NL","NO","PL","PS","PT",
     "RO","RS","SE","SI","SK","TN","TR","XK","UK");
(:===================================================================:)
(: Variable given as an external parameter by the QA service                                                 :)
(:===================================================================:)

declare variable $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C11 as xs:string* := ("aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV aqd:reportingMetric xlink:href attribute  shall  resolve  to  one  of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove-3yr aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H","or",
"aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LTO aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H","or","or
aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV
aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AOT40c-5yr aqd:protectionTarget
xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V","or","aqd:objectiveType xlink:href attribute shall resolve to one of
http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LTO
aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AOT40c
aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V", "or",
"aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/INT aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove
aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H",
"or", "aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ALT aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove
aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H");

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
xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V",
"or", "aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ALT
aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/3hAbove
aqd:protectionTarget xlink:href attribute shall resolve to one of
http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H");

declare variable $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C12 as xs:string* := ("aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objective
type/LV aqd:reportingMetric
xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove
aqd:protectionTarget
xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H","or","
http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV
aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/a
Mean aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H",
"or","aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVMOT aqd:reportingMetric xlink:href attribute shall resolve to one of
http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H",
"or","aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVMOT aqd:reportingMetric xlink:href attribute shall resolve to one of
http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hoursAbove aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H",
"or", "aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ALT aqd:reportingMetric xlink:href attribute shall resolve to one of
http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/3hAbove aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H",
"or", "aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVmaxMOT aqd:reportingMetric xlink:href attribute shall resolve to one of
http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H",
"or", "aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVmaxMOT aqd:reportingMetric xlink:href attribute shall resolve to one of
http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H");


declare variable $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C13 as xs:string* := ("aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V");

declare variable $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C14 as xs:string* := ("aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV
aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove
aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H",
"or","
http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV
aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean
aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H");

declare variable $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C15 as xs:string* := ("
    aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ECO
    aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AEI
    aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H","or","
    
    aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV
    aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean
    aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H","or","
    
    aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV
    aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean
    aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H","or","
    
    aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVMOT
    aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean
    aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H","or","
    
    aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVMOT
    aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean
    aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S1","or","
    
    aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV
    aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean
    aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S1","or","
    
    aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV
    aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean
    aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S2","or","
    
    aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO
    aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/NA
    aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/NA");


declare variable $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C16 as xs:string* := (
"aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV
aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove
aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H");
declare variable $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C17 as xs:string* := (
"aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV
aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean
aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H",
"or", "aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO
aqd:reportingMetric xlink:href attribute shall resolve to one of  http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/NA
aqd:protectionTarget xlink:href attribute shall resolve to one of  http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/NA");

declare variable $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C18 as xs:string* := (
"aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV
aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean
aqd:protectionTarget xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H",
"or", "aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO
aqd:reportingMetric xlink:href attribute shall resolve to one of  http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/NA
aqd:protectionTarget xlink:href attribute shall resolve to one of  http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/NA");



declare variable $xmlconv:VALID_POLLUTANT_IDS as xs:string* := ("1", "7", "8", "9", "5", "6001", "10","20", "5012", "5014", "5015", "5018", "5029");

declare variable $xmlconv:VALID_POLLUTANT_IDS_18 as xs:string* := ("5014", "5015", "5018", "5029");

declare variable $xmlconv:MANDATORY_POLLUTANT_IDS_8  as xs:string* := ("1","7","8","9","5","6001","10","20","5012","5014","5015","5018","5029");

declare variable $xmlconv:UNIQUE_POLLUTANT_IDS_9  as xs:string* := ("1","7","8","9","5","6001","10","20","5012","5014","5015","5018","5029","1045",
"1046","1047","1771","1772","1629","1659","1657","1668","1631","2012","2014","2015","2018","7013","4013","4813","653","5013","5610","5617","5759",
"5626","5655","5763","7029","611","618","760","627","656","7419","20","428","430","432","503","505","394","447","6005","6006","6007","24","486",
"316","6008","6009","451","443","316","441","475","449","21","431","464","482","6011","6012","32","25");

declare variable $xmlconv:VALID_POLLUTANT_IDS_19  as xs:string* := ("1045","1046","1047","1771","1772","1629","1659","1657","1668","1631","2012","2014","2015","2018","7013","4013","4813","653","5013","5610","5617",
"5759","5626","5655","5763","7029","611","618","760","627","656","7419","428","430","432","503","505","394","447","6005","6006","6007","24","486","316","6008","6009","451","443","441","475","449","21","431","464",
"482","6011","6012","32","25");

declare variable $xmlconv:VALID_POLLUTANT_IDS_27 as xs:string* := ('1045','1046','1047','1771','1772','1629','1659','1657','1668','1631','2012','2014','2015','2018','7013','4013','4813','653','5013','5610','5617',
'5759','5626','5655','5763','7029','611','618','760','627','656','7419','20','428','430','432','503','505','394','447','6005','6006','6007','24','486','316','6008','6009',
'451','443','316','441','475','449','21','431','464','482','6011','6012','32','25','6001');

declare variable $xmlconv:VALID_POLLUTANT_IDS_40 as xs:string* := ($xmlconv:MANDATORY_POLLUTANT_IDS_8, $xmlconv:UNIQUE_POLLUTANT_IDS_9);

(:'1045','1046','1047','1771','1772','1629','1659','1657','1668','1631','2012','2014','2015','2018','7013','4013','4813','653','5013','5610','5617',
'5759','5626','5655','5763','7029','611','618','760','627','656','7419','428','430','432','503','505','394','447','6005','6006','6007','24','486','316','6008','6009',
'451','443','316','441','475','449','21','431','464','482','6011','6012','32','25':)

declare variable $xmlconv:VALID_POLLUTANT_IDS_21 as xs:string* := ("1","8","9","10","5","6001","5014","5018","5015","5029","5012","20");

declare function xmlconv:getProtectionTarget($cdrUrl as xs:string, $bDir as xs:string) as xs:string {
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
         FILTER (CONTAINS(str(?zone), '", $cdrUrl, $bDir, "'))
} order by ?zone ")
};

declare function xmlconv:getSamplingPointInspireLabel($cdrUrl as xs:string) as xs:string {
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


declare function xmlconv:getModelEndPosition($latestDEnvelopes as xs:string*, $startDate as xs:string, $endDate as xs:string) as xs:string {
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

declare function xmlconv:getSamplingPointEndPosition($latestDEnvelopes as xs:string*, $startDate as xs:string, $endDate as xs:string) as xs:string {
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

declare function xmlconv:getLatestDEnvelope($cdrUrl as xs:string) {
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
declare function xmlconv:getLatestZoneEnvelope($zonesUrl as xs:string, $reportingYear) as xs:string? {
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

declare function xmlconv:getInspireId($latestZonesUrl as xs:string)
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

declare function xmlconv:getPollutantCodeAndProtectionTarge($cdrUrl as xs:string, $bDir as xs:string)
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

declare function xmlconv:getC31($countryCode as xs:string) as xs:string {
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
(: Rule implementations :)
declare function xmlconv:checkReport($source_url as xs:string, $countryCode as xs:string, $bDir as xs:string) as element(table) {

(: SETUP COMMON VARIABLES :)
let $envelopeUrl := common:getEnvelopeXML($source_url)

let $docRoot := doc($source_url)

let $cdrUrl := common:getCdrUrl($countryCode)
let $zonesUrl := concat($cdrUrl, $bDir)
let $reportingYear := common:getReportingYear($docRoot)



let $latestZonesUrl := xmlconv:getLatestZoneEnvelope($zonesUrl, $reportingYear)


(: C1 :)
let $countRegimes := count($docRoot//aqd:AQD_AssessmentRegime)
let $tblAllRegimes :=
    for $rec in $docRoot//aqd:AQD_AssessmentRegime
    return
        <tr>
            <td title="gml:id">{data($rec/@gml:id)}</td>
            <td title="base:localId">{data($rec/aqd:inspireId/base:Identifier/base:localId)}</td>
            <td title="base:namespace">{data($rec/aqd:inspireId/base:Identifier/base:namespace)}</td>
            <td title="aqd:zone">{common:checkLink(data($rec/aqd:zone/@xlink:href))}</td>
            <td title="aqd:pollutant">{common:checkLink(data($rec/aqd:pollutant/@xlink:href))}</td>
            <td title="aqd:protectionTarget">{common:checkLink(data($rec/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href))}</td>
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
let $tblC6 :=
    for $id in $allBaseNamespace
    let $localId := $docRoot//aqd:AQD_AssessmentRegime/aqd:inspireId/base:Identifier[base:namespace = $id]/base:localId
    return
        <tr>
            <td title="base:namespace">{$id}</td>
            <td title="base:localId">{count($localId)}</td>
        </tr>
        
(: C6.1 :)
let $invalidNamespaces := common:checkNamespaces($source_url) 
(: C7 :)

let $invalidAssessmentRegim :=
    for $aqdAQD_AssessmentRegim in $docRoot//aqd:AQD_AssessmentRegime
    where $aqdAQD_AssessmentRegim[count(aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href)=0]
    return $aqdAQD_AssessmentRegim/@gml:id

(: C8 :)
(: if a regime is missing for a pollutant in the list, warning should be thrown :)

let $missingPollutantC8 :=
for $code in $xmlconv:MANDATORY_POLLUTANT_IDS_8
    let $pollutantLink := fn:concat($vocabulary:POLLUTANT_VOCABULARY, $code)
    where count($docRoot//aqd:AQD_AssessmentRegime/aqd:pollutant[@xlink:href=$pollutantLink]) < 1
    return $code

(:~
     C9 - Provides a count of unique pollutants and lists them
 :)

let $foundPollutantC9 :=
for $code in $xmlconv:UNIQUE_POLLUTANT_IDS_9
    let $pollutantLink := fn:concat($vocabulary:POLLUTANT_VOCABULARY, $code)
    where count($docRoot//aqd:AQD_AssessmentRegime/aqd:pollutant[@xlink:href=$pollutantLink and ..//aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO"]) > 0
    return $code

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
(: Please add following combination: aqd:objectiveType xlink:href attribute shall resolve to one of
http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ALT aqd:reportingMetric xlink:href attribute shall resolve to one of
http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/3hAbove aqd:protectionTarget xlink:href attribute shall resolve to one of  http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H
:)
      and
            (($aqdPollutantC10/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ALT")
                   or ($aqdPollutantC10/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/3hAbove")
                   or ($aqdPollutantC10/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))


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
        (: 2 additional combinations based on #21117 :)
        and
           (($aqdPollutantC11/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/INT")
            or ($aqdPollutantC11/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove")
            or ($aqdPollutantC11/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
        and
           (($aqdPollutantC11/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ALT")
            or ($aqdPollutantC11/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove")
            or ($aqdPollutantC11/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))

    return $aqdPollutantC11/../../../../@gml:id

(: C12 :)

let $invalidAqdAssessmentRegimeAqdPollutantC12 :=
    for $aqdPollutantC12 in  $docRoot//aqd:AQD_AssessmentRegime[count(aqd:pollutant)>0 and aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/8"]/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
    where (($aqdPollutantC12/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
            or ($aqdPollutantC12/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove")
            or ($aqdPollutantC12/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
       and
            (($aqdPollutantC12/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
                    or ($aqdPollutantC12/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
                    or ($aqdPollutantC12/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))

        (: 3 additional based on #21117 :)
       and
            (($aqdPollutantC12/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVMOT")
                    or ($aqdPollutantC12/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
                    or ($aqdPollutantC12/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
       and
            (($aqdPollutantC12/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVMOT")
                    or ($aqdPollutantC12/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove")
                    or ($aqdPollutantC12/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
       and
            (($aqdPollutantC12/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ALT")
                    or ($aqdPollutantC12/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/3hAbove")
                    or ($aqdPollutantC12/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))

       and
            (($aqdPollutantC12/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVmaxMOT")
                    or ($aqdPollutantC12/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
                    or ($aqdPollutantC12/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
       and
            (($aqdPollutantC12/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVmaxMOT")
                    or ($aqdPollutantC12/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove")
                    or ($aqdPollutantC12/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))


    return $aqdPollutantC12/../../../../@gml:id

(: C13 :)

let $invalidAqdAssessmentRegimeAqdPollutantC13 :=
    for $aqdPollutantC13 in  $docRoot//aqd:AQD_AssessmentRegime[count(aqd:pollutant)>0 and aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/9"]/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
    where (($aqdPollutantC13/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL")
            or ($aqdPollutantC13/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
            or ($aqdPollutantC13/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V"))
	and
            (($aqdPollutantC13/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO")
            or ($aqdPollutantC13/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/NA")
            or ($aqdPollutantC13/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/NA"))

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
(: 2 additional in #21117 :)
    and
            (($aqdPollutantC15/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV")
            or ($aqdPollutantC15/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
            or ($aqdPollutantC15/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
    and
            (($aqdPollutantC15/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVMOT")
            or ($aqdPollutantC15/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
            or ($aqdPollutantC15/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
            
    and
            (($aqdPollutantC15/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVMOT")
            or ($aqdPollutantC15/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
            or ($aqdPollutantC15/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S1"))            

    and
            (($aqdPollutantC15/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
            or ($aqdPollutantC15/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
            or ($aqdPollutantC15/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S1"))

    and
            (($aqdPollutantC15/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
            or ($aqdPollutantC15/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
            or ($aqdPollutantC15/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S2"))
(: another addition by JT :)
    and
            (($aqdPollutantC15/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO")
            or ($aqdPollutantC15/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/NA")
            or ($aqdPollutantC15/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/NA"))



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
     where (($aqdPollutantC17/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
        or ($aqdPollutantC17/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
        or  ($aqdPollutantC17/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
    and
        (($aqdPollutantC17/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO")
        or ($aqdPollutantC17/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/NA")
        or  ($aqdPollutantC17/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/NA"))

    return $aqdPollutantC17/../../../../@gml:id

(: C18 :)

let $invalidAqdAssessmentRegimeAqdPollutantC18 :=
    for $aqdPollutantC18 in  $docRoot//aqd:AQD_AssessmentRegime[count(aqd:pollutant)>0 and aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5014" or aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5018"
    or aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5015" or aqd:pollutant/@xlink:href="http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5029"]/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
    where (($aqdPollutantC18/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV")
            or ($aqdPollutantC18/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
            or  ($aqdPollutantC18/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
     and
     (($aqdPollutantC18/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO")
            or ($aqdPollutantC18/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/NA")
            or  ($aqdPollutantC18/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/NA"))

    return $aqdPollutantC18/../../../../@gml:id

(: C19 :)

let $invalidAqdAssessmentRegimeAqdPollutantC19 :=
    for $aqdPollutantC19 in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
    let $pollutantXlinkC19 := fn:substring-after(data($aqdPollutantC19/../../../../aqd:pollutant/@xlink:href),"pollutant/")
    where empty(index-of(('1045','1046','1047','1771','1772','1629','1659','1657','1668','1631','2012','2014','2015','2018','7013','4013','4813','653','5013','5610','5617',
    '5759','5626','5655','5763','7029','611','618','760','627','656','7419','428','430','432','503','505','394','447','6005','6006','6007','24','486','316','6008','6009',
    '451','443','316','441','475','449','21','431','464','482','6011','6012','32','25'),$pollutantXlinkC19))=false()
    return if (($aqdPollutantC19/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO")
    or ($aqdPollutantC19/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/NA")
    or  ($aqdPollutantC19/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/NA"))
    then $aqdPollutantC19/../../../../@gml:id else ()

(: DEPRECATED C20
    TODO: REMOVE after testing

let $invalidAqdAssessmentRegimeAqdPollutantC20 :=
     for $aqdPollutantC20 in  $docRoot//aqd:AQD_AssessmentRegime[count(aqd:pollutant)>0 and aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/7"
        and aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href="http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LTO"]/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
     where (($aqdPollutantC20/../../aqd:exceedanceAttainment/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/assessmentthresholdexceedance/aboveLTO")
            and ($aqdPollutantC20/../../aqd:exceedanceAttainment/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/assessmentthresholdexceedance/belowLTO"))
    return  $aqdPollutantC20/../../../../@gml:id:)

(: C20 :)
let $environmentalObjectiveCombinations :=
    doc("http://dd.eionet.europa.eu/vocabulary/aq/environmentalobjective/rdf")

let $invalidAqdAssessmentRegimeAqdPollutantC20 :=
    for $x in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
        let $pollutant := string($x/../../../../aqd:pollutant/@xlink:href)
        let $objectiveType := string($x/aqd:objectiveType/@xlink:href)
        let $reportingMetric := string($x/aqd:reportingMetric/@xlink:href)
        let $protectionTarget := string($x/aqd:protectionTarget/@xlink:href)
        let $exceedance := string($x/../../aqd:exceedanceAttainment/@xlink:href)
    return
        if (not($environmentalObjectiveCombinations//skos:Concept[prop:relatedPollutant/@rdf:resource = $pollutant and prop:hasProtectionTarget/@rdf:resource = $protectionTarget
                and prop:hasObjectiveType/@rdf:resource = $objectiveType and prop:hasReportingMetric/@rdf:resource = $reportingMetric
                and prop:assessmentThreshold/@rdf:resource = $exceedance]))
        then
            $x/../../../../@gml:id
        else
            ()

(: C22
    TODO: Remove after testing
let $invalidAqdAssessmentRegimeAqdPollutantC22 :=
    for $x in $docRoot//aqd:AQD_AssessmentRegime[aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO"]
    let $exceedance :=  $x/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:exceedanceAttainment/string(@xlink:href)
    where not($exceedance = "http://dd.eionet.europa.eu/vocabulary/aq/assessmentthresholdexceedance/NA")
    return $x/@gml:id :)

(: C23a :)
let $invalidAqdAssessmentType :=
    for $aqdAssessment in $docRoot//aqd:AQD_AssessmentRegime[count(aqd:assessmentMethods/aqd:AssessmentMethods/aqd:assessmentType/@xlink:href)>0]/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:assessmentType
where   $aqdAssessment/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/fixed"
    and $aqdAssessment/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/model"
    and $aqdAssessment/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/indicative"
    and $aqdAssessment/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/objective"
return  $aqdAssessment/../../../@gml:id
(:~
    C23B - Warning
:)
let $invalid23B :=
    $docRoot//aqd:AQD_AssessmentRegime[count(aqd:assessmentMethods/aqd:AssessmentMethods/aqd:assessmentType/@xlink:href)>0]/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:assessmentTypeDescription[string() = ""]/../../../@gml:id

(: 26 :)

let $startDate := substring(data($docRoot//aqd:reportingPeriod/gml:TimePeriod/gml:beginPosition),1,10)
let $endDate := substring(data($docRoot//aqd:reportingPeriod/gml:TimePeriod/gml:endPosition),1,10)

let $latestDEnvelopes := distinct-values(data(sparqlx:executeSparqlQuery(xmlconv:getLatestDEnvelope($cdrUrl))//sparql:binding[@name='dataset']/sparql:uri))
let $modelSparql := if (fn:string-length($countryCode) = 2) then xmlconv:getModelEndPosition($latestDEnvelopes, $startDate, $endDate) else ""
let $modelMethods := distinct-values(data(sparqlx:executeSparqlQuery($modelSparql)//sparql:binding[@name='inspireLabel']/sparql:literal))

let $samplingPointSparql := if (fn:string-length($countryCode) = 2) then xmlconv:getSamplingPointEndPosition($latestDEnvelopes,$startDate,$endDate) else ""
let $sampingPointMethods := distinct-values(data(sparqlx:executeSparqlQuery($samplingPointSparql)//sparql:binding[@name='inspireLabel']/sparql:literal))


let $tblC26 :=
    for $method in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods
        let $modelMetaCount := count($method/aqd:modelAssessmentMetadata)
        let $samplingPointMetaCount := count($method/aqd:samplingPointAssessmentMetadata)

        let $invalidModel :=
        for $meta1 in $method/aqd:modelAssessmentMetadata
            return
            if (empty(index-of($modelMethods, data($meta1/@xlink:href)))) then
                <tr>
                    <td title="AQD_AssessmentRegime">{data($meta1/../../../@gml:id)}</td>
                    <td title="aqd:modelAssessmentMetadata">{data($meta1/@xlink:href)}</td>
                    <td title="aqd:samplingPointAssessmentMetadata"></td>
                </tr>

            else ()

        let $invalidSampingPoint :=
        for $meta2 in $method/aqd:samplingPointAssessmentMetadata
            return
            if (empty(index-of($sampingPointMethods, data($meta2/@xlink:href)))) then
                <tr>
                    <td title="AQD_AssessmentRegime">{data($meta2/../../../@gml:id)}</td>
                    <td title="aqd:modelAssessmentMetadata"></td>
                    <td title="aqd:samplingPointAssessmentMetadata">{data($meta2/@xlink:href)}</td>
                </tr>

            else ()

          return if ($modelMetaCount = 0 and $samplingPointMetaCount = 0) then
                <tr>
                    <td title="AQD_AssessmentRegime">{data($method/../../@gml:id)}</td>
                    <td title="aqd:modelAssessmentMetadata">None specified</td>
                    <td title="aqd:samplingPointAssessmentMetadata">None specified</td>
                </tr>
          else
            (($invalidModel), ($invalidSampingPoint))


(: 27 :)

(: return all zones listed in the doc :)

let $resultXml := if (fn:string-length($countryCode) = 2) then xmlconv:getInspireId($latestZonesUrl) else ""
let $isInspireIdCodesAvailable := string-length($resultXml) > 0 and doc-available(sparqlx:getSparqlEndpointUrl($resultXml, "xml"))
let $zoneIds := if($isInspireIdCodesAvailable) then distinct-values(data(sparqlx:executeSparqlQuery($resultXml)//sparql:binding[@name='inspireLabel']/sparql:literal)) else ()

let $validZones := 
    for $zoneId in $zoneIds
    return
        if ($zoneId != "" and count($docRoot//aqd:AQD_AssessmentRegime/aqd:zone[@xlink:href=$zoneId]) > 0) then
            $zoneId
        else
            ()
            
(: return zones not listed in B :)
let $invalidEqual :=
    for $regime in $docRoot//aqd:AQD_AssessmentRegime
    let $zoneId := data($regime/aqd:zone/@xlink:href)
    let $zoneId := if (string-length($zoneId) = 0) then "" else $zoneId

    return
    if ($zoneId != "" and empty(index-of($zoneIds, $zoneId))) then
        <tr>
            <td title="AQD_AssessmentRegime">{data($regime/@gml:id)}</td>
            <td title="aqd:zoneId">{$zoneId}</td>
            <td title="AQD_Zone">Not existing</td>
        </tr>
    else ()

let $invalidEqual2 :=
    for $zoneId in $zoneIds
    return
    if ($zoneId != "" and count($docRoot//aqd:AQD_AssessmentRegime/aqd:zone[@xlink:href=$zoneId]) = 0) then
        <tr>
            <td title="AQD_AssessmentRegime">Not existing</td>
            <td title="aqd:zoneId"></td>
            <td title="AQD_Zone">{$zoneId}</td>
        </tr>
    else ()


let $countZoneIds1 := count($zoneIds)
let $countZoneIds2 := count(distinct-values($docRoot//aqd:AQD_AssessmentRegime/aqd:zone/@xlink:href))


let $resultC27 := (($invalidEqual), ($invalidEqual2))

(: 29 :)

(:
let $resultXml := if (fn:string-length($countryCode) = 2) then xmlconv:getInspireId($cdrUrl) else ""
let $isInspireIdCodesAvailable := string-length($resultXml) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultXml, "xml"))
let $inspireId := if($isInspireIdCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='inspireLabel']/sparql:literal)) else ""
:)

let $resultSparql := if (fn:string-length($countryCode) = 2) then xmlconv:getPollutantCodeAndProtectionTarge($cdrUrl, $bDir) else ""
let $isProtectionTargetAvailable := string-length($resultSparql) > 0 and doc-available(sparqlx:getSparqlEndpointUrl($resultSparql, "xml"))

let $validRows :=
for $rec in sparqlx:executeSparqlQuery($resultSparql)
return
    concat(data($rec//sparql:binding[@name='inspireLabel']/sparql:literal), "#", data($rec//sparql:binding[@name='pollutantCode']/sparql:uri), "#",data($rec//sparql:binding[@name='protectionTarget']/sparql:uri))
let $validRows := distinct-values($validRows)

let $exceptionPollutantIds := ("6001")

let $invalid :=
for $x in  $docRoot//aqd:AQD_AssessmentRegime[aqd:zone/@xlink:href = $validZones]
    let $pollutantCode := fn:substring-after(data($x//aqd:pollutant/@xlink:href),"pollutant/")
    let $key := if (not(empty(index-of($exceptionPollutantIds, $pollutantCode)))
      and data($x//aqd:zone/@nilReason)="inapplicable") then
    "EXC" else
    concat(data($x//aqd:zone/@xlink:href), '#', data($x//aqd:pollutant/@xlink:href), '#', data($x//aqd:protectionTarget/@xlink:href))
where empty(index-of($validRows, $key)) and not(empty(index-of($xmlconv:MANDATORY_POLLUTANT_IDS_8, $pollutantCode)))
return if ($key !="EXC") then

                <tr>
                    <td title="AQD_AssessmentRegime">{data($x/@gml:id)}</td>
                    <td title="aqd:zone">{data($x//aqd:zone/@xlink:href)}</td>
                    <td title="aqd:pollutant">{data($x//aqd:pollutant/@xlink:href)}</td>
                    <td title="aqd:protectionTarget">{data($x//aqd:protectionTarget/@xlink:href)}</td>
                </tr>
else ()

let $tblC29 := $invalid

(: C28 If ./aqd:zone xlink:href shall be current, then ./AQD_zone/aqd:operationActivityPeriod/gml:endPosition shall be equal to “9999-12-31 23:59:59Z” or nulled (blank)  :)
let $invalidZoneGmlEndPosition :=
    for $zone in $docRoot//aqd:zone[@xlink:href='.']/aqd:AQD_Zone
    let $endPosition := normalize-space($zone/aqd:operationActivityPeriod/gml:endPosition)
    where upper-case($endPosition) != '9999-12-31 23:59:59Z' and $endPosition !=''
    return
        <tr>
            <td title="aqd:AQD_AssessmentRegime/ @gml:id">{data($zone/../../@gml:id)}</td>
            <td title="aqd:AQD_Zone/@gml:id">{data($zone/@gml:id)}</td>{
                html:getErrorTD(data($endPosition), "gml:endPosition", fn:true())
            }
        </tr>

(: C31 :)
let $C31query := xmlconv:getC31($countryCode)
let $C31Bresults := <results>{sparqlx:executeSparqlQuery($C31query)}</results>
let $C31BCount := <results>{
    for $i in $C31Bresults//sparql:result
    where ($i/sparql:binding[@name = "ReportingYear"]/string(sparql:literal) = $reportingYear)
    return
    <result>
        <pollutantName>{$i/sparql:binding[@name = "Pollutant"]/string(sparql:literal)}</pollutantName>
        <count>{$i/sparql:binding[@name = "countOnB"]/string(sparql:literal)}</count>
    </result>
  }</results>

let $C31Result :=
    <results> {
        for $x in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget[not(../string(aqd:objectiveType) = ("http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO", "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ECO"))]
            let $pollutant := $x/../../../../../aqd:pollutant/@xlink:href
            let $zone := $x/../../../../../aqd:zone/@xlink:href
            let $protectiontarget := $x/@xlink:href
            let $key := string-join(($zone, $pollutant, $protectiontarget), "#")
            group by $pollutant
            return
                <result>
                    <pollutantName>{dd:getNameFromPollutantCode($pollutant)}</pollutantName>
                    <pollutantCode>{tokenize($pollutant, "/")[last()]}</pollutantCode>
                    <count>{ count($key) }</count>
                </result>}
    </results>
let $C31Result := filter:filterByName($C31Result, "pollutantCode", (
    "1","7","8","9","5", "6001", "10", "20", "5012", "5018", "5014", "5015", "5029"
))

(: C32 :)
let $samplingPointSparqlC32 :=
    if (fn:string-length($countryCode) = 2) then 
        query:getAssessmentTypeSamplingPoint($cdrUrl)
    else 
        "" 
let $aqdSamplingPointAssessMEntTypes := 
    for $i in sparqlx:executeSparqlQuery($samplingPointSparqlC32)
    let $ii := concat($i/sparql:binding[@name='inspireLabel']/sparql:literal, "#", $i/sparql:binding[@name='assessmentType']/sparql:uri)
    return $ii

let $modelSparql :=
    if (fn:string-length($countryCode) = 2) then
        query:getAssessmentTypeModel($cdrUrl)
    else
        ""
let $aqdModelAssessMentTypes := 
    for $i in sparqlx:executeSparqlQuery($modelSparql)
    let $ii := concat($i/sparql:binding[@name='inspireLabel']/sparql:literal, "#", $i/sparql:binding[@name='assessmentType']/sparql:uri)
    return $ii

let $allAssessmentTypes := ($aqdSamplingPointAssessMEntTypes, $aqdModelAssessMentTypes)

let $tblC32 :=
    for $sMetadata in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata
        let $id := string($sMetadata/@xlink:href)
        let $docType := string($sMetadata/../aqd:assessmentType/@xlink:href)
        let $regimeId := string($sMetadata/../../../@gml:id)
        return 
             if (not(xmlconv:isValidAssessmentTypeCombination($id, $docType, $allAssessmentTypes))) then
                <tr>
                   <td title="AQD_AssessmentRegime">{$regimeId}</td>
                   <td title="aqd:samplingPointAssessmentMetadata">{$id}</td>
                   <td title="aqd:assessmentType">{substring-after($docType, $vocabulary:ASSESSMENTTYPE_VOCABULARY)}</td>
               </tr>
            else
                ()
        

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
                        html:getErrorTD(data($endPosition), "gml:endPosition", fn:true())
                    ,<td title="aqd:AQD_SamplingPoint/ @gml:id"/>, <td title="gml:endPosition"/>)
                else if ($assessmentMetadata/local-name() = 'samplingPointAssessmentMetadata') then
                    (<td title="aqd:AQD_Model/ @gml:id"/>, <td title="gml:endPosition"/>,
                        <td title="aqd:AQD_SamplingPoint/ @gml:id">{data($assessmentMetadata/aqd:AQD_SamplingPoint/@gml:id)}</td>,
                        html:getErrorTD(data($endPosition), "gml:endPosition", fn:true())
                    )
                else
                    ()
            }

        </tr>


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
                        html:getErrorTD(data($used), "aqd:used", fn:true())
                    ,<td title="aqd:AQD_SamplingPoint/ @gml:id"/>, <td title="aqd:usedAQD"/>)
                else if ($assessmentMetadata/local-name() = 'samplingPointAssessmentMetadata') then
                    (<td title="aqd:AQD_Model/ @gml:id"/>, <td title="aqd:used"/>,
                        <td title="aqd:AQD_SamplingPoint/ @gml:id">{data($assessmentMetadata/aqd:AQD_SamplingPoint/@gml:id)}</td>,
                        html:getErrorTD(data($used), "aqd:usedAQD", fn:true())
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

(: C38 :)

let $resultXml := if (fn:string-length($countryCode) = 2) then xmlconv:getSamplingPointInspireLabel($cdrUrl) else ""
let $isInspireLebelCodesAvailable := string-length($resultXml) > 0 and doc-available(sparqlx:getSparqlEndpointUrl($resultXml, "xml"))
let $aqdSamplingPointID := if($isInspireLebelCodesAvailable) then distinct-values(data(sparqlx:executeSparqlQuery($resultXml)//sparql:binding[@name='inspireLabel']/sparql:literal)) else ""
let $isInspireLebelCodesAvailable := count($resultXml) > 0


let $aqdSamplingPointAssessmentMetadata :=
    for $aqdAssessmentRegime in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric
    where $aqdAssessmentRegime/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AEI"
return  $aqdAssessmentRegime/../../../../../aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata/fn:normalize-space(@xlink:href)

let $invalidAqdReportingMetricTest :=
for $x in $aqdSamplingPointAssessmentMetadata
where empty(index-of($aqdSamplingPointID, $x))
return $x

(: 40 :)
let $invalidsamplingPointAssessmentMetadata40 :=
    for $aqdPollutantC40 in $docRoot//aqd:AQD_AssessmentRegime
        let $pollutantXlinkC40 := fn:substring-after(data($aqdPollutantC40/aqd:pollutant/@xlink:href),"pollutant/")
    where not(empty(index-of($xmlconv:VALID_POLLUTANT_IDS_40,$pollutantXlinkC40)))
    return if (count($aqdPollutantC40/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata)>=1
        or count($aqdPollutantC40/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:modelAssessmentMetadata)>=1) then () else $aqdPollutantC40/@gml:id

(: C41 gml:timePosition MUST be provided and must be equal or greater than (aqd:reportingPeriod – 5 years) included in the ReportingHeader :)
    let $C41minYear := xs:integer($reportingYear) - 5
    let $C41invalid :=
        for $x in $docRoot//aqd:AQD_AssessmentRegime[aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:classificationDate/gml:TimeInstant[gml:timePosition castable as xs:integer]/xs:integer(gml:timePosition) < $C41minYear]
        return
            <tr>
                <td title="aqd:AQD_AssessmentRegime/aqd:inspireId/base:Identifier/base:localId">{string($x/aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title=""></td>
            </tr>
(: C42 :)
    let $C42invalid :=
        for $x in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:classificationReport
        where (string($x) = "") or (not(common:includesURL($x)))
        return
            <tr>
                <td title="base:localId">{$x/../../../aqd:inspireId/base:Identifier/base:localId}</td>             
            </tr>


return
    <table class="maintable hover">
        {html:buildResultRows("C1", $labels:C1, $labels:C1_SHORT, (), (), "", string($countRegimes), "", "","warning", $tblAllRegimes)}
        {html:buildResultRows("C4", $labels:C4, $labels:C4_SHORT, $invalidDuplicateGmlIds, (), "@gml:id", "No duplicates found", " duplicate", "","error",())}
        {html:buildResultRows("C5", $labels:C5, $labels:C5_SHORT, $invalidDuplicateLocalIds, (), "base:localId", "No duplicates found", " duplicate", "","error", ())}
        {html:buildResultRows("C6", $labels:C6, $labels:C6_SHORT, (), (), "", string(count($tblC6)), "", "","info",$tblC6)}
        {html:buildResultRows("C6.1", $labels:C6.1, $labels:C6.1_SHORT, $invalidNamespaces, (), "base:Identifier/base:namespace", "All values are valid", " invalid namespaces", "", "error", ())}
        
        {html:buildResultRows("C7", $labels:C7, $labels:C7_SHORT, $invalidAssessmentRegim,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "","error", ())}
        {xmlconv:buildPollutantResultRows("C8",
                $missingPollutantC8, " missing pollutant", "warning", xmlconv:buildVocItemRows($vocabulary:POLLUTANT_VOCABULARY, $missingPollutantC8))}
        {html:buildResultRows("C9", $labels:C9, $labels:C9_SHORT, (), (), "", string(count($foundPollutantC9)), "", "", "info", xmlconv:buildVocItemRows($vocabulary:POLLUTANT_VOCABULARY, $foundPollutantC9))}
        {html:buildResultRows("C10", <span>Where ./aqd:pollutant resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/1 the 3 elements within ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/may only resolve to the following combinations {xmlconv:buildItemsList("C10","", $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C10)}</span>,
                $labels:C10_SHORT, $invalidAqdAssessmentRegimeAqdPollutant,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "","error", ())}
        {html:buildResultRows("C11", <span> Where ./aqd:pollutant resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/7 the 3 elements within ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/may only resolve to the following combinations {xmlconv:buildItemsList("C11","", $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C11)}</span>,
                $labels:C11_SHORT, $invalidAqdAssessmentRegimeAqdPollutantC11,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "","error", ())}
        {html:buildResultRows("C12", <span>Where ./aqd:pollutant resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/8 the22 3 elements within ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/may only resolve to the following combinations {xmlconv:buildItemsList("C12","", $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C12)}</span>,
                $labels:C12_SHORT, $invalidAqdAssessmentRegimeAqdPollutantC12,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "","error", ())}
        {html:buildResultRows("C13", <span>Where ./aqd:pollutant resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/9 the 3 elements within ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/may only resolve to the following combinations {xmlconv:buildItemsList("C13","", $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C13)}</span>,
                $labels:C13_SHORT, $invalidAqdAssessmentRegimeAqdPollutantC13,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "","error", ())}
        {html:buildResultRows("C14", <span>Where ./aqd:pollutant resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5 the 3 elements within ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/may only resolve to the following combinations {xmlconv:buildItemsList("C14","", $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C14)}</span>,
                $labels:C14_SHORT, $invalidAqdAssessmentRegimeAqdPollutantC14,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "","error", ())}
        {html:buildResultRows("C15", <span>Where ./aqd:pollutant resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001 the 3 elements within ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/may only resolve to the following combinations {xmlconv:buildItemsList("C15","", $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C15)}</span>,
                $labels:C15_SHORT, $invalidAqdAssessmentRegimeAqdPollutantC15,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "","error", ())}
        {html:buildResultRows("C16", <span>Where ./aqd:pollutant resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/10 the 3 elements within ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/may only resolve to the following combinations {xmlconv:buildItemsList("C16","", $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C16)}</span>,
                $labels:C16_SHORT, $invalidAqdAssessmentRegimeAqdPollutantC16,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "","error", ())}

        {html:buildResultRows("C17", <span>Where ./aqd:pollutant resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5012  or http://dd.eionet.europa.eu/vocabulary/aq/pollutant/20 the 3 elements within ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/may only resolve to the following combinations{xmlconv:buildItemsList("C17","", $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C17)}</span>,
                $labels:C17_SHORT, $invalidAqdAssessmentRegimeAqdPollutantC17,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "","error", ())}
        {html:buildResultRows("C18", <span>Where ./aqd:pollutant resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5014  or http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5018 or http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5015 or http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5029 the 3 elements within ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/may only resolve to the following combinations{xmlconv:buildItemsList("C18","", $xmlconv:VALID_ENVIRONMENTALOBJECTIVE_C18)}</span>,
                $labels:C18_SHORT, $invalidAqdAssessmentRegimeAqdPollutantC18,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "","error", ())}
        {html:buildResultRows("C19", <span>The 3  elements  within ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/ may  only resolve  to  the  following  combination
            aqd:objectiveType xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO aqd:reportingMetric xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean aqd:protectionTarget xlink:href attribute  shall  resolve  to  one  of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/NA where
            <a href="{ $vocabulary:POLLUTANT_VOCABULARY }">{ $vocabulary:POLLUTANT_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("C19", $vocabulary:POLLUTANT_VOCABULARY, $xmlconv:VALID_POLLUTANT_IDS_19)}</span>,
                $labels:C19_SHORT, $invalidAqdAssessmentRegimeAqdPollutantC19, (), "aqd:reportingMetric", "All values are valid", " invalid value", "","warning", ())}
        <!--{xmlconv:buildResultRows("C20", "Where ./aqd:pollutant resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/7 and ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType xlink:href attribute resolve to http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LTO ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:exceedanceAttainment xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/assessmentthresholdexceedance/aboveLTO http://dd.eionet.europa.eu/vocabulary/aq/assessmentthresholdexceedance/belowLTO",
            $invalidAqdAssessmentRegimeAqdPollutantC20,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "","error", ())}-->
        {html:buildResultRows("C20", $labels:C20, $labels:C20_SHORT, $invalidAqdAssessmentRegimeAqdPollutantC20, (), "aqd:reportingMetric", "All values are valid", " invalid value", "","warning", ())}
        <!--{xmlconv:buildResultRows("C22", "Where ./aqd:objectiveType resolves to http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO THEN ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:exceedanceAttainment xlink:href attribute shall resolve to http://dd.eionet.europa.eu/vocabulary/aq/assessmentthresholdexceedance/NA",
                $invalidAqdAssessmentRegimeAqdPollutantC22,(), "aqd:AQD_AssesmentRegime", "All values are valid", " invalid value", "","warning", ())}-->
        {html:buildResultRows("C23a", $labels:C23a, $labels:C23a_SHORT, $invalidAqdAssessmentType,(), "aqd:AQD_AssesmentRegime", "All values are valid", " invalid value", "","error", ())}
        {html:buildResultRows("C23b", $labels:C23b, $labels:C23b_SHORT, $invalid23B,(), "aqd:AQD_AssesmentRegime", "All values are valid", " invalid value", "","warning", ())}
        {html:buildResultRows("C24", $labels:C24, $labels:C24_SHORT, (),(), "", "", " ", "","warning", ())}
        {html:buildResultRows("C25", $labels:C25, $labels:C25_SHORT, (),(), "", "", " ", "","warning", ())}
        {html:buildResultTable("C26", $labels:C26, $labels:C26_SHORT, (), "All values are valid", " invalid value", "","warning", $tblC26)}
        {html:buildResultTable("C27", concat("The  number of unique zones cited by /aqd:AQD_AssessmentRegime (", $countZoneIds2 , ") shall be EQUAL to the number of unique zones in ./aqd:AQD_Zone (", $countZoneIds1, ")"),
            $labels:C27_SHORT, (), "Count of unique zones matches", " not unique zone",  "", "warning", $resultC27)}
        <!--{xmlconv:buildResultRows("C27", concat("aqd:zone xlink:href attribute shall resolve to a traversable link to an AQ zone in /aqd:AQD_Zone reported under cdr.eionet.europa.eu/ZZ/eu/aqd/b/...  The ./aqd:pollutant and ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget within the Assessment Regime shall equal one combination /aqd:AQD_Zone/aqd:pollutants/aqd:Pollutant/aqd:pollutantCode and /aqd:AQD_Zone/aqd:pollutants/aqd:Pollutant/aqd:protectionTarget within  the  linked  zone  aqd:AQD_Zone/aqd:pollutants",
                "Exception : Where ./aqd:pollutant resolves to the list in  C9 and http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001 ./aqd:zone xlink:href attribute MAY resolve to <aqd:zone nilReason='inapplicable'/>"),
                $invalidAqdAssessmentRegimeZone,(),  "aqd:AQD_Model or aqd:AQD_SamplingPoint", "All values are valid", " invalid value", "","warning", ())}-->
        {html:buildResultRows("C28", $labels:C28, $labels:C28_SHORT, $invalidZoneGmlEndPosition,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "","error", ())}
        {html:buildResultTable("C29", concat("aqd:zone xlink:href attribute shall resolve to a traversable link to an AQ zone in /aqd:AQD_Zone reported under cdr.eionet.europa.eu/ZZ/eu/aqd/b/...  The ./aqd:pollutant and ./aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget within the Assessment Regime shall equal one combination /aqd:AQD_Zone/aqd:pollutants/aqd:Pollutant/aqd:pollutantCode and /aqd:AQD_Zone/aqd:pollutants/aqd:Pollutant/aqd:protectionTarget within  the  linked  zone  aqd:AQD_Zone/aqd:pollutants",
                "Exception : Where ./aqd:pollutant resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001 ./aqd:zone xlink:href attribute MAY resolve to <aqd:zone nilReason='inapplicable'/>"),
                $labels:C29_SHORT, (), "All values are valid", " invalid value", "","warning", $tblC29)}
        {html:buildResultC31("C31", $C31Result, $C31BCount)}
        {html:buildResultTable("C32", $labels:C32, $labels:C32_SHORT, (),"All valid", " invalid value",  "","warning", $tblC32)}
        {html:buildResultRows("C33", $labels:C33, $labels:C33_SHORT, $invalidAssessmentGmlEndPosition,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "","error", ())}
        {html:buildResultRows("C35", $labels:C35, $labels:C35_SHORT, $invalidAssessmentUsed,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "","error", ())}
        {html:buildResultRows("C37", $labels:C37, $labels:C37_SHORT, $invalidAqdReportingMetric,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "","warning", ())}
        {html:buildResultRows("C38", $labels:C38, $labels:C38_SHORT, $invalidAqdReportingMetricTest,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "","warning", ())}
        {html:buildResultRows("C40", <span>The total number of /aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata and /aqd:assessmentMethods/aqd:AssessmentMethods/aqd:modelAssessmentMetadata citations within a MS (delivery) shall be GREATER THAN OR EQUAL to 1 where ./aqd:pollutant xlink:href attribute resolves to{xmlconv:buildVocItemsList("C40", $vocabulary:POLLUTANT_VOCABULARY, $xmlconv:VALID_POLLUTANT_IDS_40)}</span>,
                $labels:C40_SHORT, $invalidsamplingPointAssessmentMetadata40,(), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "","warning", ())}
        {html:buildResultRows("C41", $labels:C41, $labels:C41_SHORT, $C41invalid, (), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "","warning", ())}
        {html:buildResultRows("C42", $labels:C42, $labels:C42_SHORT, $C42invalid, (), "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "","warning", ())}
    </table>
};

declare function xmlconv:buildItemsList($ruleId as xs:string, $vocabularyUrl as xs:string, $ids as xs:string*) as element(div) {
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

declare function xmlconv:buildVocItemsList($ruleId as xs:string, $vocabularyUrl as xs:string, $ids as xs:string*) as element(div) {
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

declare function xmlconv:buildPollutantResultRows($ruleCode as xs:string,  $invalidStrValues as xs:string*, $invalidMsg as xs:string, $errorLevel as xs:string, $recordDetails as element(tr)*) as element(tr)* {

    let $msg :=
        if (count($invalidStrValues) > 0) then
            "Assessment regime(s) not found for the following pollutant(s):"
        else
            "Assessment regimes reported for all expected pollutants"

    return
        html:buildResultRows($ruleCode, <span>{$msg}</span>, <span>{$msg}</span>, $invalidStrValues, (),
                "", "", " missing pollutant", "","warning", xmlconv:buildVocItemRows($vocabulary:POLLUTANT_VOCABULARY, $invalidStrValues))
};

declare function xmlconv:buildVocItemRows($vocabularyUrl as xs:string, $codes as xs:string*) as element(tr)* {
    for $code in $codes
    let $vocLink := concat($vocabularyUrl, $code)
    return
        <tr>
            <td title="Pollutant"><a href="{$vocLink}">{$vocLink}</a></td>
        </tr>
};

declare function xmlconv:reChangeCountrycode($countryCode as xs:string)
as xs:string {
    if ($countryCode = "uk") then "gb" else if ($countryCode = "el") then "gr" else $countryCode
};


(:
 : ======================================================================
 : Main function
 : ======================================================================
 :)
declare function xmlconv:proceed($source_url as xs:string, $countryCode as xs:string) {

let $doc := doc($source_url)
let $bDir := if (contains($source_url, "c_preliminary")) then "b_preliminary/" else "b/"
let $countZones := count($doc//aqd:AQD_AssessmentRegime)
let $result := if ($countZones > 0) then xmlconv:checkReport($source_url, $countryCode, $bDir) else ()

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
                    <p class="error" style="color:red"><strong>This XML file did NOT pass the following crucial check(s): {string-join($result//div[@class = 'error'], ',')}</strong></p>
                else
                    <p>This XML file passed all crucial checks.</p>
            }
            {
                if ($result//div/@class = 'warning') then
                    <p class="warning" style="color:orange"><strong>This XML file generated warnings during the following check(s): {string-join($result//div[@class = 'warning'], ',')}</strong></p>
                else
                    ()
            }
            <p>This check evaluated the delivery by executing tier-1 tests on air quality assessment regimes data in Dataflow C as specified in <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a>.</p>
            <div><a id='legendLink' href="javascript: showLegend()" style="padding-left:10px;">How to read the test results?</a></div>
            <fieldset style="font-size: 90%; display:none" id="legend">
                <legend>How to read the test results</legend>
                All test results are labeled with coloured bullets. The number in the bullet reffers to the rule code. The background colour of the bullets means:
                <ul style="list-style-type: none;">
                    <li><div style="width:50px; display:inline-block;margin-left:10px">{html:getBullet('Blue', 'info')}</div> - the data confirms to the rule, but additional feedback could be provided in QA result.</li>
                    <li><div style="width:50px; display:inline-block;margin-left:10px">{html:getBullet('Red', 'error')}</div> - the crucial check did NOT pass and errenous records found from the delivery.</li>
                    <li><div style="width:50px; display:inline-block;margin-left:10px">{html:getBullet('Orange', 'warning')}</div> - the non-crucial check did NOT pass.</li>
                    <li><div style="width:50px; display:inline-block;margin-left:10px">{html:getBullet('Grey', 'skipped')}</div> - the check was skipped due to no relevant values found to check.</li>
                </ul>
                <p>Click on the "Show records" link to see more details about the test result.</p>
            </fieldset>
            <h3>Test results</h3>
            {$result}
        </div>
        }
    </div>
};

declare function xmlconv:isValidAssessmentTypeCombination($id as xs:string, $type as xs:string, $allCombinations as xs:string*) as xs:boolean {
    let $typeInDoc := lower-case(substring-after($type, $vocabulary:ASSESSMENTTYPE_VOCABULARY))
    let $combination := concat($id, "#", $type)
    let $combinationFixed := concat($id, "#", $vocabulary:ASSESSMENTTYPE_VOCABULARY, "fixed")
    let $combinationIndicative := concat($id, "#", $vocabulary:ASSESSMENTTYPE_VOCABULARY, "indicative")
    let $combinationModel := concat($id, "#", $vocabulary:ASSESSMENTTYPE_VOCABULARY, "model")
    let $combinationObjective := concat($id, "#", $vocabulary:ASSESSMENTTYPE_VOCABULARY, "objective")
    
    let $combinationOk := 
        if ($typeInDoc = ("fixed", "model")) then
            if ($combination = $allCombinations) then
                true()
            else
                false()
        else if ($typeInDoc = "indicative") then
            if ($allCombinations = ($combinationFixed, $combinationIndicative)) then
                true()
            else
                false()
        else if ($typeInDoc = "objective") then
            if ($allCombinations = ($combinationFixed, $combinationIndicative, $combinationModel, $combinationObjective)) then
                true()
            else
                false()   
        else
            false()
    return $combinationOk
};