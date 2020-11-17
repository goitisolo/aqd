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
let $ms1Total := prof:current-ms()

let $ms1GeneralParameters:= prof:current-ms()
    let $docRoot := doc($source_url)
    let $cdrUrl := common:getCdrUrl($countryCode)

    let $reportingYear := common:getReportingYear($docRoot)
    let $namespaces := distinct-values($docRoot//base:namespace)

    let $latestEnvelopeByYearI := query:getLatestEnvelope($cdrUrl || "i/", $reportingYear)
    let $latestEnvelopesD := query:getLatestEnvelopesForObligation("672")
    let $latestEnvelopesD1 := query:getLatestEnvelopesForObligation("742")
    let $latestEnvelopesG := query:getLatestEnvelopesForObligation("679")
    let $latestEnvelopesH := query:getLatestEnvelopesForObligation("680")
    let $latestEnvelopeByCountryG := query:getLatestEnvelope($cdrUrl || "g/")
    let $headerBeginPosition := $docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:beginPosition
    let $headerEndPosition := $docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:endPosition


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

let $ms2GeneralParameters:= prof:current-ms()
    let $ms1NS := prof:current-ms()
    
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

        let $ms2NS := prof:current-ms()

    (: VOCAB check:)
    let $ms1VOCAB := prof:current-ms()
    let $VOCABinvalid := checks:vocab($docRoot)
    let $ms2VOCAB := prof:current-ms()

    (: I0 Check
    Check if delivery if this is a new delivery or updated delivery (via
    reporting year)

    Checks if this delivery is new or an update (on same reporting year)

    WARNING
    :)

    let $ms1I0 := prof:current-ms()
    
    let $I0table :=
        try {
            if ($reportingYear = "") then
                <tr class="{$errors:ERROR}">
                    <td title="Status">Reporting Year is missing.</td>
                </tr>
            else if($headerBeginPosition > $headerEndPosition) then
               <tr class="{$errors:BLOCKER}">
                    <td title="Status">Start position must be less than end position</td>
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

    let $ms2I0 := prof:current-ms()
    
    (: I1

    Compile & feedback upon the total number of Source Apportionments included
    in the delivery

    Number of Source Apportionments reported
    :)
    
    let $ms1I01 := prof:current-ms()
    
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

        let $ms2I01 := prof:current-ms()

    (: I2

    Compile & feedback upon the total number of new  Source Apportionments
    records included in the delivery. ERROR will be returned if XML is a new
    delivery and localId are not new compared to previous deliveries.

    Number of new  Source Apportionments compared to previous report. ERROR
    will be returned if XML is a new delivery and localId are not new compared
    to previous deliveries

    BLOCKER

    :)
    
    let $ms1I02 := prof:current-ms()
    
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
                    <td title="Sparql1">{sparqlx:getLink(query:sparql-objects-in-subject($cdrUrl || "g/", $node-name))}</td>
                    <td title="Sparql2">{sparqlx:getLink(query:sparql-objects-in-subject($latestEnvelopeByYearI,$node-name))}</td>
                    <td title="SparqlQuery">{sparqlx:getLink(query:sparql-objects-ids-query($namespaces, $node-name))}</td>
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
    
    let $ms2I02 := prof:current-ms()
    
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
    
    let $ms1I03 := prof:current-ms()
    
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
                    <td title="Sparql1">{sparqlx:getLink(query:sparql-objects-in-subject($cdrUrl || "g/", $node-name))}</td>
                    <td title="Sparql2">{sparqlx:getLink(query:sparql-objects-in-subject($latestEnvelopeByYearI,$node-name))}</td>
                </tr>
        } catch * {
            html:createErrorRow($err:code, $err:description)
        }
    let $I3errorLevel :=
        if (not($isNewDelivery) and count($I3table) = 0) then
            $errors:I3
        else
            $errors:INFO

    let $ms2I03 := prof:current-ms()
    
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
    
    let $ms1I04 := prof:current-ms()
    
    let $I4table :=
        try {
            let $gmlIds := $sources/lower-case(normalize-space(@gml:id))
            let $inspireIds := $sources/lower-case(normalize-space(aqd:inspireId))

            for $x in $sources
                let $id := $x/@gml:id
                let $inspireId := $x/aqd:inspireId
                let $aqdinspireId := concat($x/aqd:inspireId/base:Identifier/base:namespace, "/", $x/aqd:inspireId/base:Identifier/base:localId)
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
                    <td title="Sparql">{sparqlx:getLink(query:get-pollutant-for-attainment-query($att-url))}</td>
                </tr>
        } catch * {
            html:createErrorRow($err:code, $err:description)
        }

        let $ms2I04 := prof:current-ms()
        
    (: I5 reserved :)
    let $ms1I05 := prof:current-ms()
    let $I5 := ()
    let $ms2I05 := prof:current-ms()

    (: I6 reserved :)
    let $ms1I06 := prof:current-ms()
    let $I6 := ()
    let $ms2I06 := prof:current-ms()

    (: I7

    All gml:id attributes, ef:inspireId and aqd:inspireId elements shall have
    unique content

    All gml ID attributes shall have unique code

    BLOCKER

    :)
    (:let $I7 := try {
        let $checks := ('gml:id', 'base:localId base:namespace', 'ef:inspireId')

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
            (:[
                array:get($errors, 1),
                array:get($errors, 2)
            ]:)
            $errors
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }:)

let $ms1I07 := prof:current-ms()

let $I7 := try {
        let $combinspireid:= (for  $x in $sources
                                let $localId := $x/aqd:inspireId/base:Identifier/lower-case(normalize-space(base:localId))
                                let $namespace := $x/aqd:inspireId/base:Identifier/lower-case(normalize-space(base:namespace))
                                return concat($namespace,"/",$localId)
                            )
        let $combgmlid := $sources/lower-case(normalize-space(@gml:id))

        for $y in $sources
            let $localId := $y/aqd:inspireId/base:Identifier/lower-case(normalize-space(base:localId))
            let $namespace := $y/aqd:inspireId/base:Identifier/lower-case(normalize-space(base:namespace))
            let $aqdinspireId := concat($namespace,"/",$localId)
            let $gmlid := $y/@gml:id
            let $ok := (count(index-of($combinspireid, lower-case(normalize-space($aqdinspireId)))) = 1
                and
                functx:if-empty($aqdinspireId, "") != "")
                and
                (count(index-of($combgmlid, lower-case(normalize-space($gmlid)))) = 1
                and
                functx:if-empty($gmlid, "") != "")


        
            return common:conditionalReportRow(
                    $ok,
                    [
                        ("gml:id", data($y/@gml:id)),
                        ("aqd:inspireId", distinct-values($aqdinspireId))
                    ]
                )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    let $ms2I07 := prof:current-ms()
    
    (: I8

    ./aqd:inspireId/base:Identifier/base:localId must be unique code for the
    Plans records

    Local Id must be unique for the Plans records

    BLOCKER
    :)
    let $ms1I08 := prof:current-ms()
    
    let $I8invalid:= try {
        let $localIds := $sources/aqd:inspireId/base:Identifier/lower-case(normalize-space(base:localId))
        for $x in $sources
            let $localID := $x/aqd:inspireId/base:Identifier/base:localId
            let $aqdinspireId := concat($x/aqd:inspireId/base:Identifier/base:namespace, "/", $x/aqd:inspireId/base:Identifier/base:localId )
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

    let $ms2I08 := prof:current-ms()

    (: I9

    ./aqd:inspireId/base:Identifier/base:namespace

    List base:namespace and count the number of base:localId assigned to each
    base:namespace.

    List unique namespaces used and count number of elements

    BLOCKER
    :)

    let $ms1I09 := prof:current-ms()
    
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
     
    let $ms2I09 := prof:current-ms()
     
    (: I10

    Check that namespace is registered in vocabulary
    (http://dd.eionet.europa.eu/vocabulary/aq/namespace/view)

    Check namespace is registered

    ERROR
    :)
    
    let $ms1I10 := prof:current-ms()
    
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
    
    let $ms2I10 := prof:current-ms()
    
    (: I11

    aqd:AQD_SourceApportionment/aqd:usedInPlan shall reference an existing
    H document for the same reporting year same year via namespace/localId

    You must provide a reference to a plan document from data flow H via its
    namespace & localId. The plan document must have the same reporting year as
    the source apportionment document.

    BLOCKER
    :)
    
    let $ms1I11 := prof:current-ms()
    
    let $I11 := try{
        let $generalData := sparqlx:run(query:existsViaNameLocalIdYearI11QueryGeneral('AQD_Plan',$reportingYear))
                
        for $el in $sources/aqd:usedInPlan

            let $label := functx:if-empty(functx:substring-after-last($el/@xlink:href, "/"), "")

            let $localId:=
                for $nameLocalId in $generalData[sparql:binding[@name='label']/sparql:literal=$label]/sparql:binding[@name='envelope']/sparql:uri
                   return  query:existsViaNameLocalIdYearI11General(
                        $nameLocalId,
                        $latestEnvelopesH
                    )
            let $ok := $localId

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($el/../@gml:id)),
                ("aqd:usedInPlan", $label),
                ("Sparql", sparqlx:getLink(query:existsViaNameLocalIdYearI11Query($label,'AQD_Plan',$reportingYear,$latestEnvelopesH)))
            ]
        )
    } catch * { 
        html:createErrorRow($err:code, $err:description)
    }

    let $ms2I11 := prof:current-ms()

    (: I11b

    aqd:AQD_SourceApportionment/aqd:parentExceedanceSituation shall reference
    an existing exceedance situation delivered within a data flow G and the
    reporting year of G & I shall be the same year via namespace/localId.

    You must provide a reference to an exceedance situation from data flow G.
    The exceedance situation must have the same reporting year as the source
    apportionment and refer to the same pollutant.

    BLOCKER
    :)
    
    let $ms1I12 := prof:current-ms()
    
    let $I12 := try{
        for $node in $sources/aqd:parentExceedanceSituation
            let $link := data($node/@xlink:href)

            let $ok := query:existsViaNameLocalIdYear(
                    $link,
                    'AQD_Attainment',
                    $reportingYear,
                    $latestEnvelopeByCountryG
            )
            (:let $ok := 1 = -1:)

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                (node-name($node), $node/@xlink:href),
                ("test", $link),
                ("test2", $latestEnvelopeByCountryG),
                ("reportingYear", $reportingYear),
                ("Sparql", sparqlx:getLink(query:existsViaNameLocalIdYearQuery($link,'AQD_Attainment',$reportingYear,$latestEnvelopeByCountryG)))
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    let $ms2I12 := prof:current-ms()
    
    (: I13

    aqd:AQD_SourceApportionment/aqd:referenceYear/gml:TimeInstant/gml:timePosition
    shall be a calendar year in yyyy format

    Reference year must be a calendar year in yyyy format

    BLOCKER
    :)

    let $ms1I13 := prof:current-ms()
      
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

    let $ms2I13 := prof:current-ms()
    
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
    
    let $ms1I15 := prof:current-ms()
    
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
    
    let $ms2I15 := prof:current-ms()
    
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
    
    let $ms1I16 := prof:current-ms()
    
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

    let $ms2I16 := prof:current-ms()
    
    (: I17

    Across all the delivery, If aqd:QuantityCommented/aqd:quantity attribute
    xsi:nil="true" aqd:QuantityCommented/aqd:comment must be populated

    If the quantification is voided an explanation is required in aqd:comment

    ERROR
    :)

    let $ms1I17 := prof:current-ms()
    
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
                ("Source fraction", node-name($node/../..)),
                ("aqd:comment missing for", node-name($node/..))

            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    let $ms2I17 := prof:current-ms()

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

    let $ms1I18 := prof:current-ms()
    
    let $I18 := try {

        (:let $sources := $docRoot//aqd:AQD_SourceApportionment:)
        for $quant in $sources//aqd:QuantityCommented/aqd:quantity

            let $uom := data($quant/@uom)
            let $nil := data($quant/@xsi:nil)

            let $node := $quant/ancestor::aqd:AQD_SourceApportionment
            let $att-url := data($node/aqd:parentExceedanceSituation/@xlink:href)
            let $pollutant-code := query:get-pollutant-for-attainment($att-url) (:returns empty list:)

            let $pollutant-code := functx:if-empty($pollutant-code,"")

            let $pollutant := dd:getNameFromPollutantCode($pollutant-code)
            let $rec-uom := dd:getRecommendedUnit($pollutant-code)

            let $ok := (
                        if ($uom = "Unknown" and $nil = "true")
                        then (true())
                        else (if ($pollutant-code = "")
                                then (
                                        false() (:blocker   "Consistency in uom between AQ Plans & Attainment cannot be checked because AQ Plan & Attainment pollutants do not match":)
                                    )
                                else ( 
                                        $uom = $rec-uom (:warning:)
                                    ) 
                            ) 
                        )

        return common:conditionalReportRowI18(
            $ok,
            [
                ("gml:id", data($node/@gml:id)),
                ("Source App uom", $uom),
                ("Attainment uom", $rec-uom),
                ("Sparql", sparqlx:getLink(query:get-pollutant-for-attainment-query($att-url)))
            ]
            )
            

    } catch * {
        html:createErrorRow($err:code, $err:description)
    }


    let $I18errorLevel :=

    for $quant in $sources//aqd:QuantityCommented/aqd:quantity

            let $uom := data($quant/@uom)
            let $nil := data($quant/@xsi:nil)

            let $node := $quant/ancestor::aqd:AQD_SourceApportionment
            let $att-url := data($node/aqd:parentExceedanceSituation/@xlink:href)
            let $pollutant-code := query:get-pollutant-for-attainment($att-url) (:returns empty list:)

            let $pollutant-code := functx:if-empty($pollutant-code,"")

            let $pollutant := dd:getNameFromPollutantCode($pollutant-code)
            let $rec-uom := dd:getRecommendedUnit($pollutant-code)

            return  
            if ($uom = "Unknown" and $nil = "true")
                then ()
                else (if ($pollutant-code = "")
                        then (
                                $errors:BLOCKER
                            )
                        else (if ( $uom = $rec-uom)
                                then()
                                else(
                                    $errors:I18
                                ) 
                        )
                    ) 

let $I18maxErrorLevel := (if ($I18errorLevel = $errors:BLOCKER)
                            then( $errors:BLOCKER )
                            else(if ($I18errorLevel = $errors:WARNING)
                                then( $errors:WARNING )
                                else( $errors:INFO )
                                )
                        )

let $I18errorMessage := (
                            if ($I18errorLevel = $errors:BLOCKER)
                                then ("We could not find the uom in the cited Attainment record cited. Is the provided Attainment record ID correct?")

                                else ($labels:I18)
                            )

    let $ms2I18 := prof:current-ms()
    
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
    
    let $ms1I19 := prof:current-ms()
    
   let $I19 := try {
        for $x in $sources
            let $rb := $x/aqd:regionalBackground/aqd:RegionalBackground
            let $quantity := $rb/aqd:total/aqd:QuantityCommented/aqd:quantity
            let $total := functx:if-empty(data($quantity), 0)
            let $fwm := $rb/aqd:fromWithinMS/aqd:QuantityCommented/aqd:quantity
            let $trans := $rb/aqd:transboundary/aqd:QuantityCommented/aqd:quantity
            let $natural := $rb/aqd:natural/aqd:QuantityCommented/aqd:quantity
            let $other := $rb/aqd:other/aqd:QuantityCommented/aqd:quantity
            let $dec := string-length(substring-after(xs:string($total),"."))

            let $sum := common:sum-of-nodes((
                $fwm,
                $trans,
                $natural,
                $other
            ))

            let $sumRound := round-half-to-even($sum, $dec)
            let $ok := $total = $sumRound

        return common:conditionalReportRowI21I20I19(
            $ok,
            [
                ("gml:id", data($x/@gml:id)),
                ("Total in XML", $total),
                ("sum-of-components", $sumRound),
                ("FromWithinMS", data($fwm)),
                ("Transboundary", data($trans)),
                ("Natural", data($natural)),
                ("Other", data($other))
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }
    
    let $ms2I19 := prof:current-ms()
    
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

    let $ms1I20 := prof:current-ms()

    let $I20 := try {
        for $x in $sources
            let $ub := $x/aqd:urbanBackground/aqd:UrbanBackground
            let $quantity := $ub/aqd:total/aqd:QuantityCommented/aqd:quantity
            let $total := functx:if-empty(data($quantity), 0)

            let $trafic := $ub/aqd:traffic/aqd:QuantityCommented/aqd:quantity
            let $head := $ub/aqd:heatAndPowerProduction/aqd:QuantityCommented/aqd:quantity
            let $agr := $ub/aqd:agriculture/aqd:QuantityCommented/aqd:quantity
            let $comer := $ub/aqd:commercialAndResidential/aqd:QuantityCommented/aqd:quantity
            let $ship := $ub/aqd:shipping/aqd:QuantityCommented/aqd:quantity
            let $offroad := $ub/aqd:offRoadMobileMachinery/aqd:QuantityCommented/aqd:quantity
            let $natural := $ub/aqd:natural/aqd:QuantityCommented/aqd:quantity
            let $transb := $ub/aqd:transboundary/aqd:QuantityCommented/aqd:quantity
            let $other := $ub/aqd:other/aqd:QuantityCommented/aqd:quantity
            let $dec := string-length(substring-after(xs:string($total),"."))



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

            let $sumRound := round-half-to-even($sum, $dec)

            let $ok := $total = $sumRound

        return common:conditionalReportRowI21I20I19(
            $ok,
            [
                ("gml:id", data($x/@gml:id)),
                ("Total in XML", $total),
                ("sum-of-components", $sumRound),
                ("Traffic", data($trafic)),
                ("HeatAndPowerProduction", data($head)),
                ("Agriculture", data($agr)),
                ("CommercialAndResidential", data($comer)),
                ("Shipping", data($ship)),
                ("OffRoadMobileMachinery", data($offroad)),
                ("Natural", data($natural)),
                ("Transboundary", data($transb)),
                ("Other", data($other))
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    let $ms2I20 := prof:current-ms()

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

    let $ms1I21 := prof:current-ms()
    
    let $I21 := try {
        for $x in $sources
            let $li := $x/aqd:localIncrement/aqd:LocalIncrement
            let $quantity := $li/aqd:total/aqd:QuantityCommented/aqd:quantity
            let $total := functx:if-empty(data($quantity), 0)

            let $dec := string-length(substring-after(xs:string($total),"."))

            let $sum := common:sum-of-nodes((
                $li/aqd:traffic/aqd:QuantityCommented/aqd:quantity,
                $li/aqd:heatAndPowerProduction/aqd:QuantityCommented/aqd:quantity,
                $li/aqd:agriculture/aqd:QuantityCommented/aqd:quantity,
                $li/aqd:commercialAndResidential/aqd:QuantityCommented/aqd:quantity,
                $li/aqd:shipping/aqd:QuantityCommented/aqd:quantity,
                $li/aqd:offRoadMobileMachinery/aqd:QuantityCommented/aqd:quantity,
                $li/aqd:natural/aqd:QuantityCommented/aqd:quantity,
                $li/aqd:transboundary/aqd:QuantityCommented/aqd:quantity,
                $li/aqd:other/aqd:QuantityCommented/aqd:quantity
            ))

            let $sumRound := round-half-to-even($sum, $dec)

            let $ok := $total = $sumRound

        return common:conditionalReportRowI21I20I19(
            $ok,
            [
                ("gml:id", data($x/@gml:id)),
                ("Total in XML", $total),
                ("sum-of-components", $sumRound),
                ("Traffic", $li/aqd:traffic/aqd:QuantityCommented/aqd:quantity),
                ("HeatAndPowerProduction",$li/aqd:heatAndPowerProduction/aqd:QuantityCommented/aqd:quantity),
                ("Agriculture", $li/aqd:agriculture/aqd:QuantityCommented/aqd:quantity),
                ("CommercialAndResidential", $li/aqd:commercialAndResidential/aqd:QuantityCommented/aqd:quantity),
                ("Shipping", $li/aqd:shipping/aqd:QuantityCommented/aqd:quantity),
                ("OffRoadMobileMachinery", $li/aqd:offRoadMobileMachinery/aqd:QuantityCommented/aqd:quantity),
                ("Natural", $li/aqd:natural/aqd:QuantityCommented/aqd:quantity),
                ("Transboundary", $li/aqd:transboundary/aqd:QuantityCommented/aqd:quantity),
                ("Other", $li/aqd:other/aqd:QuantityCommented/aqd:quantity)
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    let $ms2I21 := prof:current-ms()
    

    (: I22

    aqd:AQD_SourceApportionment/aqd:macroExceedanceSituation must be presented
    and must not be an empty tag

    The macro exceedance situation relevant to the source apportionment must be
    populated

    Blocker

    :)

    let $ms1I22 := prof:current-ms()
    
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
    
    let $ms2I22 := prof:current-ms()


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
    
    let $ms1I23 := prof:current-ms()
    
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
    
    let $ms2I23 := prof:current-ms()

    (: I24

    The content of
    /aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:areaClassification
    xlink:xref must be provided and must resolve to a areaClassification in
    http://dd.eionet.europa.eu/vocabulary/aq/areaclassification/

    Area Classification is mandatory and must conform to vocabulary

    BLOCKER

    :)
    
    let $ms1I24 := prof:current-ms()
    
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
    
    let $ms2I24 := prof:current-ms()

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
    
    let $ms1I25 := prof:current-ms()
    
    let $I25 := try {
        for $node in $sources/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:areaClassification
            let $areaClassification := data($node/@xlink:href)
            let $parent := $node/ancestor::aqd:AQD_SourceApportionment/aqd:parentExceedanceSituation/@xlink:href
            let $parentAreaClassification := query:get-area-classifications-for-attainment($parent)
            let $parentAreaClassification_query := sparqlx:getLink(query:get-area-classifications-for-attainment-query($parent))

            let $latestParentAreaClassifications :=
                for $result in $parentAreaClassification
                    let $envelope := functx:substring-before-last($result/sparql:binding[@name="aqd_attainment"]/sparql:uri, "/")
                    return
                    if($envelope = $latestEnvelopesG)
                    then
                        $result/sparql:binding[@name="areaClassification"]/sparql:uri
                    else
                        ()
            let $ok := $areaClassification = $latestParentAreaClassifications

        return common:conditionalReportRow(
            $ok,
            [
                (node-name($node/ancestor::aqd:AQD_SourceApportionment), data($node/ancestor::aqd:AQD_SourceApportionment/@gml:id)),
                (node-name($node), $areaClassification),
                ('AQD_Attainment classification', string-join($latestParentAreaClassifications, "&#xa;")),
                ("Sparql", $parentAreaClassification_query)
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }
    
    let $ms2I25 := prof:current-ms()

    (: I26
    /aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:surfaceArea
    uom attribute shall resolve to
    http://dd.eionet.europa.eu/vocabulary/uom/area/km2

    Exceedence area uom attribute must be in Square kilometers.

    ERROR
    :)
    
    let $ms1I26 := prof:current-ms()

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
    
    let $ms2I26 := prof:current-ms()

    (: I27

    /aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:roadLength
    uom attribute shall be http://dd.eionet.europa.eu/vocabulary/uom/length/km

    Exceedence area uom attribute must be in Square kilometers.

    ERROR
    :)
    
    let $ms1I27 := prof:current-ms()
    
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
    
    let $ms2I27 := prof:current-ms()

    (: I28 is missing in XLS :)
    let $ms1I28 := prof:current-ms()
    let $I28 := ()
    let $ms2I28 := prof:current-ms()

    (: I29

    ./aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationUsed
    OR
    ./aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed
    must be populated

    A link to the exceeding SamplingPoint(s) and/or Model(s) must be provided
    [at least one]

    ERROR

    :)
    
    let $ms1I29 := prof:current-ms()
    
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
    
    let $ms2I29 := prof:current-ms()

    (: I30

    If, aqd:stationUsed and/or aqd:modelUsed are populated,
    these must be valid elements:

    stationUsed must link To SamplingPoint via namespace/localid
    modelUsed must link to AQD_Model via namespace/ localid

    If SamplingPoint(s) and/or Model(s) are provided, these must be valid

    ERROR
    :)
    
    let $ms1I30 := prof:current-ms()
    
    let $I30 := try {
        let $elements := (
            "stationUsed",
            "modelUsed"
        )
        
        (::)
        for $elem in $sources//*[local-name() = $elements]
        let $query :=
            if (local-name($elem) = "stationUsed")
            then
                let $allResults_query :=
                    sparqlx:getLink(query:getAllEnvelopesForObjectViaLabelQuery($elem/@xlink:href, "AQD_SamplingPoint"))
                return $allResults_query
        (::)     
        
        for $elem in $sources//*[local-name() = $elements]
        let $ok :=
            if (local-name($elem) = "stationUsed")
            then
                let $allResults :=
                    query:getAllEnvelopesForObjectViaLabel($elem/@xlink:href, "AQD_SamplingPoint")
                let $allResults_query :=
                    sparqlx:getLink(query:getAllEnvelopesForObjectViaLabelQuery($elem/@xlink:href, "AQD_SamplingPoint"))
                for $result in $allResults
                let $envelope := functx:substring-before-last($result/sparql:binding[@name="s"]/sparql:uri, "/")
                return
                    if($envelope = $latestEnvelopesD)
                    then $envelope
                    else ()
            else if(local-name($elem) = "modelUsed")
                then
                    let $allResults :=
                        query:getAllEnvelopesForObjectViaLabel($elem/@xlink:href, "AQD_Model")
                    let $allResults_query :=
                        sparqlx:getLink(query:getAllEnvelopesForObjectViaLabelQuery($elem/@xlink:href, "AQD_Model"))
                    for $result in $allResults
                    let $envelope := functx:substring-before-last($result/sparql:binding[@name="s"]/sparql:uri, "/")
                    return
                        if($envelope = $latestEnvelopesD1)
                        then $envelope
                        else ()
            else
                ()

        return common:conditionalReportRow(
            exists($ok),
            [
                ("gml:id", data($elem/ancestor::aqd:AQD_SourceApportionment/@gml:id)),
                ("element name", node-name($elem)),
                ("element value", $elem/@xlink:href),
                ("Sparql", $query)
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }
    
    let $ms2I30 := prof:current-ms()


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
    TODO: implementation changed, now works but not 100% sure if it's OK

    :)
    
    let $ms1I31 := prof:current-ms()

    let $I31 := try {
        for $node in $sources
            let $att-url := functx:if-empty($node/aqd:parentExceedanceSituation/@xlink:href, "")
            for $modelUsed in $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed
                (: let $model := query:get-used-model-for-attainment($att-url)
                let $model_query := sparqlx:getLink(query:get-used-model-for-attainment-query($att-url)) :)
                let $attainmentsFound := query:getAttainmentForExceedanceArea($att-url,local-name($modelUsed), $modelUsed/@xlink:href)
                let $attainmentsFound_query := sparqlx:getLink(query:getAttainmentForExceedanceAreaQuery($att-url,local-name($modelUsed), $modelUsed/@xlink:href))
                let $attainmentLatest :=
                    for $attainment in $attainmentsFound
                        return
                        if(functx:substring-before-last($attainment, "/") = $latestEnvelopesG)
                        then 1
                        else ()
                let $ok := (
                    count($attainmentsFound) > 0
                    and
                    count($attainmentLatest) > 0
                )
               
                return common:conditionalReportRow(
                    $ok,
                    [
                        ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                        (node-name($modelUsed), $modelUsed/@xlink:href),
                        ("parentExceedanceSituation", $att-url),
                        (:("found model", $model)
                        ("SparqlModel", $model_query), :)
                        ("Sparql", $attainmentsFound_query)  
                    ]
                )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }
    
    let $ms2I31 := prof:current-ms()


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
    TODO: implementation changed, now works but not 100% sure if it's OK
    :)

    let $ms1I32 := prof:current-ms()
    
    let $I32 := try {
        for $node in $sources
            let $att-url := functx:if-empty($node/aqd:parentExceedanceSituation/@xlink:href,"")
            for $stationUsed in $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationUsed
                (: let $model := query:get-used-model-for-attainment($att-url)
                let $model_query := sparqlx:getLink(query:get-used-model-for-attainment-query($att-url)) :)
                let $attainmentsFound := query:getAttainmentForExceedanceArea($att-url,local-name($stationUsed), $stationUsed/@xlink:href)
                let $attainmentsFound_query := sparqlx:getLink(query:getAttainmentForExceedanceAreaQuery($att-url,local-name($stationUsed), $stationUsed/@xlink:href))
                let $attainmentLatest :=
                    for $attainment in $attainmentsFound
                        return
                        if(functx:substring-before-last($attainment, "/") = $latestEnvelopesG)
                        then 1
                        else ()
                let $ok := (
                    count($attainmentsFound) > 0
                    and
                    count($attainmentLatest) > 0
                )
                return common:conditionalReportRow(
                    $ok,
                    [
                        ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                        (node-name($stationUsed), $stationUsed/@xlink:href),
                        ("parentExceedanceSituation", $att-url),
                        (:("found model", $model)
                        ("SparqlModel", $model_query), :)
                        ("Sparql", $attainmentsFound_query) 
                    ]
                )

    } catch * {
        html:createErrorRow($err:code, $err:description)
    }
    
    let $ms2I32 := prof:current-ms()


    (: I33

    ./aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:spatalExtent
    OR
    ./aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:administrativeUnit
    shall be populated

    Spatial extent or administrative unit may be provided

    RESERVE

    :)
    
    let $ms1I33 := prof:current-ms()
    
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
    
    let $ms2I33 := prof:current-ms()

    (: I34

    ./aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:surfaceArea
    OR
    ./aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:roadLength
    shall be populated

    Information on surface are or road lenght shall be provided

    RESERVE
    :)

    let $ms1I34 := prof:current-ms()
    
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
    
    let $ms2I34 := prof:current-ms()

    (: I35
    WHERE
    ./aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedance
    shall EQUAL “true”
    /aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:populationExposed
    shall be populated

    If exceedance is TRUE, information on population exposed must be provided

    RESERVE

    :)
    
    let $ms1I35 := prof:current-ms()

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
    
    let $ms2I35 := prof:current-ms()

    (: I36

    /aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:ecosystemAreaExposed
    shall be populated

    If exceedance is TRUE, information on area exposed must be provided

    RESERVE

    :)
    
    let $ms1I36 := prof:current-ms()

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
    
    let $ms2I36 := prof:current-ms()

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
    
    let $ms1I37 := prof:current-ms()
    
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
                       and 
                       functx:between-inclusive($node, 2010, 2050)

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

    let $ms2I37 := prof:current-ms()

    (: I38

    aqd:AQD_SourceApportionment/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:reason
    shall conform to vocabulary
    http://dd.eionet.europa.eu/vocabulary/aq/exceedancereason/

    Exceedance reason must match vocabulary

    ERROR

    :)
    
    let $ms1I38 := prof:current-ms()
    
    let $I38 := try {
        for $node in $sources/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:reason
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
    
    let $ms2I38 := prof:current-ms()


    (: I39
    /aqd:AQD_SourceApportionment/aqd:macroExceedanceSituation/aqd:ExceedanceDescription
    /aqd:deductionAssessmentMethod/aqd:AdjustmentMethod
    may be populated if ./aqd:pollutant xlink:href attribute EQUALs
    http://dd.eionet.europa.eu/vocabulary/aq/pollutant/[1,5,10,6001]  (via
    …/aqd:parentExceedanceSituation)

    If the pollutant is SO2, PM10, PM2.5 or CO deduction assessment methods may
    be populated

    RESERVE
    :)
    
    let $ms1I39 := prof:current-ms()

    let $I39 := try {
        for $node in $sources
            let $el := $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod
            let $parent := functx:if-empty($node/aqd:parentExceedanceSituation/@xlink:href,"")
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
                ('needed', $needed),
                ("Sparql", sparqlx:getLink(query:get-pollutant-for-attainment-query($parent)))
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }
    
    let $ms2I39 := prof:current-ms()


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
    
    let $ms1I40 := prof:current-ms()

    let $I40 := try {
        for $node in $sources
            let $parent := functx:if-empty($node/aqd:parentExceedanceSituation/@xlink:href,"empty")
            let $pollutant := query:get-pollutant-for-attainment($parent)
            let $ul := $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods/aqd:assessmentType
            let $linkAssesment := $ul/@xlink:href
            
            let $el := $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentType
            let $link := $el/@xlink:href
            let $needed := not(common:is-polutant-air($pollutant))(:) and ($link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/fullyCorrected" or $link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplied"):)
            let $needed2 := common:is-polutant-air($pollutant) and ($link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplicable" or $link = "")
            


            let $ok := 
                if($needed)
                then
                    (:Skip check:)
                    true()
                else if($needed2) then
                        (:Skip check:)
                        true()
                else                 
                    common:isInVocabulary(
                        $linkAssesment,
                        $vocabulary:ASSESSMENTTYPE_VOCABULARY
                    )
        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                (("pollutant"), $pollutant),
                (node-name($el), $link),
                ("Sparql", sparqlx:getLink(query:get-pollutant-for-attainment-query($parent)))
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }
    
    let $ms2I40 := prof:current-ms()


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
    
    let $ms1I41 := prof:current-ms()

    let $I41 := try {
        for $node in $sources
            let $el := $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentTypeDescription
            let $parent := functx:if-empty($node/aqd:parentExceedanceSituation/@xlink:href,"")
            let $pollutant := functx:if-empty(query:get-pollutant-for-attainment($parent),"")

            let $ul := $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentType
            let $linkAjustment := $ul/@xlink:href
            let $assessmentTypeDescriptionEmpty := functx:if-empty($node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods/aqd:assessmentTypeDescription, "")
            
            let $ul := $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentType
            let $linkAjustment := $ul/@xlink:href
            
            let $needed := not(common:is-polutant-air($pollutant))(:) and ($link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/fullyCorrected" or $link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplied"):)
            let $needed2 := common:is-polutant-air($pollutant) and ($linkAjustment = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplicable" or $linkAjustment = "")
            
            let $needed3 := common:is-polutant-air($pollutant)


            let $ok := 
                if($needed) 
                then
                    (:Skip check:)
                    true()
                else if($needed2) 
                     then
                        (:Skip check:)
                        true()
                else
                    common:has-content($el)


        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                (node-name($node), data($node)),
                ("Sparql", sparqlx:getLink(query:get-pollutant-for-attainment-query($parent)))
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }
    
    let $ms2I41 := prof:current-ms()


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

    TODO: $samplingPointAssessmentMetadata and $assessmentMetadata are not filled in
    :)

    (:let $I42 := try {
        let $pollutants := (
            "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/1",
            "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5",
            "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/10",
            "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001"
        )
        let $seq :=
            $sources/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods

        (: modelAssessmentMetadata :)
        (: samplingPointAssessmentMetadata :)
        for $node in $seq
            let $parentExceedanceSituation := $node/ancestor::aqd:AQD_SourceApportionment/aqd:parentExceedanceSituation/@xlink:href
            let $pollutant := query:get-pollutant-for-attainment($parentExceedanceSituation)
            let $ok2 :=
                if($pollutant = $pollutants)
                then
                    let $samplingPointAssessmentMetadata := $node/aqd:samplingPointAssessmentMetadata/@xlink:href
                    let $ok-spa := if(not(empty($samplingPointAssessmentMetadata)))
                        then
                            (:query:existsViaNameLocalId(
                            $samplingPointAssessmentMetadata,
                            "AQD_SamplingPoint",
                            $latestEnvelopesD
                            ):)
                            $samplingPointAssessmentMetadata
                        else
                            true()

                    (:let $modelAssessmentMetadata := $node/aqd:modelAssessmentMetadata/@xlink:href
                    let $ok-ma := if(functx:if-empty($modelAssessmentMetadata, "") != "")
                        then
                            query:existsViaNameLocalId(
                            $modelAssessmentMetadata,
                            "AQD_Model",
                            $latestEnvelopesD1
                            )
                        else
                            true():)

                    (:return $ok-spa and $ok-ma:)
                    return $ok-spa
                else
                    true()
                let $ok := 1 = -1

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                ("aqd:pollutant", $pollutant),
                ("aqd:parentExceedanceSituation", $parentExceedanceSituation),
                ("aqd:samplingPointAssessmentMetadata", $node/aqd:samplingPointAssessmentMetadata/@xlink:href),
                ("aqd:modelAssessmentMetadata", $node/aqd:modelAssessmentMetadata/@xlink:href),
                ("test", $ok2)
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }:)
    
    let $ms1I42 := prof:current-ms()
    
    let $I42 := try {
       
        let $seq :=
            $sources/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods

        (: modelAssessmentMetadata :)
        (: samplingPointAssessmentMetadata :)
        for $node in $seq
            let $parentExceedanceSituation := $node/ancestor::aqd:AQD_SourceApportionment/aqd:parentExceedanceSituation/@xlink:href
            let $pollutant := query:get-pollutant-for-attainment($parentExceedanceSituation)
            (:let $modelAssessmentMetadata := $node/aqd:modelAssessmentMetadata/@xlink:href:)
            let $modelAssessmentMetadata := 
                if(local-name($node) = "modelAssessmentMetadata")
                then
                    let $modelAssessmentMetadata := $node/aqd:modelAssessmentMetadata/@xlink:href
                    return $modelAssessmentMetadata
            
            let $poll := common:is-polutant-air($pollutant)
            
            let $ok-ma := if(fn:empty($modelAssessmentMetadata))
                          then
                            false()
                            (:for $ma in $modelAssessmentMetadata
                              return
                                query:existsViaNameLocalId(
                                $ma,
                                "AQD_Model",
                                $latestEnvelopesD1
                                ):)
                          else
                            for $ma in $modelAssessmentMetadata
                              return
                                query:existsViaNameLocalId(
                                $ma,
                                "AQD_Model",
                                $latestEnvelopesD1
                                )
                                (:true():)
            
            let $sparql_query := if(fn:empty($modelAssessmentMetadata))
                                   then
                                    "No modelAssessmentMetadata to execute this query"
                                   else
                                    sparqlx:getLink(query:existsViaNameLocalIdQuery($modelAssessmentMetadata, "AQD_Model", $latestEnvelopesD1))
            
            let $ul := $node/../../aqd:adjustmentType
            let $linkAjustment := $ul/@xlink:href
            
            let $needed := not(common:is-polutant-air($pollutant))(:) and ($link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/fullyCorrected" or $link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplied"):)
            let $needed2 := common:is-polutant-air($pollutant) and ($linkAjustment = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplicable" or $linkAjustment = "")
            

            let $check := not(common:is-polutant-air($pollutant))
            let $ok := 
                            if($needed) 
                            then
                                (:Skip check:)
                                true()
                            else if($needed2) 
                                 then
                                    (:Skip check:)
                                    true()
                            else if($poll and $modelAssessmentMetadata = "" and $ok-ma = false())                           
                            then
                                true()
                            else
                                false()
                                        

            

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                ("aqd:pollutant", $pollutant),
                ("aqd:parentExceedanceSituation", $parentExceedanceSituation),
                ("test", $modelAssessmentMetadata),
                (: ("Sparql", sparqlx:getLink(query:existsViaNameLocalIdQuery($modelAssessmentMetadata, "AQD_Model", $latestEnvelopesD1))) :)
                (: ("Sparql", sparqlx:getLink(query:existsViaNameLocalIdQuery(data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id), "AQD_Model", $latestEnvelopesD1))), :)
                ("Sparql", $sparql_query),
                ("SparqlQueryPollutant", sparqlx:getLink(query:get-pollutant-for-attainment-query($parentExceedanceSituation)))
            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }

    let $I42errorLevel := try {
           
            let $seq :=
                $sources/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods

            (: modelAssessmentMetadata :)
            (: samplingPointAssessmentMetadata :)
            for $node in $seq
              (:)  let $parentExceedanceSituation := $node/ancestor::aqd:AQD_SourceApportionment/aqd:parentExceedanceSituation/@xlink:href
                let $pollutant := query:get-pollutant-for-attainment($parentExceedanceSituation)
                let $modelAssessmentMetadata := $node/aqd:modelAssessmentMetadata/@xlink:href
                let $samplingPointAssessmentMetadata := $node/aqd:samplingPointAssessmentMetadata/@xlink:href
                let $poll := common:is-polutant-air($pollutant)
                let $ok-ma := 
                                if(fn:empty($modelAssessmentMetadata))
                                then
                                    false()
                                else
                                     for $ma in $modelAssessmentMetadata
                                     return
                                            query:existsViaNameLocalId(
                                                $ma,
                                                "AQD_Model",
                                                $latestEnvelopesD1
                                            )
                                            

                let $check := not(common:is-polutant-air($pollutant))
           
                    return 
                        if (not($poll) and $modelAssessmentMetadata != "")
                        then
                            $errors:WARNING
                        else if(not($poll) and $modelAssessmentMetadata = "" and $ok-ma = false())
                        then 
                            $errors:ERROR
                        else
                            $errors:INFO:)

                let $parentExceedanceSituation := $node/ancestor::aqd:AQD_SourceApportionment/aqd:parentExceedanceSituation/@xlink:href
                let $pollutant := query:get-pollutant-for-attainment($parentExceedanceSituation)
                let $modelAssessmentMetadata := $node/aqd:modelAssessmentMetadata/@xlink:href
                let $ul := $node/../../aqd:adjustmentType
                let $linkAjustment := $ul/@xlink:href
                
                let $needed := not(common:is-polutant-air($pollutant))(:) and ($link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/fullyCorrected" or $link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplied"):)
                let $needed2 := common:is-polutant-air($pollutant) and ($linkAjustment = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplicable" or $linkAjustment = "")
                let $samplingPointAssessmentMetadata := $node/aqd:samplingPointAssessmentMetadata/@xlink:href
                
                let $modelAssessmentMetadata := $node/aqd:modelAssessmentMetadata/@xlink:href
                let $ok-ma := if(functx:if-empty($modelAssessmentMetadata, "") != "")
                    then
                        query:existsViaNameLocalId(
                        $modelAssessmentMetadata,
                        "AQD_Model",
                        $latestEnvelopesD1
                        )
                    else
                        true()


                return
                            if($needed) 
                            then
                                (:Skip check:)
                                $errors:INFO
                            else if($needed2) 
                                 then
                                    (:Skip check:)
                                    $errors:INFO
                            else if ($ok-ma) then

                                        $errors:ERROR

                                    else 
                                        $errors:INFO
                
          
        } catch * {
            html:createErrorRow($err:code, $err:description)
        }

        let $I42maxErrorLevel := (if ($I42errorLevel = $errors:ERROR)
                            then( $errors:ERROR )
                            else(if ($I42errorLevel = $errors:WARNING)
                                then( $errors:WARNING )
                                else( $errors:INFO )
                                )
                        )

        let $I42errorMessage := (
                            if ($I18errorLevel = $errors:WARNING)
                                then ("No assessment information for NS and WSS correction is expected for this pollutant")

                                else ($labels:I42)
                            )
                            
     let $ms2I42 := prof:current-ms()                     
                            
     (:let $I42errorLevel :=

            let $pollutants := (
                        "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/1",
                        "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5",
                        "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/10",
                        "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001"
                    )
                    let $seq :=
                        $sources/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods

                    (: modelAssessmentMetadata :)
                    (: samplingPointAssessmentMetadata :)
                    for $node in $seq
                        let $parentExceedanceSituation := $node/ancestor::aqd:AQD_SourceApportionment/aqd:parentExceedanceSituation/@xlink:href
                        let $pollutant := query:get-pollutant-for-attainment($parentExceedanceSituation)
                        let $ok :=
                            if($pollutant = $pollutants and )
                            then
                                let $samplingPointAssessmentMetadata := $node/aqd:samplingPointAssessmentMetadata/@xlink:href
                                let $ok-spa := if(functx:if-empty($samplingPointAssessmentMetadata, "") != "")
                                    then
                                        query:existsViaNameLocalId(
                                        $samplingPointAssessmentMetadata,
                                        "AQD_SamplingPoint",
                                        $latestEnvelopesD
                                        )
                                    else
                                        true()

                                let $modelAssessmentMetadata := $node/aqd:modelAssessmentMetadata/@xlink:href
                                let $ok-ma := if(functx:if-empty($modelAssessmentMetadata, "") != "")
                                    then
                                        query:existsViaNameLocalId(
                                        $modelAssessmentMetadata,
                                        "AQD_Model",
                                        $latestEnvelopesD1
                                        )
                                    else
                                        true()

                                return $ok-spa and $ok-ma
                            else
                                true()


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
:)
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
    
    let $ms1I43 := prof:current-ms()

    let $I43 := try {
        let $seq :=
            $sources/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods

        (: modelAssessmentMetadata :)
        (: samplingPointAssessmentMetadata :)
        for $node in $seq
            let $parentExceedanceSituation := $node/ancestor::aqd:AQD_SourceApportionment/aqd:parentExceedanceSituation/@xlink:href
            let $pollutant := query:get-pollutant-for-attainment($parentExceedanceSituation)
            let $samplingPointAssessmentMetadata := $node/aqd:samplingPointAssessmentMetadata/@xlink:href
            let $poll := common:is-polutant-air($pollutant)

            let $ok-spa := if(fn:empty($samplingPointAssessmentMetadata))
                            then
                                false()
                            else
                            for $sa in $samplingPointAssessmentMetadata
                                return
                                
                                     query:existsViaNameLocalId(
                                     $sa,
                                     "AQD_SamplingPoint",
                                     $latestEnvelopesD
                                     )
                                     
            let $sparql_query := if(fn:empty($samplingPointAssessmentMetadata))
                            then
                                "No samplingPointAssessmentMetadata to execute this query"
                            else
                                sparqlx:getLink(query:existsViaNameLocalIdQuery($samplingPointAssessmentMetadata, "AQD_SamplingPoint", $latestEnvelopesD))
                                                       
            let $ul := $node/../../aqd:adjustmentType
            let $linkAjustment := $ul/@xlink:href
            
            let $needed := not(common:is-polutant-air($pollutant))(:) and ($link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/fullyCorrected" or $link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplied"):)
            let $needed2 := common:is-polutant-air($pollutant) and ($linkAjustment = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplicable" or $linkAjustment = "")
            
             
            let $check := not(common:is-polutant-air($pollutant))
            let $ok :=

                 if($needed) 
                    then
                        (:Skip check:)
                        true()
                    else if($needed2) 
                         then
                            (:Skip check:)
                            true()            
                   else if (not($poll) and $samplingPointAssessmentMetadata != "")
                    then
                        true()
                    else if($poll and $samplingPointAssessmentMetadata = "" and $ok-spa = false())
                    then 
                        true()
                    else
                        false()

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id)),
                ("aqd:pollutant", $pollutant),
                ("aqd:parentExceedanceSituation", $parentExceedanceSituation),
                ("aqd:samplingPointAssessmentMetadata", $ok-spa),
                ("test", $samplingPointAssessmentMetadata),
                (: ("Sparql", sparqlx:getLink(query:existsViaNameLocalIdQuery($samplingPointAssessmentMetadata, "AQD_SamplingPoint", $latestEnvelopesD))) :)
                (: ("Sparql", sparqlx:getLink(query:existsViaNameLocalIdQuery(data($node/ancestor-or-self::aqd:AQD_SourceApportionment/@gml:id), "AQD_SamplingPoint", $latestEnvelopesD))) :)
                ("Sparql", $sparql_query)

            ]
        )
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }


    let $I43errorLevel := try {
        let $seq :=
            $sources/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods

        (: modelAssessmentMetadata :)
        (: samplingPointAssessmentMetadata :)
        for $node in $seq
            let $parentExceedanceSituation := $node/ancestor::aqd:AQD_SourceApportionment/aqd:parentExceedanceSituation/@xlink:href
            let $pollutant := query:get-pollutant-for-attainment($parentExceedanceSituation)
            let $samplingPointAssessmentMetadata := $node/aqd:samplingPointAssessmentMetadata/@xlink:href
            let $poll := common:is-polutant-air($pollutant)

            let $ok-spa := if(fn:empty($samplingPointAssessmentMetadata))
                            then
                                false()
                            else
                            for $sa in $samplingPointAssessmentMetadata
                                return
                                
                                     query:existsViaNameLocalId(
                                     $sa,
                                     "AQD_SamplingPoint",
                                     $latestEnvelopesD
                                     )
            

            let $ul := $node/../../aqd:adjustmentType
            let $linkAjustment := $ul/@xlink:href
            
            let $needed := not(common:is-polutant-air($pollutant))(:) and ($link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/fullyCorrected" or $link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplied"):)
            let $needed2 := common:is-polutant-air($pollutant) and ($linkAjustment = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplicable" or $linkAjustment = "")
            
                               

            let $check := not(common:is-polutant-air($pollutant))
            return
                if($needed) 
                    then
                        (:Skip check:)
                        $errors:INFO
                else if($needed2) 
                     then
                        (:Skip check:)
                        $errors:INFO           
                else if (not($poll) and $samplingPointAssessmentMetadata != "")
                then
                     $errors:ERROR
                else if($poll and $samplingPointAssessmentMetadata = "" and $ok-spa = false())
                then 
                      $errors:ERROR
                else
                      $errors:INFO

       
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }
    
    let $ms2I43 := prof:current-ms()

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

   (:) let $I44error := 
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
            let $needed := common:is-polutant-I40($pollutant)
            let $validation1 := $needed and $link !="http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplicable"
            let $validation2 := count(not($link ="http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplied" or $link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/fullyCorrected"))

            return 
                if ($needed and $link !="http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplicable")
                then
                    1
                else if (not($link ="http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplied" or $link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/fullyCorrected"))
                then
                    2
                else 
                    0
:)

    let $ms1I44 := prof:current-ms()
    
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
            let $needed := common:is-polutant-air($pollutant) and not($link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/fullyCorrected" or $link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplied")
            let $needed2 := not(common:is-polutant-air($pollutant)) and $link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplicable"
            
            let $ul := $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentType
            let $linkAjustment := $ul/@xlink:href
            
            let $neededAll := not(common:is-polutant-air($pollutant))(:) and ($link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/fullyCorrected" or $link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplied"):)
            let $neededAll2 := common:is-polutant-air($pollutant) and ($linkAjustment = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplicable" or $linkAjustment = "")
            
                    
            let $ok :=
               if($neededAll) 
                    then
                        (:Skip check:)
                        true()
                else if($neededAll2) 
                    then
                       (:Skip check:)
                       true()       
                else if($needed) 
                    then
                    false()
                else if($needed2)
                then
                    false()
                else 
                    true()
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
    
    let $I44errorLevel := try {
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
            let $needed := common:is-polutant-air($pollutant) and not($link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/fullyCorrected" or $link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplied")
            let $needed2 := not(common:is-polutant-air($pollutant)) and $link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplicable"
            
            let $ul := $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentType
            let $linkAjustment := $ul/@xlink:href
            
            let $neededAll := not(common:is-polutant-air($pollutant))(:) and ($link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/fullyCorrected" or $link = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplied"):)
            let $neededAll2 := $linkAjustment = "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplicable" or $linkAjustment = ""
            
                    
            return
               if($neededAll) 
                    then
                        (:Skip check:)
                        $errors:INFO
                else if($neededAll2) 
                    then
                       (:Skip check:)
                       $errors:INFO       
                else if ($needed)
                then
                    $errors:I44
                else if($needed2)
                then
                    $errors:WARNING 
                else 
                    $errors:INFO
     
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }


let $I44maxErrorLevel := (if ($I44errorLevel = $errors:ERROR)
                            then( $errors:I44 )
                            else(if ($I44errorLevel = $errors:WARNING)
                                then( $errors:WARNING )
                                else( $errors:INFO )
                                )
                        )

let $I44errorMessage := (
                            if ($I44errorLevel = $errors:WARNING)
                                then ("Only source apportionment information with all corrections available to you applied are expected or no corrections at all. If you excpect other NS or WSS contributions exist for which you have no details, please use fullyCorrected. If you have no information to correct for them use noneApplied")
                                else ($labels:I44)
                            )

    let $ms2I44 := prof:current-ms()

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
    
    let $ms1I45 := prof:current-ms()
    
    let $I45 := try {
        for $node in $sources
            let $parent := functx:if-empty($node/aqd:parentExceedanceSituation/@xlink:href,"")
            let $pollutant := query:get-pollutant-for-attainment($parent)
            let $needed := common:is-polutant-air($pollutant)

            for $el in $node/aqd:macroExceedanceSituation/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentSource
            
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
    
    let $ms2I45 := prof:current-ms()

let $ms2Total := prof:current-ms()
    return
        <table class="maintable hover">
        
        <table>
        {html:build2("NS", $labels:NAMESPACES, $labels:NAMESPACES_SHORT, $NSinvalid, "All values are valid", "record", $errors:NS)}
        {html:build2("VOCAB", $labels:VOCAB, $labels:VOCAB_SHORT, $VOCABinvalid, "All values are valid", "record", $errors:VOCAB)}
        {html:build3("I0", $labels:I0, $labels:I0_SHORT, $I0table, string($I0table/td), errors:getMaxError($I0table))}
        {html:build1("I1", $labels:I1, $labels:I1_SHORT, $tblAllSources, "", string($countSources), "", "", $errors:I1)}
        {html:buildSimpleSparql("I2", $labels:I2, $labels:I2_SHORT, $I2table, "", "report", $I2errorLevel)}
        {html:buildSimpleSparql("I3", $labels:I3, $labels:I3_SHORT, $I3table, "", "", $I3errorLevel)}
        {html:build1Sparql("I4", $labels:I4, $labels:I4_SHORT, $I4table, "", string(count($I4table)), " ", "", $errors:I4)}
        {html:build1("I5", $labels:I5, $labels:I5_SHORT, $I5, "RESERVE", "RESERVE", "RESERVE", "RESERVE", $errors:I5)}
        {html:build1("I6", $labels:I6, $labels:I6_SHORT, $I6, "RESERVE", "RESERVE", "RESERVE", "RESERVE", $errors:I6)}
        {html:build2("I7", $labels:I7, $labels:I7_SHORT, $I7, "No duplicate values found", " duplicate value", $errors:I7)}
        {html:build2("I8", $labels:I8, $labels:I8_SHORT, $I8invalid, "No duplicate values found", " duplicate value", $errors:I8)}
        {html:build2("I9", $labels:I9, $labels:I9_SHORT, $I9table, "namespace", "", $errors:I9)}
        {html:build2("I10", $labels:I10, $labels:I10_SHORT, $I10invalid, "All values are valid", " not conform to vocabulary", $errors:I10)}

        {html:build2Sparql("I11", $labels:I11, $labels:I11_SHORT, $I11,
                     "All values are valid", "needs valid input", $errors:I11)}
        <!--{html:build2("I12", $labels:I12, $labels:I12_SHORT, $I12,"All values are valid", "needs valid input", $errors:I12)}-->
        {html:build2Sparql("I12", $labels:I12, $labels:I12_SHORT, $I12,"All values are valid", "needs valid input", $errors:I12)}
        {html:build2("I13", $labels:I13, $labels:I13_SHORT, $I13, "All values are valid", "needs valid input", $errors:I13)}
        {html:build2("I15", $labels:I15, $labels:I15_SHORT, $I15, "All values are valid", "needs valid input", $errors:I15)}
        {html:build2("I16", $labels:I16, $labels:I16_SHORT, $I16, "All values are valid", "needs valid input", $errors:I16)}
        {html:build2("I17", $labels:I17, $labels:I17_SHORT, $I17, "All values are valid", "needs valid input", $errors:I17)}
        {html:build2Sparql("I18", $I18errorMessage, $labels:I18_SHORT, $I18, "All values are valid", "needs valid input", $I18maxErrorLevel)}
        {html:build2("I19", $labels:I19, $labels:I19_SHORT, $I19, "All values are valid", "needs valid input", $errors:I19)}
        {html:build2("I20", $labels:I20, $labels:I20_SHORT, $I20, "All values are valid", "needs valid input", $errors:I20)}
        {html:build2("I21", $labels:I21, $labels:I21_SHORT, $I21, "All values are valid", "needs valid input", $errors:I21)}
        {html:build2("I22", $labels:I22, $labels:I22_SHORT, $I22, "All values are valid", "needs valid input", $errors:I22)}
        {html:build2("I23", $labels:I23, $labels:I23_SHORT, $I23, "All values are valid", "needs valid input", $errors:I23)}
        {html:build2("I24", $labels:I24, $labels:I24_SHORT, $I24, "All values are valid", "needs valid input", $errors:I24)}
        {html:build2Sparql("I25", $labels:I25, $labels:I25_SHORT, $I25, "All values are valid", "needs valid input", $errors:I25)}
        {html:build2("I26", $labels:I26, $labels:I26_SHORT, $I26, "All values are valid", "needs valid input", $errors:I26)}
        {html:build2("I27", $labels:I27, $labels:I27_SHORT, $I27, "All values are valid", "needs valid input", $errors:I27)}
        {
        (: 28 is missing in XLS
        {html:build2("I28", $labels:I28, $labels:I28_SHORT, $I28, "All values are valid", "needs valid input", $errors:I28)}
        :)
        }
        {html:build2("I29", $labels:I29, $labels:I29_SHORT, $I29, "All values are valid", "needs valid input", $errors:I29)}
        <!-- {html:build2("I30", $labels:I30, $labels:I30_SHORT, $I30, "All values are valid", "needs valid input", $errors:I30)} -->
        {html:build2Sparql("I30", $labels:I30, $labels:I30_SHORT, $I30, "All values are valid", "needs valid input", $errors:I30)}
        {html:build2Sparql("I31", $labels:I31, $labels:I31_SHORT, $I31, "All values are valid", "needs valid input", $errors:I31)}
        {html:build2Sparql("I32", $labels:I32, $labels:I32_SHORT, $I32, "All values are valid", "needs valid input", $errors:I32)}
        {html:build2("I33", $labels:I33, $labels:I33_SHORT, $I33, "All values are valid", "needs valid input", $errors:I33)}
        {html:build2("I34", $labels:I34, $labels:I34_SHORT, $I34, "All values are valid", "needs valid input", $errors:I34)}
        {html:build2("I35", $labels:I35, $labels:I35_SHORT, $I35, "All values are valid", "needs valid input", $errors:I35)}
        <!--{html:build2("I36", $labels:I36, $labels:I36_SHORT, $I36, "All values are valid", "needs valid input", $errors:I36)}-->
        {html:build2("I37", $labels:I37, $labels:I37_SHORT, $I37, "All values are valid", "needs valid input", $errors:I37)}
        {html:build2("I38", $labels:I38, $labels:I38_SHORT, $I38, "All values are valid", "needs valid input", $errors:I38)}
        <!--{html:build2("I39", $labels:I39, $labels:I39_SHORT, $I39, "All values are valid", "needs valid input", $errors:I39)}-->
        {html:build2Sparql("I39", $labels:I39, $labels:I39_SHORT, $I39, "All values are valid", "needs valid input", $errors:I39)}
        {html:build2Sparql("I40", $labels:I40, $labels:I40_SHORT, $I40, "All values are valid", "needs valid input", $errors:I40)}
        {html:build2Sparql("I41", $labels:I41, $labels:I41_SHORT, $I41, "All values are valid", "needs valid input", $errors:I41)}
        {html:build2Sparql("I42", $labels:I42, $labels:I42_SHORT, $I42, "All values are valid", "needs valid input", $errors:I42)}
        {html:build2Sparql("I43", $labels:I43, $labels:I43_SHORT, $I43, "All values are valid", "needs valid input", $errors:I43)}
        {html:build2("I44", $I44errorMessage, $labels:I44_SHORT, $I44, "All values are valid", "needs valid input", $I44maxErrorLevel)}
        <!--{html:build2("I45", $labels:I45, $labels:I45_SHORT, $I45, "All values are valid", "needs valid input", $errors:I45)}-->
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
             {common:runtime("I0", $ms1I0, $ms2I0)}
             {common:runtime("I01", $ms1I01, $ms2I01)}
             {common:runtime("I02", $ms1I02, $ms2I02)}
             {common:runtime("I03", $ms1I03, $ms2I03)} 
             {common:runtime("I04", $ms1I04, $ms2I04)}
             {common:runtime("I05", $ms1I05, $ms2I05)}
             {common:runtime("I06", $ms1I06, $ms2I06)}
             {common:runtime("I07", $ms1I07, $ms2I07)}
             {common:runtime("I08", $ms1I08, $ms2I08)}
             {common:runtime("I09", $ms1I09, $ms2I09)}
             {common:runtime("I10", $ms1I10, $ms2I10)}
             {common:runtime("I11", $ms1I11, $ms2I11)}
             {common:runtime("I12", $ms1I12, $ms2I12)}
             {common:runtime("I13", $ms1I13, $ms2I13)}
             {common:runtime("I15", $ms1I15, $ms2I15)}
             {common:runtime("I16", $ms1I16, $ms2I16)}
             {common:runtime("I17", $ms1I17, $ms2I17)}
             {common:runtime("I18", $ms1I18, $ms2I18)}
             {common:runtime("I19", $ms1I19, $ms2I19)}
             {common:runtime("I20", $ms1I20, $ms2I20)}
             {common:runtime("I21", $ms1I21, $ms2I21)}
             {common:runtime("I22", $ms1I22, $ms2I22)}
             {common:runtime("I23", $ms1I23, $ms2I23)}
             {common:runtime("I24", $ms1I24, $ms2I24)}
             {common:runtime("I25", $ms1I25, $ms2I25)}
             {common:runtime("I26", $ms1I26, $ms2I26)}
             {common:runtime("I27", $ms1I27, $ms2I27)}
             <!-- {common:runtime("I28", $ms1I28, $ms2I28)} -->
             {common:runtime("I29", $ms1I29, $ms2I29)}
             {common:runtime("I30", $ms1I30, $ms2I30)}
             {common:runtime("I31", $ms1I31, $ms2I31)}
             {common:runtime("I32", $ms1I32, $ms2I32)}
             {common:runtime("I33", $ms1I33, $ms2I33)}
             {common:runtime("I34", $ms1I34, $ms2I34)}
             {common:runtime("I35", $ms1I35, $ms2I35)}
             <!-- {common:runtime("I36", $ms1I36, $ms2I36)} -->
             {common:runtime("I37", $ms1I37, $ms2I37)}
             {common:runtime("I38", $ms1I38, $ms2I38)}
             {common:runtime("I39", $ms1I39, $ms2I39)}
             {common:runtime("I40", $ms1I40, $ms2I40)}
             {common:runtime("I41", $ms1I41, $ms2I41)}
             {common:runtime("I42", $ms1I42, $ms2I42)}
             {common:runtime("I43", $ms1I43, $ms2I43)}
             {common:runtime("I44", $ms1I44, $ms2I44)}
             <!-- {common:runtime("I45", $ms1I45, $ms2I45)} -->
             
       {common:runtime("Total time",  $ms1Total, $ms2Total)}
        </table>

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
