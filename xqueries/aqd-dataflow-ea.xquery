xquery version "3.0";

(:~
: User: George Sofianos
: Date: 6/28/2016
: Time: 6:10 PM
:)

module namespace dataflowEa = "http://converters.eionet.europa.eu/dataflowEa";
import module namespace common = "aqd-common" at "aqd-common.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";
import module namespace errors = "aqd-errors" at "aqd-errors.xquery";
import module namespace labels = "aqd-labels" at "aqd-labels.xquery";
import module namespace dd = "aqd-dd" at "aqd-dd.xquery";
import module namespace vocabulary = "aqd-vocabulary" at "aqd-vocabulary.xquery";
import module namespace query = "aqd-query" at "aqd-query.xquery";
import module namespace sparqlx = "aqd-sparql" at "aqd-sparql.xquery";
import module namespace schemax = "aqd-schema" at "aqd-schema.xquery";
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

declare variable $dataflowEa:OBLIGATIONS as xs:string* := ($vocabulary:ROD_PREFIX || "673");
declare function dataflowEa:checkReport($source_url as xs:string, $countryCode as xs:string) as element(table) {
let $ms1Total := prof:current-ms()

let $ms1GeneralParameters:= prof:current-ms()
let $envelopeUrl := common:getEnvelopeXML($source_url)
let $docRoot := doc($source_url)
let $reportingYear := common:getReportingYear($docRoot)
let $cdrUrl := common:getCdrUrl($countryCode)
let $latestEnvelopeD := query:getLatestEnvelope($cdrUrl || "d/")

let $headerBeginPosition := $docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:beginPosition
let $headerEndPosition := $docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:endPosition

let $pollutants :=   fn:string-join(fn:distinct-values(
                        for $x in $docRoot//om:OM_Observation
                         let $observedProperty := $x/om:observedProperty/@xlink:href
                        return "<" || $observedProperty || ">"
                      ), " , ")

let $ms2GeneralParameters:= prof:current-ms()
(: File prefix/namespace check :)

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
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
   let $ms2NS := prof:current-ms()


let $ms1EVOCAB := prof:current-ms()

let $VOCABinvalid := checks:vocab($docRoot)

let $ms2EVOCAB := prof:current-ms()

(: E0 :)
let $ms1E0 := prof:current-ms()

let $E0table :=
    try {
        if ($reportingYear = "") then
            <tr class="{$errors:ERROR}">
                <td title="Status">Reporting Year is missing.</td>
            </tr>
        else if($headerBeginPosition > $headerEndPosition) then
            <tr class="{$errors:BLOCKER}">
                <td title="Status">Start position must be less than end position</td>
            </tr>
        else if (query:deliveryExists($dataflowEa:OBLIGATIONS, $countryCode, "e1a/", $reportingYear)) then
            <tr class="{$errors:WARNING}">
                <td title="Status">Updating delivery for {$reportingYear}</td>
            </tr>
        else
            <tr class="{$errors:INFO}">
                <td title="Status">New delivery for {$reportingYear}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $isNewDelivery := errors:getMaxError($E0table) = $errors:INFO

let $ms2E0 := prof:current-ms()

(: E01a :)

let $ms1E01a := prof:current-ms()

let $E01atable :=
    try {
        for $x in $docRoot//om:OM_Observation
            let $namedValue := $x/om:parameter/om:NamedValue[om:name/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/processparameter/SamplingPoint"]
            let $samplingPoint := tokenize(common:if-empty($namedValue/om:value, $namedValue/om:value/@xlink:href), "/")[last()]
            let $observedProperty := $x/om:observedProperty/@xlink:href/string()
        return
            <tr>
                <td title="gml:id">{data($x/@gml:id)}</td>
                <td title="aqd:AQD_SamplingPoint">{$samplingPoint}</td>
                <td title="Pollutant">{$observedProperty}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E01a := prof:current-ms()

(: E01b - /om:OM_Observation gml:id attribute shall be unique code for the group of observations enclosed by /OM_Observation within the delivery. :)

let $ms1E01b := prof:current-ms()
let $E01binvalid :=
    try {
        (let $all := data($docRoot//om:OM_Observation/@gml:id)
        for $x in $docRoot//om:OM_Observation/@gml:id
        where count(index-of($all, $x)) > 1
        return
            <tr>
                <td title="om:OM_Observation">{string($x)}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E01b := prof:current-ms()

(:E02 - /om:phenomenonTime/gml:TimePeriod/gml:beginPosition shall be LESS THAN ./om:phenomenonTime/gml:TimePeriod/gml:endPosition. -:)

let $ms1E02 := prof:current-ms()

let $E02invalid :=
    try {
        (let $all := $docRoot//om:phenomenonTime/gml:TimePeriod
        for $x in $all
            let $begin := xs:dateTime($x/gml:beginPosition)
            let $end := xs:dateTime($x/gml:endPosition)
        where ($end <= $begin)
        return
            <tr>
                <td title="@gml:id">{string($x/../../@gml:id)}</td>
                <td title="gml:beginPosition">{string($x/gml:beginPosition)}</td>
                <td title="gml:endPosition">{string($x/gml:endPosition)}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    }
    catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E02 := prof:current-ms()

(:E03 - ./om:resultTime/gml:TimeInstant/gml:timePosition shall be GREATER THAN ./om:phenomenonTime/gml:TimePeriod/gml:endPosition :)

let $ms1E03 := prof:current-ms()

let $E03invalid :=
    try {
        (let $all := $docRoot//om:OM_Observation
        for $x in $all
            let $timePosition := xs:dateTime($x/om:resultTime/gml:TimeInstant/gml:timePosition)
            let $endPosition := xs:dateTime($x/om:phenomenonTime/gml:TimePeriod/gml:endPosition)
        where ($timePosition < $endPosition)
        return
            <tr>
                <td title="@gml:id">{string($x/@gml:id)}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    }
    catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E03 := prof:current-ms()

(: E04 - ./om:procedure xlink:href attribute shall resolve to a traversable link process configuration in Data flow D: /aqd:AQD_SamplingPointProcess/ompr:inspireld/base:Identifier/base:localId:)

let $ms1E04 := prof:current-ms()

let $E04invalid :=
    try {
        ( (:let $result := sparqlx:run(query:getSamplingPointProcess($cdrUrl)):)
        
        let $result := sparqlx:run(query:getSamplingPointMetadataFromFiles($latestEnvelopeD, $pollutants))
        let $sparqlprocedure :=  $result/sparql:binding[@name = "procedure"]/sparql:uri/string()
        let $all:= 
                 for $x in $sparqlprocedure
                   let $procedurecut := fn:substring-after($x, 'http://reference.eionet.europa.eu/aq/')
                 return $procedurecut
        let $procedures := $docRoot//om:procedure/@xlink:href/string()
        for $x in $procedures[not(. = $all)]
        return
            <tr>
                <td title="base:localId">{$x}</td>
                <td title="Sparql">{sparqlx:getLink(query:getSamplingPointMetadataFromFiles($cdrUrl, $pollutants))}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E04 := prof:current-ms()

(: E05 - A valid delivery MUST provide an om:parameter with om:name/@xlink:href to http://dd.eionet.europa.eu/vocabulary/aq/processparameter/SamplingPoint :)

let $ms1E05 := prof:current-ms()

let $E05invalid :=
    try {
        (for $x in $docRoot//om:OM_Observation
        where not($x/om:parameter/om:NamedValue/om:name/@xlink:href = $vocabulary:PROCESS_PARAMETER || "SamplingPoint")
        return
        <tr>
            <td title="@gml:id">{string($x/@gml:id)}</td>
        </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E05 := prof:current-ms()

(: E06 :)

let $ms1E06 := prof:current-ms()

let $E06invalid :=
    try {
        ( (:let $result := sparqlx:run(query:getSamplingPointFromFiles($latestEnvelopeD))
        :)
         let $result := sparqlx:run(query:getSamplingPointMetadataFromFiles($latestEnvelopeD, $pollutants))
       let $all := $result/sparql:binding[@name = "inspireLabel"]/sparql:literal/string()
        for $x in $docRoot//om:OM_Observation/om:parameter/om:NamedValue[om:name/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/processparameter/SamplingPoint"]
            let $name := $x/om:name/@xlink:href/string()
            let $value := common:if-empty($x/om:value, $x/om:value/@xlink:href)
        where ($value = "" or not($value = $all))
        return
            <tr>
                <td title="om:OM_Observation">{string($x/../../@gml:id)}</td>
                <td title="om:value">{$value}</td>
                <td title="Sparql">{sparqlx:getLink(query:getSamplingPointMetadataFromFiles($latestEnvelopeD, $pollutants))}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ms2E06 := prof:current-ms()

(: E07 :)

let $ms1E07 := prof:current-ms()

let $E07invalid :=
    try {
        (for $x in $docRoot//om:OM_Observation
        where not($x/om:parameter/om:NamedValue/om:name/@xlink:href = $vocabulary:PROCESS_PARAMETER || "AssessmentType")
        return
            <tr>
                <td title="@gml:id">{string($x/@gml:id)}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    }
    catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E07 := prof:current-ms()

(: E08 :)

let $ms1E08 := prof:current-ms()

let $E08invalid :=
    try {
        (let $valid := dd:getValidConcepts($vocabulary:ASSESSMENTTYPE_VOCABULARY || "rdf")
        for $x in $docRoot//om:OM_Observation/om:parameter/om:NamedValue[om:name/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/processparameter/AssessmentType"]
        let $value := common:if-empty($x/om:value, $x/om:value/@xlink:href)
        where not($value = $valid)
        return
            <tr>
                <td title="om:OM_Observation">{string($x/../../@gml:id)}</td>
                <td title="om:value">{$value}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    }
    catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E08 := prof:current-ms()

(: E09 :)
(: TODO Check ticket for implementation :)

let $ms1E09 := prof:current-ms()

let $E09invalid :=
    try {
        (let $valid := dd:getValidConcepts($vocabulary:PROCESS_PARAMETER || "rdf")
        for $x in $docRoot//om:OM_Observation/om:parameter/om:NamedValue/om:name
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="@gml:id">{string($x/../../../@gml:id)}</td>
                <td title="om:name">{data($x/@xlink:href)}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E09 := prof:current-ms()

(: E10 - /om:observedProperty xlink:href attribute shall resolve to a traversable link to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/ :)

let $ms1E10 := prof:current-ms()

let $E10invalid :=
    try {
        (let $all := dd:getValidConcepts("http://dd.eionet.europa.eu/vocabulary/aq/pollutant/rdf")
        for $x in $docRoot//om:OM_Observation/om:observedProperty
        let $namedValue := $x/../om:parameter/om:NamedValue[om:name/@xlink:href ="http://dd.eionet.europa.eu/vocabulary/aq/processparameter/SamplingPoint"]
        let $value := common:if-empty($namedValue/om:value, $namedValue/om:value/@xlink:href)
        where not($x/@xlink:href = $all)
        return
            <tr>
                <td title="om:OM_Observation">{string($x/../@gml:id)}</td>
                <td title="om:value">{$value}</td>
                <td title="om:observedProperty">{string($x/@xlink:href)}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E10 := prof:current-ms()

(: E11 - The pollutant xlinked via /om:observedProperty must match the pollutant code declared via /aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability/ef:observedProperty :)

let $ms1E11 := prof:current-ms()

let $E11invalid :=
    try {
        (let $result := sparqlx:run(query:getSamplingPointMetadataFromFiles($latestEnvelopeD))
        let $resultConcat := for $x in $result
        return $x/sparql:binding[@name="featureOfInterest"]/sparql:uri/string() || $x/sparql:binding[@name="observedProperty"]/sparql:uri/string()
        for $x in $docRoot//om:OM_Observation
            let $observedProperty := $x/om:observedProperty/@xlink:href/string()
            let $featureOfInterest := $x/om:featureOfInterest/@xlink:href/string()
            let $featureOfInterest :=
                if (not($featureOfInterest = "") and not(starts-with($featureOfInterest, "http://"))) then
                    "http://reference.eionet.europa.eu/aq/" || $featureOfInterest
                else
                    $featureOfInterest
            let $concat := $featureOfInterest || $observedProperty
            let $namedValue := $x/om:parameter/om:NamedValue[om:name/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/processparameter/SamplingPoint"]
            let $value := common:if-empty($namedValue/om:value, $namedValue/om:value/@xlink:href)
        where not($concat = $resultConcat)
        return
            <tr>
                <td title="@gml:id">{$x/@gml:id/string()}</td>
                <td title="om:value">{$value}</td>
                <td title="om:observedProperty">{$observedProperty}</td>
                <td title="Sparql">{sparqlx:getLink(query:getSamplingPointMetadataFromFiles($latestEnvelopeD)
)}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E11 := prof:current-ms()

(: E12 :) 

let $ms1E12 := prof:current-ms()

let $E12invalid :=
    try {
        (let $samples := data(sparqlx:run(query:getSample($latestEnvelopeD))/sparql:binding[@name = "localId"]/sparql:literal)
        for $x in $docRoot//om:OM_Observation
            let $featureOfInterest := $x/om:featureOfInterest/@xlink:href/tokenize(string(), "/")[last()]
        where ($featureOfInterest = "") or not($featureOfInterest = $samples)
        return
            <tr>
                <td title="@gml:id">{$x/@gml:id/string()}</td>
                <td title="om:featureOfInterest">{$featureOfInterest}</td>
                <td title="om:observedProperty">{string($x/om:observedProperty/@xlink:href)}</td>
                <td title="Sparql">{sparqlx:getLink(query:getSample($latestEnvelopeD))}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E12 := prof:current-ms()

(: E15 :)

let $ms1E15 := prof:current-ms()

let $E15invalid :=
    try {
        (for $x in $docRoot//om:OM_Observation/om:result//swe:elementType/swe:DataRecord/swe:field[@name = "StartTime"
                and not(swe:Time[@definition = "http://www.opengis.net/def/property/OGC/0/SamplingTime"]/swe:uom/@xlink:href = "http://www.opengis.net/def/uom/ISO-8601/0/Gregorian")]
        return
            <tr>
                <td title="@gml:id">{string($x/../../../../../@gml:id)}</td>
                <td title="swe:uom">{string($x/swe:Time[@definition = "http://www.opengis.net/def/property/OGC/0/SamplingTime"]/swe:uom/@xlink:href)}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E15 := prof:current-ms()

(: E16 :)

let $ms1E16 := prof:current-ms()

let $E16invalid :=
    try {
        (for $x in $docRoot//om:OM_Observation/om:result//swe:elementType/swe:DataRecord/swe:field[@name = "EndTime"
                and not(swe:Time[@definition = "http://www.opengis.net/def/property/OGC/0/SamplingTime"]/swe:uom/@xlink:href = "http://www.opengis.net/def/uom/ISO-8601/0/Gregorian")]
        return
            <tr>
                <td title="@gml:id">{string($x/../../../../../@gml:id)}</td>
                <td title="swe:uom">{string($x/swe:Time[@definition = "http://www.opengis.net/def/property/OGC/0/SamplingTime"]/swe:uom/@xlink:href)}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E16 := prof:current-ms()

(: E17 :)

let $ms1E17 := prof:current-ms()

let $E17invalid :=
    try {
        (for $x in $docRoot//om:OM_Observation/om:result//swe:elementType/swe:DataRecord/swe:field[@name="Validity"
                and not(swe:Category/@definition = "http://dd.eionet.europa.eu/vocabulary/aq/observationvalidity")]
        return
            <tr>
                <td title="@gml:id">{string($x/../../../../../@gml:id)}</td>
                <td title="swe:Category">{string($x/swe:Category/@definition)}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E17 := prof:current-ms()

(: E18 :)

let $ms1E18 := prof:current-ms()

let $E18invalid :=
    try {
        (for $x in $docRoot//om:OM_Observation/om:result//swe:elementType/swe:DataRecord/swe:field[@name = "Verification"
                and not(swe:Category/@definition = "http://dd.eionet.europa.eu/vocabulary/aq/observationverification")]
        return
            <tr>
                <td title="@gml:id">{string($x/../../../../../@gml:id)}</td>
                <td title="swe:Category">{string($x/swe:Category/@definition)}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E18 := prof:current-ms()

(: E19 :)

let $ms1E19 := prof:current-ms()

let $E19invalid :=
    try {
        (let $obs := dd:getValidConceptsLC("http://dd.eionet.europa.eu/vocabulary/aq/primaryObservation/rdf")
        let $cons := dd:getValidConceptsLC("http://dd.eionet.europa.eu/vocabulary/uom/concentration/rdf")
        for $x in $docRoot//om:OM_Observation/om:result//swe:elementType/swe:DataRecord/swe:field[@name = "Value"
                and (not(swe:Quantity/lower-case(@definition) = $obs) or not(swe:Quantity/swe:uom/lower-case(@xlink:href) = $cons))]
        return
            <tr>
                <td title="@gml:id">{string($x/../../../../../@gml:id)}</td>
                <td title="swe:Quantity">{string($x/swe:Quantity/@definition)}</td>
                <td title="swe:uom">{string($x/swe:Quantity/swe:uom/@xlink:href)}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E19 := prof:current-ms()

(:E19a:)

let $ms1E19a := prof:current-ms()

let $E19ainvalid :=
    try {
        (for $x in $docRoot//om:OM_Observation
        let $pollutant := string($x/om:observedProperty/@xlink:href)
        let $value := string($x//swe:field[@name = 'Value']/swe:Quantity/@definition)
        where not($value = "http://dd.eionet.europa.eu/vocabulary/aq/primaryObservation/hour" 
                or $value = "http://dd.eionet.europa.eu/vocabulary/aq/primaryObservation/day" 
                or $value = "http://dd.eionet.europa.eu/vocabulary/aq/primaryObservation/var" 
                )
        return
            <tr>
                <td title="om:OM_Observation">{data($x/@gml:id)}</td>
                <td title="Pollutant">{$pollutant}</td>
                <td title="swe:Quantity">{$value}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E19a := prof:current-ms()


(: E19b :)

let $ms1E19b := prof:current-ms()

let $E19binvalid :=
    try {
        (for $x in $docRoot//om:OM_Observation
        let $pollutant := string($x/om:observedProperty/@xlink:href)
        let $value := string($x//swe:field[@name = 'Value']/swe:Quantity/swe:uom/@xlink:href)
        let $recommended := dd:getRecommendedUnit($pollutant)
        where not($value = $recommended)
        return
            <tr>
                <td title="om:OM_Observation">{data($x/@gml:id)}</td>
                <td title="Pollutant">{$pollutant}</td>
                <td title="Recommended Unit">{$recommended}</td>
                <td title="swe:uom">{$value}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E19b := prof:current-ms()




(: E19c :)
let $ms1E19c := prof:current-ms()

let $E19cinvalid :=
    try {
        (for $x in $docRoot//om:OM_Observation
        let $pollutant := string($x/om:observedProperty/@xlink:href)
        let $value := string($x//swe:field[@name = 'Value']/swe:Quantity/swe:uom/@xlink:href)
        let $mandatory := dd:getMandatoryUnit($pollutant)
        where not($value = $mandatory)
        return
            <tr>
                <td title="om:OM_Observation">{data($x/@gml:id)}</td>
                <td title="Pollutant">{$pollutant}</td>
                <td title="Mandatory Unit">{$mandatory}</td>
                <td title="swe:uom">{$value}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E19c := prof:current-ms()

(: E20 :)

let $ms1E20 := prof:current-ms()

let $E20invalid :=
    try {
        (let $all := $docRoot//om:result//swe:elementType/swe:DataRecord/swe:field[@name="DataCapture"]
        for $x in $all
        let $def := $x/swe:Quantity/@definition/string()
        let $uom := $x/swe:Quantity/swe:uom/@xlink:href/string()
        where (not($def = "http://dd.eionet.europa.eu/vocabulary/aq/primaryObservation/dc") or not($uom = "http://dd.eionet.europa.eu/vocabulary/uom/statistics/percentage"))
        return
            <tr>
                <td title="@gml:id">{string($x/../../../../../@gml:id)}</td>
                <td title="@definition">{$def}</td>
                <td title="@uom">{$uom}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    }
    catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E20 := prof:current-ms()

(: E21 - /om:result/swe:DataArray/swe:encoding/swe:TextEncoding shall resolve to decimalSeparator="." tokenSeparator="," blockSeparator="@@" :)

let $ms1E21 := prof:current-ms()

let $E21invalid :=
    try {
        (for $x in $docRoot//om:result//swe:encoding/swe:TextEncoding[not(@decimalSeparator=".") or not(@tokenSeparator=",") or not(@blockSeparator="@@")]
        return
            <tr>
                <td title="@gml:id">{string($x/../../../../@gml:id)}</td>
                <td title="@decimalSeparator">{string($x/@decimalSeparator)}</td>
                <td title="@tokenSeparator">{string($x/@tokenSeparator)}</td>
                <td title="@blockSeparator">{string($x/@blockSeparator)}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    }
    catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E21 := prof:current-ms()



let $ms1E22 := prof:current-ms()

let $E22invalid :=
    try {
        (let $validVerifications := dd:getValidNotations($vocabulary:OBSERVATIONS_VERIFICATION || "rdf")
        let $validValidity:= dd:getValidNotations($vocabulary:OBSERVATIONS_VALIDITY || "rdf")
        let $exceptionDataCapture := ("-99", "-999")

        for $x at $xpos in $docRoot//om:OM_Observation/om:result
        let $blockSeparator := string($x//swe:encoding/swe:TextEncoding/@blockSeparator)
        let $decimalSeparator := string($x//swe:encoding/swe:TextEncoding/@decimalSeparator)
        let $tokenSeparator := string($x//swe:encoding/swe:TextEncoding/@tokenSeparator)
        let $fields := data($x//swe:elementType/swe:DataRecord/swe:field/@name)

        for $i at $ipos in tokenize(replace($x//swe:values, $blockSeparator || "$", ""), $blockSeparator)
        for $z at $zpos in tokenize($i, $tokenSeparator)
        let $invalid :=
            (:if ($fields[$zpos] = ("StartTime", "EndTime")) then if ($z castable as xs:dateTime) then false() else true()
            else if ($fields[$zpos] = "Verification") then if ($z = $validVerifications) then false() else true()
            else if ($fields[$zpos] = "Validity") then if ($z = $validValidity) then false() else true()
            else if ($fields[$zpos] = "Value") then if ($z = "" or $z castable as xs:double) then false() else true()
            else if ($fields[$zpos] = "DataCapture") then if ($z = $exceptionDataCapture or ($z castable as xs:decimal and number($z) >= 0 and number($z) <= 100)) then false() else true()
            else true():)
            switch ($fields[$zpos])
              case '("StartTime", "EndTime")'
                return if ($z castable as xs:dateTime) then false() else true()
              case "Verification"
                return if ($z = $validValidity) then false() else true()
              case "Value"
                return if ($z = "" or $z castable as xs:double) then false() else true()
              case "DataCapture"
                return if ($z = $exceptionDataCapture or ($z castable as xs:decimal and number($z) >= 0 and number($z) <= 100)) then false() else true()
              default 
                return false()
        where $invalid = true() (:where $invalid = false():)
        return
            <tr>
                <td title="OM_Observation">{string($x/../@gml:id)}</td>
                <td title="Data record position">{$ipos}</td>
                <td title="Expected type">{$fields[$zpos]}</td>
                <td title="Actual value">{$z}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E22 := prof:current-ms()


let $ms1E23 := prof:current-ms()

let $E23invalid :=
    try {
        (for $x at $xpos in $docRoot//om:OM_Observation/om:result
        let $blockSeparator := string($x//swe:encoding/swe:TextEncoding/@blockSeparator)
        let $decimalSeparator := string($x//swe:encoding/swe:TextEncoding/@decimalSeparator)
        let $tokenSeparator := string($x//swe:encoding/swe:TextEncoding/@tokenSeparator)

        let $actual := count(tokenize(replace($x//swe:values, $blockSeparator || "$", ""), $blockSeparator))
        let $expected := number($x//swe:elementCount/swe:Count/swe:value)
        where not($actual = $expected) or ($expected = 0)
        return
            <tr>
                <td title="OM_Observation">{string($x/../@gml:id)}</td>
                <td title="Expected count">{$expected}</td>
                <td title="Actual count">{$actual}</td>
            </tr>)[position() = 1 to $errors:HIGHER_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E23 := prof:current-ms()

let $ms1E24 := prof:current-ms()

let $E24invalid :=
    try {
        (for $x at $xpos in $docRoot//om:OM_Observation/om:result[//swe:field[@name = "Value"]/swe:Quantity/contains(@definition, $vocabulary:OBSERVATIONS_PRIMARY) = true()]

        let $blockSeparator := string($x//swe:encoding/swe:TextEncoding/@blockSeparator)
        let $decimalSeparator := string($x//swe:encoding/swe:TextEncoding/@decimalSeparator)
        let $tokenSeparator := string($x//swe:encoding/swe:TextEncoding/@tokenSeparator)
        let $definition := $x//swe:field[@name = "Value"]/swe:Quantity/@definition/string()
        let $fields := data($x//swe:elementType/swe:DataRecord/swe:field/@name)

        let $startPos := index-of($fields, "StartTime")
        let $endPos := index-of($fields, "EndTime")

        for $i at $ipos in tokenize(replace($x//swe:values, $blockSeparator || "$", ""), $blockSeparator)
        let $startTime := tokenize($i, $tokenSeparator)[$startPos]
        let $endTime := tokenize($i, $tokenSeparator)[$endPos]
        let $result :=
            if (not($startTime castable as xs:dateTime) or not($endTime castable as xs:dateTime)) then
                true()
            else
                let $startDateTime := xs:dateTime($startTime)
                let $endDateTime := xs:dateTime($endTime)
                return
                    (:if ($definition = $vocabulary:OBSERVATIONS_PRIMARY || "hour") then
                        if (($endDateTime - $startDateTime) div xs:dayTimeDuration("PT1H") = 1) then
                            false()
                        else
                            true()
                    else if ($definition = $vocabulary:OBSERVATIONS_PRIMARY || "day") then
                        if (($endDateTime - $startDateTime) div xs:dayTimeDuration("P1D") = 1) then
                            false()
                        else
                            true()
                    else if ($definition = $vocabulary:OBSERVATIONS_PRIMARY || "year") then
                        if (common:isDateTimeDifferenceOneYear($startDateTime, $endDateTime)) then
                            false()
                        else
                            true()
                    else if ($definition = $vocabulary:OBSERVATIONS_PRIMARY || "var") then
                        if (($endDateTime - $startDateTime) div xs:dayTimeDuration("PT1H") > 0) then
                            false()
                        else
                            true()
                    else
                        false():)
            switch ($definition)
              case '$vocabulary:OBSERVATIONS_PRIMARY || "hour"'
                return if (($endDateTime - $startDateTime) div xs:dayTimeDuration("PT1H") = 1) then
                            false()
                        else
                            true()
              case '$vocabulary:OBSERVATIONS_PRIMARY || "day"'
                return if (($endDateTime - $startDateTime) div xs:dayTimeDuration("P1D") = 1) then
                            false()
                        else
                            true()
              case '$vocabulary:OBSERVATIONS_PRIMARY || "year"'
                return if (common:isDateTimeDifferenceOneYear($startDateTime, $endDateTime)) then
                            false()
                        else
                            true()
              case '$vocabulary:OBSERVATIONS_PRIMARY || "var"'
                return if (($endDateTime - $startDateTime) div xs:dayTimeDuration("PT1H") > 0) then
                            false()
                        else
                            true()
              default 
                return false()
                              
        where $result = true()
        return
            <tr>
                <td title="@gml:id">{string($x/../@gml:id)}</td>
                <td title="@definition">{$definition}</td>
                <td title="StartTime">{$startTime}</td>
                <td title="EndTime">{$endTime}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    }
    catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ms2E24 := prof:current-ms()

let $ms1E25 := prof:current-ms()


let $E25invalid :=
    try {
        (for $x at $xpos in $docRoot//om:OM_Observation/om:result
        let $blockSeparator := string($x//swe:encoding/swe:TextEncoding/@blockSeparator)
        let $decimalSeparator := string($x//swe:encoding/swe:TextEncoding/@decimalSeparator)
        let $tokenSeparator := string($x//swe:encoding/swe:TextEncoding/@tokenSeparator)
        let $fields := data($x//swe:elementType/swe:DataRecord/swe:field/@name)
        let $startPos := index-of($fields, "StartTime")
        let $endPos := index-of($fields, "EndTime")
        let $expectedStart := $x/../om:phenomenonTime/gml:TimePeriod/gml:beginPosition/text()
        let $expectedEnd := $x/../om:phenomenonTime/gml:TimePeriod/gml:endPosition/text()
        return
            try {
                let $arrayValuesPos1 := tokenize($x//swe:values, $blockSeparator)[1]
                let $arrayValuesLastPos := tokenize($x//swe:values, $blockSeparator)[last()]
                let $firstAndLastElement := concat($arrayValuesPos1, $blockSeparator, $arrayValuesLastPos)
                for $i at $ipos in tokenize(replace($firstAndLastElement, $blockSeparator || "$", ""), $blockSeparator)

                let $startTime := tokenize($i, $tokenSeparator)[$startPos]
                let $endTime := tokenize($i, $tokenSeparator)[$endPos]
                where not(xs:dateTime($expectedStart) <= xs:dateTime($startTime)) or not(xs:dateTime($expectedEnd) >= xs:dateTime($endTime))
                return
                    <tr>
                        <td title="@gml:id">{string($x/../@gml:id)}</td>
                        <td title="Data record position">{$ipos}</td>
                        <td title="gml:beginPosition">{$expectedStart}</td>
                        <td title="StartTime">{$startTime}</td>
                        <td title="gml:endPosition">{$expectedEnd}</td>
                        <td title="EndTime">{$endTime}</td>
                    </tr>
            } catch * {
                <tr class="{$errors:FAILED}">
                    <td title="Error code">{$err:code}</td>
                    <td title="Error description">{$err:description}</td>
                </tr>
            })[position() = 1 to $errors:HIGHER_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ms2E25 := prof:current-ms()

(: E25b :)

let $ms1E25b := prof:current-ms()

let $E25binvalid :=
    try {
        (for $x at $xpos in $docRoot//om:OM_Observation
        
        let $headerBeginPosition := xs:dateTime($x/../..//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:beginPosition)
        let $headerEndPosition := xs:dateTime($x/../..//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:endPosition)
        
        let $fields := data($x//om:result/swe:elementType/swe:DataRecord/swe:field/@name)

        let $field := $x//om:result/swe:DataArray/swe:elementType/swe:DataRecord/swe:field

        let $beginPosition := xs:dateTime($x//om:phenomenonTime/gml:TimePeriod/gml:beginPosition)
        let $endPosition := xs:dateTime($x//om:phenomenonTime/gml:TimePeriod/gml:endPosition)

        
         return
            if(contains($field[@name = "Value"]/swe:Quantity/@definition, '/day') or contains($field[@name = "Value"]/swe:Quantity/@definition, '/hour'))then 
                  if(($headerBeginPosition - xs:dayTimeDuration("P1D")) > $beginPosition or ($headerEndPosition + xs:dayTimeDuration("P1D")) < $endPosition ) then
                    <tr>
                        <td title="@gml:id">{string($x/@gml:id)}</td>
                        <td title="gml:headerBeginPosition">{$headerBeginPosition}</td>
                        <td title="gml:headerEndPosition">{$headerEndPosition}</td>
                        <td title="gml:beginPosition">{$beginPosition}</td>
                        <td title="gml:endPosition">{$endPosition}</td>
                        
                    </tr>
                           else()
            else if (($headerBeginPosition - xs:dayTimeDuration("P42D")) > $beginPosition or ($headerEndPosition + xs:dayTimeDuration("P42D")) < $endPosition ) then
                
                    <tr>
                        <td title="@gml:id">{string($x/@gml:id)}</td>
                        <td title="gml:headerBeginPosition">{$headerBeginPosition}</td>
                        <td title="gml:headerEndPosition">{$headerEndPosition}</td>
                        <td title="gml:beginPosition">{$beginPosition}</td>
                        <td title="gml:endPosition">{$endPosition}</td>
                        
                    </tr>
         else()

        )
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
    
let $ms2E25b := prof:current-ms()

(: E26 :)

let $ms1E26 := prof:current-ms()

let $E26invalid :=
    try {
        (let $result := sparqlx:run(query:getSamplingPointMetadataFromFiles($latestEnvelopeD, $pollutants))
        let $resultsConcat :=
            for $x in $result
            return $x/sparql:binding[@name="localId"]/sparql:literal/string() || $x/sparql:binding[@name="procedure"]/sparql:uri/string() ||
            $x/sparql:binding[@name="featureOfInterest"]/sparql:uri/string() || $x/sparql:binding[@name="observedProperty"]/sparql:uri/string()

        for $x in $docRoot//om:OM_Observation
            let $namedValue := $x/om:parameter/om:NamedValue[om:name/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/processparameter/SamplingPoint"]
            let $samplingPoint := tokenize(common:if-empty($namedValue/om:value, $namedValue/om:value/@xlink:href), "/")[last()]
            let $procedure := $x/om:procedure/@xlink:href/string()
            let $procedure :=
                if (not($procedure = "") and not(starts-with($procedure, "http://"))) then
                    "http://reference.eionet.europa.eu/aq/" || $procedure
                else
                    $procedure
            let $featureOfInterest := $x/om:featureOfInterest/@xlink:href/string()
            let $featureOfInterest :=
                if (not($featureOfInterest = "") and not(starts-with($featureOfInterest, "http://"))) then
                    "http://reference.eionet.europa.eu/aq/" || $featureOfInterest
                else
                    $featureOfInterest
            let $observedProperty := $x/om:observedProperty/@xlink:href/string()
            let $concat := $samplingPoint || $procedure || $featureOfInterest || $observedProperty
        where not($concat = $resultsConcat)
        return
            <tr>
                <td title="om:OM_Observation">{string($x/@gml:id)}</td>
                <td title="aqd:AQD_SamplingPoint">{string($samplingPoint)}</td>
                <td title="aqd:AQD_SamplingPointProcess">{$procedure}</td>
                <td title="aqd:AQD_Sample">{$featureOfInterest}</td>
                <td title="Pollutant">{$observedProperty}</td>
                <td title="Sparql">{sparqlx:getLink(query:getSamplingPointMetadataFromFiles($latestEnvelopeD, $pollutants))}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    }
    catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E26 := prof:current-ms()


let $ms1E26b := prof:current-ms()

let $E26bfunc := function() {
    (let $result := sparqlx:run(query:getE26b($latestEnvelopeD, $pollutants))
    let $operationalResults :=
        for $x in $result
        let $beginPosition := string($x/sparql:binding[@name="beginPosition"]/sparql:literal)
        let $endPosition := string($x/sparql:binding[@name="endPosition"]/sparql:literal)
        let $beginYear := year-from-dateTime(common:getUTCDateTime($beginPosition))
        let $endYear := if ($endPosition = "") then () else year-from-dateTime(common:getUTCDateTime($endPosition))
        let $reportingYear := xs:integer($reportingYear)
        where $beginYear <= $reportingYear and (empty($endYear) or $endYear >= $reportingYear)
        return $x/sparql:binding[@name="localId"]/sparql:literal/string() || $x/sparql:binding[@name="procedure"]/sparql:uri/string() ||
        $x/sparql:binding[@name="featureOfInterest"]/sparql:uri/string() || $x/sparql:binding[@name="observedProperty"]/sparql:uri/string()

    for $x in $docRoot//om:OM_Observation
    let $namedValue := $x/om:parameter/om:NamedValue[om:name/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/processparameter/SamplingPoint"]
    let $samplingPoint := tokenize(common:if-empty($namedValue/om:value, $namedValue/om:value/@xlink:href), "/")[last()]
    let $procedure := $x/om:procedure/@xlink:href/string()
    let $procedure :=
        if (not($procedure = "") and not(starts-with($procedure, "http://"))) then
            "http://reference.eionet.europa.eu/aq/" || $procedure
        else
            $procedure
    let $featureOfInterest := $x/om:featureOfInterest/@xlink:href/string()
    let $featureOfInterest :=
        if (not($featureOfInterest = "") and not(starts-with($featureOfInterest, "http://"))) then
            "http://reference.eionet.europa.eu/aq/" || $featureOfInterest
        else
            $featureOfInterest
    let $observedProperty := $x/om:observedProperty/@xlink:href/string()
    let $concat := $samplingPoint || $procedure || $featureOfInterest || $observedProperty
    where not($concat = $operationalResults)
    return
        <tr>
            <td title="om:OM_Observation">{string($x/@gml:id)}</td>
            <td title="aqd:AQD_SamplingPoint">{string($samplingPoint)}</td>
            <td title="aqd:AQD_SamplingPointProcess">{$procedure}</td>
            <td title="aqd:AQD_Sample">{$featureOfInterest}</td>
            <td title="Pollutant">{$observedProperty}</td>
            <td title="Sparql">{sparqlx:getLink(query:getE26b($latestEnvelopeD, $pollutants))}</td>
        </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
}
let $E26binvalid := errors:trycatch($E26bfunc)


let $ms2E26b := prof:current-ms()

(: E27 :)

let $ms1E27 := prof:current-ms()

let $E27invalid :=
    try {
        (for $x at $xpos in $docRoot//om:OM_Observation/om:result
        let $blockSeparator := string($x//swe:encoding/swe:TextEncoding/@blockSeparator)
        let $decimalSeparator := string($x//swe:encoding/swe:TextEncoding/@decimalSeparator)
        let $tokenSeparator := string($x//swe:encoding/swe:TextEncoding/@tokenSeparator)
        let $validCount := count($x//swe:elementType/swe:DataRecord/swe:field)

        for $i at $ipos in tokenize(replace($x//swe:values, $blockSeparator || "$", ""), $blockSeparator)
        let $count := count(tokenize($i, $tokenSeparator))
        where not($count = $validCount)
        return
            <tr>
                <td title="OM_Observation">{string($x/../@gml:id)}</td>
                <td title="Data record position">{$ipos}</td>
                <td title="Expected fields">{$validCount}</td>
                <td title="Actual fields">{$count}</td>
            </tr>)[position() = 1 to $errors:HIGHER_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ms2E27 := prof:current-ms()


let $ms1E28 := prof:current-ms()

let $E28invalid :=
    try {
        (for $x at $xpos in $docRoot//om:OM_Observation/om:result
        let $blockSeparator := string($x//swe:encoding/swe:TextEncoding/@blockSeparator)
        where ends-with($x//swe:values, $blockSeparator)
        return
            <tr>
                <td title="OM_Observation">{string($x/../@gml:id)}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ms2E28 := prof:current-ms()



let $ms1E29 := prof:current-ms()

let $E29invalid :=
    try {
        (for $x at $xpos in $docRoot//om:OM_Observation/om:result
        let $blockSeparator := string($x//swe:encoding/swe:TextEncoding/@blockSeparator)
        let $decimalSeparator := string($x//swe:encoding/swe:TextEncoding/@decimalSeparator)
        let $tokenSeparator := string($x//swe:encoding/swe:TextEncoding/@tokenSeparator)
        let $fields := data($x//swe:elementType/swe:DataRecord/swe:field/@name)

        for $i at $ipos in tokenize(replace($x//swe:values, $blockSeparator || "$", ""), $blockSeparator)
        for $z at $zpos in tokenize($i, $tokenSeparator)
        where matches($z, "\s+")
        return
            <tr>
                <td title="OM_Observation">{string($x/../@gml:id)}</td>
                <td title="Data record position">{$ipos}</td>
                <td title="Expected type">{$fields[$zpos]}</td>
                <td title="Actual value">{$z}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E29 := prof:current-ms()
(:let $E30invalid :=
    try {
        (let $valid := dd:getValid($vocabulary:OBSERVATIONS_RANGE)

        for $x at $xpos in $docRoot//om:OM_Observation/om:result
        let $blockSeparator := string($x//swe:encoding/swe:TextEncoding/@blockSeparator)
        let $decimalSeparator := string($x//swe:encoding/swe:TextEncoding/@decimalSeparator)
        let $tokenSeparator := string($x//swe:encoding/swe:TextEncoding/@tokenSeparator)
        let $fields := data($x//swe:elementType/swe:DataRecord/swe:field/@name)

        let $definition := $x//swe:field[@name = "Value"]/swe:Quantity/@definition/string()
        let $uom := $x//swe:field[@name = "Value"]/swe:Quantity/swe:uom/@xlink:href/string()
        let $pollutant := $x/../om:observedProperty/@xlink:href/string()
        let $minValue := $valid[prop:recommendedUnit/@rdf:resource = $uom and prop:relatedPollutant/@rdf:resource = $pollutant and prop:primaryObservationTime/@rdf:resource = $definition]/prop:minimumValue/string()
        let $maxValue := $valid[prop:recommendedUnit/@rdf:resource = $uom and prop:relatedPollutant/@rdf:resource = $pollutant and prop:primaryObservationTime/@rdf:resource = $definition]/prop:maximumValue/string()
        where ($minValue castable as xs:double and $maxValue castable as xs:double)

        for $i at $ipos in tokenize(replace($x//swe:values, $blockSeparator || "$", ""), $blockSeparator)
        let $tokens := tokenize($i, $tokenSeparator)
        let $validity := $tokens[index-of($fields, "Validity")]
        let $value := $tokens[index-of($fields, "Value")]
        where (($validity castable as xs:integer) and xs:integer($validity) >= 1) and (not($value castable as xs:double) or (xs:double($value) < xs:double($minValue)) or (xs:double($value) > xs:double($maxValue)))
        return
            <tr>
                <td title="OM_Observation">{string($x/../@gml:id)}</td>
                <td title="Data record position">{$ipos}</td>
                <td title="Pollutant">{tokenize($pollutant, "/")[last()]}</td>
                <td title="Concentration">{tokenize($uom, "/")[last()]}</td>
                <td title="Primary Observation">{tokenize($definition, "/")[last()]}</td>
                <td title="Minimum value">{$minValue}</td>
                <td title="Maximum value">{$maxValue}</td>
                <td title="Actual value">{$value}</td>
            </tr>)[position() = 1 to $errors:MAX_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }:)

let $ms1E30a := prof:current-ms()

let $E30ainvalid :=
    try {
        (let $valid := dd:getValid($vocabulary:OBSERVATIONS_RANGE)
         let $validCountry := dd:getValid($vocabulary:OBSERVATIONS_RANGE_COUNTRY)
          
            for $x at $xpos in $docRoot//om:OM_Observation/om:result
            let $blockSeparator := string($x//swe:encoding/swe:TextEncoding/@blockSeparator)
            let $decimalSeparator := string($x//swe:encoding/swe:TextEncoding/@decimalSeparator)
            let $tokenSeparator := string($x//swe:encoding/swe:TextEncoding/@tokenSeparator)
            let $fields := data($x//swe:elementType/swe:DataRecord/swe:field/@name)

            let $definition := $x//swe:field[@name = "Value"]/swe:Quantity/@definition/string()
            let $uom := $x//swe:field[@name = "Value"]/swe:Quantity/swe:uom/@xlink:href/string()
            let $pollutant := $x/../om:observedProperty/@xlink:href/string()
            let $minValue := $valid[prop:recommendedUnit/@rdf:resource = $uom and prop:relatedPollutant/@rdf:resource = $pollutant and prop:primaryObservationTime/@rdf:resource = $definition]/prop:minimumValue/string()
            let $maxValue := $valid[prop:recommendedUnit/@rdf:resource = $uom and prop:relatedPollutant/@rdf:resource = $pollutant and prop:primaryObservationTime/@rdf:resource = $definition]/prop:maximumValue/string()
            
            let $inCountry := "http://dd.eionet.europa.eu/vocabulary/common/countries/" || upper-case($countryCode)

            let $combinationMissing := $validCountry[prop:inCountry/@rdf:resource = $inCountry and prop:recommendedUnit/@rdf:resource = $uom and prop:relatedPollutant/@rdf:resource = $pollutant and prop:primaryObservationTime/@rdf:resource = $definition] = ""(:empty():)
            let $countryMinValue := $validCountry[prop:inCountry/@rdf:resource = $inCountry and prop:recommendedUnit/@rdf:resource = $uom and prop:relatedPollutant/@rdf:resource = $pollutant and prop:primaryObservationTime/@rdf:resource = $definition]/prop:minimumValue/string()
            let $countryMaxValue := $validCountry[prop:inCountry/@rdf:resource = $inCountry and prop:recommendedUnit/@rdf:resource = $uom and prop:relatedPollutant/@rdf:resource = $pollutant and prop:primaryObservationTime/@rdf:resource = $definition]/prop:maximumValue/string()
           
            
            (:where ($minValue castable as xs:double and $maxValue castable as xs:double)
              where ($minValue castable as xs:double and $maxValue castable as xs:double and not($combinationMissing)):)
            return 
            if($countryMinValue castable as xs:double and $countryMaxValue castable as xs:double and not($combinationMissing))then
                for $i at $ipos in tokenize(replace($x//swe:values, $blockSeparator || "$", ""), $blockSeparator)

                let $tokens := tokenize($i, $tokenSeparator)
                let $validity := $tokens[index-of($fields, "Validity")]
                let $value := $tokens[index-of($fields, "Value")]
                where (($validity castable as xs:integer) and xs:integer($validity) >= 1) and (not($value castable as xs:double) or (xs:double($value) < xs:double($countryMinValue)) or (xs:double($value) > xs:double($countryMaxValue)))
                return
                    <tr>
                        <td title="OM_Observation">{string($x/../@gml:id)}</td>
                        <td title="Data record position">{$ipos}</td>
                        <td title="Pollutant">{tokenize($pollutant, "/")[last()]}</td>
                        <td title="Concentration">{tokenize($uom, "/")[last()]}</td>
                        <td title="Primary Observation">{tokenize($definition, "/")[last()]}</td>
                        <td title="Minimum value">{$countryMinValue}</td>
                        <td title="Maximum value">{$countryMaxValue}</td>
                        <td title="Actual value">{$value}</td>
                    </tr>
              else if($minValue castable as xs:double and $maxValue castable as xs:double)then 
                    for $i at $ipos in tokenize(replace($x//swe:values, $blockSeparator || "$", ""), $blockSeparator)

                      let $tokens := tokenize($i, $tokenSeparator)
                      let $validity := $tokens[index-of($fields, "Validity")]
                      let $value := $tokens[index-of($fields, "Value")]
                      where (($validity castable as xs:integer) and xs:integer($validity) >= 1) and (not($value castable as xs:double) or (xs:double($value) < xs:double($minValue)) or (xs:double($value) > xs:double($maxValue)))
                      return
                          <tr>
                              <td title="OM_Observation">{string($x/../@gml:id)}</td>
                              <td title="Data record position">{$ipos}</td>
                              <td title="Pollutant">{tokenize($pollutant, "/")[last()]}</td>
                              <td title="Concentration">{tokenize($uom, "/")[last()]}</td>
                              <td title="Primary Observation">{tokenize($definition, "/")[last()]}</td>
                              <td title="Minimum value">{$minValue}</td>
                              <td title="Maximum value">{$maxValue}</td>
                              <td title="Actual value">{$value}</td>
                          </tr>
                else())[position() = 1 to $errors:MAX_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E30a := prof:current-ms()

(:let $E30bfunc := function() { 
    (let $valid := dd:getValid($vocabulary:OBSERVATIONS_RANGE_COUNTRY)

    for $x at $xpos in $docRoot//om:OM_Observation/om:result
    let $blockSeparator := string($x//swe:encoding/swe:TextEncoding/@blockSeparator)
    let $decimalSeparator := string($x//swe:encoding/swe:TextEncoding/@decimalSeparator)
    let $tokenSeparator := string($x//swe:encoding/swe:TextEncoding/@tokenSeparator)
    let $fields := data($x//swe:elementType/swe:DataRecord/swe:field/@name)

    let $definition := $x//swe:field[@name = "Value"]/swe:Quantity/@definition/string()
    let $uom := $x//swe:field[@name = "Value"]/swe:Quantity/swe:uom/@xlink:href/string()
    let $pollutant := $x/../om:observedProperty/@xlink:href/string()
    let $inCountry := "http://dd.eionet.europa.eu/vocabulary/common/countries/" || upper-case($countryCode)

    let $combinationMissing := $valid[prop:inCountry/@rdf:resource = $inCountry and prop:recommendedUnit/@rdf:resource = $uom and prop:relatedPollutant/@rdf:resource = $pollutant and prop:primaryObservationTime/@rdf:resource = $definition] => empty()
    let $minValue := $valid[prop:inCountry/@rdf:resource = $inCountry and prop:recommendedUnit/@rdf:resource = $uom and prop:relatedPollutant/@rdf:resource = $pollutant and prop:primaryObservationTime/@rdf:resource = $definition]/prop:minimumValue/string()
    let $maxValue := $valid[prop:inCountry/@rdf:resource = $inCountry and prop:recommendedUnit/@rdf:resource = $uom and prop:relatedPollutant/@rdf:resource = $pollutant and prop:primaryObservationTime/@rdf:resource = $definition]/prop:maximumValue/string()
    where ($minValue castable as xs:double and $maxValue castable as xs:double and not($combinationMissing))

    for $i at $ipos in tokenize(replace($x//swe:values, $blockSeparator || "$", ""), $blockSeparator)
    let $tokens := tokenize($i, $tokenSeparator)
    let $validity := $tokens[index-of($fields, "Validity")]
    let $value := $tokens[index-of($fields, "Value")]
    where (($validity castable as xs:integer) and xs:integer($validity) >= 1) and (not($value castable as xs:double) or (xs:double($value) < xs:double($minValue)) or (xs:double($value) > xs:double($maxValue)))
    return
        <tr>
            <td title="OM_Observation">{string($x/../@gml:id)}</td>
            <td title="Data record position">{$ipos}</td>
            <td title="Pollutant">{tokenize($pollutant, "/")[last()]}</td>
            <td title="Concentration">{tokenize($uom, "/")[last()]}</td>
            <td title="Primary Observation">{tokenize($definition, "/")[last()]}</td>
            <td title="Minimum value">{$minValue}</td>
            <td title="Maximum value">{$maxValue}</td>
            <td title="Actual value">{$value}</td>
        </tr>)[position() = 1 to $errors:MAX_LIMIT]
}
let $E30binvalid := errors:trycatch($E30bfunc):)

let $ms1E31 := prof:current-ms()

let $E31invalid :=
    try {
        (for $x at $xpos in $docRoot//om:OM_Observation/om:result

        let $blockSeparator := string($x//swe:encoding/swe:TextEncoding/@blockSeparator)
        let $decimalSeparator := string($x//swe:encoding/swe:TextEncoding/@decimalSeparator)
        let $tokenSeparator := string($x//swe:encoding/swe:TextEncoding/@tokenSeparator)
        let $fields := data($x//swe:elementType/swe:DataRecord/swe:field/@name)

        let $startPos := index-of($fields, "StartTime")
        let $endPos := index-of($fields, "EndTime")

        let $startTimes := for $i in tokenize(replace($x//swe:values, $blockSeparator || "$", ""), $blockSeparator)
        return tokenize($i, $tokenSeparator)[$startPos]
        let $endTimes := for $i in tokenize(replace($x//swe:values, $blockSeparator || "$", ""), $blockSeparator)
        return tokenize($i, $tokenSeparator)[$endPos]
        
        return try {
            for $startTime at $ipos in $startTimes
            let $prevStartTime := $startTimes[$ipos - 1]
            let $endTime := $endTimes[$ipos]
            let $prevEndTime := $endTimes[$ipos - 1]
            where not($ipos = 1) and (xs:dateTime($startTime) < xs:dateTime($prevEndTime))
            return
                <tr>
                    <td title="@gml:id">{string($x/../@gml:id)}</td>
                    <td title="Data record position">{$ipos}</td>
                    <td title="StartTime">{$startTime}</td>
                    <td title="Previous endTime">{$prevEndTime}</td>
                </tr>
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        })[position() = 1 to $errors:MEDIUM_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E31 := prof:current-ms()


let $ms1E32 := prof:current-ms()

let $E32invalid :=
    try {
        (for $x at $xpos in $docRoot//om:OM_Observation/om:result
        let $blockSeparator := string($x//swe:encoding/swe:TextEncoding/@blockSeparator)
        let $decimalSeparator := string($x//swe:encoding/swe:TextEncoding/@decimalSeparator)
        let $tokenSeparator := string($x//swe:encoding/swe:TextEncoding/@tokenSeparator)
        let $fields := data($x//swe:elementType/swe:DataRecord/swe:field/@name)
        let $verificationPos := index-of($fields, "Verification")

        let $values :=
            for $i at $ipos in tokenize(replace($x//swe:values, $blockSeparator || "$", ""), $blockSeparator)
            let $verification := tokenize($i, $tokenSeparator)[$verificationPos]
            where not($verification = "1")
            return
                $verification
        for $z in distinct-values($values)
        return
            <tr>
                <td title="OM_Observation">{string($x/../@gml:id)}</td>
                <td title="Verification">{$z}</td>
                <td title="Occurrences">{count(index-of($values, $z))}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]

    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2E32 := prof:current-ms()


let $ms1E33 := prof:current-ms()

let $E33func := function() {
    (for $x at $xpos in $docRoot//om:OM_Observation/om:result

    let $blockSeparator := string($x//swe:encoding/swe:TextEncoding/@blockSeparator)
    let $decimalSeparator := string($x//swe:encoding/swe:TextEncoding/@decimalSeparator)
    let $tokenSeparator := string($x//swe:encoding/swe:TextEncoding/@tokenSeparator)
    let $fields := data($x//swe:elementType/swe:DataRecord/swe:field/@name)
    let $observationType := (string($x//swe:field[@name = "Value"]/swe:Quantity/@definition) => tokenize("/"))[last()]
    let $coverageType := if ($observationType = "hour") then "Hourly" else "Daily"
    let $values :=
        for $i at $ipos in tokenize(replace($x//swe:values, $blockSeparator || "$", ""), $blockSeparator)
        let $values := tokenize($i, $tokenSeparator)
        let $validity := $values[index-of($fields, "Validity")]
        let $value := $values[index-of($fields, "Value")]
        where $validity castable as xs:decimal and xs:decimal($validity) > 0 and $value castable as xs:decimal
        return xs:decimal($value)
    let $count := count($values)
    return if ($count = 0) then () else
    let $values := $values => sum()
    let $mean := $values div $count
    let $dataCoverage :=
        let $dc :=
        if ($observationType = "day") then
            ($count div common:getYearDaysCount($reportingYear)) => format-number("0.01")
        else
            ($count div common:getYearHoursCount($reportingYear)) => format-number("0.01")
        let $dc := number($dc) * 100
        return $dc || "%"
    where $mean <= 0
    return
        <tr>
            <td title="OM_Observation">{string($x/../@gml:id)}</td>
            <td title="Mean">{format-number($mean, "0.1")}</td>
            <td title="Data coverage">{$coverageType || " coverage: " || $dataCoverage}</td>
        </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
}
let $E33invalid := errors:trycatch($E33func)

let $ms2E33 := prof:current-ms()


let $ms1E34 := prof:current-ms()

let $E34func := function() {
    
    (let $previousData := sparqlx:run(query:getE34($countryCode, $reportingYear))
          
    for $x at $xpos in $docRoot//om:OM_Observation
   
      let $previousTRT:=
        for $y in $x/om:parameter/om:NamedValue[om:name/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/processparameter/SamplingPoint"]
         (: let $samplingPoint := tokenize(common:if-empty($y/om:value, 'no data'), "/")[last()]:)
         let $samplingPoint := tokenize(common:if-empty($y/om:value, $y/om:value/@xlink:href), "/")[last()]
         (:let $previousMean := sparqlx:run(query:getE34Sampling($countryCode, $reportingYear, $samplingPoint)):)
        return $previousData[(sparql:binding[@name = "SamplingPointLocalId"]/sparql:literal = $samplingPoint)]/sparql:binding[@name = "AQValue"]/sparql:literal
      
       let $previousTRTquery:=
         for $y in $x/om:parameter/om:NamedValue[om:name/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/processparameter/SamplingPoint"]
            let $samplingPoint := tokenize(common:if-empty($y/om:value, $y/om:value/@xlink:href), "/")[last()]
            let $previousMean := sparqlx:getLink(query:getE34Sampling($countryCode, $reportingYear, $samplingPoint))
        return $previousMean

 
   return if (string($previousTRT) = 'NaN' ) then () else 

    let $blockSeparator := string($x//swe:encoding/swe:TextEncoding/@blockSeparator)
    let $decimalSeparator := string($x//swe:encoding/swe:TextEncoding/@decimalSeparator)
    let $tokenSeparator := string($x//swe:encoding/swe:TextEncoding/@tokenSeparator)
    let $fields := data($x//swe:elementType/swe:DataRecord/swe:field/@name)
    let $observationType := (string($x//swe:field[@name = "Value"]/swe:Quantity/@definition) => tokenize("/"))[last()]
    let $coverageType := if ($observationType = "hour") then "Hourly" else "Daily"
    let $values :=
        for $i at $ipos in tokenize(replace($x//swe:values, $blockSeparator || "$", ""), $blockSeparator)
        let $values := tokenize($i, $tokenSeparator)
        let $validity := $values[index-of($fields, "Validity")]
        let $value := $values[index-of($fields, "Value")]
        where $validity castable as xs:decimal and xs:decimal($validity) >= 0 and $value castable as xs:decimal
                
        return xs:decimal($value)
    let $count := count($values)
    
    return if ($count = 0) then () else
    
    let $values := $values => sum()
    let $mean := $values div $count
    let $dataCoverage :=
        let $dc :=
            if ($observationType = "day") then
                ($count div common:getYearDaysCount($reportingYear)) => format-number("0.01")
            else
                ($count div common:getYearHoursCount($reportingYear)) => format-number("0.01")
        let $dc := number($dc) * 100
        return $dc || "%"
    let $higherLimit := $previousTRT * 3
    let $lowerLimit := $previousTRT div 3
    where $mean > $higherLimit or $mean < $lowerLimit
    
    return    
        <tr>
            <td title="OM_Observation">{string($x/@gml:id)}</td>
            <td title="Mean">{format-number($mean, "0.1")}</td>
            <td title="Previous Mean">{format-number($previousTRT, "0.1")}</td>
            <td title="Data coverage">{$coverageType || " coverage: " || $dataCoverage}</td>
            <td title="Sparql">{sparqlx:getLink(query:getE34($countryCode, $reportingYear))}</td>
        </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
       
}

let $E34invalid := errors:trycatch($E34func)

let $ms2E34 := prof:current-ms()

let $ms2Total := prof:current-ms()

return
    <table class="maintable hover">
    <table>
        {html:build2("NS", $labels:NAMESPACES, $labels:NAMESPACES_SHORT, $NSinvalid, "All values are valid", "record", $errors:NS)}
        {html:build2("VOCAB", $labels:VOCAB, $labels:VOCAB, $VOCABinvalid, "All values are valid", "record", $errors:VOCAB)}
        {html:build3("E0", $labels:E0, $labels:E0_SHORT, $E0table, data($E0table/td), errors:getMaxError($E0table))}
        {html:build1("E01a", $labels:E01a, $labels:E01a_SHORT, $E01atable, "", string(count($E01atable)), "record", "", $errors:E01a)}
        {html:build2("E01b", $labels:E01b, $labels:E01b_SHORT, $E01binvalid, "All records are valid", "record", $errors:E01b)}
        {html:build2("E02", $labels:E02, $labels:E02_SHORT, $E02invalid, "All records are valid", "record", $errors:E02)}
        {html:build2("E03", $labels:E03, $labels:E03_SHORT, $E03invalid, "All records are valid", "record", $errors:E03)}
        {html:build2Sparql("E04", $labels:E04, $labels:E04_SHORT, $E04invalid, "All records are valid", "record", $errors:E04)}
        {html:build2("E05", $labels:E05, $labels:E05_SHORT, $E05invalid, "All records are valid", "record", $errors:E05)}
        {html:build2Sparql("E06", $labels:E06, $labels:E06_SHORT, $E06invalid, "All records are valid", "record", $errors:E06)}
        {html:build2("E07", $labels:E07, $labels:E07_SHORT, $E07invalid, "All records are valid", "record", $errors:E07)}
        {html:build2("E08", $labels:E08, $labels:E08_SHORT, $E08invalid, "All records are valid", "record", $errors:E08)}
        {html:build2("E09", $labels:E09, $labels:E09_SHORT, $E09invalid, "All records are valid", "record", $errors:E09)}
        {html:build2("E10", $labels:E10, $labels:E10_SHORT, $E10invalid, "All records are valid", "record", $errors:E10)}
        {html:build2Sparql("E11", $labels:E11, $labels:E11_SHORT, $E11invalid, "All records are valid", "record", $errors:E11)}
        {html:build2Sparql("E12", $labels:E12, $labels:E12_SHORT, $E12invalid, "All records are valid", "record", $errors:E12)}
        {html:build2("E15", $labels:E15, $labels:E15_SHORT, $E15invalid, "All records are valid", "record", $errors:E15)}
        {html:build2("E16", $labels:E16, $labels:E16_SHORT, $E16invalid, "All records are valid", "record", $errors:E16)}
        {html:build2("E17", $labels:E17, $labels:E17_SHORT, $E17invalid, "All records are valid", "record", $errors:E17)}
        {html:build2("E18", $labels:E18, $labels:E18_SHORT, $E18invalid, "All records are valid", "record", $errors:E18)}
        {html:build2("E19", $labels:E19, $labels:E19_SHORT, $E19invalid, "All records are valid", "record", $errors:E19)}
        {html:build2("E19a", $labels:E19a, $labels:E19a_SHORT, $E19ainvalid, "All records are valid", "record", $errors:E19a)}
        {html:build2("E19b", $labels:E19b, $labels:E19b_SHORT, $E19binvalid, "All records are valid", "record", $errors:E19b)}
        {html:build2("E19c", $labels:E19c, $labels:E19c_SHORT, $E19cinvalid, "All records are valid", "record", $errors:E19c)}
        {html:build2("E20", $labels:E20, $labels:E20_SHORT, $E20invalid, "All records are valid", "record", $errors:E20)}
        {html:build2("E21", $labels:E21, $labels:E21_SHORT, $E21invalid, "All records are valid", "record", $errors:E21)}
        {html:build2("E22", $labels:E22, $labels:E22_SHORT, $E22invalid, "All records are valid", "record", $errors:E22)}
        {html:build2("E23", $labels:E23, $labels:E23_SHORT, $E23invalid, "All records are valid", "record", $errors:E23)}
        {html:build2("E24", $labels:E24, $labels:E24_SHORT, $E24invalid, "All records are valid", "record", $errors:E24)}
        {html:build2("E25", $labels:E25, $labels:E25_SHORT, $E25invalid, "All records are valid", "record", $errors:E25)}
        {html:build2("E25b", $labels:E25b, $labels:E25b_SHORT, $E25binvalid, "All records are valid", "record", $errors:E25b)}
        {html:build2Sparql("E26", $labels:E26, $labels:E26_SHORT, $E26invalid, "All records are valid", "record", $errors:E26)}
        {html:build2Sparql("E26b", $labels:E26b, $labels:E26b_SHORT, $E26binvalid, "All records are valid", "record", $errors:E26b)}
        {html:build2("E27", $labels:E27, $labels:E27_SHORT, $E27invalid, "All records are valid", "record", $errors:E27)}
        {html:build2("E28", $labels:E28, $labels:E28_SHORT, $E28invalid, "All records are valid", "record", $errors:E28)}
        {html:build2("E29", $labels:E29, $labels:E29_SHORT, $E29invalid, "All records are valid", "record", $errors:E29)}
        <!--{html:build2("E30", $labels:E30, $labels:E30_SHORT, $E30invalid, "All records are valid", "record", $errors:E30)}-->
        {html:build2("E30a", $labels:E30a, $labels:E30a_SHORT, $E30ainvalid, "All records are valid", "record", $errors:E30a)}
        <!--{html:build2("E30b", $labels:E30b, $labels:E30b_SHORT, $E30binvalid, "All records are valid", "record", $errors:E30b)}-->
        {html:build2("E31", $labels:E31, $labels:E31_SHORT, $E31invalid, "All records are valid", "record", $errors:E31)}
        {html:build2("E32", $labels:E32, $labels:E32_SHORT, $E32invalid, "All records are valid", "record", $errors:E32)}
        {html:build2("E33", $labels:E33, $labels:E33_SHORT, $E33invalid, "All records are valid", "record", $errors:E33)}
        {html:build2Sparql("E34", $labels:E34, $labels:E34_SHORT, $E34invalid, "All records are valid", "record", $errors:E34)}
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
       {common:runtime("VOCAB", $ms1EVOCAB, $ms2EVOCAB)}
       {common:runtime("E0",  $ms1E0, $ms2E0)}
       {common:runtime("E01a", $ms1E01a, $ms2E01a)}
       {common:runtime("E01b", $ms1E01b, $ms2E01b)}
       {common:runtime("E02", $ms1E02, $ms2E02)}
       {common:runtime("E03", $ms1E03, $ms2E03)}
       {common:runtime("E04",  $ms1E04, $ms2E04)}
       {common:runtime("E05", $ms1E05, $ms2E05)}
       {common:runtime("E06",  $ms1E06, $ms2E06)}
       {common:runtime("E07",  $ms1E07, $ms2E07)}
       {common:runtime("E08",  $ms1E08, $ms2E08)}
       {common:runtime("E09",  $ms1E09, $ms2E09)}
       {common:runtime("E10",  $ms1E10, $ms2E10)}
       {common:runtime("E11",  $ms1E11, $ms2E11)}
       {common:runtime("E12",  $ms1E12, $ms2E12)}
       {common:runtime("E15",  $ms1E15, $ms2E15)}
       {common:runtime("E16",  $ms1E16, $ms2E16)}
       {common:runtime("E17",  $ms1E17, $ms2E17)}
       {common:runtime("E18",  $ms1E18, $ms2E18)}
       {common:runtime("E19",  $ms1E19, $ms2E19)}
       {common:runtime("E19a",  $ms1E19a, $ms2E19a)}
       {common:runtime("E19b",  $ms1E19b, $ms2E19b)}
       {common:runtime("E19c",  $ms1E19c, $ms2E19c)}
       {common:runtime("E20", $ms1E20, $ms2E20)}
       {common:runtime("E21",  $ms1E21, $ms2E21)}
       {common:runtime("E22",  $ms1E22, $ms2E22)}
       {common:runtime("E23",  $ms1E23, $ms2E23)}
       {common:runtime("E24",  $ms1E24, $ms2E24)}
       {common:runtime("E25",  $ms1E25, $ms2E25)}
       {common:runtime("E25b",  $ms1E25b, $ms2E25b)}
       {common:runtime("E26",  $ms1E26, $ms2E26)}
       {common:runtime("E26b",  $ms1E26b, $ms2E26b)}
       {common:runtime("E27",  $ms1E27, $ms2E27)}
       {common:runtime("E28",  $ms1E28, $ms2E28)}
       {common:runtime("E29",  $ms1E29, $ms2E29)}
       {common:runtime("E30a",  $ms1E30a, $ms2E30a)}
       {common:runtime("E31",  $ms1E31, $ms2E31)}
       {common:runtime("E32",  $ms1E32, $ms2E32)}
       {common:runtime("E33",  $ms1E33, $ms2E33)}
       {common:runtime("E34",  $ms1E34, $ms2E34)}

       {common:runtime("Total time",  $ms1Total, $ms2Total)}
    </table>
    </table>

};


declare function dataflowEa:proceed($source_url as xs:string, $countryCode as xs:string) as element(div) {
    let $count := count(doc($source_url)//om:OM_Observation)
    let $result := if ($count > 0) then dataflowEa:checkReport($source_url, $countryCode) else ()
    let $meta := map:merge((
        map:entry("count", $count),
        map:entry("header", "Check air quality observations"),
        map:entry("dataflow", "Dataflow E"),
        map:entry("zeroCount", <p>No aqd:OM_Observation elements found in this XML.</p>),
        map:entry("report", <p>This check evaluated the delivery by executing tier-1 tests on air quality observation data in Dataflow E as specified in <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a>.</p>)
    ))
    return
        html:buildResultDiv($meta, $result)
};
