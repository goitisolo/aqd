xquery version "1.0" encoding "UTF-8";
(:
 : Module Name: Implementing Decision 2011/850/EU: AQ info exchange & reporting (Library module)
 :
 : Version:     $Id$
 : Created:     13 September 2013
 : Copyright:   European Environment Agency
 :)
(:~
 : XQuery script implements dataflow M tier-1 checks as documented in http://taskman.eionet.europa.eu/documents/3 .
 :
 : @author Juri Tõnisson
 :
 :Quality Assurance and Control rules version: 3.9d
 :)

module namespace xmlconv = "http://converters.eionet.europa.eu/dataflowM";
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

(:~ declare Content Registry SPARQL endpoint:)
declare variable $xmlconv:CR_SPARQL_URL := "http://cr.eionet.europa.eu/sparql";

declare variable $xmlconv:ISO2_CODES as xs:string* := ("AL","AT","BA","BE","BG","CH","CY","CZ","DE","DK","DZ","EE","EG","ES","FI",
    "FR","GB","GR","HR","HU","IE","IL","IS","IT","JO","LB","LI","LT","LU","LV","MA","ME","MK","MT","NL","NO","PL","PS","PT",
     "RO","RS","SE","SI","SK","TN","TR","XK","UK");

declare variable $xmlconv:FEATURE_TYPES := ("aqd:AQD_Model", "aqd:AQD_ModelProcess", "aqd:AQD_ModelArea");


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
    let $countResult := if($isCountAvailable) then (data($endpoint//sparql:binding[@name='callret-0']/sparql:literal)) else ""
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
            let $offset := if ($r > 1) then string(((number($r)-1) * $limit)+1) else "1"
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
    $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string, $recordDetails as element(tr)*)
as element(tr)*{

    let $countInvalidValues := count($invalidStrValues) + count($invalidValues)

    let $recordDetails := if (count($invalidValues) > 0) then $invalidValues else $recordDetails

    let $bulletType := if (string-length($skippedMsg) > 0) then "skipped" else if ($countInvalidValues = 0) then "info" else $errorLevel
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
    } order by ?inspireid"
    )
};

declare function xmlconv:getSamplingPointZone($zoneId as xs:string*)
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
declare function xmlconv:checkReport($source_url as xs:string, $countryCode as xs:string)
as element(table) {

let $docRoot := doc($source_url)

(: M1 :)
let $countFeatureTypes :=
    for $featureType in $xmlconv:FEATURE_TYPES
    return
        count(doc($source_url)//gml:featureMember/descendant::*[name()=$featureType])
let $tblAllFeatureTypes :=
    for $featureType at $pos in $xmlconv:FEATURE_TYPES
    where $countFeatureTypes[$pos] > 0
    return
        <tr>
            <td title="Feature type">{$featureType }</td>
            <td title="Total number">{$countFeatureTypes[$pos]}</td>
        </tr>

(: M2 :)

let $M2Combinations :=
    for $featureType in $xmlconv:FEATURE_TYPES
    return
        doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

let $nameSpaces := distinct-values($docRoot//base:namespace)
let $zonesSparql := xmlconv:getZonesSparql($nameSpaces)
let $isZonesAvailable := string-length($zonesSparql) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($zonesSparql, "xml"))
let $knownZones := if ($isZonesAvailable ) then distinct-values(data(xmlconv:executeSparqlQuery($zonesSparql)//sparql:binding[@name='inspireid']/sparql:literal)) else ()
let $unknownZones :=
    for $zone in $M2Combinations
    let $id := if (empty($zone/@gml:id)) then "" else data($zone/@gml:id)
    where empty(index-of($knownZones, $id))
    return $zone

let $tblM2 :=
    for $rec in $unknownZones
    return
        $rec/@gml:id


(: M3 :)

let $M3Combinations :=
    for $featureType in $xmlconv:FEATURE_TYPES
    return
        doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

let $nameSpaces := distinct-values($docRoot//base:namespace)
let $zonesSparql := xmlconv:getZonesSparql($nameSpaces)
let $isZonesAvailable := string-length($zonesSparql) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($zonesSparql, "xml"))
let $knownZones := if ($isZonesAvailable ) then distinct-values(data(xmlconv:executeSparqlQuery($zonesSparql)//sparql:binding[@name='inspireid']/sparql:literal)) else ()
let $unknownZones :=
    for $zone in $M3Combinations
    let $id := if (empty($zone/@gml:id)) then "" else data($zone/@gml:id)
    where empty(index-of($knownZones, $id))=false()
    return $zone

let $tblM3 :=
    for $rec in $unknownZones
    return
        $rec/@gml:id

(: M4 :)


    let $M4Combinations :=
        for $featureType in $xmlconv:FEATURE_TYPES
        return
            doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

    let $allM4Combinations :=
    for $aqdModel in $M4Combinations
    return concat(data($aqdModel/@gml:id), "#", $aqdModel/am:inspireId, "#", $aqdModel/aqd:inspireId, "#", $aqdModel/ef:name, "#", $aqdModel/ompr:name )

let $allM4Combinations := fn:distinct-values($allM4Combinations)
let $tblM4 :=
    for $rec in $allM4Combinations
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

            <td title="agml:id">{xmlconv:checkLink($modelType)}</td>
            <td title="am:inspireId">{xmlconv:checkLink($inspireId)}</td>
            <td title="aqd:inspireId">{xmlconv:checkLink($aqdInspireId)}</td>
            <td title="ef:name">{xmlconv:checkLink($efName)}</td>
            <td title="ompr:name">{xmlconv:checkLink($omprName)}</td>
        </tr>

(: M5 :)
let $M5Combinations :=
    for $featureType in $xmlconv:FEATURE_TYPES
    return
        doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

let $gmlIds := $M5Combinations/lower-case(normalize-space(@gml:id))
let $duplicateGmlIds := distinct-values(
        for $id in $M5Combinations/@gml:id
        where string-length(normalize-space($id)) > 0 and count(index-of($gmlIds, lower-case(normalize-space($id)))) > 1
        return
            $id
)
let $amInspireIds := for $id in $M5Combinations/am:inspireId
return
    lower-case(concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
            ", ", normalize-space($id/base:Identifier/base:versionId), "]"))
let $duplicateamInspireIds := distinct-values(
        for $id in $M5Combinations/am:inspireId
        let $key :=
            concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
                    ", ", normalize-space($id/base:Identifier/base:versionId), "]")
        where string-length(normalize-space($id/base:Identifier/base:localId)) > 0 and count(index-of($amInspireIds, lower-case($key))) > 1
        return
            $key
)


let $aqdInspireIds := for $id in $M5Combinations/aqd:inspireId
return
    lower-case(concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
            ", ", normalize-space($id/base:Identifier/base:versionId), "]"))
let $duplicateaqdInspireIds := distinct-values(
        for $id in $M5Combinations/aqd:inspireId
        let $key :=
            concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
                    ", ", normalize-space($id/base:Identifier/base:versionId), "]")
        where  string-length(normalize-space($id/base:Identifier/base:localId)) > 0 and count(index-of($aqdInspireIds, lower-case($key))) > 1
        return
            $key
)


let $countGmlIdDuplicates := count($duplicateGmlIds)
let $countamInspireIdDuplicates := count($duplicateamInspireIds)
let $countaqdInspireIdDuplicates := count($duplicateaqdInspireIds)
let $countB8duplicates := $countGmlIdDuplicates + $countamInspireIdDuplicates + $countaqdInspireIdDuplicates

(: M6 :)
let $amInspireIds := $docRoot//aqd:AQD_Model/ef:inspireId/base:Identifier/concat(lower-case(normalize-space(base:namespace)), '##',
        lower-case(normalize-space(base:localId)))
let $duplicateEUStationCode := distinct-values(
        for $identifier in $docRoot//aqd:AQD_Model/am:inspireId/base:Identifier
        where string-length(normalize-space($identifier/base:localId)) > 0 and count(index-of($amInspireIds,
                concat(lower-case(normalize-space($identifier/base:namespace)), '##', lower-case(normalize-space($identifier/base:localId))))) > 1
        return
            concat(normalize-space($identifier/base:namespace), ':', normalize-space($identifier/base:localId))
)
let $countAmInspireIdDuplicates := count($duplicateEUStationCode)
let $countM6duplicates := $countAmInspireIdDuplicates

(: M7 :)
let $allBaseNamespace := distinct-values($docRoot//aqd:AQD_Model/ef:inspireId/base:Identifier/base:namespace)
let  $tblM7 :=
    for $id in $allBaseNamespace
    let $localId := $docRoot//aqd:AQD_Model/ef:inspireId/base:Identifier[base:namespace = $id]/base:localId
    return
        <tr>
            <td title="base:namespace">{$id}</td>
            <td title="base:localId">{count($localId)}</td>
        </tr>

(: M12 :)

let $invalidGeometry := distinct-values($docRoot//aqd:AQD_Model[count(ef:geometry) >0 and ef:geometry/@srsName != "urn:ogc:def:crs:EPSG::4258" and ef:geometry/@srsName != "urn:ogc:def:crs:EPSG::4326"]/@gml:id)

(: M15 :)

let $allNotNullEndPeriods :=
    for $allPeriod in $docRoot//gml:featureMember//aqd:AQD_Model/ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod
    where ($allPeriod/gml:endPosition[normalize-space(@indeterminatePosition)!="unknown"]
            or fn:string-length($allPeriod/gml:endPosition) > 0)
    return $allPeriod

let $allObservingCapabilityPeriod :=
    for $observingCapabilityPeriod in $allNotNullEndPeriods
    where ((xs:dateTime($observingCapabilityPeriod/gml:endPosition) < xs:dateTime($observingCapabilityPeriod/gml:beginPosition)))
    return
        <tr>
            <td title="aqd:AQD_Model">{data($observingCapabilityPeriod/../../../../@gml:id)}</td>
            <td title="gml:TimePeriod">{data($observingCapabilityPeriod/@gml:id)}</td>
            <td title="gml:beginPosition">{$observingCapabilityPeriod/gml:beginPosition}</td>
            <td title="gml:endPosition">{$observingCapabilityPeriod/gml:endPosition}</td>
        </tr>

(: M18 :)

let $invalidObservedProperty := xmlconv:checkVocabularyConceptValues($source_url, "aqd:AQD_Model/ef:observingCapability/ef:ObservingCapability", "ef:observedProperty", $xmlconv:POLLUTANT_VOCABULARY)

(: M19 :)

let $aqdModelArea :=
    for $allModelArea in $docRoot//aqd:AQD_ModelArea
    return $allModelArea/@gml:id

let $invalideFeatureOfInterest :=
    for $x in $docRoot//aqd:AQD_Model/ef:observingCapability/ef:ObservingCapability/ef:featureOfInterest
    where empty(index-of($aqdModelArea,fn:normalize-space(fn:substring-after($x/@xlink:href,"/"))))
    return
        <tr>
            <td title="aqd:AQD_AQD_Model">{data($x/../../../@gml:id)}</td>
            <td title="ef:featureOfInterest">{data(fn:normalize-space(fn:substring-after($x/@xlink:href,"/")))}</td>
        </tr>

(: M23 :)
let $invalidObservedPropertyCombinations :=
    for $oPC in $docRoot//gml:featureMember/aqd:AQD_Model/aqd:environmentalObjective/aqd:EnvironmentalObjective
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

(: 24 :)

let $invalidAssessmentType := $docRoot//aqd:AQD_Model/aqd:assessmentType[fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/model" and fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/objective" ]/../@gml:id

(: M25 :)

    let $allTrueUsedAQD :=
        for $trueUsedAQD in $docRoot//gml:featureMember/aqd:AQD_Model
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

(: M26 :)

let $allInvalidZoneXlinks :=
   for $invalidZoneXlinks in $docRoot//gml:featureMember/aqd:AQD_Model/aqd:zone
        where
            count(xmlconv:executeSparqlQuery(xmlconv:getSamplingPointZone($invalidZoneXlinks/@xlink:href))/*) = 0
        return
            <tr>
                <td title="gml:id">{data($invalidZoneXlinks/../@gml:id)}</td>
                <td title="aqd:zone">{data($invalidZoneXlinks/@xlink:href)}</td>
            </tr>

(: M27 :)

    let $localModelProcessIds := $docRoot//gml:featureMember/aqd:AQD_ModelProcess/ompr:inspireId/base:Identifier
    let $invalidDuplicateModelProcessIds :=
        for $idModelProcessCode in $docRoot//gml:featureMember/aqd:AQD_ModelProcess/ompr:inspireId/base:Identifier
        where
            count(index-of($localModelProcessIds/base:localId, normalize-space($idModelProcessCode/base:localId))) > 1 and
                    count(index-of($localModelProcessIds/base:namespace, normalize-space($idModelProcessCode/base:namespace))) > 1
        return
            <tr>
                <td title="aqd:AQD_ModelProcess">{data($idModelProcessCode/../../@gml:id)}</td>
                <td title="base:localId">{data($idModelProcessCode/base:localId)}</td>
                <td title="base:namespace">{data($idModelProcessCode/base:namespace)}</td>
            </tr>
(: M28 :)

    let $allBaseNamespace := distinct-values($docRoot//aqd:AQD_ModelProcess/ompr:inspireld/base:Identifier/base:namespace)

    let  $tblM28 :=
        for $id in $allBaseNamespace
        let $localId := $docRoot//aqd:AQD_ModelProcess/ompr:inspireld/base:Identifier[base:namespace = $id]/base:localId
        return
            <tr>
                <td title="base:namespace">{$id}</td>
                <td title="base:localId">{count($localId)}</td>
            </tr>

(: M29 :)

let $invalidBase2link :=
    for $baseLink in  $docRoot//aqd:AQD_ModelProcess/ompr:documentation/base2:DocumentationCitation/base2:link
    let $invalidLink:= fn:substring-before($baseLink,":")
where (fn:lower-case($invalidLink) !="http")and(fn:lower-case($invalidLink) !="https")
return
<tr>
    <td title="aqd:AQD_ModelProcess">{data($baseLink/../../../@gml:id)}</td>
    <td title="base2:link">{data($baseLink)}</td>
</tr>

(: M39 :)

let $invalidDataQualityReport :=
    for $dataQualityReport in  $docRoot//aqd:AQD_ModelProcess/dataQualityReport
    let $invalidLink:= fn:substring-before($dataQualityReport,":")
where (fn:lower-case($invalidLink) !="http")and(fn:lower-case($invalidLink) !="https")
return
<tr>
    <td title="aqd:AQD_ModelProcess">{data($dataQualityReport/../@gml:id)}</td>
    <td title="base2:link">{data($dataQualityReport)}</td>
</tr>

    (: M40 :)
let $localModelAreaIds := $docRoot//gml:featureMember/aqd:AQD_ModelArea/ompr:inspireId/base:Identifier
let $invalidDuplicateModelAreaIds :=
    for $idModelAreaCode in $docRoot//gml:featureMember/aqd:AQD_ModelArea/ompr:inspireId/base:Identifier
    where
        count(index-of($localModelAreaIds/base:localId, normalize-space($idModelAreaCode/base:localId))) > 1 and
                count(index-of($localModelAreaIds/base:namespace, normalize-space($idModelAreaCode/base:namespace))) > 1
    return
        <tr>
            <td title="aqd:AQD_ModelProcess">{data($idModelAreaCode/../../@gml:id)}</td>
            <td title="base:localId">{data($idModelAreaCode/base:localId)}</td>
            <td title="base:namespace">{data($idModelAreaCode/base:namespace)}</td>
        </tr>

(: M41 :)
let $allBaseNamespace := distinct-values($docRoot//aqd:AQD_ModelArea/aqd:inspireId/base:Identifier/base:namespace)
let  $tblM41 :=
    for $id in $allBaseNamespace
    let $localId := $docRoot//aqd:AQD_ModelArea/aqd:inspireId/base:Identifier[base:namespace = $id]/base:localId
    return
        <tr>
            <td title="base:namespace">{$id}</td>
            <td title="base:localId">{count($localId)}</td>
        </tr>

(: M43 :)

    let $invalidSrsName := distinct-values($docRoot//aqd:AQD_Sample[count(sams:shape) >0 and sams:shape/@srsName != "urn:ogc:def:crs:EPSG::4258" and sams:shape/@srsName != "urn:ogc:def:crs:EPSG::4326"]/@gml:id)

    return
    <table style="border-collapse:collapse;display:inline">
        <colgroup>
            <col width="15px" style="text-align:center"/>
            <col width="500px" style="text-align:left"/>
            <col width="350px" style="text-align:left"/>
            <col width="*"/>
        </colgroup>
        {xmlconv:buildResultRows("M1", "Total number of each environmental monitoring feature types",
            (), (), "", string(sum($countFeatureTypes)), "", "","error", $tblAllFeatureTypes)}
        {xmlconv:buildResultRows("M2", "Compile and feedback upon the total number of new records for each environmental monitoring feature types included in the delivery",
                (), (), "", string(count($tblM2)), "", "","error",())}
        {xmlconv:buildResultRows("M3", "Compile and feedback upon the total number of modification to existing for each environmental monitoring feature types included in the delivery",
        (), (), "", string(count($tblM3)), "", "","error",())}
        {xmlconv:buildResultRows("M4", "Total number  aqd:aqdModelType, aqd:inspireId, ef:name, ompr:nam  combinations ",
                (), (), "", string(count($tblM4)), "", "","error",$tblM4)}
        <tr style="border-top:1px solid #666666">
        <tr>
            <td style="vertical-align:top;">{ xmlconv:getBullet("M5", if ($countB8duplicates = 0) then "info" else "error") }</td>
            <th style="vertical-align:top;">All gml:id attributes, am:inspireId and aqd:inspireId elements shall have unique content</th>
            <td style="vertical-align:top;">{
                if ($countB8duplicates = 0) then
                    "All Ids are unique"
                else
                    concat($countB8duplicates, " duplicate", substring("s ", number(not($countB8duplicates > 1)) * 2) ,"found") }</td>
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
            if ($countamInspireIdDuplicates > 0) then
                <tr style="font-size: 0.9em;color:grey;">
                    <td colspan="2" style="text-align:right;vertical-align:top;">am:inspireId - </td>
                    <td style="font-style:italic;vertical-align:top;">{ string-join($duplicateamInspireIds, ", ")}</td>
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
        <tr style="border-top:1px solid #666666">
            <td style="vertical-align:top;">{ xmlconv:getBullet("M6", if ($countM6duplicates = 0) then "info" else "error") }</td>
            <th style="vertical-align:top;">./am:inspireId/base:Identifier/base:localId shall be an unique code within namespace</th>
            <td style="vertical-align:top;">{
                if ($countM6duplicates = 0) then
                    <span style="font-size:1.3em;">All Ids are unique</span>
                else
                    concat($countM6duplicates, " error", substring("s ", number(not($countM6duplicates > 1)) * 2) ,"found") }</td>
        </tr>
        {xmlconv:buildResultRows("M7", "./ef:inspireId/base:Identifier/base:namespace List base:namespace and  count the number of base:localId assigned to each base:namespace. ",
                (), (), "", string(count($tblM7)), "", "","error",$tblM7)}

        {xmlconv:buildResultRows("M12", "./ef:geometry the srsName attribute  shall  be  a  recognisable  URN .  The  following  2  srsNames  are  expected urn:ogc:def:crs:EPSG::4258 or urn:ogc:def:crs:EPSG::4326",
                $invalidGeometry,(), "aqd:AQD_Model/@gml:id","All smsName attributes are valid"," invalid attribute","","error", ())}
        {xmlconv:buildResultRows("M15", "Total number aqd:AQD_Model/ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod/ invalid operational activity periods ",
                (), $allObservingCapabilityPeriod, "", concat(fn:string(count($allObservingCapabilityPeriod))," errors found"), "", "","error", ())}
        {xmlconv:buildResultRowsWithTotalCount("M18", <span>The content of ./ef:observedProperty shall resolve to a valid code within
            <a href="{ $xmlconv:POLLUTANT_VOCABULARY }">{ $xmlconv:POLLUTANT_VOCABULARY }</a></span>,
                (), (), "aqd:AQD_Model", "", "", "", "error", $invalidObservedProperty)}
        {xmlconv:buildResultRows("M19", "./ef:observingCapability/ef:ObservingCapability/ef:featureOfInterest shall resolve to a traversable local of global URI to an ../AQD_ModelArea",
                (),$invalideFeatureOfInterest,"aqd:AQD_Model/@gml:id", "All attributes is invalid", " invalid attribute", "","error", ())}
        {xmlconv:buildResultRows("M23", "Number of invalid 3 elements /aqd:AQD_Model/aqd:environmentalObjective/aqd:EnvironmentalObjective/ combinations: ",
                (), $invalidObservedPropertyCombinations, "", concat(fn:string(count($invalidObservedPropertyCombinations))," errors found"), "", "","error", ())}
        {xmlconv:buildResultRows("M24", "/aqd:assessmentType shall resolve to http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/ via xlink:href to either http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/model or http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/objective",
                $invalidAssessmentType, (), "", concat(fn:string(count($invalidAssessmentType))," errors found"), "", "","error", ())}
        {xmlconv:buildResultRows("M25", " Number of AQD_Model(s) witch has ./aqd:usedAQD equals “true” but does not have at least at one /aqd:Model xlinked: ",
                (), $allInvalidTrueUsedAQD, "", concat(fn:string(count($allInvalidTrueUsedAQD))," errors found"), "", "","warning", ())}
        {xmlconv:buildResultRows("M26", " Number of invalid aqd:AQD_Model/aqd:zone xlinks: ",
                (),  $allInvalidZoneXlinks, "", concat(fn:string(count( $allInvalidZoneXlinks))," errors found"), "", "","error", ())}
        {xmlconv:buildResultRows("M27", "./aqd:inspireId/base:Identifier/base:localId shall be an unique code for AQD_ModelProgress and unique within the namespace",
                (),$invalidDuplicateModelProcessIds, "", concat(string(count($invalidDuplicateModelProcessIds))," errors found.") , "", "","error", ())}
        {xmlconv:buildResultRows("M28", "./ompr:inspireld/base:Identifier/base:namespace List base:namespace and  count the number of base:localId assigned to each base:namespace. ",
                (), (), "", string(count($tblM28)), "", "","error",$tblM28)}
        {xmlconv:buildResultRows("M29", "./ompr:documentation/base2:DocumentationCitation/base2:link shall resolve to a traversable URL to a documentation report",
                (),$invalidBase2link, "aqd:AQD_ModelProcess/@gml:id","All attributes are valid"," invalid attribute","","error", ())}
        {xmlconv:buildResultRows("M39", "./dataQualityReport shall provide a traversable URL to a report describing the data quality equaluati on proces",
                (),$invalidDataQualityReport, "aqd:AQD_ModelProcess/@gml:id","All attributes are valid"," invalid attribute","","error", ())}
        {xmlconv:buildResultRows("M40", "./aqd:inspireId/base:Identifier/base:localId shall be an unique code for AQD_ModelArea and unique within the namespace",
                (),$invalidDuplicateModelAreaIds, "", concat(string(count($invalidDuplicateModelAreaIds))," errors found.") , "", "","error",())}
        {xmlconv:buildResultRows("M41", "./aqd:inspireId/base:Identifier/base:namespace List base:namespace and  count the number of base:localId assigned to each base:namespace. ",
                (), (), "", string(count($tblM41)), "", "","error",$tblM41)}
        {xmlconv:buildResultRows("M43", "./sams:shape, the srsDimension attribute shall resolve to “2” to allow the coordinate  of  the  feature  of  intere",
                $invalidSrsName,(), "aqd:AQD_ModelArea/@gml:id","All srsDimension attributes are valid"," invalid attribute","","error", ())}

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


declare function xmlconv:checkVocabularyConceptEquipmentValues($source_url as xs:string,  $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $vocabularyType as xs:string)
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
declare function xmlconv:checkMeasurementMethodLinkValues($source_url as xs:string,  $concept,$featureType as xs:string,  $vocabularyUrl as xs:string, $vocabularyType as xs:string)
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
declare function xmlconv:proceed($source_url as xs:string, $countryCode as xs:string) {

let $countFeatures := count(doc($source_url)//gml:featureMember/descendant::*[
    not(empty(index-of($xmlconv:FEATURE_TYPES, name())))]
    )
let $result := if ($countFeatures > 0) then xmlconv:checkReport($source_url, $countryCode) else ()

return
    <div>
        <h2>Check environmental monitoring feature types - Dataflow D on Models and Objective Estimation</h2>
        {
        if ( $countFeatures = 0) then
            <p>No environmental monitoring feature type elements ({string-join($xmlconv:FEATURE_TYPES, ", ")}) found from this XML.</p>
        else
        <div>
            {
                if ($result//div/@class = 'error') then
                    <p>This XML file did NOT pass the following crucial checks: {string-join($result//div[@class = 'error'], ',')}</p>
                else
                    <p>This XML file passed all crucial checks' which in this case are: M1,M2,M3,M4,M5,M6,M7,M12,M15,M18,M19,M21,M22,M23,M24,M26,M27,M28,M29,M30,M38,M39,M40,M41,M43</p>
            }
            <p>This feedback report provides a summary overview of feature types reported and some consistency checks defined in Dataflow D on Models and Objective Estimation as specified in <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a>.</p>
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
(:)
xmlconv:proceed( $source_url )
:)
