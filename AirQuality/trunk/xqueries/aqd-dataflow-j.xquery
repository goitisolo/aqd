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

let $latestEnvelopesH := query:getLatestEnvelopesForObligation("680")
let $latestEnvelopesI := query:getLatestEnvelopesForObligation("681")
let $latestEnvelopesJ := query:getLatestEnvelopesForObligation("682")
let $latestEnvelopesK := query:getLatestEnvelopesForObligation("683")

(: NS
Check prefix and namespaces of the gml:featureCollection according to expected root elements
(More information at http://www.eionet.europa.eu/aqportal/datamodel)

Prefix/namespaces check
:)

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

(: VOCAB check:)
let $VOCABinvalid := checks:vocab($docRoot)

(: J0
Check if delivery if this is a new delivery or updated delivery (via reporting year)

Checks if this delivery is new or an update (on same reporting year)
:)

let $J0 := try {
    if ($reportingYear = "")
    then
        common:checkDeliveryReport($errors:ERROR, "Reporting Year is missing.")
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

(: J1
Compile & feedback upon the total number of plans records included in the delivery

Number of AQ Plans reported
:)

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

(: J2
Compile & feedback upon the total number of new EvaluationScenarios records included in the delivery.
ERROR will be returned if XML is a new delivery and localId are not new compared to previous deliveries.

Number of new EvaluationScenarios compared to previous report.
:)

let $J2 := try {
    for $el in $docRoot//aqd:AQD_EvaluationScenario
        let $x := $el/aqd:inspireId/base:Identifier
        let $inspireId := concat(data($x/base:namespace), "/", data($x/base:localId))
        let $ok := not($inspireId = $knownEvaluationScenarios)
        return
            common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($el/@gml:id)),
                ("aqd:inspireId", $inspireId)
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
                where query:existsViaNameLocalId($id, 'AQD_EvaluationScenario', $latestEnvelopesJ)
                return 1
        ) > 0
        )
    then
        $errors:J2
    else
        $errors:INFO

(: J3
Compile & feedback upon the total number of updated EvaluationScenarios records included in the delivery.
ERROR will be returned if XML is an update and ALL localId (100%) are different
to previous delivery (for the same YEAR).

Number of existing EvaluationScenarios compared to previous report.
ERROR will be returned if XML is an update and ALL localId (100%)
are different to previous delivery (for the same YEAR).
:)

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
                ("aqd:classification", common:checkLink(distinct-values(data($main/aqd:classification/@xlink:href))))
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

(: J4
Compile & feedback a list of the unique identifier information
for all EvaluationScenarios records included in the delivery.
Feedback report shall include the gml:id attribute, ./aqd:inspireId, ./aqd:pollutant, ./aqd:protectionTarget,

List of unique identifier information for all EvaluationScenarios records. Blocker if no EvaluationScenarios
:)

let $J4 := try {
    let $gmlIds := $docRoot//aqd:AQD_EvaluationScenario/lower-case(normalize-space(@gml:id))
    let $inspireIds := $docRoot//aqd:AQD_EvaluationScenario/lower-case(normalize-space(aqd:inspireId))
    for $x in $docRoot//aqd:AQD_EvaluationScenario
        let $id := $x/@gml:id
        let $inspireId := $x/aqd:inspireId
        let $aqdinspireId := concat($x/aqd:inspireId/base:Identifier/base:localId, "/", $x/aqd:inspireId/base:Identifier/base:namespace)
        let $ok := (count(index-of($gmlIds, lower-case(normalize-space($id)))) = 1
            and
            count(index-of($inspireIds, lower-case(normalize-space($inspireId)))) = 1
        )
        return common:conditionalReportRow(
            not($ok),
            [
                ("gml:id", data($x/@gml:id)),
                ("aqd:inspireId", distinct-values($aqdinspireId)),
                ("aqd:pollutant", data($x/aqd:pollutant)),
                ("aqd:protectionTarget", data($x/aqd:protectionTarget))
            ]
        )
} catch * {
    html:createErrorRow($err:code, $err:description)
}


(: J5 RESERVE :)

let $J5 := ()

(: J6 RESERVE :)

let $J6 := ()

(: J7
All gml:id attributes, ef:inspireId and aqd:inspireId elements shall have unique content

All gml ID attributes shall have unique code
:)

let $J7 := try {
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

(: J8
./aqd:inspireId/base:Identifier/base:localId must be unique code for the Plans records

Local Id must be unique for the EvaluationScenarios records
:)

let $J8 := try {
    let $localIds := $docRoot//aqd:AQD_EvaluationScenario/aqd:inspireId/base:Identifier/lower-case(normalize-space(base:localId))
    for $x in $docRoot//aqd:AQD_EvaluationScenario
        let $localID := $x/aqd:inspireId/base:Identifier/base:localId
        let $aqdinspireId := concat($x/aqd:inspireId/base:Identifier/base:localId, "/", $x/aqd:inspireId/base:Identifier/base:namespace)
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

(: J9
 ./aqd:inspireId/base:Identifier/base:namespace List base:namespace
 and count the number of base:localId assigned to each base:namespace.

 List unique namespaces used and count number of elements
:)

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
}

(: J10
Check that namespace is registered in vocabulary (http://dd.eionet.europa.eu/vocabulary/aq/namespace/view)

Check namespace is registered
:)

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

(: J11
aqd:AQD_EvaluationScenario/aqd:usedInPlan shall reference an existing AQD_Plan (H) document
for the same reporting year same year via namespace/localId

You must provide a reference to a plan document from data flow H via its namespace & localId.
The plan document must have the same reporting year as the source apportionment document.
:)

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
                    (node-name($el), $label)
                ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

(: J12
aqd:AQD_EvaluationScenario/aqd:sourceApportionment MUST reference an existing AQD_SourceApportionment (I) document
via namespace/localId record for the same reporting year .

You must provide a link to a Source Apportionment (I) document from data flow I
via its namespace & localId (for the same reporting year)
:)

let $J12 := try {
    for $main in $evaluationScenario
        let $el := $main/aqd:sourceApportionment
        let $label := $el/@xlink:href
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
                    (node-name($el), $label)
                ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

(: J13
aqd:AQD_EvaluationScenario/aqd:codeOfScenario should begin with with the 2-digit country code according to ISO 3166-1.

A code of the scenario should be provided as nn alpha-numeric code starting with the country ISO code
:)

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

(: J14
aqd:AQD_EvaluationScenario/aqd:publication/aqd:Publication/aqd:description shall be a text string

Short textul description of the publication should be provided. If availabel, include the ISBN number.
:)

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

(: J15
aqd:AQD_EvaluationScenario/aqd:publication/aqd:Publication/aqd:title
shall be a text string

Title as written in the publication.
:)

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

(: J16
aqd:AQD_EvaluationScenario/aqd:publication/aqd:Publication/aqd:author shall be a text string (if provided)

Author(s) should be provided as text (If there are multiple authors, please provide in one field separated by commas)
:)

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

(: J17
aqd:AQD_EvaluationScenario/aqd:publication/aqd:Publication/aqd:publicationDate/gml:TimeInstant/gml:timePosition
may be a data in yyyy or yyyy-mm-dd format

The publication date should be provided in yyyy or yyyy-mm-dd format
:)

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

(: J18
aqd:AQD_EvaluationScenario/aqd:publication/aqd:Publication/aqd:publisher
shall be a text string

Publisher should be provided as a text (Publishing institution, academic jourmal, etc.)
:)

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

(: J19
aqd:AQD_EvaluationScenario/aqd:publication/aqd:Publication/aqd:webLink
as a valid url (if provided)

Url to the published AQ Plan should be valid (if provided)
:)

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

(: J20
aqd:AQD_EvaluationScenario/aqd:attainmentYear/gml:TimeInstant/gml:timePosition must be provided and must conform to yyyy format

The year for which the projections are developed must be provided and the yyyy format used
:)

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

(: J21
aqd:AQD_EvaluationScenario/aqd:startYear/gml:TimeInstant/gml:timePosition
must be provided and must conform to yyyy format

Reference year from which the projections started and
for which the source apportionment is available must be provided. Format used yyyy.
:)

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

(: J22
Check aqd:AQD_EvaluationScenario/aqd:startYear/gml:TimeInstant/gml:timePosition must be equal to
aqd:AQD_SourceApportionment/aqd:referenceYear/gml:TimeInstant/gml:timePosition
referenced via the xlink of (aqd:AQD_EvaluationScenario/aqd:sourceApportionment)

Check if start year of the evaluation scenario is the same as
the source apportionment reference year
:)
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
                (node-name($el), $el/@xlink:href)
            ]
        )

} catch * {
    html:createErrorRow($err:code, $err:description)
}

(: J23
aqd:AQD_EvaluationScenario/aqd:baselineScenario/aqd:Scenario/aqd:description shall be a text string

A description of the emission scenario used for the baseline analysis should be provided as text
:)

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

(: J24
Check that the element aqd:AQD_EvaluationScenario/aqd:baselineScenario/aqd:Scenario/aqd:totalEmissions
is an integer or floating point numeric >= 0 and the unit (@uom) shall resolve to the codelist
http://dd.eionet.europa.eu/vocabulary/uom/emission/kt.year-1

The baseline total emissions should be provided as integer with correct unit.
:)

let $J24 := try {
    for $node in $evaluationScenario
        let $el := $node/aqd:baselineScenario/aqd:Scenario/aqd:totalEmissions
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

(: J25
Check that the element aqd:AQD_EvaluationScenario/aqd:baselineScenario/aqd:AQD_Scenario/aqd:expectedConcentration
is an integer or floating point numeric >= 0 and the unit (@uom) shall resolve to the codelist
http://dd.eionet.europa.eu/vocabulary/uom/concentration/

The expected concentration (under baseline scenario) should be provided as an integer and its unit should conform to vocabulary
:)

let $J25 := try {
    let $main := $evaluationScenario/aqd:baselineScenario/aqd:AQD_Scenario/aqd:expectedConcentration
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

(: J26
Check that the element aqd:AQD_EvaluationScenario/aqd:baselineScenario/aqd:AQD_Scenario/aqd:expectedExceedances
is an integer or floating point numeric >= 0 and the unit (@uom) shall resolve to the codelist
http://dd.eionet.europa.eu/vocabulary/uom/statistics

The number of exceecedance expected (under baseline scenario) should be provided as an integer and its unit should conform to vocabulary
:)

let $J26 := try {
    let $main := $evaluationScenario/aqd:baselineScenario/aqd:AQD_Scenario/aqd:expectedExceedances
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

(: J27
aqd:AQD_EvaluationScenario/aqd:baselineScenario/aqd:Scenario/aqd:measuresApplied
shall reference an existing AQD_Measures delivered within a data flow K
and the reporting year of K & J shall be the same year via namespace/localId.

Measures identified in the AQ-plan that are included in this baseline scenario should be provided (link to dataflow K)
:)

let $J27 := try{
    let $main := $evaluationScenario/aqd:baselineScenario/aqd:Scenario/aqd:measuresApplied
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
                    (node-name($el), $el/@xlink:href)
                ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

(: J28
aqd:AQD_EvaluationScenario/aqd:projectionScenario/aqd:Scenario/aqd:description shall be a text string

A description of the emission scenario used for the projection analysis should be provided as text
:)

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

(: J29
Check that the element aqd:AQD_EvaluationScenario/aqd:projectionScenario/aqd:Scenario/aqd:totalEmissions
is an integer or floating point numeric >= 0 and the unit (@uom) shall resolve to the codelist
http://dd.eionet.europa.eu/vocabulary/uom/emission/kt.year-1

The projection total emissions should be provided as integer with correct unit.
:)


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

(: J30
Check that the element aqd:AQD_EvaluationScenario/aqd:projectionScenario/aqd:AQD_Scenario/aqd:expectedConcentration
is an integer or floating point numeric >= 0 and the unit (@uom) shall resolve to the codelist
http://dd.eionet.europa.eu/vocabulary/uom/concentration/

The expected concentration (under projection scenario) should be provided as an integer and its unit should conform to vocabulary
:)
(:  TODO CHECK IF $main node is not empty for all CHECKS  :)
let $J30 := try {
    let $main := $evaluationScenario/aqd:projectionScenario/aqd:AQD_Scenario/aqd:expectedConcentration
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

(: J31
Check that the element aqd:AQD_EvaluationScenario/aqd:projectionScenario/aqd:AQD_Scenario/aqd:expectedExceedances
is an integer or floating point numeric >= 0 and the unit (@uom) shall resolve to the codelist
http://dd.eionet.europa.eu/vocabulary/uom/statistics

The number of exceecedance expected (under projection scenario) should be provided
as an integer and its unit should conform to vocabulary
:)

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

(: J32
aqd:AQD_EvaluationScenario/aqd:projectionScenario/aqd:Scenario/aqd:measuresApplied
shall reference an existing AQD_Measures delivered within a data flow K
and the reporting year of K & J shall be the same year via namespace/localId.

Measures identified in the AQ-plan that are included in this projection should be provided (link to dataflow K)
:)

let $J32 := try{
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
                    (node-name($el), $el/@xlink:href)
                ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

return
(
    <table class="maintable hover">
        {html:build2("NS", $labels:NAMESPACES, $labels:NAMESPACES_SHORT, $NSinvalid, "All values are valid", "record", $errors:NS)}
        {html:build2("VOCAB", $labels:VOCAB, $labels:VOCAB_SHORT, $VOCABinvalid, "All values are valid", "record", $errors:VOCAB)}
        {html:build3("J0", $labels:J0, $labels:J0_SHORT, $J0, string($J0/td), errors:getMaxError($J0))}
        {html:build1("J1", $labels:J1, $labels:J1_SHORT, $J1, "", string($countEvaluationScenario), "", "", $errors:J1)}
        {html:buildSimple("J2", $labels:J2, $labels:J2_SHORT, $J2, "", "", $J2errorLevel)}
        {html:buildSimple("J3", $labels:J3, $labels:J3_SHORT, $J3, "", "", $J3errorLevel)}
        {html:build1("J4", $labels:J4, $labels:J4_SHORT, $J4, "", string(count($J4)), " ", "", $errors:J4)}
        {html:build1("J5", $labels:J5, $labels:J5_SHORT, $J5, "RESERVE", "RESERVE", "RESERVE", "RESERVE", $errors:J5)}
        {html:build1("J6", $labels:J6, $labels:J6_SHORT, $J6, "RESERVE", "RESERVE", "RESERVE", "RESERVE", $errors:J6)}
        {html:build2("J7", $labels:J7, $labels:J7_SHORT, $J7, "No duplicate values found", " duplicate value", $errors:J7)}
        {html:build2("J8", $labels:J8, $labels:J8_SHORT, $J8, "No duplicate values found", " duplicate value", $errors:J8)}
        {html:buildUnique("J9", $labels:J9, $labels:J9_SHORT, $J9, "namespace", $errors:J9)}
        {html:build2("J10", $labels:J10, $labels:J10_SHORT, $J10, "All values are valid", " not conform to vocabulary", $errors:J10)}
        {html:build2("J11", $labels:J11, $labels:J11_SHORT, $J11, "All values are valid", "needs valid input", $errors:J11)}
        {html:build2("J12", $labels:J12, $labels:J12_SHORT, $J12, "All values are valid", "needs valid input", $errors:J12)}
        {html:build2("J13", $labels:J13, $labels:J13_SHORT, $J13, "All values are valid", " not valid", $errors:J13)}
        {html:build2("J14", $labels:J14, $labels:J14_SHORT, $J14, "All values are valid", "needs valid input", $errors:J14)}
        {html:build2("J15", $labels:J15, $labels:J15_SHORT, $J15, "All values are valid", "needs valid input", $errors:J15)}
        {html:build2("J16", $labels:J16, $labels:J16_SHORT, $J16, "All values are valid", "needs valid input", $errors:J16)}
        {html:build2("J17", $labels:J17, $labels:J17_SHORT, $J17, "All values are valid", "not valid", $errors:J17)}
        {html:build2("J18", $labels:J18, $labels:J18_SHORT, $J18, "All values are valid", "needs valid input", $errors:J18)}
        {html:build2("J19", $labels:J19, $labels:J19_SHORT, $J19, "All values are valid", "not valid", $errors:J19)}
        {html:build2("J20", $labels:J20, $labels:J20_SHORT, $J20, "All values are valid", "not valid", $errors:J20)}
        {html:build2("J21", $labels:J21, $labels:J21_SHORT, $J21, "All values are valid", "not valid", $errors:J21)}
        {html:build2("J22", $labels:J22, $labels:J22_SHORT, $J22, "All values are valid", "not valid", $errors:J22)}
        {html:build2("J23", $labels:J23, $labels:J23_SHORT, $J23, "All values are valid", "not valid", $errors:J23)}
        {html:build2("J24", $labels:J24, $labels:J24_SHORT, $J24, "All values are valid", "not valid", $errors:J24)}
        {html:build2("J25", $labels:J25, $labels:J25_SHORT, $J25, "All values are valid", "not valid", $errors:J25)}
        {html:build2("J26", $labels:J26, $labels:J26_SHORT, $J26, "All values are valid", "not valid", $errors:J26)}
        {html:build2("J27", $labels:J27, $labels:J27_SHORT, $J27, "All values are valid", "not valid", $errors:J27)}
        {html:build2("J28", $labels:J28, $labels:J28_SHORT, $J28, "All values are valid", "not valid", $errors:J28)}
        {html:build2("J29", $labels:J29, $labels:J29_SHORT, $J29, "All values are valid", "not valid", $errors:J29)}
        {html:build2("J30", $labels:J30, $labels:J30_SHORT, $J30, "All values are valid", "not valid", $errors:J30)}
        {html:build2("J31", $labels:J31, $labels:J31_SHORT, $J31, "All values are valid", "not valid", $errors:J31)}
        {html:build2("J32", $labels:J32, $labels:J32_SHORT, $J32, "All values are valid", "not valid", $errors:J32)}

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

