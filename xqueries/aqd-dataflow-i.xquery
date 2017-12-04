xquery version "3.0" encoding "UTF-8";
(:
 : Module Name: Implementing Decision 2011/850/EU: AQ info exchange & reporting (Library module)
 :
 : Version:     $Id$
 : Created:     9 November 2017
 : Copyright:   European Environment Agency
 :
 : XQuery script implements dataflow I checks.
 :
 : @author Claudia Ifrim
 :)

module namespace dataflowI = "http://converters.eionet.europa.eu/dataflowI";

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

declare variable $dataflowI:ISO2_CODES as xs:string* := ("AL","AT","BA","BE","BG","CH","CY","CZ","DE","DK","DZ","EE","EG","ES","FI",
    "FR","GB","GR","HR","HU","IE","IL","IS","IT","JO","LB","LI","LT","LU","LV","MA","ME","MK","MT","NL","NO","PL","PS","PT",
     "RO","RS","SE","SI","SK","TN","TR","XK","UK");

declare variable $dataflowI:OBLIGATIONS as xs:string* :=
    ($vocabulary:ROD_PREFIX || "681");

(: Rule implementations :)
declare function dataflowI:checkReport(
    $source_url as xs:string,
    $countryCode as xs:string
) as element(table) {

    let $docRoot := doc($source_url)
    let $cdrUrl := common:getCdrUrl($countryCode)

    let $reportingYear := common:getReportingYear($docRoot)
    let $namespaces := distinct-values($docRoot//base:namespace)

    let $latestEnvelopeByYearI := query:getLatestEnvelope($cdrUrl || "i/", $reportingYear)

    let $node-name := 'aqd:AQD_SourceApportionment'
    let $sources := $docRoot//aqd:AQD_SourceApportionment
    let $allSources := query:sparql-objects-ids($namespaces, $node-name)

    let $samplingPointAssessmentMetadata := ()
    (:
        let $results := sparqlx:run(query:getSamplingPointAssessmentMetadata())
        return distinct-values(
            for $i in $results
            return concat(
                $i/sparql:binding[@name='metadataNamespace']/sparql:literal,
                "/",
                $i/sparql:binding[@name='metadataId']/sparql:literal
            )
        )
    :)

    let $assessmentMetadata := ()
    (:
    distinct-values(
        data(
            sparqlx:run(
                query:getAssessmentMethods()
            )//concat(
                sparql:binding[@name='assessmentMetadataNamespace']/sparql:literal,
                "/",
                sparql:binding[@name='assessmentMetadataId']/sparql:literal
            )
        )
    )
    :)

    (: NS Check
    Check prefix and namespaces of the gml:featureCollection according to
    expected root elements (More information at
    http://www.eionet.europa.eu/aqportal/datamodel)

    File prefix/namespace check

    BLOCKER
    :)
    let $NSinvalid :=
        try {
            let $XQmap := inspect:static-context((), 'namespaces')
            let $fileMap := map:merge((
                for $x in in-scope-prefixes($docRoot/*)
                return map:entry($x, string(namespace-uri-for-prefix($x, $docRoot/*)))))

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

    (: I0 Check
    Check if delivery if this is a new delivery or updated delivery (via
    reporting year)

    Checks if this delivery is new or an update (on same reporting year)

    WARNING
    :)

    let $I0table :=
        try {
            if ($reportingYear = "") then
                <tr class="{$errors:ERROR}">
                    <td title="Status">Reporting Year is missing.</td>
                </tr>
            else if (query:deliveryExists($dataflowI:OBLIGATIONS, $countryCode, "i/", $reportingYear)) then
                <tr class="{$errors:WARNING}">
                    <td title="Status">Updating delivery for {$reportingYear}</td>
                </tr>
            else
                <tr class="{$errors:INFO}">
                    <td title="Status">New delivery for {$reportingYear}</td>
                </tr>
        } catch * {
            html:createErrorRow($err:code, $err:description)
        }

    let $isNewDelivery := errors:getMaxError($I0table) = $errors:INFO

    let $deliveries := sparqlx:run(
        query:sparql-objects-in-subject($cdrUrl || "g/", $node-name)
    )//sparql:binding[@name='inspireLabel']/sparql:literal

    let $latest-delivery := sparqlx:run(
        query:sparql-objects-in-subject(
            $latestEnvelopeByYearI,
            $node-name
        )
    )//sparql:binding[@name='inspireLabel']/sparql:literal

    let $knownSources :=
        if ($isNewDelivery) then
            distinct-values(data($deliveries))
        else
            distinct-values(data($latest-delivery))

    let $attainments := sparqlx:run(
        query:getAttainment($cdrUrl || "g/")
    )//sparql:binding[@name='inspireLabel']/sparql:literal

    let $latest-attainment := sparqlx:run(
        query:getAttainment($latestEnvelopeByYearI)
    )//sparql:binding[@name='inspireLabel']/sparql:literal

    let $knownAttainments :=
        if ($isNewDelivery) then
            distinct-values(data($attainments))
        else
            distinct-values(data($latest-attainment))

    (: I1

    Compile & feedback upon the total number of Source Apportionments included
    in the delivery

    Number of Source Apportionments reported
    :)
    let $countSources := count($sources)
    let $tblAllSources :=
        try {
            for $rec in $sources
            return
                <tr>
                    <td title="gml:id">{data($rec/@gml:id)}</td>
                    <td title="base:localId">{data($rec/aqd:inspireId/base:Identifier/base:localId)}</td>
                    <td title="base:namespace">{data($rec/aqd:inspireId/base:Identifier/base:namespace)}</td>
                </tr>
        }  catch * {
            html:createErrorRow($err:code, $err:description)
        }

    (: I2

    Compile & feedback upon the total number of new  Source Apportionments
    records included in the delivery. ERROR will be returned if XML is a new
    delivery and localId are not new compared to previous deliveries.

    Number of new  Source Apportionments compared to previous report. ERROR
    will be returned if XML is a new delivery and localId are not new compared
    to previous deliveries

    BLOCKER

    :)
    let $I2table :=
        try {
            for $x in $sources
            let $inspireId := concat(
                data($x/aqd:inspireId/base:Identifier/base:namespace),
                "/",
                data($x/aqd:inspireId/base:Identifier/base:localId)
            )
            where (not($inspireId = $knownSources))
            return
                <tr>
                    <td title="gml:id">{data($x/@gml:id)}</td>
                    <td title="aqd:inspireId">{$inspireId}</td>
                </tr>
        } catch * {
            html:createErrorRow($err:code, $err:description)
        }
    let $I2errorLevel :=
        if ($isNewDelivery and count(
            for $x in $sources
                let $id := $x/aqd:inspireId/base:Identifier/base:namespace
                            || "/"
                            || $x/aqd:inspireId/base:Identifier/base:localId
            where ($allSources = $id)
            return 1) > 0) then
                $errors:I2
            else
                $errors:INFO

    (: I3

    Compile & feedback upon the total number of updated Source Apportionments
    included in the delivery. ERROR will be returned if XML is an update and
    ALL localId (100%) are different to previous delivery (for the same YEAR).

    Number of existing Plans compared to previous report. ERROR will be
    returned if XML is an update and ALL localId (100%) are different to
    previous delivery (for the same YEAR).

    BLOCKER

    TODO: please check

    - :)
    let $I3table :=
        try {
            for $x in $sources
            let $inspireId := data($x/aqd:inspireId/base:Identifier/base:namespace)
                                ||  "/"
                                || data($x/aqd:inspireId/base:Identifier/base:localId)
            where ($inspireId = $knownSources)
            return
                <tr>
                    <td title="gml:id">{data($x/@gml:id)}</td>
                    <td title="aqd:inspireId">{$inspireId}</td>
                </tr>
        } catch * {
            html:createErrorRow($err:code, $err:description)
        }
    let $I3errorLevel :=
        if (not($isNewDelivery) and count($I3table) = 0) then
            $errors:I3
        else
            $errors:INFO

    (: I4

    Compile & feedback a list of the unique identifier information for all
    Source Apportionments records included in the delivery. Feedback report
    shall include the:

    * gml:id attribute,
    * ./aqd:inspireId,
    * aqd:AQD_Plan (via ./usedInPlan),
    * aqd:AQD_Attainment (via aqd:parentExceedanceSituation),
    * aqd:pollutant (via Attainment link under aqd:parentExceedanceSituation)

    List of unique identifier information for all Source Apportionments
    records. Error, if no SA(s)

    BLOCKER

    :)
    let $I4table :=
        try {
            let $gmlIds := $sources/lower-case(normalize-space(@gml:id))
            let $inspireIds := $sources/lower-case(normalize-space(aqd:inspireId))

            for $x in $sources
                let $id := $x/@gml:id
                let $inspireId := $x/aqd:inspireId
                let $aqdinspireId := concat($x/aqd:inspireId/base:Identifier/base:localId, "/", $x/aqd:inspireId/base:Identifier/base:namespace)
                let $one-gmlid := count(index-of($gmlIds, lower-case(normalize-space($id)))) = 1
                let $one-inspireid := count(index-of($inspireIds, lower-case(normalize-space($inspireId)))) = 1

                let $att-url := $x/aqd:parentExceedanceSituation/@xlink:href
                let $pollutant-code := query:get-pollutant-for-attainment($att-url)
                let $pollutant := dd:getNameFromPollutantCode($pollutant-code)

            where $one-gmlid and $one-inspireid
            return
                <tr>
                    <td title="gml:id">
                        {distinct-values($x/@gml:id)}
                    </td>
                    <td title="aqd:inspireId">
                        {distinct-values($aqdinspireId)}
                    </td>
                    <td title="aqd:usedInPlan">
                        {common:checkLink(distinct-values(data($x/aqd:usedInPlan/@xlink:href)))}
                    </td>
                    <td title="aqd:parentExceedanceSituation">
                        {common:checkLink(distinct-values(data($att-url)))}
                    </td>
                    <td title="aqd:pollutant">{$pollutant}</td>
                </tr>
        } catch * {
            html:createErrorRow($err:code, $err:description)
        }

    (: I5 reserved :)
    let $I5 := ()

    (: I6 reserved :)
    let $I6 := ()

    (: I7

    All gml:id attributes, ef:inspireId and aqd:inspireId elements shall have
    unique content

    All gml ID attributes shall have unique code

    BLOCKER

    :)
    let $I7 := try {
        let $checks := ('gml:id', 'aqd:inspireId', 'ef:inspireId')

        let $errors := array {

            for $name in $checks
                let $name := lower-case(normalize-space($name))
                let $values := $sources//(*[lower-case(normalize-space(name())) = $name] |
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

    (: I8

    ./aqd:inspireId/base:Identifier/base:localId must be unique code for the
    Plans records

    Local Id must be unique for the Plans records

    BLOCKER
    :)
    let $I8invalid:= try {
        let $localIds := $sources/aqd:inspireId/base:Identifier/lower-case(normalize-space(base:localId))
        for $x in $sources
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


    (: I9

    ./aqd:inspireId/base:Identifier/base:namespace

    List base:namespace and count the number of base:localId assigned to each
    base:namespace.

    List unique namespaces used and count number of elements

    BLOCKER
    :)

    let $I9table := try {
        for $namespace in distinct-values($sources/aqd:inspireId/base:Identifier/base:namespace)
            let $localIds := $sources/aqd:inspireId/base:Identifier[base:namespace = $namespace]/base:localId
            let $ok := false()
            return common:conditionalReportRow(
                $ok,
                [
                    ("base:namespace", $namespace),
                    ("base:localId count", count($localIds))
                ]
            )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    (: I10

    Check that namespace is registered in vocabulary
    (http://dd.eionet.europa.eu/vocabulary/aq/namespace/view)

    Check namespace is registered

    ERROR
    :)

    let $I10invalid := try {

        let $vocDoc := doc($vocabulary:NAMESPACE || "rdf")
        let $concept := $vocDoc//skos:Concept[
            adms:status/@rdf:resource = $dd:VALIDRESOURCE
            and
            @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)
        ]
        let $prefLabel := $concept/skos:prefLabel[1]
        let $altLabel := $concept/skos:altLabel[1]

        for $x in distinct-values($docRoot//base:namespace)
            let $ok := ($x = $prefLabel and $x = $altLabel)
            return common:conditionalReportRow(
                $ok,
                [
                    ("base:namespace", $x)
                ]
            )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    (: I11

    aqd:AQD_SourceApportionment/aqd:usedInPlan shall reference an existing
    H document for the same reporting year same year via namespace/localId

    You must provide a reference to a plan document from data flow H via its
    namespace & localId. The plan document must have the same reporting year as
    the source apportionment document.

    BLOCKER
    :)
    let $I11 := try{
        for $el in $sources/aqd:usedInPlan

            let $label := data($el/@xlink:href)
            let $ok := query:existsViaNameLocalIdYear(
                $label,
                'AQD_Plan',
                $reportingYear
            )

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($el/../@gml:id)),
                ("aqd:usedInPlan", $el/@xlink:href)
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }


    (: I11b

    aqd:AQD_SourceApportionment/aqd:parentExceedanceSituation shall reference
    an existing exceedance situation delivered within a data flow G and the
    reporting year of G & I shall be the same year via namespace/localId.

    You must provide a reference to an exceedance situation from data flow G.
    The exceedance situation must have the same reporting year as the source
    apportionment and refer to the same pollutant.

    BLOCKER
    :)
    let $I12 := try{
        for $node in $sources/aqd:parentExceedanceSituation
            let $link := data($node/@xlink:href)

            let $ok := query:existsViaNameLocalIdYear(
                    $link,
                    'AQD_Attainment',
                    $reportingYear
            )

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                (node-name($node), $node/@xlink:href)
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    (: I13

    aqd:AQD_SourceApportionment/aqd:referenceYear/gml:TimeInstant/gml:timePosition
    shall be a calendar year in yyyy format

    Reference year must be a calendar year in yyyy format

    BLOCKER
    :)

    let $I13 := try {
        for $node in $sources
            let $el := $node/aqd:referenceYear/gml:TimeInstant/gml:timePosition
            let $ok := data($el) castable as xs:gYear

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                ("gml:timePosition", data($el))
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    (: I13, I14 are missing in xls file :)

    (: I15

    Across all the delivery, check that the element
    aqd:QuantityCommented/aqd:quantity is
    * an integer or
    * floating point numeric >= 0
    if attribute xsi:nil="false"
    (example:
        <aqd:quantity uom="http://dd.eionet.europa.eu/vocabulary/uom/concentration/ug.m-3" xsi:nil="false">4.03038</aqd:quantity>
    )

    Source apportionments should be provided as an integer

    BLOCKER
    :)
    let $I15 := try {

        for $node in $sources//aqd:QuantityCommented/aqd:quantity[@xsi:nil="false"]
            let $ok := common:is-a-number(data($node))

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                (node-name($node), data($node))
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    (: I16

    Across all the delivery, check that the element
    aqd:QuantityCommented/aqd:quantity is empty
    if attribute xsi:nil="unpopulated" or "unknown" or "withheld"
    (example:
    <aqd:quantity uom="Unknown" nilReason="Unpopulated" xsi:nil="true"/>
    )

    If quantification is either "unpopulated" or "unknown" or "withheld",
    the element should be empty

    BLOCKER
    :)

    let $I16 := try {
        for $node in $docRoot//aqd:QuantityCommented/aqd:quantity
            let $reason := $node/@nilReason
            let $isnil := lower-case($node/@xsi:nil) = "true"
            let $unpop := lower-case($reason) = ("unknown", "unpopulated", "withheld")

            let $ok :=
                if ($isnil)
                then
                    functx:all-whitespace($node) and $unpop
                else
                    true()

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                ("aqd:quantity", data($node)),
                ("nilReason", data($node/@nilReason))
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    (: I17

    Across all the delivery, If aqd:QuantityCommented/aqd:quantity attribute
    xsi:nil="true" aqd:QuantityCommented/aqd:comment must be populated

    If the quantification is voided an explanation is required in aqd:comment

    ERROR
    :)

    let $I17 := try {
        for $node in $docRoot//aqd:QuantityCommented
            let $isnil := $node/aqd:quantity[@xsi:nil = "true"]
            let $hascomment := common:has-content($node/aqd:comment)

            let $ok :=
                if ($isnil)
                then
                    $hascomment
                else
                    true()

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                ("needs comment", node-name($node/..))
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }


    (: I18

    Across all the delivery, check that the unit attribute
    (.../aqd:QuantityCommented/aqd:quantity@uom)
    corresponds to the recommended unit (via vocabulary) of the
    pollutant found at aqd:AQD_Attainment/aqd:pollutant xlink:href attribute
    for the
    AQD_Attainment record cited by ./aqd:parentExceedanceSituation

    The unit of measurement of the Source Apportioment must match recommended
    unit for the pollutant

    BLOCKER
    :)

    let $I18 := try {
        for $quant in $sources//aqd:QuantityCommented/aqd:quantity

            let $uom := data($quant/@uom)

            let $node := $quant/ancestor::aqd:AQD_SourceApportionment
            let $att-url := data($node/aqd:parentExceedanceSituation/@xlink:href)
            let $pollutant-code := query:get-pollutant-for-attainment($att-url)
            let $pollutant := dd:getNameFromPollutantCode($pollutant-code)
            let $rec-uom := dd:getRecommendedUnit($pollutant-code)

            let $ok := $uom = $rec-uom

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/@gml:id)),
                (node-name($quant), $uom),
                ('recommended', $rec-uom)
            ]
        )

    } catch * {
        html:createErrorRow($err:code, $err:description)
    }


    (: I19

    aqd:AQD_SourceApportionment/aqd:regionalBackground/aqd:RegionalBackground/aqd:total/aqd:QuantityCommented/aqd:quantity
    must equal to the sum of
    aqd:regionalBackground/aqd:RegionalBackground/aqd:fromWithinMS/aqd:QuantityCommented/aqd:quantity
    + aqd:regionalBackground/aqd:RegionalBackground/aqd:transboundary/aqd:QuantityCommented/aqd:quantity
    + aqd:regionalBackground/aqd:RegionalBackground/aqd:natural/aqd:QuantityCommented/aqd:quantity
    + aqd:regionalBackground/aqd:RegionalBackground/aqd:other/aqd:QuantityCommented/aqd:quantity

    The total regional background source contribution must be equal to the sum
    of its components.

    BLOCKER

    :)

    let $I19 := try {
        for $x in $sources
            let $rb := $x/aqd:regionalBackground/aqd:RegionalBackground
            let $quantity := $rb/aqd:total/aqd:QuantityCommented/aqd:quantity
            let $total := data($quantity)

            let $fwm := $rb/aqd:fromWithinMS/aqd:QuantityCommented/aqd:quantity
            let $trans := $rb/aqd:transboundary/aqd:QuantityCommented/aqd:quantity
            let $natural := $rb/aqd:natural/aqd:QuantityCommented/aqd:quantity
            let $other := $rb/aqd:other/aqd:QuantityCommented/aqd:quantity

            let $sum := common:sum-of-nodes((
                $fwm,
                $trans,
                $natural,
                $other
            ))

            let $ok := $sum = $total

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($x/@gml:id)),
                (node-name($quantity), $total),
                ("Sum of nodes", $sum),
                ('aqd:fromWithinMS', data($fwm)),
                ('aqd:transboundary', data($trans)),
                ('aqd:natural', data($natural)),
                ('aqd:other', data($other))
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    (: I20

    aqd:AQD_SourceApportionment/aqd:urbanBackground/aqd:UrbanBackground/aqd:total/aqd:QuantityCommented/aqd:quantity
    must equal the sum of
      aqd:urbanBackground/aqd:UrbanBackground/aqd:traffic/aqd:QuantityCommented/aqd:quantity
    + aqd:urbanBackground/aqd:UrbanBackground/aqd:heatAndPowerProduction/aqd:QuantityCommented/aqd:quantity
    + aqd:urbanBackground/aqd:UrbanBackground/aqd:agriculture/aqd:QuantityCommented/aqd:quantity
    + aqd:urbanBackground/aqd:UrbanBackground/aqd:commercialAndResidential/aqd:QuantityCommented/aqd:quantity
    + aqd:urbanBackground/aqd:UrbanBackground/aqd:shipping/aqd:QuantityCommented/aqd:quantity
    + aqd:urbanBackground/aqd:UrbanBackground/aqd:offRoadMobileMachinery/aqd:QuantityCommented/aqd:quantity
    + aqd:urbanBackground/aqd:UrbanBackground/aqd:natural/aqd:QuantityCommented/aqd:quantity
    + aqd:urbanBackground/aqd:UrbanBackground/aqd:transboundary/aqd:QuantityCommented/aqd:quantity
    + aqd:urbanBackground/aqd:UrbanBackground/aqd:other/aqd:QuantityCommented/aqd:quantity

    The total urban background source contribution must be equal to the sum of its components.

    BLOCKER

    :)

    let $I20 := try {
        for $x in $sources
            let $ub := $x/aqd:urbanBackground/aqd:UrbanBackground
            let $quantity := $ub/aqd:total/aqd:QuantityCommented/aqd:quantity
            let $total := data($quantity)

            let $trafic := $ub/aqd:traffic/aqd:QuantityCommented/aqd:quantity
            let $head := $ub/aqd:heatAndPowerProduction/aqd:QuantityCommented/aqd:quantity
            let $agr := $ub/aqd:agriculture/aqd:QuantityCommented/aqd:quantity
            let $comer := $ub/aqd:commercialAndResidential/aqd:QuantityCommented/aqd:quantity
            let $ship := $ub/aqd:shipping/aqd:QuantityCommented/aqd:quantity
            let $offroad := $ub/aqd:offRoadMobileMachinery/aqd:QuantityCommented/aqd:quantity
            let $natural := $ub/aqd:natural/aqd:QuantityCommented/aqd:quantity
            let $transb := $ub/aqd:transboundary/aqd:QuantityCommented/aqd:quantity
            let $other := $ub/aqd:other/aqd:QuantityCommented/aqd:quantity

            let $sum := common:sum-of-nodes((
                $trafic,
                $head,
                $agr,
                $comer,
                $ship,
                $offroad,
                $natural,
                $transb,
                $other
            ))

            let $ok := $total = $sum

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($x/@gml:id)),
                (node-name($quantity), $total),
                ("Sum of nodes", $sum),
                ("aqd:traffic", data($trafic)),
                ("aqd:heatAndPowerProduction", data($head)),
                ("aqd:agriculture", data($agr)),
                ("aqd:commercialAndResidential", data($comer)),
                ("aqd:shipping", data($ship)),
                ("aqd:offRoadMobileMachinery", data($offroad)),
                ("aqd:natural", data($natural)),
                ("aqd:transb", data($transb)),
                ("aqd:other", data($other))
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    (: I21

    aqd:AQD_SourceApportionment/aqd:localIncrement/aqd:LocalIncrement/aqd:total/aqd:QuantityCommented/aqd:quantity
    must equal to the sum of
    aqd:localIncrement/aqd:LocalIncrement/aqd:traffic/aqd:QuantityCommented/aqd:quantity
    + aqd:localIncrement/aqd:LocalIncrement/aqd:heatAndPowerProduction/aqd:QuantityCommented/aqd:quantity
    + aqd:localIncrement/aqd:LocalIncrement/aqd:agriculture/aqd:QuantityCommented/aqd:quantity
    + aqd:localIncrement/aqd:LocalIncrement/aqd:commercialAndResidential/aqd:QuantityCommented/aqd:quantity
    + aqd:localIncrement/aqd:LocalIncrement/aqd:shipping/aqd:QuantityCommented/aqd:quantity
    + aqd:localIncrement/aqd:LocalIncrement/aqd:offRoadMobileMachinery/aqd:QuantityCommented/aqd:quantity
    + aqd:localIncrement/aqd:LocalIncrement/aqd:natural/aqd:QuantityCommented/aqd:quantity
    + aqd:localIncrement/aqd:LocalIncrement/aqd:transboundary/aqd:QuantityCommented/aqd:quantity
    + aqd:localIncrement/aqd:LocalIncrement/aqd:other/aqd:QuantityCommented/aqd:quantity

    The total local increment source contribution must be equal to the sum of
    its components.

    BLOCKER

    :)

    let $I21 := try {
        for $x in $sources
            let $li := $x/aqd:localIncrement/aqd:LocalIncrement
            let $quantity := $li/aqd:total/aqd:QuantityCommented/aqd:quantity
            let $total := data($quantity)
            let $sum := common:sum-of-nodes((
                $li/aqd:heatAndPowerProduction/aqd:QuantityCommented/aqd:quantity,
                $li/aqd:agriculture/aqd:QuantityCommented/aqd:quantity,
                $li/aqd:commercialAndResidential/aqd:QuantityCommented/aqd:quantity,
                $li/aqd:shipping/aqd:QuantityCommented/aqd:quantity,
                $li/aqd:offRoadMobileMachinery/aqd:QuantityCommented/aqd:quantity,
                $li/aqd:natural/aqd:QuantityCommented/aqd:quantity,
                $li/aqd:transboundary/aqd:QuantityCommented/aqd:quantity,
                $li/aqd:other/aqd:QuantityCommented/aqd:quantity
            ))
            let $ok := $total = $sum

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($x/@gml:id)),
                (node-name($quantity), $total),
                ("Sum of nodes", $sum)
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }



    (: I22

    aqd:AQD_SourceApportionment/aqd:macroExceedanceSituation must be presented
    and must not be an empty tag

    The macro exceedance situation relevant to the source apportionment must be
    populated

    Blocker

    :)

    let $I22 := try {
        for $node in $sources
            let $ok := exists($node/aqd:macroExceedanceSituation)
        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/@gml:id)),
                ('aqd:macroExceedanceSituation',
                    data($node/aqd:macroExceedanceSituation))
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }


    (: I23

    Either
    aqd:AQD_SourceApportionment/aqd:macroExceedanceSituation/aqd:numericalExceedance
    OR
    aqd:AQD_SourceApportionment/aqd:macroExceedanceSituation/aqd:numberExceedances
    must be provided (just one or the other) AS an integer or floating point
    numeric > 0, no more that 2 decimal places expected

    numericalExceedance or numberExceedances must be provided

    ERROR

    :)
    let $I23 := try {

        for $node in $sources/aqd:macroExceedanceSituation
            let $a := data($node//aqd:numericalExceedance)
            let $b := data($node//aqd:numberExceedances)
            let $ok := common:is-a-number($a) or common:is-a-number($b)

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                ('aqd:numericalExceedance', $a),
                ('aqd:numberExceedances', $b)
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    (: I24

    The content of
    /aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:areaClassification
    xlink:xref must be provided and must resolve to a areaClassification in
    http://dd.eionet.europa.eu/vocabulary/aq/areaclassification/

    Area Classification is mandatory and must conform to vocabulary

    BLOCKER

    :)
    let $I24 := try {
        for $el in $sources/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:areaClassification
            let $uri := $el/@xlink:href
            return
            if (not(common:isInVocabulary($uri, $vocabulary:AREA_CLASSIFICATION_VOCABULARY)))
            then
                <tr>
                    <td title="gml:id">{data($el/../../../../../@gml:id)}</td>
                    <td title="xlink:href"> {$el/@xlink:href}</td>
                    <td title="{node-name($el)}">not conform to vocabulary</td>
                </tr>
            else
                ()
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    (: I25

        aqd:AQD_SourceApportionment/
        aqd:macroExceedanceSituation/
        aqd:ExceedanceDescription/
        aqd:exceedanceArea/
        aqd:ExceedanceArea/
        aqd:areaClassification
    xlink:href attribute shall match those
        /aqd:AQD_Attainment/
        aqd:exceedanceDescriptionFinal/
        aqd:ExceedanceDescription/
        aqd:exceedanceArea/
        aqd:ExceedanceArea/
        aqd:areaClassification
    xlink:href attribute for the AQD_Attainment record cited by
        ./aqd:parentExceedanceSituation

    Area classification should match classification declared in the
    corresponding Attainment

    WARNING

    TODO: check get-area-classifications-for-attainment, it returns a list
    because of how it gets Attainments
    See comments on ticket https://taskman.eionet.europa.eu/issues/89179

    :)

    let $I25 := try {
        for $node in $sources
            let $el := $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:areaClassification
            let $ac := data($el/@xlink:href)
            let $parent := $node/aqd:parentExceedanceSituation/@xlink:href
            let $parent-ac := query:get-area-classifications-for-attainment($parent)

            let $ok := $ac = $parent-ac

        return common:conditionalReportRow(
            $ok,
            [
                (node-name($node), data($node/@gml:id)),
                (node-name($el), $ac),
                ('AQD_Attainment classification', $parent-ac)
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    (: I26
    /aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:surfaceArea
    uom attribute shall resolve to
    http://dd.eionet.europa.eu/vocabulary/uom/area/km2

    Exceedence area uom attribute must be in Square kilometers.

    ERROR
    :)

    let $I26 := try {
        for $node in $sources
            let $area := $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:surfaceArea
            let $uom := string($area/@uom)
            let $ok :=
                if (exists($area))
                    then $uom eq "http://dd.eionet.europa.eu/vocabulary/uom/area/km2"
                else
                    true()
        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/@gml:id)),
                ("uom", $uom),
                (node-name($area), data($area))
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    (: I27

    /aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:roadLength
    uom attribute shall be http://dd.eionet.europa.eu/vocabulary/uom/length/km

    Exceedence area uom attribute must be in Square kilometers.

    ERROR
    :)
    let $I27 := try {
        for $node in $sources
            let $length := $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:roadLength
            let $uom := $length/@uom
            let $ok :=
                if (exists($length))
                then
                    $uom = "http://dd.eionet.europa.eu/vocabulary/uom/length/km"
                else
                    true()
        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/@gml:id)),
                ("uom", $uom)
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    (: I28 is missing in XLS :)
    let $I28 := ()

    (: I29

    ./aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationUsed
    OR
    ./aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed
    must be populated

    A link to the exceeding SamplingPoint(s) and/or Model(s) must be provided
    [at least one]

    ERROR

    :)
    let $I29 := try {
        for $node in $sources
            let $area := $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea
            let $st := common:has-content($area/aqd:stationUsed)
            let $mu := common:has-content($area/aqd:modelUsed)
            let $ok := $st or $mu
        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/@gml:id)),
                ("aqd:stationUsed", $area/aqd:stationUsed/@xlink:href),
                ("aqd:modelUsed", $area/aqd:modelUsed/@xlink:href)
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    (: I30

    If, aqd:stationUsed and/or aqd:modelUsed are populated,
    these must be valid elements:

    stationUsed must link To SamplingPoint via namespace/localid
    modelUsed must link to AQD_Model via namespace/ localid

    If SamplingPoint(s) and/or Model(s) are provided, these must be valid

    TODO: double check the existsViaNameLocalId

    ERROR
    :)
    let $I30 := try {
        for $node in $sources
            let $a := $node//aqd:stationUsed
            let $a-ok :=
                if (exists($a/@xlink:href))
                then
                    query:existsViaNameLocalId($a/@xlink:href, "AQD_SamplingPoint")
                else
                    true()

            let $b := $node//aqd:modelUsed
            let $b-ok :=
                if (exists($b/@xlink:href))
                then
                    query:existsViaNameLocalId($b/@xlink:href, "AQD_Model")
                else
                    true()

            let $ok := $a-ok and $b-ok

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/@gml:id)),
                ("aqd:stationUsed", $a/@xlink:href),
                ("aqd:modelUsed", $b/@xlink:href)
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    (: I31

    The subject of
        ./aqd:macroExceedanceSituation
        /aqd:ExceedanceDescription
        /aqd:exceedanceArea
        /aqd:ExceedanceArea
        /aqd:modelUsed
    xlink:href attribute shall be found in
        /aqd:AQD_Attainment
        /aqd:exceedanceDescriptionFinal
        /aqd:ExceedanceDescription
        /aqd:exceedanceArea
        /aqd:ExceedanceArea
        /aqd:modelUsed
    xlink:href attribute for the AQD_Attainment record cited by
    ./aqd:parentExceedanceSituation

    The exceeding AQ_Model must be included in the corresponding Attainment

    Similar to G74. However, G74 checks against C and I31 should check against
    G instead

    WARNING

    TODO: check implementation

    :)

    let $I31 := try {
        for $node in $sources
            let $mu := $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed
            let $att-url := $node/aqd:parentExceedanceSituation/@xlink:href
            let $model := query:get-used-model-for-attainment($att-url)
            let $ok :=
                if (exists($mu))
                then
                    $mu/@xlink:href = $model
                else
                    true()
        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                (node-name($mu), $mu/@xlink:href),
                ("parentExceedanceSituation", $att-url),
                ("found model", $model)
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }


    (: I32

    TODO: original description was wrong in XLS, it was assumed this is correct

    The subject of
        ./aqd:macroExceedanceSituation
        /aqd:ExceedanceDescription
        /aqd:exceedanceArea
        /aqd:ExceedanceArea
        /aqd:stationUsed
    xlink:href attribute shall be found in
        /aqd:AQD_Attainment
        /aqd:exceedanceDescriptionFinal
        /aqd:ExceedanceDescription
        /aqd:exceedanceArea
        /aqd:ExceedanceArea
        /aqd:stationUsed
    xlink:href attribute for the AQD_Attainment record cited by ./aqd:parentExceedanceSituation

    The exceeding SamplingPoint must be included in the corresponding Attainment

    Similar to G76. However, G76 checks against C and I31 should check against
    G instead

    WARNING
    TODO: check implementation
    :)

    let $I32 := try {

        for $mu in $sources/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed
            let $node := $mu/ancestor-or-self::aqd:AQD_SourceApportionment
            let $att-url := $node/aqd:parentExceedanceSituation/@xlink:href
            let $station := query:get-used-station-for-attainment($att-url)
            let $ok := $mu/@xlink:href = $station

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                (node-name($mu), $mu/@xlink:href),
                ("used station", $station)
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }


    (: I33

    ./aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:spatalExtent
    OR
    ./aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:administrativeUnit
    shall be populated

    Spatial extent or administrative unit may be provided

    RESERVE

    :)
    let $I33 := try {
        for $node in $sources
            let $area := $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea

            let $a := $area/aqd:spatialExtent
            let $b := $area/aqd:administrativeUnit

            let $ok := common:has-content($a) or common:has-content($b)

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                ('aqd:spatialExtent', data($a)),
                ('aqd:administrativeUnit', data($b))
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    (: I34

    ./aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:surfaceArea
    OR
    ./aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:roadLength
    shall be populated

    Information on surface are or road lenght shall be provided

    RESERVE
    :)

    let $I34 := try {
        for $node in $sources
            let $area := $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea
            let $a := $area/aqd:surfaceArea
            let $b := $area/aqd:roadLength
            let $ok := common:has-content($a) or common:has-content($b)
        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                ('aqd:surfaceArea', data($a)),
                ('aqd:roadLength', data($b))
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    (: I35
    WHERE
    ./aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedance
    shall EQUAL “true”
    /aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:populationExposed
    shall be populated

    If exceedance is TRUE, information on population exposed must be provided

    RESERVE

    :)

    let $I35 := try {
        for $node in $sources
            let $a := $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedance
            let $b := $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:populationExposed

            let $ok :=
                if (data($a) = "true")
                then
                    common:has-content($b)
                else
                    true()

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                (node-name($a), data($a)),
                ('aqd:populationExposed', data($b))
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    (: I36

    /aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:ecosystemAreaExposed
    shall be populated

    If exceedance is TRUE, information on area exposed must be provided

    RESERVE

    :)

    let $I36 := try {
        for $node in $sources
            let $a := $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedance
            let $b := $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:ecosystemAreaExposed
            let $ok :=
                if (data($a) = "true")
                then
                    common:has-content($b)
                else
                    true()
        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                (node-name($a), data($a)),
                ('aqd:ecosystemAreaExposed', data($b))
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }


    (: I37

    aqd:AQD_SourceApportionment/
    aqd:macroExceedanceSituation/
    aqd:ExceedanceDescription/
    aqd:exceedanceExposure/
    aqd:ExceedanceExposure/
    aqd:referenceYear/
    gml:TimeInstant/
    gml:timePosition

    shall be a calendar year in yyyy format

    Reference year for the population/exposure data in yyyy format

    ERROR

    :)
    let $I37 := try {
        for $node in $sources/
                aqd:macroExceedanceSituation/
                aqd:ExceedanceDescription/
                aqd:exceedanceExposure/
                aqd:ExceedanceExposure/
                aqd:referenceYear/
                gml:TimeInstant/
                gml:timePosition

            let $ok := data($node) castable as xs:gYear

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                ('gml:timePosition', data($node))
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    (: I38

    aqd:AQD_SourceApportionment/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:reason
    shall conform to vocabulary
    http://dd.eionet.europa.eu/vocabulary/aq/exceedancereason/

    Exceedance reason must match vocabulary

    ERROR

    :)
    let $I38 := try {
        for $node in $sources/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:reason
            let $link := $node/@xlink:href
            let $ok := common:isInVocabulary(
                $link,
                $vocabulary:EXCEEDANCEREASON_VOCABULARY
            )
        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                ('aqd:reason', $link)
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }


    (: I39
    /aqd:AQD_SourceApportionment/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod
    may be populated if ./aqd:pollutant xlink:href attribute EQUALs
    http://dd.eionet.europa.eu/vocabulary/aq/pollutant/[1,5,10,6001]  (via
    …/aqd:parentExceedanceSituation)

    If the pollutant is SO2, PM10, PM2.5 or CO deduction assessment methods may
    be populated

    RESERVE
    :)

    let $I39 := try {
        for $node in $sources
            let $el := $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod
            let $parent := $node/aqd:parentExceedanceSituation/@xlink:href
            let $pollutant := query:get-pollutant-for-attainment($parent)
            let $needed := common:is-polutant-air($pollutant)
            let $ok :=
                if (not($needed))
                then
                    true()
                else
                    $needed and common:has-content($el)
        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                (node-name($el), data($el)),
                ('pollutant', $pollutant),
                ('needed', $needed)
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }


    (: I40

    WHERE ./aqd:pollutant xlink:href attribute EQUALs
    http://dd.eionet.europa.eu/vocabulary/aq/pollutant/[1,5,10,6001]  (via
    …/aqd:parentExceedanceSituation),
    /aqd:AQD_SourceApportionment/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods/aqd:assessmentType
    must conform to http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype.

    If the pollutant is SO2, PM10, PM2.5 or CO a link to assessment type is
    expected

    BLOCKER
    :)

    let $I40 := try {
        for $node in $sources
            let $parent := $node/aqd:parentExceedanceSituation/@xlink:href
            let $pollutant := query:get-pollutant-for-attainment($parent)
            let $needed := common:is-polutant-air($pollutant)
            let $el := $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods/aqd:assessmentType
            let $link := $el/@xlink:href
            let $ok :=
                if (not($needed))
                then
                    true()
                else
                    common:isInVocabulary(
                        $link,
                        $vocabulary:ASSESSMENTTYPE_VOCABULARY
                    )
        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                (node-name($el), $link)
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }


    (: I41
    WHERE ./aqd:pollutant xlink:href attribute EQUALs
    http://dd.eionet.europa.eu/vocabulary/aq/pollutant/[1,5,10,6001]  (via
    …/aqd:parentExceedanceSituation),
    /aqd:AQD_SourceApportionment/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods/aqd:assessmentTypeDescription
    must be populated.

    If the pollutant is SO2, PM10, PM2.5 or CO a Description of the assessment
    type is expected

    ERROR
    :)

    let $I41 := try {
        for $node in $sources
            let $el := $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods/aqd:assessmentTypeDescription
            let $parent := $node/aqd:parentExceedanceSituation/@xlink:href
            let $pollutant := query:get-pollutant-for-attainment($parent)
            let $needed := common:is-polutant-air($pollutant)
            let $ok :=
                if (not($needed))
                then
                    true()
                else
                    $needed and common:has-content($el)
        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                (node-name($node), data($node))
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }


    (: I42

    WHERE

        ./aqd:pollutant xlink:href attribute EQUALs http://dd.eionet.europa.eu/vocabulary/aq/pollutant/[1,5,10,6001]

    (via …/aqd:parentExceedanceSituation),

    at least one of
        /aqd:AQD_SourceApportionment/
        aqd:macroExceedanceSituation/
        aqd:ExceedanceDescription/
        aqd:deductionAssessmentMethod/
        aqd:AdjustmentMethod/
        aqd:assessmentMethod/
        aqd:AssessmentMethods/
        aqd:samplingPointAssessmentMetadata/@xlink:href

    or

        /aqd:AQD_SourceApportionment/
        aqd:macroExceedanceSituation/
        aqd:ExceedanceDescription/
        aqd:deductionAssessmentMethod/
        aqd:AdjustmentMethod/
        aqd:assessmentMethod/
        aqd:AssessmentMethods/
        aqd:modelAssessmentMetadata/@xlink:href

    must be populated and correctly link to D/D1b.

    Cross check the links provided against D, all assessment methods must exist
    in D

    If the pollutant is SO2, PM10, PM2.5 or CO a link to the assessment method
    in D or D1b is required via xlink:href attribute

    ERROR

    TODO: check implementation. The implementation has not been check properly

    TODO: $samplingPointAssessmentMetadata and $assessmentMetadata are not
    filled in
    :)

    let $I42 := try {
        for $node in $sources/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods

            let $a := $node/aqd:samplingPointAssessmentMetadata
            let $a-m := $a/@xlink:href
            let $a-ok := common:has-content($a-m)
            (: TODO: this implements the "correctly link in D/D1b :)
            (: and ($a-m = $samplingPointAssessmentMetadata) :)

            let $b := $node/aqd:modelAssessmentMetadata
            let $b-m := $b/@xlink:href
            let $b-ok := common:has-content($b-m)
            (: TODO: this implements the "correctly link in D/D1b :)
            (: and ($b-m = $assessmentMetadata) :)

            let $parent := $node/ancestor::aqd:AQD_SourceApportionment/aqd:parentExceedanceSituation/@xlink:href
            let $pollutant := query:get-pollutant-for-attainment($parent)
            let $needed := common:is-polutant-air($pollutant)

            let $ok :=
                if (not($needed))
                then
                    true()
                else
                    $a-ok or $b-ok
        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                ("aqd:samplingPointAssessmentMetadata", $a-m),
                ("aqd:modelAssessmentMetadata", $b-m)
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    (: I43

    WHERE ./aqd:pollutant xlink:href attribute does NOT EQUAL
    http://dd.eionet.europa.eu/vocabulary/aq/pollutant/[1,5,10,6001]
    (via …/aqd:parentExceedanceSituation),
    the following elments must be empty or not provided:
    aqd:assessmentType
    ; /aqd:AQD_SourceApportionment/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata/@xlink:href
    ; /aqd:AQD_SourceApportionment/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods/aqd:modelAssessmentMetadata/@xlink:href
    ; /aqd:AQD_SourceApportionment/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods/aqd:assessmentTypeDescription
    ; /aqd:AQD_SourceApportionment/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods/aqd:assessmentType

    If the pollutant is NOT SO2, PM10, PM2.5 or CO the following elements are not
    expected:
        assessmentType,
        link to adjusting sampling point/model;assessmentTypeDescription;assessmentType

    ERROR
    :)

    let $I43 := try {
        for $node in $sources
            let $parent := $node/aqd:parentExceedanceSituation/@xlink:href
            let $pollutant := query:get-pollutant-for-attainment($parent)
            let $check := not(common:is-polutant-air($pollutant))

            let $meths := $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods

            let $values := (
                $meths/aqd:samplingPointAssessmentMetadata/@xlink:href,
                $meths/aqd:modelAssessmentMetadata/@xlink:href,
                $meths/aqd:assessmentTypeDescription,
                $meths/aqd:assessmentType
            )

            return
                if ($check)
                then
                    common:conditionalReportRow(
                        not(exists($values)),
                        [
                            ("gml:id", data($node/@gml:id)),
                            ("pollutant", $pollutant),
                            ('aqd:samplingPointAssessmentMetadata',
                             data($meths/aqd:samplingPointAssessmentMetadata/@xlink:href)),
                            ('aqd:modelAssessmentMetadata',
                             data($meths/aqd:modelAssessmentMetadata/@xlink:href)),
                            ('aqd:assessmentTypeDescription',
                             data($meths/aqd:assessmentTypeDescription)),
                            ('aqd:assessmentType',
                             data($meths/aqd:assessmentType))
                        ]
                    )
                else
                    ()
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    (: I44

    If
        aqd:AQD_SourceApportionment/
        aqd:macroExceedanceSituation/
        aqd:ExceedanceDescription/
        aqd:deductionAssessmentMethod/
        aqd:AdjustmentMethod/
        aqd:adjustmentType
    is populated ,
    WHERE ./aqd:pollutant xlink:href attribute EQUALs http://dd.eionet.europa.eu/vocabulary/aq/pollutant/[1,5,10,6001]

    (via …/aqd:parentExceedanceSituation),

    the xlink:href must be "fullyCorrected"

    if another pollutant it must be "noneApplicable"

    If the pollutant is SO2, PM10, PM2.5 or CO and DeductionAssessmentMethod
    populated, adjustmentType must be "fullyCorrected", else "noneApplicable"

    ERROR
    :)

    let $I44 := try {
        for $node in $sources
            let $el := $node/
                        aqd:macroExceedanceSituation/
                        aqd:ExceedanceDescription/
                        aqd:deductionAssessmentMethod/
                        aqd:AdjustmentMethod/
                        aqd:adjustmentType
            let $link := $el/@xlink:href

            let $parent := $node/aqd:parentExceedanceSituation/@xlink:href
            let $pollutant := query:get-pollutant-for-attainment($parent)
            let $needed := common:is-polutant-air($pollutant)

            let $check :=
                if ($needed)
                then
                    $link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/fullyCorrected"
                else
                    $link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplicable"

            let $ok :=
                if (not(exists($link)))
                then
                    true()
                else
                    $check
        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/@gml:id)),
                ("pollutant", $pollutant),
                (node-name($el), $link)
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    (:  I45
    "WHERE ./aqd:pollutant xlink:href attribute EQUALs
    http://dd.eionet.europa.eu/vocabulary/aq/pollutant/[1,5,10,6001] (via …/aqd:parentExceedanceSituation),
    /aqd:AQD_SourceApportionment/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentSource
    must be populated & the content of the xlink:href shall conform to
    http://dd.eionet.europa.eu/vocabulary/aq/adjustmentsourcetype,
    else  this element must not be populated"

    If the pollutant is SO2, PM10, PM2.5 or CO and DeductionAssessmentMethod populated,
    adjustmentSource must conform with vocabulary, else "noneApplicable"

    Error

    :)
    let $I45 := try {
        for $node in $sources
            let $parent := $node/aqd:parentExceedanceSituation/@xlink:href
            let $pollutant := query:get-pollutant-for-attainment($parent)
            let $needed := common:is-polutant-air($pollutant)

            let $el := $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentSource
            let $is-populated := common:has-content($el)
            let $link := $el/@xlink:href
            let $conforms := common:isInVocabulary(
                $link,
                $vocabulary:ADJUSTMENTSOURCE_VOCABULARY
            )

            let $ok :=
                if (not($needed))
                then
                    true()
                else
                    if ($conforms)
                    then
                        true()
                    else
                        data($el) = "noneApplicable"

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/@gml:id)),
                (node-name($el), $link)
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    return
        <table class="maintable hover">

        {html:build2("NS", $labels:NAMESPACES, $labels:NAMESPACES_SHORT, $NSinvalid, "All values are valid", "record", $errors:NS)}
        {html:build3("I0", $labels:I0, $labels:I0_SHORT, $I0table, string($I0table/td), errors:getMaxError($I0table))}
        {html:build1("I1", $labels:I1, $labels:I1_SHORT, $tblAllSources, "", string($countSources), "", "", $errors:I1)}
        {html:buildSimple("I2", $labels:I2, $labels:I2_SHORT, $I2table, "", "report", $I2errorLevel)}
        {html:buildSimple("I3", $labels:I3, $labels:I3_SHORT, $I3table, "", "", $I3errorLevel)}
        {html:build1("I4", $labels:I4, $labels:I4_SHORT, $I4table, "", string(count($I4table)), " ", "", $errors:I4)}
        {html:build1("I5", $labels:I5, $labels:I5_SHORT, $I5, "RESERVE", "RESERVE", "RESERVE", "RESERVE", $errors:I5)}
        {html:build1("I6", $labels:I6, $labels:I6_SHORT, $I6, "RESERVE", "RESERVE", "RESERVE", "RESERVE", $errors:I6)}
        {html:build2("I7", $labels:I7, $labels:I7_SHORT, $I7, "No duplicate values found", " duplicate value", $errors:I7)}
        {html:build2("I8", $labels:I8, $labels:I8_SHORT, $I8invalid, "No duplicate values found", " duplicate value", $errors:I8)}
        {html:build2("I9", $labels:I9, $labels:I9_SHORT, $I9table, "namespace", "", $errors:I9)}
        {html:build2("I10", $labels:I10, $labels:I10_SHORT, $I10invalid, "All values are valid", " not conform to vocabulary", $errors:I10)}

        {html:build2("I11", $labels:I11, $labels:I11_SHORT, $I11,
                     "All values are valid", "needs valid input", $errors:I11)}
        {html:build2("I12", $labels:I12, $labels:I12_SHORT, $I12,
                     "All values are valid", "needs valid input", $errors:I12)}

        {html:build2("I13", $labels:I13, $labels:I13_SHORT, $I13, "All values are valid", "needs valid input", $errors:I13)}
        {html:build2("I15", $labels:I15, $labels:I15_SHORT, $I15, "All values are valid", "needs valid input", $errors:I15)}
        {html:build2("I16", $labels:I16, $labels:I16_SHORT, $I16, "All values are valid", "needs valid input", $errors:I16)}

        {html:build2("I17", $labels:I17, $labels:I17_SHORT, $I17, "All values are valid", "needs valid input", $errors:I17)}

        {html:build2("I18", $labels:I18, $labels:I18_SHORT, $I18, "All values are valid", "needs valid input", $errors:I18)}
        {html:build2("I19", $labels:I19, $labels:I19_SHORT, $I19, "All values are valid", "needs valid input", $errors:I19)}
        {html:build2("I20", $labels:I20, $labels:I20_SHORT, $I20, "All values are valid", "needs valid input", $errors:I20)}
        {html:build2("I21", $labels:I21, $labels:I21_SHORT, $I21, "All values are valid", "needs valid input", $errors:I21)}
        {html:build2("I22", $labels:I22, $labels:I22_SHORT, $I22, "All values are valid", "needs valid input", $errors:I22)}
        {html:build2("I23", $labels:I23, $labels:I23_SHORT, $I23, "All values are valid", "needs valid input", $errors:I23)}
        {html:build2("I24", $labels:I24, $labels:I24_SHORT, $I24, "All values are valid", "needs valid input", $errors:I24)}
        {html:build2("I25", $labels:I25, $labels:I25_SHORT, $I25, "All values are valid", "needs valid input", $errors:I25)}
        {html:build2("I26", $labels:I26, $labels:I26_SHORT, $I26, "All values are valid", "needs valid input", $errors:I26)}
        {html:build2("I27", $labels:I27, $labels:I27_SHORT, $I27, "All values are valid", "needs valid input", $errors:I27)}
        {
        (: 28 is missing in XLS
        {html:build2("I28", $labels:I28, $labels:I28_SHORT, $I28, "All values are valid", "needs valid input", $errors:I28)}
        :)
        }
        {html:build2("I29", $labels:I29, $labels:I29_SHORT, $I29, "All values are valid", "needs valid input", $errors:I29)}
        {html:build2("I30", $labels:I30, $labels:I30_SHORT, $I30, "All values are valid", "needs valid input", $errors:I30)}
        {html:build2("I31", $labels:I31, $labels:I31_SHORT, $I31, "All values are valid", "needs valid input", $errors:I31)}
        {html:build2("I32", $labels:I32, $labels:I32_SHORT, $I32, "All values are valid", "needs valid input", $errors:I32)}
        {html:build2("I33", $labels:I33, $labels:I33_SHORT, $I33, "All values are valid", "needs valid input", $errors:I33)}
        {html:build2("I34", $labels:I34, $labels:I34_SHORT, $I34, "All values are valid", "needs valid input", $errors:I34)}
        {html:build2("I35", $labels:I35, $labels:I35_SHORT, $I35, "All values are valid", "needs valid input", $errors:I35)}
        {html:build2("I36", $labels:I36, $labels:I36_SHORT, $I36, "All values are valid", "needs valid input", $errors:I36)}
        {html:build2("I37", $labels:I37, $labels:I37_SHORT, $I37, "All values are valid", "needs valid input", $errors:I37)}
        {html:build2("I38", $labels:I38, $labels:I38_SHORT, $I38, "All values are valid", "needs valid input", $errors:I38)}
        {html:build2("I39", $labels:I39, $labels:I39_SHORT, $I39, "All values are valid", "needs valid input", $errors:I39)}
        {html:build2("I40", $labels:I40, $labels:I40_SHORT, $I40, "All values are valid", "needs valid input", $errors:I40)}
        {html:build2("I41", $labels:I41, $labels:I41_SHORT, $I41, "All values are valid", "needs valid input", $errors:I41)}
        {html:build2("I42", $labels:I42, $labels:I42_SHORT, $I42, "All values are valid", "needs valid input", $errors:I42)}
        {html:build2("I43", $labels:I43, $labels:I43_SHORT, $I43, "All values are valid", "needs valid input", $errors:I43)}
        {html:build2("I44", $labels:I44, $labels:I44_SHORT, $I44, "All values are valid", "needs valid input", $errors:I44)}
        {html:build2("I45", $labels:I45, $labels:I45_SHORT, $I45, "All values are valid", "needs valid input", $errors:I45)}

    </table>
};


declare function dataflowI:proceed(
    $source_url as xs:string,
    $countryCode as xs:string
) as element(div) {

    let $countZones := count(doc($source_url)//aqd:AQD_SourceApportionment)
    let $result := if ($countZones > 0) then dataflowI:checkReport($source_url, $countryCode) else ()
    let $meta := map:merge((
        map:entry("count", $countZones),
        map:entry("header", "Check air quality zones"),
        map:entry("dataflow", "Dataflow I"),
        map:entry("zeroCount", <p>No aqd:AQD_SourceApportionment elements found in this XML.</p>),
        map:entry("report", <p>This check evaluated the delivery by executing tier-1 tests on air quality zones data in Dataflow I as specified in <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a>.</p>)
    ))
    return
        html:buildResultDiv($meta, $result)
};
