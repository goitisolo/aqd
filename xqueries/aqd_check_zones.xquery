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
declare namespace ef="http://inspire.ec.europa.eu/schemas/ef/3.0rc3";
declare namespace base="http://inspire.ec.europa.eu/schemas/base/3.3rc3/";
(:===================================================================:)
(: Variable given as an external parameter by the QA service                                                 :)
(:===================================================================:)

declare variable $source_url := "../test/D_GB_Zones.xml";

(:
declare variable $source_url as xs:untypedAtomic external;
Change it for testing locally:
declare variable $source_url as xs:string external;
declare variable $source_url := "http://cdr.eionet.europa.eu/gb/eu/aqd/e2a/colutn32a/envubnpvw/B_GB_Zones.xml";
:)

declare function xmlconv:getBullet($text as xs:string, $level as xs:string)
as element(div) {

    let $color :=
        if ($level = "error") then
            "red"
        else if ($level = "warning") then
            "orange"
        else
            "deepskyblue"
return
    <div style="background-color: { $color }; font-size: 0.8em; color: white; padding-left:5px;padding-right:5px;margin-right:5px;text-align:center">{ $text }</div>
};

declare function xmlconv:checkReport($source_url as xs:string)
as element(table) {

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
    where count(index-of($gmlIds, lower-case(normalize-space($id)))) > 1
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
    where count(index-of($efInspireIds, lower-case($key))) > 1
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
    where count(index-of($aqdInspireIds, lower-case($key))) > 1
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
    where count(index-of($amInspireIds, lower-case(normalize-space($id)))) > 1
    return
        $id
    )

let $countAmInspireIdDuplicates := count($duplicateAmInspireIds)
let $countB9duplicates := $countAmInspireIdDuplicates


return
    <table style="text-align:left">
        <tr>
            <td>{ xmlconv:getBullet("B1", "info") }</td>
            <th>Total number of AQ zones</th>
            <td>{ $countZones }</td>
        </tr>
        <tr>
            <td>{ xmlconv:getBullet("B3", "info") }</td>
            <th>The number of zones designated with coordinates via the ./am:geometry element</th>
            <td>{ $countZonesWithAmGeometry }</td>
        </tr>
        <tr>
            <td>{ xmlconv:getBullet("B4", "info") }</td>
            <th>The number of zones designated with coordinates via the ./aqd:LAU element</th>
            <td>{ $countZonesWithLAU }</td>
        </tr>
        <tr>
            <td>{ xmlconv:getBullet("B8", if ($countB8duplicates = 0) then "info" else "error") }</td>
            <th>All gml:id attributes, ef:inspireId and aqd:inspireId elements shall have unique content</th>
            <td>{
                if ($countB8duplicates = 0) then
                    "All Ids are unique"
                else
                    concat($countB8duplicates, " duplicate", substring("s ", number(not($countB8duplicates > 1)) * 2) ,"found") }</td>
        </tr>
        {
            if ($countGmlIdDuplicates > 0) then
                <tr style="font-size: 0.9em;color:grey;">
                    <td colspan="2" style="text-align:right;">gml:id - </td>
                    <td style="font-style:italic">{ string-join($duplicateGmlIds, ", ")}</td>
                </tr>
            else
                ()
        }
        {
            if ($countefInspireIdDuplicates > 0) then
                <tr style="font-size: 0.9em;color:grey;">
                    <td colspan="2" style="text-align:right;">ef:inspireId - </td>
                    <td style="font-style:italic">{ string-join($duplicateefInspireIds, ", ")}</td>
                </tr>
            else
                ()
        }
        {
            if ($countaqdInspireIdDuplicates > 0) then
                <tr style="font-size: 0.9em;color:grey;">
                    <td colspan="2" style="text-align:right;">aqd:inspireId - </td>
                    <td style="font-style:italic">{ string-join($duplicateaqdInspireIds, ", ")}</td>
                </tr>
            else
                ()
        }
        <tr>
            <td>{ xmlconv:getBullet("B9", if ($countB9duplicates = 0) then "info" else "error") }</td>
            <th>./am:inspireId/base:Identifier/base:localId shall be an unique code for network starting with ISO2-country code</th>
            <td>{
                if ($countB9duplicates = 0) then
                    "All Ids are unique"
                else
                    concat($countB9duplicates, " error", substring("s ", number(not($countB9duplicates > 1)) * 2) ,"found") }</td>
        </tr>
        {
            if ($countAmInspireIdDuplicates > 0) then
                <tr style="font-size: 0.9em;color:grey;">
                    <td colspan="2" style="text-align:right;">Duplicate base:localId - </td>
                    <td style="font-style:italic">{ string-join($duplicateAmInspireIds, ", ")}</td>
                </tr>
            else
                ()
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

