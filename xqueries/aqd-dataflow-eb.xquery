xquery version "3.0" encoding "UTF-8";

module namespace dataflowEb = "http://converters.eionet.europa.eu/dataflowEb";
import module namespace common = "aqd-common" at "aqd-common.xquery";
import module namespace sparqlx = "aqd-sparql" at "aqd-sparql.xquery";
import module namespace labels = "aqd-labels" at "aqd-labels.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";
import module namespace dd = "aqd-dd" at "aqd-dd.xquery";
import module namespace vocabulary = "aqd-vocabulary" at "aqd-vocabulary.xquery";
import module namespace query = "aqd-query" at "aqd-query.xquery";
import module namespace errors = "aqd-errors" at "aqd-errors.xquery";
import module namespace schemax = "aqd-schema" at "aqd-schema.xquery";
import module namespace functx = "http://www.functx.com" at "aqd-functx.xq";

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

declare variable $dataflowEb:OBLIGATIONS as xs:string* := ($vocabulary:ROD_PREFIX || "674");
declare variable $dataflowEb:FEATURE_TYPES := ("aqd:AQD_Model", "aqd:AQD_ModelProcess", "aqd:AQD_ModelArea");

(: Rule implementations :)
declare function dataflowEb:checkReport($source_url as xs:string, $countryCode as xs:string) as element(table) {
    let $docRoot := doc($source_url)
    let $cdrUrl := common:getCdrUrl($countryCode)
    let $reportingYear := common:getReportingYear($docRoot)
    let $latestEnvelopeD1b := query:getLatestEnvelope($cdrUrl || "d1b/")

    (: File prefix/namespace check :)
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

    (: Eb0 - Check if delivery if this is a new delivery or updated delivery (via reporting year) :)
    let $Eb0table :=
        try {
            if ($reportingYear = "") then
                <tr class="{$errors:ERROR}">
                    <td title="Status">Reporting Year is missing.</td>
                </tr>
            else if (query:deliveryExists($dataflowEb:OBLIGATIONS, $countryCode, "e1b/", $reportingYear)) then
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
    let $isNewDelivery := errors:getMaxError($Eb0table) = $errors:INFO

    (: Eb01 - Compile & feedback upon the total number of observations included in the delivery :)
    let $Eb01table :=
        try {
            let $parameters := for $i in ("model", "objective") return $vocabulary:PROCESS_PARAMETER || $i
            for $x in $docRoot//om:OM_Observation
            let $namedValue := $x/om:parameter/om:NamedValue[om:name/@xlink:href = $parameters]
            let $model := tokenize(common:if-empty($namedValue/om:value, $namedValue/om:value/@xlink:href), "/")[last()]
            let $observedProperty := $x/om:observedProperty/@xlink:href/string()
            return
                <tr>
                    <td title="gml:id">{data($x/@gml:id)}</td>
                    <td title="aqd:AQD_Model">{$model}</td>
                    <td title="Pollutant">{$observedProperty}</td>
                </tr>
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    (:Eb02 ./om:phenomenonTime/gml:TimePeriod/gml:beginPosition shall be LESS THAN ./om:phenomenonTime/gml:TimePeriod/gml:endPosition. :)
    let $Eb02invalid :=
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
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    (:Eb03 - ./om:resultTime/gml:TimeInstant/gml:timePosition shall be GREATER THAN ./om:phenomenonTime/gml:TimePeriod/gml:endPosition :)
    let $Eb03invalid :=
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

    (: Eb04 -  All om:OM_Observation/ must provide a valid /om:procedure xlink (can not be empty) & ./om:procedure xlink:href attribute
     shall resolve to a traversable link process configuration in Data flow D1b: /aqd:AQD_ModelProcess/ompr:inspireld/base:Identifier/base:localId :)
    let $Eb04invalid :=
        try {
            (let $result := sparqlx:run(query:getModelProcess($cdrUrl))
            let $all := $result/sparql:binding[@name = "inspireLabel"]/sparql:literal/string()
            let $procedures := $docRoot//om:procedure/@xlink:href/string()
            for $x in $procedures[not(. = $all)]
            return
                <tr>
                    <td title="base:localId">{$x}</td>
                </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    (: Eb05 A valid delivery MUST provide an om:parameter/om:NamedValue/om:name xlink:href to
    either http://dd.eionet.europa.eu/vocabulary/aq/processparameter/model or http://dd.eionet.europa.eu/vocabulary/aq/processparameter/objective :)
    let $Eb05invalid :=
        try {
            (let $parameters := for $i in ("model", "objective") return $vocabulary:PROCESS_PARAMETER || $i
            for $x in $docRoot//om:OM_Observation
            where not($x/om:parameter/om:NamedValue/om:name/@xlink:href = $parameters)
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

    (: Eb06 - If ./om:parameter/om:NamedValue/om:name xlink:href  resolves to http://dd.eionet.europa.eu/vocabulary/aq/processparameter/model or .../objective
/om:parameter/om:NamedValue/om:value xlink:href attribute shall resolve to a traversable link to a unique AQD_Model (“namespace/localId” of the object) :)
    let $Eb06invalid :=
        try {
            (let $parameters := for $i in ("model", "objective") return $vocabulary:PROCESS_PARAMETER || $i
            let $result := sparqlx:run(query:getModelFromFiles($latestEnvelopeD1b))
            let $all := $result/sparql:binding[@name = "inspireLabel"]/sparql:literal/string()
            for $x in $docRoot//om:OM_Observation/om:parameter/om:NamedValue[om:name/@xlink:href = $parameters]
            let $name := $x/om:name/@xlink:href/string()
            let $value := common:if-empty($x/om:value, $x/om:value/@xlink:href)
            where ($value = "" or not($value = $all))
            return
                <tr>
                    <td title="om:OM_Observation">{string($x/../../@gml:id)}</td>
                    <td title="om:value">{$value}</td>
                </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    (: Eb07 - A valid delivery should provide  an om:parameter with om:name xlink:href to http://dd.eionet.europa.eu/vocabulary/aq/processparameter/AssessmentType :)
    let $Eb07invalid :=
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

    (: Eb08 - If ./om:parameter/om:NamedValue/om:name links to http://dd.eionet.europa.eu/vocabulary/aq/processparameter/AssessmentType
     /om:parameter/om:NamedValue/om:value xlink:href attribute shall resolve to  valid code for http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/ :)
    let $Eb08invalid :=
        try {
            (let $valid := dd:getValidConcepts($vocabulary:ASSESSMENTTYPE_VOCABULARY || "rdf")
            for $x in $docRoot//om:OM_Observation/om:parameter/om:NamedValue[om:name/@xlink:href = $vocabulary:PROCESS_PARAMETER || "AssessmentType"]
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

    (: Eb09 - OM observations shall contain several om:parameters to further define the model/objective estimation results
./om:parameter/om:NamedValue/om:name xlink:href attribute shall resolve to a traversable link to http://dd.eionet.europa.eu/vocabulary/aq/processparameter/ :)
    let $Eb09invalid :=
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

    (: Eb10 - . /om:observedProperty xlink:href attribute shall resolve to a traversable link to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/ :)
    let $Eb10invalid :=
        try {
            (let $all := dd:getValidConcepts("http://dd.eionet.europa.eu/vocabulary/aq/pollutant/rdf")
            for $x in $docRoot//om:OM_Observation/om:observedProperty
            let $namedValue := $x/../om:parameter/om:NamedValue[om:name/@xlink:href = $vocabulary:PROCESS_PARAMETER || "model"]
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

    (: Eb11 - The pollutant xlinked via /om:observedProperty must match the pollutant code declared via /aqd:AQD_Model/ef:observingCapability/ef:ObservingCapability/ef:observedProperty
      (See Eb6 on linkages between the Observations & the SamplingPoint) :)
    let $Eb11invalid :=
        try {
            (let $result := sparqlx:run(query:getModelMetadataFromFiles($latestEnvelopeD1b))
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
            let $namedValue := $x/om:parameter/om:NamedValue[om:name/@xlink:href = $vocabulary:PROCESS_PARAMETER || "model"]
            let $value := common:if-empty($namedValue/om:value, $namedValue/om:value/@xlink:href)
            where not($concat = $resultConcat)
            return
                <tr>
                    <td title="@gml:id">{$x/@gml:id/string()}</td>
                    <td title="om:value">{$value}</td>
                    <td title="om:observedProperty">{$observedProperty}</td>
                </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    (: Eb12 - All om:OM_Observation/ must provide a valid /om:featureOfInterest xlink (can not be empty)& 
     /om:featureOfInterest xlink:href attribute shall resolve to a traversable link to /aqd:AQD_modelArea/ompr:inspireld/base:Identifier/base:localId :)
    let $Eb12invalid :=
        try {
            (let $areas := data(sparqlx:run(query:getModelArea($latestEnvelopeD1b))/sparql:binding[@name = "localId"]/sparql:literal)
            for $x in $docRoot//om:OM_Observation
            let $featureOfInterest := $x/om:featureOfInterest/@xlink:href/tokenize(string(), "/")[last()]
            where ($featureOfInterest = "") or not($featureOfInterest = $areas)
            return
                <tr>
                    <td title="@gml:id">{$x/@gml:id/string()}</td>
                    <td title="om:featureOfInterest">{$featureOfInterest}</td>
                    <td title="om:observedProperty">{string($x/om:observedProperty/@xlink:href)}</td>
                </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    (: Eb13 - A valid delivery MUST provide an om:parameter/om:NamedValue/om:name xlink:href to http://dd.eionet.europa.eu/vocabulary/aq/processparameter/resultencoding &
    om:parameter/om:NamedValue/om:value xlink:href attribute shall resolve to  valid code for http://dd.eionet.europa.eu/vocabulary/aq/resultencoding/ :)
    let $Eb13invalid :=
        try {
            (let $valid := dd:getValidConcepts($vocabulary:RESULT_ENCODING || "rdf")
            for $x in $docRoot//om:OM_Observation
            let $node := $x/om:parameter/om:NamedValue[om:name/@xlink:href = $vocabulary:PROCESSPARAMETER_RESULTENCODING]
            let $value := common:if-empty($node/om:value, $node/om:value/@xlink:href)
            where $node => empty() or not($value = $valid)
            return
                <tr>
                    <td title="gml:id">{data($x/@gml:id)}</td>
                    <td title="Result encoding">{$value}</td>
                </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    (: Eb14 - A valid delivery MUST provide an om:parameter/om:NamedValue/om:name xlink:href to http://dd.eionet.europa.eu/vocabulary/aq/processparameter/resultformat &
    om:parameter/om:NamedValue/om:value xlink:href attribute attribute shall resolve to  valid code for http://dd.eionet.europa.eu/vocabulary/aq/resultformat/ :)
    let $Eb14invalid :=
        try {
            (let $valid := dd:getValidConcepts($vocabulary:RESULT_FORMAT || "rdf")
            for $x in $docRoot//om:OM_Observation
            let $node := $x/om:parameter/om:NamedValue[om:name/@xlink:href = $vocabulary:PROCESSPARAMETER_RESULTFORMAT]
            let $value := common:if-empty($node/om:value, $node/om:value/@xlink:href)
            where $node => empty() or not($value = $valid)
            return
                <tr>
                    <td title="gml:id">{data($x/@gml:id)}</td>
                    <td title="Result format">{$value}</td>
                </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    (: IF resultencoding = inline, resultformat can only be http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array
     IF resultencoding = external resultformat can only be http://dd.eionet.europa.eu/vocabulary/aq/resultformat/ascii-grid ,
       http://dd.eionet.europa.eu/vocabulary/aq/resultformat/esri-shp or http://dd.eionet.europa.eu/vocabulary/aq/resultformat/geotiff
    :)
    let $Eb14binvalid :=
        try {
            (let $ir := "http://dd.eionet.europa.eu/vocabulary/aq/resultencoding/inline"
            let $er := "http://dd.eionet.europa.eu/vocabulary/aq/resultencoding/external"
            let $validInline := ($ir || "http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array")
            let $validExternal := ($er || "http://dd.eionet.europa.eu/vocabulary/aq/resultformat/ascii-grid",
            $er || "http://dd.eionet.europa.eu/vocabulary/aq/resultformat/esri-shp", $er || "http://dd.eionet.europa.eu/vocabulary/aq/resultformat/geotiff")
            for $x in $docRoot//om:OM_Observation
            let $encoding := $x/om:parameter/om:NamedValue[om:name/@xlink:href = $vocabulary:PROCESSPARAMETER_RESULTENCODING]
            let $encoding := common:if-empty($encoding/om:value, $encoding/om:value/@xlink:href)
            let $format := $x/om:parameter/om:NamedValue[om:name/@xlink:href = $vocabulary:PROCESSPARAMETER_RESULTFORMAT]
            let $format := common:if-empty($format/om:value, $format/om:value/@xlink:href)
            let $combination := $encoding || $format
            let $condition :=
                if ($encoding = "http://dd.eionet.europa.eu/vocabulary/aq/resultencoding/inline") then
                    $combination = $validInline and exists($x/om:result/swe:DataArray)
                else if ($encoding = "http://dd.eionet.europa.eu/vocabulary/aq/resultencoding/external") then
                    $combination = $validExternal and exists($x/om:result/gml:File)
                else
                    false()
            where not($condition)
            return
                <tr>
                    <td title="gml:id">{data($x/@gml:id)}</td>
                    <td title="Result Encoding">{$encoding}</td>
                    <td title="Result Formatting">{$format}</td>
                </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    (: Eb15 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then ./om:result/swe:DataArray/swe:elementType/swe:DataRecord/swe:field name="startTime" attribute THEN
    swe:Time definition=http://www.opengis.net/def/property/OGC/0/SamplingTime swe:uom xlink:href=http://www.opengis.net/def/uom/ISO-8601/0/Gregorian:)
    (: TODO FIX :)
    let $Eb15invalid :=
        try {
            (for $x in $docRoot//om:OM_Observation/om:result[swe:DataArray]//swe:elementType/swe:DataRecord/swe:field[@name = "StartTime"
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

    (: Eb16 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then ./om:result/swe:DataArray/swe:elementType/swe:DataRecord/swe:field name="endTime" attribute THEN
    swe:Time definition=http://www.opengis.net/def/property/OGC/0/SamplingTime swe:uom xlink:href=http://www.opengis.net/def/uom/ISO-8601/0/Gregorian :)
    let $Eb16invalid :=
        try {
            (for $x in $docRoot//om:OM_Observation/om:result[swe:DataArray]//swe:elementType/swe:DataRecord/swe:field[@name = "EndTime"
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

    (: Eb17 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then ./om:result/swe:DataArray/swe:elementType/swe:DataRecord/swe:field name="validity" attribute THEN
     swe:Category definition is defined by http://dd.eionet.europa.eu/vocabulary/aq/observationvalidity:)
    let $Eb17invalid :=
        try {
            (for $x in $docRoot//om:OM_Observation/om:result[swe:DataArray]//swe:elementType/swe:DataRecord/swe:field[@name="Validity"
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
    (: Eb18 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then ./om:result/swe:DataArray/swe:elementType/swe:DataRecord/swe:field name="verification" attribute THEN
     swe:Category definition is defined by http://dd.eionet.europa.eu/vocabulary/aq/observationverification :)
    let $Eb18invalid :=
        try {
            (for $x in $docRoot//om:OM_Observation/om:result[swe:DataArray]//swe:elementType/swe:DataRecord/swe:field[@name = "Verification"
                    and not(swe:Category/@definition = $vocabulary:BASE || "observationverification")]
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
    (: Eb19 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then ./om:result/swe:DataArray/swe:elementType/swe:DataRecord/swe:field name="Value" attribute THEN swe:Quantity definition is defined by
    http://dd.eionet.europa.eu/vocabulary/aq/primaryObservation/[code] & the swe:uom resolves to an xlink to http://dd.eionet.europa.eu/vocabulary/uom/concentration/[code] :)
    let $Eb19invalid :=
        try {
            (let $obs := dd:getValidConceptsLC($vocabulary:OBSERVATIONS_PRIMARY || "rdf")
            let $cons := dd:getValidConceptsLC($vocabulary:UOM_CONCENTRATION_VOCABULARY || "rdf")
            for $x in $docRoot//om:OM_Observation/om:result[swe:DataArray]//swe:elementType/swe:DataRecord/swe:field[@name = "Value"
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

    (: Eb19b - Check if the unit of measure reporting via (swe:uom) corresponds to the recommended unit of measure in vocabulary
     http://dd.eionet.europa.eu/vocabulary/uom/concentration/[code] depending on pollutant reported via /om:observedProperty :)
    let $Eb19binvalid :=
        try {
            (for $x in $docRoot//om:OM_Observation/om:result[swe:DataArray]
            let $pollutant := string($x/../om:observedProperty/@xlink:href)
            let $value := string($x//swe:field[@name = 'Value']/swe:Quantity/swe:uom/@xlink:href)
            let $recommended := dd:getRecommendedUnit($pollutant)
            where not($value = $recommended)
            return
                <tr>
                    <td title="om:OM_Observation">{data($x/../@gml:id)}</td>
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

    (: Eb20 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then a fifth element might be included. IF ./om:result/swe:DataArray/swe:elementType/swe:DataRecord/swe:field name="DataCapture" attribute THEN swe:Category definition is defined by
     http://dd.eionet.europa.eu/vocabulary/aq/primaryObservation/dc & the swe:uom resolves to an xlink to http://dd.eionet.europa.eu/vocabulary/uom/statistics/percentage :)
    let $Eb20invalid :=
        try {
            (let $all := $docRoot//om:OM_Observation/om:result[swe:DataArray]//swe:elementType/swe:DataRecord/swe:field[@name="DataCapture"]
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

    (: Eb21 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then /om:result/swe:DataArray/swe:encoding/swe:TextEncoding shall resolve to decimalSeparator="." tokenSeparator="," blockSeparator="@@" :)
    let $Eb21invalid :=
        try {
            (for $x in $docRoot//om:OM_Observation/om:result[swe:DataArray]//swe:encoding/swe:TextEncoding[not(@decimalSeparator=".") or not(@tokenSeparator=",") or not(@blockSeparator="@@")]
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

    (: Eb22 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then the order of the fields within individual data blocks (swe:values) must correspond to the order described within the swe:DataRecord/swe:field(multiple). :)
    let $Eb22invalid :=
        try {
            (let $validVerifications := dd:getValidNotations($vocabulary:OBSERVATIONS_VERIFICATION || "rdf")
            let $validValidity:= dd:getValidNotations($vocabulary:OBSERVATIONS_VALIDITY || "rdf")
            let $exceptionDataCapture := ("-99", "-999")

            for $x at $xpos in $docRoot//om:OM_Observation/om:result[swe:DataArray]
            let $blockSeparator := string($x//swe:encoding/swe:TextEncoding/@blockSeparator)
            let $decimalSeparator := string($x//swe:encoding/swe:TextEncoding/@decimalSeparator)
            let $tokenSeparator := string($x//swe:encoding/swe:TextEncoding/@tokenSeparator)
            let $fields := data($x//swe:elementType/swe:DataRecord/swe:field/@name)

            for $i at $ipos in tokenize(replace($x//swe:values, $blockSeparator || "$", ""), $blockSeparator)
            for $z at $zpos in tokenize($i, $tokenSeparator)
            let $invalid :=
                if ($fields[$zpos] = ("StartTime", "EndTime")) then if ($z castable as xs:dateTime) then false() else true()
                else if ($fields[$zpos] = "Verification") then if ($z = $validVerifications) then false() else true()
                else if ($fields[$zpos] = "Validity") then if ($z = $validValidity) then false() else true()
                    else if ($fields[$zpos] = "Value") then if ($z = "" or $z castable as xs:double) then false() else true()
                        else if ($fields[$zpos] = "DataCapture") then if ($z = $exceptionDataCapture or ($z castable as xs:decimal and number($z) >= 0 and number($z) <= 100)) then false() else true()
                            else true()
            where $invalid = true()
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

    (: Eb23 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14)
     then the count of elements under <swe:elementCount><swe:Count><swe:value> should match the count of data blocks under <swe:values>. :)
    let $Eb23invalid :=
        try {
            (for $x at $xpos in $docRoot//om:OM_Observation/om:result[swe:DataArray]
            let $blockSeparator := string($x//swe:encoding/swe:TextEncoding/@blockSeparator)
            let $decimalSeparator := string($x//swe:encoding/swe:TextEncoding/@decimalSeparator)
            let $tokenSeparator := string($x//swe:encoding/swe:TextEncoding/@tokenSeparator)

            let $actual := count(tokenize(replace($x//swe:values, $blockSeparator || "$", ""), $blockSeparator))
            let $expected := number($x//swe:elementCount/swe:Count/swe:value)
            where not($actual = $expected)
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

    (: Eb24 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then difference between endTime & startTime must correspond to the definition under <swe:field name="Value"><swe:Quantity definition=> .Difference between endTime & startTime must correspond to the definition:
    http://dd.eionet.europa.eu/vocabulary/aq/primaryObservation/hour must be 1 h
    http://dd.eionet.europa.eu/vocabulary/aq/primaryObservation/day must be 24 hours
    http://dd.eionet.europa.eu/vocabulary/aq/primaryObservation/year must be 8760 hours or 8784
    http://dd.eionet.europa.eu/vocabulary/aq/primaryObservation/var can be anything :)
    let $Eb24invalid :=
        try {
            (for $x at $xpos in $docRoot//om:OM_Observation/om:result[swe:DataArray//swe:field[@name = "Value"]/swe:Quantity/contains(@definition, $vocabulary:OBSERVATIONS_PRIMARY) = true()]

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
                        if ($definition = $vocabulary:OBSERVATIONS_PRIMARY || "hour") then
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
                                    false()
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
    (: Eb25 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14)
     then the temporal envelopes of the swe:values (reported via starTime and EndTime) shall reconcile with ./om:phenomenonTime/gml:TimePeriod/gml:beginPosition :)
    let $Eb25invalid :=
        try {
            (for $x at $xpos in $docRoot//om:OM_Observation/om:result[swe:DataArray]
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
                    for $i at $ipos in tokenize(replace($x//swe:values, $blockSeparator || "$", ""), $blockSeparator)
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

    (: Eb26 :)
    (: TODO check if objective is needed as process parameter :)
    let $Eb26invalid :=
        try {
            (let $result := sparqlx:run(query:getModelMetadataFromFiles($latestEnvelopeD1b))
            let $resultsConcat :=
                for $x in $result
                return $x/sparql:binding[@name="localId"]/sparql:literal/string() || $x/sparql:binding[@name="procedure"]/sparql:uri/string() ||
                $x/sparql:binding[@name="featureOfInterest"]/sparql:uri/string() || $x/sparql:binding[@name="observedProperty"]/sparql:uri/string()

            for $x in $docRoot//om:OM_Observation
            let $namedValue := $x/om:parameter/om:NamedValue[om:name/@xlink:href = $vocabulary:PROCESS_PARAMETER || "model"]
            let $model := tokenize(common:if-empty($namedValue/om:value, $namedValue/om:value/@xlink:href), "/")[last()]
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
            let $concat := $model || $procedure || $featureOfInterest || $observedProperty
            where not($concat = $resultsConcat)
            return
                <tr>
                    <td title="om:OM_Observation">{string($x/@gml:id)}</td>
                    <td title="aqd:AQD_Model">{string($model)}</td>
                    <td title="aqd:AQD_ModelProcess">{$procedure}</td>
                    <td title="aqd:AQD_ModelArea">{$featureOfInterest}</td>
                    <td title="Pollutant">{$observedProperty}</td>
                </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
        }
        catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    (: Eb27 -  IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then check that all values (between @@) include as many fields as declared under swe:DataRecord :)
    let $Eb27invalid :=
        try {
            (for $x at $xpos in $docRoot//om:OM_Observation/om:result[swe:DataArray]
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

    (: Eb28 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then the data array should not end with "@@". Please note that @@ is a block separator. :)
    let $Eb28invalid :=
        try {
            (for $x at $xpos in $docRoot//om:OM_Observation/om:result[swe:DataArray]
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

    (: Eb29 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then check for unexpected spaces  around all values (between comma separator) under swe:values :)
    let $Eb29invalid :=
        try {
            (for $x at $xpos in $docRoot//om:OM_Observation/om:result[swe:DataArray]
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

    (: Eb31 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then check for date overlaps
     between consecutive data blocks within swe:values :)
    let $Eb31invalid :=
        try {
            (let $valid := dd:getValid($vocabulary:OBSERVATIONS_RANGE)

            for $x at $xpos in $docRoot//om:OM_Observation/om:result[swe:DataArray]
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
        }

    (: Eb32 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then check that all data submitted via CDR has been fully verified. The verification flag must be 1 for all data. :)
    let $Eb32invalid :=
        try {
            (for $x at $xpos in $docRoot//om:OM_Observation/om:result[swe:DataArray]

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

    (: Eb35 - IF resultformat is ascii-grid ;  esri-shp or geotiff (Eb14) then ./om:result/gml:File/gml:rangeParameters MUST be populated :)
    let $Eb35invalid :=
        try {
            (for $x in $docRoot//om:OM_Observation/om:result[gml:File]
                let $files := $x/gml:File/gml:rangeParameters
                where $files/* => empty()
                return
                <tr>
                    <td title="@gml:id">{string($x/../@gml:id)}</td>
                </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    (: Eb36 - IF resultformat is ascii-grid ;  esri-shp or geotiff (Eb14) then ./om:result/gml:File/gml:rangeParameters/swe:Quantity@Definition MUST match a code under
     http://dd.eionet.europa.eu/vocabulary/aq/aggregationprocess/ :)
    let $Eb36invalid :=
        try {
            (let $valid := dd:getValidConcepts($vocabulary:AGGREGATION_PROCESS || "rdf")
            for $x in $docRoot//om:OM_Observation/om:result[gml:File]
            let $definition := $x/gml:File/gml:rangeParameters/swe:Quantity/@definition/string()
            where not($definition = $valid)
            return
                <tr>
                    <td title="@gml:id">{string($x/../@gml:id)}</td>
                    <td title="Definition">{$definition}</td>
                </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    (: Eb37 - IF resultformat is ascii-grid ;  esri-shp or geotiff (Eb14) then ./om:result/gml:File/gml:rangeParameters/swe:label should be populated :)
    let $Eb37invalid :=
        try {
            (for $x in $docRoot//om:OM_Observation/om:result[gml:File]
            let $label:= $x/gml:File/gml:rangeParameters/swe:Quantity/swe:label
            where ($label => empty())
            return
                <tr>
                    <td title="@gml:id">{string($x/../@gml:id)}</td>
                </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    (: Eb38 - IF resultformat is ascii-grid ;  esri-shp or geotiff (Eb14) then ./om:result/gml:File/gml:rangeParameters/swe:description MUST be provided :)
    let $Eb38invalid :=
        try {
            (for $x in $docRoot//om:OM_Observation/om:result[gml:File]
            let $description:= $x/gml:File/gml:rangeParameters/swe:Quantity/swe:description
            where ($description => empty())
            return
                <tr>
                    <td title="@gml:id">{string($x/../@gml:id)}</td>
                </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    (: Eb39 - IF resultformat is ascii-grid ;  esri-shp or geotiff (Eb14) then ./om:result/gml:File/gml:rangeParameters/swe:uom xlink
     MUST match a code under http://dd.eionet.europa.eu/vocabulary/uom/concentration/ :)
    let $Eb39invalid :=
        try {
            (let $valid := (dd:getValidConcepts($vocabulary:UOM_CONCENTRATION_VOCABULARY || "rdf"), dd:getValidConcepts($vocabulary:UOM_STATISTICS || "rdf"))
            for $x in $docRoot//om:OM_Observation/om:result[gml:File]
            let $xlink := $x/gml:File/gml:rangeParameters/swe:Quantity/swe:uom/@xlink:href
            where not($xlink = $valid)
            return
                <tr>
                    <td title="@gml:id">{string($x/../@gml:id)}</td>
                    <td title="swe:uom">{$xlink => string()}</td>
                </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    (: Eb40 - Check if the unit of measure reporting via (/om:result/gml:File/gml:rangeParameters/swe:uom) corresponds to the recommended unit of measure in
    vocabulary http://dd.eionet.europa.eu/vocabulary/uom/concentration/[code] depending on pollutant reported via /om:observedProperty :)
    let $Eb40invalid :=
        try {
            (let $valid := dd:getValidConcepts($vocabulary:UOM_CONCENTRATION_VOCABULARY || "rdf")
            for $x in $docRoot//om:OM_Observation/om:result[gml:File]
            let $observedProperty := $x/om:observedProperty
            let $xlink := $x/gml:File/gml:rangeParameters/swe:Quantity/swe:uom/@xlink:href
            let $condition1 := not(contains($xlink, $vocabulary:UOM_STATISTICS))
            where $condition1 and not($xlink = $valid)
            return
                <tr>
                    <td title="@gml:id">{string($x/../@gml:id)}</td>
                    <td title="swe:uom">{$xlink => string()}</td>
                </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }
    (: Eb41 - IF resultformat is ascii-grid ;  esri-shp or geotiff (Eb14) then ./om:result/gml:File/gml:fileReference MUST be provided :)
    let $Eb41invalid :=
        try {
            (for $x in $docRoot//om:OM_Observation/om:result[gml:File]
            let $reference := $x/gml:File/gml:fileReference
            where $reference => empty()
            return
                <tr>
                    <td title="@gml:id">{string($x/../@gml:id)}</td>
                </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    (: Eb42 - ./om:result/gml:File/gml:fileReference MUST provide appropiate reference following this format:
        A valid cdr URL matching the cdr location where the XML files is located  (e.g. http://cdr.eionet.europa.eu/es/eu/aqd/e1b/.../)
        +
        File including extension (e.g. model.zip)
        +
        Variable using a # (e.g. #no2) :)
    let $Eb42invalid :=
        try {
            (let $regex := functx:escape-for-regex($cdrUrl || "e1b") || ".+\.[a-z]{3,3}#.*"
            for $x in $docRoot//om:OM_Observation/om:result[gml:File]
            let $reference := $x/gml:File/gml:fileReference
            where not(matches($reference, $regex))
            return
                <tr>
                    <td title="@gml:id">{string($x/../@gml:id)}</td>
                    <td title="gml:fileReference">{$reference => string()}</td>
                </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    return
        <table class="maintable hover">
            {html:build2("NS", $labels:NAMESPACES, $labels:NAMESPACES_SHORT, $NSinvalid, "All values are valid", "record", $errors:NS)}
            {html:build3("Eb0", $labels:Eb0, $labels:Eb0_SHORT, $Eb0table, data($Eb0table/td), errors:getMaxError($Eb0table))}
            {html:build1("Eb01", $labels:Eb01, $labels:Eb01_SHORT, $Eb01table, "", string(count($Eb01table)), "record", "", $errors:Eb01)}
            {html:build2("Eb02", $labels:Eb02, $labels:Eb02_SHORT, $Eb02invalid, "All records are valid", "record", $errors:Eb02)}
            {html:build2("Eb03", $labels:Eb03, $labels:Eb03_SHORT, $Eb03invalid, "All records are valid", "record", $errors:Eb03)}
            {html:build2("Eb04", $labels:Eb04, $labels:Eb04_SHORT, $Eb04invalid, "All records are valid", "record", $errors:Eb04)}
            {html:build2("Eb05", $labels:Eb05, $labels:Eb05_SHORT, $Eb05invalid, "All records are valid", "record", $errors:Eb05)}
            {html:build2("Eb06", $labels:Eb06, $labels:Eb06_SHORT, $Eb06invalid, "All records are valid", "record", $errors:Eb06)}
            {html:build2("Eb07", $labels:Eb07, $labels:Eb07_SHORT, $Eb07invalid, "All records are valid", "record", $errors:Eb07)}
            {html:build2("Eb08", $labels:Eb08, $labels:Eb08_SHORT, $Eb08invalid, "All records are valid", "record", $errors:Eb08)}
            {html:build2("Eb09", $labels:Eb09, $labels:Eb09_SHORT, $Eb09invalid, "All records are valid", "record", $errors:Eb09)}
            {html:build2("Eb10", $labels:Eb10, $labels:Eb10_SHORT, $Eb10invalid, "All records are valid", "record", $errors:Eb10)}
            {html:build2("Eb13", $labels:Eb13, $labels:Eb13_SHORT, $Eb13invalid, "All records are valid", "record", $errors:Eb13)}
            {html:build2("Eb14", $labels:Eb14, $labels:Eb14_SHORT, $Eb14invalid, "All records are valid", "record", $errors:Eb14)}
            {html:build2("Eb14b", $labels:Eb14b, $labels:Eb14b_SHORT, $Eb14binvalid, "All records are valid", "record", $errors:Eb14b)}
            {html:build2("Eb15", $labels:Eb15, $labels:Eb15_SHORT, $Eb15invalid, "All records are valid", "record", $errors:Eb15)}
            {html:build2("Eb16", $labels:Eb16, $labels:Eb16_SHORT, $Eb16invalid, "All records are valid", "record", $errors:Eb16)}
            {html:build2("Eb17", $labels:Eb17, $labels:Eb17_SHORT, $Eb17invalid, "All records are valid", "record", $errors:Eb17)}
            {html:build2("Eb18", $labels:Eb18, $labels:Eb18_SHORT, $Eb18invalid, "All records are valid", "record", $errors:Eb18)}
            {html:build2("Eb19", $labels:Eb19, $labels:Eb19_SHORT, $Eb19invalid, "All records are valid", "record", $errors:Eb19)}
            {html:build2("Eb19b", $labels:Eb19b, $labels:Eb19b_SHORT, $Eb19binvalid, "All records are valid", "record", $errors:Eb19b)}
            {html:build2("Eb20", $labels:Eb20, $labels:Eb20_SHORT, $Eb20invalid, "All records are valid", "record", $errors:Eb20)}
            {html:build2("Eb21", $labels:Eb21, $labels:Eb21_SHORT, $Eb21invalid, "All records are valid", "record", $errors:Eb21)}
            {html:build2("Eb22", $labels:Eb22, $labels:Eb22_SHORT, $Eb22invalid, "All records are valid", "record", $errors:Eb22)}
            {html:build2("Eb23", $labels:Eb23, $labels:Eb23_SHORT, $Eb23invalid, "All records are valid", "record", $errors:Eb23)}
            {html:build2("Eb24", $labels:Eb24, $labels:Eb24_SHORT, $Eb24invalid, "All records are valid", "record", $errors:Eb24)}
            {html:build2("Eb25", $labels:Eb25, $labels:Eb25_SHORT, $Eb25invalid, "All records are valid", "record", $errors:Eb25)}
            {html:build2("Eb26", $labels:Eb26, $labels:Eb26_SHORT, $Eb26invalid, "All records are valid", "record", $errors:Eb26)}
            {html:build2("Eb27", $labels:Eb27, $labels:Eb27_SHORT, $Eb27invalid, "All records are valid", "record", $errors:Eb27)}
            {html:build2("Eb28", $labels:Eb28, $labels:Eb28_SHORT, $Eb28invalid, "All records are valid", "record", $errors:Eb28)}
            {html:build2("Eb29", $labels:Eb29, $labels:Eb29_SHORT, $Eb29invalid, "All records are valid", "record", $errors:Eb29)}
            {html:build2("Eb31", $labels:Eb31, $labels:Eb31_SHORT, $Eb31invalid, "All records are valid", "record", $errors:Eb31)}
            {html:build2("Eb32", $labels:Eb32, $labels:Eb32_SHORT, $Eb32invalid, "All records are valid", "record", $errors:Eb32)}
            {html:build2("Eb35", $labels:Eb35, $labels:Eb35_SHORT, $Eb35invalid, "All records are valid", "record", $errors:Eb35)}
            {html:build2("Eb36", $labels:Eb36, $labels:Eb36_SHORT, $Eb36invalid, "All records are valid", "record", $errors:Eb36)}
            {html:build2("Eb37", $labels:Eb37, $labels:Eb37_SHORT, $Eb37invalid, "All records are valid", "record", $errors:Eb37)}
            {html:build2("Eb38", $labels:Eb38, $labels:Eb38_SHORT, $Eb38invalid, "All records are valid", "record", $errors:Eb38)}
            {html:build2("Eb39", $labels:Eb39, $labels:Eb39_SHORT, $Eb39invalid, "All records are valid", "record", $errors:Eb39)}
            {html:build2("Eb40", $labels:Eb40, $labels:Eb40_SHORT, $Eb40invalid, "All records are valid", "record", $errors:Eb40)}
            {html:build2("Eb41", $labels:Eb41, $labels:Eb41_SHORT, $Eb41invalid, "All records are valid", "record", $errors:Eb41)}
            {html:build2("Eb42", $labels:Eb42, $labels:Eb42_SHORT, $Eb42invalid, "All records are valid", "record", $errors:Eb42)}
        </table>

};


declare function dataflowEb:proceed($source_url as xs:string, $countryCode as xs:string) as element(div) {
    let $count := count(doc($source_url)//om:OM_Observation)
    let $result := if ($count > 0) then dataflowEb:checkReport($source_url, $countryCode) else ()
    let $meta := map:merge((
        map:entry("count", $count),
        map:entry("header", "Check air quality observations"),
        map:entry("dataflow", "Dataflow Eb"),
        map:entry("zeroCount", <p>No aqd:OM_Observation elements found in this XML.</p>),
        map:entry("report", <p>This check evaluated the delivery by executing tier-1 tests on air quality observation data in Dataflow E as specified in <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a>.</p>)
    ))
    return
        html:buildResultDiv($meta, $result)
};
