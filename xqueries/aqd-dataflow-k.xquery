xquery version "3.0" encoding "UTF-8";
(:
 : Module Name: Implementing Decision 2011/850/EU: AQ info exchange & reporting (Library module)
 :
 : Version:     $Id$
 : Created:     9 November 2017
 : Copyright:   European Environment Agency
 :
 : XQuery script implements dataflow K checks.
 :
 : @author Laszlo Cseh
 :)

module namespace dataflowK = "http://converters.eionet.europa.eu/dataflowK";

import module namespace common = "aqd-common" at "aqd-common.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";
import module namespace sparqlx = "aqd-sparql" at "aqd-sparql.xquery";
import module namespace labels = "aqd-labels" at "aqd-labels.xquery";
import module namespace vocabulary = "aqd-vocabulary" at "aqd-vocabulary.xquery";
import module namespace query = "aqd-query" at "aqd-query.xquery";
import module namespace errors = "aqd-errors" at "aqd-errors.xquery";
import module namespace dd = "aqd-dd" at "aqd-dd.xquery";
import module namespace checks = "aqd-checks" at "aqd-checks.xq";
import module namespace functx = "http://www.functx.com" at "functx-1.0-doc-2007-01.xq";

(:import module namespace filter = "aqd-filter" at "aqd-filter.xquery";:)
(:import module namespace schemax = "aqd-schema" at "aqd-schema.xquery";:)
(:import module namespace geox = "aqd-geo" at "aqd-geo.xquery";
import module namespace functx = "http://www.functx.com" at "aqd-functx.xq";:)

declare namespace aqd = "http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0";
declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace am = "http://inspire.ec.europa.eu/schemas/am/3.0";
declare namespace base = "http://inspire.ec.europa.eu/schemas/base/3.3";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace adms = "http://www.w3.org/ns/adms#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";

(:declare namespace ef = "http://inspire.ec.europa.eu/schemas/ef/3.0";:)
(:declare namespace ad = "urn:x-inspire:specification:gmlas:Addresses:3.0";:)
(:declare namespace gn = "urn:x-inspire:specification:gmlas:GeographicalNames:3.0";:)
(:declare namespace base2 = "http://inspire.ec.europa.eu/schemas/base2/1.0";:)
(:declare namespace om = "http://www.opengis.net/om/2.0";:)
(:declare namespace swe = "http://www.opengis.net/swe/2.0";:)
(:declare namespace ompr="http://inspire.ec.europa.eu/schemas/ompr/2.0";:)
(:declare namespace sams="http://www.opengis.net/samplingSpatial/2.0";:)
(:declare namespace sam = "http://www.opengis.net/sampling/2.0";:)
(:declare namespace gmd = "http://www.isotc211.org/2005/gmd";:)
(:declare namespace gco = "http://www.isotc211.org/2005/gco";:)

(:declare namespace prop = "http://dd.eionet.europa.eu/property/";:)

declare variable $dataflowK:OBLIGATIONS as xs:string* := ($vocabulary:ROD_PREFIX || "683");

(: These attributes should be unique :)
declare variable $dataflowK:UNIQUE_IDS as xs:string* := (
  "gml:id",
  "ef:inspireId",
  "aqd:inspireId"
);


(: Rule implementations :)
declare function dataflowK:checkReport($source_url as xs:string, $countryCode as xs:string) as element(table) {
  
let $ms1Total := prof:current-ms()  
let $ms1GeneralParameters:= prof:current-ms()  

let $envelopeUrl := common:getEnvelopeXML($source_url)
let $docRoot := doc($source_url)
(: cdr.eionet.europa.eu/be/eu/aqd/ :)
let $cdrUrl := common:getCdrUrl($countryCode)
let $bdir := if (contains($source_url, "k_preliminary")) then "k_preliminary/" else "k/"
(: 2004  :)
let $reportingYear := common:getReportingYear($docRoot)
let $latestEnvelopeB := query:getLatestEnvelope($cdrUrl || $bdir, $reportingYear)
let $nameSpaces := distinct-values($docRoot//base:namespace)
let $zonesNamespaces := distinct-values($docRoot//aqd:AQD_Zone/am:inspireId/base:Identifier/base:namespace)

let $latestEnvelopeByYearK := query:getLatestEnvelope($cdrUrl || "k/", $reportingYear)

let $latestEnvelopesG := query:getLatestEnvelopesForObligation("679")
let $latestEnvelopesI := query:getLatestEnvelopesForObligation("681")
let $latestEnvelopesJ := query:getLatestEnvelopesForObligation("682")
let $latestEnvelopesK := query:getLatestEnvelopesForObligation("683")
let $latestEnvelopeK := query:getLatestEnvelope($cdrUrl || "k", $reportingYear)

let $headerBeginPosition := $docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:beginPosition
let $headerEndPosition := $docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:endPosition

let $namespaces := distinct-values($docRoot//base:namespace)
let $ancestor-name := "aqd:AQD_Measures"

let $ms2GeneralParameters:= prof:current-ms()

let $knownMeasures := distinct-values(data(sparqlx:run(query:getMeasures($latestEnvelopeK))/sparql:binding[@name = 'localId']/sparql:literal))
(:let $knownMeasures := sparqlx:run(query:getMeasures($latestEnvelopeK)):)

(:let $knownRegimes := distinct-values(data(sparqlx:run(query:getAssessmentRegime($latestEnvelopeC))/sparql:binding[@name = 'inspireLabel']/sparql:literal)):)
(:/sparql:binding[@name = 'localId']/sparql:literal:)




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

(: K0 Checks if this delivery is new or an update (on same reporting year) :)

let $ms1K0 := prof:current-ms()

let $K0table := try {
    if ($reportingYear = "")
    then
        common:checkDeliveryReport($errors:BLOCKER, "Reporting Year is missing.")
   
    else if($headerBeginPosition > $headerEndPosition) then
        <tr class="{$errors:BLOCKER}">
            <td title="Status">Start position must be less than end position</td>
        </tr>
    else
        if (query:deliveryExists($dataflowK:OBLIGATIONS, $countryCode, "k/", $reportingYear))
            then
                common:checkDeliveryReport($errors:WARNING, "Updating delivery for " || $reportingYear)
            else
                common:checkDeliveryReport($errors:INFO, "New delivery for " || $reportingYear)
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $isNewDelivery := errors:getMaxError($K0table) = $errors:INFO
let $knownMeasures :=
    if ($isNewDelivery)
    then
        distinct-values(data(sparqlx:run(query:getMeasures($cdrUrl || "k/"))//sparql:binding[@name='inspireLabel']/sparql:literal))
    else
        distinct-values(data(sparqlx:run(query:getMeasures($latestEnvelopeByYearK))//sparql:binding[@name='inspireLabel']/sparql:literal))
        
let $ms2K0 := prof:current-ms()        

(: K01 Number of Measures reported :)
let $ms1K01 := prof:current-ms()
let $countMeasures := count($docRoot//aqd:AQD_Measures)
let $K01 := try {
    for $rec in $docRoot//aqd:AQD_Measures
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
let $ms2K01 := prof:current-ms()

(: K02 Compile & feedback upon the total number of new Measures records included in the delivery.
ERROR will be returned if XML is a new delivery and localId are not new compared to previous deliveries. :)

let $ms1K02 := prof:current-ms()
let $K02table := try {
    let $knownMeasuresK02 := distinct-values(data(sparqlx:run(query:getMeasures($latestEnvelopeByYearK))/sparql:binding[@name = 'localId']/sparql:literal))
    for $el in $docRoot//aqd:AQD_Measures
        let $x := $el/aqd:inspireId/base:Identifier
        let $inspireId := data($x/base:localId) (:concat(data($x/base:namespace), "/", :)
        let $ok := $inspireId = $knownMeasuresK02
        return
            common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($el/@gml:id)),
                ("aqd:inspireId", $inspireId),               
                ("Sparql", <td title="Sparql">{sparqlx:getLink(query:getMeasures($latestEnvelopeByYearK))}</td>),
                (: ("SparqlQuery", sparqlx:getLink(query:existsViaNameLocalIdQuery(data($el/@gml:id), 'AQD_Measures', $latestEnvelopesK))) :)
                ("SparqlQuery", sparqlx:getLink(query:existsViaNameLocalIdQuery($inspireId, 'AQD_Measures', $latestEnvelopesK)))
            ]
            )
} catch * {
    html:createErrorRow($err:code, $err:description)
}
let $K02errorLevel :=
    if (
        $isNewDelivery
        and
        count(
            for $x in $docRoot//aqd:AQD_Measures/aqd:inspireId/base:Identifier
                let $id := $x/base:namespace || "/" || $x/base:localId
                (:where ($allMeasures = $id):)
                where query:existsViaNameLocalId($id, 'AQD_Measures', $latestEnvelopesK)
                return 1
        ) > 0
        )
    then
        $errors:K02
    else
        $errors:INFO
        
let $ms2K02 := prof:current-ms()

(: K03 Compile & feedback upon the total number of updated Measures included in the delivery.
ERROR will be returned if XML is an update and ALL localId (100%)
are different to previous delivery (for the same YEAR). :)

let $ms1K03 := prof:current-ms()


let $K03table :=
    try {
        let $knownMeasuresK03 := distinct-values(data(sparqlx:run(query:getMeasures($latestEnvelopeK))/sparql:binding[@name = 'localId']/sparql:literal))
        for $main in $docRoot//aqd:AQD_Measures
        let $x := $main/aqd:inspireId/base:Identifier       
        let $localId :=  data($x/base:localId) 
        for $y in $knownMeasuresK03
        where ($y = $localId)
        return
           <tr>
                <td title="gml:id">{data($main/@gml:id)}</td>               
                <td title="base:localId">{$localId}</td>
               <td title="base:namespace">{data($x/base:namespace)}</td>
               <td title="aqd:code">{data($main/aqd:code)}</td>
               <td title="aqd:name">{data($main/aqd:name)}</td>
               <td title="Sparql">{sparqlx:getLink(query:getMeasures($latestEnvelopeK))}</td>
               <!--  <td title="latestEnvelopeK">{data($latestEnvelopeK)}</td>
                 <td title="isNewDelivery">{data($isNewDelivery)}</td>  
                <td title="knownMeasures y">{$y}</td>-->
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $K03errorLevel :=
    if (not($isNewDelivery) and count($K03table) = 0) then

        $errors:K03
       
    else
     $errors:INFO
      





let $ms2K03 := prof:current-ms()

(: K04 Compile & feedback a list of the unique identifier information for all Measures records included in the delivery.
Feedback report shall include the gml:id attribute,
./aqd:inspireId,
aqd:AQD_SourceApportionment (via ./exceedanceAffected),
aqd:AQD_Scenario (via aqd:usedForScenario) :)

let $ms1K04 := prof:current-ms()
let $K04table := try {
    let $gmlIds := $docRoot//aqd:AQD_Measures/lower-case(normalize-space(@gml:id))
    let $inspireIds := $docRoot//aqd:AQD_Measures/lower-case(normalize-space(aqd:inspireId))
    for $x in $docRoot//aqd:AQD_Measures
        let $id := $x/@gml:id
        let $inspireId := $x/aqd:inspireId
        let $aqdinspireId := concat($x/aqd:inspireId/base:Identifier/base:namespace, "/" , $x/aqd:inspireId/base:Identifier/base:localId)
        let $ok := (count(index-of($gmlIds, lower-case(normalize-space($id)))) = 1
            and
            count(index-of($inspireIds, lower-case(normalize-space($inspireId)))) = 1
        )
        return common:conditionalReportRow(
            not($ok),
            [
                ("gml:id", data($x/@gml:id)),
                ("aqd:inspireId", distinct-values($aqdinspireId)),
                ("Number of Source Apportionment", count(common:checkLink(distinct-values(data($x/aqd:exceedanceAffected/@xlink:href))))),
                ("Number of Scenarios", count(common:checkLink(distinct-values(data($x/aqd:usedForScenario/@xlink:href)))))
            ]
        )
} catch * {
    html:createErrorRow($err:code, $err:description)
}
let $ms2K04 := prof:current-ms()

(: K05
RESERVE
:)
let $ms1K05 := prof:current-ms()
let $K05 := ()
let $ms2K05 := prof:current-ms()

(: K06
RESERVE
:)
let $ms1K06 := prof:current-ms()
let $K06 := ()
let $ms2K06 := prof:current-ms()

(: K07
All gml:id attributes, ef:inspireId and aqd:inspireId elements shall have unique content

All gml ID attributes shall have unique code

    count(index-of($gmlIds, lower-case(normalize-space($id)))) = 1
    or count(index-of($inspireIds, lower-case(normalize-space($inspireId)))) = 1
    or (
        count(index-of($efInspireIds, lower-case(normalize-space($efInspireId)))) = 1
        and not(empty($efInspireId))
    )

:)

let $ms1K07 := prof:current-ms()
let $K07 := try {
    let $main := $docRoot//aqd:AQD_Measures

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
let $ms2K07 := prof:current-ms()

(: K08 ./aqd:inspireId/base:Identifier/base:localId must be unique code for the Measure records :)

let $ms1K08 := prof:current-ms()
let $K08invalid:= try {
    let $localIds := $docRoot//aqd:AQD_Measures/aqd:inspireId/base:Identifier/lower-case(normalize-space(base:localId))
    for $x in $docRoot//aqd:AQD_Measures
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
                ("base:localId", data($x/aqd:inspireId/base:Identifier/base:localId)),
                ("base:namespace", data($x/aqd:inspireId/base:Identifier/base:namespace)),
                ("aqd:AQD_Measures", common:checkLink(distinct-values(data($x/aqd:exceedanceAffected/@xlink:href)))),
                ("aqd:AQD_Scenario", distinct-values(data($x/aqd:usedForScenario/@xlink:href)))
            ]
        )
} catch * {
    html:createErrorRow($err:code, $err:description)
}
let $ms2K08 := prof:current-ms()

(: K09 ./aqd:inspireId/base:Identifier/base:namespace List base:namespace
and count the number of base:localId assigned to each base:namespace.  :)

let $ms1K09 := prof:current-ms()
let $K09table := try {
    for $namespace in distinct-values($docRoot//aqd:AQD_Measures/aqd:inspireId/base:Identifier/base:namespace)
        let $localIds := $docRoot//aqd:AQD_Measures/aqd:inspireId/base:Identifier[base:namespace = $namespace]/base:localId
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
let $ms2K09 := prof:current-ms()

(: K10 Check that namespace is registered in vocabulary
(http://dd.eionet.europa.eu/vocabulary/aq/namespace/view) :)

let $ms1K10 := prof:current-ms()
let $K10invalid := try {
    let $vocDoc := doc($vocabulary:NAMESPACE || "rdf")
    let $prefLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE
            and @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)]/skos:prefLabel[1]
    let $altLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE
            and @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)]/skos:altLabel[1]
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
let $ms2K10 := prof:current-ms()

(: K11
aqd:AQD_Measures/aqd:exceedanceAffected MUST reference
an existing Source Apportionment (I) document via namespace/localId

You must provide a link to a source apportionment document from data flow I via its namespace & localId.
:)
let $ms1K11 := prof:current-ms()
let $K11 := try{
    let $main := $docRoot//aqd:AQD_Measures/aqd:exceedanceAffected
    for $el in $main
        let $label := data($el/@xlink:href)
        (: let $ok := query:existsViaNameLocalId($label, 'AQD_SourceApportionment', $latestEnvelopesI) :)
        let $ok := if(fn:empty($label))
                    then
                      false()
                    else
                      for $l in $label
                        return
                          query:existsViaNameLocalIdYear($l, 'AQD_SourceApportionment', $reportingYear, $latestEnvelopesI)                      
                                
        let $sparql_query := if(fn:empty($label))
                             then
                              "No label to execute this query"
                             else
                              sparqlx:getLink(query:existsViaNameLocalIdYearQuery($label, 'AQD_SourceApportionment', $reportingYear, $latestEnvelopesI)) 

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                (node-name($el), $el/@xlink:href),
                (: ("Sparql", sparqlx:getLink(query:existsViaNameLocalIdQuery($label, 'AQD_SourceApportionment', $latestEnvelopesI))) :)
                ("Sparql", $sparql_query)
            ]
        )
} catch * {
    html:createErrorRow($err:code, $err:description)
}
let $ms2K11 := prof:current-ms()


(: K12
aqd:AQD_Measures/aqd:usedForScenario shall reference an existing Scenario
delivered within a data flow J  via namespace/localId.

A link may be provided to Evaluation Scenario (J). This must be valid via namespace & localId
:)

let $ms1K12 := prof:current-ms()

let $K12 := try {
    let $main := $docRoot//aqd:AQD_Measures/aqd:usedForScenario
    for $el in $main
        let $label := data($el/@xlink:href)
        let $ok := query:existsViaNameLocalId($label, 'AQD_EvaluationScenario', $latestEnvelopesJ)

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                (node-name($el), $el/@xlink:href),
                ("Sparql", sparqlx:getLink(query:existsViaNameLocalIdQuery($label, 'AQD_EvaluationScenario', $latestEnvelopesJ)))
            ]
        )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2K12:= prof:current-ms()

(: K13 ## goititer: skipped; issue #1234534 ##
aqd:AQD_Measures/aqd:code should be a unique local identifier for each measure record.
For convenience the same code as localId may be used

So, the aqd:code should be unique within XML


let $ms1K13 := prof:current-ms()

let $K13invalid := try {
    let $codes := $docRoot//aqd:AQD_Measures/aqd:code
    for $node in $docRoot//aqd:AQD_Measures
        let $code := $node/aqd:code
        let $localId := $node/aqd:inspireId/base:Identifier/base:localId
        let $ok := (
            $code = $localId
            and
            count(fn:index-of($codes,$code)) = 1
        )
        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", data($node/@gml:id)),
                (node-name($code), data($code)),
                (node-name($localId), data($localId))
            ]
        )
}  catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2K13 := prof:current-ms():)

(: K14 aqd:AQD_Measures/aqd:name must be populated with a text string
A short name for the measure :)
let $ms1K14 := prof:current-ms()
let $K14invalid := common:needsValidString(
        $docRoot//aqd:AQD_Measures, 'aqd:name',
        $ancestor-name
        )
let $ms2K14 := prof:current-ms()

(: K15 aqd:AQD_Measures/aqd:name must be populated with a text string
A short name for the measure :)

let $ms1K15 := prof:current-ms()
let $K15invalid := common:needsValidString(
        $docRoot//aqd:AQD_Measures,
        'aqd:description',
        $ancestor-name
        )
let $ms2K15 := prof:current-ms()

(: K16 aqd:AQD_Measures/aqd:classification shall resolve to the codelist http://dd.eionet.europa.eu/vocabulary/aq/measureclassification/
Measure classification should conform to vocabulary :)
let $ms1K16 := prof:current-ms()
let $K16 := common:isInVocabularyReport(
        $docRoot//aqd:AQD_Measures/aqd:classification,
        $vocabulary:MEASURECLASSIFICATION_VOCABULARY,
        $ancestor-name
        )
let $ms2K16 := prof:current-ms()

(: K17 aqd:AQD_Measures/aqd:measureType shall resolve to the codelist http://dd.eionet.europa.eu/vocabulary/aq/measuretype/
Measure type should conform to vocabulary :)
let $ms1K17 := prof:current-ms()
let $K17 := common:isInVocabularyReport(
        $docRoot//aqd:AQD_Measures/aqd:measureType,
        $vocabulary:MEASURETYPE_VOCABULARY,
        $ancestor-name
        )
let $ms2K17 := prof:current-ms()

(: K18 aqd:AQD_Measures/aqd:administrativeLevel shall resolve to the codelist
http://dd.eionet.europa.eu/vocabulary/aq/administrativelevel/
Administrative level should conform to vocabulary
:)
let $ms1K18 := prof:current-ms()
let $K18 := common:isInVocabularyReport(
        $docRoot//aqd:AQD_Measures/aqd:administrativeLevel,
        $vocabulary:ADMINISTRATIVE_LEVEL_VOCABULARY,
        $ancestor-name
        )
let $ms2K18 := prof:current-ms()

(: K19
aqd:AQD_Measures/aqd:timeScale shall resolve to the codelist http://dd.eionet.europa.eu/vocabulary/aq/timescale/
The measure's timescale should conform to vocabulary
:)
let $ms1K19 := prof:current-ms()
let $K19 := common:isInVocabularyReport(
        $docRoot//aqd:AQD_Measures/aqd:timeScale,
        $vocabulary:TIMESCALE_VOCABULARY,
        $ancestor-name
        )
let $ms2K19 := prof:current-ms()

(: K20 aqd:AQD_Measures/aqd:costs/ should be provided
Information on the cost of the measure should be provided
:)
let $ms1K20 := prof:current-ms()
let $K20 := common:isNodeNotInParentReport(
        $docRoot//aqd:AQD_Measures,
        'aqd:costs',
        $ancestor-name
        )

let $ms2K20 := prof:current-ms()

(: K21
If aqd:costs provided
aqd:AQD_Measures/aqd:costs/aqd:Costs/aqd:estimatedImplementationCosts should be
an integer number. If voided /aqd:AQD_Measures/aqd:costs/aqd:Costs/aqd:comment
must be populated with an explanation of why no costs are available.

The estimated total costs should be provided. If not, an explanation on the
reasons for not providing it should be included.
:)

let $ms1K21 := prof:current-ms()
(:let $K21 := try {
    let $root := $docRoot//aqd:AQD_Measures
    for $el in $root
        let $costs := $el/aqd:costs
        let $implCosts := $costs/aqd:Costs/aqd:estimatedImplementationCosts
        let $comment := $costs/aqd:Costs/aqd:comment
        let $costsRoot := $costs/aqd:Costs

        let $isValidCost := common:is-a-number(data($implCosts))
        let $hasCost := common:isNodeInParent($costsRoot, 'aqd:estimatedImplementationCosts')

        return
            if (common:isNodeInParent($el, 'aqd:costs'))
            then (
                if (not($isValidCost))
                then
                    if (empty($comment/text()))
                    then
                        if ($hasCost)
                        then
                            (
                             <tr>
                                <td title="gml:id">{data($el/@gml:id)}</td>
                                <td title="aqd:estimatedImplementationCosts"> aqd:estimatedImplementationCosts not provided</td>
                             </tr>
                            )
                        else
                            (
                            <tr>
                                <td title="gml:id">{data($el/@gml:id)}</td>
                                <td title="aqd:comment"> aqd:comment not provided</td>
                            </tr>)
                    else
                        ()  (: ok, we have a comment :)
                else
                    ()      (: ok, cost is a number :)
            )
            else
                <tr>
                    <td title="gml:id">{data($el/@gml:id)}</td>
                    <td title="aqd:costs"> aqd:costs not provided</td>
                    <td title="$costs"> $costs</td>
                </tr>

} catch * {
    html:createErrorRow($err:code, $err:description)
}:)
let $K21 := try { (:@goititer 30/12/2020 Ref. #124536:)

    let $root := $docRoot//aqd:AQD_Measures
    for $el in $root
        let $costs := $el/aqd:costs
        let $implCosts := $costs/aqd:Costs/aqd:estimatedImplementationCosts
        let $comment := $costs/aqd:Costs/aqd:comment
        let $costsRoot := $costs/aqd:Costs

        let $isValidCost := common:is-a-number2(data($implCosts))

        let $hasCost := common:isNodeInParent($costsRoot, 'aqd:estimatedImplementationCosts')

 let $ancestorCosts:=

    if (not(common:isNodeInParent($el,  'aqd:costs'))) then
     data($el/ancestor-or-self::*[name() = 'aqd:AQD_Measures']/@gml:id)
    else  ()


        return
             if (empty($comment/text()) and (string($ancestorCosts)!=string(data($el/@gml:id))))  then
                if (empty($implCosts)) then 
                        <tr>
                            <td title="gml:id">{data($el/@gml:id)}</td>
                            <td title="aqd:estimatedImplementationCosts">aqd:estimatedImplementationCosts not provided</td>
                            <td title="aqd:comment"> aqd:comment not provided</td>
                            
                            
                        </tr>
                else (:there´cost:)
                            
                if  (not($isValidCost))                   
                    then
                         <tr>
                            <td title="gml:id">{data($el/@gml:id)}</td>
                            <td title="aqd:estimatedImplementationCosts">no valid number</td>
                            <td title="aqd:comment"> aqd:comment not provided</td>
                            
                        </tr>  
                 else()(:cost is a valid number:)  
            else () (:ok, there´s a comment:)


} catch * {
    html:createErrorRow($err:code, $err:description)
}
let $ms2K21 := prof:current-ms()

(: K22
If populated,
/aqd:AQD_Measures/aqd:costs/aqd:Costs/aqd:finalImplementationCosts should be an
integer number
If the final total costs of the measure is provided, this nneeds to be a number

:)

let $ms1K22 := prof:current-ms()
(: commented because of the issue #124537
let $K22 := common:validatePossibleNodeValueReport(
    $docRoot//aqd:AQD_Measures/aqd:costs/aqd:Costs,
    'aqd:finalImplementationCosts',
    common:is-a-number#1,
    $ancestor-name
):)
let $K22 := 
    try {
        (for $x in $docRoot//aqd:AQD_Measures/aqd:costs/aqd:Costs/aqd:finalImplementationCosts
        let $elementExists := exists(data($x))
        (:checking if it is a number:)
        let $number := if($elementExists) then string(number($x))
                       else -1
        let $matches := if($elementExists) then matches($number, "^\d+(\.\d{0,9}?){0,1}$")
                        else false()
        let $positive := number($x) >= 0
        let $isNum := (
            (data($x) castable as xs:integer)
            or
            (data($x) castable as xs:float)
        )

        where ( ($elementExists = true() and $matches = false() and not($isNum)) or ($elementExists = true() and not($positive) and not($isNum)) )
        return
            <tr>
                <td title="gml:id">{data($x/../../../@gml:id)}</td>
                <td title="aqd:finalImplementationCosts">{data($x)}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $ms2K22 := prof:current-ms()

(: K23
If aqd:AQD_Measures/aqd:costs/aqd:Costs/aqd:estimatedImplementationCosts is
populated aqd:AQD_Measures/aqd:costs/aqd:Costs/aqd:currency must be populated
and shall resolve to the codelist
http://dd.eionet.europa.eu/vocabulary/common/currencies/

If estimated costs are provided, the currency must be provided conforming to
vocabulary

:)

let $ms1K23 := prof:current-ms()
let $K23 := try {
    let $main := $docRoot//aqd:AQD_Measures/aqd:costs/aqd:Costs
    for $node in $main
        let $ok := (
                    if(lower-case($node/aqd:currency/@xsi:nil) = "true" and (lower-case($node/aqd:currency/@nilReason) = "unpopulated"))then
                        true()
                    else 
                     common:isInVocabulary(
                        $node/aqd:currency/@xlink:href,
                        $vocabulary:CURRENCIES
                    )
                )

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", $node/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                ("aqd:quantity", data($node/aqd:currency/@xlink:href)),
                ("xsi:nil", common:isInVocabulary(
                        $node/aqd:currency/@xlink:href,
                        $vocabulary:CURRENCIES
                    ))
            ]
        )
} catch * {
    html:createErrorRow($err:code, $err:description)
}
let $ms2K23 := prof:current-ms()


(: K24
aqd:AQD_Measures/aqd:sourceSectors shall resolve to the codelist
http://dd.eionet.europa.eu/vocabulary/aq/sourcesectors/

Source sector should conform to vocabulary
:)

let $ms1K24 := prof:current-ms()
let $K24 := common:isInVocabularyReport(
    $docRoot//aqd:AQD_Measures/aqd:sourceSectors,
    $vocabulary:SOURCESECTORS_VOCABULARY,
    $ancestor-name
    )
let $ms2K24 := prof:current-ms()

(: K25
aqd:AQD_Measures/aqd:spatialScale shall resolve to the codelist
http://dd.eionet.europa.eu/vocabulary/aq/spatialscale/

Spatial scale should conform to vocabulary
:)

let $ms1K25 := prof:current-ms()
let $K25 := common:isInVocabularyReport(
    $docRoot//aqd:AQD_Measures/aqd:spatialScale,
    $vocabulary:SPACIALSCALE_VOCABULARY,
    $ancestor-name
    )
let $ms2K25 := prof:current-ms()

(: K26
aqd:AQD_Measures/aqd:plannedImplementation/aqd:PlannedImplementation/aqd:status shall resolve to the codelist
http://dd.eionet.europa.eu/vocabulary/aq/measureimplementationstatus/

Measure Implementation Status should conform to vocabulary
:)

let $ms1K26 := prof:current-ms()
let $K26 := try {
    let $main := $docRoot//aqd:AQD_Measures/aqd:plannedImplementation/aqd:PlannedImplementation/aqd:status
    for $el in $main
        let $uri := $el/@xlink:href
        return
        if (not(common:isInVocabulary($uri, $vocabulary:MEASUREIMPLEMENTATIONSTATUS_VOCABULARY)))
        then
            <tr>
                <td title="gml:id">{data($el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id)}</td>
                <td title="{node-name($el)}"> not conform to vocabulary</td>
            </tr>
        else
            ()
} catch * {
    html:createErrorRow($err:code, $err:description)
}
let $ms2K26 := prof:current-ms()

(: K27
aqd:AQD_Measures/aqd:plannedImplementation/aqd:PlannedImplementation/aqd:implementationPlannedTimePeriod/gml:TimePeriod/gml:beginPosition
must be a date in full ISO date format

The planned start date for the measure should be provided
:)
let $ms1K27 := prof:current-ms()
let $K27 := common:isDateFullISOReport(
    $docRoot//aqd:AQD_Measures/aqd:plannedImplementation/aqd:PlannedImplementation/aqd:implementationPlannedTimePeriod/gml:TimePeriod/gml:beginPosition,
    $ancestor-name
)
let $ms2K27 := prof:current-ms()

(: K28
If not voided, aqd:AQD_Measures/aqd:plannedImplementation/aqd:PlannedImplementation/aqd:implementationPlannedTimePeriod/gml:TimePeriod/gml:endPosition
must be a date in full ISO format
and must be after aqd:AQD_Measures/aqd:plannedImplementation/aqd:PlannedImplementation/aqd:implementationPlannedTimePeriod/gml:TimePeriod/gml:beginPosition.
If voided it should be indeterminatePosition="unknown"

The planned end date for the measure should be provided in the right format,
if unknown voided using indeterminatePosition="unknown"
:)
let $ms1K28 := prof:current-ms()

let $K28 := try {
    for $el in $docRoot//aqd:AQD_Measures/aqd:plannedImplementation/aqd:PlannedImplementation/aqd:implementationPlannedTimePeriod/gml:TimePeriod
        let $begin := $el/gml:beginPosition
        let $end := $el/gml:endPosition

        let $ok := (
            (common:isDateFullISO($begin) and common:isDateFullISO($end) and $end > $begin)
            or
            (lower-case($end/@indeterminatePosition) = "unknown" and functx:if-empty(data($end),"") eq "")
        )

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                ("gml:beginPosition", data($begin)),
                ("gml:endPosition", data($end))
            ]
        )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2K28 := prof:current-ms()

(: K29
aqd:AQD_Measures/aqd:plannedImplementation/aqd:PlannedImplementation/aqd:implementationActualTimePeriod/gml:TimePeriod/gml:beginPosition
must be a date in full ISO date format

The planned start date for the measure should be provided
:)
let $ms1K29 := prof:current-ms()
let $K29 := common:isDateFullISOReport(
    $docRoot//aqd:AQD_Measures/aqd:plannedImplementation/aqd:PlannedImplementation/aqd:implementationActualTimePeriod/gml:TimePeriod/gml:beginPosition,
    $ancestor-name
)
let $ms2K29 := prof:current-ms()

(:
let $K29 := c:errorReport(
    (isDate() and isDate() and isBigger()) or ()
{
}
)
:)

(: K30
If not voided, aqd:AQD_Measures/aqd:plannedImplementation/aqd:PlannedImplementation/aqd:implementationActualTimePeriod/gml:TimePeriod/gml:endPosition
must be a date in full ISO format and must be after
aqd:AQD_Measures/aqd:plannedImplementation/aqd:PlannedImplementation/aqd:implementationActualTimePeriod/gml:TimePeriod/gml:beginPosition.

If voided it should be indeterminatePosition="unknown"
The planned end date for the measure should be provided in the right format,
if unknown, voided using indeterminatePosition="unknown"
:)

let $ms1K30 := prof:current-ms()

let $K30 := try {
    for $el in $docRoot//aqd:AQD_Measures/aqd:plannedImplementation/aqd:PlannedImplementation/aqd:implementationActualTimePeriod/gml:TimePeriod
        let $begin := $el/gml:beginPosition
        let $end := $el/gml:endPosition

        let $ok := (
            (common:isDateFullISO($begin) and common:isDateFullISO($end) and $end > $begin)
            or
            (lower-case($end/@indeterminatePosition) = "unknown" and functx:if-empty(data($end),"") eq "")
        )

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                ("gml:beginPosition", data($begin)),
                ("gml:endPosition", data($end))
            ]
        )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2K30 := prof:current-ms()

(: K31
aqd:AQD_Measures/aqd:plannedImplementation/aqd:PlannedImplementation/aqd:plannedFullEffectDate/gml:TimeInstant/gml:timePosition
to be provided in the following format yyyy or yyyy-mm-dd

The full effect date of the measure must be provided and the format to be yyyy or yyyy-mm-dd
:)

let $ms1K31 := prof:current-ms()

let $K31 := try {
    for $node in $docRoot//aqd:AQD_Measures/aqd:plannedImplementation/aqd:PlannedImplementation/aqd:plannedFullEffectDate/gml:TimeInstant/gml:timePosition

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

let $ms2K31 := prof:current-ms()

(: K32
/aqd:AQD_Measures/aqd:plannedImplementation/aqd:PlannedImplementation/aqd:otherDates
RESERVE
:)

let $ms1K32 := prof:current-ms()
let $K32 := <tr><td title="aqd:otherDates">{data($docRoot//aqd:AQD_Measures/aqd:plannedImplementation/aqd:PlannedImplementation/aqd:otherDates)}</td></tr>
let $ms2K32 := prof:current-ms()

(: K33
A text string may be provided under
aqd:AQD_Measures/aqd:plannedImplementation/aqd:PlannedImplementation/aqd:monitoringProgressIndicators
If voided an explanation of why this information unavailable shall be provided in
/aqd:AQD_Measures/aqd:plannedImplementation/aqd:PlannedImplementation/aqd:comment
:)

let $ms1K33 := prof:current-ms()

let $K33 := try {
    for $el in $docRoot//aqd:AQD_Measures/aqd:plannedImplementation/aqd:PlannedImplementation
        let $main := $el/aqd:monitoringProgressIndicators
        let $comment := $el/aqd:comment

        let $ok := (
                functx:if-empty(data($main),"") != ""
                or
                functx:if-empty(data($comment),"") != ""
        )

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                ("aqd:monitoringProgressIndicators", data($main)),
                ("aqd:comment", data($comment))
            ]
        )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2K33 := prof:current-ms()

(:
K34
Check that the element
aqd:AQD_Measures/aqd:reductionOfEmissions/aqd:QuantityCommented/aqd:quantity is
an integer or floating point numeric >= 0 if attribute xsi:nil="false"
(example:
    <aqd:quantity uom="http://dd.eionet.europa.eu/vocabulary/uom/emission/t.year-1" xsi:nil="false">273</aqd:quantity>
    )
:)

let $ms1K34 := prof:current-ms()

let $K34 := try {
    let $main := $docRoot//aqd:AQD_Measures/aqd:reductionOfEmissions/aqd:QuantityCommented/aqd:quantity
    for $node in $main
        (: TODO: should write a function for this? there's already is-a-number :)
        let $isNum := (
            (data($node) castable as xs:integer)
            or
            (data($node) castable as xs:float)
        )

        let $ok := (
            ($node/@xsi:nil != 'false')
            or
            ($isNum and ($node cast as xs:float >= 0))
        )

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", $node/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                ("aqd:quantity", data($node)),
                ("xsi:nil", $node/@xsi:nil)
            ]
        )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2K34 := prof:current-ms()

(: K35
Check that the element aqd:QuantityCommented/aqd:quantity is empty if attribute xsi:nil="unpopulated" or "unknown" or "withheld"
(example: <aqd:quantity uom="Unknown" nilReason="Unpopulated" xsi:nil="true"/>)

If quantification is either "unpopulated" or "unknown" or "withheld", the element should be empty
:)

let $ms1K35 := prof:current-ms()

let $K35 := try {
    let $main := $docRoot//aqd:AQD_Measures/aqd:reductionOfEmissions/aqd:QuantityCommented/aqd:quantity
    for $node in $main
        let $ok := (
            (functx:if-empty($node/text(), "") != "")
            or
            (
                lower-case($node/@xsi:nil) = "true"
                and
                (
                    (lower-case($node/@nilReason) = "unknown")
                    or
                    (lower-case($node/@nilReason) = "unpopulated")
                    or
                    (lower-case($node/@nilReason) = "withheld")
                )
            )
        )

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", $node/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                ("aqd:quantity", data($node)),
                ("xsi:nil", data($node/@xsi:nil)),
                ("nilReason", data($node/@nilReason))
            ]
        )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2K35 := prof:current-ms()

(: K36
If aqd:QuantityCommented/aqd:quantity attribute xsi:nil="true"
aqd:QuantityCommented/aqd:comment must be populated

If the quantification is voided an explanation is required in aqd:comment
:)

let $ms1K36 := prof:current-ms()

let $K36 := try {
    for $main in $docRoot//aqd:AQD_Measures/aqd:reductionOfEmissions/aqd:QuantityCommented
        let $quantity := $main/aqd:quantity
        let $comment := $main/aqd:comment

        (:let $ok := (
                lower-case(functx:if-empty(data($quantity/@xsi:nil), "")) = "false"
            or
            (
                lower-case(functx:if-empty(data($quantity/@xsi:nil), "")) = "true"
                and
                functx:if-empty(data($comment), "") != ""
            )
            or 
            (
             lower-case(functx:if-empty(data($quantity/@xsi:nil), "")) = ""                             
             and             
             functx:if-empty(data($quantity), "") != ""
             and
             functx:if-empty(data($comment), "") != ""
            )
        ):)

        let $ok := (     (:changed by @goititer #117080:)    
            $quantity/@xsi:nil!="true" 
             or
             not(empty($comment))
            )
        

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", $main/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                ("aqd:quantity", data($quantity)),
                ("aqd:comment", data($comment))
               
              
            ]
        )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2K36 := prof:current-ms()

(: K37
The unit attribute (aqd:AQD_Measures/aqd:reductionOfEmissions/aqd:QuantityCommented/aqd:quantity/@UoM)
shall correspond to http://dd.eionet.europa.eu/vocabulary/uom/emission

the quantification of reductionOfEmissions should conform to vocabulary
:)

let $ms1K37 := prof:current-ms()

let $K37 := try {
    let $main := $docRoot//aqd:AQD_Measures/aqd:reductionOfEmissions/aqd:QuantityCommented/aqd:quantity
    for $el in $main
        let $uri := data($el/@uom)
        let $uriFromVoc := dd:getValidConcepts($vocabulary:UOM_EMISSION_VOCABULARY || "rdf")
        let $validUris := 
                            if($uri= 'Unknown') then 
                                'http://dd.eionet.europa.eu/vocabulary/uom/emission/Unknown'
                            else 
                                $uriFromVoc

        let $ok := ($uri and $validUris = $uriFromVoc)(:) or ($uri="Unknown" and $el/@xsi:nil="true"):)

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                ("aqd:quantity", data($el)),
                ("uom", data($uri)),
                ("test0", $validUris)
            ]
        )

} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2K37 := prof:current-ms()

(: K38
Check that the element aqd:AQD_Measures/aqd:expectedImpact/aqd:ExpectedImpact/aqd:levelOfConcentration
is an integer or floating point numeric >= 0
and the unit (@uom) shall resolve to the codelist
http://dd.eionet.europa.eu/vocabulary/uom/concentration/

The level of concentration expected should be provided as an integer and its unit should conform to vocabulary
:)

let $ms1K38 := prof:current-ms()

let $K38 := try {
    let $main := $docRoot//aqd:AQD_Measures/aqd:expectedImpact/aqd:ExpectedImpact/aqd:levelOfConcentration
    for $el in $main
        let $uri := data($el/@uom)
        let $validVocabulary := common:isInVocabulary($uri, $vocabulary:UOM_CONCENTRATION_VOCABULARY)

        let $isNum := (
            (data($el) castable as xs:integer)
            or
            (data($el) castable as xs:float)
        )

        let $ok := (
            $validVocabulary
            and
            ($isNum and ($el cast as xs:float >= 0))
        )

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                ("aqd:levelOfConcentration", data($el)),
                ("uom", data($uri))
            ]
        )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2K38 := prof:current-ms()

(: K39
Check that the element aqd:AQD_Measures/aqd:expectedImpact/aqd:ExpectedImpact/aqd:numberOfExceedances
is an integer or floating point numeric >= 0
and the unit (@uom) shall resolve to the codelist
http://dd.eionet.europa.eu/vocabulary/uom/statistics

The number of exceecedance expected should be provided as an integer and its unit should conform to vocabulary
:)

let $ms1K39 := prof:current-ms()

let $K39 := try {
    let $main := $docRoot//aqd:AQD_Measures/aqd:expectedImpact/aqd:ExpectedImpact/aqd:numberOfExceedances
    for $el in $main
        let $uri := data($el/@uom)
        
        let $isNum := (
            ($el castable as xs:integer)
            or
            ($el castable as xs:float)
        )
        
        let $specificationOfHoursLink := $el/../aqd:specificationOfHours/@xlink:href

        let $ok := (
           $isNum and ($el cast as xs:float >= 0) and not(empty($specificationOfHoursLink))
        )

        return common:conditionalReportRow(
            $ok,
            [
                ("gml:id", $el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id),
                ("aqd:numberOfExceedances", data($el)),
                ("uom", data($uri)),
                ("aqd:specificationOfHours",$specificationOfHoursLink)
            ]
        )
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ms2K39 := prof:current-ms()

(: K40
Reserve for specificationOfHours
:)

let $ms1K40 := prof:current-ms()

let $K40 :=
    try {
        (
        for $x in $docRoot//aqd:AQD_Measures/aqd:expectedImpact/aqd:ExpectedImpact
        let $specified := string($x/aqd:specificationOfHours/@xlink:href)
        let $invoca := common:isInVocabulary($specified, $vocabulary:UOM_TIME)
        let $elementExist := exists($x/aqd:specificationOfHours/@xlink:href)
        let $numberOfExceedancesExist := exists($x/aqd:numberOfExceedances)

        where ( ($elementExist = true() and not($invoca and functx:substring-after-last($specified, "/") = "hour" or functx:substring-after-last($specified, "/") = "day")) or ($elementExist = true() and not($invoca and functx:substring-after-last($specified, "/") = "hour" or functx:substring-after-last($specified, "/") = "day") and $numberOfExceedancesExist = false()) )
        return
            <tr>
                <td title="gml:id">{data($x/../../@gml:id)}</td>
                <td title="aqd:specificationOfHours">{$specified}</td>
                <td title="aqd:numberOfExceedances">{data($x/aqd:numberOfExceedances)}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2K40 := prof:current-ms()

let $ms2Total := prof:current-ms()

return
(
    <table class="maintable hover">
    <table>
        {html:build2("NS", $labels:NAMESPACES, $labels:NAMESPACES_SHORT, $NSinvalid, "All values are valid", "record", $errors:NS)}
        {html:build2("VOCAB", $labels:VOCAB, $labels:VOCAB_SHORT, $VOCABinvalid, "All values are valid", "record", $errors:VOCAB)}
        {html:build3("K0", $labels:K0, $labels:K0_SHORT, $K0table, string($K0table/td), errors:getMaxError($K0table))}
        {html:build1("K01", $labels:K01, $labels:K01_SHORT, $K01, "", string($countMeasures), "", "", $errors:K01)}
        {html:buildSimpleSparql("K02", $labels:K02, $labels:K02_SHORT, $K02table, "", "", $K02errorLevel)}
        {html:buildSimpleSparql("K03", $labels:K03, $labels:K03_SHORT, $K03table, "", "", $K03errorLevel)} <!--$K03errorLevel)}-->
        {html:build1("K04", $labels:K04, $labels:K04_SHORT, $K04table, "", string(count($K04table)), " ", "", $errors:K04)}
        {html:build1("K05", $labels:K05, $labels:K05_SHORT, $K05, "RESERVE", "RESERVE", "RESERVE", "RESERVE", $errors:K05)}
        {html:build1("K06", $labels:K06, $labels:K06_SHORT, $K06, "RESERVE", "RESERVE", "RESERVE", "RESERVE", $errors:K06)}
        {html:build2("K07", $labels:K07, $labels:K07_SHORT, $K07, "No duplicate values found", " duplicate value", $errors:K07)}
        {html:build2("K08", $labels:K08, $labels:K08_SHORT, $K08invalid, "No duplicate values found", " duplicate value", $errors:K08)}
        {html:build2("K09", $labels:K09, $labels:K09_SHORT, $K09table, "namespace", "", $errors:K09)} 
        <!-- {html:buildUnique("K09", $labels:K09, $labels:K09_SHORT, $K09table, "namespace", $errors:K09)}-->
        {html:build2("K10", $labels:K10, $labels:K10_SHORT, $K10invalid, "All values are valid", " not conform to vocabulary", $errors:K10)}
        {html:build2Sparql("K11", $labels:K11, $labels:K11_SHORT, $K11, "All values are valid", "needs valid input", $errors:K11)}
        {html:build2Sparql("K12", $labels:K12, $labels:K12_SHORT, $K12, "All values are valid", "needs valid input", $errors:K12)}
        <!--{html:build2("K13", $labels:K13, $labels:K13_SHORT, $K13invalid, "All values are valid", " code not equal", $errors:K13)}-->
        {html:build2("K14", $labels:K14, $labels:K14_SHORT, $K14invalid, "All values are valid", "needs valid input", $errors:K14)}
        {html:build2("K15", $labels:K15, $labels:K15_SHORT, $K15invalid, "All values are valid", "needs valid input", $errors:K15)}
        {html:build2("K16", $labels:K16, $labels:K16_SHORT, $K16, "All values are valid", "not conform to vocabulary",$errors:K16)}
        {html:build2("K17", $labels:K17, $labels:K17_SHORT, $K17, "All values are valid", "not conform to vocabulary",$errors:K17)}
        {html:build2("K18", $labels:K18, $labels:K18_SHORT, $K18, "All values are valid", "not conform to vocabulary",$errors:K18)}
        {html:build2("K19", $labels:K19, $labels:K19_SHORT, $K19, "All values are valid", "not conform to vocabulary", $errors:K19)}
        {html:build2("K20", $labels:K20, $labels:K20_SHORT, $K20, "All values are valid", " needs valid input ", $errors:K20)}
        {html:build2("K21", $labels:K21, $labels:K21_SHORT, $K21, "All values are valid", " needs valid input", $errors:K21)}
        {html:build2("K22", $labels:K22, $labels:K22_SHORT, $K22, "All values are valid", " needs valid input", $errors:K22)}
        {html:build2("K23", $labels:K23, $labels:K23_SHORT, $K23, "All values are valid", " needs valid input", $errors:K23)}
        {html:build2("K24", $labels:K24, $labels:K24_SHORT, $K24, "All values are valid", "not conform to vocabulary", $errors:K24)}
        {html:build2("K25", $labels:K25, $labels:K25_SHORT, $K25, "All values are valid", "not conform to vocabulary", $errors:K25)}
        {html:build2("K26", $labels:K26, $labels:K26_SHORT, $K26, "All values are valid", "not conform to vocabulary", $errors:K26)}
        {html:build2("K27", $labels:K27, $labels:K27_SHORT, $K27, "All values are valid", "not full ISO format", $errors:K27)}
        {html:build2("K28", $labels:K28, $labels:K28_SHORT, $K28, "All values are valid", "not valid", $errors:K28)}
        {html:build2("K29", $labels:K29, $labels:K29_SHORT, $K29, "All values are valid", "not full ISO format", $errors:K29)}
        {html:build2("K30", $labels:K30, $labels:K30_SHORT, $K30, "All values are valid", "not valid", $errors:K30)}
        {html:build2("K31", $labels:K31, $labels:K31_SHORT, $K31, "All values are valid", "not valid", $errors:K31)}
        {html:build1("K32", $labels:K32, $labels:K32_SHORT, $K32, "RESERVE", "RESERVE", "RESERVE", "RESERVE", $errors:K32)}
        {html:build2("K33", $labels:K33, $labels:K33_SHORT, $K33, "All values are valid", "not valid", $errors:K33)}
        {html:build2("K34", $labels:K34, $labels:K34_SHORT, $K34, "All values are valid", "not valid", $errors:K34)}
        {html:build2("K35", $labels:K35, $labels:K35_SHORT, $K35, "All values are valid", "not valid", $errors:K35)}
        {html:build2("K36", $labels:K36, $labels:K36_SHORT, $K36, "All values are valid", "not valid", $errors:K36)}
        {html:build2("K37", $labels:K37, $labels:K37_SHORT, $K37, "All values are valid", "not valid", $errors:K37)}
        {html:build2("K38", $labels:K38, $labels:K38_SHORT, $K38, "All values are valid", "not valid", $errors:K38)}
        {html:build2("K39", $labels:K39, $labels:K39_SHORT, $K39, "All values are valid", "not valid", $errors:K39)}
        {html:build2("K40", $labels:K40, $labels:K40_SHORT, $K40, "All values are valid", "not valid", $errors:K40)}
    </table>
    <table>
         <br/>
        <caption> {$labels:TIMINGTABLEHEADER} </caption>
        <tr>
            <th>Query</th>
            <th>Process time in miliseconds</th>
            <th>Process time in seconds</th>
        </tr>
       {common:runtime("Common Variables", $ms1GeneralParameters, $ms2GeneralParameters)}
       {common:runtime("NS", $ms1NS, $ms2NS)}
       {common:runtime("VOCAB", $ms1VOCAB, $ms2VOCAB)}
       {common:runtime("K0", $ms1K0, $ms2K0)}
       {common:runtime("K01", $ms1K01, $ms2K01)}
       {common:runtime("K02", $ms1K02, $ms2K02)}
       {common:runtime("K03", $ms1K03, $ms2K03)} 
       {common:runtime("K04", $ms1K04, $ms2K04)}
       {common:runtime("K05", $ms1K05, $ms2K05)}
       {common:runtime("K06", $ms1K06, $ms2K06)}
       {common:runtime("K07", $ms1K07, $ms2K07)}
       {common:runtime("K08", $ms1K08, $ms2K08)}
       {common:runtime("K09", $ms1K09, $ms2K09)}
       {common:runtime("K10", $ms1K10, $ms2K10)}
       {common:runtime("K11", $ms1K11, $ms2K11)}
       {common:runtime("K12", $ms1K12, $ms2K12)}
      <!-- {common:runtime("K13", $ms1K13, $ms2K13)}-->
       {common:runtime("K14", $ms1K14, $ms2K14)}
       {common:runtime("K15", $ms1K15, $ms2K15)}
       {common:runtime("K16", $ms1K16, $ms2K16)}
       {common:runtime("K17", $ms1K17, $ms2K17)}
       {common:runtime("K18", $ms1K18, $ms2K18)}
       {common:runtime("K19", $ms1K19, $ms2K19)}
       {common:runtime("K20", $ms1K20, $ms2K20)}
       {common:runtime("K21", $ms1K21, $ms2K21)}
       {common:runtime("K22", $ms1K22, $ms2K22)}
       {common:runtime("K23", $ms1K23, $ms2K23)}
       {common:runtime("K24", $ms1K24, $ms2K24)}
       {common:runtime("K25", $ms1K25, $ms2K25)}
       {common:runtime("K26", $ms1K26, $ms2K26)}
       {common:runtime("K27", $ms1K27, $ms2K27)}
       {common:runtime("K28", $ms1K28, $ms2K28)}
       {common:runtime("K29", $ms1K29, $ms2K29)}
       {common:runtime("K30", $ms1K30, $ms2K30)}
       {common:runtime("K31", $ms1K31, $ms2K31)}
       {common:runtime("K32", $ms1K32, $ms2K32)}
       {common:runtime("K33", $ms1K33, $ms2K33)}
       {common:runtime("K34", $ms1K34, $ms2K34)}
       {common:runtime("K35", $ms1K35, $ms2K35)}
       {common:runtime("K36", $ms1K36, $ms2K36)}
       {common:runtime("K37", $ms1K37, $ms2K37)}
       {common:runtime("K38", $ms1K38, $ms2K38)}
       {common:runtime("K39", $ms1K39, $ms2K39)}
       {common:runtime("K40", $ms1K40, $ms2K40)}
       {common:runtime("Total", $ms1Total, $ms2Total)}
    </table>
    </table>
)

};

declare function dataflowK:proceed($source_url as xs:string, $countryCode as xs:string) as element(div) {

let $countZones := count(doc($source_url)//aqd:AQD_Measures)
let $result := if ($countZones > 0) then dataflowK:checkReport($source_url, $countryCode) else ()
let $meta := map:merge((
    map:entry("count", $countZones),
    map:entry("header", "Check air quality zones"),
    map:entry("dataflow", "Dataflow K"),
    map:entry("zeroCount", <p>No aqd:AQD_Measures elements found in this XML.</p>),
    map:entry("report", <p>This check evaluated the delivery by executing tier-1 tests on air quality zones data in Dataflow K as specified in <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a>.</p>)
))
return
    html:buildResultDiv($meta, $result)
};
