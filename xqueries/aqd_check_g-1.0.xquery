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
declare variable $xmlconv:VALID_REPMETRIC_IDS as xs:string* := ("aMean", "wMean", "hrsAbove", "daysAbove");
declare variable $xmlconv:VALID_AREACLASSIFICATION_IDS as xs:string* := ("1", "2", "3", "4", "5", "6");
declare variable $xmlconv:VALID_OBJECTIVETYPE_IDS as xs:string* := ("TV", "LV", "CL");



declare variable $xmlconv:POLLUTANT_VOCABULARY as xs:string := "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/";
declare variable $xmlconv:REPMETRIC_VOCABULARY as xs:string := "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/";
declare variable $xmlconv:OBJECTIVETYPE_VOCABULARY as xs:string := "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/";
declare variable $xmlconv:AREACLASSIFICATION_VOCABULARY as xs:string := "http://dd.eionet.europa.eu/vocabulary/aq/areaclassification/";
declare variable $source_url as xs:string external;
(:
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
let $countryCode := "hr"
:)
(:
let $countryCode := if ($countryCode = "gb") then "uk" else if ($countryCode = "gr") then "el" else $countryCode
:)
let $countryCode := 'gr'
(: =============================================== FIXME !!! :)

let $envelopeUrl := xmlconv:getEnvelopeXML($source_url)
let $countryCode := if(string-length($envelopeUrl)>0) then lower-case(fn:doc($envelopeUrl)/envelope/countrycode) else ""


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



(: G19
.//aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType xlink:href attribute shall resolve to one of
:)
let $invalidObjectiveTypes := xmlconv:isinvalidDDConceptLimited("aqd:exceedanceDescriptionBase", "aqd:EnvironmentalObjective", "aqd:objectiveType", $xmlconv:OBJECTIVETYPE_VOCABULARY, $xmlconv:VALID_OBJECTIVETYPE_IDS)

(: G20 - ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric xlink:href attribute shall resolve to one of
... :)
let $invalidReportingMetric := xmlconv:isinvalidDDConceptLimited("aqd:exceedanceDescriptionBase", "aqd:EnvironmentalObjective", "aqd:reportingMetric",
    $xmlconv:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS)


(: G21
WHERE
./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType xlink:href attribute
EQUALS http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL
./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget xlink:href attribute
EQUALS http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V

:)
let $invalidobjectiveTypesForVEG :=
    for $obj in $docRoot//aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective
    where
        $obj/aqd:protectionTarget/@xlink:href != 'http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V'
        and $obj/aqd:objectiveType/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL'
   return $obj/../../../..

   let $tblInvalidobjectiveTypesForVEG :=
   for $rec in $invalidobjectiveTypesForVEG
   (: FIXME - there are sev eral Env Objects in XML and schema does not correspond to word doc :)
   return
        <tr>
            <td title="gml:id">{data($rec/@gml:id)}</td>
            <td title="aqd:protectionTarget">{data($rec//aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href)}</td>
            <td title="aqd:objectiveType">{data($rec//aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href)}</td>
        </tr>

(: G25 /aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:surfaceArea uom attribute shall be “km2” :)
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
        </tr>
(: G26 /aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:roadLength uom attribute shall be “km” :)
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
        </tr>

(: G27/aqd:AQD_Attainment
   /aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:areaClassification xlink:href attribute shall resolve to
... :)
let $invalidClassification :=
    xmlconv:checkVocabularyConceptValues("aqd:exceedanceDescriptionBase", "aqd:ExceedanceArea", "aqd:areaClassification", $xmlconv:AREACLASSIFICATION_VOCABULARY)


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
        {xmlconv:buildResultRows("G5", "Total number of exceedances",
            (), (), "", string($countExceedances), " exceedance", "", $tblAllExceedances)}
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

        {xmlconv:buildResultRowsWithTotalCount("G19", <span>./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType xlink:href attribute shall resolve to one of
            <a href="{ $xmlconv:OBJECTIVETYPE_VOCABULARY }">{ $xmlconv:OBJECTIVETYPE_VOCABULARY }</a>
            Allowed items: {xmlconv:buildVocItemsList("G19", $xmlconv:OBJECTIVETYPE_VOCABULARY, $xmlconv:VALID_OBJECTIVETYPE_IDS)}</span>,
            (), (), "aqd:objectivetype", "", "", "", $invalidObjectiveTypes)}

        {xmlconv:buildResultRowsWithTotalCount("G20", <span>The content of ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:EnvironmentalObjective/aqd:reportingMetric shall resolve to a valid concept in
            <a href="{ $xmlconv:REPMETRIC_VOCABULARY }">{ $xmlconv:REPMETRIC_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G20", $xmlconv:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS)}</span>,
            (), (), "aqd:reportingMetric", "", "", "", $invalidReportingMetric)}

        {xmlconv:buildResultRows("G21", "If
                    ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType xlink:href attribute EQUALS http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL (Critical)
                        ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget xlink:href attribute has to be http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V (Vegetation)",
            $invalidobjectiveTypesForVEG, (), "", "No invalid objective types for Vegetation found", " invalid", "", $tblInvalidobjectiveTypesForVEG)}

        {xmlconv:buildResultRows("G25", "Surface area must be measured in km2",
            $invalidSurfaceAreas, (), "", "No invalid surface area units found", " invalid", "", $tblInvalidSurfaceAreas)}
        {xmlconv:buildResultRows("G26", "Road Length must be measured in km",
            $invalidRoadLengths, (), "", "No invalid road length units found", " invalid", "", $tblinvalidRoadLengths)}
        {xmlconv:buildResultRowsWithTotalCount("G27", <span>The content of /aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:areaClassification xlink:href attribute shall resolve to
           a concept in
            <a href="{ $xmlconv:AREACLASSIFICATION_VOCABULARY }">{ $xmlconv:AREACLASSIFICATION_VOCABULARY }</a></span>,
            (), (), "aqd:reportingMetric", "", "", "", $invalidClassification)}

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

