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
 : @author Enriko Käsper
 :)

declare namespace xmlconv = "http://converters.eionet.europa.eu";
declare namespace aqd = "http://aqd.ec.europa.eu/aqd/0.3.7c";
declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace am = "http://inspire.ec.europa.eu/schemas/am/3.0rc3";
declare namespace ef = "http://inspire.ec.europa.eu/schemas/ef/3.0rc3";
declare namespace base = "http://inspire.ec.europa.eu/schemas/base/3.3rc3/";
declare namespace gn = "urn:x-inspire:specification:gmlas:GeographicalNames:3.0";
declare namespace base2 = "http://inspire.ec.europa.eu/schemas/base2/1.0rc3";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace xlink = "http://www.w3.org/1999/xlink";

(:~ declare Content Registry SPARQL endpoint:)
declare variable $xmlconv:CR_SPARQL_URL := "http://cr.eionet.europa.eu/sparql";

declare variable $xmlconv:ISO2_CODES as xs:string* := ("AL","AT","BA","BE","BG","CH","CY","CZ","DE","DK","DZ","EE","EG","ES","FI",
    "FR","GB","GR","HR","HU","IE","IL","IS","IT","JO","LB","LI","LT","LU","LV","MA","ME","MK","MT","NL","NO","PL","PS","PT",
     "RO","RS","SE","SI","SK","TN","TR","XK","UK");

declare variable $xmlconv:FEATURE_TYPES := ("aqd:AQD_Network", "aqd:AQD_Station", "aqd:AQD_StationProcess", "aqd:AQD_Sample",
"aqd:AQD_RepresentativeArea", "aqd:AQD_SamplingPoint");


declare variable $xmlconv:MEDIA_VALUE_VOCABULARY_BASE_URI := "http://inspire.ec.europa.eu/codeList/MediaValue/";
declare variable $xmlconv:MEDIA_VALUE_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/inspire/MediaValue/";
declare variable $xmlconv:ORGANISATIONAL_LEVEL_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/organisationallevel/";
declare variable $xmlconv:NETWORK_TYPE_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/networktype/";
declare variable $xmlconv:METEO_PARAMS_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/meteoparams/";
declare variable $xmlconv:AREA_CLASSIFICATION_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/areaclassification/";
declare variable $xmlconv:DISPERSION_LOCAL_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/dispersionlocal/";
declare variable $xmlconv:DISPERSION_REGIONAL_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/dispersionregional/";


(:===================================================================:)
(: Variable given as an external parameter by the QA service                                                 :)
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
                        concat($countInvalidValues, $invalidMsg, substring("s ", number(not($countInvalidValues > 1)) * 2) ,"found")
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
        count(doc($source_url)//gml:featureMember/child::*[name()=$featureType])
let $tblAllFeatureTypes :=
    for $featureType at $pos in $xmlconv:FEATURE_TYPES
    where $countFeatureTypes[$pos] > 0
    return
        <tr>
            <td title="Feature type">{ $featureType }</td>
            <td title="Total number">{$countFeatureTypes[$pos]}</td>
        </tr>

(: D8 :)
let $invalidNetworkMedia := xmlconv:checkVocabularyConceptValues("aqd:AQD_Network", "ef:mediaMonitored", $xmlconv:MEDIA_VALUE_VOCABULARY_BASE_URI)
(: D12 :)
let $invalidOrganisationalLevel := xmlconv:checkVocabularyConceptValues("aqd:AQD_Station", "ef:organisationLevel", $xmlconv:ORGANISATIONAL_LEVEL_VOCABULARY)
(: D13 :)
let $invalidNetworkType := xmlconv:checkVocabularyConceptValues("aqd:AQD_Station", "aqd:networkType", $xmlconv:NETWORK_TYPE_VOCABULARY)
(: D19 :)
let $invalidStationMedia := xmlconv:checkVocabularyConceptValues("aqd:AQD_Station", "ef:mediaMonitored", $xmlconv:MEDIA_VALUE_VOCABULARY_BASE_URI)
(: D27 :)
let $invalidMeteoParams := xmlconv:checkVocabularyConceptValues("aqd:AQD_Station", "aqd:meteoParams", $xmlconv:METEO_PARAMS_VOCABULARY)
(: D28 :)
let $invalidAreaClassification := xmlconv:checkVocabularyConceptValues("aqd:AQD_Station", "aqd:areaClassification", $xmlconv:AREA_CLASSIFICATION_VOCABULARY)
(: D29 :)
let $invalidDispersionLocal := xmlconv:checkVocabularyConceptValues("aqd:AQD_Station", "aqd:dispersionLocal", $xmlconv:DISPERSION_LOCAL_VOCABULARY)
(: D30 :)
let $invalidDispersionRegional := xmlconv:checkVocabularyConceptValues("aqd:AQD_Station", "aqd:dispersionRegional", $xmlconv:DISPERSION_REGIONAL_VOCABULARY)
(: D33 :)
let $invalidSamplingPointMedia := xmlconv:checkVocabularyConceptValues("aqd:AQD_SamplingPoint", "ef:mediaMonitored", $xmlconv:MEDIA_VALUE_VOCABULARY_BASE_URI)

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
        {xmlconv:buildResultRowsWithTotalCount("D8", <span>The content of /aqd:AQD_Network/ef:mediaMonitored shall resolve to any concept in
            <a href="{ $xmlconv:MEDIA_VALUE_VOCABULARY }">{ $xmlconv:MEDIA_VALUE_VOCABULARY }</a></span>,
            (), (), "ef:mediaMonitored", "", "", "", $invalidNetworkMedia)}
        {xmlconv:buildResultRowsWithTotalCount("D12", <span>The content of /aqd:AQD_Station/ef:organisationLevel shall resolve to any concept in
            <a href="{ $xmlconv:ORGANISATIONAL_LEVEL_VOCABULARY }">{ $xmlconv:ORGANISATIONAL_LEVEL_VOCABULARY }</a></span>,
            (), (), "ef:organisationLevel", "", "", "", $invalidOrganisationalLevel)}
        {xmlconv:buildResultRowsWithTotalCount("D13", <span>The content of /aqd:AQD_Station/aqd:networkType shall resolve to any concept in
            <a href="{ $xmlconv:NETWORK_TYPE_VOCABULARY }">{ $xmlconv:NETWORK_TYPE_VOCABULARY }</a></span>,
            (), (), "aqd:networkType", "", "", "", $invalidNetworkType)}
        {xmlconv:buildResultRowsWithTotalCount("D19", <span>The content of /aqd:AQD_Station/ef:mediaMonitored shall resolve to any concept in
            <a href="{ $xmlconv:MEDIA_VALUE_VOCABULARY }">{ $xmlconv:MEDIA_VALUE_VOCABULARY }</a></span>,
            (), (), "ef:mediaMonitored", "", "", "", $invalidStationMedia)}
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
        {xmlconv:buildResultRowsWithTotalCount("D33", <span>The content of /aqd:AQD_SamplingPoint/ef:mediaMonitored shall resolve to any concept in
            <a href="{ $xmlconv:MEDIA_VALUE_VOCABULARY }">{ $xmlconv:MEDIA_VALUE_VOCABULARY }</a></span>,
            (), (), "ef:mediaMonitored", "", "", "", $invalidSamplingPointMedia)}
    </table>
}
;
declare function xmlconv:checkVocabularyConceptValues($featureType as xs:string, $element as xs:string, $vocabularyUrl)
as element(tr)*{

    let $sparql := xmlconv:getConceptUrlSparql($vocabularyUrl)
    let $crConcepts := xmlconv:executeSparqlQuery($sparql)

    for $rec in doc($source_url)//gml:featureMember/child::*[name()=$featureType]
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

let $countFeatures := count(doc($source_url)//gml:featureMember/child::*[
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

