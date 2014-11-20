xquery version "1.0" encoding "UTF-8";
(:
 : Module Name: Implementing Decision 2011/850/EU: AQ info exchange & reporting (Main module)
 :
 : Version:     $Id$
 : Created:     13 September 2013
 : Copyright:   European Environment Agency
 :)
(:~
 : XQuery script implements dataflow C tier-1 checks as documented in http://taskman.eionet.europa.eu/documents/3 .
 :
 : @author Rait Väli and Enriko Käsper
 :
 :Quality Assurance and Control rules version: 3.9d
 :)

declare namespace xmlconv = "http://converters.eionet.europa.eu";
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

declare variable $xmlconv:FEATURE_TYPES := ("aqd:AQD_Network", "aqd:AQD_Station", "aqd:AQD_SamplingPointProcess", "aqd:AQD_Sample",
"aqd:AQD_RepresentativeArea", "aqd:AQD_SamplingPoint");


declare variable $xmlconv:MEDIA_VALUE_VOCABULARY_BASE_URI := "http://inspire.ec.europa.eu/codeList/MediaValue/";
declare variable $xmlconv:MEDIA_VALUE_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/inspire/MediaValue/";
declare variable $xmlconv:ORGANISATIONAL_LEVEL_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/organisationallevel/";
declare variable $xmlconv:NETWORK_TYPE_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/networktype/";
declare variable $xmlconv:METEO_PARAMS_VOCABULARY := "http://vocab.nerc.ac.uk/collection/P07/current/";
declare variable $xmlconv:AREA_CLASSIFICATION_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/areaclassification/";
declare variable $xmlconv:DISPERSION_LOCAL_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/dispersionlocal/";
declare variable $xmlconv:DISPERSION_REGIONAL_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/dispersionregional/";
declare variable $xmlconv:TIMEZONE_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/timezone/";
declare variable $xmlconv:POLLUTANT_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/";

(:===================================================================:)
(: Variable given as an external parameter by the QA service :)
(:===================================================================:)

declare variable $source_url as xs:string external;

(:
declare variable $source_url := "../test/DE_D_Station.xml";
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
             ""
(:              "http://cdrtest.eionet.europa.eu/ee/eu/art17/envriytkg/xml" :)
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
        divName = divName + "-" + checkId;
        linkName = linkName + "-" + checkId;

        var elem = document.getElementById(divName);
        var text = document.getElementById(linkName);
        if(elem.style.display == "inline") {{
            elem.style.display = "none";
            text.innerHTML = "Show records";
            }}
            else {{
              elem.style.display = "inline";
              text.innerHTML = "Hide records";
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
        if(doc-available($uri))then
        fn:doc($uri)//sparql:results
        else
            <sparql:results/>

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
            "grey"
        else
            "deepskyblue"
return
    <div style="background-color: { $color }; font-size: 0.8em; color: white; padding-left:5px;padding-right:5px;margin-right:5px;margin-top:2px;text-align:center">{ $text }</div>
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
                    if (contains($invalidMsg, " found")) then
                        concat($countInvalidValues, $invalidMsg)
                    else
                        concat($countInvalidValues, $invalidMsg, substring(" ", number(not($countInvalidValues > 1)) * 2) ,"found")
                }
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
declare function xmlconv:getSamplingPointAssessment($inspireId as xs:string, $inspireNamespace as xs:string)
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
declare function xmlconv:getSamplingPointZone($zoneId as xs:string)
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

(:
    Rule implementations
:)
declare function xmlconv:checkReport($source_url as xs:string)
as element(table) {

(: get reporting country :)
(:
let $envelopeUrl := xmlconv:getEnvelopeXML($source_url)
let $countryCode := if(string-length($envelopeUrl)>0) then lower-case(fn:doc($envelopeUrl)/envelope/countrycode) else ""
:)

(: FIXME
let $countryCode := "gb"
let $countryCode := if ($countryCode = "gb") then "uk" else if ($countryCode = "gr") then "el" else $countryCode
:)

let $docRoot := doc($source_url)
(: D1 :)
let $countFeatureTypes :=
    for $featureType in $xmlconv:FEATURE_TYPES
    return
        count(doc($source_url)//gml:featureMember/descendant::*[name()=$featureType])
let $tblAllFeatureTypes :=
    for $featureType at $pos in $xmlconv:FEATURE_TYPES
    where $countFeatureTypes[$pos] > 0
    return
        <tr>
            <td title="Feature type">{ $featureType }</td>
            <td title="Total number">{$countFeatureTypes[$pos]}</td>
        </tr>

(: D6 Done by Rait ./ef:inspireId/base:Identifier/base:localId shall be an unique code for AQD_network and unique within the namespace.:)
let $amInspireIds := $docRoot//aqd:AQD_Network/ef:inspireId/base:Identifier/concat(lower-case(normalize-space(base:namespace)), '##',
        lower-case(normalize-space(base:localId)))
let $duplicateEUStationCode := distinct-values(
        for $identifier in $docRoot//aqd:AQD_Network/am:inspireId/base:Identifier
        where string-length(normalize-space($identifier/base:localId)) > 0 and count(index-of($amInspireIds,
                concat(lower-case(normalize-space($identifier/base:namespace)), '##', lower-case(normalize-space($identifier/base:localId))))) > 1
        return
            concat(normalize-space($identifier/base:namespace), ':', normalize-space($identifier/base:localId))
)
let $countAmInspireIdDuplicates := count($duplicateEUStationCode)
let $countD6duplicates := $countAmInspireIdDuplicates

(: D8 :)
let $invalidNetworkMedia := xmlconv:checkVocabularyConceptValues("aqd:AQD_Network", "ef:mediaMonitored", $xmlconv:MEDIA_VALUE_VOCABULARY_BASE_URI)
(: D9 :)
let $invalidOrganisationalLevel := xmlconv:checkVocabularyConceptValues("aqd:AQD_Station", "ef:organisationLevel", $xmlconv:ORGANISATIONAL_LEVEL_VOCABULARY)
(: D13 :)
let $invalidNetworkType := xmlconv:checkVocabularyConceptValues("aqd:AQD_Station", "aqd:networkType", $xmlconv:NETWORK_TYPE_VOCABULARY)
(: D14 Done by Rait  :)
let $invalidTimeZone := xmlconv:checkVocabularyConceptValues("aqd:AQD_Network", "aqd:aggregationTimeZone", $xmlconv:TIMEZONE_VOCABULARY)
(: D15 Done by Rait :)
let $amInspireIds := $docRoot//aqd:AQD_Station/ef:inspireId/base:Identifier/concat(lower-case(normalize-space(base:namespace)), '##',
        lower-case(normalize-space(base:localId)))
let $duplicateEUStationCode := distinct-values(
        for $identifier in $docRoot//aqd:AQD_Station/am:inspireId/base:Identifier
        where string-length(normalize-space($identifier/base:localId)) > 0 and count(index-of($amInspireIds,
                concat(lower-case(normalize-space($identifier/base:namespace)), '##', lower-case(normalize-space($identifier/base:localId))))) > 1
        return
            concat(normalize-space($identifier/base:namespace), ':', normalize-space($identifier/base:localId))
)
let $countAmInspireIdDuplicates := count($duplicateEUStationCode)
let $countD15duplicates := $countAmInspireIdDuplicates


(: D19 :)
let $invalidStationMedia := xmlconv:checkVocabularyConceptValues("aqd:AQD_Station", "ef:mediaMonitored", $xmlconv:MEDIA_VALUE_VOCABULARY_BASE_URI)

(: D20 Done by Rait:)
let $invalidPoints := distinct-values($docRoot//aqd:AQD_Station[count(ef:geometry/gml:Point) >0 and ef:geometry/gml:Point/@srsName != "urn:ogc:def:crs:EPSG::4258" and ef:geometry/gml:Point/@srsName != "urn:ogc:def:crs:EPSG::4326"]/@gml:id)

(: D21 Done by Rait :)
let $invalidPos  := distinct-values($docRoot//aqd:AQD_Station/ef:geometry/gml:Point/gml:pos[@srsDimension != "2"]/
concat(../../../../../@gml:id, ": srsDimension=", @srsDimension))


(: D23 Done by Rait :)
    let $allEfOperationActivityPeriod :=
        for $allOperationActivityPeriod in $docRoot//gml:featureMember/aqd:AQD_Station/ef:operationalActivityPeriod
        where ($allOperationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition[normalize-space(@indeterminatePosition)!="unknown"]
                or fn:string-length($allOperationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition) > 0)
        return $allOperationActivityPeriod

    let $allInvalidEfOperationActivityPeriod :=
            for $operationActivityPeriod in  $allEfOperationActivityPeriod
            where ((xs:dateTime($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition) < xs:dateTime($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition)))
    return
        <tr>
            <td title="aqd:AQD_Station">{data($operationActivityPeriod/../@gml:id)}</td>
            <td title="gml:TimePeriod">{data($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/@gml:id)}</td>
            <td title="gml:beginPosition">{$operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition}</td>
            <td title="gml:endPosition">{$operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition}</td>
        </tr>



(: D24 Done by Rait:)
let $allUnknownEfOperationActivityPeriod :=
    for $operationActivityPeriod in $docRoot//gml:featureMember/aqd:AQD_Station/ef:operationalActivityPeriod
    where $operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition[normalize-space(@indeterminatePosition)="unknown"]
            or fn:string-length($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition) = 0
    return
        <tr>
            <td title="aqd:AQD_Station">{data($operationActivityPeriod/../@gml:id)}</td>
            <td title="gml:TimePeriod">{data($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/@gml:id)}</td>
            <td title="gml:beginPosition">{$operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition}</td>
            <td title="gml:endPosition">{$operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition}</td>
        </tr>
(: D26 Done by Rait:)

let $localEUStationCode := $docRoot//gml:featureMember/aqd:AQD_Station/upper-case(normalize-space(aqd:EUStationCode))
let $invalidDuplicateLocalIds :=
    for $EUStationCode in $docRoot//gml:featureMember/aqd:AQD_Station/aqd:EUStationCode
    where
    count(index-of($localEUStationCode, upper-case(normalize-space($EUStationCode)))) > 1 or
     count(index-of($xmlconv:ISO2_CODES , substring(upper-case(normalize-space($EUStationCode)), 5, 2))) = 0
    return
        <tr>
            <td title="aqd:AQD_Station">{data($EUStationCode/../@gml:id)}</td>
            <td title="aqd:EUStationCode">{data($EUStationCode)}</td>
        </tr>

(: D27 :)
let $invalidMeteoParams := xmlconv:checkVocabularyConceptValues("aqd:AQD_Station", "aqd:meteoParams", $xmlconv:METEO_PARAMS_VOCABULARY, "collection")
(: D28 :)
let $invalidAreaClassification := xmlconv:checkVocabularyConceptValues("aqd:AQD_Station", "aqd:areaClassification", $xmlconv:AREA_CLASSIFICATION_VOCABULARY)
(: D29 :)
let $invalidDispersionLocal := xmlconv:checkVocabularyConceptValues("aqd:AQD_Station", "aqd:dispersionLocal", $xmlconv:DISPERSION_LOCAL_VOCABULARY)
(: D30 :)
let $invalidDispersionRegional := xmlconv:checkVocabularyConceptValues("aqd:AQD_Station", "aqd:dispersionRegional", $xmlconv:DISPERSION_REGIONAL_VOCABULARY)
(: D31 Done by Rait:)
let $localSamplingPointIds := $docRoot//gml:featureMember/aqd:AQD_SamplingPoint/ef:inspireId/base:Identifier/base:localId
let $invalidDuplicateSamplingPointIds :=
    for $idCode in $docRoot//gml:featureMember/aqd:AQD_SamplingPoint/ef:inspireId/base:Identifier/base:localId
    where
        count(index-of($localSamplingPointIds, normalize-space($idCode))) > 1
    return
        <tr>
            <td title="aqd:AQD_SamplingPoint">{data($idCode/../../../@gml:id)}</td>
            <td title="base:localId">{data($idCode)}</td>
        </tr>

(: D33 :)
let $invalidSamplingPointMedia := xmlconv:checkVocabularyConceptValues("aqd:AQD_SamplingPoint", "ef:mediaMonitored", $xmlconv:MEDIA_VALUE_VOCABULARY_BASE_URI)

(: D35 FIX ME :)
let $invalidPos  := distinct-values($docRoot/gml:featureMember//aqd:AQD_SamplingPoint/ef:geometry/gml:Point/gml:pos[@srsDimension != "2"]/
concat(../../../../../@gml:id, ": srsDimension=", @srsDimension))

(: D36 FIX ME ask  /aqd:AQD_SamplingPoint do not have ef:geometry:)


(: D37 Done by Rait:)
(: Find all period with out end period :)
let $allNotNullEndPeriods :=
    for $allPeriod in $docRoot//gml:featureMember//aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod
    where ($allPeriod/gml:endPosition[normalize-space(@indeterminatePosition)!="unknown"]
            or fn:string-length($allPeriod/gml:endPosition) > 0)
    return $allPeriod

let $allObservingCapabilityPeriod :=
    for $observingCapabilityPeriod in $allNotNullEndPeriods
    where ((xs:dateTime($observingCapabilityPeriod/gml:endPosition) < xs:dateTime($observingCapabilityPeriod/gml:beginPosition)))
    return
        <tr>
            <td title="aqd:AQD_Station">{data($observingCapabilityPeriod/../../../../@gml:id)}</td>
            <td title="gml:TimePeriod">{data($observingCapabilityPeriod/@gml:id)}</td>
            <td title="gml:beginPosition">{$observingCapabilityPeriod/gml:beginPosition}</td>
            <td title="gml:endPosition">{$observingCapabilityPeriod/gml:endPosition}</td>
        </tr>


(:D40 Done by Rait:)
let $invalidObservedProperty := xmlconv:checkVocabularyConceptValues("aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability", "ef:observedProperty", $xmlconv:POLLUTANT_VOCABULARY)

(: D45 Done by Rait:)
(: Find all period with out end period :)
let $allNotNullEndOperationActivityPeriods :=
    for $allOperationActivityPeriod in $docRoot//gml:featureMember//aqd:AQD_SamplingPoint/ef:operationActivityPeriod/ef:OperationActivityPeriod/ef:activityTime/gml:TimePeriod
    where ($allOperationActivityPeriod/gml:endPosition[normalize-space(@indeterminatePosition)!="unknown"]
            or fn:string-length($allOperationActivityPeriod/gml:endPosition) > 0)
    return $allOperationActivityPeriod

let $allOperationActivitPeriod :=
    for $operationActivitPeriod in $allNotNullEndOperationActivityPeriods
    where ((xs:dateTime($operationActivitPeriod/gml:endPosition) < xs:dateTime($operationActivitPeriod/gml:beginPosition)))
    return
        <tr>
            <td title="aqd:AQD_Station">{data($operationActivitPeriod/../../../../@gml:id)}</td>
            <td title="gml:TimePeriod">{data($operationActivitPeriod/@gml:id)}</td>
            <td title="gml:beginPosition">{$operationActivitPeriod/gml:beginPosition}</td>
            <td title="gml:endPosition">{$operationActivitPeriod/gml:endPosition}</td>
        </tr>

(:D46 Done by Rait:)
let $allUnknownEfOperationActivityPeriod :=
    for $operationActivityPeriod in $docRoot//gml:featureMember/aqd:AQD_Station/ef:operationalActivityPeriod
    where $operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition[normalize-space(@indeterminatePosition)="unknown"]
            or fn:string-length($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition) = 0
    return
        <tr>
            <td title="aqd:AQD_Station">{data($operationActivityPeriod/../@gml:id)}</td>
            <td title="gml:TimePeriod">{data($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/@gml:id)}</td>
            <td title="gml:beginPosition">{$operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition}</td>
            <td title="gml:endPosition">{$operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition}</td>
        </tr>

(:D50 Done by Rait:)
let $invalidStationClassificationLink :=
    for $allLinks in $docRoot//gml:featureMember/aqd:AQD_SamplingPoint
    where not(substring($allLinks/aqd:relevantEmissions/aqd:RelevantEmissions/aqd:stationClassification/@xlink:href,1,fn:string-length("http://dd.eionet.europa.eu/vocabulary/aq/stationclassification"))="http://dd.eionet.europa.eu/vocabulary/aq/stationclassification")
    return
        <tr>
            <td title="gml:id">{data($allLinks/@gml:id)}</td>
            <td title="xlink:href">{data($allLinks/aqd:relevantEmissions/aqd:RelevantEmissions/aqd:stationClassification/@xlink:href)}</td>
        </tr>

(:D51 Done by Rait:)
let $invalidObservedPropertyCombinations :=
    for $oPC in $docRoot//gml:featureMember/aqd:AQD_SamplingPoint/aqd:environmentalObjective/aqd:EnvironmentalObjective
    where
       (($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/1" and
                    not(
                        (($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                         $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove" and
                         $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                    or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                         $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                    or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V")
                    or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/wMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V")
                        )
                    )
              )
              or
                  ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/7" and
                      not(
                                ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV" and
                                $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove-3yr" and
                                $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                       or
                                ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV" and
                                $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove-3yr" and
                                $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                       or
                                ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LTO" and
                                $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove" and
                                $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                       or
                                ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV" and
                                $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AOT40c-5yr" and
                                $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V")
                      or
                                ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LTO" and
                                 $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AOT40c" and
                                 $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V")
                      )
              )
              or

                  ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/8" and
                     not(
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                         $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hoursAbove" and
                         $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                        or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                     ))
              or
                   ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/9" and
                        not(
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V")
                        )
                   )
              or
                   ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5" and
                        not(
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                         or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                        )
                   )
              or

                   ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001" and
                        not(
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ECO" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AEI" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                        or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                        )
                   )
               or
                   ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/10" and
                        not(
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                        ))
              or
                      (($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5012" or
                              ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5012")) and
                        not(
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                        ))
               or
                      (($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5014" or
                          $oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5018" or
                                  $oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5015" or
                                  $oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5029") and
                        not(
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                        )
                        )
        )


    return
        <tr>
            <td title="gml:id">{data($oPC/../../@gml:id)}</td>
            <td title="ef:observedProperty">{data($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href)}</td>
            <td title="aqd:objectiveType">{data($oPC/aqd:objectiveType/@xlink:href)}</td>
            <td title="aqd:objectiveType">{data($oPC/aqd:reportingMetric/@xlink:href)}</td>
            <td title="aqd:objectiveType">{data($oPC/aqd:protectionTarget/@xlink:href)}</td>

        </tr>
(: D52 Done by Rait :)
let $allTrueUsedAQD :=
    for $trueUsedAQD in $docRoot//gml:featureMember/aqd:AQD_SamplingPoint
    where $trueUsedAQD/aqd:usedAQD = true()
    return $trueUsedAQD

let $allInvalidTrueUsedAQD :=
    for $invalidTrueUsedAQD in $allTrueUsedAQD
    where
        count(xmlconv:executeSparqlQuery(xmlconv:getSamplingPointAssessment($invalidTrueUsedAQD/ef:inspireId/base:Identifier/base:localId ,$invalidTrueUsedAQD/ef:inspireId/base:Identifier/base:namespace))/*) = 0
    return
        <tr>
            <td title="gml:id">{data($invalidTrueUsedAQD/@gml:id)}</td>
            <td title="base:localId">{data($invalidTrueUsedAQD/ef:inspireId/base:Identifier/base:localId)}</td>
            <td title="base:namespace">{data($invalidTrueUsedAQD/ef:inspireId/base:Identifier/base:namespace)}</td>
        </tr>

(:D53 Done by Rait :)
let $allInvalidZoneXlinks :=
    for $invalidZoneXlinks in $docRoot//gml:featureMember/aqd:AQD_SamplingPoint/aqd:zone
     where
        count(xmlconv:executeSparqlQuery(xmlconv:getSamplingPointZone($invalidZoneXlinks/@xlink:href))/*) = 0
    return
        <tr>
            <td title="gml:id">{data($invalidZoneXlinks/../@gml:id)}</td>
            <td title="aqd:zone">{data($invalidZoneXlinks/@xlink:href)}</td>
        </tr>

(:,D54,D55,D56,D57,D58,D57,D58,D59:)

return
    <table style="border-collapse:collapse;display:inline">
        <colgroup>
            <col width="15px" style="text-align:center"/>
            <col width="500px" style="text-align:left"/>
            <col width="350px" style="text-align:left"/>
            <col width="*"/>
        </colgroup>
        {xmlconv:buildResultRows("D1", "Total number of each environmental monitoring feature types",
            (), (), "", string(sum($countFeatureTypes)), "", "", $tblAllFeatureTypes)}
        <tr style="border-top:1px solid #666666">
            <td style="vertical-align:top;">{ xmlconv:getBullet("D6", if ($countD6duplicates = 0) then "info" else "error") }</td>
            <th style="vertical-align:top;">./am:inspireId/base:Identifier/base:localId shall be an unique code within namespace</th>
            <td style="vertical-align:top;">{
                if ($countD6duplicates = 0) then
                    <span style="font-size:1.3em;">All Ids are unique</span>
                else
                    concat($countD6duplicates, " error", substring("s ", number(not($countD6duplicates > 1)) * 2) ,"found") }</td>
        </tr>
        {xmlconv:buildResultRowsWithTotalCount("D8", <span>The content of /aqd:AQD_Network/ef:mediaMonitored shall resolve to any concept in
            <a href="{ $xmlconv:MEDIA_VALUE_VOCABULARY }">{ $xmlconv:MEDIA_VALUE_VOCABULARY }</a></span>,
            (), (), "ef:mediaMonitored", "", "", "", $invalidNetworkMedia)}

        {xmlconv:buildResultRowsWithTotalCount("D9", <span>The content of /aqd:AQD_Station/ef:organisationLevel shall resolve to any concept in
            <a href="{ $xmlconv:ORGANISATIONAL_LEVEL_VOCABULARY }">{ $xmlconv:ORGANISATIONAL_LEVEL_VOCABULARY }</a></span>,
            (), (), "ef:organisationLevel", "", "", "", $invalidOrganisationalLevel)}
        {xmlconv:buildResultRowsWithTotalCount("D13", <span>The content of /aqd:AQD_Station/aqd:networkType shall resolve to any concept in
            <a href="{ $xmlconv:NETWORK_TYPE_VOCABULARY }">{ $xmlconv:NETWORK_TYPE_VOCABULARY }</a></span>,
            (), (), "aqd:networkType", "", "", "", $invalidNetworkType)}

        {xmlconv:buildResultRowsWithTotalCount("D14", <span>The content of ./aqd:aggregationTimeZone attribute shall resolve to a valid code in
            <a href="{ $xmlconv:TIMEZONE_VOCABULARY }">{ $xmlconv:TIMEZONE_VOCABULARY }</a></span>,
                (), (), "aqd:aggregationTimeZone", "", "", "", $invalidTimeZone)}
        <tr style="border-top:1px solid #666666">
            <td style="vertical-align:top;">{ xmlconv:getBullet("D15", if ($countD15duplicates = 0) then "info" else "error") }</td>
            <th style="vertical-align:top;">./am:inspireId/base:Identifier/base:localId shall be an unique code within namespace</th>
            <td style="vertical-align:top;">{
                if ($countD15duplicates = 0) then
                    <span style="font-size:1.3em;">All Ids are unique</span>
                else
                    concat($countD15duplicates, " error", substring("s ", number(not($countD15duplicates > 1)) * 2) ,"found") }</td>
        </tr>
        {xmlconv:buildResultRowsWithTotalCount("D19", <span>The content of /aqd:AQD_Station/ef:mediaMonitored shall resolve to any concept in
            <a href="{ $xmlconv:MEDIA_VALUE_VOCABULARY }">{ $xmlconv:MEDIA_VALUE_VOCABULARY }</a></span>,
            (), (), "ef:mediaMonitored", "", "", "", $invalidStationMedia)}
        {xmlconv:buildResultRows("D20", "./ef:geometry/gml:Points the srsName attribute  shall  be  a  recognisable  URN .  The  following  2  srsNames  are  expected urn:ogc:def:crs:EPSG::4258 or urn:ogc:def:crs:EPSG::4326",
                $invalidPoints,(), "aqd:AQD_Station/@gml:id","All smsName attributes are valid"," invalid attribute","", ())}
        {xmlconv:buildResultRows("D21", "./ef:geometry/gml:Point/gml:pos the srsDimension attribute shall resolve to ""2"" to allow the coordinate of the station",
                $invalidPos, () , "aqd:AQD_Zone/@gml:id", "All srsDimension attributes resolve to ""2""", " invalid attribute", "",())}

       {xmlconv:buildResultRows("D23", "Total number  aqd:AQD_Station invalid operational activity periods ",
            (), $allInvalidEfOperationActivityPeriod, "", fn:string(count($allInvalidEfOperationActivityPeriod)), "", "", ())}

        {xmlconv:buildResultRows("D24", "Total number operational activity periods where ending period is unclosed (null) or have an indeterminatePosition='unknown' ",
                (), $allUnknownEfOperationActivityPeriod, "", string(count($allUnknownEfOperationActivityPeriod)), "", "", ())}
        {xmlconv:buildResultRows("D26", "./aqd:EUStationCode shall be an unique code for the station starting with ISO2-country code",
                (), $invalidDuplicateLocalIds, "", string(count($invalidDuplicateLocalIds)), "", "", ())}

        {xmlconv:buildResultRowsWithTotalCount("D27", <span>The content of /aqd:AQD_Station/aqd:meteoParams shall resolve to any concept in
            <a href="{ $xmlconv:METEO_PARAMS_VOCABULARY }">{ $xmlconv:METEO_PARAMS_VOCABULARY }</a></span>,
            (), (), "aqd:meteoParams", "", "", "", $invalidMeteoParams)}
        {xmlconv:buildResultRowsWithTotalCount("D28", <span>The content of /aqd:AQD_Station/aqd:areaClassification shall resolve to any concept in
            <a href="{ $xmlconv:AREA_CLASSIFICATION_VOCABULARY }">{ $xmlconv:AREA_CLASSIFICATION_VOCABULARY }</a></span>,
            (), (), "aqd:areaClassification", "", "", "", $invalidAreaClassification)}
        {xmlconv:buildResultRowsWithTotalCount("D29", <span>The content of /aqd:AQD_Station/aqd:dispersionLocal shall resolve to any concept in
            <a href="{ $xmlconv:DISPERSION_LOCAL_VOCABULARY }">{ $xmlconv:DISPERSION_LOCAL_VOCABULARY }</a></span>,
            (), (), "aqd:dispersionLocal", "", "", "", $invalidDispersionLocal)}
        {xmlconv:buildResultRowsWithTotalCount("D30", <span>The content of /aqd:AQD_Station/aqd:dispersionRegional shall resolve to any concept in
            <a href="{ $xmlconv:DISPERSION_REGIONAL_VOCABULARY }">{ $xmlconv:DISPERSION_REGIONAL_VOCABULARY }</a></span>,
            (), (), "aqd:dispersionRegional", "", "", "", $invalidDispersionRegional)}
        {xmlconv:buildResultRows("D31", "./AQD_SamplingPoint/ef:inspireId/base:Identifier/base:localId not unique codes: ",
                (), $invalidDuplicateSamplingPointIds, "", concat(string(count($invalidDuplicateSamplingPointIds))," errors found.") , "", "", ())}
        {xmlconv:buildResultRowsWithTotalCount("D33", <span>The content of /aqd:AQD_SamplingPoint/ef:mediaMonitored shall resolve to any concept in
            <a href="{ $xmlconv:MEDIA_VALUE_VOCABULARY }">{ $xmlconv:MEDIA_VALUE_VOCABULARY }</a></span>,
            (), (), "ef:mediaMonitored", "", "", "", $invalidSamplingPointMedia)}
        <!-- FIX ME D35 /aqd:AQD_SamplingPoint do not have ef:geometry-->
        {xmlconv:buildResultRows("D35", "./ef:geometry/gml:Point/gml:pos the srsDimension attribute shall resolve to ""2"" to allow the coordinate of the station",
                $invalidPos, () , "aqd:AQD_SamplingPoint/@gml:id", "All srsDimension attributes resolve to ""2""", " invalid attribute", "",())}

        {xmlconv:buildResultRows("D37", "Total number aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod/ invalid operational activity periods ",
                (), $allObservingCapabilityPeriod, "", concat(fn:string(count($allObservingCapabilityPeriod))," errors found"), "", "", ())}

        {xmlconv:buildResultRowsWithTotalCount("D40", <span>The content of ./ef:observedProperty shall resolve to a valid code within
            <a href="{ $xmlconv:POLLUTANT_VOCABULARY }">{ $xmlconv:POLLUTANT_VOCABULARY }</a></span>,
                (), (), "aqd:AQD_SamplingPoint", "", "", "", $invalidObservedProperty)}

        {xmlconv:buildResultRows("D45", "Total number aqd:AQD_SamplingPoint/ef:operationActivityPeriod/ef:OperationActivityPeriod/ef:activityTime/gml:TimePeriod/ invalid operational activity periods ",
                (), $allOperationActivitPeriod, "", concat(fn:string(count($allOperationActivitPeriod))," errors found"), "", "", ())}

        {xmlconv:buildResultRows("D50", "Total number/aqd:stationClassification witch resolve to http://dd.eionet.europa.eu/vocabulary/aq/stationclassification/ via xlink:href ",
                (), $invalidStationClassificationLink, "", concat(fn:string(count($invalidStationClassificationLink))," errors found"), "", "", ())}
        {xmlconv:buildResultRows("D51", "Number of invalid 3 elements /aqd:AQD_SamplingPoint/aqd:environmentalObjective/aqd:EnvironmentalObjective/ combinations: ",
                (), $invalidObservedPropertyCombinations, "", concat(fn:string(count($invalidObservedPropertyCombinations))," errors found"), "", "", ())}

        {xmlconv:buildResultRows("D52", " Number of AQD_SamplingPoint(s) witch has ./aqd:usedAQD equals “true” but does not have at least at one /aqd:samplingPointAssessment xkinked: ",
                (), $allInvalidTrueUsedAQD, "", concat(fn:string(count($allInvalidTrueUsedAQD))," errors found"), "", "", ())}
        {xmlconv:buildResultRows("D53", " Number of invalid aqd:AQD_SamplingPoint/aqd:zone xlinks: ",
                (),  $allInvalidZoneXlinks, "", concat(fn:string(count( $allInvalidZoneXlinks))," errors found"), "", "", ())}

    </table>
}
;
declare function xmlconv:checkVocabularyConceptValues($featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string)
as element(tr)*{
    xmlconv:checkVocabularyConceptValues($featureType, $element, $vocabularyUrl, "")
};
declare function xmlconv:checkVocabularyConceptValues($featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $vocabularyType as xs:string)
as element(tr)*{
    if(doc-available($source_url))
    then

        let $sparql :=
            if ($vocabularyType = "collection") then
                xmlconv:getCollectionConceptUrlSparql($vocabularyUrl)
            else
                xmlconv:getConceptUrlSparql($vocabularyUrl)
        let $crConcepts := xmlconv:executeSparqlQuery($sparql)

        for $rec in doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]
        for $conceptUrl in $rec/child::*[name() = $element]/@xlink:href
        let $conceptUrl := normalize-space($conceptUrl)

        where string-length($conceptUrl) > 0

        return
            <tr isvalid="{ xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl) }">
                <td title="Feature type">{ $featureType }</td>
                <td title="gml:id">{data($rec/@gml:id)}</td>
                <td title="ef:inspireId">{data($rec/ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:inspireId">{data($rec/aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="ef:name">{data($rec/ef:name)}</td>
                <td title="{ $element }" style="color:red">{$conceptUrl}</td>
            </tr>
    else
        ()
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

(:
 : ======================================================================
 : Main function
 : ======================================================================
 :)
declare function xmlconv:proceed($source_url as xs:string) {

let $countFeatures := count(doc($source_url)//gml:featureMember/descendant::*[
    not(empty(index-of($xmlconv:FEATURE_TYPES, name())))]
    )
let $result := if ($countFeatures > 0) then xmlconv:checkReport($source_url) else ()

return
<div class="feedbacktext">
    { xmlconv:javaScript() }
    <div>
        <h2>Check environmental monitoring feature types - Dataflow D</h2>
        {
        if ( $countFeatures = 0) then
            <p>No environmental monitoring feature type elements ({string-join($xmlconv:FEATURE_TYPES, ", ")}) found from this XML.</p>
        else
            (<p>This feedback report provides a summary overview of feature types reported and some consistency checks defined in Dataflow D.
            Red bullet in front of the test result indicates that errenous records found from the delivery.
            Blue bullet means that the data confirms to rule, but additional feedback is provided. </p>,
            <p>Please click on the "Show records" link to see more details.</p>,
            $result
            )
        }
    </div>
</div>

};
xmlconv:proceed( $source_url )

