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
declare variable $source_url := "../test/D_GB_Zones.xml";
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
let $countZones := count($docRoot//gml:featureMember/aqd:AQD_Zone)
(: B3 :)
let $countZonesWithAmGeometry := count($docRoot//gml:featureMember/aqd:AQD_Zone/am:geometry)
(: B4 :)
let $countZonesWithLAU := count($docRoot//gml:featureMember/aqd:AQD_Zone/aqd:LAU)

(: B8 :)
let $gmlIds := $docRoot//gml:featureMember/aqd:AQD_Zone/lower-case(normalize-space(@gml:id))
let $duplicateGmlIds := distinct-values(
    for $id in $docRoot//gml:featureMember/aqd:AQD_Zone/@gml:id
    where string-length(normalize-space($id)) > 0 and count(index-of($gmlIds, lower-case(normalize-space($id)))) > 1
    return
        $id
    )
let $efInspireIds := for $id in $docRoot//gml:featureMember/aqd:AQD_Zone/ef:inspireId
                     return
                        lower-case(concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
                            ", ", normalize-space($id/base:Identifier/base:versionId), "]"))
let $duplicateefInspireIds := distinct-values(
    for $id in $docRoot//gml:featureMember/aqd:AQD_Zone/ef:inspireId
    let $key :=
        concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
            ", ", normalize-space($id/base:Identifier/base:versionId), "]")
    where string-length(normalize-space($id/base:Identifier/base:localId)) > 0 and count(index-of($efInspireIds, lower-case($key))) > 1
    return
        $key
    )

let $aqdInspireIds := for $id in $docRoot//gml:featureMember/aqd:AQD_Zone/aqd:inspireId
                     return
                        lower-case(concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
                            ", ", normalize-space($id/base:Identifier/base:versionId), "]"))
let $duplicateaqdInspireIds := distinct-values(
    for $id in $docRoot//gml:featureMember/aqd:AQD_Zone/aqd:inspireId
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
let $countB8duplicates := $countGmlIdDuplicates + $countefInspireIdDuplicates + $countaqdInspireIdDuplicates

(: B9 :)
let $amInspireIds := $docRoot//gml:featureMember/aqd:AQD_Zone/am:inspireId/base:Identifier/lower-case(normalize-space(base:localId))
let $duplicateAmInspireIds := distinct-values(
    for $id in $docRoot//gml:featureMember/aqd:AQD_Zone/am:inspireId/base:Identifier/base:localId
    where string-length(normalize-space($id)) > 0 and count(index-of($amInspireIds, lower-case(normalize-space($id)))) > 1
    return
        $id
    )
let $invalidIsoAmInspireIds := distinct-values(
    for $id in $docRoot//gml:featureMember/aqd:AQD_Zone/am:inspireId/base:Identifier/base:localId
    where string-length(normalize-space($id)) > 0 and (string-length(normalize-space($id)) < 2 or
        count(index-of($xmlconv:ISO2_CODES , substring(upper-case(normalize-space($id)), 1, 2))) = 0)
    return
        $id
    )

let $countAmInspireIdDuplicates := count($duplicateAmInspireIds)
let $countAmInspireIdInvalidIso := count($invalidIsoAmInspireIds)
let $countB9duplicates := $countAmInspireIdDuplicates + $countAmInspireIdInvalidIso

(: B14 :)
let $unknownNativeness := distinct-values($docRoot//gml:featureMember/aqd:AQD_Zone[count(am:name/gn:GeographicalName/gn:nativeness[@xsi:nil="true" and @nilReason="unknown"])>0]/@gml:id)
(: B15 :)
let $unknownNameStatus := distinct-values($docRoot//gml:featureMember/aqd:AQD_Zone[count(am:name/gn:GeographicalName/gn:nameStatus[@xsi:nil="true" and @nilReason="unknown"])>0]/@gml:id)
(: B16 :)
let $unknownSourceOfName := distinct-values($docRoot//gml:featureMember/aqd:AQD_Zone[count(am:name/gn:GeographicalName/gn:sourceOfName[@xsi:nil="true" and @nilReason="unknown"])>0]/@gml:id)
(: B17 :)
let $unknownPronunciation  := distinct-values($docRoot//gml:featureMember/aqd:AQD_Zone[count(am:name/gn:GeographicalName/gn:pronunciation[@xsi:nil="true" and @nilReason="unknown"])>0]/@gml:id)

(: B21 :)
let $invalidPosListDimension  := distinct-values($docRoot//gml:featureMember/aqd:AQD_Zone/am:geometry/gml:Polygon/gml:exterior/gml:LinearRing/gml:posList[@srsDimension != "2"]/
            concat(../../../../../@gml:id, ": srsDimension=", @srsDimension))

(: B30 :)
let $invalidLegalBasisName  := distinct-values($docRoot//gml:featureMember/aqd:AQD_Zone/am:legalBasis/base2:LegislationCitation[normalize-space(base2:name) != "2011/850/EC"]/
            concat(../../@gml:id, ": base2:name=", if (string-length(base2:name) > 20) then concat(substring(base2:name, 1, 20), "...") else base2:name))
(: B31 :)
let $invalidLegalBasisDate  := distinct-values($docRoot//gml:featureMember/aqd:AQD_Zone/am:legalBasis/base2:LegislationCitation[normalize-space(base2:date) != "2011-12-12"]/
            concat(../../@gml:id, ": base2:date=", if (string-length(base2:date) > 20) then concat(substring(base2:date, 1, 20), "...") else base2:date))
(: B32 :)
let $invalidLegalBasisLink  := distinct-values($docRoot//gml:featureMember/aqd:AQD_Zone/am:legalBasis/base2:LegislationCitation[normalize-space(base2:link) != "http://rod.eionet.europa.eu/instruments/650"]/
            concat(../../@gml:id, ": base2:link=", if (string-length(base2:link) > 40) then concat(substring(base2:link, 1, 40), "...") else base2:link))

(: B35 :)
let $invalidResidentPopulation  := distinct-values($docRoot//gml:featureMember/aqd:AQD_Zone[not(count(aqd:residentPopulation)>0 and aqd:residentPopulation castable as xs:integer and number(aqd:residentPopulation) > 0)]/
            concat(@gml:id, ": aqd:residentPopulation=", if (string-length(aqd:residentPopulation) = 0) then "missing" else aqd:residentPopulation))
(: B37 :)
let $invalidArea  := distinct-values($docRoot//gml:featureMember/aqd:AQD_Zone[not(count(aqd:area)>0 and number(aqd:area) and number(aqd:area) > 0)]/
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
        distinct-values($docRoot//gml:featureMember/aqd:AQD_Zone/aqd:LAU[string-length(normalize-space(@xlink:href)) > 0 and
            empty(index-of($lau2Codes, normalize-space(@xlink:href))) and empty(index-of($nutsCodes, normalize-space(@xlink:href)))]/@xlink:href)
    else
        ()
let $lauSkippedMsg := if (fn:string-length($countryCode) != 2) then "The test was skipped - reporting country code not found."
    else if (not($isLau2CodesAvailable)) then "The test was skipped - LAU2 concepts are not available in CR."
    else if (not($isNutsAvailable)) then "The test was skipped - NUTS concepts are not available in CR."
    else ""


return
    <table style="text-align:left;vertical-align:top;">
        <tr>
            <td style="vertical-align:top;">{ xmlconv:getBullet("B1", "info") }</td>
            <th style="vertical-align:top;">Total number of AQ zones</th>
            <td style="vertical-align:top;">{ $countZones }</td>
        </tr>
        <tr>
            <td style="vertical-align:top;">{ xmlconv:getBullet("B3", "info") }</td>
            <th style="vertical-align:top;">The number of zones designated with coordinates via the ./am:geometry element</th>
            <td style="vertical-align:top;">{ $countZonesWithAmGeometry }</td>
        </tr>
        <tr>
            <td style="vertical-align:top;">{ xmlconv:getBullet("B4", "info") }</td>
            <th style="vertical-align:top;">The number of zones designated with coordinates via the ./aqd:LAU element</th>
            <td style="vertical-align:top;">{ $countZonesWithLAU }</td>
        </tr>
        <tr>
            <td style="vertical-align:top;">{ xmlconv:getBullet("B8", if ($countB8duplicates = 0) then "info" else "error") }</td>
            <th style="vertical-align:top;">All gml:id attributes, ef:inspireId and aqd:inspireId elements shall have unique content</th>
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
        <tr>
            <td style="vertical-align:top;">{ xmlconv:getBullet("B9", if ($countB9duplicates = 0) then "info" else "error") }</td>
            <th style="vertical-align:top;">./am:inspireId/base:Identifier/base:localId shall be an unique code for network starting with ISO2-country code</th>
            <td style="vertical-align:top;">{
                if ($countB9duplicates = 0) then
                    "All Ids are unique"
                else
                    concat($countB9duplicates, " error", substring("s ", number(not($countB9duplicates > 1)) * 2) ,"found") }</td>
        </tr>
        {
            if ($countAmInspireIdDuplicates > 0) then
                <tr style="font-size: 0.9em;color:grey;">
                    <td colspan="2" style="text-align:right;vertical-align:top;">Duplicate base:localId - </td>
                    <td style="font-style:italic;vertical-align:top;">{ string-join($duplicateAmInspireIds, ", ")}</td>
                </tr>
            else
                ()
        }
        {
            if ($countAmInspireIdInvalidIso > 0) then
                <tr style="font-size: 0.9em;color:grey;">
                    <td colspan="2" style="text-align:right;vertical-align:top;">Wrong ISO2 in base:localId - </td>
                    <td style="font-style:italic;vertical-align:top;">{ string-join($invalidIsoAmInspireIds, ", ")}</td>
                </tr>
            else
                ()
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
        {xmlconv:buildResultRows("B30", "./am:legalBasis/base2:LegislationCitation/base2:name value shall be ""2011/850/EC""",
            $invalidLegalBasisName, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "")}
        {xmlconv:buildResultRows("B31", "./am:legalBasis/base2:LegislationCitation/base2:date value shall be ""2011-12-12""",
            $invalidLegalBasisDate, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "")}
        {xmlconv:buildResultRows("B32", "./am:legalBasis/base2:LegislationCitation/base2:link value shall be ""http://rod.eionet.europa.eu/instruments/650""",
            $invalidLegalBasisLink, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "")}
        {xmlconv:buildResultRows("B35", "./aqd:residentPopulation shall be an integer value GREATER THAN 0 (zero)",
            $invalidResidentPopulation, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "")}
        {xmlconv:buildResultRows("B37", "./aqd:area the value will be a decimal number GREATER THAN 0 (zero)",
            $invalidArea, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "")}

        {xmlconv:buildResultRows("B42", <span>Where ./aqd:LAU has been used
            then the reference must point to a concept in the list of <a href="http://dd.eionet.europa.eu/vocabulary/lau2/{$countryCode}/view">LAU2</a> or
             <a href="http://dd.eionet.europa.eu/vocabulary/common/nuts/view">NUTS</a></span>,
            $invalidLau, "aqd:AQD_Zone/aqd:LAU/@xlink:href", "All values are valid", " invalid value", $lauSkippedMsg)
            }
    </table>
}
;


(:
 : ======================================================================
 : Main function
 : ======================================================================
 :)
declare function xmlconv:proceed($source_url as xs:string) {

let $countZones := count(doc($source_url)//gml:featureMember/aqd:AQD_Zone)
let $result := if ($countZones > 0) then xmlconv:checkReport($source_url) else ()

return
<div class="feedbacktext">
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
xmlconv:proceed( $source_url )

