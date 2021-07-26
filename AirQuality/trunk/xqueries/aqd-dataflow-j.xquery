xquery version "3.0" encoding "UTF-8";
(:
 : Module Name: Implementing Decision 2011/850/EU: AQ info exchange & reporting (Library module)
 :
 : Version:     $Id$
 : Created:     9 November 2017
 : Copyright:   European Environment Agency
 :
 : XQuery script implements dataflow j checks.
 :
 : @author Claudia Ifrim
 :)

module namespace dataflowJ = "http://converters.eionet.europa.eu/dataflowJ";

import module namespace common = "aqd-common" at "aqd-common.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";
import module namespace sparqlx = "aqd-sparql" at "aqd-sparql.xquery";
import module namespace labels = "aqd-labels" at "aqd-labels.xquery";
import module namespace vocabulary = "aqd-vocabulary" at "aqd-vocabulary.xquery";
import module namespace query = "aqd-query" at "aqd-query.xquery";
import module namespace errors = "aqd-errors" at "aqd-errors.xquery";
import module namespace filter = "aqd-filter" at "aqd-filter.xquery";
import module namespace dd = "aqd-dd" at "aqd-dd.xquery";
import module namespace schemax = "aqd-schema" at "aqd-schema.xquery";
import module namespace geox = "aqd-geo" at "aqd-geo.xquery";
import module namespace checks = "aqd-checks" at "aqd-checks.xq";
import module namespace functx = "http://www.functx.com" at "functx-1.0-doc-2007-01.xq";

declare namespace aqd = "http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0";
declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace am = "http://inspire.ec.europa.eu/schemas/am/3.0";
declare namespace ef = "http://inspire.ec.europa.eu/schemas/ef/3.0";
declare namespace base = "http://inspire.ec.europa.eu/schemas/base/3.3";
declare namespace ad = "urn:x-inspire:specification:gmlas:Addresses:3.0";
declare namespace gn = "urn:x-inspire:specification:gmlas:GeographicalNames:3.0";
declare namespace base2 = "http://inspire.ec.europa.eu/schemas/base2/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace om = "http://www.opengis.net/om/2.0";
declare namespace swe = "http://www.opengis.net/swe/2.0";
declare namespace ompr="http://inspire.ec.europa.eu/schemas/ompr/2.0";
declare namespace sams="http://www.opengis.net/samplingSpatial/2.0";
declare namespace sam = "http://www.opengis.net/sampling/2.0";
declare namespace gmd = "http://www.isotc211.org/2005/gmd";
declare namespace gco = "http://www.isotc211.org/2005/gco";

declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace adms = "http://www.w3.org/ns/adms#";
declare namespace prop = "http://dd.eionet.europa.eu/property/";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare variable $dataflowJ:ISO2_CODES as xs:string* := ("AL","AT","BA","BE","BG","CH","CY","CZ","DE","DK","DZ","EE","EG","ES","FI",
    "FR","GB","GR","HR","HU","IE","IL","IS","IT","JO","LB","LI","LT","LU","LV","MA","ME","MK","MT","NL","NO","PL","PS","PT",
     "RO","RS","SE","SI","SK","TN","TR","XK","UK");

declare variable $dataflowJ:OBLIGATIONS as xs:string* := ($vocabulary:ROD_PREFIX || "682");

(: Rule implementations :)
declare function dataflowJ:checkReport($source_url as xs:string, $countryCode as xs:string) as element(table) {
let $ms1Total := prof:current-ms()

let $ms1GeneralParameters:= prof:current-ms()
let $docRoot := doc($source_url)
let $evaluationScenario := $docRoot//aqd:AQD_EvaluationScenario
(: example 2014 :)
let $reportingYear := common:getReportingYear($docRoot)
(: example resources/dataflow-j/xml :)
let $envelopeUrl := common:getEnvelopeXML($source_url)
(: example cdr.eionet.europa.eu/be/eu/aqd/ :)
let $cdrUrl := common:getCdrUrl($countryCode)
(: example http://cdr.eionet.europa.eu/be/eu/aqd/j/envwmp5lw :)
let $latestEnvelopeByYearJ := query:getLatestEnvelope($cdrUrl || "j/", $reportingYear)
let $ancestor-name := "aqd:AQD_EvaluationScenario"

let $headerBeginPosition := $docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:beginPosition
let $headerEndPosition := $docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:endPosition

let $latestEnvelopesH := query:getLatestEnvelopesForObligation("680")
let $latestEnvelopesI := query:getLatestEnvelopesForObligation("681")
let $latestEnvelopesJ := query:getLatestEnvelopesForObligation("682")
let $latestEnvelopesK := query:getLatestEnvelopesForObligation("683")

let $ms2GeneralParameters:= prof:current-ms()
(: NS
Check prefix and namespaces of the gml:featureCollection according to expected root elements
(More information at http://www.eionet.europa.eu/aqportal/datamodel)

Prefix/namespaces check
:)

let $ms1NS := prof:current-ms()

let $NSinvalid := try {
    let $XQmap := inspect:static-context((), 'namespaces')
    let $fileMap := map:merge(
        for $x in in-scope-prefixes($docRoot/*)
        return map:entry($x, string(namespace-uri-for-prefix($x, $docRoot/*)))
    )

    return map:for-each($fileMap, function($a, $b) {
        let $x := map:get($XQmap, $a)
        return
            if ($x != "" and not($x = $b)) then
                <tr>
                    <td title="Prefix">{$a}</td>
                    <td title="File namespace">{$b}</td>
                    <td title="XQuery namespace">{$x}</td>
                </tr>
            else
                ()
    })
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2NS := prof:current-ms()

(: VOCAB check:)
let $ms1VOCAB := prof:current-ms()
let $VOCABinvalid := checks:vocab($docRoot)
let $ms2VOCAB := prof:current-ms()

(:VOCABALL check @goititer:)

let $ms1CVOCABALL := prof:current-ms()

let $VOCABALLinvalid := checks:vocaball($docRoot)

let $ms2CVOCABALL := prof:current-ms()

(: J0
Check if delivery if this is a new delivery or updated delivery (via reporting year)

Checks if this delivery is new or an update (on same reporting year)
:)

let $ms1J0 := prof:current-ms()

let $J0 := try {
    if ($reportingYear = "")
    then
        common:checkDeliveryReport($errors:ERROR, "Reporting Year is missing.")
    else if($headerBeginPosition > $headerEndPosition) then
        <tr class="{$errors:BLOCKER}">
            <td title="Status">Start position must be less than end position</td>
        </tr>
    else
        if(query:deliveryExists($dataflowJ:OBLIGATIONS, $countryCode, "j/", $reportingYear))
        then
                common:checkDeliveryReport($errors:WARNING, "Updating delivery for " || $reportingYear)
            else
                common:checkDeliveryReport($errors:INFO, "New delivery for " || $reportingYear)


} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $isNewDelivery := errors:getMaxError($J0) = $errors:INFO
let $knownEvaluationScenarios :=
    if ($isNewDelivery)
    then
        distinct-values(data(sparqlx:run(query:getEvaluationScenarios($cdrUrl || "j/"))//sparql:binding[@name='inspireLabel']/sparql:literal))
    else
        distinct-values(data(sparqlx:run(query:getEvaluationScenarios($latestEnvelopeByYearJ))//sparql:binding[@name='inspireLabel']/sparql:literal))
        
let $ms2J0 := prof:current-ms()        

(: J1
Compile & feedback upon the total number of plans records included in the delivery

Number of AQ Plans reported
:)

let $ms1J01 := prof:current-ms()

let $countEvaluationScenario := count($docRoot//aqd:AQD_EvaluationScenario)
let $J1 := try {
    for $rec in $docRoot//aqd:AQD_EvaluationScenario
        let $el := $rec/aqd:inspireId/base:Identifier
        return
            common:conditionalReportRow(
            false(),
            [
                ("gml:id", data($rec/@gml:id)),
                ("base:localId", data($el/base:localId)),
                ("base:namespace", data($el/base:namespace)),
                ("base:versionId", data($el/base:versionId))
            ]
            )

} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J01 := prof:current-ms()

(: J2
Compile & feedback upon the total number of new EvaluationScenarios records included in the delivery.
ERROR will be returned if XML is a new delivery and localId are not new compared to previous deliveries.

Number of new EvaluationScenarios compared to previous report.
:)

let $ms1J02 := prof:current-ms()

let $J2 := try {
    for $el in $docRoot//aqd:AQD_EvaluationScenario
        let $x := $el/aqd:inspireId/base:Identifier
        let $inspireId := concat(data($x/base:namespace), "/", data($x/base:localId))
        let $ok := $inspireId = $knownEvaluationScenarios
        return
            common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($el/@gml:id)),
                ("aqd:inspireId", $inspireId),
                (:("Sparql", sparqlx:getLink(query:existsViaNameLocalIdQueryFilteringBySubject(data($el/@gml:id), 'AQD_EvaluationScenario', $latestEnvelopesJ))):) (:08/01/2021:)
                ("Sparql", sparqlx:getLink(query:existsViaNameLocalIdQueryFilteringBySubject($x/base:localId, 'AQD_EvaluationScenario', $latestEnvelopesJ)))(:11/01/2021:)
            ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}
let $J2errorLevel :=
    if (
        $isNewDelivery
        and
        count(
            for $x in $docRoot//aqd:AQD_EvaluationScenario/aqd:inspireId/base:Identifier
                let $id := $x/base:namespace || "/" || $x/base:localId
                where query:existsViaNameLocalIdJ02($x/base:localId, 'AQD_EvaluationScenario', $latestEnvelopesJ)
                return 1
        ) > 0
        )
    then
        $errors:J2
    else
        $errors:INFO

let $ms2J02 := prof:current-ms()

(: J3
Compile & feedback upon the total number of updated EvaluationScenarios records included in the delivery.
ERROR will be returned if XML is an update and ALL localId (100%) are different
to previous delivery (for the same YEAR).

Number of existing EvaluationScenarios compared to previous report.
ERROR will be returned if XML is an update and ALL localId (100%)
are different to previous delivery (for the same YEAR).
:)

let $ms1J03 := prof:current-ms()

let $J3 := try {
    for $main in $docRoot//aqd:AQD_EvaluationScenario
        let $x := $main/aqd:inspireId/base:Identifier
        let $inspireId := concat(data($x/base:namespace), "/", data($x/base:localId))
        let $ok := not(query:existsViaNameLocalId($inspireId, 'AQD_EvaluationScenario', $latestEnvelopesJ))
        return
            common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($main/@gml:id)),
                ("aqd:inspireId", $inspireId),
                ("aqd:classification", common:checkLink(distinct-values(data($main/aqd:classification/@xlink:href)))),
                ("Sparql", sparqlx:getLink(query:existsViaNameLocalIdQuery($inspireId, 'AQD_EvaluationScenario', $latestEnvelopesJ)))
            ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}
let $J3errorLevel :=
    if (not($isNewDelivery) and count($J3) = 0)
    then
        $errors:J3
    else
        $errors:INFO

let $ms2J03 := prof:current-ms()

(: J4
Compile & feedback a list of the unique identifier information
for all EvaluationScenarios records included in the delivery.
Feedback report shall include the gml:id attribute, ./aqd:inspireId, ./aqd:pollutant, ./aqd:protectionTarget,

List of unique identifier information for all EvaluationScenarios records. Blocker if no EvaluationScenarios
:)

let $ms1J04 := prof:current-ms()

let $J4 := try {
    let $gmlIds := $docRoot//aqd:AQD_EvaluationScenario/lower-case(normalize-space(@gml:id))
    let $inspireIds := $docRoot//aqd:AQD_EvaluationScenario/lower-case(normalize-space(aqd:inspireId))
    for $x in $docRoot//aqd:AQD_EvaluationScenario
        let $id := $x/@gml:id
        let $inspireId := $x/aqd:inspireId
        let $aqdinspireId := concat($x/aqd:inspireId/base:Identifier/base:namespace, "/",$x/aqd:inspireId/base:Identifier/base:localId)
        let $ok := (count(index-of($gmlIds, lower-case(normalize-space($id)))) = 1
            and
            count(index-of($inspireIds, lower-case(normalize-space($inspireId)))) = 1
        )
        return common:conditionalReportRow(
            not($ok),
            [
                ("gml:id", string($x/@gml:id)),
                ("aqd:inspireId", distinct-values($aqdinspireId)),
                ("aqd:usedInPlan", data($x/aqd:usedInPlan/@xlink:href)),
                ("aqd:sourceApportionment ", data($x/aqd:sourceApportionment/@xlink:href))
            ]
        )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J04 := prof:current-ms()

(: J5 RESERVE :)

let $ms1J05 := prof:current-ms()
let $J5 := ()
let $ms2J05 := prof:current-ms()

(: J6 RESERVE :)

let $ms1J06 := prof:current-ms()
let $J6 := ()
let $ms2J06 := prof:current-ms()

(: J7
All gml:id attributes, ef:inspireId and aqd:inspireId elements shall have unique content

All gml ID attributes shall have unique code
:)

let $ms1J07 := prof:current-ms()
(:)
let $H07 := try {
    let $gmlIds := $docRoot//aqd:AQD_Plan//@gml:id
    let $inspireIds := $docRoot//aqd:AQD_Plan/lower-case(normalize-space(aqd:inspireId))

    for $x in $docRoot//aqd:AQD_Plan 
      let $ids := $x//@gml:id
      let $aqdInspireId := $x/aqd:inspireId/base:Identifier/base:localId 
      for $id in $ids           
        let $ok := (
          count(index-of($gmlIds, $id)) = 1
        )

       where not($ok) return
          <tr>
              <td title="duplicated gml:id">{data($id)}</td>
              <td title="aqd:inspireId">{distinct-values($aqdInspireId)}</td>
          </tr>   
} catch * {
    html:createErrorRow($err:code, $err:description)
}:)
let $J7 := try {

    let $gmlIds := $docRoot//aqd:AQD_EvaluationScenario//@gml:id
    let $inspireIds := $docRoot//aqd:AQD_EvaluationScenario/lower-case(normalize-space(aqd:inspireId))

    for $x in $docRoot//aqd:AQD_EvaluationScenario 
      let $ids := $x//@gml:id
      let $aqdInspireId := $x/aqd:inspireId/base:Identifier/base:localId 
      for $id in $ids           
        let $ok := (
          count(index-of($gmlIds, $id)) = 1
        )

       where not($ok) return
          <tr>
              <td title="duplicated gml:id">{data($id)}</td>
              <td title="aqd:inspireId">{distinct-values($aqdInspireId)}</td>
          </tr>   
} catch * {
    html:createErrorRow($err:code, $err:description)
}

   

let $ms2J07 := prof:current-ms()
(:let $J7 := try {


    let $main := $docRoot//aqd:AQD_EvaluationScenario

    let $checks := ('gml:id', 'aqd:inspireId', 'ef:inspireId')

    let $errors := array {

        for $name in $checks
            let $name := lower-case(normalize-space($name))
            let $values := $main//(*[lower-case(normalize-space(name())) = $name] |
                                   @*[lower-case(normalize-space(name())) = $name])
            return
                for $v in distinct-values($values)
                    return
                        if (common:has-one-node($values, $v))
                        then
                            ()
                        else
                            [$name, data($v)]
    }

    return common:conditionalReportRow(
        array:size($errors) = 0,
        $errors
    )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J07 := prof:current-ms():)

(: J8
./aqd:inspireId/base:Identifier/base:localId must be unique code for the Plans records

Local Id must be unique for the EvaluationScenarios records
:)

let $ms1J08 := prof:current-ms()

let $J8 := try {
    let $localIds := $docRoot//aqd:AQD_EvaluationScenario/aqd:inspireId/base:Identifier/lower-case(normalize-space(base:localId))
    for $x in $docRoot//aqd:AQD_EvaluationScenario
        let $localID := $x/aqd:inspireId/base:Identifier/base:localId
        let $aqdinspireId := concat($x/aqd:inspireId/base:Identifier/base:namespace, "/", $x/aqd:inspireId/base:Identifier/base:localId)
        let $ok := (
            count(index-of($localIds, lower-case(normalize-space($localID)))) = 1
            and
            functx:if-empty($localID/text(), "") != ""
        )
        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($x/@gml:id)),
                ("aqd:inspireId", distinct-values($aqdinspireId))
            ]
        )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J08 := prof:current-ms()

(: J9
 ./aqd:inspireId/base:Identifier/base:namespace List base:namespace
 and count the number of base:localId assigned to each base:namespace.

 List unique namespaces used and count number of elements
:)

let $ms1J09 := prof:current-ms()
(: commented by diezzana on 20201123, issue #124498
let $J9 := try {
    for $namespace in distinct-values($docRoot//aqd:AQD_EvaluationScenario/aqd:inspireId/base:Identifier/base:namespace)
        let $localIds := $docRoot//aqd:AQD_EvaluationScenario/aqd:inspireId/base:Identifier[base:namespace = $namespace]/base:localId
        let $ok := false()
        return common:conditionalReportRow(
            $ok,
            [
                ("base:namespace", $namespace),
                ("base:localId", count($localIds))
            ]
        )
} catch * {
    html:createErrorRow($err:code, $err:description)
}:)

let $J9 := try {
    for $x in $docRoot//aqd:AQD_EvaluationScenario/aqd:inspireId/base:Identifier
        let $namespace := $x/base:namespace 
        let $localIds := $docRoot//aqd:AQD_EvaluationScenario/aqd:inspireId/base:Identifier[base:namespace = $namespace]/base:localId
        let $ok := false()
        return common:conditionalReportRow(
            $ok,
            [
                ("base:namespace", $namespace),
                ("base:localId", count($localIds))
            ]
        )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J09 := prof:current-ms()

(: J10
Check that namespace is registered in vocabulary (http://dd.eionet.europa.eu/vocabulary/aq/namespace/view)

Check namespace is registered
:)

let $ms1J10 := prof:current-ms()

let $J10 := try {
    let $vocDoc := doc($vocabulary:NAMESPACE || "rdf")
    let $prefLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE
            and @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)]/skos:prefLabel[1]
    let $altLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE
            and @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)]/skos:altLabel[1]
    for $x in distinct-values($docRoot//base:namespace)
        let $ok := (
            $x = $prefLabel
            and
            $x = $altLabel
        )
        return common:conditionalReportRow(
            $ok,
            [
                ("base:namespace", $x)
            ]
        )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J10 := prof:current-ms()

(: J11
aqd:AQD_EvaluationScenario/aqd:usedInPlan shall reference an existing AQD_Plan (H) document
for the same reporting year same year via namespace/localId

You must provide a reference to a plan document from data flow H via its namespace & localId.
The plan document must have the same reporting year as the source apportionment document.
:)

let $ms1J11 := prof:current-ms()

let $J11 := try {
    for $main in $evaluationScenario
        let $el := $main/aqd:usedInPlan
        let $label := $el/@xlink:href
        let $ok := query:existsViaNameLocalIdYear(
                $label,
                'AQD_Plan',
                $reportingYear,
                $latestEnvelopesH
        )
        return common:conditionalReportRow(
                $ok,
                [
                    ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                    (node-name($el), $label),
                    ("Sparql", sparqlx:getLink(query:existsViaNameLocalIdYearQuery($label,'AQD_Plan',$reportingYear,$latestEnvelopesH)))
                ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J11 := prof:current-ms()

(: J12
aqd:AQD_EvaluationScenario/aqd:sourceApportionment MUST reference an existing AQD_SourceApportionment (I) document
via namespace/localId record for the same reporting year .

You must provide a link to a Source Apportionment (I) document from data flow I
via its namespace & localId (for the same reporting year)
:)

let $ms1J12 := prof:current-ms()

let $J12 := try {
    for $main in $evaluationScenario
        let $el := $main/aqd:sourceApportionment
        let $label := functx:if-empty($el/@xlink:href, "")
        let $ok := query:existsViaNameLocalIdYear(
                $label,
                'AQD_SourceApportionment',
                $reportingYear,
                $latestEnvelopesI
        )
        return common:conditionalReportRow(
                $ok,
                [
                    ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                    (node-name($el), $label),
                    ("Sparql", sparqlx:getLink(query:existsViaNameLocalIdYearQuery($label,'AQD_SourceApportionment',$reportingYear,$latestEnvelopesI)))
                ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J12 := prof:current-ms()

(: J13
aqd:AQD_EvaluationScenario/aqd:codeOfScenario should begin with with the 2-digit country code according to ISO 3166-1.

A code of the scenario should be provided as nn alpha-numeric code starting with the country ISO code
:)

(:
let $ms1J13 := prof:current-ms()
let $J13 := try {
    for $main in $evaluationScenario
        let $el := $main/aqd:codeOfScenario
        let $ok := fn:lower-case($countryCode) = fn:lower-case(fn:substring(data($el), 1, 2))
        return common:conditionalReportRow(
                $ok,
                [
                    ("gml:id", $main/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                    (node-name($el), $el)
                ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}
let $ms2J13 := prof:current-ms()
:)

(: J14
aqd:AQD_EvaluationScenario/aqd:publication/aqd:Publication/aqd:description shall be a text string

Short textul description of the publication should be provided. If availabel, include the ISBN number.
:)

let $ms1J14 := prof:current-ms()

let $J14 := try {
    for $el in $evaluationScenario/aqd:publication/aqd:Publication/aqd:description
        let $ok := (data($el) castable as xs:string
            and
            functx:if-empty(data($el), "") != ""
        )
        return common:conditionalReportRow(
                $ok,
                [
                    ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                    (node-name($el), data($el))
                ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J14 := prof:current-ms()

(: J15
aqd:AQD_EvaluationScenario/aqd:publication/aqd:Publication/aqd:title
shall be a text string

Title as written in the publication.
:)

let $ms1J15 := prof:current-ms()

let $J15 := try {
    let $main := $evaluationScenario/aqd:publication/aqd:Publication/aqd:title
    for $el in $main
        let $ok := (data($el) castable as xs:string
            and
            functx:if-empty(data($el), "") != ""
        )
        return common:conditionalReportRow(
                $ok,
                [
                    ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                    (node-name($el), $el)
                ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J15 := prof:current-ms()

(: J16
aqd:AQD_EvaluationScenario/aqd:publication/aqd:Publication/aqd:author shall be a text string (if provided)

Author(s) should be provided as text (If there are multiple authors, please provide in one field separated by commas)
:)

let $ms1J16 := prof:current-ms()

let $J16 := try {
    let $main := $evaluationScenario/aqd:publication/aqd:Publication/aqd:author
    for $el in $main
        let $ok := (data($el) castable as xs:string
            and
            functx:if-empty(data($el), "") != ""
        )
        return common:conditionalReportRow(
                $ok,
                [
                    ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                    (node-name($el), $el)
                ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J16 := prof:current-ms()

(: J17
aqd:AQD_EvaluationScenario/aqd:publication/aqd:Publication/aqd:publicationDate/gml:TimeInstant/gml:timePosition
may be a data in yyyy or yyyy-mm-dd format

The publication date should be provided in yyyy or yyyy-mm-dd format
:)

let $ms1J17 := prof:current-ms()

let $J17 := try {
    let $main := $evaluationScenario/aqd:publication/aqd:Publication/aqd:publicationDate/gml:TimeInstant/gml:timePosition
    for $node in $main
        let $ok := (
            data($node) castable as xs:date
            or
            not(common:isInvalidYear(data($node)))
        )
        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", $node/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                (node-name($node), data($node))
            ]
        )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J17 := prof:current-ms()

(: J18
aqd:AQD_EvaluationScenario/aqd:publication/aqd:Publication/aqd:publisher
shall be a text string

Publisher should be provided as a text (Publishing institution, academic jourmal, etc.)
:)

let $ms1J18 := prof:current-ms()

let $J18 := try {
    let $main := $evaluationScenario/aqd:publication/aqd:Publication/aqd:publisher
    for $el in $main
        let $ok := (data($el) castable as xs:string
            and
            functx:if-empty(data($el), "") != ""
        )
        return common:conditionalReportRow(
                $ok,
                [
                    ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                    (node-name($el), $el)
                ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J18 := prof:current-ms()

(: J19
aqd:AQD_EvaluationScenario/aqd:publication/aqd:Publication/aqd:webLink
as a valid url (if provided)

Url to the published AQ Plan should be valid (if provided)
:)

let $ms1J19 := prof:current-ms()

let $J19 := try {
    let $main :=  $evaluationScenario/aqd:publication/aqd:Publication/aqd:webLink
    for $el in $main
        let $ok := (
            functx:if-empty(data($el), "") != ""
            and
            common:includesURL(data($el))
            )
        return common:conditionalReportRow(
                $ok,
                [
                    ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                    (node-name($el), $el)
                ]
            )

} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J19 := prof:current-ms()

(: J20
aqd:AQD_EvaluationScenario/aqd:attainmentYear/gml:TimeInstant/gml:timePosition must be provided and must conform to yyyy format

The year for which the projections are developed must be provided and the yyyy format used
:)

let $ms1J20 := prof:current-ms()

let $J20 := try {
    let $main := $evaluationScenario/aqd:attainmentYear/gml:TimeInstant/gml:timePosition
    for $el in $main
        let $ok := not(common:isInvalidYear(data($el)))
        return common:conditionalReportRow(
                $ok,
                [
                    ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                    (node-name($el), $el)
                ]
            )

} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J20 := prof:current-ms()

(: J21
aqd:AQD_EvaluationScenario/aqd:startYear/gml:TimeInstant/gml:timePosition
must be provided and must conform to yyyy format

Reference year from which the projections started and
for which the source apportionment is available must be provided. Format used yyyy.
:)

let $ms1J21 := prof:current-ms()

let $J21 := try {
    let $main := $evaluationScenario/aqd:startYear/gml:TimeInstant/gml:timePosition
    for $el in $main
        let $ok := (
            not(common:isInvalidYear(data($el)))
            and
            functx:if-empty(data($el), "") != ""
        )
        return common:conditionalReportRow(
                $ok,
                [
                    ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                    (node-name($el), $el)
                ]
            )

} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J21 := prof:current-ms()

(: J22
Check aqd:AQD_EvaluationScenario/aqd:startYear/gml:TimeInstant/gml:timePosition must be equal to
aqd:AQD_SourceApportionment/aqd:referenceYear/gml:TimeInstant/gml:timePosition
referenced via the xlink of (aqd:AQD_EvaluationScenario/aqd:sourceApportionment)

Check if start year of the evaluation scenario is the same as
the source apportionment reference year
:)
(: 
let $ms1J22 := prof:current-ms()
let $J22 := try {
    for $node in $evaluationScenario
        let $el := $node/aqd:sourceApportionment
        let $year := $node/aqd:startYear/gml:TimeInstant/gml:timePosition
        let $ok := query:isTimePositionValid(
            'AQD_SourceApportionment',
            $el/@xlink:href,
            $year,
            $latestEnvelopesI
        )
        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                (node-name($el), $el/@xlink:href),
                ("Sparql", sparqlx:getLink(query:isTimePositionValidQuery('AQD_SourceApportionment',$el/@xlink:href,$year,$latestEnvelopesI)))
            ]
        )

} catch * {
    html:createErrorRow($err:code, $err:description)
} 
let $ms2J22 := prof:current-ms()
:)

(: J23
aqd:AQD_EvaluationScenario/aqd:baselineScenario/aqd:Scenario/aqd:description shall be a text string

A description of the emission scenario used for the baseline analysis should be provided as text
:)

let $ms1J23 := prof:current-ms()

let $J23 := try {
    let $main := $evaluationScenario/aqd:baselineScenario/aqd:Scenario/aqd:description
    for $el in $main
        let $ok := (data($el) castable as xs:string
            and
            functx:if-empty(data($el), "") != ""
        )
        return common:conditionalReportRow(
                $ok,
                [
                    ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                    (node-name($el), $el)
                ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J23 := prof:current-ms()

(: J24
Check that the element aqd:AQD_EvaluationScenario/aqd:baselineScenario/aqd:Scenario/aqd:totalEmissions
is an integer or floating point numeric >= 0 and the unit (@uom) shall resolve to the codelist
http://dd.eionet.europa.eu/vocabulary/uom/emission/kt.year-1

The baseline total emissions should be provided as integer with correct unit.
:)

let $ms1J24 := prof:current-ms()

let $J24 := try {
    for $node in $evaluationScenario
        let $el := $node/aqd:baselineScenario/aqd:Scenario/aqd:totalEmissions
        let $ok := (
            $el/@uom = "http://dd.eionet.europa.eu/vocabulary/uom/emission/kt.year-1"
            and
            (data($el) castable as xs:float
            or
            data($el) castable as xs:integer)
            and
            data($el) >= 0
            and
            common:isInVocabulary(
                    $el/@uom,
                    $vocabulary:UOM_EMISSION_VOCABULARY
            )
        )
        return common:conditionalReportRow(
                $ok,
                [
                    ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                    ("aqd:totalEmissions", $el),
                    ("uom", $el/@uom)
                ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J24 := prof:current-ms()

(: J25
Check that the element aqd:AQD_EvaluationScenario/aqd:baselineScenario/aqd:AQD_Scenario/aqd:expectedConcentration
is an integer or floating point numeric >= 0 and the unit (@uom) shall resolve to the codelist
http://dd.eionet.europa.eu/vocabulary/uom/concentration/

The expected concentration (under baseline scenario) should be provided as an integer and its unit should conform to vocabulary
:)

let $ms1J25 := prof:current-ms()

let $J25 := try {
    let $main := $evaluationScenario/aqd:baselineScenario/aqd:Scenario/aqd:expectedConcentration
    for $el in $main
        let $ok := (
            (data($el) castable as xs:float
            or
            data($el) castable as xs:integer)
            and
            data($el) >= 0
            and 
            data($el) <= 5000
            and
            common:isInVocabulary(
                    $el/@uom,
                    $vocabulary:UOM_CONCENTRATION_VOCABULARY
            )
        )
        return common:conditionalReportRow(
                $ok,
                [
                    ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                    ("aqd:expectedConcentration", $el),
                    ("uom", $el/@uom)
                ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J25 := prof:current-ms()

(: J26
Check that the element aqd:AQD_EvaluationScenario/aqd:baselineScenario/aqd:AQD_Scenario/aqd:expectedExceedances
is an integer or floating point numeric >= 0 and the unit (@uom) shall resolve to the codelist
http://dd.eionet.europa.eu/vocabulary/uom/statistics

The number of exceecedance expected (under baseline scenario) should be provided as an integer and its unit should conform to vocabulary
:)

let $ms1J26 := prof:current-ms()
(: commented by diezzana on 20201120, issue #120666
let $J26 := try {
    let $main := $evaluationScenario/aqd:baselineScenario/aqd:Scenario/aqd:expectedExceedances
    for $el in $main
        let $ok := (
            (data($el) castable as xs:float
            or
            data($el) castable as xs:integer)
            and
            data($el) >= 0
            and
            common:isInVocabulary(
                    $el/@uom,
                    $vocabulary:UOM_STATISTICS
            )
        )
        return common:conditionalReportRow(
                $ok,
                [
                    ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                    ("aqd:expectedExceedances", $el),
                    ("uom", $el/@uom)
                ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}:)

let $J26 := try {
    let $main := $evaluationScenario/aqd:baselineScenario/aqd:Scenario/aqd:expectedExceedances
    for $el in $main
        let $ok := (
            (data($el) castable as xs:float
            or
            data($el) castable as xs:integer)
            and
            data($el) >= 0
        )
        return common:conditionalReportRow(
                $ok,
                [
                    ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                    ("aqd:expectedExceedances", $el)
                ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J26 := prof:current-ms()

(: J27
aqd:AQD_EvaluationScenario/aqd:baselineScenario/aqd:Scenario/aqd:measuresApplied
shall reference an existing AQD_Measures delivered within a data flow K
and the reporting year of K & J shall be the same year via namespace/localId.

Measures identified in the AQ-plan that are included in this baseline scenario should be provided (link to dataflow K)
:)

(:let $ms1J27 := prof:current-ms()

let $J27 := try{
    let $main := $evaluationScenario/aqd:baselineScenario/aqd:Scenario/aqd:measuresApplied
    for $el in $main
        (: let $ok := query:existsViaNameLocalIdYear(
                $el/@xlink:href,
                'AQD_Measures',
                $reportingYear,
                $latestEnvelopesK
        ) :)
        
        let $label := data($el/@xlink:href)
        let $ok := if(fn:empty($label))
        then
            true()
        else
            query:existsViaNameLocalIdYear(
                $el/@xlink:href,
                'AQD_Measures',
                $reportingYear,
                $latestEnvelopesK
            )
        
        let $sparql_query := if(fn:empty($label))
                             then
                              "No element to execute this query"
                             else
                              sparqlx:getLink(query:existsViaNameLocalIdYearQuery($el/@xlink:href, 'AQD_Measures', $reportingYear, $latestEnvelopesK))
        
        return common:conditionalReportRow(
                $ok,
                [
                    ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                    (node-name($el), $el/@xlink:href),
                    (: ("Sparql", sparqlx:getLink(query:existsViaNameLocalIdYearQuery($el/@xlink:href,'AQD_Measures',$reportingYear,$latestEnvelopesK))) :)
                    ("Sparql", $sparql_query)
                ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}:)

let $ms1J27 := prof:current-ms()

let $J27 := try{
    let $main := $evaluationScenario/aqd:baselineScenario/aqd:Scenario/aqd:measuresApplied
    (:let $viaNameLocalIdList:= sparqlx:run(query:existsViaNameLocalIdYearGeneral('AQD_Measures',$reportingYear)):) (: issue #117054 :)
    let $viaNameLocalIdList:= sparqlx:run(query:existsViaNameLocalIdYearGeneralWithoutYearFilter('AQD_Measures',$reportingYear)) (: issue #117054 :)
    for $el in $main
    
        let $label := data($el/@xlink:href)
        (:  let $localId:=
          for $nameLocalId in $viaNameLocalIdList
            for $nameLocalId in $viaNameLocalIdList[sparql:binding[@name='label']/sparql:literal=$label]/sparql:binding[@name='subject']/sparql:uri
            return  $nameLocalId/sparql:binding[@name='subject']/sparql:uri
            return  $nameLocalId/sparql:binding[@name='label']/sparql:literal:)

       let $localId:=
            (: for $nameLocalId in $viaNameLocalIdList[sparql:binding[@name='label']/sparql:literal=$label]/sparql:binding[@name='subject']/sparql:uri :) (:issue #117054 :)
            for $nameLocalId in $viaNameLocalIdList[sparql:binding[@name='label']/sparql:literal=$label and sparql:binding[@name='reportingYear']/sparql:literal=$reportingYear]/sparql:binding[@name='subject']/sparql:uri (: issue #117054 :)
           return  query:existsViaNameLocalIdYear1(
                $nameLocalId,
                $latestEnvelopesK
            )
        let $ok := if(fn:empty($label))
        then
            (:true() volver a poner a true cnd terminen pruebas:)
            false()
        else
        
        (:
            for $nameLocalId in $viaNameLocalIdList:)
            
            if(fn:empty($localId)) then false()
            else $localId
            (:return  $nameLocalId/sparql:binding[@name='label']/sparql:literal:)

        let $sparql_query := if(fn:empty($label))
                             then
                              "No element to execute this query"
                             else
                              (:sparqlx:getLink(query:existsViaNameLocalIdYearQuery($el/@xlink:href, 'AQD_Measures', $reportingYear, $latestEnvelopesK)):) (: issue #117054 :)
                              (:sparqlx:getLink(query:existsViaNameLocalIdYearGeneralWithoutYearFilter('AQD_Measures',$reportingYear)):) (: issue #117054 :) (: 09/12/2020 :)
                              sparqlx:getLink(query:existsViaNameLocalIdYearGeneralWithoutYearFilter($label, 'AQD_Measures',$reportingYear)) (: 09/12/2020 :)
        
        return common:conditionalReportRow(
                $ok,
                [
                    ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                    (node-name($el), $el/@xlink:href),
                    
                    (: ("Sparql", sparqlx:getLink(query:existsViaNameLocalIdYearQuery($el/@xlink:href,'AQD_Measures',$reportingYear,$latestEnvelopesK))) :)
                    ("Sparql", $sparql_query)
                ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J27 := prof:current-ms()

(: J28
aqd:AQD_EvaluationScenario/aqd:projectionScenario/aqd:Scenario/aqd:description shall be a text string

A description of the emission scenario used for the projection analysis should be provided as text
:)

let $ms1J28 := prof:current-ms()

let $J28 := try {
    let $main := $evaluationScenario/aqd:projectionScenario/aqd:Scenario/aqd:description
    for $el in $main
    let $ok := (data($el) castable as xs:string
        and
        functx:if-empty(data($el), "") != ""
    )
    return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                (node-name($el), $el)
            ]
        )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J28 := prof:current-ms()

(: J29
Check that the element aqd:AQD_EvaluationScenario/aqd:projectionScenario/aqd:Scenario/aqd:totalEmissions
is an integer or floating point numeric >= 0 and the unit (@uom) shall resolve to the codelist
http://dd.eionet.europa.eu/vocabulary/uom/emission/kt.year-1

The projection total emissions should be provided as integer with correct unit.
:)

let $ms1J29 := prof:current-ms()

let $J29 := try {
    let $main := $evaluationScenario/aqd:projectionScenario/aqd:Scenario/aqd:totalEmissions
    for $el in $main
        let $ok := (
            $el/@uom eq "http://dd.eionet.europa.eu/vocabulary/uom/emission/kt.year-1"
            and
            (data($el) castable as xs:float
            or
            data($el) castable as xs:integer)
            and
            data($el) >= 0
            and
            common:isInVocabulary(
                    $el/@uom,
                    $vocabulary:UOM_EMISSION_VOCABULARY
            )
        )
        return common:conditionalReportRow(
                $ok,
                [
                    ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                    ("aqd:totalEmissions", $el),
                    ("uom", $el/@uom)
                ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J29 := prof:current-ms()

(: J30
Check that the element aqd:AQD_EvaluationScenario/aqd:projectionScenario/aqd:AQD_Scenario/aqd:expectedConcentration
is an integer or floating point numeric >= 0 and the unit (@uom) shall resolve to the codelist
http://dd.eionet.europa.eu/vocabulary/uom/concentration/

The expected concentration (under projection scenario) should be provided as an integer and its unit should conform to vocabulary
:)
(:  TODO CHECK IF $main node is not empty for all CHECKS  :)

let $ms1J30 := prof:current-ms()

let $J30 := try {
    let $main := $evaluationScenario/aqd:projectionScenario/aqd:Scenario/aqd:expectedConcentration
    for $el in $main
        let $ok := (
            (data($el) castable as xs:float
            or
            data($el) castable as xs:integer)
            and
            data($el) >= 0
            and
            common:isInVocabulary(
                    $el/@uom,
                    $vocabulary:UOM_CONCENTRATION_VOCABULARY
            )
        )
        return common:conditionalReportRow(
                $ok,
                [
                    ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                    ("aqd:expectedConcentration", $el),
                    ("uom", $el/@uom)
                ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J30 := prof:current-ms()

(: J31
Check that the element aqd:AQD_EvaluationScenario/aqd:projectionScenario/aqd:AQD_Scenario/aqd:expectedExceedances
is an integer or floating point numeric >= 0 and the unit (@uom) shall resolve to the codelist
http://dd.eionet.europa.eu/vocabulary/uom/statistics

The number of exceecedance expected (under projection scenario) should be provided
as an integer and its unit should conform to vocabulary
:)

let $ms1J31 := prof:current-ms()

let $J31 := try {
    let $main := $evaluationScenario/aqd:projectionScenario/aqd:AQD_Scenario/aqd:expectedExceedances
    for $el in $main
        let $ok := (
            (data($el) castable as xs:float
            or
            data($el) castable as xs:integer)
            and
            data($el) >= 0
            and
            common:isInVocabulary(
                    $el/@uom,
                    $vocabulary:UOM_STATISTICS
            )
        )
        return common:conditionalReportRow(
                $ok,
                [
                    ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                    ("aqd:expectedExceedances", $el),
                    ("uom", $el/@uom)
                ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J31 := prof:current-ms()

(: J32
aqd:AQD_EvaluationScenario/aqd:projectionScenario/aqd:Scenario/aqd:measuresApplied
shall reference an existing AQD_Measures delivered within a data flow K
and the reporting year of K & J shall be the same year via namespace/localId.

Measures identified in the AQ-plan that are included in this projection should be provided (link to dataflow K)
:)

let $ms1J32 := prof:current-ms()

(:let $J32 := try{
    let $main := $evaluationScenario/aqd:projectionScenario/aqd:Scenario/aqd:measuresApplied
    for $el in $main
        let $ok := query:existsViaNameLocalIdYear(
                $el/@xlink:href,
                'AQD_Measures',
                $reportingYear,
                $latestEnvelopesK
        )
        return common:conditionalReportRow(
                $ok,
                [
                    ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                    (node-name($el), $el/@xlink:href),
                    ("Sparql", sparqlx:getLink(query:existsViaNameLocalIdYearQuery($el/@xlink:href,'AQD_Measures',$reportingYear,$latestEnvelopesK)))
                ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}:)

(: code lines commented for issue #117054: time optimization and removal year specific :)
let $J32 := try{
    let $main := $evaluationScenario/aqd:projectionScenario/aqd:Scenario/aqd:measuresApplied
    (:let $viaNameLocalIdList:= sparqlx:run(query:existsViaNameLocalIdYearGeneral('AQD_Measures',$reportingYear)):)
    let $viaNameLocalIdList:= sparqlx:run(query:existsViaNameLocalIdYearGeneralWithoutYearFilter('AQD_Measures',$reportingYear))
    for $el in $main
        let $label := data($el/@xlink:href)
        
        let $localId:=
            (: for $nameLocalId in $viaNameLocalIdList[sparql:binding[@name='label']/sparql:literal=$label]/sparql:binding[@name='subject']/sparql:uri :)
            for $nameLocalId in $viaNameLocalIdList[sparql:binding[@name='label']/sparql:literal=$label and sparql:binding[@name='reportingYear']/sparql:literal=$reportingYear]/sparql:binding[@name='subject']/sparql:uri
           return  query:existsViaNameLocalIdYear1(
                $nameLocalId,
                $latestEnvelopesK
            )
            
        let $ok := if(fn:empty($label)) then
                        true()
                    else
                        if(fn:empty($localId)) then false()
                        else $localId

        let $sparql_query := if(fn:empty($label))
                             then
                              "No element to execute this query"
                             else
                              (:sparqlx:getLink(query:existsViaNameLocalIdYearQuery($el/@xlink:href, 'AQD_Measures', $reportingYear, $latestEnvelopesK)):)
                              (:sparqlx:getLink(query:existsViaNameLocalIdYearGeneralWithoutYearFilter('AQD_Measures',$reportingYear)):) (:09/12/2020:)
                              sparqlx:getLink(query:existsViaNameLocalIdYearGeneralWithoutYearFilter($label,'AQD_Measures',$reportingYear)) (:09/12/2020:)

        return common:conditionalReportRow(
                $ok,
                [
                    ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                    (node-name($el), $el/@xlink:href),
                    ("Sparql", $sparql_query)
                ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2J32 := prof:current-ms()

  let $ms2Total := prof:current-ms()
return
(
    <table class="maintable hover">
    <table>
        {html:build2("NS", $labels:NAMESPACES, $labels:NAMESPACES_SHORT, $NSinvalid, "All values are valid", "record", $errors:NS)}
        {html:build2("VOCAB", $labels:VOCAB, $labels:VOCAB_SHORT, $VOCABinvalid, "All values are valid", "record", $errors:VOCAB)}
        {html:buildNoCount2Sparql("VOCABALL", $labels:VOCABALL, $labels:VOCABALL_SHORT, $VOCABALLinvalid, "All values are valid", "Invalid urls found", $errors:VOCABALL)}
        {html:build3("J0", $labels:J0, $labels:J0_SHORT, $J0, string($J0/td), errors:getMaxError($J0))}
        {html:build1("J1", $labels:J1, $labels:J1_SHORT, $J1, "", string($countEvaluationScenario), "", "", $errors:J1)}
        {html:buildSimpleSparql("J2", $labels:J2, $labels:J2_SHORT, $J2, "", "", $J2errorLevel)}
        {html:buildSimpleSparql("J3", $labels:J3, $labels:J3_SHORT, $J3, "", "", $J3errorLevel)}
        {html:build1("J4", $labels:J4, $labels:J4_SHORT, $J4, "", string(count($J4)), " ", "", $errors:J4)}
        {html:build1("J5", $labels:J5, $labels:J5_SHORT, $J5, "RESERVE", "RESERVE", "RESERVE", "RESERVE", $errors:J5)}
        {html:build1("J6", $labels:J6, $labels:J6_SHORT, $J6, "RESERVE", "RESERVE", "RESERVE", "RESERVE", $errors:J6)}
        {html:build2Distinct("J7", $labels:J7, $labels:J7_SHORT, $J7, "No duplicate values found", " duplicate value", $errors:J7)}
        {html:build2("J8", $labels:J8, $labels:J8_SHORT, $J8, "No duplicate values found", " duplicate value", $errors:J8)}
        <!--{html:buildUnique("J9", $labels:J9, $labels:J9_SHORT, $J9, "namespace", $errors:J9)}-->
        {html:build2Distinct("J9", $labels:J9, $labels:J9_SHORT, $J9, "namespace", "", $errors:J9)}
        {html:build2("J10", $labels:J10, $labels:J10_SHORT, $J10, "All values are valid", " not conform to vocabulary", $errors:J10)}
        {html:build2Sparql("J11", $labels:J11, $labels:J11_SHORT, $J11, "All values are valid", "needs valid input", $errors:J11)}
        {html:build2Sparql("J12", $labels:J12, $labels:J12_SHORT, $J12, "All values are valid", "needs valid input", $errors:J12)}
        <!--{html:build2("J13", $labels:J13, $labels:J13_SHORT, $J13, "All values are valid", " not valid", $errors:J13)}-->
        {html:build2("J14", $labels:J14, $labels:J14_SHORT, $J14, "All values are valid", "needs valid input", $errors:J14)}
        {html:build2("J15", $labels:J15, $labels:J15_SHORT, $J15, "All values are valid", "needs valid input", $errors:J15)}
        {html:build2("J16", $labels:J16, $labels:J16_SHORT, $J16, "All values are valid", "needs valid input", $errors:J16)}
        {html:build2("J17", $labels:J17, $labels:J17_SHORT, $J17, "All values are valid", "not valid", $errors:J17)}
        {html:build2("J18", $labels:J18, $labels:J18_SHORT, $J18, "All values are valid", "needs valid input", $errors:J18)}
        {html:build2("J19", $labels:J19, $labels:J19_SHORT, $J19, "All values are valid", "not valid", $errors:J19)}
        {html:build2("J20", $labels:J20, $labels:J20_SHORT, $J20, "All values are valid", "not valid", $errors:J20)}
        {html:build2("J21", $labels:J21, $labels:J21_SHORT, $J21, "All values are valid", "not valid", $errors:J21)}
        <!-- {html:build2Sparql("J22", $labels:J22, $labels:J22_SHORT, $J22, "All values are valid", "not valid", $errors:J22)} -->
        {html:build2("J23", $labels:J23, $labels:J23_SHORT, $J23, "All values are valid", "not valid", $errors:J23)}
        {html:build2("J24", $labels:J24, $labels:J24_SHORT, $J24, "All values are valid", "not valid", $errors:J24)}
        {html:build2("J25", $labels:J25, $labels:J25_SHORT, $J25, "All values are valid", "not valid", $errors:J25)}
        {html:build2("J26", $labels:J26, $labels:J26_SHORT, $J26, "All values are valid", "not valid", $errors:J26)}
        {html:build2Sparql("J27", $labels:J27, $labels:J27_SHORT, $J27, "All values are valid", "not valid", $errors:J27)}
        {html:build2("J28", $labels:J28, $labels:J28_SHORT, $J28, "All values are valid", "not valid", $errors:J28)}
        {html:build2("J29", $labels:J29, $labels:J29_SHORT, $J29, "All values are valid", "not valid", $errors:J29)}
        {html:build2("J30", $labels:J30, $labels:J30_SHORT, $J30, "All values are valid", "not valid", $errors:J30)}
        {html:build2("J31", $labels:J31, $labels:J31_SHORT, $J31, "All values are valid", "not valid", $errors:J31)}
        {html:build2Sparql("J32", $labels:J32, $labels:J32_SHORT, $J32, "All values are valid", "not valid", $errors:J32)}
    </table>
    <table>
     <br/>
    <caption> {$labels:TIMINGTABLEHEADER} </caption>
        <tr>
            <th>Query</th>
            <th>Process time in miliseconds</th>
            <th>Process time in seconds</th>
        </tr>
       {common:runtime("Common variables",  $ms1GeneralParameters, $ms2GeneralParameters)}
       {common:runtime("NS", $ms1NS, $ms2NS)}
       {common:runtime("VOCAB", $ms1VOCAB, $ms2VOCAB)}
       {common:runtime("VOCABALL", $ms1CVOCABALL, $ms2CVOCABALL)}
       {common:runtime("J0", $ms1J0, $ms2J0)}
       {common:runtime("J01", $ms1J01, $ms2J01)}
       {common:runtime("J02", $ms1J02, $ms2J02)}
       {common:runtime("J03", $ms1J03, $ms2J03)} 
       {common:runtime("J04", $ms1J04, $ms2J04)}
       {common:runtime("J05", $ms1J05, $ms2J05)}
       {common:runtime("J06", $ms1J06, $ms2J06)}
       {common:runtime("J07", $ms1J07, $ms2J07)}
       {common:runtime("J08", $ms1J08, $ms2J08)}
       {common:runtime("J09", $ms1J09, $ms2J09)}
       {common:runtime("J10", $ms1J10, $ms2J10)}
       {common:runtime("J11", $ms1J11, $ms2J11)}
       {common:runtime("J12", $ms1J12, $ms2J12)}
       <!-- {common:runtime("J13", $ms1J13, $ms2J13)} -->
       {common:runtime("J14", $ms1J14, $ms2J14)}
       {common:runtime("J15", $ms1J15, $ms2J15)}
       {common:runtime("J16", $ms1J16, $ms2J16)}
       {common:runtime("J17", $ms1J17, $ms2J17)}
       {common:runtime("J18", $ms1J18, $ms2J18)}
       {common:runtime("J19", $ms1J19, $ms2J19)}
       {common:runtime("J20", $ms1J20, $ms2J20)}
       {common:runtime("J21", $ms1J21, $ms2J21)}
       <!-- {common:runtime("J22", $ms1J22, $ms2J22)} -->
       {common:runtime("J23", $ms1J23, $ms2J23)}
       {common:runtime("J24", $ms1J24, $ms2J24)}
       {common:runtime("J25", $ms1J25, $ms2J25)}
       {common:runtime("J26", $ms1J26, $ms2J26)}
       {common:runtime("J27", $ms1J27, $ms2J27)}
       {common:runtime("J28", $ms1J28, $ms2J28)}
       {common:runtime("J29", $ms1J29, $ms2J29)}
       {common:runtime("J30", $ms1J30, $ms2J30)}
       {common:runtime("J31", $ms1J31, $ms2J31)}
       {common:runtime("J32", $ms1J32, $ms2J32)}
       {common:runtime("Total time",  $ms1Total, $ms2Total)}
    </table>
    </table>
)
};


declare function dataflowJ:proceed($source_url as xs:string, $countryCode as xs:string) as element(div) {

let $countZones := count(doc($source_url)//aqd:AQD_EvaluationScenario)
let $result := if ($countZones > 0) then dataflowJ:checkReport($source_url, $countryCode) else ()
let $meta := map:merge((
    map:entry("count", $countZones),
    map:entry("header", "Check air quality zones"),
    map:entry("dataflow", "Dataflow J"),
    map:entry("zeroCount", <p>No aqd:AQD_EvaluationScenario elements found in this XML.</p>),
    map:entry("report", <p>This check evaluated the delivery by executing tier-1 tests on air quality zones data in Dataflow J as specified in <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a>.</p>)
))
return
    html:buildResultDiv($meta, $result)
};

