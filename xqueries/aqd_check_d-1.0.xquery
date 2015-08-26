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
 : @author Rait Väli and Enriko Käsper
 : small modification added by Jaume Targa (ETC/ACM) to align with QA document
 :
 :Quality Assurance and Control rules version: 4.0
 :)

module namespace xmlconv = "http://converters.eionet.europa.eu/dataflowD";
declare namespace aqd = "http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0";
declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace am = "http://inspire.ec.europa.eu/schemas/am/3.0";
declare namespace ef = "http://inspire.ec.europa.eu/schemas/ef/3.0";
declare namespace base = "http://inspire.ec.europa.eu/schemas/base/3.3";
declare namespace gn = "urn:x-inspire:specification:gmlas:GeographicalNames:3.0";
declare namespace base2 = "http://inspire.ec.europa.eu/schemas/base2/1.0";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace ompr="http://inspire.ec.europa.eu/schemas/ompr/2.0";
declare namespace sams="http://www.opengis.net/samplingSpatial/2.0";

(:
declare variable $source_url := "../test/ES_D_SamplingPoint-1.xml";
declare variable $country := "es";
declare variable $source_url := "../test/DK_D_Sample.xml";
declare variable $source_url := "../test/ES_D_Station.xml";
declare variable $country := "dk";
declare variable $source_url := "../test/REP_D-DK_NERI.xml";

declare variable $country := "es";
declare variable $source_url := "../test/ES_D_Sample.xml";
declare variable $source_url := "../test/D_GIB_Complete_Corrupted.xml";
declare variable $country := "gi";
:)

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
declare variable $xmlconv:METEO_PARAMS_VOCABULARY := ("http://vocab.nerc.ac.uk/collection/P07/current/","http://vocab.nerc.ac.uk/collection/I01/current/","http://dd.eionet.europa.eu/vocabulary/aq/meteoparameter/");
declare variable $xmlconv:METEO_PARAMS_VOCABULARY_I01 := "http://vocab.nerc.ac.uk/collection/I01/current/";
declare variable $xmlconv:METEO_PARAMS_VOCABULARY_aq := "http://dd.eionet.europa.eu/vocabulary/aq/meteoparameter/";
declare variable $xmlconv:AREA_CLASSIFICATION_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/areaclassification/";
declare variable $xmlconv:DISPERSION_LOCAL_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/dispersionlocal/";
declare variable $xmlconv:DISPERSION_REGIONAL_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/dispersionregional/";
declare variable $xmlconv:TIMEZONE_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/timezone/";
declare variable $xmlconv:POLLUTANT_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/";
declare variable $xmlconv:MEASUREMENTTYPE_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/measurementtype/";
declare variable $xmlconv:MEASUREMENTMETHOD_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/measurementmethod/";
declare variable $xmlconv:ANALYTICALTECHNIQUE_VOCABULARY :=  "http://dd.eionet.europa.eu/vocabulary/aq/analyticaltechnique/";
declare variable $xmlconv:SAMPLINGEQUIPMENT_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/samplingequipment/";
declare variable $xmlconv:MEASUREMENTEQUIPMENT_VOCABULARY :="http://dd.eionet.europa.eu/vocabulary/aq/measurementequipment/";
declare variable $xmlconv:UOM_CONCENTRATION_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/uom/concentration/";
declare variable $xmlconv:EQUIVALENCEDEMONSTRATED_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/equivalencedemonstrated/";


(:===================================================================:)
(: Variable given as an external parameter by the QA service :)
(:===================================================================:)
(:
declare variable $source_url as xs:string external;
:)
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



 (:---------------------------------Old xmlconv:executeSparqlQuery function----------------------------------------------------------------------:)
(:~ Function executes given SPARQL query and returns result elements in SPARQL result format.
 : URL parameters will be correctly encoded.
 : @param $sparql SPARQL query.
 : @return sparql:results element containing zero or more sparql:result subelements in SPARQL result format.
 :)
declare function xmlconv:executeSparqlEndpoint($sparql as xs:string)
as element(sparql:results)
{
    let $uri := xmlconv:getSparqlEndpointUrl($sparql, "xml")

    return
        if(doc-available($uri))then
        fn:doc($uri)//sparql:results
        else
            <sparql:results/>

};

(:----------------------------------------------------------------------------------------------------------------------------------------------:)
declare function xmlconv:setLimitAndOffset($sparql as xs:string, $limit as xs:string, $offset as xs:string)
as xs:string
{
    concat($sparql," offset ",$offset," limit ",$limit)
};

declare function xmlconv:toCountSparql($sparql as xs:string)
as xs:string
{       let $s :=if (fn:contains($sparql,"order")) then tokenize($sparql, "order") else tokenize($sparql, "ORDER")
        let $firstPart := tokenize($s[1], "SELECT")
        let $secondPart := tokenize($s[1], "WHERE")
    return concat($firstPart[1], " SELECT count(*) WHERE ", $secondPart[2])
};

declare function xmlconv:countsSparqlResults($sparql as xs:string)
as xs:integer
{    let $countingSparql := xmlconv:toCountSparql($sparql)
    let $endpoint :=  xmlconv:executeSparqlEndpoint($countingSparql)



    (: Counting all results:)
    let $count :=  $countingSparql
    let $isCountAvailable := string-length($count) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($count, "xml"))
    let $countResult := if($isCountAvailable) then (data($endpoint//sparql:binding[@name='callret-0']/sparql:literal)) else 0
    return $countResult[1]
};

declare function xmlconv:executeSparqlQuery($sparql as xs:string)
as element(sparql:result)*
{

    let $limit := number(2000)
    let $countResult := xmlconv:countsSparqlResults($sparql)

    (:integer - how many times must sparql function repeat :)
    let $divCountResult := if($countResult>0) then ceiling(number($countResult) div number($limit)) else number("1")

    (:Collects all sparql results:)
    let $allResults :=
        for $r in (1 to  xs:integer(number($divCountResult)))
            let $offset := if ($r > 1) then string(((number($r)-1) * $limit)) else "0"
            let $resultXml := xmlconv:setLimitAndOffset($sparql,xs:string($limit), $offset)
            let $isResultsAvailable := string-length($resultXml) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultXml, "xml"))
        let $result := if($isResultsAvailable) then xmlconv:executeSparqlEndpoint($resultXml)//sparql:result else ()
    return $result

    return  $allResults
};

(:----------------------------------------------------------------------------------------------------------------------------------------------:)


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

declare function xmlconv:is-a-number( $value as xs:anyAtomicType? )
as xs:boolean {
    string(number($value)) != 'NaN'
} ;

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
    $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string, $recordDetails as element(tr)*)
as element(tr)*{
    xmlconv:buildResultRows($ruleCode, $text, $invalidStrValues, $invalidValues,
        $valueHeading, $validMsg, $invalidMsg, $skippedMsg, $errorLevel, $recordDetails, fn:true())
};


declare function xmlconv:buildResultRows($ruleCode as xs:string, $text, $invalidStrValues as xs:string*, $invalidValues as element()*,
    $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string, $recordDetails as element(tr)*,
    $invalidValuesAreInvalid as xs:boolean)
as element(tr)*{

    let $countInvalidValues := count($invalidStrValues) + count($invalidValues)

    let $recordDetails := if (count($invalidValues) > 0) then $invalidValues else $recordDetails

    let $bulletType := if (string-length($skippedMsg) > 0) then "skipped" else if ($countInvalidValues = 0) then "info" else $errorLevel


(: sometimes warning is needed if count is 0 :)
    let $bulletType :=
    if (not($invalidValuesAreInvalid)) then
        if (string-length($skippedMsg) > 0) then "skipped" else if ($countInvalidValues = 0) then $errorLevel else "info"
    else
        $bulletType


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
                        concat($countInvalidValues, $invalidMsg, substring(" ", number(not($countInvalidValues > 1)) * 2) ," found")
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
    $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string,$recordDetails as element(tr)*)
as element(tr)*{

    let $countCheckedRecords := count($recordDetails)
    let $invalidValues := $recordDetails[./@isvalid = "false"]

    let $skippedMsg := if ($countCheckedRecords = 0) then "No values found to check" else ""
    let $invalidMsg := if (count($invalidValues) > 0) then concat(" invalid value", substring("s ", number(not(count($invalidValues) > 1)) * 2), " found out of ", $countCheckedRecords, " checked") else ""
    let $validMsg := if (count($invalidValues) = 0) then concat("Checked ", $countCheckedRecords, " value", substring("s", number(not($countCheckedRecords > 1)) * 2), ", all valid") else ""

    return
        xmlconv:buildResultRows($ruleCode, $text, $invalidStrValues, $invalidValues,
            $valueHeading, $validMsg, $invalidMsg, $skippedMsg,$errorLevel, ())
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

declare function xmlconv:getZonesSparql($nameSpaces as xs:string*)
as xs:string
{
    let $nameSpacesStr :=
        for $nameSpace in $nameSpaces
        return concat("""", $nameSpace, """")

    let $nameSpacesStr :=
        fn:string-join($nameSpacesStr, ",")

    return     concat(
            "PREFIX aqr: <http://reference.eionet.europa.eu/aq/ontology/>

            SELECT ?inspireid
            FROM <http://rdfdata.eionet.europa.eu/airquality/zones.ttl>
            WHERE {
              ?zoneuri a aqr:Zone ;
                        aqr:inspireNamespace ?namespace;
                         aqr:inspireId ?inspireid .
            filter (?namespace in (", $nameSpacesStr,  "))
    } order by ?zoneuri"
    )
};

(:
    Rule implementations
:)
declare function xmlconv:checkReport($source_url as xs:string, $countryCode as xs:string)
as element(table) {


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

        (: D2 :)

let $D2Combinations :=
    for $featureType in $xmlconv:FEATURE_TYPES
    return
        doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

let $nameSpaces := distinct-values($docRoot//base:namespace)
let $zonesSparql := xmlconv:getZonesSparql($nameSpaces)
let $isZonesAvailable := string-length($zonesSparql) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($zonesSparql, "xml"))
let $knownZones := if ($isZonesAvailable ) then distinct-values(data(xmlconv:executeSparqlQuery($zonesSparql)//sparql:binding[@name='inspireid']/sparql:literal)) else ()
let $unknownZones :=
    for $zone in $D2Combinations
    let $id := if (empty($zone/@gml:id)) then "" else data($zone/@gml:id)
    where empty(index-of($knownZones, $id))
    return $zone

let $tblD2 :=
    for $rec in $unknownZones
    return
        $rec/@gml:id

(: D3 :)

let $D3Combinations :=
    for $featureType in $xmlconv:FEATURE_TYPES
    return
        doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

let $nameSpaces := distinct-values($docRoot//base:namespace)
let $zonesSparql := xmlconv:getZonesSparql($nameSpaces)
let $isZonesAvailable := string-length($zonesSparql) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($zonesSparql, "xml"))
let $knownZones := if ($isZonesAvailable ) then distinct-values(data(xmlconv:executeSparqlQuery($zonesSparql)//sparql:binding[@name='inspireid']/sparql:literal)) else ()
let $unknownZones :=
    for $zone in $D3Combinations
    let $id := if (empty($zone/@gml:id)) then "" else data($zone/@gml:id)
    where empty(index-of($knownZones, $id))=false()
    return $zone

let $tblD3 :=
    for $rec in $unknownZones
    return
        $rec/@gml:id

(: D4 :)
let $D4Combinations :=
    for $featureType in $xmlconv:FEATURE_TYPES
    return
        doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

let $allD4Combinations :=
    for $aqdModel in $D4Combinations
    return concat(data($aqdModel/@gml:id), "#", $aqdModel/ef:inspireId/base:Identifier/base:localId, "#", $aqdModel/ompr:inspireId/base:Identifier/base:localId, "#", $aqdModel/ef:name, "#", $aqdModel/ompr:name )

let $allD4Combinations := fn:distinct-values($allD4Combinations)
let $tblD4 :=
    for $rec in $allD4Combinations
    let $modelType := substring-before($rec, "#")
    let $tmpStr := substring-after($rec, concat($modelType, "#"))
    let $inspireId := substring-before($tmpStr, "#")
    let $tmpInspireId := substring-after($tmpStr, concat($inspireId, "#"))
    let $aqdInspireId := substring-before($tmpInspireId, "#")
    let $tmpEfName := substring-after($tmpInspireId, concat($aqdInspireId, "#"))
    let $efName := substring-before($tmpEfName, "#")
    let $omprName := substring-after($tmpEfName,concat($efName,"#"))
    return
        <tr>

            <td title="gml:id">{xmlconv:checkLink($modelType)}</td>
            <td title="ef:inspireId/localId">{xmlconv:checkLink($inspireId)}</td>
            <td title="ompr:inspireId/localId">{xmlconv:checkLink($aqdInspireId)}</td>
            <td title="ef:name">{xmlconv:checkLink($efName)}</td>
            <td title="ompr:name">{xmlconv:checkLink($omprName)}</td>
        </tr>

(: D5 :)

let $D5Combinations :=
    for $featureType in $xmlconv:FEATURE_TYPES
    return
        doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

let $gmlIds := $D5Combinations/lower-case(normalize-space(@gml:id))
let $duplicateGmlIds := distinct-values(
        for $id in $D5Combinations/@gml:id
        where string-length(normalize-space($id)) > 0 and count(index-of($gmlIds, lower-case(normalize-space($id)))) > 1
        return
            $id
)
let $efInspireIds := for $id in $D5Combinations/ef:inspireId
return
    lower-case(concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
            ", ", normalize-space($id/base:Identifier/base:versionId), "]"))
let $duplicateefInspireIds := distinct-values(
        for $id in $D5Combinations/ef:inspireId
        let $key :=
            concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
                    ", ", normalize-space($id/base:Identifier/base:versionId), "]")
        where string-length(normalize-space($id/base:Identifier/base:localId)) > 0 and count(index-of($efInspireIds, lower-case($key))) > 1
        return
            $key
)


let $aqdInspireIds := for $id in $D5Combinations/aqd:inspireId
return
    lower-case(concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
            ", ", normalize-space($id/base:Identifier/base:versionId), "]"))
let $duplicateaqdInspireIds := distinct-values(
        for $id in $D5Combinations/aqd:inspireId
        let $key :=
            concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
                    ", ", normalize-space($id/base:Identifier/base:versionId), "]")
        where  string-length(normalize-space($id/base:Identifier/base:localId)) > 0 and count(index-of($aqdInspireIds, lower-case($key))) > 1
        return
            $key
)


let $countGmlIdDuplicates := count($duplicateGmlIds)
let $countefInspireIdDuplicates := count($duplicateefInspireIds)
let $countaqdInspireIdDuplicates := count($duplicateaqdInspireIds)
let $countD5duplicates := $countGmlIdDuplicates + $countefInspireIdDuplicates + $countaqdInspireIdDuplicates

(: D6 Done by Rait ./ef:inspireId/base:Identifier/base:localId shall be an unique code for AQD_network and unique within the namespace.:)
let $amInspireIds := $docRoot//aqd:AQD_Network/ef:inspireId/base:Identifier/concat(lower-case(normalize-space(base:namespace)), '##',
        lower-case(normalize-space(base:localId)))
let $duplicateEUStationCode := distinct-values(
        for $identifier in $docRoot//aqd:AQD_Network/ef:inspireId/base:Identifier
        where string-length(normalize-space($identifier/base:localId)) > 0 and count(index-of($amInspireIds,
                concat(lower-case(normalize-space($identifier/base:namespace)), '##', lower-case(normalize-space($identifier/base:localId))))) > 1
        return
            concat(normalize-space($identifier/base:namespace), ':', normalize-space($identifier/base:localId))
)
let $countAmInspireIdDuplicates := count($duplicateEUStationCode)
let $countD6duplicates := $countAmInspireIdDuplicates

(: D7 :)
let $allBaseNamespace := distinct-values($docRoot//aqd:AQD_Network/ef:inspireId/base:Identifier/base:namespace)
let  $tblD7 :=
    for $id in $allBaseNamespace
    let $localId := $docRoot//aqd:AQD_Network/ef:inspireId/base:Identifier[base:namespace = $id]/base:localId
    return
        <tr>
	    <td title="feature">Network(s)</td>
            <td title="base:namespace">{$id}</td>
            <td title="base:localId">{count($localId)}</td>
        </tr>

(: D8 :)
let $invalidNetworkMedia := xmlconv:checkVocabularyConceptValues($source_url, "aqd:AQD_Network", "ef:mediaMonitored", $xmlconv:MEDIA_VALUE_VOCABULARY_BASE_URI)
(: D9 :)
let $invalidOrganisationalLevel := xmlconv:checkVocabularyConceptValues($source_url, "aqd:AQD_Network", "ef:organisationLevel", $xmlconv:ORGANISATIONAL_LEVEL_VOCABULARY)
(: D10 :)
let $invalidNetworkType := xmlconv:checkVocabularyConceptValues($source_url, "aqd:AQD_Network", "aqd:networkType", $xmlconv:NETWORK_TYPE_VOCABULARY)

(: D11 :)
let $invalidAQDNetworkBeginPosition := distinct-values($docRoot//aqd:AQD_Network/aqd:operationActivityPeriod/gml:TimePeriod[((gml:beginPosition>=gml:endPosition) and (gml:endPosition!=""))]/../../@gml:id)
(: D14 Done by Rait  :)
let $invalidTimeZone := xmlconv:checkVocabularyConceptValues($source_url, "aqd:AQD_Network", "aqd:aggregationTimeZone", $xmlconv:TIMEZONE_VOCABULARY)
(: D15 Done by Rait :)
let $amInspireIds := $docRoot//aqd:AQD_Station/ef:inspireId/base:Identifier/concat(lower-case(normalize-space(base:namespace)), '##',
        lower-case(normalize-space(base:localId)))

let $duplicateEUStationCode := distinct-values(
        for $identifier in $docRoot//aqd:AQD_Station/ef:inspireId/base:Identifier
        where string-length(normalize-space($identifier/base:localId)) > 0 and count(index-of($amInspireIds,
                concat(lower-case(normalize-space($identifier/base:namespace)), '##', lower-case(normalize-space($identifier/base:localId))))) > 1
        return
            concat(normalize-space($identifier/base:namespace), ':', normalize-space($identifier/base:localId))
)
let $countAmInspireIdDuplicates := count($duplicateEUStationCode)
let $countD15duplicates := $countAmInspireIdDuplicates


(:
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
:)


(: D16 :)

let $allBaseNamespace := distinct-values($docRoot//aqd:AQD_Station/ef:inspireId/base:Identifier/base:namespace)

let  $tblD16 :=
    for $id in $allBaseNamespace
    let $localId := $docRoot//aqd:AQD_Station/ef:inspireId/base:Identifier[base:namespace = $id]/base:localId
    return
        <tr>
	    <td title="feature">Station(s)</td>
            <td title="base:namespace">{$id}</td>
            <td title="base:localId">{count($localId)}</td>
        </tr>

(: D19 :)
(:
let $sparqlD19 := xmlconv:getConceptUrlSparql($xmlconv:MEDIA_VALUE_VOCABULARY_BASE_URI)
let $crConcepts := xmlconv:executeSparqlEndpoint($sparqlD19)//sparql:result

let $invalidStationMedia :=
for $rec in doc($source_url)//gml:featureMember/descendant::*[name()='aqd:AQD_Station']

    for $conceptUrl in $rec/child::*[name() = 'ef:mediaMonitored']/@xlink:href
        let $conceptUrl := normalize-space(data($conceptUrl))
        where string-length($conceptUrl) > 0 and not(xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl))

                return
                    <tr isvalid="{ xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl) }">
                        <td title="Feature type">aqd:AQD_Station</td>
                        <td title="gml:id">{data($rec/@gml:id)}</td>
                        <td title="ef:name">{data($rec/ef:name)}</td>
                        <td title="ef:mediaMonitored" style="color:red">{$conceptUrl}</td>
                    </tr>
:)

let $invalidStationMedia := xmlconv:checkVocabularyConceptValues($source_url, "aqd:AQD_Station", "ef:mediaMonitored", $xmlconv:MEDIA_VALUE_VOCABULARY_BASE_URI)

(: D20 Done by Rait:)
let $invalidPoints := distinct-values($docRoot//aqd:AQD_Station[count(ef:geometry/gml:Point) >0 and ef:geometry/gml:Point/@srsName != "urn:ogc:def:crs:EPSG::4258" and ef:geometry/gml:Point/@srsName != "urn:ogc:def:crs:EPSG::4326"]/@gml:id)

(: D21 Done by Rait :)
let $invalidPos_srsDim  := distinct-values($docRoot//aqd:AQD_Station/ef:geometry/gml:Point/gml:pos[@srsDimension != "2"]/
concat(../../../@gml:id, ": srsDimension=", @srsDimension))


let $aqdStationPos :=
    for $allPos in $docRoot//aqd:AQD_Station
    where not(empty($allPos/ef:geometry/gml:Point/gml:pos))
    return concat($allPos/ef:inspireId/base:Identifier/base:namespace,"/",$allPos/ef:inspireId/base:Identifier/base:localId,"|",
        fn:substring-before(data($allPos/ef:geometry/gml:Point/gml:pos), " "), "#", fn:substring-after(data($allPos/ef:geometry/gml:Point/gml:pos), " "))


let $invalidPos_order :=
    for $gmlPos in $docRoot//aqd:AQD_SamplingPoint

        let $samplingPos := data($gmlPos/ef:geometry/gml:Point/gml:pos)
        let $samplingLat := if (not(empty($samplingPos))) then fn:substring-before($samplingPos, " ") else ""
        let $samplingLong := if (not(empty($samplingPos))) then fn:substring-after($samplingPos, " ") else ""


        let $samplingLat := if ($samplingLat castable as xs:decimal) then xs:decimal($samplingLat) else 0.00
        let $samplingLong := if ($samplingLong castable as xs:decimal) then xs:decimal($samplingLong) else 0.00

        return if ($samplingLat < $samplingLong and $countryCode != 'FR')
        then concat($gmlPos/@gml:id, " : lat=" , string($samplingLat), " :long=", string($samplingLong)) else ()


let $invalidPosD21 := (($invalidPos_srsDim), ($invalidPos_order))

(: D23 Done by Rait :)
    let $allEfOperationActivityPeriod :=
        for $allOperationActivityPeriod in $docRoot//gml:featureMember/aqd:AQD_Station/ef:operationalActivityPeriod
        where ($allOperationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition[normalize-space(@indeterminatePosition)!="unknown"]
                or fn:string-length($allOperationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition) > 0)
        return $allOperationActivityPeriod

    let $allInvalidEfOperationActivityPeriod :=
            for $operationActivityPeriod in  $allEfOperationActivityPeriod
            where ($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition < $operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition)and ($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition!="")
    return
        <tr>
            <td title="aqd:AQD_Station">{data($operationActivityPeriod/../@gml:id)}</td>
            <td title="gml:TimePeriod">{data($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/@gml:id)}</td>
            <td title="gml:beginPosition">{$operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition}</td>
            <td title="gml:endPosition">{$operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition}</td>
        </tr>



(: D24 Done by Rait:)
let $allUnknownEfOperationActivityPeriodD24 :=
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
     (
     count(index-of($xmlconv:ISO2_CODES , substring(upper-case(normalize-space($EUStationCode)), 1, 2))) = 0
     )
    return
        <tr>
            <td title="aqd:AQD_Station">{data($EUStationCode/../@gml:id)}</td>
            <td title="aqd:EUStationCode">{data($EUStationCode)}</td>
        </tr>

(: D27 :)
let $invalidMeteoParams :=xmlconv:checkVocabulariesConceptEquipmentValues($source_url, "aqd:AQD_Station", "aqd:meteoParams", $xmlconv:METEO_PARAMS_VOCABULARY, "collection")

(: D28 :)
let $invalidAreaClassification := xmlconv:checkVocabularyConceptValues($source_url, "aqd:AQD_Station", "aqd:areaClassification", $xmlconv:AREA_CLASSIFICATION_VOCABULARY)
(: D29 :)

let $allDispersionLocal :=
for $rec in $docRoot//aqd:AQD_Station/aqd:dispersionSituation/aqd:DispersionSituation/aqd:dispersionLocal
return
<tr>{$rec}</tr>
let $invalidDispersionLocal := xmlconv:checkVocabularyConceptValues4($source_url, "aqd:AQD_Station", "aqd:dispersionLocal", $xmlconv:DISPERSION_LOCAL_VOCABULARY)

(: D30 :)
let $invalidDispersionRegional := xmlconv:checkVocabularyConceptValues4($source_url, "aqd:AQD_Station", "aqd:dispersionRegional", $xmlconv:DISPERSION_REGIONAL_VOCABULARY)
let $allDispersionRegional :=
for $rec in $docRoot//aqd:AQD_Station/aqd:dispersionSituation/aqd:DispersionSituation/aqd:dispersionRegional
return
<tr>{$rec}</tr>

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

(: D32 :)

let $allBaseNamespace := distinct-values($docRoot//aqd:AQD_SamplingPoint//base:Identifier/base:namespace)

let  $tblD32 :=
    for $id in $allBaseNamespace
    let $localId := $docRoot//aqd:AQD_SamplingPoint//base:Identifier[base:namespace = $id]/base:localId
    return
        <tr>
	    <td title="feature">SamplingPoint(s)</td>
	    <td title="base:namespace">{$id}</td>
            <td title="base:localId">{count($localId)}</td>
        </tr>

(: D33 :)
let $invalidSamplingPointMedia := xmlconv:checkVocabularyConceptValues($source_url, "aqd:AQD_SamplingPoint", "ef:mediaMonitored", $xmlconv:MEDIA_VALUE_VOCABULARY_BASE_URI)

(: D34 :)
let $allGeometryPoint :=
for $rec in $docRoot//aqd:AQD_SamplingPoint/ef:geometry/gml:Point
return <tr>{$rec}</tr>

let $invalidGeometryPoint := distinct-values($docRoot//aqd:AQD_SamplingPoint[count(ef:geometry/gml:Point) >0 and ef:geometry/gml:Point/@srsName != "urn:ogc:def:crs:EPSG::4258" and ef:geometry/gml:Point/@srsName != "urn:ogc:def:crs:EPSG::4326"]/@gml:id)

(: D35 :)
let $invalidPos  := distinct-values($docRoot/gml:featureMember//aqd:AQD_SamplingPoint/ef:geometry/gml:Point/gml:pos[@srsDimension != "2"]/
concat(../../../../../@gml:id, ": srsDimension=", @srsDimension))

(: D36 :)

let $approximity := 0.0003

(: StationID|long#lat :)
let $aqdStationPos :=
    for $allPos in $docRoot//aqd:AQD_Station
    where not(empty($allPos/ef:geometry/gml:Point/gml:pos))
    return concat($allPos/ef:inspireId/base:Identifier/base:namespace,"/",$allPos/ef:inspireId/base:Identifier/base:localId,"|",
        fn:substring-before(data($allPos/ef:geometry/gml:Point/gml:pos), " "), "#", fn:substring-after(data($allPos/ef:geometry/gml:Point/gml:pos), " "))


let $invalidSamplingPointPos :=
    for $gmlPos in $docRoot//aqd:AQD_SamplingPoint
        let $efBroader := $gmlPos/ef:broader/@xlink:href
        let $samplingStationId := data($efBroader)
        let $stationPos :=
            for $station in $aqdStationPos
              let $stationId := fn:substring-before($station, "|")
              return if ($stationId = $samplingStationId) then $station else ()

        let $stationLong := if (not(empty($stationPos))) then fn:substring-before(fn:substring-after($stationPos[1], "|"), "#") else ""
        let $stationLat := if (not(empty($stationPos))) then fn:substring-after(fn:substring-after($stationPos[1], "|"), "#") else ""

        let $samplingPos := data($gmlPos/ef:geometry/gml:Point/gml:pos)
        let $samplingLong := if (not(empty($samplingPos))) then fn:substring-before($samplingPos, " ") else ""
        let $samplingLat := if (not(empty($samplingPos))) then fn:substring-after($samplingPos, " ") else ""


        let $stationLong := if ($stationLong castable as xs:decimal) then xs:decimal($stationLong) else 0.00
        let $stationLat := if ($stationLat castable as xs:decimal) then xs:decimal($stationLat) else 0.00

        let $samplingLong := if ($samplingLong castable as xs:decimal) then xs:decimal($samplingLong) else 0.00
        let $samplingLat := if ($samplingLat castable as xs:decimal) then xs:decimal($samplingLat) else 0.00

        return if (abs($samplingLong - $stationLong) > $approximity
        or abs($samplingLat - $stationLat) > $approximity) then $gmlPos/@gml:id else ()
(: D37 :)


(: begin < end :)
let $invalidPosition  :=
    for $timePeriod in $docRoot//aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod
        (: XQ does not support 24h that is supported by xsml schema validation :)
        let $beginDate := substring(normalize-space($timePeriod/gml:beginPosition),1,10)
        let $endDate := substring(normalize-space($timePeriod/gml:endPosition),1,10)
        let $beginPosition := if ($beginDate castable as xs:date) then xs:date($beginDate) else ()
        let $endPosition := if ($endDate castable as xs:date) then xs:date($endDate) else ()

        return
            if (not(empty($beginPosition)) and not(empty($endPosition)) and $beginPosition > $endPosition) then
             <tr>
                <td title="aqd:AQD_Station">{data($timePeriod/../../../../@gml:id)}</td>
                <td title="gml:TimePeriod">{data($timePeriod/@gml:id)}</td>
                <td title="gml:beginPosition">{$timePeriod/gml:beginPosition}</td>
                <td title="gml:endPosition">{$timePeriod/gml:endPosition}</td>
            </tr>

            else
                ()


(: sort by begin and find if end is greater than next end :)
let $overlappingPeriods :=
for $rec in $docRoot//aqd:AQD_SamplingPoint
    let $observingCapabilities :=
    for $cp in $rec/ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod
    order by $cp/gml:beginPosition
        return $cp

    for $period at $pos in $observingCapabilities

        let $ok := if ($pos < count($observingCapabilities))
        then
            if ($period/gml:endPosition castable as xs:dateTime and $observingCapabilities[$pos+1]/gml:beginPosition castable as xs:dateTime) then
                 if (xs:dateTime($period/gml:endPosition) > xs:dateTime($observingCapabilities[$pos+1]/gml:beginPosition)) then fn:false() else fn:true()
            else
                fn:true()
        else
            fn:true()

       return if ($ok) then () else

            <tr>
                <td title="aqd:AQD_Station">{data($period/../../../../@gml:id)}</td>
                <td title="gml:TimePeriod">{data($period/@gml:id)}</td>
                <td title="gml:beginPosition">{$period/gml:beginPosition}</td>
                <td title="gml:endPosition">{$period/gml:endPosition}</td>
            </tr>


let $allObservingCapabilityPeriod := (($invalidPosition), ($overlappingPeriods))


(: D40 :)

let $invalidObservedProperty := xmlconv:checkVocabularyConceptValues($source_url, "ef:ObservingCapability", "ef:observedProperty", $xmlconv:POLLUTANT_VOCABULARY)

(: D41
let $aqdSampleLocal :=
    for $allSampleLocal in $docRoot//aqd:AQD_Sample
    return $allSampleLocal/@gml:id

let $invalideFeatureOfInterest :=
    for $x in $docRoot//aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability/ef:featureOfInterest
    where empty(index-of($aqdSampleLocal,fn:normalize-space(fn:substring-after($x/@xlink:href,"/"))))
    return
    <tr>
        <td title="aqd:AQD_SamplingPoint">{data($x/../../../@gml:id)}</td>
        <td title="ef:featureOfInterest">{data(fn:normalize-space(fn:substring-after($x/@xlink:href,"/")))}</td>
    </tr>
:)

(: D41 Updated by Jaume Targa following working logic of D44 :)
let $aqdSampleLocal :=
    for $z in $docRoot//aqd:AQD_Sample
    let $id := concat(data($z/aqd:inspireId/base:Identifier/base:namespace), '/',
        data($z/aqd:inspireId/base:Identifier/base:localId))
    return $id

let $invalideFeatureOfInterest :=
    for $x in $docRoot//aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability/ef:featureOfInterest
    where empty(index-of($aqdSampleLocal,fn:normalize-space($x/@xlink:href)))
    return
    <tr>
      <td title="aqd:AQD_SamplingPoint">{data($x/../@gml:id)}</td>
      <td title="ef:featureOfInterest">{data(fn:normalize-space($x/@xlink:href))}</td>
    </tr>


(: D42 :)

let $aqdProcessLocal :=
    for $allProcessLocal in $docRoot//aqd:AQD_SamplingPointProcess
    let $id := concat(data($allProcessLocal/ompr:inspireId/base:Identifier/base:namespace),
        '/', data($allProcessLocal/ompr:inspireId/base:Identifier/base:localId))
    return $id

let $invalidEfprocedure :=
    for $x in $docRoot//aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability/ef:procedure
    where empty(index-of($aqdProcessLocal,fn:normalize-space($x/@xlink:href)))
    return
    <tr>
        <td title="aqd:AQD_SamplingPoint">{data($x/../../../@gml:id)}</td>
      <td title="ef:procedure">{data(fn:normalize-space($x/@xlink:href))}</td>
    </tr>

(: D43 Updated by Jaume Targa following working logic of D44 :)

let $aqdStationLocal :=
    for $z in $docRoot//aqd:AQD_Station
    let $id := concat(data($z/ef:inspireId/base:Identifier/base:namespace), '/',
        data($z/ef:inspireId/base:Identifier/base:localId))
    return $id

let $invalidEfbroader :=
    for $x in $docRoot//aqd:AQD_SamplingPoint/ef:broader
    where empty(index-of($aqdStationLocal,fn:normalize-space($x/@xlink:href)))
    return
    <tr>
      <td title="aqd:AQD_SamplingPoint">{data($x/../@gml:id)}</td>
      <td title="ef:broader">{data(fn:normalize-space($x/@xlink:href))}</td>
    </tr>

(: D44 :)

let $aqdNetworkLocal :=
    for $z in $docRoot//aqd:AQD_Network
    let $id := concat(data($z/ef:inspireId/base:Identifier/base:namespace), '/',
        data($z/ef:inspireId/base:Identifier/base:localId))
    return $id

let $invalidEfbelongsTo :=
    for $x in $docRoot//aqd:AQD_SamplingPoint/ef:belongsTo
    where empty(index-of($aqdNetworkLocal,fn:normalize-space($x/@xlink:href)))
    return
    <tr>
      <td title="aqd:AQD_SamplingPoint">{data($x/../@gml:id)}</td>
      <td title="ef:belongsTo">{data(fn:normalize-space($x/@xlink:href))}</td>
    </tr>

(: D45 :)
(: Find all period with out end period :)

let $allNotNullEndOperationActivityPeriods :=
    for $allOperationActivityPeriod in $docRoot//aqd:AQD_SamplingPoint/ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod
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

(: D46 :)

let $allUnknownEfOperationActivityPeriod :=
    for $operationActivityPeriod in $docRoot//gml:featureMember/aqd:AQD_SamplingPoint/ef:operationalActivityPeriod
    where $operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition[normalize-space(@indeterminatePosition)="unknown"]
            or fn:string-length($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition) = 0
    return
        <tr>
            <td title="aqd:AQD_SamplingPoint">{data($operationActivityPeriod/../@gml:id)}</td>
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


(:D51 Done by Rait UPDATED by Jaume :)
let $invalidObservedPropertyCombinations :=
    for $oPC in $docRoot//gml:featureMember/aqd:AQD_SamplingPoint/aqd:environmentalObjective/aqd:EnvironmentalObjective
    where
       (($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/1" and
                    not(
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
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
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/wMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V")
                    or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ALT" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/3hAbove" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")


                    )
              )
              or
                  ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/7" and
                      not(
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
		       or
                                ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/INT" and
                                 $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove" and
                                 $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
 or
                                ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ALT" and
                                 $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove" and
                                 $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                      )
              )
              or

                  ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/8" and
                     not(
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                         $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove" and
                         $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                        or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                        or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVMOT" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                        or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVMOT" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
			or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ALT" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/3hAbove" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")

                         or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVmaxMOT" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                        or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVmaxMOT" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")


                     ))
              or
                   ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/9" and
                        not(
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V")
                    or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/NA" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/NA")
                     ))
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
                        or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                        or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S1")
                        or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S2")
                        or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVMOT" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                        or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/NA" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/NA")
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
                      ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/20" and
                        not(
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                        or
			($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVMOT" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                        or

                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/NA" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/NA")

                        ))
or
                      ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5012" and
                        not(
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                        or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/NA" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/NA")

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
                        or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/NA" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/NA")
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

(: D52 moved to D67 - 70:)
(:
let $allProcNotMatchingCondition :=
for $proc in $docRoot//aqd:AQD_SamplingPointProcess
let $demonstrated := data($proc/aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:equivalenceDemonstrated/@xlink:href)
let $demonstrationReport := data($proc/aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:demonstrationReport)
let $documentation := data($proc/aqd:dataQuality/aqd:DataQuality/aqd:documentation)
let $qaReport := data($proc/aqd:dataQuality/aqd:DataQuality/aqd:qaReport)

    where fn:string-length($qaReport) = 0 or fn:string-length($documentation) = 0 or fn:string-length($demonstrationReport) = 0
        or not(xmlconv:isValidConceptCode($demonstrated, $xmlconv:EQUIVALENCEDEMONSTRATED_VOCABULARY))

return concat(data($proc/ompr:inspireId/base:Identifier/base:namespace), '/' , data($proc/ompr:inspireId/base:Identifier/base:localId))


let $allInvalidTrueUsedAQD :=
    for $invalidTrueUsedAQD in $docRoot//aqd:AQD_SamplingPoint
        let $procIds := data($invalidTrueUsedAQD/ef:observingCapability/ef:ObservingCapability/ef:procedure/@xlink:href)
        let $aqdUsed := $invalidTrueUsedAQD/aqd:usedAQD = true()

    for $procId in $procIds
    return
        if ($aqdUsed  and  not(empty(index-of($allProcNotMatchingCondition, $procId)))) then
        <tr>
            <td title="gml:id">{data($invalidTrueUsedAQD/@gml:id)}</td>
            <td title="base:localId">{data($invalidTrueUsedAQD/ef:inspireId/base:Identifier/base:localId)}</td>
            <td title="base:namespace">{data($invalidTrueUsedAQD/ef:inspireId/base:Identifier/base:namespace)}</td>
            <td title="ef:procedure">{$procId}</td>
            <td title="ef:ObservingCapability">{data($invalidTrueUsedAQD/ef:observingCapability/ef:ObservingCapability/@gml:id)}</td>

        </tr>
        else ()
:)

(:D52 Done by Jaume Targa :)
(: let $allInvalidZoneXlinks :=
    for $invalidZoneXlinks in $docRoot//aqd:AQD_SamplingPoint/aqd:zone
     where
        count(xmlconv:executeSparqlQuery(xmlconv:getSamplingPointZone($invalidZoneXlinks/@xlink:href))/*) = 0
    return
        <tr>
            <td title="gml:id">{data($invalidZoneXlinks/../@gml:id)}</td>
            <td title="aqd:zone">{data($invalidZoneXlinks/@xlink:href)}</td>
        </tr>
:)

(: D52 Done by Jaume Targa; re-using M25 :)
    let $allTrueUsedAQD :=
        for $trueUsedAQD in $docRoot//aqd:AQD_SamplingPoint
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
    for $invalidZoneXlinks in $docRoot//aqd:AQD_SamplingPoint/aqd:zone
     where
        count(xmlconv:executeSparqlQuery(xmlconv:getSamplingPointZone(string($invalidZoneXlinks/@xlink:href)))/*) = 0
    return
        <tr>
            <td title="gml:id">{data($invalidZoneXlinks/../@gml:id)}</td>
            <td title="aqd:zone">{data($invalidZoneXlinks/@xlink:href)}</td>
        </tr>

(: D54 Done by Rait:)
let $localSamplingPointProcessIds := $docRoot//gml:featureMember/aqd:AQD_SamplingPointProcess/ompr:inspireId/base:Identifier
let $invalidDuplicateSamplingPointProcessIds :=
    for $idSamplingPointProcessCode in $docRoot//gml:featureMember/aqd:AQD_SamplingPointProcess/ompr:inspireId/base:Identifier
    where
        count(index-of($localSamplingPointProcessIds/base:localId, normalize-space($idSamplingPointProcessCode/base:localId))) > 1 and
                count(index-of($localSamplingPointProcessIds/base:namespace, normalize-space($idSamplingPointProcessCode/base:namespace))) > 1
    return
        <tr>
            <td title="aqd:AQD_SamplingPointProcess">{data($idSamplingPointProcessCode/../../@gml:id)}</td>
            <td title="base:localId">{data($idSamplingPointProcessCode/base:localId)}</td>
            <td title="base:namespace">{data($idSamplingPointProcessCode/base:namespace)}</td>
        </tr>

(: D55 :)

let $allBaseNamespace := distinct-values($docRoot//aqd:AQD_SamplingPointProcess/ompr:inspireId/base:Identifier/base:namespace)

let  $tblD55 :=
    for $id in $allBaseNamespace
    let $localId := $docRoot//aqd:AQD_SamplingPointProcess/ompr:inspireId/base:Identifier[base:namespace = $id]/base:localId
    return
        <tr>
  	    <td title="feature">SamplingPointProcess(es)</td>
	    <td title="base:namespace">{$id}</td>
            <td title="unique localId">{count($localId)}</td>
        </tr>


(:D56 Done by Rait:)
let  $allInvalidMeasurementType
     := xmlconv:checkVocabularyConceptValues($source_url, "aqd:AQD_SamplingPointProcess", "aqd:measurementType", $xmlconv:MEASUREMENTTYPE_VOCABULARY)


(: D57 :)
let $allConceptUrl57 :=
for $process in doc($source_url)//aqd:AQD_SamplingPointProcess
    let $measurementType := data($process/aqd:measurementType/@xlink:href)
    let $measurementMethod := data($process/aqd:measurementMethod/aqd:MeasurementMethod/aqd:measurementMethod/@xlink:href)
    let $samplingMethod := data($process/aqd:samplingMethod/aqd:SamplingMethod/aqd:samplingMethod/@xlink:href)
    let $analyticalTechnique := data($process/aqd:analyticalTechnique/aqd:AnalyticalTechnique/aqd:analyticalTechnique/@xlink:href)
    where ($measurementType  = 'http://dd.eionet.europa.eu/vocabulary/aq/measurementtype/automatic' or
         $measurementType = 'http://dd.eionet.europa.eu/vocabulary/aq/measurementtype/remote')
         and (
            string-length($samplingMethod) > 0 or string-length($analyticalTechnique) > 0 or not(xmlconv:isValidConceptCode($measurementMethod,$xmlconv:MEASUREMENTMETHOD_VOCABULARY))
            )

    return
        <tr>
            <td title="aqd:AQD_SamplingPointProcess">{data($process/@gml:id)}</td>
            <td title="aqd:measurementType">{$measurementType}</td>
            <td title="aqd:measurementMethod">{$measurementMethod}</td>
            <td title="aqd:samplingMethod">{$samplingMethod}</td>
            <td title="aqd:analyticalTechnique">{$analyticalTechnique}</td>
        </tr>

(:D58 Done by Rait:)
let $allConceptUrl58 :=
    for $conceptUrl in doc($source_url)//gml:featureMember/aqd:AQD_SamplingPointProcess/aqd:measurementType/@xlink:href
    where $conceptUrl = 'http://dd.eionet.europa.eu/vocabulary/aq/measurementtype/active' or
            $conceptUrl = 'http://dd.eionet.europa.eu/vocabulary/aq/measurementtype/passive'
    return $conceptUrl

let $elementsIncluded :=
    for $checkElements in $allConceptUrl58
        let $style1 := if(count($checkElements/../../aqd:samplingMethod) = 0 ) then "color:red;" else ""
        let $style2 := if(count($checkElements/../../aqd:analyticalTechnique) = 0) then "color:red;" else ""
        let $style3 := if(count($checkElements/../../aqd:measurementMethod) >= 1) then "color:red;" else ""
    where (count($checkElements/../../aqd:samplingMethod) = 0 or count($checkElements/../../aqd:analyticalTechnique) = 0)
             or count($checkElements/../../aqd:measurementMethod) >= 1
    return
        <tr>
            <td title="gml:id">{data($checkElements/../../@gml:id)}</td>
            <td style="{$style1}" title="aqd:samplingMethod">{if(count($checkElements/../../aqd:samplingMethod) = 0 ) then "Error, shall  be provided." else "Valid."}</td>
            <td style="{$style2}" title="aqd:analyticalTechnique">{if(count($checkElements/../../aqd:analyticalTechnique) = 0) then "Error, shall  be provided." else "Valid."}</td>
            <td style="{$style3}" title="aqd:measurementMethod">{if(count($checkElements/../../aqd:measurementMethod) >= 1) then "Error, shall not be provided." else "Valid."}</td>
        </tr>

(: D59 Done by Rait:)
let  $allInvalidAnalyticalTechnique
    := xmlconv:checkVocabularyaqdAnalyticalTechniqueValues($source_url, "aqd:AQD_SamplingPointProcess", "aqd:analyticalTechnique", $xmlconv:ANALYTICALTECHNIQUE_VOCABULARY, "")

(: D60a  :)
let  $allInvalid60a
    := xmlconv:checkVocabularyConceptEquipmentValues($source_url, "aqd:AQD_SamplingPointProcess", "aqd:measurementEquipment", $xmlconv:MEASUREMENTEQUIPMENT_VOCABULARY, "")

(: D60b :)
let  $allInvalid60b
    := xmlconv:checkVocabularyConceptEquipmentValues($source_url, "aqd:AQD_SamplingPointProcess", "aqd:samplingEquipment", $xmlconv:SAMPLINGEQUIPMENT_VOCABULARY, "")

(: D63 :)
let  $allInvalid63
    := xmlconv:checkVocabularyConceptValuesUom($source_url, "aqd:DataQuality", "aqd:detectionLimit", $xmlconv:UOM_CONCENTRATION_VOCABULARY)

(: Block for D67 to D70 Jaume Targa:)

(: Original from D52

let $allProcNotMatchingCondition70 :=
for $proc in $docRoot//aqd:AQD_SamplingPointProcess
let $demonstrated := data($proc/aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:equivalenceDemonstrated/@xlink:href)
let $demonstrationReport := data($proc/aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:demonstrationReport)
let $documentation := data($proc/aqd:dataQuality/aqd:DataQuality/aqd:documentation)
let $qaReport := data($proc/aqd:dataQuality/aqd:DataQuality/aqd:qaReport)

    where fn:string-length($qaReport) = 0 or fn:string-length($documentation) = 0 or fn:string-length($demonstrationReport) = 0
        or not(xmlconv:isValidConceptCode($demonstrated, $xmlconv:EQUIVALENCEDEMONSTRATED_VOCABULARY))

return concat(data($proc/ompr:inspireId/base:Identifier/base:namespace), '/' , data($proc/ompr:inspireId/base:Identifier/base:localId))


let $allInvalidTrueUsedAQD70 :=
    for $invalidTrueUsedAQD70 in $docRoot//aqd:AQD_SamplingPoint
        let $procIds70 := data($invalidTrueUsedAQD70/ef:observingCapability/ef:ObservingCapability/ef:procedure/@xlink:href)
        let $aqdUsed70 := $invalidTrueUsedAQD70/aqd:usedAQD = true()

    for $procId70 in $procIds70
    return
        if ($aqdUsed70  and  not(empty(index-of($allProcNotMatchingCondition70, $procId70)))) then
        <tr>
            <td title="gml:id">{data($invalidTrueUsedAQD70/@gml:id)}</td>
            <td title="base:localId">{data($invalidTrueUsedAQD70/ef:inspireId/base:Identifier/base:localId)}</td>
            <td title="base:namespace">{data($invalidTrueUsedAQD70/ef:inspireId/base:Identifier/base:namespace)}</td>
            <td title="ef:procedure">{$procId70}</td>
            <td title="ef:ObservingCapability">{data($invalidTrueUsedAQD70/ef:observingCapability/ef:ObservingCapability/@gml:id)}</td>

        </tr>
        else ()
:)


(: D67 Jaume Targa :)

let $allProcNotMatchingCondition67 :=
for $proc in $docRoot//aqd:AQD_SamplingPointProcess
let $demonstrated := data($proc/aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:equivalenceDemonstrated/@xlink:href)
let $demonstrationReport := data($proc/aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:demonstrationReport)

where not(xmlconv:isValidConceptCode($demonstrated, $xmlconv:EQUIVALENCEDEMONSTRATED_VOCABULARY))

return concat(data($proc/ompr:inspireId/base:Identifier/base:namespace), '/' , data($proc/ompr:inspireId/base:Identifier/base:localId))


let $allInvalidTrueUsedAQD67 :=
    for $invalidTrueUsedAQD67 in $docRoot//aqd:AQD_SamplingPoint
        let $procIds67 := data($invalidTrueUsedAQD67/ef:observingCapability/ef:ObservingCapability/ef:procedure/@xlink:href)
        let $aqdUsed67 := $invalidTrueUsedAQD67/aqd:usedAQD = true()

    for $procId67 in $procIds67
    return
        if ($aqdUsed67  and  not(empty(index-of($allProcNotMatchingCondition67, $procId67)))) then
        <tr>
            <td title="gml:id">{data($invalidTrueUsedAQD67/@gml:id)}</td>
            <td title="base:localId">{data($invalidTrueUsedAQD67/ef:inspireId/base:Identifier/base:localId)}</td>
            <td title="base:namespace">{data($invalidTrueUsedAQD67/ef:inspireId/base:Identifier/base:namespace)}</td>
            <td title="ef:procedure">{$procId67}</td>
            <td title="ef:ObservingCapability">{data($invalidTrueUsedAQD67/ef:observingCapability/ef:ObservingCapability/@gml:id)}</td>

        </tr>
        else ()

(: D68 Jaume Targa :)

let $allProcNotMatchingCondition68 :=
for $proc in $docRoot//aqd:AQD_SamplingPointProcess
let $demonstrated := data($proc/aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:equivalenceDemonstrated/@xlink:href)
let $demonstrationReport := data($proc/aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:demonstrationReport)

where ($demonstrated = 'http://dd.eionet.europa.eu/vocabulary/aq/equivalencedemonstrated/yes' and fn:string-length($demonstrationReport) = 0)

return concat(data($proc/ompr:inspireId/base:Identifier/base:namespace), '/' , data($proc/ompr:inspireId/base:Identifier/base:localId))


let $allInvalidTrueUsedAQD68 :=
    for $invalidTrueUsedAQD68 in $docRoot//aqd:AQD_SamplingPoint
        let $procIds68 := data($invalidTrueUsedAQD68/ef:observingCapability/ef:ObservingCapability/ef:procedure/@xlink:href)
        let $aqdUsed68 := $invalidTrueUsedAQD68/aqd:usedAQD = true()

    for $procId68 in $procIds68
    return
        if ($aqdUsed68  and  not(empty(index-of($allProcNotMatchingCondition68, $procId68)))) then
        <tr>
            <td title="gml:id">{data($invalidTrueUsedAQD68/@gml:id)}</td>
            <td title="base:localId">{data($invalidTrueUsedAQD68/ef:inspireId/base:Identifier/base:localId)}</td>
            <td title="base:namespace">{data($invalidTrueUsedAQD68/ef:inspireId/base:Identifier/base:namespace)}</td>
            <td title="ef:procedure">{$procId68}</td>
            <td title="ef:ObservingCapability">{data($invalidTrueUsedAQD68/ef:observingCapability/ef:ObservingCapability/@gml:id)}</td>

        </tr>
        else ()



(: D69 Jaume Targa :)

let $allProcNotMatchingCondition69 :=
for $proc in $docRoot//aqd:AQD_SamplingPointProcess
let $documentation := data($proc/aqd:dataQuality/aqd:DataQuality/aqd:documentation)
let $qaReport := data($proc/aqd:dataQuality/aqd:DataQuality/aqd:qaReport)

where fn:string-length($documentation) = 0

return concat(data($proc/ompr:inspireId/base:Identifier/base:namespace), '/' , data($proc/ompr:inspireId/base:Identifier/base:localId))


let $allInvalidTrueUsedAQD69 :=
    for $invalidTrueUsedAQD69 in $docRoot//aqd:AQD_SamplingPoint
        let $procIds69 := data($invalidTrueUsedAQD69/ef:observingCapability/ef:ObservingCapability/ef:procedure/@xlink:href)
        let $aqdUsed69 := $invalidTrueUsedAQD69/aqd:usedAQD = true()

    for $procId69 in $procIds69
    return
        if ($aqdUsed69  and  not(empty(index-of($allProcNotMatchingCondition69, $procId69)))) then
        <tr>
            <td title="gml:id">{data($invalidTrueUsedAQD69/@gml:id)}</td>
            <td title="base:localId">{data($invalidTrueUsedAQD69/ef:inspireId/base:Identifier/base:localId)}</td>
            <td title="base:namespace">{data($invalidTrueUsedAQD69/ef:inspireId/base:Identifier/base:namespace)}</td>
            <td title="ef:procedure">{$procId69}</td>
            <td title="ef:ObservingCapability">{data($invalidTrueUsedAQD69/ef:observingCapability/ef:ObservingCapability/@gml:id)}</td>

        </tr>
        else ()

(: D70 Jaume Targa :)

let $allProcNotMatchingCondition70 :=
for $proc in $docRoot//aqd:AQD_SamplingPointProcess
let $documentation := data($proc/aqd:dataQuality/aqd:DataQuality/aqd:documentation)
let $qaReport := data($proc/aqd:dataQuality/aqd:DataQuality/aqd:qaReport)

where fn:string-length($qaReport) = 0


return concat(data($proc/ompr:inspireId/base:Identifier/base:namespace), '/' , data($proc/ompr:inspireId/base:Identifier/base:localId))


let $allInvalidTrueUsedAQD70 :=
    for $invalidTrueUsedAQD70 in $docRoot//aqd:AQD_SamplingPoint
        let $procIds70 := data($invalidTrueUsedAQD70/ef:observingCapability/ef:ObservingCapability/ef:procedure/@xlink:href)
        let $aqdUsed70 := $invalidTrueUsedAQD70/aqd:usedAQD = true()

    for $procId70 in $procIds70
    return
        if ($aqdUsed70  and  not(empty(index-of($allProcNotMatchingCondition70, $procId70)))) then
        <tr>
            <td title="gml:id">{data($invalidTrueUsedAQD70/@gml:id)}</td>
            <td title="base:localId">{data($invalidTrueUsedAQD70/ef:inspireId/base:Identifier/base:localId)}</td>
            <td title="base:namespace">{data($invalidTrueUsedAQD70/ef:inspireId/base:Identifier/base:namespace)}</td>
            <td title="ef:procedure">{$procId70}</td>
            <td title="ef:ObservingCapability">{data($invalidTrueUsedAQD70/ef:observingCapability/ef:ObservingCapability/@gml:id)}</td>

        </tr>
        else ()


(: D71 :)

let $localSampleIds := $docRoot//gml:featureMember/aqd:AQD_Sample/aqd:inspireId/base:Identifier
let $invalidDuplicateSampleIds :=
    for $idSampleCode in $docRoot//gml:featureMember/aqd:AQD_Sample/aqd:inspireId/base:Identifier
    where
        count(index-of($localSampleIds/base:localId, normalize-space($idSampleCode/base:localId))) > 1 and
                count(index-of($localSampleIds/base:namespace, normalize-space($idSampleCode/base:namespace))) > 1
    return
        <tr>
            <td title="aqd:AQD_Sample">{data($idSampleCode/../../@gml:id)}</td>
            <td title="base:localId">{data($idSampleCode/base:localId)}</td>
            <td title="base:namespace">{data($idSampleCode/base:namespace)}</td>
        </tr>

(: D72 :)
let $allBaseNamespace := distinct-values($docRoot//aqd:AQD_Sample/aqd:inspireId/base:Identifier/base:namespace)

let  $tblD72 :=
    for $id in $allBaseNamespace
    let $localId := $docRoot//aqd:AQD_Sample/aqd:inspireId/base:Identifier[base:namespace = $id]/base:localId
    return
        <tr>
            <td title="base:namespace">{$id}</td>
            <td title="base:localId">{count($localId)}</td>
        </tr>

(: D73 :)

let $allGmlPoint := $docRoot//aqd:AQD_Sample/sams:shape/gml:Point
let $tblD73 := if (count($allGmlPoint) > 0) then
for $point in $docRoot//aqd:AQD_Sample/sams:shape/gml:Point[@srsName != "urn:ogc:def:crs:EPSG::4258" and @srsName != "urn:ogc:def:crs:EPSG::4326"]
    return
        <tr>
            <td title="aqd:AQD_Sample">{data($point/../../@gml:id)}</td>
            <td title="gml:Point">{data($point/@gml:id)}</td>
            <td title="gml:Point/@srsName">{data($point/@srsName)}</td>

        </tr>
else
()
let $strErr73 := for $tr in $tblD73
return data($tr/td[@title='aqd:AQD_Sample'])

let $isInvalidInvalidD73 := if (count($allGmlPoint) > 0) then fn:true() else fn:false()
let $errLevelD73 := if (count($allGmlPoint) > 0) then "error" else "warning"
let $errMsg73  := if (count($allGmlPoint) > 0) then " errors found" else " gml:Point elements found"

(: D74 :)

let $invalidPointDimension  := distinct-values($docRoot//aqd:AQD_Sample/sams:shape/gml:Point[@srsDimension != "2"]/
concat(../@gml:id, ": srsDimension=", @srsDimension))

(: D78 :)
let $invalidInletHeigh :=
for $inletHeigh in  $docRoot//aqd:AQD_Sample/aqd:inletHeight
    return if (($inletHeigh/@uom != "http://dd.eionet.europa.eu/vocabulary/uom/length/m") or (xmlconv:is-a-number(data($inletHeigh))=false())) then $inletHeigh/../@gml:id else ()



return
    <table style="border-collapse:collapse;display:inline">
        <colgroup>
            <col width="15px" style="text-align:center"/>
            <col width="500px" style="text-align:left"/>
            <col width="350px" style="text-align:left"/>
            <col width="*"/>
        </colgroup>
        {xmlconv:buildResultRows("D1", "Total number of environmental monitoring feature types provided within this XML",
            (), (), "", string(sum($countFeatureTypes)), "", "","error", $tblAllFeatureTypes)}
        {xmlconv:buildResultRows("D2", "Compile and feedback upon the total number of new records for each environmental monitoring feature types included in the delivery",
                (), (), "", string(count($tblD2)), "", "","error",())}
        {xmlconv:buildResultRows("D3", "Compile and feedback upon the total number of modification to existing for each environmental monitoring feature types included in the delivery",
                (), (), "", string(count($tblD3)), "", "","error",())}
        {xmlconv:buildResultRows("D4", "Full list of reported Environmental Monitoring Feature within this XML",
                (), (), "", string(count($tblD4)), "", "","error",$tblD4)}
        <tr>
            <tr style="border-top:1px solid #666666">
                <td style="vertical-align:top;">{ xmlconv:getBullet("D5", if ($countD5duplicates = 0) then "info" else "error") }</td>
                <th style="vertical-align:top;text-align:left">All gml:id attributes, ef:inspireId and aqd:inspireId elements shall have unique content</th>
                <td style="vertical-align:top;">{
                    if ($countD5duplicates = 0) then
                        "All Ids are unique"
                    else
                        concat($countD5duplicates, " duplicate", substring("s ", number(not($countD5duplicates > 1)) * 2) ,"found") }</td>
            </tr>
            {
                if ($countGmlIdDuplicates > 0) then
                    <tr style="font-size: 0.9em;color:grey;">
                        <td colspan="2" style="text-align:right;vertical-align:top;">aqd:AQD_Model/@gml:id - </td>
                        <td style="font-style:italic;vertical-align:top;">{ string-join($duplicateGmlIds, ", ")}</td>
                    </tr>
                else
                    ()
            }
            {
                if ($countefInspireIdDuplicates > 0) then
                    <tr style="font-size: 0.9em;color:grey;">
                        <td colspan="2" style="text-align:right;vertical-align:top;">ef:inspireId - </td>
                        <td style="font-style:italic;vertical-align:top;">{ string-join($duplicateefInspireIds, ", ")}</td>
                    </tr>
                else
                    ()
            }
            {
                if ($countaqdInspireIdDuplicates > 0) then
                    <tr style="font-size: 0.9em;color:grey;">
                        <td colspan="2" style="text-align:right;vertical-align:top;">aqd:inspireId - </td>
                        <td style="font-style:italic;vertical-align:top;">{ string-join($duplicateaqdInspireIds, ", ")}</td>
                    </tr>
                else
                    ()
            }
        </tr>
	<tr style="border-top:2px solid #666666">
            <td style="vertical-align:top;"></td>
            <td style="vertical-align:top;"></td>
            <td style="vertical-align:top;"></td>
	</tr>
	<tr style="border-top:0px solid #666666">
            <th colspan="2" style="vertical-align:top;text-align:left">Specific checks on AQD_Network feature(s) within this XML</th>
            <td style="vertical-align:top;"></td>
	</tr>

        <tr style="border-top:1px solid #666666">
            <td style="vertical-align:top;">{ xmlconv:getBullet("D6", if ($countD6duplicates = 0) then "info" else "error") }</td>
            <th style="vertical-align:top;text-align:left">aqd:AQD_Network/ef:inspireId/base:Identifier/base:localId shall be an unique code for AQD_network and unique within the namespace.</th>
            <td style="vertical-align:top;">{
                if ($countD6duplicates = 0) then
                    <span style="font-size:1.3em;">All Ids are unique</span>
                else
                    concat($countD6duplicates, " error", substring("s ", number(not($countD6duplicates > 1)) * 2) ,"found") }</td>
        </tr>
        {xmlconv:buildResultRows("D7", "Count the number of unique AQD_Network (via localId) submitted within base:namespace. ",
                (), (), "", string(count($tblD7)), "", "","error",$tblD7)}
        {xmlconv:buildResultRowsWithTotalCount("D8", <span>The content of aqd:AQD_Network/ef:mediaMonitored shall resolve to any concept in
            <a href="{ $xmlconv:MEDIA_VALUE_VOCABULARY_BASE_URI }">{ $xmlconv:MEDIA_VALUE_VOCABULARY_BASE_URI }</a></span>,
            (), (), "ef:mediaMonitored", "", "", "", "warning",$invalidNetworkMedia)}

        {xmlconv:buildResultRowsWithTotalCount("D9", <span>The content of aqd:AQD_Network/ef:organisationLevel shall resolve to any concept in
            <a href="{ $xmlconv:ORGANISATIONAL_LEVEL_VOCABULARY }">{ $xmlconv:ORGANISATIONAL_LEVEL_VOCABULARY }</a></span>,
            (), (), "ef:organisationLevel", "", "", "","warning", $invalidOrganisationalLevel)}

        {xmlconv:buildResultRowsWithTotalCount("D10", <span>The content of aqd:AQD_Network/aqd:networkType shall resolve to any concept in
            <a href="{ $xmlconv:NETWORK_TYPE_VOCABULARY }">{ $xmlconv:NETWORK_TYPE_VOCABULARY }</a></span>,
            (), (), "aqd:networkType", "", "", "","warning", $invalidNetworkType)}

        {xmlconv:buildResultRows("D11", "aqd:AQD_Network/aqd:operationActivityPeriod/gml:TimePeriod/gml:beginPosition shall be less than gml:endPosition",
                $invalidAQDNetworkBeginPosition, () , "aqd:AQD_Network/@gml:id", "All attributes are valid", " invalid attribute ", "","error", ())}


        {xmlconv:buildResultRowsWithTotalCount("D14", <span>The content of /aqd:AQD_Network/aqd:aggregationTimeZone attribute shall resolve to a valid code in
            <a href="{ $xmlconv:TIMEZONE_VOCABULARY }">{ $xmlconv:TIMEZONE_VOCABULARY }</a></span>,
                (), (), "aqd:aggregationTimeZone", "", "", "","error",$invalidTimeZone)}

	<tr style="border-top:2px solid #666666">
            <td style="vertical-align:top;"></td>
            <td style="vertical-align:top;"></td>
            <td style="vertical-align:top;"></td>
	</tr>
	<tr style="border-top:0px solid #666666">
            <th colspan="2" style="vertical-align:top;text-align:left">Specific checks on AQD_Station feature(s) within this XML</th>
            <td style="vertical-align:top;"></td>
	</tr>


        <tr style="border-top:1px solid #666666">
            <td style="vertical-align:top;">{ xmlconv:getBullet("D15", if ($countD15duplicates = 0) then "info" else "error") }</td>
            <th style="vertical-align:top;text-align:left">aqd:AQD_Station/ef:inspireId/base:Identifier/base:localId shall be an unique code within namespace</th>
            <td style="vertical-align:top;">{
                if ($countD15duplicates = 0) then
                    <span style="font-size:1.3em;">All Ids are unique</span>
                else
                    concat($countD15duplicates, " error", substring("s ", number(not($countD15duplicates > 1)) * 2) ,"found") }</td>
        </tr>



        {xmlconv:buildResultRows("D16", "Count the number of unique AQD_Station (via localId) submitted within base:namespace. ",
                (), (), "", string(count($tblD16)), "", "","error",$tblD16)}


        {xmlconv:buildResultRowsWithTotalCount("D19", <span>The content of /aqd:AQD_Station/ef:mediaMonitored shall resolve to any concept in
            <a href="{ $xmlconv:MEDIA_VALUE_VOCABULARY_BASE_URI }">{ $xmlconv:MEDIA_VALUE_VOCABULARY_BASE_URI }</a></span>,
            (), (), "ef:mediaMonitored", "", "", "","warning", $invalidStationMedia)}



        {xmlconv:buildResultRows("D20", "./ef:geometry/gml:Points the srsName attribute  shall  be  a  recognisable  URN .  The  following  2  srsNames  are  expected urn:ogc:def:crs:EPSG::4258 or urn:ogc:def:crs:EPSG::4326",
                $invalidPoints,(), "aqd:AQD_Station/@gml:id","All smsName attributes are valid"," invalid attribute","", "warning",())}
        {xmlconv:buildResultRows("D21", "./ef:geometry/gml:Point/gml:pos the srsDimension attribute shall resolve to ""2"" to allow the coordinate of the station",
                $invalidPosD21, () , "aqd:AQD_Zone/@gml:id", "All srsDimension attributes resolve to ""2""", " invalid attribute", "","error",())}

       {xmlconv:buildResultRows("D23", "Total number  aqd:AQD_Station invalid operational activity periods ",
            (), $allInvalidEfOperationActivityPeriod, "", fn:string(count($allInvalidEfOperationActivityPeriod)), "", "","error", ())}

        {xmlconv:buildResultRows("D24", "Total number of aqd:AQD_Station which are operational ",
                (), $allUnknownEfOperationActivityPeriodD24, "", string(count($allUnknownEfOperationActivityPeriodD24)), "", "","warning",(), fn:false())}

        {xmlconv:buildResultRows("D26", "AQD_Station/aqd:EUStationCode shall be an unique code for the station starting with ISO2-country code",
                (), $invalidDuplicateLocalIds, "", "All station codes are valid", " invalid station codes", "","error", ())}

        {xmlconv:buildResultRowsWithTotalCount("D27", <span>The content of aqd:AQD_Station/aqd:meteoParams shall resolve to any concept in
            <a href="{ $xmlconv:METEO_PARAMS_VOCABULARY[1] }">{ $xmlconv:METEO_PARAMS_VOCABULARY[1] }</a>,
            <a href="{ $xmlconv:METEO_PARAMS_VOCABULARY[2] }">{ $xmlconv:METEO_PARAMS_VOCABULARY[2] }</a>,
            <a href="{ $xmlconv:METEO_PARAMS_VOCABULARY[3] }">{ $xmlconv:METEO_PARAMS_VOCABULARY[3] }</a></span>,
                (), (), "aqd:meteoParams", "", "", "","warning",$invalidMeteoParams)}
        {xmlconv:buildResultRowsWithTotalCount("D28", <span>The content of aqd:AQD_Station/aqd:areaClassification shall resolve to any concept in
            <a href="{ $xmlconv:AREA_CLASSIFICATION_VOCABULARY }">{ $xmlconv:AREA_CLASSIFICATION_VOCABULARY }</a></span>,
            (), (), "aqd:areaClassification", "", "", "","error", $invalidAreaClassification)}

        {xmlconv:buildResultRowsWithTotalCount("D29", <span>The content of aqd:AQD_Station/aqd:dispersionLocal shall resolve to any concept in
            <a href="{ $xmlconv:DISPERSION_LOCAL_VOCABULARY }">{ $xmlconv:DISPERSION_LOCAL_VOCABULARY }</a></span>,
            $invalidDispersionLocal, (), "aqd:dispersionLocal", "", "", "","warning", $allDispersionLocal)}

        {xmlconv:buildResultRowsWithTotalCount("D30", <span>The content of aqd:AQD_Station/aqd:dispersionRegional shall resolve to any concept in
            <a href="{ $xmlconv:DISPERSION_REGIONAL_VOCABULARY }">{ $xmlconv:DISPERSION_REGIONAL_VOCABULARY }</a></span>,
            $invalidDispersionRegional, (), "aqd:dispersionRegional", "", "", "","warning", $allDispersionRegional)}

	<tr style="border-top:2px solid #666666">
            <td style="vertical-align:top;"></td>
            <td style="vertical-align:top;"></td>
            <td style="vertical-align:top;"></td>
	</tr>
	<tr style="border-top:0px solid #666666">
            <th colspan="2" style="vertical-align:top;text-align:left">Specific checks on AQD_SamplingPoint feature(s) within this XML</th>
            <td style="vertical-align:top;"></td>
	</tr>

        {xmlconv:buildResultRows("D31", "AQD_SamplingPoint/ef:inspireId/base:Identifier/base:localId not unique codes: ",
                (), $invalidDuplicateSamplingPointIds, "", concat(string(count($invalidDuplicateSamplingPointIds))," errors found.") , "", "","error", ())}
        {xmlconv:buildResultRows("D32", "Count the number of unique AQD_SamplingPoint (via localId) submitted within base:namespace ",
                (), (), "", string(count($tblD32)), "", "","error",$tblD32)}
        {xmlconv:buildResultRowsWithTotalCount("D33", <span>The content of aqd:AQD_SamplingPoint/ef:mediaMonitored shall resolve to any concept in
            <a href="{ $xmlconv:MEDIA_VALUE_VOCABULARY }">{ $xmlconv:MEDIA_VALUE_VOCABULARY }</a></span>,
            (), (), "ef:mediaMonitored", "", "", "","warning", $invalidSamplingPointMedia)}

        {xmlconv:buildResultRowsWithTotalCount("D34", <span>aqd:AQD_SamplingPoint/am:geometry/gml:Point the srsName attribute  shall  be  a  recognisable  URN .  The  following  2  srsNames  are  expected urn:ogc:def:crs:EPSG::4258 or urn:ogc:def:crs:EPSG::4326</span>,
            $invalidGeometryPoint, (), "gml:point", "", "", "","warning", $allGeometryPoint)}

        {xmlconv:buildResultRows("D35", "./ef:geometry/gml:Point/gml:pos the srsDimension attribute shall resolve to ""2"" to allow the coordinate of the station",
                $invalidPos, () , "aqd:AQD_SamplingPoint/@gml:id", "All srsDimension attributes resolve to ""2""", " invalid attribute", "","error",())}
        {xmlconv:buildResultRows("D36", "./ef:geometry/gml:Point/gml:pos shall resolve to within the approximate geographic location of the AQD_Station cited by .aqd:AQD_SamplingPoint ef:broader",
                $invalidSamplingPointPos, () , "aqd:AQD_SamplingPoint/@gml:id", "All attributes are valid", " invalid attribute", "","warning",())}
        {xmlconv:buildResultRows("D37", "Total number aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod/ invalid or overlapping operational activity periods ",
                (), $allObservingCapabilityPeriod, "", concat(fn:string(count($allObservingCapabilityPeriod))," errors found"), "", "","error", ())}

        {xmlconv:buildResultRowsWithTotalCount("D40", <span>The content of ../ef:observedProperty shall resolve to a valid code within
            <a href="{ $xmlconv:POLLUTANT_VOCABULARY }">{ $xmlconv:POLLUTANT_VOCABULARY }</a></span>,
                (), (), "ef:observedProperty", "", "", "","error", $invalidObservedProperty)}

        <tr style="border-top:2px solid #666666">
            <th colspan="3" style="vertical-align:top;text-align:left">Internal XML cross-checks between AQD_SamplingPoint and AQD_Sample;AQD_SamplingPointProcess;AQD_Station;AQD_Network</th>
            </tr>
	    <tr style="border-top:0px solid #666666">
            <td colspan="3" style="vertical-align:top;text-align:left">Please note that the qa might give you warning if different features have been submitted in separate XMLs</td>
            </tr>


        {xmlconv:buildResultRows("D41", "Cross-check with AQD_Sample (./ef:observingCapability/ef:ObservingCapability/ef:featureOfInterest/@xlink shall resolve to a traversable local of global URI to an ../AQD_Sample)",
                (),$invalideFeatureOfInterest,"aqd:AQD_SamplingPoint/@gml:id", "All attributes are valid", " invalid attribute", "","warning", ())}
        {xmlconv:buildResultRows("D42", "Cross-check with AQD_SamplingPointProcess (./ef:observingCapability/ef:ObservingCapability/ef:procedure/@xlink shall resolve to a traversable local of global URI to  ../AQD_SamplingPointProcess)",
                (),$invalidEfprocedure, "aqd:AQD_SamplingPoint/@gml:id", "All attributes are valid", " invalid attribute", "","warning", ())}
        {xmlconv:buildResultRows("D43", "Cross-check with AQD_Station (../ef:broader/@xlink shall resolve to a traversable local of global URI to ../AQD_Station)",
                (),$invalidEfbroader, "aqd:AQD_SamplingPoint/@gml:id", "All attributes are valid", " invalid attribute", "","warning", ())}
        {xmlconv:buildResultRows("D44", "Cross-check with AQD_Network (../ef:belongsTo shall resolve to a traversable local of global URI to ../AQD_Network)",
                (),$invalidEfbelongsTo, "aqd:AQD_SamplingPoint/@gml:id", "All attributes are valid", " invalid attribute", "","warning", ())}
	    <tr style="border-top:2px solid #666666">
            <th colspan="3" style="vertical-align:top;text-align:left"></th>
            </tr>

{xmlconv:buildResultRows("D45", "Total number aqd:AQD_SamplingPoint/ef:operationActivityPeriod/ef:OperationActivityPeriod/ef:activityTime/gml:TimePeriod/ invalid operational activity periods ",
                (), $allOperationActivitPeriod, "", concat(fn:string(count($allOperationActivitPeriod))," errors found"), "", "", "error",())}

        {xmlconv:buildResultRows("D46", "Total number of AQD_SamplingPoints which are operational ",
                (), $allUnknownEfOperationActivityPeriod, "", "", "", "","info", ())}

        {xmlconv:buildResultRows("D50", "Total number/aqd:stationClassification which resolve to http://dd.eionet.europa.eu/vocabulary/aq/stationclassification/ via xlink:href ",
                (), $invalidStationClassificationLink, "", concat(fn:string(count($invalidStationClassificationLink))," errors found"), "", "","error", ())}
        {xmlconv:buildResultRows("D51", "Number of invalid 3 elements aqd:AQD_SamplingPoint/aqd:environmentalObjective/aqd:EnvironmentalObjective/ combinations: ",
                (), $invalidObservedPropertyCombinations, "", concat(fn:string(count($invalidObservedPropertyCombinations))," errors found"), " invalid attribute", "", "warning",())}
    	{xmlconv:buildResultRows("D52", "Number of SamplingPoint(s) declared as usedAQD = TRUE which are not used in any Assessment Regime stored in Content Registry",
                (), $allInvalidTrueUsedAQD, "", concat(fn:string(count($allInvalidTrueUsedAQD))," errors found"), "", "", "warning",())}
        {xmlconv:buildResultRows("D53", " Number of invalid aqd:AQD_SamplingPoint/aqd:zone xlinks: ",
                (),  $allInvalidZoneXlinks, "", concat(fn:string(count( $allInvalidZoneXlinks))," errors found"), " invalid attribute", "", "error",())}
        {xmlconv:buildResultRows("D54", "aqd:AQD_SamplingPointProcess/ompr:inspireId/base:Identifier/base:localId not unique codes: ",
                (),$invalidDuplicateSamplingPointProcessIds, "", concat(string(count($invalidDuplicateSamplingPointProcessIds))," errors found.") , " invalid attribute", "","error", ())}

	<tr style="border-top:2px solid #666666">
            <td style="vertical-align:top;"></td>
            <td style="vertical-align:top;"></td>
            <td style="vertical-align:top;"></td>
	</tr>
	<tr style="border-top:0px solid #666666">
            <th colspan="2" style="vertical-align:top;text-align:left">Specific checks on AQD_SamplingPointProcess feature(s) within this XML</th>
            <td style="vertical-align:top;"></td>
	</tr>


        {xmlconv:buildResultRows("D55", "Count the number of unique AQD_SamplingPointProcess (via localId) submitted within base:namespace ",
            (), (), "", string(count($tblD55)), "", "","info",$tblD55)}

        {xmlconv:buildResultRowsWithTotalCount("D56", <span>./aqd:measurementType shall resolve to
            <a href="{ $xmlconv:MEASUREMENTTYPE_VOCABULARY }">{ $xmlconv:MEASUREMENTTYPE_VOCABULARY }</a>/[concept]</span>,
                (), (), "aqd:measurementType", "", "", "","error", $allInvalidMeasurementType)}


        {xmlconv:buildResultRows("D57", <span>If ./aqd:measurementType resolves to ./measurementtype/automatic or ./measurementtype/remote,
            aqd:measurementMethod shall be included and resolve to any concept in
            <a href="{ $xmlconv:MEASUREMENTMETHOD_VOCABULARY }">{ $xmlconv:MEASUREMENTMETHOD_VOCABULARY }</a> AND /aqd:samplingMethod and ./aqd:analyticalTechnique SHALL NOT BE PROVIDED</span>,
                (), $allConceptUrl57, "", concat(string(count($allConceptUrl57)), " errors found"), "", "", "error", ())}


        {xmlconv:buildResultRows("D58", " aqd:measurementType  which resolves
            to ./measurementtype/active or ./measurementtype/passive  shall be included ./aqd:samplingMethod and ./aqd:analyticalTechnique. ./aqd:measurementMethod shall not be provided.",
                (), $elementsIncluded, "", concat(fn:string(count($elementsIncluded))," errors found"), " invalid attribute", "","warning", ())}

        {xmlconv:buildResultRowsWithTotalCount("D59", <span>The content of /aqd:AQD_SamplingPointProcess/aqd:analyticalTechnique shall resolve to any concept in
            <a href="{ $xmlconv:ANALYTICALTECHNIQUE_VOCABULARY }">{ $xmlconv:ANALYTICALTECHNIQUE_VOCABULARY }</a></span>,
                (), (), "aqd:analyticalTechnique", "", "", "","error",$allInvalidAnalyticalTechnique )}

        {xmlconv:buildResultRowsWithTotalCount("D60a", <span>The content of ./aqd:AQD_SamplingPointProcess/aqd:measurementType shall resolve to any concept in
            <a href="{ $xmlconv:MEASUREMENTEQUIPMENT_VOCABULARY }">{ $xmlconv:MEASUREMENTEQUIPMENT_VOCABULARY }</a></span>,
                (), (), "aqd:measurementEquipment", "", "", "","error",$allInvalid60a )}
        {xmlconv:buildResultRowsWithTotalCount("D60b", <span>The content of ./aqd:AQD_SamplingPointProcess/aqd:samplingEquipment shall resolve to any concept in
            <a href="{ $xmlconv:SAMPLINGEQUIPMENT_VOCABULARY }">{ $xmlconv:SAMPLINGEQUIPMENT_VOCABULARY }</a></span>,
                (), (), "aqd:samplingEquipment", "", "", "","error",$allInvalid60b )}
        <!--{xmlconv:buildResultRows("D61", "Total number ./aqd:dataQuality/aqd:DataQuality/aqd:detectionLimit witch does not contain an integer, fixed point or floating point number ",
                (), $allInvalid61, "", concat(fn:string(count($allInvalid61))," errors found"), "", "", ())}-->

        {xmlconv:buildResultRowsWithTotalCount("D63", <span>Where ./aqd:detectionLimit is resolved uom link resolving to any concept in <a href="{ $xmlconv:UOM_CONCENTRATION_VOCABULARY }">{ $xmlconv:UOM_CONCENTRATION_VOCABULARY }</a> shall be provided</span>,
                (), (), "aqd:detectionLimit", "", "", "","error",$allInvalid63 )}

	<tr style="border-top:1px solid #666666">
            <th colspan="3" style="vertical-align:top;text-align:left">Checks on SamplingPointProcess(es) where the xlinked SamplingPoint has aqd:AQD_SamplingPoint/aqd:usedAQD equals TRUE (D67 to D70): </th>
            </tr>

{xmlconv:buildResultRows("D67", concat('SamplingPointProcess(es) with incorrect code for Equivalence demonstration',
		' (http://dd.eionet.europa.eu/vocabulary/aq/equivalencedemonstrated/) ',''),
                (), $allInvalidTrueUsedAQD67, "", concat(fn:string(count($allInvalidTrueUsedAQD67))," errors found"), "", "", "warning",())}

{xmlconv:buildResultRows("D68", concat('SamplingPointProcess(es) declared as an equivalent method” ',
		'i.e. http://dd.eionet.europa.eu/vocabulary/aq/equivalencedemonstrated/yes ',
		'but /aqd:demonstrationReport not provided. '),
                (), $allInvalidTrueUsedAQD68, "", concat(fn:string(count($allInvalidTrueUsedAQD68))," errors found"), "", "", "warning",())}

{xmlconv:buildResultRows("D69", concat('SamplingPointProcess(es) is missing mandatory document on Traceability and Uncertainty Estimation ',
                ' via aqd:AQD_SamplingPointProcess/aqd:dataQuality/aqd:DataQuality/aqd:documentation. ',''),
                (), $allInvalidTrueUsedAQD69, "", concat(fn:string(count($allInvalidTrueUsedAQD69))," errors found"), "", "", "warning",())}

{xmlconv:buildResultRows("D70", concat('SamplingPointProcess(es) is missing mandatory document on QA/QC ',
                ' via aqd:AQD_SamplingPointProcess/aqd:dataQuality/aqd:DataQuality/aqd:qaReport. ',''),
                (), $allInvalidTrueUsedAQD70, "", concat(fn:string(count($allInvalidTrueUsedAQD70))," errors found"), "", "", "warning",())}


        <!--{xmlconv:buildResultRows("D67", <span>Where .AQD_SamplingPoint/aqd:usedAQD is 'true' the content of ./aqd:AQD_SamplingPointProcess/aqd:equivalenceDemonstrated shall resolve to any concept in
            <a href="{ $xmlconv:EQUIVALENCEDEMONSTRATED_VOCABULARY }">{ $xmlconv:EQUIVALENCEDEMONSTRATED_VOCABULARY }</a></span>,
                (),$allInvalid67, "", concat(string(count($allInvalid67))," errors found.") , "", "","error", ())}
        {xmlconv:buildResultRows("D68", <span>Where ./AQD_SamplingPoint/aqd:usedAQD is “true”, ./aqd:demonstrationReport shall be  populate</span>,
                (),$allInvalid68, "", concat(string(count($allInvalid68))," errors found.") , "", "","error", ())}
        {xmlconv:buildResultRows("D69", <span>Where ./AQD_SamplingPoint/aqd:usedAQD is “true”, ./aqd:documentation shall be populate</span>,
            (),$allInvalid69, "", concat(string(count($allInvalid69))," errors found.") , "", "","error", ())}
        {xmlconv:buildResultRows("D70", <span>Where ./AQD_SamplingPoint/aqd:usedAQD is “true”, ./aqd:qaReport shall be populated</span>,
                (),$allInvalid70, "", concat(string(count($allInvalid70))," errors found.") , "", "","error", ())}-->

	<tr style="border-top:2px solid #666666">
            <td style="vertical-align:top;"></td>
            <td style="vertical-align:top;"></td>
            <td style="vertical-align:top;"></td>
	</tr>
	<tr style="border-top:0px solid #666666">
            <th colspan="2" style="vertical-align:top;text-align:left">Specific checks on AQD_Sample feature(s) within this XML</th>
            <td style="vertical-align:top;"></td>
	</tr>


        {xmlconv:buildResultRows("D71", "aqd:AQD_Sample/ompr:inspireId/base:Identifier/base:localId not unique codes: ",
                (),$invalidDuplicateSampleIds, "", concat(string(count($invalidDuplicateSampleIds))," errors found.") , "", "","error", ())}
        {xmlconv:buildResultRows("D72", "Count the number of unique AQD_Sample (via localId) submitted within base:namespace ",
                (), (), "", string(count($tblD72)), "", "","error",$tblD72)}


        {xmlconv:buildResultRows("D73", "./sams:shape/gml:Point the srsName attribute  shall  be  a  recognisable  URN .  The  following  2  srsNames  are  expected urn:ogc:def:crs:EPSG::4258 or urn:ogc:def:crs:EPSG::4326",
                $strErr73 ,(), "", concat(string(count($tblD73)), $errMsg73), "", "",$errLevelD73, $tblD73, $isInvalidInvalidD73 )}


        {xmlconv:buildResultRows("D74", "./sams:shape/gml:Point, the srsDimension attribute shall resolve to “2” to allow the coordinate  of  the  feature  of  interest",
                $invalidPointDimension,(), "aqd:AQD_Sample/@gml:id","All srsDimension attributes are valid"," invalid attribute","","error", ())}
        {xmlconv:buildResultRows("D78", "./aqd:inletHeight shall contain a numerical value, uom within it shall resolve to http://dd.eionet.europa.eu/vocabulary/uom/length/m",
                $invalidInletHeigh,(), "aqd:AQD_Sample/@gml:id","All values are valid"," invalid attribute","", "warning",())}

 	<tr style="border-top:3px solid #666666">
            <td style="vertical-align:top;"></td>
            <td style="vertical-align:top;"></td>
            <td style="vertical-align:top;"></td>
	</tr>

        <!--{xmlconv:buildResultRowsWithTotalCount("D67", <span>The content of ./aqd:AQD_SamplingPoint/aqd:samplingEquipment shall resolve to any concept in
            <a href="{ $xmlconv:UOM_CONCENTRATION_VOCABULARY }">{ $xmlconv:UOM_CONCENTRATION_VOCABULARY }</a></span>,
                (), (), "aqd:samplingEquipment", "", "", "",$allInvalid67 )}
-->

    </table>
}
;
declare function xmlconv:checkVocabularyConceptValues($source_url as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string)
as element(tr)*{
    xmlconv:checkVocabularyConceptValues($source_url, $featureType, $element, $vocabularyUrl, "")
};
declare function xmlconv:checkVocabularyConceptValues($source_url as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $vocabularyType as xs:string)
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
                <td title="ef:name">{data($rec/ef:name)}</td>
                <td title="{ $element }" style="color:red">{$conceptUrl}</td>
            </tr>
    else
        ()
};

(: TODO add attribute as method param :)
declare function xmlconv:checkVocabularyConceptValuesUom($source_url as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string)
as element(tr)*{

    if(doc-available($source_url))
    then

        let $sparql := xmlconv:getConceptUrlSparql($vocabularyUrl)
        let $crConcepts := xmlconv:executeSparqlQuery($sparql)

        for $rec in doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

        for $conceptUrl in $rec/child::*[name() = $element]/@uom



        let $conceptUrl := normalize-space($conceptUrl)

        where string-length($conceptUrl) > 0

        return
            <tr isvalid="{ xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl) }">
                <td title="Feature type">{ $featureType }</td>
                <td title="gml:id">{data($rec/@gml:id)}</td>
                <td title="{ $element }" style="color:red">{$conceptUrl}</td>
            </tr>
    else
        ()
};

declare function xmlconv:checkVocabularyConceptValues2($source_url as xs:string, $concept , $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $vocabularyType as xs:string)
as element(tr)*{

    if(doc-available($source_url))
    then

        let $sparql :=
            if ($vocabularyType = "collection") then
                xmlconv:getCollectionConceptUrlSparql($vocabularyUrl)
            else
                xmlconv:getConceptUrlSparql($vocabularyUrl)
        let $crConcepts := xmlconv:executeSparqlQuery($sparql)

        for $rec in $concept/ancestor::*[name()=$featureType]

        for $conceptUrl in $concept



        let $conceptUrl := normalize-space($conceptUrl)

        where string-length($conceptUrl) > 0

        return
            <tr isvalid="{ xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl) }">
                <td title="Feature type">{ $featureType }</td>
                <td title="gml:id">{data($rec/@gml:id)}</td>
                <td title="ef:name">{data($rec/ef:name)}</td>
                <td title="{ $element }" style="color:red">{$conceptUrl}</td>
            </tr>
    else
        ()
};

declare function xmlconv:checkVocabularyConceptValues3($source_url as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $vocabularyType as xs:string){

    if(doc-available($source_url))
    then

        let $sparql :=
            if ($vocabularyType = "collection") then
                xmlconv:getCollectionConceptUrlSparql($vocabularyUrl)
            else
                xmlconv:getConceptUrlSparql($vocabularyUrl)
        let $crConcepts := xmlconv:executeSparqlQuery($sparql)

        for $rec in doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

        for $conceptUrl in $rec/child::*[name() = $element]





        where  not(xmlconv:isMatchingVocabCode($crConcepts, normalize-space($conceptUrl/@xlink:href)))

        return
            $conceptUrl
    else
        ()
};


declare function xmlconv:isValidConceptCode($conceptUrl as xs:string?, $vocabularyUrl as xs:string)
as xs:boolean {

    let $conceptUrl := if (empty($conceptUrl)) then "" else $conceptUrl

    let $sparql := xmlconv:getConceptUrlSparql($vocabularyUrl)
    let $crConcepts := xmlconv:executeSparqlQuery($sparql)

    return xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl)

};

declare function xmlconv:checkVocabularyConceptValues4($source_url as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string)
as element(tr)*{

    if(doc-available($source_url))
    then

        let $sparql := xmlconv:getConceptUrlSparql($vocabularyUrl)
        let $crConcepts := xmlconv:executeSparqlQuery($sparql)

        for $rec in doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

        for $conceptUrl in $rec//child::*[name() = $element]/@xlink:href


        let $conceptUrl := normalize-space($conceptUrl)

        where string-length($conceptUrl) > 0 and not(xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl))

        return
            <tr isvalid="{ xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl) }">
                <td title="Feature type">{ $featureType }</td>
                <td title="gml:id">{data($rec/@gml:id)}</td>
                <td title="ef:name">{data($rec/ef:name)}</td>
                <td title="{ $element }" style="color:red">{$conceptUrl}</td>
            </tr>
    else
        ()
};


declare function xmlconv:checkVocabularyaqdAnalyticalTechniqueValues($source_url as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $vocabularyType as xs:string)
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

        for $conceptUrl in $rec/child::*[name() = $element]/aqd:AnalyticalTechnique/child::*[name() = $element]/@xlink:href



        let $conceptUrl := normalize-space($conceptUrl)

        where string-length($conceptUrl) > 0

        return
            <tr isvalid="{ xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl) }">
                <td title="Feature type">{ $featureType }</td>
                <td title="gml:id">{data($rec/@gml:id)}</td>
                <td title="ef:name">{data($rec/ef:name)}</td>
                <td title="{ $element }" style="color:red">{$conceptUrl}</td>
            </tr>
    else
        ()
};

declare function xmlconv:checkVocabulariesConceptEquipmentValues($source_url as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrls as xs:string*, $vocabularyType as xs:string)
as element(tr)*{

    if(doc-available($source_url))
    then
      let $crConcepts :=
        for  $vocabularyUrl in  $vocabularyUrls

            let $sparql :=
              if ($vocabularyType = "collection") then
                xmlconv:getCollectionConceptUrlSparql($vocabularyUrl)
            else
                xmlconv:getConceptUrlSparql($vocabularyUrl)
        return
        xmlconv:executeSparqlQuery($sparql)

        for $rec in doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

        for $conceptUrl in $rec/child::*[name() = $element]/@xlink:href



        let $conceptUrl := normalize-space($conceptUrl)

       where string-length($conceptUrl) > 0

        return
               <tr isvalid="{ xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl) }">
                <td title="Feature type">{ $featureType }</td>
                <td title="gml:id">{data($rec/@gml:id)}</td>
                <td title="ef:name">{data($rec/ef:name)}</td>
                <td title="{ $element }" style="color:red">{$conceptUrl}</td>
            </tr>
    else
        ()
};



declare function xmlconv:checkVocabularyConceptEquipmentValues($source_url as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $vocabularyType as xs:string)
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

        for $conceptUrl in $rec/child::*[name() = $element]/*/aqd:equipment/@xlink:href



        let $conceptUrl := normalize-space($conceptUrl)

        where string-length($conceptUrl) > 0

        return
            <tr isvalid="{ xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl) }">
                <td title="Feature type">{ $featureType }</td>
                <td title="gml:id">{data($rec/@gml:id)}</td>
                <td title="ef:name">{data($rec/ef:name)}</td>
                <td title="{ $element }" style="color:red">{$conceptUrl}</td>
            </tr>
    else
        ()
};
declare function xmlconv:checkMeasurementMethodLinkValues($source_url as xs:string, $concept,$featureType as xs:string,  $vocabularyUrl as xs:string, $vocabularyType as xs:string)
as element(tr)*{
    if(doc-available($source_url))
    then

        let $sparql :=
            if ($vocabularyType = "collection") then
                xmlconv:getCollectionConceptUrlSparql($vocabularyUrl)
            else
                xmlconv:getConceptUrlSparql($vocabularyUrl)
        let $crConcepts := xmlconv:executeSparqlQuery($sparql)
        for $conceptUrl in $concept/../../aqd:measurementMethod/aqd:MeasurementMethod/aqd:measurementMethod/@xlink:href
            let $measurementMethodStyle := if(xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl))then "" else "color:red"
            let $analyticalTechniqueStyle := if(count($conceptUrl/../../../../*[name(.) = "aqd:analyticalTechnique"])=0)then "" else "color:red"
            let $samplingMethod := if(count($conceptUrl/../../../../*[name(.) = "aqd:samplingMethod"])=0)then "" else "color:red"

        return
            <tr isvalid="{ xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl) and count($conceptUrl/../../../../*[name(.) = "aqd:analyticalTechnique"])=0  and count($conceptUrl/../../../../*[name(.) = "aqd:samplingMethod"])=0}">
                <td title="gml:id">{data($conceptUrl/../../../../@gml:id)}</td>
                <td style="{$measurementMethodStyle}" title="{name($conceptUrl/..)}" >{data($conceptUrl)}</td>
                <td style="{$analyticalTechniqueStyle}" title=" aqd:analyticalTechnique " >{if(count($conceptUrl/../../../../*[name(.) = "aqd:analyticalTechnique"])=0)then "Valid." else "Error, shall not be provided."}</td>
                <td style="{$samplingMethod}" title=" aqd:samplingMethod " >{if(count($conceptUrl/../../../../*[name(.) = "aqd:samplingMethod"])=0)then "Valid." else "Error, shall not be provided."}</td>
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

declare function xmlconv:isMatchingVocabCode($crConcepts as element(sparql:result)*, $concept as xs:string)
as xs:boolean
{
    count($crConcepts/sparql:binding[@name="concepturl" and sparql:uri=$concept]) > 0
};

(:
 : ======================================================================
 : Main function
 : ======================================================================
 :)
declare function xmlconv:proceed($source_url as xs:string, $countryCode as xs:string) {

let $countFeatures := count(doc($source_url)//gml:featureMember/descendant::*[
    not(empty(index-of($xmlconv:FEATURE_TYPES, name())))]
    )
let $result := if ($countFeatures > 0) then xmlconv:checkReport($source_url, $countryCode) else ()

return
    <div>
        <h2>Check environmental monitoring feature types - Dataflow D</h2>
        {

        if ( $countFeatures = 0) then
            <p>No environmental monitoring feature type elements ({string-join($xmlconv:FEATURE_TYPES, ", ")}) found from this XML.</p>
        else
        <div>
            {
                if ($result//div/@class = 'error') then
                    <div>
                        <p class="error" style="color:red"><strong>This XML file did NOT pass the following crucial check(s): {string-join($result//div[@class = 'error'], ',')}</strong></p>
                        <p style="color:red">Please pay attention that QA rules D1-D4 concern all monitoring (measurement) feature types, QA rules D5 - D14 concern AQD_Networks, QA rules D15 - D30 concern AQD_Stations, QA rules D31 - D53 concern AQD_SamplingPoints, QA rules D54 - D70 concern AQD_SamplingPointProcesses, QA rules D71 - D77 concern AQD_Samples, QA rules D78 - D85 concern AQD_RepresentativeAreas.</p>
                        <p style="color:red">Please pay attention that QA rules M1 - M5 concern all monitoring (model) feature types, QA rules M6 - M26 concern AQD_Models, QA rules M27 - M39 concern AQD_ModelProcesses, QA rules M40 - M45 concern AQD_ModelAreas.</p>
                    </div>
                else
                    <p>This XML file passed all crucial checks.</p>
            }

            {
                if ($result//div/@class = 'warning') then
                    <div>
                        <p style="color:orange"><strong>This XML file did NOT pass the following check(s): {string-join($result//div[@class = 'warning'], ',')}</strong></p>
                        <p style="color:grey">Please pay attention that QA rules D1-D4 concern all monitoring (measurement) feature types, QA rules D5 - D14 concern AQD_Networks, QA rules D15 - D30 concern AQD_Stations, QA rules D31 - D53 concern AQD_SamplingPoints, QA rules D54 - D70 concern AQD_SamplingPointProcesses, QA rules D71 - D77 concern AQD_Samples, QA rules D78 - D85 concern AQD_RepresentativeAreas.</p>
                        <p style="color:grey">Please pay attention that QA rules M1 - M5 concern all monitoring (model) feature types, QA rules M6 - M26 concern AQD_Models, QA rules M27 - M39 concern AQD_ModelProcesses, QA rules M40 - M45 concern AQD_ModelAreas.</p>
                    </div>
                else
                    ()
            }
            <p>This feedback report provides a summary overview of feature types reported and some consistency checks defined in Dataflow D as specified in <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a>.</p>
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

declare function xmlconv:aproceed ($source_url, $countryCode ) {

let $docRoot := doc($source_url)

let $invalidPos_srsDim  := distinct-values($docRoot//aqd:AQD_Station/ef:geometry/gml:Point/gml:pos[@srsDimension != "2"]/
concat(../../../@gml:id, ": srsDimension=", @srsDimension))


let $aqdStationPos :=
    for $allPos in $docRoot//aqd:AQD_Station
    where not(empty($allPos/ef:geometry/gml:Point/gml:pos))
    return concat($allPos/ef:inspireId/base:Identifier/base:namespace,"/",$allPos/ef:inspireId/base:Identifier/base:localId,"|",
        fn:substring-before(data($allPos/ef:geometry/gml:Point/gml:pos), " "), "#", fn:substring-after(data($allPos/ef:geometry/gml:Point/gml:pos), " "))


let $invalidPos_order :=
    for $gmlPos in $docRoot//aqd:AQD_SamplingPoint

        let $samplingPos := data($gmlPos/ef:geometry/gml:Point/gml:pos)
        let $samplingLat := if (not(empty($samplingPos))) then fn:substring-before($samplingPos, " ") else ""
        let $samplingLong := if (not(empty($samplingPos))) then fn:substring-after($samplingPos, " ") else ""


        let $samplingLat := if ($samplingLat castable as xs:decimal) then xs:decimal($samplingLat) else 0.00
        let $samplingLong := if ($samplingLong castable as xs:decimal) then xs:decimal($samplingLong) else 0.00

        return if ($samplingLat < $samplingLong and $countryCode != 'FR')
        then concat($gmlPos/@gml:id, " : lat=" , string($samplingLat), " :long=", string($samplingLong)) else ()



let $invalidPosD21 := (($invalidPos_srsDim), ($invalidPos_order))

return data($invalidPos_order )
};

(:)
xmlconv:proceed( $source_url, $country )
:)
