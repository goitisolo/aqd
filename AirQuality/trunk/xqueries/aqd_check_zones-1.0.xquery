xquery version "1.0" encoding "UTF-8";
(:
 : Module Name: Implementing Decision 2011/850/EU: AQ info exchange & reporting (Main module)
 :
 : Version:     $Id$
 : Created:     20 June 2013
 : Copyright:   European Environment Agency
 :)
(:~
 : XQuery script implements dataflow B tier-1 checks as documented in http://taskman.eionet.europa.eu/documents/3 .
 :
 : @author Enriko Käsper
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

declare variable $xmlconv:AQ_MANAGEMENET_ZONE := "http://inspire.ec.europa.eu/codeList/ZoneTypeCode/airQualityManagementZone";
declare variable $xmlconv:ZONETYPE_VOCABULARY as xs:string := "http://dd.eionet.europa.eu/vocabulary/aq/zonetype/";

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
declare variable $source_url := "../test/B.2013_3_.xml";
declare variable $source_url as xs:string external;
declare variable $source_url := "../test/D_GB_Zones.xml";
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
            "brown"
        else
            "deepskyblue"
return
    <div style="background-color: { $color }; font-size: 0.8em; color: white; padding-left:5px;padding-right:5px;margin-right:5px;margin-top:2px;text-align:center">{ $text }</div>
};

(:
    Builds HTML table rows for rules B13 - B17.
:)
declare function xmlconv:buildResultRows($ruleCode as xs:string, $text, $invalidValues as xs:string*,
    $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg)
as element(tr)*{
    let $countInvalidValues := count($invalidValues)
    let $bulletType := if (string-length($skippedMsg) > 0) then "skipped" else if ($countInvalidValues = 0) then "info" else "error"
let $result :=
    (
        <tr>
            <td style="vertical-align:top;">{ xmlconv:getBullet($ruleCode, $bulletType) }</td>
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


(:
    Rule implementations
:)
declare function xmlconv:checkReport($source_url as xs:string)
as element(table) {

(: get reporting country :)
let $envelopeUrl := xmlconv:getEnvelopeXML($source_url)
let $countryCode := if(string-length($envelopeUrl)>0) then lower-case(fn:doc($envelopeUrl)/envelope/countrycode) else ""

(: FIXME
let $countryCode := "gb"
:)
let $countryCode := if ($countryCode = "gb") then "uk" else if ($countryCode = "gr") then "el" else $countryCode

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


(: B11 :)
let $emptyNames := distinct-values($docRoot//aqd:AQD_Zone[normalize-space(am:name)=""]/@gml:id)

(: B13 :)
let $langCodeSparql := xmlconv:getLangCodesSparql()
let $isLangCodesAvailable := string-length($langCodeSparql) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($langCodeSparql, "xml"))
let $langCodes := if ($isLangCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($langCodeSparql)//sparql:binding[@name='code']/sparql:literal)) else ()
let $isLangCodesAvailable := count($langCodes) > 0

let $invalidLangCode := if ($isLangCodesAvailable) then
        distinct-values($docRoot//aqd:AQD_Zone/am:name/gn:GeographicalName[string-length(normalize-space(gn:language)) > 0 and
            empty(index-of($langCodes, normalize-space(gn:language))) and empty(index-of($langCodes, normalize-space(gn:language)))]/gn:language)
    else
        ()

let $langSkippedMsg :=
    if (not($isLangCodesAvailable)) then "The test was skipped - ISO 639-3 and ISO 639-5 language codes are not available in Content Registry."
    else ""

(: B14 :)
let $unknownNativeness := distinct-values($docRoot//aqd:AQD_Zone[count(am:name/gn:GeographicalName/gn:nativeness[@xsi:nil="true" and @nilReason="unknown"])>0]/@gml:id)
(: B15 :)
let $unknownNameStatus := distinct-values($docRoot//aqd:AQD_Zone[count(am:name/gn:GeographicalName/gn:nameStatus[@xsi:nil="true" and @nilReason="unknown"])>0]/@gml:id)
(: B16 :)
let $unknownSourceOfName := distinct-values($docRoot//aqd:AQD_Zone[count(am:name/gn:GeographicalName/gn:sourceOfName[@xsi:nil="true" and @nilReason="unknown"])>0]/@gml:id)
(: B17 :)
let $unknownPronunciation  := distinct-values($docRoot//aqd:AQD_Zone[count(am:name/gn:GeographicalName/gn:pronunciation[@xsi:nil="true" and @nilReason="unknown"])>0]/@gml:id)

(: B21 :)
let $invalidPosListDimension  := distinct-values($docRoot//aqd:AQD_Zone/am:geometry/gml:Polygon/gml:exterior/gml:LinearRing/gml:posList[@srsDimension != "2"]/
            concat(../../../../../@gml:id, ": srsDimension=", @srsDimension))

(: B23 :)
(: ./am:zoneType value shall resolve to http://inspire.ec.europa.eu/codeList/ZoneTypeCode/airQualityManagementZone :)
let $invalidManagementZones  := distinct-values($docRoot//aqd:AQD_Zone/am:zoneType[@xlink:href != $xmlconv:AQ_MANAGEMENET_ZONE]/
            concat(../@gml:id, ": zoneType=", @xlink:href))

(: B24 :)
(: ./am:designationPeriod/gml:TimePeriod/gml:beginPosition shall be less than ./am:designationPeri/gml:TimePeriod/gml:endPosition. :)
let $invalidPosition  :=
    for $timePeriod in $docRoot//aqd:AQD_Zone/am:designationPeriod/gml:TimePeriod
        let $beginPosition := if (normalize-space($timePeriod/gml:beginPosition) castable as xs:date) then xs:date($timePeriod/gml:beginPosition) else ()
        let $endPosition := if (normalize-space($timePeriod/gml:endPosition)  castable as xs:date) then xs:date($timePeriod/gml:endPosition) else ()
        return
        if (not(empty($beginPosition)) and not(empty($endPosition)) and $beginPosition > $endPosition) then
            concat($timePeriod/../../@gml:id, ": gml:beginPosition=", $beginPosition, ": gml:endPosition=", $endPosition)
        else
            ()

(: B27 :)
(: ./am:beginLifespanVersion shall be a valid historical date for the start of the version of the zone in extended ISO format.
If an am:endLifespanVersion exists its value shall be greater than the am:beginLifespanVersion :)
let $invalidLifespanVer  :=
    for $rec in $docRoot//aqd:AQD_Zone
        let $beginPeriod := if (normalize-space($rec/am:beginLifespanVersion) castable as xs:dateTime) then xs:dateTime($rec/am:beginLifespanVersion) else ()
        let $endPeriod := if (normalize-space($rec/am:endLifespanVersion)  castable as xs:dateTime) then xs:dateTime($rec/am:endLifespanVersion) else ()
        return
        if ((not(empty($beginPeriod)) and not(empty($endPeriod)) and $beginPeriod > $endPeriod) or empty($beginPeriod)) then
            concat($rec/@gml:id, ": am:beginLifespanVersion=", data($rec/am:beginLifespanVersion),
            if (not(empty($endPeriod))) then concat(": am:endLifespanVersion=", data($rec/am:endLifespanVersion)) else "")
        else
            ()
(: B28 :)
(: ./am:beginLifespanVersion shall be LESS THAN OR EQUAL TO ./am:designationPeriod/gml:TimePeriod/gml:endPosition
./am:beginLifespanVersion shall be GREATER THAN OR EQUAL TO
./am:designationPeriod/gml:TimePeriod/gml:beginPosition
:)
let $invalidLifespanVerB28  :=
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


(: B30 :)
let $invalidLegalBasisName  := distinct-values($docRoot//aqd:AQD_Zone/am:legalBasis/base2:LegislationCitation[normalize-space(base2:name) != "2011/850/EC"]/
            concat(../../@gml:id, ": base2:name=", if (string-length(base2:name) > 20) then concat(substring(base2:name, 1, 20), "...") else base2:name))
(: B31 :)
let $invalidLegalBasisDate  := distinct-values($docRoot//aqd:AQD_Zone/am:legalBasis/base2:LegislationCitation[normalize-space(base2:date) != "2011-12-12"]/
            concat(../../@gml:id, ": base2:date=", if (string-length(base2:date) > 20) then concat(substring(base2:date, 1, 20), "...") else base2:date))
(: B32 :)
let $invalidLegalBasisLink  := distinct-values($docRoot//aqd:AQD_Zone/am:legalBasis/base2:LegislationCitation[normalize-space(base2:link) != "http://rod.eionet.europa.eu/instruments/650"]/
            concat(../../@gml:id, ": base2:link=", if (string-length(base2:link) > 40) then concat(substring(base2:link, 1, 40), "...") else base2:link))

(: B35 :)
let $invalidResidentPopulation  := distinct-values($docRoot//aqd:AQD_Zone[not(count(aqd:residentPopulation)>0 and aqd:residentPopulation castable as xs:integer and number(aqd:residentPopulation) > 0)]/
            concat(@gml:id, ": aqd:residentPopulation=", if (string-length(aqd:residentPopulation) = 0) then "missing" else aqd:residentPopulation))

(: B36 :)
(: ./aqd:residentPopulationYear/gml:TimeInstant/gml:timePosition shall cite the year in which the resident population was estimated in yyyy format :)
let $invalidPopulationYear :=
for $zone in $docRoot//aqd:AQD_Zone
return
    if (xmlconv:isInvalidYear(data($zone/aqd:residentPopulationYear/gml:TimeInstant/gml:timePosition))) then
        concat($zone/@gml:id, ": gml:timePosition=",data($zone/aqd:residentPopulationYear/gml:TimeInstant/gml:timePosition))
    else ()

(: B37 :)
let $invalidArea  := distinct-values($docRoot//aqd:AQD_Zone[not(count(aqd:area)>0 and number(aqd:area) and number(aqd:area) > 0)]/
            concat(@gml:id, ": aqd:area=", if (string-length(aqd:area) = 0) then "missing" else aqd:area))
(: B42 :)
let $lau2Sparql := if (fn:string-length($countryCode) = 2) then xmlconv:getLau2Sparql($countryCode) else ""
let $isLau2CodesAvailable := string-length($lau2Sparql) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($lau2Sparql, "xml"))
let $lau2Codes := if ($isLau2CodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($lau2Sparql)//sparql:binding[@name='concepturl']/sparql:uri)) else ()
let $isLau2CodesAvailable := count($lau2Codes) > 0

let $nutsSparql := if (fn:string-length($countryCode) = 2) then xmlconv:getNutsSparql($countryCode) else ""
let $isNutsCodesAvailable := doc-available(xmlconv:getSparqlEndpointUrl($nutsSparql, "xml"))
let $nutsCodes := if ($isNutsCodesAvailable) then  distinct-values(data(xmlconv:executeSparqlQuery($nutsSparql)//sparql:binding[@name='concepturl']/sparql:uri)) else ()
let $isNutsAvailable := count($nutsSparql) > 0

let $invalidLau := if ($isLau2CodesAvailable and $isNutsAvailable) then
        distinct-values($docRoot//aqd:AQD_Zone/aqd:LAU[string-length(normalize-space(@xlink:href)) > 0 and
            empty(index-of($lau2Codes, normalize-space(@xlink:href))) and empty(index-of($nutsCodes, normalize-space(@xlink:href)))]/@xlink:href)
    else
        ()
let $lauSkippedMsg := if (fn:string-length($countryCode) != 2) then "The test was skipped - reporting country code not found."
    else if (not($isLau2CodesAvailable)) then "The test was skipped - LAU2 concepts are not available in CR."
    else if (not($isNutsAvailable)) then "The test was skipped - NUTS concepts are not available in CR."
    else ""

(: B47 :)
let $invalidZoneType :=
    xmlconv:checkVocabularyConceptValues("", "aqd:AQD_Zone", "aqd:aqdZoneType", $xmlconv:ZONETYPE_VOCABULARY)


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


        {xmlconv:buildResultRowsHTML("B7", "Total number  aqd:aqdZoneType, aqd:pollutantCode, aqd:protectionTarget combinations ",
            (), (), "", string(count($tblB7)), "", "", $tblB7)}


        <tr>
            <td style="vertical-align:top;">{ xmlconv:getBullet("B8", if ($countB8duplicates = 0) then "info" else "error") }</td>
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

        {xmlconv:buildResultRows("B11", "./am:name xsl:nil=""false""",
            $emptyNames, "aqd:AQD_Zone/@gml:id", "No empty values found", " empty name", "")}

        {xmlconv:buildResultRows("B13", <span>/aqd:AQD_Zone/am:name/gn:GeographicalName/gn:language value shall be the language of the name,
 given as a three letters code, in accordance with either <a href="http://dd.eionet.europa.eu/vocabulary/common/iso639-3/view">ISO 639-3</a> or
 <a href="http://dd.eionet.europa.eu/vocabulary/common/iso639-5/view">ISO 639-5</a>.</span>,
            $invalidLangCode, "/aqd:AQD_Zone/am:name/gn:GeographicalName/gn:language", "All values are valid", " invalid value", $langSkippedMsg)
            }
        {xmlconv:buildResultRows("B14", "./am:name/gn:GeographicalName/gn:nativeness attribute xsi:nil=""true"" nilReason=""unknown""",
            $unknownNativeness, "aqd:AQD_Zone/@gml:id", "No unknown values found", " unknwon reason", "")}
        {xmlconv:buildResultRows("B15", "./am:name/gn:GeographicalName/gn:nameStatus  attribute xsi:nil=""true"" nilReason=""unknown""",
            $unknownNameStatus, "aqd:AQD_Zone/@gml:id", "No unknown values found", " unknwon reason", "")}
        {xmlconv:buildResultRows("B16", "./am:name/gn:GeographicalName/gn:sourceOfName  attribute xsi:nil=""true"" nilReason=""unknown""",
            $unknownSourceOfName, "aqd:AQD_Zone/@gml:id", "No unknown values found", " unknwon reason", "")}
        {xmlconv:buildResultRows("B17", "./am:name/gn:GeographicalName/gn:pronunciation  attribute xsi:nil=""true"" nilReason=""unknown""",
            $unknownPronunciation, "aqd:AQD_Zone/@gml:id", "No unknown values found", " unknwon reason", "")}
        {xmlconv:buildResultRows("B21", "./am:geometry/gml:Polygon/gml:exterior/gml:LinearRing/gml:posList the srsDimension attribute shall resolve to ""2"" to allow the x &amp; y-coordinate of the feature of interest",
            $invalidPosListDimension, "aqd:AQD_Zone/@gml:id", "All srsDimension attributes resolve to ""2""", " invalid attribute", "")}
        {xmlconv:buildResultRows("B23", "./am:zoneType shall resolve to http://inspire.ec.europa.eu/codeList/ZoneTypeCode/airQualityManagementZone",
            $invalidManagementZones, "aqd:AQD_Zone/@gml:id", "All zoneType attributes are valid", " invalid attribute", "")}
        {xmlconv:buildResultRows("B24", "./am:designationPeriod/gml:TimePeriod/gml:beginPosition shall be less than ./am:designationPeri/gml:TimePeriod/gml:endPosition.",
            $invalidPosition, "gml:TimePeriod gml:id", "All positions are valid", " invalid position", "")}
        {xmlconv:buildResultRows("B27", "./am:beginLifespanVersion shall be a valid historical date for the start of the version of the zone in extended ISO format. If an am:endLifespanVersion exists its value shall be greater than the am:beginLifespanVersion",
            $invalidLifespanVer, "gml:id", "All LifespanVersion values are valid", " invalid value", "")}
        {xmlconv:buildResultRows("B28", "./am:beginLifespanVersion shall be less than or equal to ./am:designationPeriod/gml:TimePeriod/gml:endPosition  ./am:beginLifespanVersion shall be greater than or equal to ./am:designationPeriod/gml:TimePeriod/gml:beginPosition ",
            $invalidLifespanVerB28, "gml:id", "All values are valid ", " invalid value", "")}
        {xmlconv:buildResultRows("B30", "./am:legalBasis/base2:LegislationCitation/base2:name value shall be ""2011/850/EC""",
            $invalidLegalBasisName, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "")}
        {xmlconv:buildResultRows("B31", "./am:legalBasis/base2:LegislationCitation/base2:date value shall be ""2011-12-12""",
            $invalidLegalBasisDate, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "")}
        {xmlconv:buildResultRows("B32", "./am:legalBasis/base2:LegislationCitation/base2:link value shall be ""http://rod.eionet.europa.eu/instruments/650""",
            $invalidLegalBasisLink, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "")}
        {xmlconv:buildResultRows("B35", "./aqd:residentPopulation shall be an integer value GREATER THAN 0 (zero)",
            $invalidResidentPopulation, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "")}
        {xmlconv:buildResultRows("B36", "./aqd:residentPopulationYear/gml:TimeInstant/gml:timePosition shall cite the year in which the resident population was estimated in yyyy format",
            $invalidPopulationYear, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "")}
        {xmlconv:buildResultRows("B37", "./aqd:area the value will be a decimal number GREATER THAN 0 (zero)",
            $invalidArea, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "")}
        {xmlconv:buildResultRows("B42", <span>Where ./aqd:LAU has been used
            then the reference must point to a concept in the list of <a href="http://dd.eionet.europa.eu/vocabulary/lau2/{$countryCode}/view">LAU2</a> or
             <a href="http://dd.eionet.europa.eu/vocabulary/common/nuts/view">NUTS</a></span>,
            $invalidLau, "aqd:AQD_Zone/aqd:LAU/@xlink:href", "All values are valid", " invalid value", $lauSkippedMsg)}

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
declare function xmlconv:proceed($source_url as xs:string) {

let $countZones := count(doc($source_url)//aqd:AQD_Zone)
let $result := if ($countZones > 0) then xmlconv:checkReport($source_url) else ()

return
<div class="feedbacktext">
    { xmlconv:javaScript() }
    <div>
        <h2>Check air quality zones - Dataflow B</h2>
        {
        if ( $countZones = 0) then
            <p>No aqd:Zone elements found from this XML.</p>
        else
            $result
        }
    </div>
</div>

};

declare function xmlconv:aproceed($s as xs:string) {
let $docRoot := doc("../test/B.2013_3_.xml")

let $nameSpaces := distinct-values(data($docRoot//base:namespace))
let $zonesSparql := xmlconv:getZonesSparql($nameSpaces)
let $isZonesAvailable := string-length($zonesSparql) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($zonesSparql, "xml"))
let $knownZones := if ($isZonesAvailable ) then distinct-values(data(xmlconv:executeSparqlQuery($zonesSparql)//sparql:binding[@name='inspireid']/sparql:literal)) else ()


let $unknownZones :=
for $zone in $docRoot//aqd:AQD_Zone
    let $id := if (empty($zone/@gml:id)) then "" else data($zone/@gml:id)
    where empty(index-of($knownZones, $id))
return $zone

let $dv := distinct-values($unknownZones/@gml:id)

let $tblB2 :=
    for $rec in $unknownZones
    return
        <tr>
            <td title="gml:id">{data($rec/@gml:id)}</td>
            <td title="aqd:predecessor">{data($rec/aqd:predecessor/aqd:AQD_Zone/@gml:id)}</td>
        </tr>



return $tblB2

};

xmlconv:proceed( $source_url )

