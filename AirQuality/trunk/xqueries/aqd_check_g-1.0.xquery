xquery version "1.0" encoding "UTF-8";
(:
 : Module Name: Implementing Decision 2011/850/EU: AQ info exchange & reporting (Main module)
 :
 : Version:     $Id$
 : Created:     13 September 2013
 : Copyright:   European Environment Agency
 :)
(:~
 : XQuery script implements dataflow G tier-1 checks as documented in http://taskman.eionet.europa.eu/documents/3 .
 :
 : @author Enriko Käsper
 :)

declare namespace xmlconv = "http://converters.eionet.europa.eu";
declare namespace aqd = "http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0";
declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace am = "http://inspire.ec.europa.eu/schemas/am/3.0";
declare namespace ef = "http://inspire.ec.europa.eu/schemas/ef/3.0rc3";

declare namespace ns = "http://inspire.ec.europa.eu/schemas/base/3.3";
declare namespace gn = "urn:x-inspire:specification:gmlas:GeographicalNames:3.0";
declare namespace  base = "http://inspire.ec.europa.eu/schemas/base/3.3rc3/";


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


declare variable $xmlconv:VALID_POLLUTANT_IDS as xs:string* := ("1", "7", "8", "9", "5", "6001", "10","20", "5012", "5014", "5015", "5018", "5029");
declare variable $xmlconv:VALID_POLLUTANT_IDS_27 as xs:string* := ("5", "8", "6001", "10","20", "5012", "5014", "5015", "5018", "5029");
declare variable $xmlconv:VALID_REPMETRIC_IDS as xs:string* := ("aMean", "wMean", "hrsAbove", "daysAbove");
declare variable $xmlconv:VALID_REPMETRIC_IDS_20 as xs:string* := ("aMean", "wMean", "hrsAbove", "daysAbove","daysAbove-3er", "maxd8hrMean", "AOT40c", "AOT40c-5yr", "AEI");
declare variable $xmlconv:VALID_REPMETRIC_IDS_24 as xs:string* := ("aMean", "daysAbove");
declare variable $xmlconv:VALID_REPMETRIC_IDS_25 as xs:string* := ("aMean");
declare variable $xmlconv:VALID_REPMETRIC_IDS_26 as xs:string* := ("daysAbove");
declare variable $xmlconv:VALID_REPMETRIC_IDS_31 as xs:string* := ("AOT40c", "AOT40c-5yr");
declare variable $xmlconv:VALID_AREACLASSIFICATION_IDS as xs:string* := ("1", "2", "3", "4", "5", "6");
declare variable $xmlconv:VALID_AREACLASSIFICATION_IDS_52 as xs:string* := ("rural","rural-nearcity","rural-regional","rural-remote","urban","suburban");
declare variable $xmlconv:VALID_OBJECTIVETYPE_IDS as xs:string* := ("TV", "LV", "CL","LTO","ECO","LVmaxMOT","INT","ALT");
declare variable $xmlconv:VALID_OBJECTIVETYPE_IDS_32 as xs:string* := ("TV", "LV","LVmaxMOT");
declare variable $xmlconv:VALID_OBJECTIVETYPE_IDS_33 as xs:string* := ("LV");
declare variable $xmlconv:VALID_ADJUSTMENTTYPE_IDS as xs:string* := ("sCorrection","wssCorrection");
declare variable $xmlconv:VALID_ADJUSTMENTSOURCE_IDS as xs:string* := ("A1","A2","B","B1","B2","C1","C2","D1","D2","E1","E2","F1","F2","G1","G2","H");
declare variable $xmlconv:VALID_ASSESSMENTTYPE_IDS as xs:string* := ("fixed","model","indicative","objective");
declare variable $xmlconv:VALID_PROTECTIONTARGET_IDS as xs:string* := ("H-S1","H-S2");



declare variable $xmlconv:POLLUTANT_VOCABULARY as xs:string := "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/";
declare variable $xmlconv:REPMETRIC_VOCABULARY as xs:string := "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/";
declare variable $xmlconv:OBJECTIVETYPE_VOCABULARY as xs:string := "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/";
declare variable $xmlconv:AREACLASSIFICATION_VOCABULARY as xs:string := "http://dd.eionet.europa.eu/vocabulary/aq/areaclassification/";
declare variable $xmlconv:ADJUSTMENTTYPE_VOCABULARY as xs:string := "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/";
declare variable $xmlconv:ADJUSTMENTSOURCE_VOCABLUARY as xs:string := "http://dd.eionet.europa.eu/vocabulary/aq/adjustmentsourcetype/";
declare variable $xmlconv:ASSESSMENTTYPE_VOCABLUARY as xs:string := "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/";
declare variable $xmlconv:PROTECTIONTARGET_VOCABLUARY as xs:string := "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/";
declare variable $source_url as xs:string external;
(:)
declare variable $source_url as xs:string external;
:)
(:
declare variable $source_url as xs:string := "http://cdrtest.eionet.europa.eu/es/eu/aqd/g/envvbgwea/ES_G_Attainment.xml";
declare variable $source_url := "http://cdrtest.eionet.europa.eu/hr/eu/aqd/g/envu_2xna/HR_G_201407281307.xml";
declare variable $source_url := "http://cdrtest.eionet.europa.eu/hr/eu/aqd/g/envu_2xna/HR_G_201407281307.xml";
declare variable $source_url := "../test/2_HR_G_201407281307.xml";
declare variable $source_url := "../test/ES_G_Attainment.xml";
declare variable $source_url := "../test/G_GB_Attainment_2012_v1.4.xml";
declare variable $source_url := "../test/HR_G_201407281307.xml";
Change it for testing locally:
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
             ""
(:              "http://cdrtest.eionet.europa.eu/ee/eu/art17/envriytkg/xml" :)
};


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
(:~
 : Checks if XML element is missing or not.
 : @param $node XML node
 : return Boolean value.
 :)
declare function xmlconv:isMissing($node as node()*)
as xs:boolean
{
    if (fn:count($node) = 0) then
        fn:true()
    else
        fn:false()
};
(:~
 : Checks if XML element is missing or value is empty.
 : @param $node XML element or value
 : return Boolean value.
 :)
declare function xmlconv:isMissingOrEmpty($node as item()*)
as xs:boolean
{
    if (xmlconv:isMissing($node)) then
        fn:true()
    else
        xmlconv:isEmpty(string-join($node, ""))
};
(:~
 : Checks if element value is empty or not.
 : @param $value Element value.
 : @return Boolean value.
 :)
declare function xmlconv:isEmpty($value as xs:string)
as xs:boolean
{
    if (fn:empty($value) or fn:string(fn:normalize-space($value)) = "") then
        fn:true()
    else
        fn:false()
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
    let $uri :=  xmlconv:getSparqlEndpointUrl($sparql, "xml") (:"E:/sparql-result-1.xml":)

    return fn:doc($uri)//sparql:results
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

};
declare function xmlconv:getTimeExtensionExemption($countryCode as xs:string)
as xs:string
{
concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
        PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

        SELECT ?zone ?timeExtensionExemption ?localId
        WHERE {
                ?zone a aqd:AQD_Zone ;
                aqd:timeExtensionExemption ?timeExtensionExemption .
                ?zone aqd:inspireId ?inspireid .
                ?inspireid aqd:localId ?localId
        FILTER (STRSTARTS(str(?zone), 'http://cdr.eionet.europa.eu/",$countryCode,"/eu/aqd/b/') and (?timeExtensionExemption != 'http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/none'))
      } LIMIT 500")
};

declare function xmlconv:getAqdZone($countryCode as xs:string)
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
FILTER (STRSTARTS(str(?zone), 'http://cdr.eionet.europa.eu/", $countryCode,"/eu/aqd/b/') and (?timeExtensionExemption != ""))
} LIMIT 500")

};

declare function xmlconv:getLocallD($countryCode as xs:string)
as xs:string
{
concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
        PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

       SELECT ?zone ?inspireId ?localId
       WHERE {
              ?zone a aqd:AQD_AssessmentRegime ;
              aqd:inspireId ?inspireId .
              ?inspireId aqd:localId ?localId .
       FILTER (STRSTARTS(str(?zone), 'http://cdr.eionet.europa.eu/", $countryCode, "/eu/aqd/c/'))
   } LIMIT 500")
};

declare function xmlconv:getZoneLocallD($countryCode as xs:string)
as xs:string
{
    concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
        PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

       SELECT ?zone ?inspireId ?localId
       WHERE {
              ?zone a aqd:AQD_Zone ;
              aqd:inspireId ?inspireId .
              ?inspireId aqd:localId ?localId .
       FILTER (STRSTARTS(str(?zone), 'http://cdr.eionet.europa.eu/", $countryCode, "/eu/aqd/b/'))
   } LIMIT 500")
};

declare function xmlconv:getPollutantlD($countryCode as xs:string)
as xs:string
{
    concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
            PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
            PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

          SELECT ?zone ?inspireId ?inspireLabel ?pollutants ?pollutantCode
          WHERE {
                 ?zone a aqd:AQD_Zone ;
                  aqd:inspireId ?inspireId .
                 ?inspireId rdfs:label ?inspireLabel .
                 ?zone aqd:pollutants ?pollutants .
                 ?pollutants aqd:pollutantCode ?pollutantCode .
          FILTER (STRSTARTS(str(?zone), 'http://cdr.eionet.europa.eu/",$countryCode,"/eu/aqd/b/'))
          } LIMIT 500")
    };


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
declare function xmlconv:checkReport($source_url as xs:string)
as element(table) {

(: get reporting country :)
(:
let $countryCode := "hr"
:)
(:
let $countryCode := if ($countryCode = "gb") then "uk" else if ($countryCode = "gr") then "el" else $countryCode
:)
(:
let $countryCode := 'hr'
:)
(: =============================================== FIXME !!! :)

let $envelopeUrl := xmlconv:getEnvelopeXML($source_url)
let $countryCode := if(string-length($envelopeUrl)>0) then lower-case(fn:doc($envelopeUrl)/envelope/countrycode) else ""
(:)let $countryCode := "es":)

let $docRoot := doc($source_url)
(: G1 :)
let $countAttainments := count($docRoot//aqd:AQD_Attainment)
let $tblAllAttainments :=
    for $rec in $docRoot//aqd:AQD_Attainment
    return
        <tr>
            <td title="gml:id">{data($rec/@gml:id)}</td>
            <td title="ns:localId">{data($rec/aqd:inspireId/ns:Identifier/ns:localId)}</td>
            <td title="ns:namespace">{data($rec/aqd:inspireId/ns:Identifier/ns:namespace)}</td>
            <td title="aqd:zone">{xmlconv:checkLink(data($rec/aqd:zone/@xlink:href))}</td>
            <td title="aqd:pollutant">{xmlconv:checkLink(data($rec/aqd:pollutant/@xlink:href))}</td>
            <td title="aqd:protectionTarget">{xmlconv:checkLink(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href))}</td>
        </tr>

(: G2 :)
        (:)let $countAttainments := count($docRoot//aqd:AQD_Attainment)  Vaata B scripti:)

(: G4 :)

let $gmlIds := $docRoot//aqd:AQD_Attainment/lower-case(normalize-space(@gml:id))
let $inspireIds := $docRoot//aqd:AQD_Attainment/lower-case(normalize-space(aqd:inspireId))
let $pollutant := $docRoot//aqd:AQD_Attainment/aqd:pollutant/lower-case(normalize-space(@xlink:href))
let $objectiveType := $docRoot//aqd:AQD_Attainment/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/lower-case(normalize-space(@xlink:href))
let $reportingMetric := $docRoot//aqd:AQD_Attainment/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/lower-case(normalize-space(@xlink:href))
let $protectionTarget := $docRoot//aqd:AQD_Attainment/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/lower-case(normalize-space(@xlink:href))
let $zone := $docRoot//aqd:AQD_Attaiment/aqd:zone/lower-case(normalize-space(@xlink:href))
let $assessment := $docRoot//aqd:AQD_Attaiment/aqd:assessment/lower-case(normalize-space(@xlink:href))


let $uniqueAttainment :=
    for $attainment in $docRoot//aqd:AQD_Attainment
    let $id := $attainment/@gml:id
    let $inspireId := $attainment/aqd:inspireId
    let $pollutantId := $attainment/aqd:pollutant/@xlink:href
    let $objectiveTypeId := $attainment/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href
    let $reportingMetricId := $attainment/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href
    let $protectionTargetId := $attainment/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href
    let $zoneId := $attainment/aqd:zone/@xlink:href
    let $assessmentId := $attainment/aqd:assessment/@xlink:href

    where count(index-of($gmlIds, lower-case(normalize-space($id)))) = 1
            and count(index-of($inspireIds, lower-case(normalize-space($inspireId)))) = 1
            (:) and count(index-of($pollutant, lower-case(normalize-space($pollutantId)))) = 1
            and count(index-of($pollutant, lower-case(normalize-space($pollutantId)))) = 1
            and count(index-of($objectiveType, lower-case(normalize-space($objectiveTypeId)))) = 1
            and count(index-of($reportingMetric, lower-case(normalize-space($reportingMetricId)))) = 1
            and count(index-of($protectionTarget, lower-case(normalize-space($protectionTargetId)))) = 1
            and count(index-of($zone, lower-case(normalize-space($zoneId)))) = 1
            and count(index-of($assessment, lower-case(normalize-space($assessmentId)))) = 1:)
    return
        $attainment

let $tblAllAttainmentsG4 :=
    for $rec in $docRoot//$uniqueAttainment
    let $aqdinspireId := concat($rec/aqd:inspireId/ns:Identifier/ns:localId,"/",$rec/aqd:inspireId/ns:Identifier/ns:namespace)
return
        <tr>
            <td title="gml:id">{distinct-values($rec/@gml:id)}</td>
            <td title="aqd:inspireId">{distinct-values($aqdinspireId)}</td>
            <td title="aqd:pollutant">{xmlconv:checkLink(distinct-values(data($rec/aqd:pollutant/@xlink:href)))}</td>
            <td title="aqd:objectiveType">{xmlconv:checkLink(distinct-values(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href)))}</td>
            <td title="aqd:reportingMetric">{xmlconv:checkLink(distinct-values(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href)))}</td>
            <td title="aqd:protectionTarget">{xmlconv:checkLink(distinct-values(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href)))}</td>
            <td title="aqd:zone">{xmlconv:checkLink(distinct-values(data($rec/aqd:zone/@xlink:href)))}</td>
            <td title="aqd:assessment">{xmlconv:checkLink(distinct-values(data($rec/aqd:assessment/@xlink:href)))}</td>
        </tr>

(: G5 Compile & feedback a list of the exceedances situations based on the content of
 ./aqd:zone, ./aqd:pollutant, ./aqd:objectiveType, ./aqd:reportingMetric, ./aqd:protectionTarget, aqd:exceedanceDescription_Final/aqd:ExceedanceDescription/aqd:exceedance :)
let $countExceedances := count($docRoot//aqd:AQD_Attainment[xs:integer(aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:numberExceedances) gt 0])
let $allExceedances :=
    for $attainment in $docRoot//aqd:AQD_Attainment
    where xs:integer($attainment/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:numberExceedances) gt 0
    return
        $attainment

let $tblAllExceedances :=
    for $rec in $allExceedances
    return
        <tr>
            <td title="aqd:zone">{xmlconv:checkLink(data($rec/aqd:zone/@xlink:href))}</td>
            <td title="aqd:pollutant">{xmlconv:checkLink(data($rec/aqd:pollutant/@xlink:href))}</td>
            <td title="aqd:objectiveType">{xmlconv:checkLink(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href))}</td>
            <td title="aqd:reportingMetric">{xmlconv:checkLink(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href))}</td>
            <td title="aqd:protectionTarget">{xmlconv:checkLink(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href))}</td>
            <td title="aqd:exceedance">{data($rec/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedance)}</td>
            <td title="aqd:numberExceedances">{data($rec/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:numberExceedances)}</td>
        </tr>

(: G6 :)

let $resultXml := if (fn:string-length($countryCode) = 2) then xmlconv:getAqdZone($countryCode) else ""
let $isAqdZoneCodesAvailable := string-length($resultXml) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultXml, "xml"))
let $localId := if($isAqdZoneCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='localId']/sparql:literal)) else ""
let $timeExtensionExemption := if($isAqdZoneCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='timeExtensionExemption']/sparql:uri)) else ""
let $isAqdZoneCodesAvailable := count($resultXml) > 0

let $aqdObjectiveType :=
   for $x in $docRoot//aqd:AQD_Attainment
    let $href := if (xmlconv:isMissingOrEmpty($x/aqd:zone/@xlink:href)) then "" else data($x/aqd:zone/@xlink:href)
    where $isAqdZoneCodesAvailable and $href != "" and not(empty($localId)) and empty(index-of($localId, $href)) = false()
    return if ($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVmaxMOT")  then  $x else ()
let $tblAllAttainment :=
    for $rec in $aqdObjectiveType
    return
        <tr>
            <td title="aqd:zone">{xmlconv:checkLink(data($rec/aqd:zone/@xlink:href))}</td>
            <td title="aqd:inspireId">{xmlconv:checkLink(data(concat($rec/aqd:inspireId/ns:Identifier/ns:localId,"/",$rec/aqd:inspireId/ns:Identifier/ns:namespace)))}</td>
            <td title="aqd:pollutant">{xmlconv:checkLink(data($rec/aqd:pollutant/@xlink:href))}</td>
            <td title="aqd:objectiveType">{xmlconv:checkLink(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href))}</td>
            <td title="aqd:reportingMetric">{xmlconv:checkLink(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href))}</td>
            <td title="aqd:protectionTarget">{xmlconv:checkLink(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href))}</td>

        </tr>



(: G7 duplicate @gml:ids and aqd:inspireIds and ef:inspireIds :)
(: Feedback report shall include the gml:id attribute, ef:inspireId, aqd:inspireId, ef:name and/or ompr:name elements as available. :)
let $gmlIds := $docRoot//aqd:AQD_Attainment/lower-case(normalize-space(@gml:id))
let $inspireIds := $docRoot//aqd:AQD_Attainment/lower-case(normalize-space(aqd:inspireId))
let $efInspireIds := $docRoot//aqd:AQD_Attainment/lower-case(normalize-space(ef:inspireId))

let $invalidDuplicateGmlIds :=
    for $attainment in $docRoot//aqd:AQD_Attainment
    let $id := $attainment/@gml:id
    let $inspireId := $attainment/aqd:inspireId
    let $efInspireId := $attainment/ef:inspireId
    where count(index-of($gmlIds, lower-case(normalize-space($id)))) > 1
        or count(index-of($inspireIds, lower-case(normalize-space($inspireId)))) > 1
        or (count(index-of($efInspireIds, lower-case(normalize-space($efInspireId)))) > 1 and not(empty($efInspireId)))
    return
        $attainment

let $tblDuplicateGmlIds :=
    for $rec in $invalidDuplicateGmlIds
    return
        <tr>
            <td title="gml:id">{data($rec/@gml:id)}</td>
            <td title="ns:localId">{data($rec/aqd:inspireId/ns:Identifier/ns:localId)}</td>
            <td title="ns:namespace">{data($rec/aqd:inspireId/ns:Identifier/ns:namespace)}</td>
            <td title="ns:versionId">{data($rec/aqd:inspireId/ns:Identifier/ns:versionId)}</td>
            <td title="base:localId">{data($rec/ef:inspireId/base:Identifier/base:localId)}</td>
            <td title="base:namespace">{data($rec/ef:inspireId/base:Identifier/base:namespace)}</td>
        </tr>

(: G8 ./ef:inspireId/base:Identifier/base:localId shall be an unique code for the attainment records starting with ISO2-country code :)
let $localIds :=  $docRoot//ef:inspireId/base:Identifier/lower-case(normalize-space(base:localId))[lower-case(substring(data(.),1,2)) = $countryCode]
let $invalidDuplicateLocalIds :=
    for $id in $docRoot//ef:inspireId/base:Identifier/lower-case(normalize-space(base:localId))
    let $recCountry := lower-case(substring($id,1,2))
    where (count(index-of($localIds, lower-case(normalize-space($id)))) > 1 and not(empty($id)))
    return
        $id

(: G9 ./ef:inspireId/base:Identifier/base:namespace shall resolve to a unique namespace identifier for the data source (within an annual e-Reporting cycle). :)
let $namespaces :=  $docRoot//ef:inspireId/base:Identifier/lower-case(normalize-space(base:namespace))
let $duplicateNamespaces :=
    for $id in $docRoot//ef:inspireId/base:Identifier/lower-case(normalize-space(base:namespace))
    where count(index-of($namespaces, lower-case(normalize-space($id)))) > 1 and not(empty($id))
    return
        $id

(: G10 pollutant codes :)
let $invalidPollutantCodes := xmlconv:isinvalidDDConceptLimited("", "aqd:AQD_Attainment", "aqd:pollutant",  $xmlconv:POLLUTANT_VOCABULARY, $xmlconv:VALID_POLLUTANT_IDS)

(: G11 :)

let $invalidExceedanceDescriptionBase :=
        for $exceedanceDescriptionBase in $docRoot//aqd:AQD_Attainment/aqd:pollutant/@xlink:href
        let $pollutantXlinkG11:= fn:substring-after(data($exceedanceDescriptionBase),"pollutant/")
        where empty(index-of(('1','5','6001','10'),$pollutantXlinkG11))
        return if (empty($exceedanceDescriptionBase/../../aqd:exceedanceDescriptionBase))
        then () else $exceedanceDescriptionBase/../../@gml:id

(: G12 :)

let $invalidExceedanceDescriptionAdjustment:=
    for $exceedanceDescriptionAdjustment in $docRoot//aqd:AQD_Attainment/aqd:pollutant/@xlink:href
    let $pollutantXlinkG12:= fn:substring-after(data($exceedanceDescriptionAdjustment),"pollutant/")
    where empty(index-of(('1','5','6001','10'),$pollutantXlinkG12))
    return if (empty($exceedanceDescriptionAdjustment/../../aqd:exceedanceDescriptionAdjustment))
    then () else $exceedanceDescriptionAdjustment/../../@gml:id

(: G13 :)

let $resultXml := if (fn:string-length($countryCode) = 2) then xmlconv:getLocallD($countryCode) else ""
let $isLocallDCodesAvailable := string-length($resultXml) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultXml, "xml"))
let $locallD := if($isLocallDCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='localId']/sparql:literal)) else ""
let $isLocallDCodesAvailable := count($resultXml) > 0

let $invalidAssessment :=
     for $x in $docRoot//aqd:AQD_Attainment/aqd:assessment
    where $isLocallDCodesAvailable
    return  if (empty(index-of($locallD, $x/fn:normalize-space(@xlink:href)))) then $x/../@gml:id else ()

(: G14 :)

(: G15 :)
let $resultXml := if (fn:string-length($countryCode) = 2) then xmlconv:getZoneLocallD($countryCode) else ""
let $isZoneLocallDCodesAvailable := string-length($resultXml) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultXml, "xml"))
let $zoneLocallD := if($isZoneLocallDCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='localId']/sparql:literal)) else ""
let $isZoneLocallDCodesAvailable := count($resultXml) > 0

let $invalidAssessmentZone :=
  for $x in $docRoot//aqd:AQD_Attainment/aqd:zone
    where $isZoneLocallDCodesAvailable
    return  if (empty(index-of($zoneLocallD, $x/fn:normalize-space(@xlink:href)))) then $x/../@gml:id else ()

(: G16 :)
(: /aqd:AQD_Zone/am:designationPeriod/gml:TimePeriod/gml:endPosition  ei leia kus asub:)

(: G17 :)

let $resultXml := if (fn:string-length($countryCode) = 2) then xmlconv:getZoneLocallD($countryCode) else ""
let $isZoneLocallDCodesAvailable := string-length($resultXml) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultXml, "xml"))
let $zoneLocallD := if($isZoneLocallDCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='localId']/sparql:literal)) else ""
let $isZoneLocallDCodesAvailable := count($resultXml) > 0

let $resultSparql := if (fn:string-length($countryCode) = 2) then xmlconv:getPollutantlD($countryCode) else ""
let $isPollutantCodesAvailable := string-length($resultSparql) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultSparql, "xml"))
let $pollutansCode:= if($isPollutantCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultSparql)//sparql:binding[@name='pollutantCode']/sparql:uri)) else ""
let $isPollutantCodesAvailable := count($resultSparql) > 0

let $invalidPollutant :=
    for $x in $docRoot//aqd:AQD_Attainment
    where $isZoneLocallDCodesAvailable and $isPollutantCodesAvailable and (empty(index-of($zoneLocallD, $x/aqd:zone/fn:normalize-space(@xlink:href)))=false())
    return  if (empty(index-of($pollutansCode, $x/aqd:pollutant/fn:normalize-space(@xlink:href)))) then $x/@gml:id else ()

(: G18 :)

let $resultXml := if (fn:string-length($countryCode) = 2) then xmlconv:getTimeExtensionExemption($countryCode) else ""
let $isLocalCodesAvailable := string-length($resultXml) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultXml, "xml"))
let $localId := if($isLocalCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='localId']/sparql:literal)) else ""
let $isLocalCodesAvailable := count($resultXml) > 0

let $invalidObjectiveType :=
for $x in $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType
where $isLocalCodesAvailable and empty(index-of($localId, $x/../../../../../aqd:zone/@xlink:href))=false()
return  if ($x/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVmaxMOT")  then $x/../../../../../@gml:id else ()

(: G19
.//aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType xlink:href attribute shall resolve to one of:)
let $invalidObjectiveTypes := xmlconv:isinvalidDDConceptLimited("", "aqd:EnvironmentalObjective", "aqd:objectiveType", $xmlconv:OBJECTIVETYPE_VOCABULARY, $xmlconv:VALID_OBJECTIVETYPE_IDS)

(: G20 - ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric xlink:href attribute shall resolve to one of
... :)
let $invalidReportingMetric := xmlconv:isinvalidDDConceptLimited("", "aqd:EnvironmentalObjective", "aqd:reportingMetric",
    $xmlconv:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS_20)


(: G21
WHERE
./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType xlink:href attribute
EQUALS http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL
./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget xlink:href attribute
EQUALS http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V

:)
let $invalidobjectiveTypesForVEG :=
    for $obj in $docRoot//aqd:environmentalObjective/aqd:EnvironmentalObjective
    where
        $obj/aqd:protectionTarget/@xlink:href != 'http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V'
        and $obj/aqd:objectiveType/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL'
   return
        <tr>
            <td title="gml:id">{data($obj/../../@gml:id)}</td>
            <td title="aqd:protectionTarget">{data($obj/aqd:protectionTarget/@xlink:href)}</td>
            <td title="aqd:objectiveType">{data($obj/aqd:objectiveType/@xlink:href)}</td>
        </tr>

(: 22 :)
let $invalidobjectiveTypesForVEGG22 :=
    for $obj in $docRoot//aqd:environmentalObjective/aqd:EnvironmentalObjective
    let $isInvalid :=
        $obj/aqd:protectionTarget/@xlink:href != 'http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H'
        and ($obj/aqd:objectiveType/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV'
        or $obj/aqd:objectiveType/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV')
    where $isInvalid
    return
        <tr>
            <td title="gml:id">{data($obj/../../@gml:id)}</td>
            <td title="aqd:protectionTarget">{data($obj/aqd:protectionTarget/@xlink:href)}</td>
            <td title="aqd:objectiveType">{data($obj/aqd:objectiveType/@xlink:href)}</td>
        </tr>


(: 23 :)
let $invalidAqdReportingMetric :=
    for $aqdReportingMetric in $docRoot//aqd:AQD_Attainment
    let $reportingXlink:= fn:substring-after(data($aqdReportingMetric/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/fn:normalize-space(@xlink:href)),"reportingmetric/")
    where empty(index-of(data($aqdReportingMetric/aqd:pollutant/fn:normalize-space(@xlink:href)),"http://dd.eionet.europa.eu/vocabulary/aq/pollutant/1"))=false()
    return  if (empty(index-of(('daysAbove','hrsAbove','wMean','aMean'),$reportingXlink))) then $aqdReportingMetric/@gml:id else ()

(: 24 :)
let $invalidAqdReportingMetricG24 :=
    for $aqdReportingMetricG24 in $docRoot//aqd:AQD_Attainment
    let $reportingXlink:= fn:substring-after(data($aqdReportingMetricG24/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/fn:normalize-space(@xlink:href)),"reportingmetric/")
    where empty(index-of(data($aqdReportingMetricG24/aqd:pollutant/fn:normalize-space(@xlink:href)),"http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5"))=false()
    return  if (empty(index-of(('daysAbove','aMean'),$reportingXlink))) then $aqdReportingMetricG24/@gml:id else ()

(: G25 /aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:surfaceArea uom attribute shall be “km2”
let $invalidSurfaceAreas :=
    for $obj in $docRoot//aqd:AQD_Attainment
    let $uom := $obj//aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:surfaceArea/@uom
    where not(empty($uom)) and lower-case(data($uom)) != 'km2'
    return $obj

let $tblInvalidSurfaceAreas :=
   for $rec in $invalidSurfaceAreas
   return
        <tr>
            <td title="gml:id">{data($rec/@gml:id)}</td>
            <td title="aqd:protectionTarget">{data($rec/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:surfaceArea/@uom)}</td>
        </tr> :)
(: G25 :)

let $invalidAqdReportingMetricG25 :=
    for $aqdReportingMetricG25 in $docRoot//aqd:AQD_Attainment
    let $reportingXlink:= fn:substring-after(data($aqdReportingMetricG25/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/fn:normalize-space(@xlink:href)),"reportingmetric/")
    where empty(index-of(data($aqdReportingMetricG25/aqd:pollutant/fn:normalize-space(@xlink:href)),"http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001"))=false()
    return  if (empty(index-of(('aMean'),$reportingXlink))) then $aqdReportingMetricG25/@gml:id else ()

(: G26 /aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:roadLength uom attribute shall be “km”
let $invalidRoadLengths :=
    for $obj in $docRoot//aqd:AQD_Attainment
    let $uom := $obj//aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:roadLength/@uom
    where not(empty($uom)) and lower-case(data($uom)) != 'km'
    return $obj

let $tblinvalidRoadLengths :=
   for $rec in $invalidRoadLengths
   return
        <tr>
            <td title="gml:id">{data($rec/@gml:id)}</td>
            <td title="aqd:protectionTarget">{data($rec/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:roadLength/@uom)}</td>
        </tr>:)

(: G26 :)

let $invalidAqdReportingMetricG26 :=
    for $aqdReportingMetricG26 in $docRoot//aqd:AQD_Attainment
    let $reportingXlink:= fn:substring-after(data($aqdReportingMetricG26/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/fn:normalize-space(@xlink:href)),"reportingmetric/")
    where empty(index-of(data($aqdReportingMetricG26/aqd:pollutant/fn:normalize-space(@xlink:href)),"http://dd.eionet.europa.eu/vocabulary/aq/pollutant/10"))=false()
    return  if (empty(index-of(('daysAbove'),$reportingXlink))) then $aqdReportingMetricG26/@gml:id else ()

(: G27/aqd:AQD_Attainment
   /aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:areaClassification xlink:href attribute shall resolve to
...
let $invalidClassification :=
    xmlconv:checkVocabularyConceptValues("aqd:exceedanceDescriptionBase", "aqd:ExceedanceArea", "aqd:areaClassification", $xmlconv:AREACLASSIFICATION_VOCABULARY) :)

(: G27 :)
let $invalidAqdReportingMetricG27 :=
      for $aqdReportingMetricG27 in $docRoot//aqd:AQD_Attainment
      let $reportingXlink:= fn:substring-after(data($aqdReportingMetricG27/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/fn:normalize-space(@xlink:href)),"protectiontarget/")
        where   $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/10"
            or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001"
            or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href)= "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5"
            or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/8"
            or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/20"
            or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5012"
            or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5014"
            or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5015"
            or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5018"
            or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5029"
    return  if (empty(index-of("V",$reportingXlink))) then $aqdReportingMetricG27/@gml:id  else ()



 (: 30 :)

let $invalidobjectiveTypesForCriticalL :=
    for $obj in $docRoot//aqd:environmentalObjective/aqd:EnvironmentalObjective
    where
        $obj/aqd:protectionTarget/@xlink:href != 'http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V'
                and $obj/aqd:objectiveType/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL'
    return
        <tr>
            <td title="gml:id">{data($obj/../../@gml:id)}</td>
            <td title="aqd:protectionTarget">{data($obj/aqd:protectionTarget/@xlink:href)}</td>
            <td title="aqd:objectiveType">{data($obj/aqd:objectiveType/@xlink:href)}</td>
        </tr>

(: G31 :)

let $invalidobjectiveTypesForAOT31 :=
    for $obj in $docRoot//aqd:environmentalObjective/aqd:EnvironmentalObjective
    let $isInvalid :=
        $obj/aqd:protectionTarget/@xlink:href != 'http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V'
         and ($obj/aqd:reportingMetric/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AOT40c'
          or $obj/aqd:reportingMetric/@xlink:href ='http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AOT40c-5y')
    where $isInvalid
    return
        <tr>
            <td title="gml:id">{data($obj/../../@gml:id)}</td>
            <td title="aqd:protectionTarget">{data($obj/aqd:protectionTarget/@xlink:href)}</td>
            <td title="aqd:objectiveType">{data($obj/aqd:objectiveType/@xlink:href)}</td>
        </tr>

(: G32 :)

let $invalidobjectiveTypesForHealth :=
    for $obj in $docRoot//aqd:environmentalObjective/aqd:EnvironmentalObjective
     let $isInvalid :=
        $obj/aqd:protectionTarget/@xlink:href != 'http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H'
                and $obj/../../aqd:pollutant/@xlink:href != 'http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001'
                and ($obj/aqd:objectiveType/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV'
                 or $obj/aqd:objectiveType/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV'
                 or $obj/aqd:objectiveType/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVmaxMOT')
    where $isInvalid
    return
        <tr>
            <td title="gml:id">{data($obj/../../@gml:id)}</td>
            <td title="aqd:protectionTarget">{data($obj/aqd:protectionTarget/@xlink:href)}</td>
            <td title="aqd:objectiveType">{data($obj/aqd:objectiveType/@xlink:href)}</td>
        </tr>


(: G33 :)

let $invalidobjectiveTypesForLV :=
    for $obj in $docRoot//aqd:environmentalObjective/aqd:EnvironmentalObjective
    let $isInvalid :=
        $obj/aqd:objectiveType/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV'
        and $obj/../../aqd:pollutant/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001'
        and $obj/aqd:protectionTarget/@xlink:href != 'http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S1'
        and $obj/aqd:protectionTarget/@xlink:href != 'http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H­S2'
    where $isInvalid
    return
        <tr>
            <td title="gml:id">{data($obj/../../@gml:id)}</td>
            <td title="aqd:protectionTarget">{data($obj/aqd:protectionTarget/@xlink:href)}</td>
            <td title="aqd:objectiveType">{data($obj/aqd:objectiveType/@xlink:href)}</td>
        </tr>


(: G38 :)

let $invalidAreaClassificationCodes := xmlconv:isinvalidDDConceptLimited("aqd:exceedanceDescriptionBase", "aqd:ExceedanceArea", "aqd:areaClassification",  $xmlconv:AREACLASSIFICATION_VOCABULARY, $xmlconv:VALID_AREACLASSIFICATION_IDS)
        (:)let $invalidAqdReportingMetricG37 :=
    for $aqdReportingMetricG37 in $docRoot//aqd:AQD_Attainment
    let $reportingXlink:= fn:substring-after(data($aqdReportingMetricG37/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective//aqd:protectionTarget/fn:normalize-space(@xlink:href)),"protectiontarget/")
    where empty(index-of(data($aqdReportingMetricG37/aqd:pollutant/fn:normalize-space(@xlink:href)),"http://dd.eionet.europa.eu/vocabulary/aq/pollutant/10"))=false()
       or empty(index-of(data($aqdReportingMetricG37/aqd:pollutant/fn:normalize-space(@xlink:href)),"http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001"))=false()
       or empty(index-of(data($aqdReportingMetricG37/aqd:pollutant/fn:normalize-space(@xlink:href)),"http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5"))=false()
    return  if (empty(index-of(('V'),$reportingXlink))) then $reportingXlink else ():)


(: TODO G41

let $invalidObjectiveCodes := xmlconv:isinvalidDDConceptLimited("", "aqd:AQD_Attainment", "aqd:objectiveType",  $xmlconv:OBJECTIVETYPE_VOCABULARY, $xmlconv:VALID_OBJECTIVETYPE_IDS)
:)
(: TODO G42

let $invalidReportingMetricCodes := xmlconv:isinvalidDDConceptLimited("", "aqd:AQD_Attainment", "aqd:reportingMetric",  $xmlconv:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS)
:)

(: G44 :)

(: let $invalidobjectiveTypesForLimitV:=
    for $obj in $docRoot//aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective
    where
        $obj/aqd:protectionTarget/@xlink:href != 'http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H'
                and $obj/aqd:objectiveType/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV'
                 or $obj/aqd:objectiveType/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV'
    return $obj/../../../..

let $tblInvalidobjectiveTypesForLimitV :=
    for $rec in $invalidobjectiveTypesForLimitV
    return
        <tr>
            <td title="gml:id">{data($rec/@gml:id)}</td>
            <td title="aqd:protectionTarget">{data($rec//aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href)}</td>
            <td title="aqd:objectiveType">{data($rec//aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href)}</td>
        </tr> :)

(: G47 :)

let $invalidAqdAdjustmentType := distinct-values($docRoot//aqd:AQD_Attainment[aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentType/fn:normalize-space(@xlink:href)!="http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplied"]/@gml:id)


(: G49 :)



(: G50 :)
(: G51 :)
(: G52 :)
let $invalidAreaClassificationAdjusmentCodes := xmlconv:isinvalidDDConceptLimited("aqd:exceedanceDescriptionAdjustment", "aqd:ExceedanceArea", "aqd:areaClassification",  $xmlconv:AREACLASSIFICATION_VOCABULARY, $xmlconv:VALID_AREACLASSIFICATION_IDS)

(: G53 :)
(: G54 :)
(: G55 :)

(: TODO )let $invalidAdjustmentReportingMetric :=
    for $aqdAdjustmentReportingMetric in $docRoot//aqd:AQD_Attainment
    let $reportingXlink:= fn:substring-after(data($aqdAdjustmentReportingMetric/aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/fn:normalize-space(@xlink:href)),"reportingmetric/")
    where empty(index-of(data($aqdAdjustmentReportingMetric/aqd:pollutant/fn:normalize-space(@xlink:href)),"http://dd.eionet.europa.eu/vocabulary/aq/pollutant/1"))=false()
    return  if (empty(index-of(('daysAbove','hrsAbove','wMean','aMean'),$reportingXlink))) then $reportingXlink else () :)

(: G56 :)

(:TODO)let $invalidAdjustmentReportingMetricG56 :=
    for $aqdAdjustmentReportingMetricG56 in $docRoot//aqd:AQD_Attainment
    let $reportingXlink:= fn:substring-after(data($aqdAdjustmentReportingMetricG56/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/fn:normalize-space(@xlink:href)),"reportingmetric/")
    where empty(index-of(data($aqdAdjustmentReportingMetricG56/aqd:pollutant/fn:normalize-space(@xlink:href)),"http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5"))=false()
    return  if (empty(index-of(('daysAbove','aMean'),$reportingXlink))) then $reportingXlink else "" :)

(: G57 :)

let $invalidAdjustmentReportingMetricG57 :=
    for $aqdAdjustmentReportingMetricG57 in $docRoot//aqd:AQD_Attainment
    let $reportingXlink:= fn:substring-after(data($aqdAdjustmentReportingMetricG57/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/fn:normalize-space(@xlink:href)),"reportingmetric/")
    where empty(index-of(data($aqdAdjustmentReportingMetricG57/aqd:pollutant/fn:normalize-space(@xlink:href)),"http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001"))=false()
    return  if (empty(index-of(('aMean'),$reportingXlink))) then $reportingXlink else ()


(: G61 :)

let $invalidExceedanceDescriptionAdjustment := xmlconv:isinvalidDDConceptLimited("aqd:exceedanceDescriptionAdjustment", "aqd:AdjustmentMethod", "aqd:adjustmentType", $xmlconv:ADJUSTMENTTYPE_VOCABULARY, $xmlconv:VALID_ADJUSTMENTTYPE_IDS)

(: G62 :)

let $invalidExceedanceDescriptionAdjustmentSrc := xmlconv:isinvalidDDConceptLimited("aqd:exceedanceDescriptionAdjustment", "aqd:AdjustmentMethod", "aqd:adjustmentSource", $xmlconv:ADJUSTMENTSOURCE_VOCABLUARY, $xmlconv:VALID_ADJUSTMENTSOURCE_IDS)

(: G63 :)

let $invalidExceedanceDescriptionAdjustmentAssessment := xmlconv:isinvalidDDConceptLimited("aqd:exceedanceDescriptionAdjustment", "aqd:AssessmentMethods", "aqd:assessmentType", $xmlconv:ASSESSMENTTYPE_VOCABLUARY, $xmlconv:VALID_ASSESSMENTTYPE_IDS)

(: G70 :)

let $aqdSurfaceArea := $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:surfaceArea[count(@uom)>0 and fn:normalize-space(@uom)!="http://dd.eionet.europa.eu/vocabulary/uom/area/km2"]/../../../../../@gml:id

(: G71 :)
let $aqdroadLength := $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:roadLength[count(@uom)>0 and fn:normalize-space(@uom)!="http://dd.eionet.europa.eu/vocabulary/uom/area/km"]/../../../../../@gml:id

(: G72 :)

let $invalidAreaClassificationCode  := xmlconv:isinvalidDDConceptLimited("aqd:exceedanceDescriptionFinal", "aqd:ExceedanceArea",  "aqd:areaClassification",  $xmlconv:AREACLASSIFICATION_VOCABULARY, $xmlconv:VALID_AREACLASSIFICATION_IDS)

(: G81 :)

let $invalidAdjustmentType := distinct-values($docRoot//aqd:AQD_Attainment[aqd:exceedanceDescriptionAdjustmen/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentType/fn:normalize-space(@xlink:href)!="http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/fullyCorrected"]/@gml:id)

return
    <table style="border-collapse:collapse;display:inline">
        <colgroup>
            <col width="15px" style="text-align:center"/>
            <col width="450px" style="text-align:left"/>
            <col width="350px" style="text-align:left"/>
            <col width="*"/>
        </colgroup>
        {xmlconv:buildResultRows("G1", "Total number of attainment statements",
            (), (), "", string($countAttainments), "", "", $tblAllAttainments)}
        {xmlconv:buildResultRows("G4", " A list of the unique identifier information for all attainment records",
                (), (), "", string(count($tblAllAttainmentsG4)), " ", "", $tblAllAttainmentsG4)}
        {xmlconv:buildResultRows("G5", "Total number of exceedances",
            (), (), "", string($countExceedances), " exceedance", "", $tblAllExceedances)}
        {xmlconv:buildResultRows("G6", "Total number of attainment records that have been assessed against the objectiveType for zones with time extens",
                $aqdObjectiveType,(), "", string(count($aqdObjectiveType)), " attainment", "", $tblAllAttainment)}
        {xmlconv:buildResultRows("G7", "All gml:id attributes, ef:inspireId and aqd:inspireId elements shall have unique content",
            $invalidDuplicateGmlIds, (), "", "No duplicates found", " duplicate", "", $tblDuplicateGmlIds)}
        {xmlconv:buildResultRows("G8", "./ef:inspireId/base:Identifier/base:localId  must be unique code for the attainment records starting with ISO2-country code",
            $invalidDuplicateLocalIds, (), "base:localId", "No duplicate values found", " duplicate value", "", ())}
        {xmlconv:buildResultRows("G9", "./ef:inspireId/base:Identifier/base:namespace shall resolve to a unique namespace identifier for the data source (within an annual e-Reporting cycle). ",
            $duplicateNamespaces, (), "base:namespace", "No duplicate values found", " duplicate value", "", ())}
        {xmlconv:buildResultRowsWithTotalCount("G10", <span>The content of /aqd:AQD_Attainment/aqd:pollutant xlink:xref shall resolve to a pollutant in
            <a href="{ $xmlconv:POLLUTANT_VOCABULARY }">{ $xmlconv:POLLUTANT_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G10", $xmlconv:POLLUTANT_VOCABULARY, $xmlconv:VALID_POLLUTANT_IDS)}
            </span>,
            (), (), "aqd:pollutant", "", "", "", $invalidPollutantCodes)}
        {xmlconv:buildResultRows("G11", ".WHERE ./aqd:pollutant xlink:href attribute EQUALs",
            $invalidExceedanceDescriptionBase, (), "base:namespace", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("G12", ".WHERE ./aqd:pollutant xlink:href attribute EQUALs",
                $invalidExceedanceDescriptionAdjustment, (), "base:namespace", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("G13", "./aqd:assessment xlink:href attribute shall resolve to a valid assessment regime with in /aqd:AQD_AssessmentRegime",
                $invalidAssessment, (), "base:namespace", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("G15", "./aqd:zone xlink:href attribute shall resolve to a valid AQ zone with /aqd:AQD_Zone",
                $invalidAssessmentZone, (), "base:namespace", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("G17", "The subject of the ./aqd: zone xlink:href attribute shall contain a /aqd:AQD_Zone/aqd:pollutant EQUAL  to ./aqd:pollutan",
            $invalidPollutant, (), "base:namespace", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("G18", "The  subject  of  the ./aqd: zone xlink:href attribute shall contain a /aqd:AQD_Zone/aqd:timeExtensionExemption shall NOT EQUAL http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/none WHERE ./aqd:exceedanceDescription_Final/aqd:ExceedanceDescription/aqd:environmentalObj ective/aqd:EnvironmentalObjective/aqd:objectiveType xlink:href attribute EQUALs http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVmaxMOT",
                $invalidObjectiveType, (), "base:namespace", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRowsWithTotalCount("G19", <span>./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType xlink:href attribute shall resolve to one of
            <a href="{ $xmlconv:OBJECTIVETYPE_VOCABULARY }">{ $xmlconv:OBJECTIVETYPE_VOCABULARY }</a>
            Allowed items: {xmlconv:buildVocItemsList("G19", $xmlconv:OBJECTIVETYPE_VOCABULARY, $xmlconv:VALID_OBJECTIVETYPE_IDS)}</span>,
            (), (), "aqd:objectivetype", "", "", "", $invalidObjectiveTypes)}

        {xmlconv:buildResultRowsWithTotalCount("G20", <span>The content of ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:EnvironmentalObjective/aqd:reportingMetric shall resolve to a valid concept in
            <a href="{ $xmlconv:REPMETRIC_VOCABULARY }">{ $xmlconv:REPMETRIC_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G20", $xmlconv:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS_20)}</span>,
            (), (), "aqd:reportingMetric", "", "", "", $invalidReportingMetric)}

        {xmlconv:buildResultRows("G21", "If
                    ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType xlink:href attribute EQUALS http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL (Critical)
                        ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget xlink:href attribute has to be http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V (Vegetation)",
            $invalidobjectiveTypesForVEG, (), "", "No invalid objective types for Vegetation found", " invalid value", "", $invalidobjectiveTypesForVEG)}
        {xmlconv:buildResultRows("G22", "If
                 ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType xlink:href attribute EQUALS http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV (Target Value)
                    ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType xlink:href attribute EQUALS http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV (Limit Value)
                        ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget xlink:href attribute has to be http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H (Health)",
                $invalidobjectiveTypesForVEGG22, (), "", "No invalid objective types for Health found", " invalid value", "", $invalidobjectiveTypesForVEGG22)}
        {xmlconv:buildResultRows("G23", <span>The content of ./aqd:EnvironmentalObjective/aqd:reportingMetric shall resolve to a valid concept in
            <a href="{ $xmlconv:REPMETRIC_VOCABULARY }">{ $xmlconv:REPMETRIC_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G23", $xmlconv:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS)}</span>,
                $invalidAqdReportingMetric, (), "aqd:reportingMetric", "", "", "",())}
        {xmlconv:buildResultRows("G24", <span>The content of ./aqd:EnvironmentalObjective/aqd:reportingMetric shall resolve to a valid concept in
            <a href="{ $xmlconv:REPMETRIC_VOCABULARY }">{ $xmlconv:REPMETRIC_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G24", $xmlconv:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS_24)}</span>,
                $invalidAqdReportingMetricG24, (), "aqd:reportingMetric", "", "", "",())}
        {xmlconv:buildResultRows("G25", <span>The content of ./aqd:EnvironmentalObjective/aqd:reportingMetric shall resolve to a valid concept in
            <a href="{ $xmlconv:REPMETRIC_VOCABULARY }">{ $xmlconv:REPMETRIC_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G25", $xmlconv:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS_25)}</span>,
                $invalidAqdReportingMetricG25, (), "aqd:reportingMetric", "", "", "",())}
        {xmlconv:buildResultRows("G26", <span>The content of ./aqd:EnvironmentalObjective/aqd:reportingMetric shall resolve to a valid concept in
            <a href="{ $xmlconv:REPMETRIC_VOCABULARY }">{ $xmlconv:REPMETRIC_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G26", $xmlconv:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS_26)}</span>,
                $invalidAqdReportingMetricG26, (), "aqd:reportingMetric", "", "", "",())}
        {xmlconv:buildResultRows("G27", <span>./aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget xlink:href attribute shall NOT EQUAL http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V and
            <a href="{ $xmlconv:POLLUTANT_VOCABULARY }">{ $xmlconv:POLLUTANT_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G27", $xmlconv:POLLUTANT_VOCABULARY, $xmlconv:VALID_POLLUTANT_IDS_27)}</span>,
                $invalidAqdReportingMetricG27, (), "aqd:reportingMetric", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("G30", "If
                 ./aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType xlink:href attribute EQUALS http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL (Critical level)
                        ./aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget xlink:href attribute has to be http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V (Vegetation)",
                $invalidobjectiveTypesForCriticalL, (), "", "No invalid objective types for Vegetation found", " invalid", "", $invalidobjectiveTypesForCriticalL)}
        {xmlconv:buildResultRows("G31", <span>The content of ./aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget xlink:href attribute shall EQUAL
            http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V and /aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric xlink:href attribute on shall resolve to a valid concept in
            <a href="{ $xmlconv:REPMETRIC_VOCABULARY }">{ $xmlconv:REPMETRIC_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G31", $xmlconv:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS_31)}</span>,
                $invalidobjectiveTypesForAOT31, (), "aqd:reportingMetric", "", "", "",$invalidobjectiveTypesForAOT31)}
        {xmlconv:buildResultRows("G32", <span>The content of ./aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget xlink:href attribute shall EQUAL
            http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H AND /aqd:polluntant is NOT EQUAL to
            http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001 where ./aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType  xlink:href attribute on shall resolve to a valid concept in
            <a href="{ $xmlconv:POLLUTANT_VOCABULARY }">{ $xmlconv:POLLUTANT_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G32", $xmlconv:POLLUTANT_VOCABULARY, $xmlconv:VALID_OBJECTIVETYPE_IDS_32)}</span>,
                $invalidobjectiveTypesForHealth, (), "aqd:reportingMetric",  "All values are valid", " invalid value", "", $invalidobjectiveTypesForHealth)}
        {xmlconv:buildResultRows("G33", <span>The content of ./aqd:polluntant is EQUAL to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001
            ./aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget xlink:href attribute EQUALS
            http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S1
            http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S2 where ./aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType  xlink:href attribute on shall resolve to a valid concept in
            <a href="{ $xmlconv:POLLUTANT_VOCABULARY }">{ $xmlconv:POLLUTANT_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G33", $xmlconv:POLLUTANT_VOCABULARY, $xmlconv:VALID_OBJECTIVETYPE_IDS_33)}</span>,
                $invalidobjectiveTypesForLV, (), "aqd:reportingMetric", "All values are valid", " invalid value", "",$invalidobjectiveTypesForLV)}
        {xmlconv:buildResultRowsWithTotalCount("G38", <span>The content of /aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:areaClassification xlink:xref shall resolve to a areaClassification in
            <a href="{ $xmlconv:AREACLASSIFICATION_VOCABULARY}">{ $xmlconv:AREACLASSIFICATION_VOCABULARY}</a> that must be one of
            {xmlconv:buildVocItemsList("G38", $xmlconv:AREACLASSIFICATION_VOCABULARY, $xmlconv:VALID_AREACLASSIFICATION_IDS)}
        </span>,
                (), (), "aqd:areaClassification", "", "", "", $invalidAreaClassificationCodes)}
        {xmlconv:buildResultRows("G47", "./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentType xlink:href attribute shall resolve to http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplied",
                $invalidAqdAdjustmentType, (), "base:namespace", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRowsWithTotalCount("G52", <span>The content of /aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:areaClassification xlink:xref shall resolve to a areaClassification in
            <a href="{ $xmlconv:AREACLASSIFICATION_VOCABULARY}">{ $xmlconv:AREACLASSIFICATION_VOCABULARY}</a> that must be one of
            {xmlconv:buildVocItemsList("G52", $xmlconv:AREACLASSIFICATION_VOCABULARY, $xmlconv:VALID_AREACLASSIFICATION_IDS_52)}
        </span>,
                (), (), "aqd:areaClassification", "", "", "", $invalidAreaClassificationAdjusmentCodes)}
        {xmlconv:buildResultRowsWithTotalCount("G61", <span>The content of /aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentType xlink:xref shall resolve to a adjustmentType in
            <a href="{ $xmlconv:ADJUSTMENTTYPE_VOCABULARY}">{ $xmlconv:ADJUSTMENTTYPE_VOCABULARY}</a> that must be one of
            {xmlconv:buildVocItemsList("G61", $xmlconv:ADJUSTMENTTYPE_VOCABULARY, $xmlconv:VALID_ADJUSTMENTTYPE_IDS)}
        </span>,
                (), (), "aqd:areaClassification", "", "", "", $invalidExceedanceDescriptionAdjustment)}
        {xmlconv:buildResultRowsWithTotalCount("G62", <span>The content of /aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmenSource xlink:xref shall resolve to a adjustmenSource in
            <a href="{ $xmlconv:ADJUSTMENTSOURCE_VOCABLUARY}">{ $xmlconv:ADJUSTMENTSOURCE_VOCABLUARY}</a> that must be one of
            {xmlconv:buildVocItemsList("G62", $xmlconv:ADJUSTMENTSOURCE_VOCABLUARY, $xmlconv:VALID_ADJUSTMENTSOURCE_IDS)}
        </span>,
                (), (), "aqd:areaClassification", "", "", "", $invalidExceedanceDescriptionAdjustmentSrc)}
        {xmlconv:buildResultRowsWithTotalCount("G63", <span>The content of /aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmenSource xlink:xref shall resolve to a adjustmenSource in
            <a href="{  $xmlconv:ASSESSMENTTYPE_VOCABLUARY}">{  $xmlconv:ASSESSMENTTYPE_VOCABLUARY}</a> that must be one of
            {xmlconv:buildVocItemsList("G63",  $xmlconv:ASSESSMENTTYPE_VOCABLUARY, $xmlconv:VALID_ASSESSMENTTYPE_IDS)}
        </span>,
                (), (), "aqd:areaClassification", "", "", "", $invalidExceedanceDescriptionAdjustmentAssessment)}

        {xmlconv:buildResultRows("G70", "/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:surfaceArea uom attribute  shall resolve  to http://dd.eionet.europa.eu/vocabulary/uom/area/km2",
                $aqdSurfaceArea, (), "base:namespace", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("G71", "/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:roadLength uom attribute  shall  be http://dd.eionet.europa.eu/vocabulary/uom/length/km",
                $aqdroadLength, (), "base:namespace", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRowsWithTotalCount("G72", <span>The content of /aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:areaClassification  xlink:xref shall resolve to a areaClassification in
            <a href="{ $xmlconv:AREACLASSIFICATION_VOCABULARY}">{ $xmlconv:AREACLASSIFICATION_VOCABULARY}</a> that must be one of
            {xmlconv:buildVocItemsList("G72", $xmlconv:AREACLASSIFICATION_VOCABULARY, $xmlconv:VALID_AREACLASSIFICATION_IDS_52)}
        </span>,
                (), (), "aqd:areaClassification", "", "", "", $invalidAreaClassificationCode)}
        {xmlconv:buildResultRows("G81", "./aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentType xlink:href attribute shall resolve to http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/fullyCorrected",
                $invalidAqdAdjustmentType, (), "base:namespace", "All values are valid", " invalid value", "", ())}
    </table>
}
;




declare function xmlconv:checkVocabularyConceptValues($parentObject as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $limitedIds as xs:string*)
as element(tr)*{
    xmlconv:checkVocabularyConceptValues($parentObject, $featureType, $element, $vocabularyUrl, $limitedIds, "")
};

declare function xmlconv:checkVocabularyConceptValues($parentObject, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string)
as element(tr)*{
    xmlconv:checkVocabularyConceptValues($parentObject, $featureType, $element, $vocabularyUrl, (), "")
};
declare function xmlconv:checkVocabularyConceptValues($parentObject as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $limitedIds as xs:string*, $vocabularyType as xs:string)
as element(tr)*{

    let $sparql :=
        if ($vocabularyType = "collection") then
            xmlconv:getCollectionConceptUrlSparql($vocabularyUrl)
        else
            xmlconv:getConceptUrlSparql($vocabularyUrl)
    let $crConcepts := xmlconv:executeSparqlQuery($sparql)

    let $allRecords :=
    if ($parentObject != "") then
        doc($source_url)//gml:featureMember/descendant::*[name()=$parentObject]/descendant::*[name()=$featureType]
    else
        doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

    for $rec in $allRecords
    for $conceptUrl in $rec/child::*[name() = $element]/@xlink:href
    let $conceptUrl := normalize-space($conceptUrl)

    where string-length($conceptUrl) > 0

    return
        <tr isvalid="{ xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl) and xmlconv:isValidLimitedValue($conceptUrl, $vocabularyUrl, $limitedIds) }">
            <td title="Feature type">{ $featureType }</td>
            <td title="gml:id">{data($rec/@gml:id)}</td>
            <td title="ef:inspireId">{data($rec/ef:inspireId/base:Identifier/base:localId)}</td>
            <td title="aqd:inspireId">{data($rec/aqd:inspireId/base:Identifier/base:localId)}</td>
            <td title="ef:name">{data($rec/ef:name)}</td>
            <td title="{ $element }" style="color:red">{$conceptUrl}</td>
        </tr>

};

declare function xmlconv:isValidLimitedValue($conceptUrl as xs:string, $vocabularyUrl as xs:string, $limitedIds as xs:string*)
as xs:boolean {
    let $limitedUrls :=
      for $id in $limitedIds
      return concat($vocabularyUrl, $id)

    return
        empty($limitedIds) or not(empty(index-of($limitedUrls, $conceptUrl)))
};

declare function xmlconv:getConceptUrlSparql($scheme as xs:string)
as xs:string
{
    concat("PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    SELECT ?concepturl ?label
    WHERE {
      ?concepturl skos:inScheme <", $scheme, ">;
                  skos:prefLabel ?label
    }")
};

declare function xmlconv:getCollectionConceptUrlSparql($collection as xs:string)
as xs:string
{
    concat("PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    SELECT ?concepturl
    WHERE {
        GRAPH <", $collection, "> {
            <", $collection, "> skos:member ?concepturl .
            ?concepturl a skos:Concept
        }
    }")
};

declare function xmlconv:isMatchingVocabCode($crConcepts as element(sparql:results), $concept as xs:string)
as xs:boolean
{
    count($crConcepts//sparql:result/sparql:binding[@name="concepturl" and sparql:uri=$concept]) > 0
};


declare function xmlconv:isinvalidDDConceptLimited($parentObject as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $allowedIds as xs:string*)
as element(tr)* {
    xmlconv:checkVocabularyConceptValues($parentObject, $featureType, $element, $vocabularyUrl, $allowedIds)
};


declare function xmlconv:buildResultRowsWithTotalCount($ruleCode as xs:string, $text, $invalidStrValues as xs:string*, $invalidValues as element()*,
    $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $recordDetails as element(tr)*)
as element(tr)*{

    let $countCheckedRecords := count($recordDetails)
    let $invalidValues := $recordDetails[./@isvalid = "false"]

    let $skippedMsg := if ($countCheckedRecords = 0) then "No values found to check" else ""
    let $invalidMsg := if (count($invalidValues) > 0) then concat(" invalid value", substring("s ", number(not(count($invalidValues) > 1)) * 2), " found out of ", $countCheckedRecords, " checked") else ""
    let $validMsg := if (count($invalidValues) = 0) then concat("Checked ", $countCheckedRecords, " value", substring("s", number(not($countCheckedRecords > 1)) * 2), ", all valid") else ""

    return
        xmlconv:buildResultRows($ruleCode, $text, $invalidStrValues, $invalidValues,
            $valueHeading, $validMsg, $invalidMsg, $skippedMsg, ())
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
declare function xmlconv:proceed($source_url as xs:string) {

let $countZones := count(doc($source_url)//aqd:AQD_Attainment)
let $result := if ($countZones > 0) then xmlconv:checkReport($source_url) else ()

return
<div class="feedbacktext">
    { xmlconv:javaScript() }
    <div>
        <h2>Check air quality attainment of environmental objectives  - Dataflow G</h2>
        {
            if ($result//div/@class = 'error') then
                <p>This XML file did NOT passed the following cruical checks: {string-join($result//div[@class='error'], ',')}</p>
            else
                <p>This XML file passed all crucial checks' which in this case are :G1,G4,G5,G6,G7,G8,G9,G10,G11,G12,G13,G15,G17,G18,G19,G20,G21,
                G22,G23,G24,G25,G26,G27,G28,G29,G30,G31,G32,G33,G38,G47,G52,G61,G62,G63,G70,G71,G72,G81</p>
        }
        {
        if ( $countZones = 0) then
            <p>No aqd:AQD_Attainment elements found from this XML.</p>
        else
            (<p>This check evaluated the delivery by executing the tier-1 tests on air quality assessment regimes data in Dataflow G.
            Red bullet in front of the test result indicates that errenous records found from the delivery.
            Blue bullet means that the data confirms to rule, but additional feedback could be provided. </p>,
            <p>Please click on the "Show records" link to see more details.</p>,
            $result
            )
        }
    </div>
</div>

};
xmlconv:proceed( $source_url )

