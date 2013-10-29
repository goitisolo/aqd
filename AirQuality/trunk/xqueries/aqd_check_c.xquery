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
(:===================================================================:)
(: Variable given as an external parameter by the QA service                                                 :)
(:===================================================================:)

declare variable $source_url as xs:string external;

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
            "brown"
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
let $envelopeUrl := xmlconv:getEnvelopeXML($source_url)
let $countryCode := if(string-length($envelopeUrl)>0) then lower-case(fn:doc($envelopeUrl)/envelope/countrycode) else ""
:)

(: FIXME
let $countryCode := "gb"
let $countryCode := if ($countryCode = "gb") then "uk" else if ($countryCode = "gr") then "el" else $countryCode
:)

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
    where count(index-of($gmlIds, lower-case(normalize-space($id)))) > 1
    return
        $id

(: C16 If ./aqd:zone xlink:href shall be current, then ./AQD_zone/aqd:operationActivityPeriod/gml:endPosition shall be equal to “9999-12-31 23:59:59Z” or nulled (blank)  :)
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

(: C22 If The lifecycle information of ./aqd:assessmentMethods/aqd:AssessmentMethods/aqd:*AssessmentMetadata xlink:href shall be current,
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

(: C24 /aqd:AQD_SamplingPoint/aqd:usedAQD or /aqd:AQD_ModelType/aqd:used shall EQUAL “true” for all ./aqd:assessmentMethods/aqd:AssessmentMethods/aqd:*AssessmentMetadata xlink:href citations :)
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
        {xmlconv:buildResultRows("C16", "The lifecycle information of ./aqd:zone xlink:href shall be current, ./AQD_Zone/aqd:operationActivityPeriod/gml:endPosition shall be equal to '9999-12-31 23:59:59Z' or nulled (blank).",
            (), $invalidZoneGmlEndPosition, "aqd:AQD_Zone", "All values are valid", " invalid value", "", $invalidZoneGmlEndPosition)}
        {xmlconv:buildResultRows("C22", "The lifecycle information of ./aqd:assessmentMethods/aqd:AssessmentMethods/aqd:*AssessmentMetadata xlink:href shall be current, /AQD_SamplingPoint/aqd:operationActivityPeriod/gml:endPosition or /AQD_ModelType/aqd:operationActivityPeriod/gml:endPosition shall be equal to '9999-12-31 23:59:59Z' or nulled (blank).",
            (), $invalidAssessmentGmlEndPosition, "aqd:AQD_Model or aqd:AQD_SamplingPoint", "All values are valid", " invalid value", "", ())}
        {xmlconv:buildResultRows("C24", "/aqd:AQD_SamplingPoint/aqd:usedAQD or /aqd:AQD_Modelype/aqd:used shall EQUAL 'true' for all ./aqd:assessmentMethods/aqd:AssessmentMethods/aqd:*AssessmentMetadata xlink:href citations.",
            (), $invalidAssessmentUsed, "aqd:AQD_Model or aqd:AQD_SamplingPoint", "All values are valid", " invalid value", "", ())}
    </table>
}
;


(:
 : ======================================================================
 : Main function
 : ======================================================================
 :)
declare function xmlconv:proceed($source_url as xs:string) {

let $countZones := count(doc($source_url)//gml:featureMember/aqd:AQD_AssessmentRegime)
let $result := if ($countZones > 0) then xmlconv:checkReport($source_url) else ()

return
<div class="feedbacktext">
    { xmlconv:javaScript() }
    <div>
        <h2>Check air quality assessment regimes - Dataflow C</h2>
        {
        if ( $countZones = 0) then
            <p>No aqd:AQD_AssessmentRegime elements found from this XML.</p>
        else
            (<p>This check evaluated the delivery by executing the tier-1 tests on air quality assessment regimes data in Dataflow C.
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

