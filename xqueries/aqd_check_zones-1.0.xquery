xquery version "1.0" encoding "UTF-8";
(:
 : Module Name: Implementing Decision 2011/850/EU: AQ info exchange & reporting (Library module)
 :
 : Version:     $Id$
 : Created:     20 June 2013
 : Copyright:   European Environment Agency
 :)
(:~
 : XQuery script implements dataflow B tier-1 checks as documented in http://taskman.eionet.europa.eu/documents/3 .
 :
 : @author Enriko Käsper
 : small modification added by Jaume Targa (ETC/ACM) to align with QA document
 :)

module namespace xmlconv = "http://converters.eionet.europa.eu/dataflowB";
declare namespace aqd = "http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0";
declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace am = "http://inspire.ec.europa.eu/schemas/am/3.0";
declare namespace ef = "http://inspire.ec.europa.eu/schemas/ef/3.0";
declare namespace base = "http://inspire.ec.europa.eu/schemas/base/3.3";
declare namespace gn = "urn:x-inspire:specification:gmlas:GeographicalNames:3.0";
declare namespace base2 = "http://inspire.ec.europa.eu/schemas/base2/1.0";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace ompr = "http://inspire.ec.europa.eu/schemas/ompr/2.0";

declare variable $xmlconv:AQ_MANAGEMENET_ZONE := "http://inspire.ec.europa.eu/codeList/ZoneTypeCode/airQualityManagementZone";
declare variable $xmlconv:ZONETYPE_VOCABULARY as xs:string := "http://dd.eionet.europa.eu/vocabulary/aq/zonetype/";

(:
declare variable $country as xs:string := "es";
declare variable $source_url as xs:string := "../test/DE_B_Zones_2013.xml";
declare variable $source_url as xs:string := "../test/ES_B_Zones.xml";
declare variable $source_url as xs:string := "http://cdrtest.eionet.europa.eu/gi/eu/aqd/b/envvqvz3q/B_GIB_Zones_retro_Corrupted.xml";
declare variable $source_url as xs:string := "../test/B_GIB_Zones_retro_Corrupted.xml";
declare variable $source_url as xs:string := "../test/B_ES_B_Zones_corrupted.xml";
declare variable $source_url as xs:string := "http://cdrtest.eionet.europa.eu/es/eu/aqd/b/envvs_qvq/B_ES_ES_B_Zones_corrupted.xml";
declare variable $country as xs:string := "gi";
declare variable $source_url as xs:string := "../test/B_GIB_Zones_retro_Corrupted2.xml";
:)



(:~ declare Content Registry SPARQL endpoint:)
declare variable $xmlconv:CR_SPARQL_URL := "http://cr.eionet.europa.eu/sparql";
declare variable $xmlconv:invalidCount as xs:integer := 0;


declare variable $xmlconv:ISO2_CODES as xs:string* := ("AL","AT","BA","BE","BG","CH","CY","CZ","DE","DK","DZ","EE","EG","ES","FI",
    "FR","GB","GR","HR","HU","IE","IL","IS","IT","JO","LB","LI","LT","LU","LV","MA","ME","MK","MT","NL","NO","PL","PS","PT",
     "RO","RS","SE","SI","SK","TN","TR","XK","UK");
(:===================================================================:)
(: Variable given as an external parameter by the QA service                                                 :)
(:===================================================================:)


(:
declare variable $source_url as xs:string external;
declare variable $source_url := "../test/FR.xml";
declare variable $source_url := "../test/B.2013_3_.xml";
declare variable $source_url as xs:string external;
declare variable $ source_url := "../test/D_GB_Zones.xml";
declare variable $source_url as xs:untypedAtomic external;
Change it for testing locally:
declare variable $source_url := "http://cdr.eionet.europa.eu/gb/eu/aqd/e2a/colutn32a/envubnpvw/B_GB_Zones.xml";
:)



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

declare function xmlconv:getNutsSparql($countryCode as xs:string)
as xs:string
{
    concat("PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    SELECT ?concepturl ?label ?code
    WHERE {
      ?concepturl skos:inScheme <http://dd.eionet.europa.eu/vocabulary/common/nuts/>;
                  skos:prefLabel ?label;
                  skos:notation ?code
                  FILTER regex(?code, '^", $countryCode, "', 'i')
    }")
};
declare function xmlconv:getLau2Sparql($countryCode as xs:string)
as xs:string
{

    concat("PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    SELECT ?concepturl ?label ?code
    WHERE {
      ?concepturl skos:inScheme <http://dd.eionet.europa.eu/vocabulary/lau2/", $countryCode, "/>;
                  skos:prefLabel ?label;
                  skos:notation ?code
    }")
};

declare function xmlconv:getLau1Sparql($countryCode as xs:string)
as xs:string
{

    concat("PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    SELECT ?concepturl ?label ?code
    WHERE {
      ?concepturl skos:inScheme <http://dd.eionet.europa.eu/vocabulary/lau1/", $countryCode, "/>;
                  skos:prefLabel ?label;
                  skos:notation ?code
    }")
};


declare function xmlconv:getLangCodesSparql()
as xs:string
{
    "PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    SELECT distinct ?code ?label ?concepturl
    WHERE {
      ?concepturl a skos:Concept .
      {?concepturl skos:inScheme <http://dd.eionet.europa.eu/vocabulary/common/iso639-3/>;
                  skos:prefLabel ?label;
                  skos:notation ?code}
      UNION
      {?concepturl skos:inScheme <http://dd.eionet.europa.eu/vocabulary/common/iso639-5/>;
                  skos:prefLabel ?label;
                  skos:notation ?code}

    }"
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
    }"
    )
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

(:
    Builds HTML table rows for rules B13 - B17.
:)
declare function xmlconv:buildResultRows($ruleCode as xs:string, $text, $invalidValues as xs:string*,
    $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string)
as element(tr)*{
    let $countInvalidValues := count($invalidValues)
    let $bulletType := if (string-length($skippedMsg) > 0) then "skipped" else if ($countInvalidValues = 0) then "info" else $errorLevel
let $result :=
    (
        <tr>
            <td style="vertical-align:top;">{ xmlconv:getBullet($ruleCode, $bulletType) }
            </td>
            <th style="vertical-align:top;">{ $text }</th>
            <td style="vertical-align:top;">{
                if (string-length($skippedMsg) > 0) then
                    $skippedMsg
                else if ($countInvalidValues = 0) then
                    $validMsg
                else
                     concat($countInvalidValues, $invalidMsg, substring("s ", number(not($countInvalidValues > 1)) * 2) ,"found") }</td>
        </tr>,
            if ($countInvalidValues > 0) then
                <tr style="font-size: 0.9em;color:grey;">
                    <td colspan="2" style="text-align:right;vertical-align:top;">{ $valueHeading} - </td>
                    <td style="font-style:italic;vertical-align:top;">{ string-join($invalidValues, ", ")}</td>
                </tr>
            else
                ()
    )
return $result

};

declare function xmlconv:buildResultTable($ruleCode as xs:string, $text,
    $valueHeading as xs:string*, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string, $recordDetails as element(tr)*)
as element(tr)*{
    let $countInvalidValues := count($recordDetails)

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
                    concat($countInvalidValues, $invalidMsg, substring("s ", number(not($countInvalidValues > 1)) * 2) ," found") }
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

(: B1 :)
let $countZones := count($docRoot//aqd:AQD_Zone)

(: B2 :)
let $nameSpaces := distinct-values($docRoot//base:namespace)
let $zonesSparql := xmlconv:getZonesSparql($nameSpaces)
let $isZonesAvailable := string-length($zonesSparql) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($zonesSparql, "xml"))
let $knownZones := if ($isZonesAvailable ) then distinct-values(data(xmlconv:executeSparqlQuery($zonesSparql)//sparql:binding[@name='inspireid']/sparql:literal)) else ()
let $unknownZones :=
for $zone in $docRoot//gml:featureMember/aqd:AQD_Zone
    let $id := if (empty($zone/@gml:id)) then "" else data($zone/@gml:id)
    where empty(index-of($knownZones, $id))
    return $zone

let $tblB2 :=
    for $rec in $unknownZones
    return
        <tr>
            <td title="gml:id">{data($rec/@gml:id)}</td>
            <td title="aqd:predecessor">{if (empty($rec/aqd:predecessor)) then "not specified" else data($rec/aqd:predecessor/aqd:AQD_Zone/@gml:id)}</td>
        </tr>

(: B3 :)
let $countZonesWithAmGeometry := count($docRoot//aqd:AQD_Zone/am:geometry)
(: B4 :)
let $countZonesWithLAU := count($docRoot//aqd:AQD_Zone[not(empty(aqd:LAU)) or not(empty(aqd:shapefileLink))])

(: B6 :)

(:
let $allB6Combinations :=
for $aqdZone in $docRoot//aqd:AQD_Zone
return concat(data($aqdZone/@gml:id), "#", $aqdZone/am:inspireId, "#", $aqdZone/aqd:inspireId, "#", $aqdZone/ef:name, "#", $aqdZone/ompr:name )
let $allB6Combinations := fn:distinct-values($allB6Combinations)
:)

let $allB6Combinations := $docRoot//aqd:AQD_Zone

let $tblB6 :=
    for $rec in $allB6Combinations
    (:
    let $zoneType := substring-before($rec, "#")
    let $tmpStr := substring-after($rec, concat($zoneType, "#"))
    let $inspireId := substring-before($tmpStr, "#")
    let $tmpInspireId := substring-after($tmpStr, concat($inspireId, "#"))
    let $aqdInspireId := substring-before($tmpInspireId, "#")
    let $tmpEfName := substring-after($tmpInspireId, concat($aqdInspireId, "#"))
    let $efName := substring-before($tmpEfName, "#")
    let $omprName := substring-after($tmpEfName,concat($efName,"#"))
    :)
    return
        <tr>
            <td title="gml:id">{data($rec/@gml:id)}</td>
            <td title="namespace/localId">{concat(data($rec/am:inspireId/base:Identifier/base:namespace),'/', data($rec/am:inspireId/base:Identifier/base:localId))}</td>
            <td title="zoneName">{data($rec/am:name/gn:GeographicalName/gn:spelling/gn:SpellingOfName/gn:text)}</td>
            <td title="zoneCode">{data($rec/aqd:zoneCode)}</td>
        </tr>

(: B7 :)
(: Compile & feedback a list of aqd:aqdZoneType, aqd:pollutantCode, aqd:protectionTarget combinations in the delivery :)
let $allB7Combinations :=
    for $pollutant in $docRoot//aqd:Pollutant
    return concat(data($pollutant/../../aqd:aqdZoneType/@xlink:href), "#", data($pollutant/aqd:pollutantCode/@xlink:href), "#",data($pollutant/aqd:protectionTarget/@xlink:href))

let $allB7Combinations := fn:distinct-values($allB7Combinations)
let $tblB7 :=
    for $rec in $allB7Combinations
    let $zoneType := substring-before($rec, "#")
    let $tmpStr := substring-after($rec, concat($zoneType, "#"))
    let $pollutant := substring-before($tmpStr, "#")
    let $protTarget := substring-after($tmpStr, "#")
    return
        <tr>
            <td title="aqd:aqdZoneType">{xmlconv:checkLink($zoneType)}</td>
            <td title="aqd:pollutantCode">{xmlconv:checkLink($pollutant)}</td>
            <td title="aqd:protectionTarget">{xmlconv:checkLink($protTarget)}</td>
        </tr>

(: B8 :)
let $gmlIds := $docRoot//aqd:AQD_Zone/lower-case(normalize-space(@gml:id))
let $duplicateGmlIds := distinct-values(
    for $id in $docRoot//aqd:AQD_Zone/@gml:id
    where string-length(normalize-space($id)) > 0 and count(index-of($gmlIds, lower-case(normalize-space($id)))) > 1
    return
        $id
    )
let $amInspireIds := for $id in $docRoot//aqd:AQD_Zone/am:inspireId
                     return
                        lower-case(concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
                            ", ", normalize-space($id/base:Identifier/base:versionId), "]"))
let $duplicateamInspireIds := distinct-values(
    for $id in $docRoot//aqd:AQD_Zone/am:inspireId
    let $key :=
        concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
            ", ", normalize-space($id/base:Identifier/base:versionId), "]")
    where string-length(normalize-space($id/base:Identifier/base:localId)) > 0 and count(index-of($amInspireIds, lower-case($key))) > 1
    return
        $key
    )


let $aqdInspireIds := for $id in $docRoot//aqd:AQD_Zone/aqd:inspireId
                     return
                        lower-case(concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
                            ", ", normalize-space($id/base:Identifier/base:versionId), "]"))
let $duplicateaqdInspireIds := distinct-values(
    for $id in $docRoot//aqd:AQD_Zone/aqd:inspireId
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

(: B9 The base:localId needs to be unique within namespace.  :)
let $amInspireIds := $docRoot//aqd:AQD_Zone/am:inspireId/base:Identifier/concat(lower-case(normalize-space(base:namespace)), '##',
    lower-case(normalize-space(base:localId)))
let $duplicateAmInspireIds := distinct-values(
    for $identifier in $docRoot//aqd:AQD_Zone/am:inspireId/base:Identifier
    where string-length(normalize-space($identifier/base:localId)) > 0 and count(index-of($amInspireIds,
        concat(lower-case(normalize-space($identifier/base:namespace)), '##', lower-case(normalize-space($identifier/base:localId))))) > 1
    return
        concat(normalize-space($identifier/base:namespace), ':', normalize-space($identifier/base:localId))
    )

(: FIXME  :)
(: wrong rule here.
The element that "shall be an unique code for network starting with ISO2-country code" is aqd:zoneCode
with the exception of UnitedKingdom that might use UK instead of GB

let $invalidIsoAmInspireIds := distinct-values(
    for $id in $docRoot//aqd:AQD_Zone/am:inspireId/base:Identifier/base:localId
    where string-length(normalize-space($id)) > 0 and (string-length(normalize-space($id)) < 2 or
        count(index-of($xmlconv:ISO2_CODES , substring(upper-case(normalize-space($id)), 1, 2))) = 0)
    return
        $id
    )
:)
let $countAmInspireIdDuplicates := count($duplicateAmInspireIds)
let $countB9duplicates := $countAmInspireIdDuplicates

(: B10 :)
let $allBaseNamespace := distinct-values($docRoot//aqd:AQD_Zone/am:inspireId/base:Identifier/base:namespace)
let  $tblB10 :=
    for $id in $allBaseNamespace
    let $localId := $docRoot//aqd:AQD_Zone/am:inspireId/base:Identifier[base:namespace = $id]/base:localId
 return
        <tr>
            <td title="base:namespace">{$id}</td>
            <td title="base:localId">{count($localId)}</td>
        </tr>

(: B11 :)


(: B13 :)
let $langCodeSparql := xmlconv:getLangCodesSparql()
let $isLangCodesAvailable := string-length($langCodeSparql) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($langCodeSparql, "xml"))
let $langCodes := if ($isLangCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($langCodeSparql)//sparql:binding[@name='code']/sparql:literal)) else ()
let $isLangCodesAvailable := count($langCodes) > 0

let $invalidLangCode := if ($isLangCodesAvailable) then
        distinct-values($docRoot//aqd:AQD_Zone/am:name/gn:GeographicalName[string-length(normalize-space(gn:language)) > 0 and
            empty(
            index-of($langCodes, normalize-space(gn:language)))
            and empty(index-of($langCodes, normalize-space(gn:language)))]/gn:language)
    else
        ()

let $langSkippedMsg :=
    if (not($isLangCodesAvailable)) then "The test was skipped - ISO 639-3 and ISO 639-5 language codes are not available in Content Registry."
    else ""

(: B14 :)
(:
let $unknownNativeness := distinct-values($docRoot//aqd:AQD_Zone[count(am:name/gn:GeographicalName/gn:nativeness[@xsi:nil="true" and @nilReason="unknown"])>0]/@gml:id)
:)
(: B15 :)
(:
let $unknownNameStatus := distinct-values($docRoot//aqd:AQD_Zone[count(am:name/gn:GeographicalName/gn:nameStatus[@xsi:nil="true" and @nilReason="unknown"])>0]/@gml:id)
:)
(: B16 :)
(:
let $unknownSourceOfName := distinct-values($docRoot//aqd:AQD_Zone[count(am:name/gn:GeographicalName/gn:sourceOfName[@xsi:nil="true" and @nilReason="unknown"])>0]/@gml:id)
:)
(: B17 :)
(:
let $unknownPronunciation  := distinct-values($docRoot//aqd:AQD_Zone[count(am:name/gn:GeographicalName/gn:pronunciation[@xsi:nil="true" and @nilReason="unknown"])>0]/@gml:id)
:)
(: B18 :)
let $invalidgnSpellingOfName := $docRoot//aqd:AQD_Zone[string-length(am:name/gn:GeographicalName/gn:spelling/gn:SpellingOfName/gn:text)=0]/@gml:id

(: B20 :)

let $invalidPolygonName := distinct-values($docRoot//aqd:AQD_Zone[count(am:geometry/gml:Polygon) >0 and am:geometry/gml:Polygon/@srsName != "urn:ogc:def:crs:EPSG::4258" and am:geometry/gml:Polygon/@srsName != "urn:ogc:def:crs:EPSG::4326"]/@gml:id)

let $invalidPointName := distinct-values($docRoot//aqd:AQD_Zone[count(am:geometry/gml:Point) >0 and am:geometry/gml:Point/@srsName != "urn:ogc:def:crs:EPSG::4258"
    and am:geometry/gml:Point/@srsName != "urn:ogc:def:crs:EPSG::4326"]/@gml:id)
let $invalidMultiPointName := distinct-values($docRoot//aqd:AQD_Zone[count(am:geometry/gml:MultiPoint) >0 and am:geometry/gml:MultiPoint/@srsName != "urn:ogc:def:crs:EPSG::4258"
    and am:geometry/gml:MultiPoint/@srsName != "urn:ogc:def:crs:EPSG::4326"]/@gml:id)
let $invalidMultiSurfaceName := distinct-values($docRoot//aqd:AQD_Zone[count(am:geometry/gml:MultiSurface) >0 and am:geometry/gml:MultiSurface/@srsName != "urn:ogc:def:crs:EPSG::4258"
    and am:geometry/gml:MultiSurface/@srsName != "urn:ogc:def:crs:EPSG::4326"]/@gml:id)
let $invalidGridName := distinct-values($docRoot//aqd:AQD_Zone[count(am:geometry/gml:Grid) >0 and am:geometry/gml:Grid/@srsName != "urn:ogc:def:crs:EPSG::4258"
    and am:geometry/gml:Grid/@srsName != "urn:ogc:def:crs:EPSG::4326"]/@gml:id)
let $invalidRectifiedGridName := distinct-values($docRoot//aqd:AQD_Zone[count(am:geometry/gml:RectifiedGrid) >0 and am:geometry/gml:RectifiedGrid/@srsName != "urn:ogc:def:crs:EPSG::4258"
    and am:geometry/gml:RectifiedGrid/@srsName != "urn:ogc:def:crs:EPSG::4326"]/@gml:id)

let $invalidGmlIdsB20 := distinct-values(($invalidPolygonName, $invalidMultiPointName, $invalidPointName, $invalidMultiSurfaceName, $invalidGridName, $invalidRectifiedGridName))

(: B21 :)
let $invalidPosListDimension  := distinct-values($docRoot//aqd:AQD_Zone/am:geometry/gml:MultiSurface/gml:surfaceMember/gml:Polygon/gml:exterior/gml:LinearRing/gml:posList[@srsDimension != "2"]/
            concat(../../../../../@gml:id, ": srsDimension=", @srsDimension))

(: B22 :)

let $invalidPosListCount :=
for $posList in  $docRoot//aqd:AQD_Zone/am:geometry/gml:MultiSurface/gml:surfaceMember/gml:Polygon/gml:exterior/gml:LinearRing/gml:posList
let $posListCount := count(fn:tokenize(normalize-space($posList)," ")) mod 2
return if (not(empty($posList)) and $posListCount gt 0) then $posList/../../../@gml:id else ()

(: B23 :)

let $invalidLatLong :=
for $latLong in $docRoot//aqd:AQD_Zone/am:geometry/gml:MultiSurface/gml:surfaceMember/gml:Polygon/gml:exterior/gml:LinearRing/gml:posList
let $latlongToken := fn:tokenize($latLong," ")
return if (count($latlongToken) mod 2 != 0) then concat($latLong/../../../@gml:id,": ",$latLong) else ()

(: B24 :)
(: ./am:zoneType value shall resolve to http://inspire.ec.europa.eu/codeList/ZoneTypeCode/airQualityManagementZone :)
 let $invalidManagementZones  := distinct-values($docRoot//aqd:AQD_Zone/am:zoneType[@xlink:href != $xmlconv:AQ_MANAGEMENET_ZONE]/
            concat(../@gml:id, ": zoneType=", @xlink:href))

(: B25 :)
(: ./am:designationPeriod/gml:TimePeriod/gml:beginPosition shall be less than ./am:designationPeri/gml:TimePeriod/gml:endPosition. :)
 let $invalidPosition  :=
    for $timePeriod in $docRoot//aqd:AQD_Zone/am:designationPeriod/gml:TimePeriod
        (: XQ does not support 24h that is supported by xsml schema validation :)
        let $beginDate := substring(normalize-space($timePeriod/gml:beginPosition),1,10)
        let $endDate := substring(normalize-space($timePeriod/gml:endPosition),1,10)
        let $beginPosition := if ($beginDate castable as xs:date) then xs:date($beginDate) else ()
        let $endPosition := if ($endDate castable as xs:date) then xs:date($endDate) else ()
        return
            (:  concat($timePeriod/../../@gml:id, ": gml:beginPosition=", $beginPosition, ": gml:endPosition=", $endPosition) :)

        if (not(empty($beginPosition)) and not(empty($endPosition)) and $beginPosition > $endPosition) then
            concat($timePeriod/../../@gml:id, ": gml:beginPosition=", $beginPosition, ": gml:endPosition=", $endPosition)
        else
            ()


 (: B25 :)

            (:) let $allAmDesignationPeriods :=
 for $designationPeriods in $docRoot//aqd:AQD_Zone/am:designationPeriod
 where $designationPeriods/gml:TimePeriod/gml:endPosition[normalize-space(@indeterminatePosition)="unknown"]
 return
       <tr>
         <td title="aqd:AQD_Zone">{data($designationPeriods/../@gml:id)}</td>
         <td title="gml:TimePeriod">{data($designationPeriods/gml:TimePeriod/@gml:id)}</td>
         <td title="gml:beginPosition">{$designationPeriods/gml:TimePeriod/gml:beginPosition}</td>
         <td title="gml:endPosition">{$designationPeriods/gml:TimePeriod/gml:endPosition}</td>
     </tr> :)


(: B28 :)
(: ./am:beginLifespanVersion shall be a valid historical date for the start of the version of the zone in extended ISO format.
If an am:endLifespanVersion exists its value shall be greater than the am:beginLifespanVersion :)
let $invalidLifespanVer  :=
    for $rec in $docRoot//aqd:AQD_Zone

        let $beginDate := substring(normalize-space($rec/am:beginLifespanVersion),1,10)
        let $endDate := substring(normalize-space($rec/am:endLifespanVersion),1,10)
        let $beginPeriod := if ($beginDate castable as xs:date) then xs:date($beginDate) else ()
        let $endPeriod := if ($endDate castable as xs:date) then xs:date($endDate) else ()

        return
        if ((not(empty($beginPeriod)) and not(empty($endPeriod)) and $beginPeriod > $endPeriod) or empty($beginPeriod)) then
            concat($rec/@gml:id, ": am:beginLifespanVersion=", data($rec/am:beginLifespanVersion),
            if (not(empty($endPeriod))) then concat(": am:endLifespanVersion=", data($rec/am:endLifespanVersion)) else "")
        else
            ()
(: B29 :)
(: ./am:beginLifespanVersion shall be LESS THAN OR EQUAL TO ./am:designationPeriod/gml:TimePeriod/gml:endPosition
./am:beginLifespanVersion shall be GREATER THAN OR EQUAL TO
./am:designationPeriod/gml:TimePeriod/gml:beginPosition
:)
(:
let $invalidLifespanVerB29  :=
    for $rec in $docRoot//aqd:AQD_Zone
        let $beginPeriodDate := substring-before(normalize-space($rec/am:beginLifespanVersion), 'T')
        let $beginPeriod := if ($beginPeriodDate castable as xs:date) then xs:date($beginPeriodDate) else ()
        let $beginPosition := if (normalize-space($rec/am:designationPeriod/gml:TimePeriod/gml:beginPosition) castable as xs:date) then xs:date($rec/am:designationPeriod/gml:TimePeriod/gml:beginPosition) else ()
        let $endPosition := if (normalize-space($rec/am:designationPeriod/gml:TimePeriod/gml:endPosition)  castable as xs:date) then xs:date($rec/am:designationPeriod/gml:TimePeriod/gml:endPosition) else ()

        return
        if (
        (not(empty($beginPeriod)) and not(empty($endPosition)) and $beginPeriod > $endPosition) or
         (not(empty($beginPeriod)) and not(empty($beginPosition)) and $beginPeriod < $beginPosition)
        ) then
            concat($rec/@gml:id, ": am:beginLifespanVersion=", data($rec/am:beginLifespanVersion),
                " gml:beginPosition=", $beginPosition," gml:endPosition=", $endPosition)
        else
            ()
:)

(: B31 :)
let $invalidLegalBasisName  := distinct-values($docRoot//aqd:AQD_Zone/am:legalBasis/base2:LegislationCitation[normalize-space(base2:name) != "2011/850/EC"]/
            concat(../../@gml:id, ": base2:name=", if (string-length(base2:name) > 20) then concat(substring(base2:name, 1, 20), "...") else base2:name))
(: B32 :)
let $invalidLegalBasisDate  := distinct-values($docRoot//aqd:AQD_Zone/am:legalBasis/base2:LegislationCitation[normalize-space(base2:date) != "2011-12-12"]/
            concat(../../@gml:id, ": base2:date=", if (string-length(base2:date) > 20) then concat(substring(base2:date, 1, 20), "...") else base2:date))
(: B33 :)
let $invalidLegalBasisLink  := distinct-values($docRoot//aqd:AQD_Zone/am:legalBasis/base2:LegislationCitation[normalize-space(base2:link) != "http://rod.eionet.europa.eu/instruments/650"]/
            concat(../../@gml:id, ": base2:link=", if (string-length(base2:link) > 40) then concat(substring(base2:link, 1, 40), "...") else base2:link))

(: B35 :)
let $amNamespaceAndaqdZoneCodeIds := $docRoot//aqd:AQD_Zone/concat(am:inspireId/base:Identifier/lower-case(normalize-space(base:namespace)), '##', lower-case(normalize-space(aqd:zoneCode)))

let $dublicateAmNamespaceAndaqdZoneCodeIds := distinct-values(
        for $identifier in $docRoot//aqd:AQD_Zone
where string-length(normalize-space($identifier/am:inspireId/base:Identifier/base:namespace)) > 0 and count(index-of($amNamespaceAndaqdZoneCodeIds,
        concat($identifier/am:inspireId/base:Identifier/lower-case(normalize-space(base:namespace)), '##', $identifier/lower-case(normalize-space(aqd:zoneCode))))) > 1
return
    concat(normalize-space($identifier/am:inspireId/base:Identifier/base:namespace), ':', normalize-space($identifier/aqd:zoneCode))
)

let $countAmNamespaceAndaqdZoneCodeDuplicates := count($dublicateAmNamespaceAndaqdZoneCodeIds)
let $countB35duplicates := $countAmNamespaceAndaqdZoneCodeDuplicates

(: B36 :)
let $invalidResidentPopulation  := distinct-values($docRoot//aqd:AQD_Zone[not(count(aqd:residentPopulation)>0 and aqd:residentPopulation castable as xs:integer and number(aqd:residentPopulation) > 0)]/
            concat(@gml:id, ": aqd:residentPopulation=", if (string-length(aqd:residentPopulation) = 0) then "missing" else aqd:residentPopulation))

(: B37 :)
(: ./aqd:residentPopulationYear/gml:TimeInstant/gml:timePosition shall cite the year in which the resident population was estimated in yyyy format :)
let $invalidPopulationYear :=
for $zone in $docRoot//aqd:AQD_Zone
return
    if (xmlconv:isInvalidYear(data($zone/aqd:residentPopulationYear/gml:TimeInstant/gml:timePosition))) then
        concat($zone/@gml:id, ": gml:timePosition=",data($zone/aqd:residentPopulationYear/gml:TimeInstant/gml:timePosition))
    else ()

(: B38 :)
let $invalidArea  := distinct-values($docRoot//aqd:AQD_Zone[not(count(aqd:area)>0 and number(aqd:area) and number(aqd:area) > 0)]/
            concat(@gml:id, ": aqd:area=", if (string-length(aqd:area) = 0) then "missing" else aqd:area))

(: B40 :)

let $tempStr := xmlconv:checkVocabularyConceptValues($source_url, "", "aqd:AQD_Zone", "aqd:timeExtensionExemption", "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/")
let $invalidTimeExtensionExemption := $tempStr

(: B41 :)

let $zoneIds :=
for $x in $docRoot//aqd:AQD_Zone/aqd:pollutants
where ($x/aqd:Pollutant/aqd:pollutantCode/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/8" and $x/aqd:Pollutant/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
       and ($x/../aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/NO2-1h"
        or $x/../aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/NO2-annual")
return
    data($x/../@gml:id)


let $invalidPollutansB41 :=
    for $y in $docRoot//aqd:AQD_Zone[aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/NO2-1h"
            or aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/NO2-annual"]
    where empty(index-of($zoneIds,$y/@gml:id))
return
        <tr>
            <td title="gml:id">{data($y/@gml:id)}</td>
            <td title="aqd:pollutantCode">{xmlconv:checkLink("http://dd.eionet.europa.eu/vocabulary/aq/pollutant/8")}</td>
            <td title="aqd:protectionTarget">{xmlconv:checkLink("http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")}</td>
        </tr>

(: B42 :)

let $zoneIds :=
    for $x in $docRoot//aqd:AQD_Zone/aqd:pollutants
    where ($x/aqd:Pollutant/aqd:pollutantCode/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5" and $x/aqd:Pollutant/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
            and ($x/../aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/PM10-24h"
                    or $x/../aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/PM10-annual")
    return $x/../@gml:id

let $aqdInvalidPollutansB42 :=
    for $y in $docRoot//aqd:AQD_Zone[aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/PM10-24h"
            or aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/PM10-annual"]
    where empty(index-of($zoneIds,$y/@gml:id))
    return
        <tr>
            <td title="gml:id">{data($y/@gml:id)}</td>
            <td title="aqd:pollutantCode">{xmlconv:checkLink("http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5")}</td>
            <td title="aqd:protectionTarget">{xmlconv:checkLink("http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")}</td>
        </tr>


(: B43 :)

let $zoneIds :=
    for $x in $docRoot//aqd:AQD_Zone/aqd:pollutants
    where (($x/aqd:Pollutant/aqd:pollutantCode/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/20" and $x/aqd:Pollutant/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
            and ($x/../aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/C6H6-annual"))
    return $x/../@gml:id

let $aqdInvalidPollutansBenzene :=
    for $y in $docRoot//aqd:AQD_Zone[aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/C6H6-annual"]
    where empty(index-of($zoneIds,$y/@gml:id))
    return
      <tr>
            <td title="gml:id">{data($y/@gml:id)}</td>
            <td title="aqd:pollutantCode">{xmlconv:checkLink("http://dd.eionet.europa.eu/vocabulary/aq/pollutant/20")}</td>
            <td title="aqd:protectionTarget">{xmlconv:checkLink("http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")}</td>
        </tr>

 (: B44 :)

(:
let $lau2Sparql := if (fn:string-length($countryCode) = 2) then xmlconv:getLau2Sparql($countryCode) else ""
let $isLau2CodesAvailable := string-length($lau2Sparql) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($lau2Sparql, "xml"))
let $lau2Codes := if ($isLau2CodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($lau2Sparql)//sparql:binding[@name='concepturl']/sparql:uri)) else ()
let $isLau2CodesAvailable := count($lau2Codes) > 0

let $lau1Sparql := if (fn:string-length($countryCode) = 2) then xmlconv:getLau1Sparql($countryCode) else ""
let $isLau1CodesAvailable := string-length($lau1Sparql) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($lau1Sparql, "xml"))
let $lau1Codes := if ($isLau1CodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($lau1Sparql)//sparql:binding[@name='concepturl']/sparql:uri)) else ()
let $isLau1CodesAvailable := count($lau1Codes) > 0

let $nutsSparql := if (fn:string-length($countryCode) = 2) then xmlconv:getNutsSparql($countryCode) else ""
let $isNutsCodesAvailable := doc-available(xmlconv:getSparqlEndpointUrl($nutsSparql, "xml"))
let $nutsCodes := if ($isNutsCodesAvailable) then  distinct-values(data(xmlconv:executeSparqlQuery($nutsSparql)//sparql:binding[@name='concepturl']/sparql:uri)) else ()
let $isNutsAvailable := count($nutsSparql) > 0

let $invalidLau := if ($isLau2CodesAvailable and $isNutsAvailable and $isLau1CodesAvailable) then
        distinct-values($docRoot//aqd:AQD_Zone/aqd:LAU[string-length(normalize-space(@xlink:href)) > 0 and
            empty(index-of($lau2Codes, normalize-space(@xlink:href))) and empty(index-of($nutsCodes, normalize-space(@xlink:href))) and empty(index-of($lau1Codes, normalize-space(@xlink:href)))]/@xlink:href)
    else
        ()
let $lauSkippedMsg := if (fn:string-length($countryCode) != 2) then "The test was skipped - reporting country code not found."
    else if (not($isLau2CodesAvailable)) then "The test was skipped - LAU2 concepts are not available in CR."
    else if (not($isNutsAvailable)) then "The test was skipped - NUTS concepts are not available in CR."
    else if (not($isLau1CodesAvailable)) then "The test skipped - LAU1 concepts are not available in CR"
    else ""
:)

(: B45 :)

let $amGeometry := $docRoot//aqd:AQD_Zone[count(am:geometry/@xlink:href)>0]/@gml:id
let $invalidGeometry :=
for $x in $amGeometry
    where (empty($amGeometry)=false())
return $x

(: B46 :)

(: TESTING on localhost :)
(:let $envLink := "http://cdrtest.eionet.europa.eu/ee/eu/colujh9jw/envvdy3dq/xml" :)
let $aqdShapeFileLink := $docRoot//aqd:AQD_Zone/aqd:shapefileLink

let $invalidLink :=
for $link in $aqdShapeFileLink
    let $envLink := xmlconv:getEnvelopeXML($link)
    let $envExists := doc-available($envLink)
    return
    if (not($envExists)  or ($envExists and count(doc($envLink)/envelope/file[@link=$link]) = 0)) then
        concat($link/../@gml:id, ' ', $link)
    else ()


(: B47 :)
let $invalidZoneType := xmlconv:checkVocabularyConceptValues($source_url, "", "aqd:AQD_Zone", "aqd:aqdZoneType", $xmlconv:ZONETYPE_VOCABULARY)

(: TODO 48:)


return
    <table style="text-align:left;vertical-align:top;">
        <tr>
            <td style="vertical-align:top;">{ xmlconv:getBullet("B1", "info") }</td>
            <th style="vertical-align:top;">Total number of AQ zones</th>
            <td style="vertical-align:top;">{ $countZones }</td>
        </tr>

        {xmlconv:buildResultRowsHTML("B2", "Total number of unkown or new records for AQ zone feature for the INSPIRE namespace ",
            (), (), "", string(count($tblB2)), "", "", $tblB2)}

        <tr>
            <td style="vertical-align:top;">{ xmlconv:getBullet("B3", "info") }</td>
            <th style="vertical-align:top;">The number of zones designated with coordinates via the ./am:geometry element</th>
            <td style="vertical-align:top;">{ $countZonesWithAmGeometry }</td>
        </tr>
        <tr>
            <td style="vertical-align:top;">{ xmlconv:getBullet("B4", "info") }</td>
            <th style="vertical-align:top;">The number of zones designated with coordinates via the ./aqd:LAU element and the ./aqd:shapefileLink element</th>
            <td style="vertical-align:top;">{ $countZonesWithLAU }</td>
        </tr>


        {xmlconv:buildResultRowsHTML("B6", "Total number of reported aqd:AQD_Zone",
                (), (), "", string(count($tblB6)), "", "", $tblB6)}

        {xmlconv:buildResultRowsHTML("B7", "List of unique combinations of aqd:aqdZoneType, aqd:pollutantCode and aqd:protectionTarget",
            (), (), "", string(count($tblB7)), "", "", $tblB7)}


        <tr>
            <td style="vertical-align:top;">{ xmlconv:getBullet("B8", if ($countB8duplicates = 0) then "info" else "warning") }</td>
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
                    <td colspan="2" style="text-align:right;vertical-align:top;">aqd:AQD_Zone/@gml:id - </td>
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
        <tr>
            <td style="vertical-align:top;">{ xmlconv:getBullet("B9", if ($countB9duplicates = 0) then "info" else "error") }</td>
            <th style="vertical-align:top;">./am:inspireId/base:Identifier/base:localId shall be an unique code within namespace</th>
            <td style="vertical-align:top;">{
                if ($countB9duplicates = 0) then
                    "All Ids are unique"
                else
                    concat($countB9duplicates, " error", substring("s ", number(not($countB9duplicates > 1)) * 2) ,"found") }</td>
        </tr>
        {
            if ($countAmInspireIdDuplicates > 0) then
                <tr style="font-size: 0.9em;color:grey;">
                    <td colspan="2" style="text-align:right;vertical-align:top;">Duplicate base:namespace:base:localId - </td>
                    <td style="font-style:italic;vertical-align:top;">{ string-join($duplicateAmInspireIds, ", ")}</td>
                </tr>
            else
                ()
        }
        {xmlconv:buildResultRowsHTML("B10", "./am:inspireId/base:Identifier/base:namespace
List base:namespace and  count the number of base:localId assigned to each base:namespace. ",
                (), (), "", string(count($tblB10)), "", "",$tblB10)}

        {xmlconv:buildResultRows("B13", <span>/aqd:AQD_Zone/am:name/gn:GeographicalName/gn:language value shall be the language of the name,
 given as a three letters code, in accordance with either <a href="http://dd.eionet.europa.eu/vocabulary/common/iso639-3/view">ISO 639-3</a> or
 <a href="http://dd.eionet.europa.eu/vocabulary/common/iso639-5/view">ISO 639-5</a>.</span>,
            $invalidLangCode, "/aqd:AQD_Zone/am:name/gn:GeographicalName/gn:language", "All values are valid", " invalid value", $langSkippedMsg,"warning")
            }
        {xmlconv:buildResultRows("B18", "./am:name/gn:GeographicalName/gn:spelling/gn:SpellingOfName/gn:text shall return a string",
                $invalidgnSpellingOfName, "aqd:AQD_Zone/@gml:id","All text are valid"," invalid attribute","", "error")}
        {xmlconv:buildResultRows("B20", concat("./am:geometry/gml:Polygon, ./am:geometry/gml:Point,./am:geometry/gml:MultiPoint, ./am:geometry/gml:MultiSurface, ",
            " ./am:geometry/gml:Grid, ./am:geometry/gml:RectifiedGrid the srsName attribute  shall  be  a  recognisable  URN .",
            " The  following  2  srsNames  are  expected urn:ogc:def:crs:EPSG::4258 or urn:ogc:def:crs:EPSG::4326"),
                $invalidGmlIdsB20, "aqd:AQD_Zone/@gml:id","All srsName attributes are valid"," invalid attribute","", "error")}
        {xmlconv:buildResultRows("B21", "./am:geometry/gml:Polygon/gml:exterior/gml:LinearRing/gml:posList the srsDimension attribute shall resolve to ""2"" to allow the x &amp; y-coordinate of the feature of interest",
            $invalidPosListDimension, "aqd:AQD_Zone/@gml:id", "All srsDimension attributes resolve to ""2""", " invalid attribute", "","warning")}
        {xmlconv:buildResultRows("B22", "./am:geometry/gml:Polygon/gml:exterior/gml:LinearRing/gml:posList the count attribute shall resolve to the sum of y and x-coordinate  doublets. ",
               $invalidPosListCount, "gml:Polygon/@gml:id", "All values are valid", " invalid attribute", "","error")}
        {xmlconv:buildResultRows("B23", "Check that the coordinates lists in ./am:geometry/gml:Polygon/gml:exterior/gml:LinearRing/gml:posListar presented in lat/long(y - axis/x - axis)  notation.",
                $invalidLatLong, "gml:Polygon", "All values are valid", " invalid attribute", "","error")}
        {xmlconv:buildResultRows("B24", "./am:zoneType shall resolve to http://inspire.ec.europa.eu/codeList/ZoneTypeCode/airQualityManagementZone",
            $invalidManagementZones, "aqd:AQD_Zone/@gml:id", "All zoneType attributes are valid", " invalid attribute", "","warning")}
        {xmlconv:buildResultRows("B25", "./am:designationPeriod/gml:TimePeriod/gml:beginPosition shall be less than ./am:designationPeri/gml:TimePeriod/gml:endPosition.",
            $invalidPosition, "gml:TimePeriod gml:id", "All positions are valid", " invalid position", "","error")}
        {xmlconv:buildResultRows("B28", "./am:beginLifespanVersion shall be a valid historical date for the start of the version of the zone in extended ISO format. If an am:endLifespanVersion exists its value shall be greater than the am:beginLifespanVersion",
            $invalidLifespanVer, "gml:id", "All LifespanVersion values are valid", " invalid value", "","error")}
        {xmlconv:buildResultRows("B31", "./am:legalBasis/base2:LegislationCitation/base2:name value shall be ""2011/850/EC""",
            $invalidLegalBasisName, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "","warning")}
        {xmlconv:buildResultRows("B32", "./am:legalBasis/base2:LegislationCitation/base2:date value shall be ""2011-12-12""",
            $invalidLegalBasisDate, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "","warning")}
        {xmlconv:buildResultRows("B33", "./am:legalBasis/base2:LegislationCitation/base2:link value shall be ""http://rod.eionet.europa.eu/instruments/650""",
            $invalidLegalBasisLink, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "","warning")}
        <tr>
            <td style="vertical-align:top;">{ xmlconv:getBullet("B35", if ($countB35duplicates = 0) then "info" else "error") }</td>
            <th style="vertical-align:top;">./aqd:zoneCode shall be a unique code for the zone within the ./am:inspireId/base:Identifier/base:namespace.  ./aqd:zoneCode</th>
            <td style="vertical-align:top;">{
                if ($countB35duplicates = 0) then
                    "All Ids are unique"
                else
                    concat($countB35duplicates, " error", substring("s ", number(not($countB35duplicates > 1)) * 2) ,"found") }</td>
        </tr>
        {
            if ($countAmNamespaceAndaqdZoneCodeDuplicates > 0) then
                <tr style="font-size: 0.9em;color:grey;">
                    <td colspan="2" style="text-align:right;vertical-align:top;">Duplicate base:namespace:aqd:zoneCode - </td>
                    <td style="font-style:italic;vertical-align:top;">{ string-join($dublicateAmNamespaceAndaqdZoneCodeIds, ", ")}</td>
                </tr>
            else
                ()
        }


        {xmlconv:buildResultRows("B36", "./aqd:residentPopulation shall be an integer value GREATER THAN 0 (zero)",
            $invalidResidentPopulation, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "", "error")}
        {xmlconv:buildResultRows("B37", "./aqd:residentPopulationYear/gml:TimeInstant/gml:timePosition shall cite the year in which the resident population was estimated in yyyy format",
            $invalidPopulationYear, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "","warning")}
        {xmlconv:buildResultRows("B38", "./aqd:area the value will be a decimal number GREATER THAN 0 (zero)",
            $invalidArea, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "", "error")}
        {xmlconv:buildResultRowsWithTotalCount("B40", <span>./aqd:timeExtensionExemption attribute must resolve to one of concept within http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/
            </span>,(), (), "aqd:timeExtensionExemption", "", "", "", $invalidTimeExtensionExemption)}

        {xmlconv:buildResultTable("B41", "Where ./aqd:timeExtensionExemption resolves  to http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/NO2 1h OR http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/NO2 annual at  least  one  combination  within ./aqd:pollutants which  includes ./aqd:pollutants/aqd:Pollutant/aqd:pollutantCode AND ./aqd:pollutants/aqd:Pollutant/aqd:protectionTarget shall  be  constrained  to Nitro gen  dioxide  Nitrogen  dioxide  (air)  +  health http://dd.eionet.europa.eu/vocabulary/aq/pollutant/8 http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H ",
                (), "All values are valid", " invalid value", "", "error", $invalidPollutansB41)}
        {xmlconv:buildResultTable("B42", "Where ./aqd:timeExtensionExemption resolves to http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/PM10-24h OR http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/PM10-annual at least one combination  within ./aqd:pollutants which  includes ./aqd:pollutants/aqd:Pollutant/aqd:pollutantCode AND ./aqd:pollutants/aqd:Pollutant/aqd:protectionTarget shall  be  constrained  to Particulate  matter  <  10  μm  (aerosol)  +  health http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5 http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H  ",
                (), "All values are valid", " crucial invalid value", "", "error", $aqdInvalidPollutansB42)}
        {xmlconv:buildResultTable("B43", "Where ./aqd:timeExtensionExemption resolves to http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/C6H6-annual at least one combination  within ./aqd:pollutants which  includes ./aqd:pollutants/aqd:Pollutant/aqd:pollutantCode AND ./aqd:pollutants/aqd:Pollutant/aqd:protectionTarget shall  be  constrained  to Benzene  (air)  +  healt http://dd.eionet.europa.eu/vocabulary/aq/pollutant/20 http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H  ",
                (), "All values are valid", " crucial invalid value", "", "error", $aqdInvalidPollutansBenzene)}
        {xmlconv:buildResultRows("B45", "./am:geometry shall  not  be  a  href  xlink. If geometry is provided via shapefile, please use element aqd:shapefileLink",
                $invalidGeometry, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "","warning")}
        {xmlconv:buildResultRows("B46", "Where ./aqd:shapefileLink has been used the is should return a link to a valid and existing link in cdr (e.g. http://cdr.eionet.europa.eu/es/eu/aqd/b/envurng9g/ES_Zones_2014.shp",
                $invalidLink, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "", "error")}
        {xmlconv:buildResultRowsWithTotalCount("B47", <span>./aqd:aqdZoneType attribute must resolve to one of  concept within
            <a href="{ $xmlconv:ZONETYPE_VOCABULARY }">{ $xmlconv:ZONETYPE_VOCABULARY }</a></span>,
            (), (), "aqd:reportingMetric", "", "", "", $invalidZoneType)}



    </table>
}
;


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



declare function xmlconv:buildResultRowsWithTotalCount($ruleCode as xs:string, $text, $invalidStrValues as xs:string*, $invalidValues as element()*,
    $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $recordDetails as element(tr)*)
as element(tr)*{

    let $countCheckedRecords := count($recordDetails)
    let $invalidValues := $recordDetails[./@isvalid = "false"]

    let $skippedMsg := if ($countCheckedRecords = 0) then "No values found to check" else ""
    let $invalidMsg := if (count($invalidValues) > 0) then concat(" invalid value", substring("s ", number(not(count($invalidValues) > 1)) * 2), " found out of ", $countCheckedRecords, " checked") else ""
    let $validMsg := if (count($invalidValues) = 0) then concat("Checked ", $countCheckedRecords, " value", substring("s", number(not($countCheckedRecords > 1)) * 2), ", all valid") else ""

    return
        xmlconv:buildResultRowsHTML($ruleCode, $text, $invalidStrValues, $invalidValues,
            $valueHeading, $validMsg, $invalidMsg, $skippedMsg, ())
};

(:
    Builds HTML table rows for rules.
:)
declare function xmlconv:buildResultRowsHTML($ruleCode as xs:string, $text, $invalidStrValues as xs:string*, $invalidValues as element()*,
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


declare function xmlconv:checkVocabularyConceptValues($source_url as xs:string, $parentObject as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $limitedIds as xs:string*)
as element(tr)*{
    xmlconv:checkVocabularyConceptValues($source_url, $parentObject, $featureType, $element, $vocabularyUrl, $limitedIds, "")
};

declare function xmlconv:checkVocabularyConceptValues($source_url as xs:string, $parentObject, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string)
as element(tr)*{
    xmlconv:checkVocabularyConceptValues($source_url, $parentObject, $featureType, $element, $vocabularyUrl, (), "")
};
declare function xmlconv:checkVocabularyConceptValues($source_url as xs:string, $parentObject as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $limitedIds as xs:string*, $vocabularyType as xs:string)
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
            <td title="gml:id">{data($rec/@gml:id)}</td>
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

declare function xmlconv:isInvalidYear($value as xs:string?) {
    let $year := if (empty($value)) then ()
    else
        if ($value castable as xs:integer) then xs:integer($value) else ()

    return
        if ((empty($year) and empty($value)) or (not(empty($year)) and $year > 1800 and $year < 9999)) then fn:false() else fn:true()

};
(:
 : ======================================================================
 : Main function
 : ======================================================================
 :)

declare function xmlconv:proceed($source_url as xs:string, $countryCode as xs:string) {

let $countZones := count(doc($source_url)//aqd:AQD_Zone)
let $result := if ($countZones > 0) then xmlconv:checkReport($source_url, $countryCode) else ()

return
    <div>
    {xmlconv:javaScript()}
        <h2>Check air quality zones - Dataflow B</h2>
        {
        if ( $countZones = 0) then
            <p>No aqd:Zone elements found from this XML.</p>
        else
            <div>
                {
                    if ($result//div/@class = 'error') then
                        <p class="crucialError" style="color:red"><strong>This XML file did NOT pass the following crucial check(s): {string-join($result//div[@class='error'], ',')}</strong></p>
                    else
                        <p>This XML file passed all crucial checks which in this case are: B1,B2,B3,B4,B9,B18,B20,B22,B25,B28,B35,B36,B38,B40,B41,B42,B43,B46</p>
                }
                <p>This check evaluated the delivery by executing tier-1 tests on air quality zones data in Dataflow B as specified in <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a>.</p>
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

declare function xmlconv:aproceed($source_url as xs:string, $country as xs:string) {


let $docRoot := doc($source_url)

let $aqdShapeFileLink := $docRoot//aqd:AQD_Zone/aqd:shapefileLink

let $invalidLink :=
for $link in $aqdShapeFileLink
    let $envLink := xmlconv:getEnvelopeXML($link)
    let $envExists := doc-available($envLink)
    return
    if (not($envExists)  or ($envExists and count(doc($envLink)/envelope/file[@link=$link]) = 0)) then
        concat($link/../@gml:id, ' ', $link)
    else ()


return $invalidLink
};

(:
xmlconv:proceed( $source_url, $country )
:)
