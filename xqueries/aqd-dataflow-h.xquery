xquery version "3.0" encoding "UTF-8";
(:
 : Module Name: Implementing Decision 2011/850/EU: AQ info exchange & reporting (Library module)
 :
 : Version:     $Id$
 : Created:     9 November 2017
 : Copyright:   European Environment Agency
 :
 : XQuery script implements dataflow H checks.
 :
 : @author Claudia Ifrim
 :)

module namespace dataflowH = "http://converters.eionet.europa.eu/dataflowH";

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
import module namespace checks = "aqd-checks" at "aqd-checks.xq";

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

declare variable $dataflowH:ISO2_CODES as xs:string* := ("AL","AT","BA","BE","BG","CH","CY","CZ","DE","DK","DZ","EE","EG","ES","FI",
    "FR","GB","GR","HR","HU","IE","IL","IS","IT","JO","LB","LI","LT","LU","LV","MA","ME","MK","MT","NL","NO","PL","PS","PT",
     "RO","RS","SE","SI","SK","TN","TR","XK","UK");

declare variable $dataflowH:OBLIGATIONS as xs:string* := ($vocabulary:ROD_PREFIX || "680");

(: Rule implementations :)
declare function dataflowH:checkReport($source_url as xs:string, $countryCode as xs:string) as element(table) {
let $ms1Total := prof:current-ms()

let $ms1GeneralParameters:= prof:current-ms()
let $envelopeUrl := common:getEnvelopeXML($source_url)
let $docRoot := doc($source_url)
let $cdrUrl := common:getCdrUrl($countryCode)
let $reportingYear := common:getReportingYear($docRoot)
let $node-name := 'aqd:AQD_Plan'
let $latestEnvelopeByYearH := query:getLatestEnvelope($cdrUrl || "h/", $reportingYear)
let $headerBeginPosition := $docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:beginPosition
let $headerEndPosition := $docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:endPosition

let $nameSpaces := distinct-values($docRoot//base:namespace)

let $latestEnvelopesG := query:getLatestEnvelopesForObligation("679")
let $latestEnvelopesH := query:getLatestEnvelopesForObligation("680")

let $ms2GeneralParameters:= prof:current-ms()
(: File prefix/namespace check :)
let $ms1NS := prof:current-ms()
let $NSinvalid := try {
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

let $ms2NS := prof:current-ms()

(: VOCAB check:)

let $ms1VOCAB := prof:current-ms()

let $VOCABinvalid := checks:vocab($docRoot)

let $ms2VOCAB := prof:current-ms()
(: H0 Checks if this delivery is new or an update (on same reporting year) :)

let $ms1H0 := prof:current-ms()

let $H0 := try {
    if ($reportingYear = "")
    then
        common:checkDeliveryReport($errors:ERROR, "Reporting Year is missing.")
    else if($headerBeginPosition > $headerEndPosition) then
        <tr class="{$errors:BLOCKER}">
            <td title="Status">Start position must be less than end position</td>
        </tr>
    else
        if (query:deliveryExists($dataflowH:OBLIGATIONS, $countryCode, "h/", $reportingYear))
        then
            common:checkDeliveryReport($errors:WARNING, "Updating delivery for " || $reportingYear)
        else
            common:checkDeliveryReport($errors:INFO, "New delivery for " || $reportingYear)
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $isNewDelivery := errors:getMaxError($H0) = $errors:INFO

let $ms2H0 := prof:current-ms()

let $deliveries := sparqlx:run(
        query:sparql-objects-in-subject($cdrUrl || "h/", $node-name)
)//sparql:binding[@name='inspireLabel']/sparql:literal

let $latest-delivery := sparqlx:run(
        query:sparql-objects-in-subject(
                $latestEnvelopeByYearH,
                $node-name
        )
)//sparql:binding[@name='inspireLabel']/sparql:literal

let $knownPlans :=
    if ($isNewDelivery) then
        distinct-values(data($deliveries))
    else
        distinct-values(data($latest-delivery))

(: H01
Number of AQ Plans reported
:)

let $ms1H01 := prof:current-ms()

let $countPlans := count($docRoot//aqd:AQD_Plan)

let $H01 := try {
    for $rec in $docRoot//aqd:AQD_Plan
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

let $ms2H01 := prof:current-ms()

(: H02
Compile & feedback upon the total number of new plans records included in the delivery
(compared to any delivery for the same reporting year)

Number of new Plans compared to previous report(s).
:)

let $ms1H02 := prof:current-ms()

let $H02 := try {
    for $el in $docRoot//aqd:AQD_Plan
    let $x := $el/aqd:inspireId/base:Identifier
    let $inspireId := concat(data($x/base:namespace), "/", data($x/base:localId))
    let $ok := $inspireId = $knownPlans
                
    return
        common:conditionalReportRow(
                $ok,
                [
                    ("gml:id", data($el/@gml:id)),
                    ("aqd:inspireId", $inspireId),
                    ("knownPlans", $isNewDelivery),
                    ("deliveries", data($knownPlans)),
                    ("Sparql", sparqlx:getLink(query:existsViaNameLocalIdQuery(data($el/@gml:id), 'AQD_Plan', $latestEnvelopesH)))
                ]
        )
} catch * {
    html:createErrorRow($err:code, $err:description)
}
let $H02errorLevel :=
    if (
        $isNewDelivery
                and
                count(
                        for $x in $docRoot//aqd:AQD_Plan/aqd:inspireId/base:Identifier
                        let $id := $x/base:namespace || "/" || $x/base:localId
                        where query:existsViaNameLocalId($id, 'AQD_Plan', $latestEnvelopesH)
                        return 1
                ) > 0
    )
    then
        $errors:H02
    else
        $errors:INFO

let $ms2H02 := prof:current-ms()

(: H03 Number of existing Plans compared to previous report (same reporting year). Blocker will be returned if
XML is an update and ALL localId (100%) are different to previous delivery (for the same YEAR). :)

let $ms1H03 := prof:current-ms()

let $H03 := try {
    let $main := $docRoot//aqd:AQD_Plan
    for $x in $main/aqd:inspireId/base:Identifier
    let $inspireId := concat(data($x/base:namespace), "/", data($x/base:localId))
    let $ok := not(query:existsViaNameLocalIdYear($inspireId, 'AQD_Plan', $reportingYear, $latestEnvelopesH ))
    return
        common:conditionalReportRow(
                $ok,
                [
                ("gml:id", data($main/@gml:id)),
                ("aqd:inspireId", $inspireId),
                ("Sparql", sparqlx:getLink(query:existsViaNameLocalIdYearQuery($inspireId, 'AQD_Plan', $reportingYear, $latestEnvelopesH)))
                ]
        )
} catch * {
    html:createErrorRow($err:code, $err:description)    
}
let $H03errorLevel :=
    if (not($isNewDelivery) and count($H03) = 0)
    then
        $errors:H03
    else
        $errors:INFO

let $ms2H03 := prof:current-ms()

(: H4

Compile & feedback a list of the unique identifier information for all Plans records included in the delivery.
Feedback report shall include the gml:id attribute, ./aqd:inspireId, ./aqd:pollutant, ./aqd:protectionTarget,
/gml:FeatureCollection/gml:featureMember/aqd:AQD_Plan/aqd:firstExceedanceYear,


List of unique identifier information for all Plan records. Blocker if no Plans.
:)

let $ms1H04 := prof:current-ms()

let $H04 := try {(:)
    let $gmlIds := $docRoot//aqd:AQD_Plan/lower-case(normalize-space(@gml:id))
    let $inspireIds := $docRoot//aqd:AQD_Plan/lower-case(normalize-space(aqd:inspireId))

    for $x in $docRoot//aqd:AQD_Plan
        let $id := $x/@gml:id
        let $inspireId := $x/aqd:inspireId
        let $pollutantCodes := 
                            for $y in $x/aqd:pollutants/aqd:Pollutant/aqd:pollutantCode/@xlink:href
                                return $y    
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
                ("aqd:pollutant", data($pollutantCodes)),
                ("aqd:protectionTarget", data($x/aqd:pollutants/aqd:Pollutant/aqd:protectionTarget/@xlink:href)),
                ("aqd:firstExceedanceYear", data($x/aqd:firstExceedanceYear))
            ]
        )
} catch * {
    html:createErrorRow($err:code, $err:description)
}:)

     let $gmlIds := $docRoot//aqd:AQD_Plan/lower-case(normalize-space(@gml:id))
     let $inspireIds := $docRoot//aqd:AQD_Plan/lower-case(normalize-space(aqd:inspireId))
     for $x in $docRoot//aqd:AQD_Plan
        let $pollutantCodes := $x/aqd:pollutants/aqd:Pollutant/aqd:pollutantCode/@xlink:href
        let $id := $x/@gml:id
        let $inspireId := $x/aqd:inspireId/base:Identifier
        let $aqdinspireId := concat($x/aqd:inspireId/base:Identifier/base:localId, "/", $x/aqd:inspireId/base:Identifier/base:namespace)
        let $ok := (count(index-of($gmlIds, lower-case(normalize-space($id)))) = 1
            and
            count(index-of($inspireIds, lower-case(normalize-space($inspireId)))) = 1)
            return
                if($ok)
                    then
                        <tr>
                            <td title="gml:id">{data($x/@gml:id)}</td>
                            <td title="aqd:inspireId">{distinct-values($aqdinspireId)}</td>
                            <td title="aqd:pollutant">{data($pollutantCodes)}</td>
                            <td title="aqd:protectionTarget">{distinct-values(data($x/aqd:pollutants/aqd:Pollutant/aqd:protectionTarget/@xlink:href))}</td>
                            <td title="aqd:firstExceedanceYear">{data($x/aqd:firstExceedanceYear)}</td>
                        </tr>
                    else
                        ()
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2H04 := prof:current-ms()

(: H05 
aqd:AQD_Plan/aqd:pollutants/aqd:Pollutant/aqd:pollutantCode xlink:href attribute shall resolve to
one of http://dd.eionet.europa.eu/vocabulary/aq/pollutant/

Your plan status should use one of those listed at http://dd.eionet.europa.eu/vocabulary/aq/pollutant/
 :)

let $ms1H05 := prof:current-ms()

let $H05 := try {
    for $el in $docRoot//aqd:AQD_Plan/aqd:pollutants/aqd:Pollutant/aqd:pollutantCode
    let $uri := $el/@xlink:href
    return
        if (not(common:isInVocabulary($uri, $vocabulary:POLLUTANT_VOCABULARY)))
        then
            <tr>
                <td title="gml:id">{data($el/ancestor-or-self::*[name() = $node-name]/@gml:id)}</td>
                <td title="xlink:href"> {data($el/@xlink:href)}</td>
                <td title="{node-name($el)}"> not conform to vocabulary</td>
            </tr>
        else
            ()
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2H05 := prof:current-ms()

(: H06 RESERVE :)

let $ms1H06 := prof:current-ms()

let $H06 := ()

let $ms2H06 := prof:current-ms()

(: H07

    All gml:id attributes, ef:inspireId and aqd:inspireId elements shall have
    unique content

    All gml ID attributes shall have unique code

    BLOCKER
:)

let $ms1H07 := prof:current-ms()

let $H07 := try {
    let $checks := ('gml:id', 'aqd:inspireId', 'ef:inspireId')

    let $errors := array {

        for $name in $checks
        let $name := lower-case(normalize-space($name))
        let $values := $docRoot//aqd:AQD_Plan//(*[lower-case(normalize-space(name())) = $name] |
                @*[lower-case(normalize-space(name())) = $name])
        return
            for $v in distinct-values($values)
            return
                if (common:has-one-node($values, $v))
                then
                    ([$name, data($v)])
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

let $ms2H07 := prof:current-ms()

(: H08

    ./aqd:inspireId/base:Identifier/base:localId must be unique code for the
    Plans records

    Local Id must be unique for the Plans records

    BLOCKER
:)

let $ms1H08 := prof:current-ms()

let $H08:= try {
    let $localIds := $docRoot//aqd:AQD_Plan/aqd:inspireId/base:Identifier/lower-case(normalize-space(base:localId))
    for $x in $docRoot//aqd:AQD_Plan
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

let $ms2H08 := prof:current-ms()

(: H09
 ./aqd:inspireId/base:Identifier/base:namespace List base:namespace
 and count the number of base:localId assigned to each base:namespace.

 List unique namespaces used and count number of elements
:)

let $ms1H09 := prof:current-ms()

let $H09 := try {
    for $namespace in distinct-values($docRoot//aqd:AQD_Plan/aqd:inspireId/base:Identifier/base:namespace)
    let $localIds := $docRoot//aqd:AQD_Plan/aqd:inspireId/base:Identifier[base:namespace = $namespace]/base:localId
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

let $ms2H09 := prof:current-ms()

(: H10
Check that namespace is registered in vocabulary (http://dd.eionet.europa.eu/vocabulary/aq/namespace/view)

Check namespace is registered
:)

let $ms1H10 := prof:current-ms()

let $H10 := try {
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

let $ms2H10 := prof:current-ms()

(: H11
If aqd:AQD_ReportingHeader/aqd:reportingPeriod => 2013 aqd:AQD_Plan/aqd:exceedanceSituation@xlink:href
attribute shall resolve to at least one  exceedance situation in dataset G via namespace/localId.

If reporting period equal or greater than 2013, AQ must link to a valid exceedande situation (G)
:)

let $ms1H11 := prof:current-ms()

let $H11 := try{
    let $year := if (empty($reportingYear)) then ()
    else
        if ($reportingYear castable as xs:integer) then xs:integer($reportingYear) else ()

    for $el in $docRoot//aqd:AQD_Plan/aqd:exceedanceSituation

    let $label := data($el/@xlink:href)
    (: let $ok := if($year>=2013)
        then
            query:existsViaNameLocalId(
                $label,
                'AQD_Attainment',
                $latestEnvelopesG
            )
        else
            true() :)
    let $ok := if($year>=2013 and not(fn:empty($label)))
        then
            query:existsViaNameLocalId(
                $label,
                'AQD_Attainment',
                $latestEnvelopesG
            )
        else
            true()
    
    let $sparql_query := if(fn:empty($label))
                         then
                          "No label to execute this query"
                         else
                          sparqlx:getLink(query:existsViaNameLocalIdQuery($label, 'AQD_Attainment', $latestEnvelopesG))
    
    return common:conditionalReportRow(
            $ok,
            [
            ("gml:id", data($el/ancestor-or-self::*[name() = $node-name]/@gml:id)),
            ("aqd:exceedanceSituation", $el/@xlink:href),
            (: ("Sparql", sparqlx:getLink(query:existsViaNameLocalIdQuery($label, 'AQD_Attainment', $latestEnvelopesG))) :)
            ("Sparql", $sparql_query)
            ]
    )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2H11 := prof:current-ms()

(: H12
If aqd:reportingPeriod < 2013 and aqd:AQD_Plan/aqd:exceedanceSituation is empty aqd:comment must be populated

If reporting period before than 2013 and a valid exceedande situation is not provided, aqd:comment should be
provided instead
:)

let $ms1H12 := prof:current-ms()

let $H12 := try {
    let $year := if (empty($reportingYear)) then ()
    else
        if ($reportingYear castable as xs:integer) then xs:integer($reportingYear) else ()

    for $el in $docRoot//aqd:AQD_Plan
        let $main := $el/aqd:exceedanceSituation/@xlink:href
        let $mainEmpty := $el/aqd:exceedanceSituation[@xlink:href = ""]
        let $allExceedanceEmpty := count($mainEmpty)
        let $allExceedance := count($main)
        let $comment := $el/aqd:comment

        let $test := if(not(empty($main)) and $main="" and $allExceedance = $allExceedanceEmpty) then 
                        $main=""
                        else 
                        empty($main)
        let $mainCommentEmpty := 
                    
                    $test
                    and
                    $comment = ""

        let $yearComment :=
                     
                    not(empty($year))
                    and
                    $year < 2013
                    and
                    $mainCommentEmpty = true()

        let $ok := (
                
                    $yearComment = false()
                    
        )

    return common:conditionalReportRow(
            $ok,
            [
            ("gml:id", data($el/@gml:id)),
            ("aqd:exceedanceSituation", data($main)),
            ("aqd:comment", data($comment))
            ]
    )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2H12 := prof:current-ms()

(: H13 RESERVE :)

let $ms1H13 := prof:current-ms()

let $H13 := ()

let $ms2H13 := prof:current-ms()

(: H14
aqd:AQD_Plan/aqd:code should begin with with the 2-digit country code according to ISO 3166-1.

We recommend you start you codes with the 2-digit country code according to ISO 3166-1.


let $H14 := try {
    let $seq := $docRoot//aqd:AQD_Plan/aqd:code
    for $el in $seq
    let $ok := fn:lower-case($countryCode) = fn:lower-case(fn:substring(data($el), 1, 2))
    return common:conditionalReportRow(
            $ok,
            [
            ("gml:id", data($el/ancestor-or-self::*[name() = $node-name]/@gml:id)),
            (node-name($el), $el)
            ]
    )
} catch * {
    html:createErrorRow($err:code, $err:description)
}:)

(: H15 RESERVE :)

let $ms1H15 := prof:current-ms()

let $H15 := (
    try {
    for $el in $docRoot//aqd:AQD_Plan
        let $codes := $docRoot//aqd:AQD_Plan[aqd:code = $el/aqd:code]
        let $ok := (
            not(count($codes) > 1)
            and
            $el/aqd:code != ""
            
        )
    return common:conditionalReportRow(
            $ok,
            [
            ("base:localId", $el/aqd:inspireId/base:Identifier/base:localId),
            ("gml:id", data($el/ancestor-or-self::*[name() = $node-name]/@gml:id)),
            ("aqd:Code", $el/aqd:code)
            ]
         )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    )

let $ms2H15 := prof:current-ms()

(: H16
aqd:AQD_Plan/aqd:competentAuthority/base2:RelatedParty/base2:organisationName/gco:CharacterString shall
not be NULL or voided

You must provide the name of the organisation responsible for the plan
:)

let $ms1H16 := prof:current-ms()

let $H16 := try {
    let $main := $docRoot//aqd:AQD_Plan/aqd:competentAuthority/base2:RelatedParty/base2:organisationName/gco:CharacterString
    for $el in $main
    let $ok := (data($el) castable as xs:string
            and
            functx:if-empty(data($el), "") != ""
    )
    return common:conditionalReportRow(
            $ok,
            [
            ("gml:id", data($el/ancestor-or-self::*[name() = $node-name]/@gml:id)),
            (node-name($el), $el)
            ]
    )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2H16 := prof:current-ms()

(: H17
aqd:AQD_Plan/aqd:competentAuthority/base2:RelatedParty/base2:individualName/gco:CharacterString shall not
be NULL or voided

You must provide a contact point within the organisation responsible for the plan, this may be a generic contact point.
:)

let $ms1H17 := prof:current-ms()

let $H17 := try {
    let $main := $docRoot//aqd:AQD_Plan/aqd:competentAuthority/base2:RelatedParty/base2:individualName/gco:CharacterString
    for $el in $main
    let $ok := (data($el) castable as xs:string
            and
            functx:if-empty(data($el), "") != ""
    )
    return common:conditionalReportRow(
            $ok,
            [
            ("gml:id", data($el/ancestor-or-self::*[name() = $node-name]/@gml:id)),
            (node-name($el), $el)
            ]
    )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2H17 := prof:current-ms()

(: H18
aqd:AQD_Plan/aqd:competentAuthority/base2:RelatedParty/base2:contact/base2:Contact/base2:electronicMailAddress shall
not be NULL or voided

You must provide an email address for the contact point within the organisation responsible for the plan, this may be
a generic telephone number.
:)

let $ms1H18 := prof:current-ms()

let $H18 := try {
    let $main := $docRoot//aqd:AQD_Plan/aqd:competentAuthority/base2:RelatedParty/base2:contact/base2:Contact/base2:electronicMailAddress
    for $el in $main
    let $ok := (data($el) castable as xs:string
            and
            functx:if-empty(data($el), "") != ""
    )
    return common:conditionalReportRow(
            $ok,
            [
            ("gml:id", data($el/ancestor-or-self::*[name() = $node-name]/@gml:id)),
            (node-name($el), $el)
            ]
    )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2H18 := prof:current-ms()

(: H19
aqd:AQD_Plan/aqd:firstExceedanceYear/gml:TimeInstant/gml:timePosition shall not be voided, NULL or an empty tag & shall contain content in yyyy format

Your reference year must be in yyyy format
:)

let $ms1H19 := prof:current-ms()

let $H19 := try {
    for $el in $docRoot//aqd:AQD_Plan/aqd:firstExceedanceYear/gml:TimeInstant/gml:timePosition
    let $ok := functx:if-empty(data($el), "") != ""
            and
            $el castable as xs:gYear

    return common:conditionalReportRow(
            $ok,
            [
            ("gml:id", data($el/ancestor-or-self::*[name() = $node-name]/@gml:id)),
            (node-name($el), data($el))
            ]
    )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2H19 := prof:current-ms()

(: H20
aqd:AQD_Plan/aqd:status  xlink:href attribute shall resolve to one of http://dd.eionet.europa.eu/vocabulary/aq/statusaqplan/

Your plan status should use one of those listed at http://dd.eionet.europa.eu/vocabulary/aq/statusaqplan/
:)

let $ms1H20 := prof:current-ms()

let $H20 := try {
    for $el in $docRoot//aqd:AQD_Plan/aqd:status
    let $uri := $el/@xlink:href
    return
        if (not(common:isInVocabulary($uri, $vocabulary:STATUSAQPLAN_VOCABULARY)))
        then
            <tr>
                <td title="gml:id">{data($el/ancestor-or-self::*[name() = $node-name]/@gml:id)}</td>
                <td title="xlink:href"> {data($el/@xlink:href)}</td>
                <td title="{node-name($el)}"> not conform to vocabulary</td>
            </tr>
        else
            ()
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2H20 := prof:current-ms()

(: H21 RESERVE:)

let $ms1H21 := prof:current-ms()

let $H21 := ()

let $ms2H21 := prof:current-ms()

(: H22
aqd:AQD_Plan/aqd:pollutants/aqd:Pollutant/aqd:protectionTarget xlink:href attribute shall resolve
to one of http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/

Your protection target should use one of those listed at http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/
:)

let $ms1H22 := prof:current-ms()

let $H22 := try {
    for $el in $docRoot//aqd:AQD_Plan/aqd:pollutants/aqd:Pollutant/aqd:protectionTarget
    let $uri := $el/@xlink:href
    return
        if (not(common:isInVocabulary($uri, $vocabulary:PROTECTIONTARGET_VOCABULARY)))
        then
            <tr>
                <td title="gml:id">{data($el/ancestor-or-self::*[name() = $node-name]/@gml:id)}</td>
                <td title="xlink:href"> {data($el/@xlink:href)}</td>
                <td title="{node-name($el)}"> not conform to vocabulary</td>
            </tr>
        else
            ()
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2H22 := prof:current-ms()

(: H23
Check and count expected combinations of Pollutant and ProtectionTarget at
/gml:FeatureCollection/gml:featureMember/aqd:AQD_Plan/aqd:pollutants/aqd:Pollutant
Sulphur dioxide (1) + health
Sulphur dioxide (1) + vegetation
Ozone (7) + health
Ozone (7) + vegetation
Nitrogen dioxide (8) + health
Nitrogen oxides (9) + vegetation
Particulate matter < 10 µm (5) + health
Particulate matter < 2.5 µm (6001) + health
Carbon monoxide (10) + health
Benzene (20) + health
Lead in PM10 (5012) + health
Arsenic in PM10 (5018) + health
Cadmium in PM10 (5014) + health
Nickel in PM10 (5015) + health
Benzo(a)pyrene in PM10 (5029) + health


Check and count expected combinations of Pollutant and ProtectionTarget
:)

let $ms1H23 := prof:current-ms()

let $H23 := try {
    (:let $accepted_health := (
        'http://dd.eionet.europa.eu/vocabulary/aq/pollutant/1',
        'http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5',
        'http://dd.eionet.europa.eu/vocabulary/aq/pollutant/7',
        'http://dd.eionet.europa.eu/vocabulary/aq/pollutant/8',
        'http://dd.eionet.europa.eu/vocabulary/aq/pollutant/10',
        'http://dd.eionet.europa.eu/vocabulary/aq/pollutant/20',
        'http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5012',
        'http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5014',
        'http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5015',
        'http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5018',
        'http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5029',
        'http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001'
    )

    let $accepted_vegetation := (
        'http://dd.eionet.europa.eu/vocabulary/aq/pollutant/1',
        'http://dd.eionet.europa.eu/vocabulary/aq/pollutant/7',
        'http://dd.eionet.europa.eu/vocabulary/aq/pollutant/9'
    )
    :)

    let $rdf := doc($vocabulary:ENVIRONMENTALOBJECTIVE || "rdf")
     let $EnviromentalObtiveDD := 
        for $x in doc($vocabulary:ENVIRONMENTALOBJECTIVE || "rdf")//skos:Concept
            
            let $relatedPollutant := $x/prop:relatedPollutant/@rdf:resource
            let $hasObjectiveType := $x/prop:hasObjectiveType/@rdf:resource
            let $hasReportingMetric := $x/prop:hasReportingMetric/@rdf:resource
            let $hasProtectionTarget := $x/prop:hasProtectionTarget/@rdf:resource

            return $relatedPollutant || "#" || $hasProtectionTarget
           



    for $polluant in $docRoot//aqd:AQD_Plan/aqd:pollutants/aqd:Pollutant
        let $pollutantCode := $polluant/aqd:pollutantCode/@xlink:href
        let $protectionTarget := $polluant/aqd:protectionTarget/@xlink:href
        let $codeAndTarget := $pollutantCode || "#" || $protectionTarget
        return
            if(not($codeAndTarget = $EnviromentalObtiveDD))

            (:if (($protectionTarget = 'http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H'
                    and not($pollutantCode = $accepted_health))
                or ($protectionTarget = 'http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V'
                    and not($pollutantCode = $accepted_vegetation))):)
            then
                <tr>
                    <td title="gml:id">{data($polluant/ancestor-or-self::*[name() = $node-name]/@gml:id)}</td>
                    <td title="pollutantCode xlink:href">{data($pollutantCode)}</td>
                    <td title="protectionTarget xlink:href">{data($protectionTarget)}</td>
                    <td title="error"> not accepted</td>
                </tr>
            else
                ()
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2H23 := prof:current-ms()

(: H24
aqd:AQD_Plan/aqd:pollutants/aqd:Pollutant/aqd:pollutantCode xlink:href attribute (may be multiple)
shall be the same as those in the referenced data flow G
xlinked via aqd:AQD_Plan/aqd:exceedanceSituation@xlink:href
attribute (maybe multiple)

AQ plan pollutant's should match those in the exceedance situation (G)
:)

let $ms1H24 := prof:current-ms()
(:
let $H24 := try {
    for $plan in $docRoot//aqd:AQD_Plan
        let $pollutantCodes := $plan/aqd:pollutants/aqd:Pollutant/aqd:pollutantCode/@xlink:href
        for $exceedanceSituation in $plan/aqd:exceedanceSituation/@xlink:href
            let $pollutants := query:getPollutants("AQD_Attainment", $exceedanceSituation)
            let $pollutants_query := sparqlx:getLink(query:getPollutantsQuery("AQD_Attainment", $exceedanceSituation))
            let $ok := count(index-of($pollutantCodes, functx:if-empty($pollutants, ""))) > 0
            return
                if(not($ok))
                    then
                        <tr>
                            <td title="gml:id">{data($plan/ancestor-or-self::*[name() = $node-name]/@gml:id)}</td>
                            <td title="aqd:exceedanceSituation">{data($exceedanceSituation)}</td>
                            <td title="pollutantCode xlink:href">{data($pollutantCodes)}</td>
                            <td title="Sparql">{$pollutants_query}</td>
                        </tr>
                    else
                        ()
} catch * {
    html:createErrorRow($err:code, $err:description)
}
:)

let $H24 := try {
    let $pollutantsList := sparqlx:run(query:getPollutantsQuery("AQD_Attainment"))
    for $plan in $docRoot//aqd:AQD_Plan
        let $pollutantCodes := $plan/aqd:pollutants/aqd:Pollutant/aqd:pollutantCode/@xlink:href

        for $exceedanceSituation in $plan/aqd:exceedanceSituation/@xlink:href            
            (: let $pollutants := query:getPollutants("AQD_Attainment", $exceedanceSituation) :)
            let $pollutants := 
                for $pollutantsFilter in $pollutantsList[sparql:binding[@name='label']/sparql:literal = $exceedanceSituation]/sparql:binding[@name='pollutant']/sparql:uri
                return $pollutantsFilter
                
            let $pollutants_query := sparqlx:getLink(query:getPollutantsQuery("AQD_Attainment", $exceedanceSituation)) 
            let $ok := count(index-of($pollutantCodes, functx:if-empty($pollutants, ""))) > 0

            return
                if(not($ok))
                    then
                        <tr>
                            <td title="gml:id">{data($plan/ancestor-or-self::*[name() = $node-name]/@gml:id)}</td>
                            <td title="aqd:exceedanceSituation">{data($exceedanceSituation)}</td>
                            <td title="pollutantCode xlink:href">{data($pollutantCodes)}</td>
                            <td title="Sparql">{sparqlx:getLink(query:getPollutantsQuery("AQD_Attainment"))}</td>
                        </tr>
                    else
                        ()
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2H24 := prof:current-ms()

(: H25
aqd:AQD_Plan/aqd:adoptionDate/gml:TimeInstant/gml:timePosition MUST be populated and its content in
yyyy-mm-dd format if /gml:FeatureCollection/gml:featureMember/aqd:AQD_Plan/aqd:status  xlink:href
attribute not equal http://dd.eionet.europa.eu/vocabulary/aq/statusaqplan/preparation,
http://dd.eionet.europa.eu/vocabulary/aq/statusaqplan/adoption-process or
http://dd.eionet.europa.eu/vocabulary/aq/statusaqplan/under-revision

Your reference year must be in yyyy-mm-dd format - rephrase it
:)

let $ms1H25 := prof:current-ms()

let $H25 := try {
    for $node in $docRoot//aqd:AQD_Plan
    let $link := $node/aqd:status/@xlink:href
    let $not_needed := common:is-status-in-progress($link)

    let $el := $node/aqd:adoptionDate/gml:TimeInstant/gml:timePosition
    let $is-populated := common:has-content($el)

    let $ok :=
        if ($not_needed)
        then
            true()
        else
            if ($is-populated and data($el) castable as xs:date)
            then
                true()
            else
                false()

    return common:conditionalReportRow(
            $ok,
            [
            ("gml:id", data($el/ancestor-or-self::*[name() = $node-name]/@gml:id)),
            (node-name($el), $link)
            ]
    )
}  catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2H25 := prof:current-ms()

(: H26
if /gml:FeatureCollection/gml:featureMember/aqd:AQD_Plan/aqd:status  xlink:href attribute equal
http://dd.eionet.europa.eu/vocabulary/aq/statusaqplan/preparation,
http://dd.eionet.europa.eu/vocabulary/aq/statusaqplan/adoption-process or
http://dd.eionet.europa.eu/vocabulary/aq/statusaqplan/under-revision

aqd:AQD_Plan/aqd:adoptionDate/gml:TimeInstant/gml:timePosition should not be populated
:)

let $ms1H26 := prof:current-ms()

let $H26 := try {
    for $node in $docRoot//aqd:AQD_Plan
    let $link := $node/aqd:status/@xlink:href
    let $not_needed := not(common:is-status-in-progress($link))

    let $el := $node/aqd:adoptionDate/gml:TimeInstant/gml:timePosition
    let $is-populated := common:has-content($el)

    let $ok :=
        if ($not_needed and $is-populated)
        then
            false()
        else
            true()

    return common:conditionalReportRow(
            $ok,
            [
            ("gml:id", data($node/@gml:id)),
            (node-name($el), $link)
            ]
    )
}  catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2H26 := prof:current-ms()


(: H27
aqd:AQD_Plan/aqd:timeTable shall contain a text string

Must contain a short textual description of timetable for the implementation of the air quality plan
:)

let $ms1H27 := prof:current-ms()

let $H27 := try {
    let $main := $docRoot//aqd:AQD_Plan/aqd:timeTable
    for $el in $main
    let $ok := (data($el) castable as xs:string
            and
            functx:if-empty(data($el), "") != ""
    )
    return common:conditionalReportRow(
            $ok,
            [
            ("gml:id", data($el/ancestor-or-self::*[name() = $node-name]/@gml:id)),
            (node-name($el), $el)
            ]
    )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2H27 := prof:current-ms()

(: H28
aqd:AQD_Plan/aqd:referenceImplementation shall contain a URL to document  or web resource describing the
latest version of full air quality plan. This MUST be valid.

Must contain a URL to document  or web resource describing the last version of full air quality plan
:)

let $ms1H28 := prof:current-ms()

let $H28 := try {
    let $main :=  $docRoot//aqd:AQD_Plan/aqd:referenceImplementation
    for $el in $main
    let $ok := (
        functx:if-empty(data($el), "") != "")
            and
            common:includesURL(data($el)
            )
    return common:conditionalReportRow(
            $ok,
            [
            ("gml:id", data($el/ancestor-or-self::*[name() = $node-name]/@gml:id)),
            (node-name($el), $el)
            ]
    )

} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2H28 := prof:current-ms()

(: H29
aqd:AQD_Plan/aqd:referenceImplementation must contain a URL to a document or web resource where
information about the implementation of the air quality plan can be found.

Must contain a URL to a document or web resource where information about the implementation of the air quality
plan can be found.
:)

let $ms1H29 := prof:current-ms()

let $H29 := try {
    let $main :=  $docRoot//aqd:AQD_Plan/aqd:referenceImplementation
    for $el in $main
    let $ok := (
        functx:if-empty(data($el), "") != "")
            and
            common:includesURL(data($el)
            )
    return common:conditionalReportRow(
            $ok,
            [
            ("gml:id", data($el/ancestor-or-self::*[name() = $node-name]/@gml:id)),
            (node-name($el), $el)
            ]
    )

} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2H29 := prof:current-ms()

(: H30
aqd:AQD_Plan/aqd:publication/aqd:Publication/aqd:description must contain a text string describing the publication

Brief textual description of the published AQ Plan should be provided. If available, include the ISBN number.
:)

let $ms1H30 := prof:current-ms()

let $H30 := try {
    let $main := $docRoot//aqd:AQD_Plan/aqd:publication/aqd:Publication/aqd:description
    for $el in $main
    let $ok := (data($el) castable as xs:string
            and
            functx:if-empty(data($el), "") != ""
    )
    return common:conditionalReportRow(
            $ok,
            [
            ("gml:id", data($el/ancestor-or-self::*[name() = $node-name]/@gml:id)),
            (node-name($el), $el)
            ]
    )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2H30 := prof:current-ms()

(: H31
aqd:AQD_Plan/aqd:publication/aqd:Publication/aqd:title must contain the title of the publication

Title as written in the published AQ Plan.
:)

let $ms1H31 := prof:current-ms()

let $H31 := try {
    let $main := $docRoot//aqd:AQD_Plan/aqd:publication/aqd:Publication/aqd:title
    for $el in $main
    let $ok := (data($el) castable as xs:string
            and
            functx:if-empty(data($el), "") != ""
    )
    return common:conditionalReportRow(
            $ok,
            [
            ("gml:id", data($el/ancestor-or-self::*[name() = $node-name]/@gml:id)),
            (node-name($el), $el)
            ]
    )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2H31 := prof:current-ms()

(: H32
aqd:AQD_Plan/aqd:publication/aqd:Publication/aqd:author must contain the author(s) of the publication

Author(s) should be provided as text (If there are multiple authors, please provide in one field separated by commas)
:)

let $ms1H32 := prof:current-ms()

let $H32 := try {
    let $main := $docRoot//aqd:AQD_Plan/aqd:publication/aqd:Publication/aqd:author
    for $el in $main
    let $localId := $el/../../../aqd:inspireId/base:Identifier/base:localId
    let $ok := (data($el) castable as xs:string
            and
            functx:if-empty(data($el), "") != ""
    )
    return common:conditionalReportRow(
            $ok,
            [
            ("gml:id", data($el/ancestor-or-self::*[name() = $node-name]/@gml:id)),
            ("localId", $localId),
            ("aqd:title", data($el/../aqd:title)),
            (node-name($el), $el)
            ]
    )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2H32 := prof:current-ms()

(: H33
aqd:AQD_Plan/aqd:publication/aqd:Publication/aqd:publicationDate/gml:TimeInstant/gml:timePosition must contaong the
date of publication in yyyy-mm-dd format

The publication date of the AQ Plan should be provided in yyyy or yyyy-mm-dd format
:)

let $ms1H33 := prof:current-ms()

let $H33 := try {
    let $main := $docRoot//aqd:AQD_Plan/aqd:publication/aqd:Publication/aqd:publicationDate/gml:TimeInstant/gml:timePosition
    for $node in $main
    let $ok := (
        data($node) castable as xs:date
        or
        not(common:isInvalidYear(data($node)))
        or 
        data($node) castable as xs:gYear
    )
    return common:conditionalReportRow(
            $ok,
            [
            ("gml:id", data($node/ancestor-or-self::*[name() = $node-name]/@gml:id)),
            (node-name($node), data($node))
            ]
    )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2H33 := prof:current-ms()

(: H34
aqd:AQD_Plan/aqd:publication/aqd:Publication/aqd:publisher must container a text string describing the publisher

Publisher should be provided as a text (Publishing institution, academic jourmal, etc.)
:)

let $ms1H34 := prof:current-ms()

let $H34 := try {
    let $main := $docRoot//aqd:AQD_Plan/aqd:publication/aqd:Publication/aqd:publisher
    for $el in $main
    let $ok := (data($el) castable as xs:string
            and
            functx:if-empty(data($el), "") != ""
    )
    return common:conditionalReportRow(
            $ok,
            [
            ("gml:id", data($el/ancestor-or-self::*[name() = $node-name]/@gml:id)),
            (node-name($el), $el)
            ]
    )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2H34 := prof:current-ms()

(: H35
aqd:AQD_Plan/aqd:publication/aqd:Publication/aqd:webLink must contain a URL to document  or web resource
describing the last version of full air quality plan

Provided url to the published AQ Plan should be valid
:)

let $ms1H35 := prof:current-ms()

let $H35 := try {
    let $main :=  $docRoot//aqd:AQD_Plan/aqd:publication/aqd:Publication/aqd:webLink
    for $el in $main
    let $ok := (
        functx:if-empty(data($el), "") != "")
            and
            common:includesURL(data($el)
            )
    return common:conditionalReportRow(
            $ok,
            [
            ("gml:id", data($el/ancestor-or-self::*[name() = $node-name]/@gml:id)),
            (node-name($el), $el)
            ]
    )

} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2H35 := prof:current-ms()
let $ms2Total := prof:current-ms()

return
    <table class="maintable hover">
    <table>
        {html:build2("NS", $labels:NAMESPACES, $labels:NAMESPACES_SHORT, $NSinvalid, "All values are valid", "record", $errors:NS)}
        {html:build2("VOCAB", $labels:VOCAB, $labels:VOCAB_SHORT, $VOCABinvalid, "All values are valid", "record", $errors:VOCAB)}
        {html:build3("H0", $labels:H0, $labels:H0_SHORT, $H0, string($H0/td), errors:getMaxError($H0))}
        {html:build1("H01", $labels:H01, $labels:H01_SHORT, $H01, "", string($countPlans), "", "", $errors:H01)}
        {html:buildSimpleSparql("H02", $labels:H02, $labels:H02_SHORT, $H02, "", "", $H02errorLevel)}
        {html:buildSimpleSparql("H03", $labels:H03, $labels:H03_SHORT, $H03, "", "", $H03errorLevel)}
        {html:build2("H04", $labels:H04, $labels:H04_SHORT, $H04, "All values are valid", "found", $errors:H04)}
        <!--{html:build1("H04", $labels:H04, $labels:H04_SHORT, $H04, "", string(count($H04)), " ", "", $errors:H04)}-->
        {html:build2("H05", $labels:H05, $labels:H05_SHORT, $H05, "All values are valid", "needs valid input", $errors:H05)}
        {html:build1("H06", $labels:H06, $labels:H06_SHORT, $H06, "RESERVE", "RESERVE", "RESERVE", "RESERVE", $errors:H06)}
        {html:build2("H07", $labels:H07, $labels:H07_SHORT, $H07, "No duplicate values found", " duplicate value", $errors:H07)}
        {html:build2("H08", $labels:H08, $labels:H08_SHORT, $H08, "No duplicate values found", " duplicate value", $errors:H08)}
        {html:buildUnique("H09", $labels:H09, $labels:H09_SHORT, $H09, "namespace", $errors:H09)}
        {html:build2("H10", $labels:H10, $labels:H10_SHORT, $H10, "All values are valid", " not conform to vocabulary", $errors:H10)}
        {html:build2Sparql("H11", $labels:H11, $labels:H11_SHORT, $H11, "All values are valid", "needs valid input", $errors:H11)}
        {html:build2("H12", $labels:H12, $labels:H12_SHORT, $H12, "All values are valid", "needs valid input", $errors:H12)}
        {html:build1("H13", $labels:H13, $labels:H13_SHORT, $H13, "RESERVE", "RESERVE", "RESERVE", "RESERVE", $errors:H13)}
    <!--{html:build2("H14", $labels:H14, $labels:H14_SHORT, $H14, "All values are valid", "needs valid input", $errors:H14)}:)-->
        {html:build2("H15", $labels:H15, $labels:H15_SHORT, $H15, "All values are valid", "needs valid input", $errors:H15)}
        {html:build2("H16", $labels:H16, $labels:H16_SHORT, $H16, "All values are valid", "needs valid input", $errors:H16)}
        {html:build2("H17", $labels:H17, $labels:H17_SHORT, $H17, "All values are valid", "needs valid input", $errors:H17)}
        {html:build2("H18", $labels:H18, $labels:H18_SHORT, $H18, "All values are valid", "needs valid input", $errors:H18)}
        {html:build2("H19", $labels:H19, $labels:H19_SHORT, $H19, "All values are valid", "needs valid input", $errors:H19)}
        {html:build2("H20", $labels:H20, $labels:H20_SHORT, $H20, "All values are valid", "needs valid input", $errors:H20)}
        {html:build1("H21", $labels:H21, $labels:H21_SHORT, $H21, "RESERVE", "RESERVE", "RESERVE", "RESERVE", $errors:H21)}
        {html:build2("H22", $labels:H22, $labels:H22_SHORT, $H22, "All values are valid", "needs valid input", $errors:H22)}
        {html:build2("H23", $labels:H23, $labels:H23_SHORT, $H23, "All values are valid", "needs valid input", $errors:H23)}
        {html:build2Sparql("H24", $labels:H24, $labels:H24_SHORT, $H24, "All values are valid", "needs valid input", $errors:H24)}
        {html:build2("H25", $labels:H25, $labels:H25_SHORT, $H25, "All values are valid", "needs valid input", $errors:H25)}
        {html:build2("H26", $labels:H26, $labels:H26_SHORT, $H26, "All values are valid", "needs valid input", $errors:H26)}
        {html:build2("H27", $labels:H27, $labels:H27_SHORT, $H27, "All values are valid", "needs valid input", $errors:H27)}
        {html:build2("H28", $labels:H28, $labels:H28_SHORT, $H28, "All values are valid", "not valid", $errors:H28)}
        {html:build2("H29", $labels:H29, $labels:H29_SHORT, $H29, "All values are valid", "not valid", $errors:H29)}
        {html:build2("H30", $labels:H30, $labels:H30_SHORT, $H30, "All values are valid", "needs valid input", $errors:H30)}
        {html:build2("H31", $labels:H31, $labels:H31_SHORT, $H31, "All values are valid", "needs valid input", $errors:H31)}
        {html:build2("H32", $labels:H32, $labels:H32_SHORT, $H32, "All values are valid", "needs valid input", $errors:H32)}
        {html:build2("H33", $labels:H33, $labels:H33_SHORT, $H33, "All values are valid", "not valid", $errors:H33)}
        {html:build2("H34", $labels:H34, $labels:H34_SHORT, $H34, "All values are valid", "needs valid input", $errors:H34)}
        {html:build2("H35", $labels:H35, $labels:H35_SHORT, $H35, "All values are valid", "not valid", $errors:H35)}
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
       {common:runtime("H0",  $ms1H0, $ms2H0)}
       {common:runtime("H01", $ms1H01, $ms2H01)}
       {common:runtime("H02", $ms1H02, $ms2H02)}
       {common:runtime("H03", $ms1H03, $ms2H03)}
       {common:runtime("H04",  $ms1H04, $ms2H04)}
       {common:runtime("H05", $ms1H05, $ms2H05)}
       {common:runtime("H06",  $ms1H06, $ms2H06)}
       {common:runtime("H07",  $ms1H07, $ms2H07)}
       {common:runtime("H08",  $ms1H08, $ms2H08)}
       {common:runtime("H09",  $ms1H09, $ms2H09)}
       {common:runtime("H10",  $ms1H10, $ms2H10)}
       {common:runtime("H11",  $ms1H11, $ms2H11)}
       {common:runtime("H12",  $ms1H12, $ms2H12)}
       {common:runtime("H13",  $ms1H13, $ms2H13)}
       {common:runtime("H15",  $ms1H15, $ms2H15)}
       {common:runtime("H16",  $ms1H16, $ms2H16)}
       {common:runtime("H17",  $ms1H17, $ms2H17)}
       {common:runtime("H18",  $ms1H18, $ms2H18)}
       {common:runtime("H19",  $ms1H19, $ms2H19)}
       {common:runtime("H20",  $ms1H20, $ms2H20)}
       {common:runtime("H21",  $ms1H21, $ms2H21)}
       {common:runtime("H22",  $ms1H22, $ms2H22)}
       {common:runtime("H23",  $ms1H23, $ms2H23)}
       {common:runtime("H24",  $ms1H24, $ms2H24)}
       {common:runtime("H25",  $ms1H25, $ms2H25)}
       {common:runtime("H26",  $ms1H26, $ms2H26)}
       {common:runtime("H27",  $ms1H27, $ms2H27)}
       {common:runtime("H28",  $ms1H28, $ms2H28)}
       {common:runtime("H29",  $ms1H29, $ms2H29)}
       {common:runtime("H30",  $ms1H30, $ms2H30)}
       {common:runtime("H31",  $ms1H31, $ms2H31)}
       {common:runtime("H32",  $ms1H32, $ms2H32)}
       {common:runtime("H33",  $ms1H33, $ms2H33)}
       {common:runtime("H34",  $ms1H34, $ms2H34)}
       {common:runtime("H35",  $ms1H35, $ms2H35)}
       
       {common:runtime("Total time",  $ms1Total, $ms2Total)}
    </table>
    </table>
};

declare function dataflowH:proceed($source_url as xs:string, $countryCode as xs:string) as element(div) {

let $countZones := count(doc($source_url)//aqd:AQD_Plan)
let $result := if ($countZones > 0) then dataflowH:checkReport($source_url, $countryCode) else ()
let $meta := map:merge((
    map:entry("count", $countZones),
    map:entry("header", "Check air quality zones"),
    map:entry("dataflow", "Dataflow H"),
    map:entry("zeroCount", <p>No aqd:AQD_Plan elements found in this XML.</p>),
    map:entry("report", <p>This check evaluated the delivery by executing tier-1 tests on air quality zones data in Dataflow H as specified in <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a>.</p>)
))
return
    html:buildResultDiv($meta, $result)
};
