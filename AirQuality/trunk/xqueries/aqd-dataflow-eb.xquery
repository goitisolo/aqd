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
import module namespace checks = "aqd-checks" at "aqd-checks.xq";
(:import module namespace functx = "http://www.functx.com" at "aqd-functx.xq";:)
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

declare variable $dataflowEb:OBLIGATIONS as xs:string* := ($vocabulary:ROD_PREFIX || "674");
declare variable $dataflowEb:FEATURE_TYPES := ("aqd:AQD_Model", "aqd:AQD_ModelProcess", "aqd:AQD_ModelArea");

(: Rule implementations :)
declare function dataflowEb:checkReport($source_url as xs:string, $countryCode as xs:string) as element(table) {
    let $ms1Total := prof:current-ms()

    let $ms1GeneralParameters:= prof:current-ms()
    let $docRoot := doc($source_url)
    let $cdrUrl := common:getCdrUrl($countryCode)
    let $reportingYear := common:getReportingYear($docRoot)
    let $latestEnvelopeD1b := query:getLatestEnvelope($cdrUrl || "d1b/")
    let $latestEnvelopeByYearD1b := query:getLatestEnvelope($cdrUrl || "d1b/", $reportingYear)

    let $headerBeginPosition := $docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:beginPosition
    let $headerEndPosition := $docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:endPosition

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
    (: VOCAB check:)
    let $ms1VOCAB := prof:current-ms()

    let $VOCABinvalid := checks:vocab($docRoot)

    let $ms2VOCAB := prof:current-ms()

    (:VOCABALL check @goititer:)

let $ms1CVOCABALL := prof:current-ms()

(:let $VOCABALLinvalid := checks:vocaball($docRoot):)

let $ms2CVOCABALL := prof:current-ms()

    (: Eb0 - Check if delivery if this is a new delivery or updated delivery (via reporting year) :)

    let $ms1Eb0 := prof:current-ms()
    let $Eb0table :=
        try {
            if ($reportingYear = "") then
                <tr class="{$errors:ERROR}">
                    <td title="Status">Reporting Year is missing.</td>
                </tr>
            else if($headerBeginPosition > $headerEndPosition) then
                <tr class="{$errors:BLOCKER}">
                    <td title="Status">Start position must be less than end position</td>
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

    let $ms2Eb0 := prof:current-ms()
    
    (: Eb01 - Compile & feedback upon the total number of observations included in the delivery :)

    let $ms1Eb01 := prof:current-ms()
    
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

    let $ms2Eb01 := prof:current-ms()
    
    (:Eb02 ./om:phenomenonTime/gml:TimePeriod/gml:beginPosition shall be LESS THAN ./om:phenomenonTime/gml:TimePeriod/gml:endPosition. :)
    
    let $ms1Eb02 := prof:current-ms()
    
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

    let $ms2Eb02 := prof:current-ms()
    
    (:Eb03 - ./om:resultTime/gml:TimeInstant/gml:timePosition shall be GREATER THAN ./om:phenomenonTime/gml:TimePeriod/gml:endPosition :)  

    let $ms1Eb03 := prof:current-ms()
    
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

    let $ms2Eb03 := prof:current-ms()
    
    
    (: Eb04 -  All om:OM_Observation/ must provide a valid /om:procedure xlink (can not be empty) & ./om:procedure xlink:href attribute
     shall resolve to a traversable link process configuration in Data flow D1b: /aqd:AQD_ModelProcess/ompr:inspireld/base:Identifier/base:localId :)
    
    let $ms1Eb04 := prof:current-ms()
    
    let $Eb04invalid :=
        try {
            (let $result := sparqlx:run(query:getModelProcess($cdrUrl))
            let $all := $result/sparql:binding[@name = "inspireLabel"]/sparql:literal/string()
            let $procedures := $docRoot//om:procedure/@xlink:href/string()
            for $x in $procedures[not(. = $all)]
            return
                <tr>
                    <td title="base:localId">{$x}</td>
                    <td title="Sparql">{sparqlx:getLink(query:getModelProcess($cdrUrl))}</td>
                </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    let $ms2Eb04 := prof:current-ms()
    
    
    (: Eb05 A valid delivery MUST provide an om:parameter/om:NamedValue/om:name xlink:href to
    either http://dd.eionet.europa.eu/vocabulary/aq/processparameter/model or http://dd.eionet.europa.eu/vocabulary/aq/processparameter/objective :)
    
    let $ms1Eb05 := prof:current-ms()
    
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

    let $ms2Eb05 := prof:current-ms()
    
    
    (: Eb06 - If ./om:parameter/om:NamedValue/om:name xlink:href  resolves to http://dd.eionet.europa.eu/vocabulary/aq/processparameter/model or .../objective
/om:parameter/om:NamedValue/om:value xlink:href attribute shall resolve to a traversable link to a unique AQD_Model (“namespace/localId” of the object) :)
    
    let $ms1Eb06 := prof:current-ms()
    
    let $Eb06invalid :=
        try {
            (let $parameters := for $i in ("model", "objective") return $vocabulary:PROCESS_PARAMETER || $i
            (:let $result := sparqlx:run(query:getModelFromFiles($latestEnvelopeD1b)):)
            let $result := sparqlx:run(query:getModelSampling($cdrUrl))
            let $all := $result/sparql:binding[@name = "inspireLabel"]/sparql:literal/string()
            for $x in $docRoot//om:OM_Observation/om:parameter/om:NamedValue[om:name/@xlink:href = $parameters]
            let $name := $x/om:name/@xlink:href/string()
            let $value := common:if-empty($x/om:value, $x/om:value/@xlink:href)
            where ($value = "" or not($value = $all))
            return
                <tr>
                    <td title="om:OM_Observation">{string($x/../../@gml:id)}</td>
                    <td title="om:value">{$value}</td>
                    <td title="Sparql">{sparqlx:getLink(query:getModelSampling($cdrUrl))}</td>
                </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    let $ms2Eb06 := prof:current-ms()
    
    
    (: Eb07 - A valid delivery should provide  an om:parameter with om:name xlink:href to http://dd.eionet.europa.eu/vocabulary/aq/processparameter/AssessmentType :)
    
    let $ms1Eb07 := prof:current-ms()
    
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

    let $ms2Eb07 := prof:current-ms()
    
    
    (: Eb08 - If ./om:parameter/om:NamedValue/om:name links to http://dd.eionet.europa.eu/vocabulary/aq/processparameter/AssessmentType
     /om:parameter/om:NamedValue/om:value xlink:href attribute shall resolve to  valid code for http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/ :)
    
    let $ms1Eb08 := prof:current-ms()
    
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

    let $ms2Eb08 := prof:current-ms()
    
    
    (: Eb09 - OM observations shall contain several om:parameters to further define the model/objective estimation results
./om:parameter/om:NamedValue/om:name xlink:href attribute shall resolve to a traversable link to http://dd.eionet.europa.eu/vocabulary/aq/processparameter/ :)
    
    let $ms1Eb09 := prof:current-ms()
    
    let $Eb09invalid :=
        try {
            (let $valid := (dd:getValidConcepts($vocabulary:MODEL_PARAMETER || "rdf"), dd:getValidConcepts($vocabulary:PROCESS_PARAMETER || "rdf"))
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

    let $ms2Eb09 := prof:current-ms()
    
    (: Eb10 - . /om:observedProperty xlink:href attribute shall resolve to a traversable link to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/ :)
    
    let $ms1Eb10 := prof:current-ms()
    
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

    let $ms2Eb10 := prof:current-ms()
    
    (: Eb11 - The pollutant xlinked via /om:observedProperty must match the pollutant code declared via /aqd:AQD_Model/ef:observingCapability/ef:ObservingCapability/ef:observedProperty
      (See Eb6 on linkages between the Observations & the SamplingPoint) :)
    
    let $ms1Eb11 := prof:current-ms()
    
    let $Eb11invalid :=
        try {
            (let $result := sparqlx:run(query:getModelMetadataFromFiles($latestEnvelopeByYearD1b))
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
                    <td title="Sparql">{sparqlx:getLink(query:getModelMetadataFromFiles($latestEnvelopeByYearD1b))}</td>
                </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    let $ms2Eb11 := prof:current-ms()
    
    (: Eb12 - All om:OM_Observation/ must provide a valid /om:featureOfInterest xlink (can not be empty)& 
     /om:featureOfInterest xlink:href attribute shall resolve to a traversable link to /aqd:AQD_modelArea/ompr:inspireld/base:Identifier/base:localId :)
    
    let $ms1Eb12 := prof:current-ms()
    
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
                    <td title="Sparql">{sparqlx:getLink(query:getModelArea($latestEnvelopeD1b))}</td>
                </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    let $ms2Eb12 := prof:current-ms()
    
    (: Eb13 - A valid delivery MUST provide an om:parameter/om:NamedValue/om:name xlink:href to http://dd.eionet.europa.eu/vocabulary/aq/processparameter/resultencoding &
    om:parameter/om:NamedValue/om:value xlink:href attribute shall resolve to  valid code for http://dd.eionet.europa.eu/vocabulary/aq/resultencoding/ :)
    
    let $ms1Eb13 := prof:current-ms()
    
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

    let $ms2Eb13 := prof:current-ms()
    
    
    (: Eb14 - A valid delivery MUST provide an om:parameter/om:NamedValue/om:name xlink:href to http://dd.eionet.europa.eu/vocabulary/aq/processparameter/resultformat &
    om:parameter/om:NamedValue/om:value xlink:href attribute attribute shall resolve to  valid code for http://dd.eionet.europa.eu/vocabulary/aq/resultformat/ :)
    
    let $ms1Eb14 := prof:current-ms()
    
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


    
    let $ms2Eb14 := prof:current-ms()
    
    (: IF resultencoding = inline, resultformat can only be http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array
     IF resultencoding = external resultformat can only be http://dd.eionet.europa.eu/vocabulary/aq/resultformat/ascii-grid ,
       http://dd.eionet.europa.eu/vocabulary/aq/resultformat/esri-shp or http://dd.eionet.europa.eu/vocabulary/aq/resultformat/geotiff
    :)
    let $ms1Eb14b := prof:current-ms()
    
   let $Eb14func := function() {
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
                $combination = $validInline and exists($x/om:result[@xsi:type = "ns:DataArrayType" or swe:DataArray])
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
    }
    let $Eb14binvalid := errors:trycatch($Eb14func)

let $ms2Eb14b := prof:current-ms()
    
   

    (: Eb15 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then ./om:result/swe:DataArray/swe:elementType/swe:DataRecord/swe:field name="startTime" attribute THEN
    swe:Time definition=http://www.opengis.net/def/property/OGC/0/SamplingTime swe:uom xlink:href=http://www.opengis.net/def/uom/ISO-8601/0/Gregorian:)
    (: TODO FIX :)

    let $ms1Eb15 := prof:current-ms()
    
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

    let $ms2Eb15 := prof:current-ms()
    
    (: Eb16 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then ./om:result/swe:DataArray/swe:elementType/swe:DataRecord/swe:field name="endTime" attribute THEN
    swe:Time definition=http://www.opengis.net/def/property/OGC/0/SamplingTime swe:uom xlink:href=http://www.opengis.net/def/uom/ISO-8601/0/Gregorian :)
    
    let $ms1Eb16 := prof:current-ms()
    
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

    let $ms2Eb16 := prof:current-ms()
    
    (: Eb17 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then ./om:result/swe:DataArray/swe:elementType/swe:DataRecord/swe:field name="validity" attribute THEN
     swe:Category definition is defined by http://dd.eionet.europa.eu/vocabulary/aq/observationvalidity:)
    
    let $ms1Eb17 := prof:current-ms()
    
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
    
    let $ms2Eb17 := prof:current-ms()
    
    (: Eb18 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then ./om:result/swe:DataArray/swe:elementType/swe:DataRecord/swe:field name="verification" attribute THEN
     swe:Category definition is defined by http://dd.eionet.europa.eu/vocabulary/aq/observationverification :)
    
    let $ms1Eb18 := prof:current-ms()
    
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
    
    let $ms2Eb18 := prof:current-ms()
    
    (: Eb19 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then ./om:result/swe:DataArray/swe:elementType/swe:DataRecord/swe:field name="Value" attribute THEN swe:Quantity definition is defined by
    http://dd.eionet.europa.eu/vocabulary/aq/primaryObservation/[code] or http://dd.eionet.europa.eu/vocabulary/aq/aggregationprocess/[code] & the swe:uom resolves to an xlink to http://dd.eionet.europa.eu/vocabulary/uom/concentration/[code]:)
    
    let $ms1Eb19 := prof:current-ms()
    
    let $Eb19invalid :=
        try {
            (let $defs := (dd:getValidConceptsLC($vocabulary:OBSERVATIONS_PRIMARY || "rdf"), dd:getValidConceptsLC($vocabulary:AGGREGATION_PROCESS || "rdf"))
            let $concepts := (dd:getValidConceptsLC($vocabulary:UOM_CONCENTRATION_VOCABULARY || "rdf"), dd:getValidConceptsLC($vocabulary:UOM_STATISTICS || "rdf"))
            for $x in $docRoot//om:OM_Observation/om:result[swe:DataArray]//swe:elementType/swe:DataRecord/swe:field[@name = "Value"
                    and (not(swe:Quantity/lower-case(@definition) = $defs) or not(swe:Quantity/swe:uom/lower-case(@xlink:href) = $concepts))]
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

    
    let $ms2Eb19 := prof:current-ms()
    
    (: Eb19b - Check if the unit of measure reporting via (swe:uom) corresponds to the recommended unit of measure in vocabulary
     http://dd.eionet.europa.eu/vocabulary/uom/concentration/[code] depending on pollutant reported via /om:observedProperty :)
    
    let $ms1Eb19b := prof:current-ms()
    
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

    let $ms2Eb19b := prof:current-ms()
    
    (: Eb20 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then a fifth element might be included. IF ./om:result/swe:DataArray/swe:elementType/swe:DataRecord/swe:field name="DataCapture" attribute THEN swe:Category definition is defined by
     http://dd.eionet.europa.eu/vocabulary/aq/primaryObservation/dc & the swe:uom resolves to an xlink to http://dd.eionet.europa.eu/vocabulary/uom/statistics/percentage :)
    
    let $ms1Eb20 := prof:current-ms()
    
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

    
    let $ms2Eb20 := prof:current-ms()
    
    (: Eb21 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then /om:result/swe:DataArray/swe:encoding/swe:TextEncoding shall resolve to decimalSeparator="." tokenSeparator="," blockSeparator="@@" :)
    
    let $ms1Eb21 := prof:current-ms()
    
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

    
    let $ms2Eb21 := prof:current-ms()
    
    (: Eb22 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then the order of the fields within individual data blocks (swe:values) must correspond to the order described within the swe:DataRecord/swe:field(multiple). :)
    
    let $ms1Eb22 := prof:current-ms()
    
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
                    else if ($fields[$zpos] = "Value") then if ($z = "" or translate($z, "<>=", "") castable as xs:double) then false() else true()
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

    let $ms2Eb22 := prof:current-ms()
    
    (: Eb23 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14)
     then the count of elements under <swe:elementCount><swe:Count><swe:value> should match the count of data blocks under <swe:values>. :)
    
    let $ms1Eb23 := prof:current-ms()
    
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

    let $ms2Eb23 := prof:current-ms()
    
    (: Eb24 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then difference between endTime & startTime must correspond to the definition under <swe:field name="Value"><swe:Quantity definition=> .Difference between endTime & startTime must correspond to the definition:
    http://dd.eionet.europa.eu/vocabulary/aq/primaryObservation/hour must be 1 h
    http://dd.eionet.europa.eu/vocabulary/aq/primaryObservation/day must be 24 hours
    http://dd.eionet.europa.eu/vocabulary/aq/primaryObservation/year must be 8760 hours or 8784
    http://dd.eionet.europa.eu/vocabulary/aq/primaryObservation/var can be anything :)
    
    let $ms1Eb24 := prof:current-ms()
    
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
    
    let $ms2Eb24 := prof:current-ms()
    
    (: Eb25 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14)
     then the temporal envelopes of the swe:values (reported via starTime and EndTime) shall reconcile with ./om:phenomenonTime/gml:TimePeriod/gml:beginPosition :)
    
    let $ms1Eb25 := prof:current-ms()
    
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

    
    let $ms2Eb25 := prof:current-ms()
    
    (: Eb26 :)
    
    let $ms1Eb26 := prof:current-ms()
    
    let $Eb26invalid :=
        try {
            (let $result := sparqlx:run(query:getModelMetadataSampling($cdrUrl))
            let $resultsConcat :=
                for $x in $result
                return $x/sparql:binding[@name="localId"]/sparql:literal/string() || $x/sparql:binding[@name="procedure"]/sparql:uri/string() ||
                $x/sparql:binding[@name="featureOfInterest"]/sparql:uri/string() || $x/sparql:binding[@name="observedProperty"]/sparql:uri/string()

            for $x in $docRoot//om:OM_Observation
            let $namedValue := $x/om:parameter/om:NamedValue[om:name/@xlink:href = ($vocabulary:PROCESS_PARAMETER || "model", $vocabulary:PROCESS_PARAMETER || "objective")]
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
                    <td title="Sparql">{sparqlx:getLink(query:getModelMetadataSampling($cdrUrl))}</td>
                </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
        }
        catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    
    let $ms2Eb26 := prof:current-ms()
    
    (: Eb27 -  IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then check that all values (between @@) include as many fields as declared under swe:DataRecord :)
    
    let $ms1Eb27 := prof:current-ms()
    
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

    
    let $ms2Eb27 := prof:current-ms()
    
    (: Eb28 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then the data array should not end with "@@". Please note that @@ is a block separator. :)
    
    let $ms1Eb28 := prof:current-ms()
    
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

    
    let $ms2Eb28 := prof:current-ms()
    
    (: Eb29 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then check for unexpected spaces  around all values (between comma separator) under swe:values :)
    
    let $ms1Eb29 := prof:current-ms()
    
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

    
    let $ms2Eb29 := prof:current-ms()
    
    (: Eb31 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then check for date overlaps
     between consecutive data blocks within swe:values :)
    
    let $ms1Eb31 := prof:current-ms()
    
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

    
    let $ms2Eb31 := prof:current-ms()
    
    (: Eb32 - IF resultformat is http://dd.eionet.europa.eu/vocabulary/aq/resultformat/swe-array (Eb14) then check that all data submitted via CDR has been fully verified. The verification flag must be 1 for all data. :)
    
    let $ms1Eb32 := prof:current-ms()
    
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

    
    let $ms2Eb32 := prof:current-ms()
    
    (: Eb35 - IF resultformat is ascii-grid ;  esri-shp or geotiff (Eb14) then ./om:result/gml:File/gml:rangeParameters MUST be populated :)
    
    let $ms1Eb35 := prof:current-ms()
    
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

    
    let $ms2Eb35 := prof:current-ms()
    
    (: Eb36 - IF resultformat is ascii-grid ;  esri-shp or geotiff (Eb14) then ./om:result/gml:File/gml:rangeParameters/swe:Quantity@Definition MUST match a code under
     http://dd.eionet.europa.eu/vocabulary/aq/aggregationprocess/ :)
    
    let $ms1Eb36 := prof:current-ms()
    
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

    
    let $ms2Eb36 := prof:current-ms()
    
    (: Eb37 - IF resultformat is ascii-grid ;  esri-shp or geotiff (Eb14) then ./om:result/gml:File/gml:rangeParameters/swe:label should be populated :)
    
    let $ms1Eb37 := prof:current-ms()
    
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

    
    let $ms2Eb37 := prof:current-ms()
    
    (: Eb38 - IF resultformat is ascii-grid ;  esri-shp or geotiff (Eb14) then ./om:result/gml:File/gml:rangeParameters/swe:description MUST be provided :)
    
    let $ms1Eb38 := prof:current-ms()
    
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

    
    let $ms2Eb38 := prof:current-ms()
    
    (: Eb39 - IF resultformat is ascii-grid ;  esri-shp or geotiff (Eb14) then ./om:result/gml:File/gml:rangeParameters/swe:uom xlink
     MUST match a code under http://dd.eionet.europa.eu/vocabulary/uom/concentration/ :)
    
    let $ms1Eb39 := prof:current-ms()
    
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

    
    let $ms2Eb39 := prof:current-ms()
    
    (: Eb40 - Check if the unit of measure reporting via (/om:result/gml:File/gml:rangeParameters/swe:uom) corresponds to the recommended unit of measure in
    vocabulary http://dd.eionet.europa.eu/vocabulary/uom/concentration/[code] depending on pollutant reported via /om:observedProperty :)
    
    let $ms1Eb40 := prof:current-ms()
    
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
    
    let $ms2Eb40 := prof:current-ms()
    
    (: Eb41 - IF resultformat is ascii-grid ;  esri-shp or geotiff (Eb14) then ./om:result/gml:File/gml:fileReference MUST be provided :)
    
    let $ms1Eb41 := prof:current-ms()
    
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

    
    let $ms2Eb41 := prof:current-ms()
    
    (: Eb42 - ./om:result/gml:File/gml:fileReference MUST provide appropiate reference following this format:
        A valid cdr URL matching the cdr location where the XML files is located  (e.g. http://cdr.eionet.europa.eu/es/eu/aqd/e1b/.../)
        +
        File including extension (e.g. model.zip)
        +
        Variable using a # (e.g. #no2) :)
    
    let $ms1Eb42 := prof:current-ms()
    
    let $Eb42invalid :=    
        try {
          (        
            let $processParameterModel := $vocabulary:PROCESS_PARAMETER || "model"
            
            let $envelopeUrl := common:getCleanUrl($source_url)
            let $xmlName := tokenize($envelopeUrl , "/")[last()]
            let $currentEnvelope := substring-before($envelopeUrl, $xmlName)
            let $envelopexml := substring-before($envelopeUrl, $xmlName) || "xml"
            let $docEnvelopexml := doc($envelopexml)
            
            let $regex := functx:escape-for-regex($currentEnvelope) || ".+\.[a-z]{3,3}#.+"
            
            for $x in $docRoot//om:OM_Observation/om:result[gml:File]
              let $reference := $x/gml:File/gml:fileReference
              let $referenceHTTPS := replace($reference, "http://", "https://")
              let $referenceHTTP := replace($reference, "https://", "http://")
              let $okAllowedFileReference := ( if( contains($reference, ".zip") or contains($reference, ".shp") or contains($reference, ".tiff") or contains($reference, ".asc") ) then true()
                                              else false() )
              
              let $model := $x/../om:parameter/om:NamedValue[om:name/@xlink:href = $processParameterModel]
              let $modelValueLink := common:if-empty($model/om:value, $model/om:value/@xlink:href)
              
              (: start comparing envelope/xml file @link with the xml <gml:fileReference> :)
              let $comparingEnvelopexmlAndxml := ( 
                  for $y in $docEnvelopexml/envelope/file/@link
                    let $comparingEnvelopexmlAndxml := if ( contains($y, substring-before($reference, "#")) = false() and contains($y, substring-before($referenceHTTPS, "#")) = false() and contains($y, substring-before($referenceHTTP, "#")) = false() ) 
                                  then false()
                                  else true()        
                    return $comparingEnvelopexmlAndxml
              )
              let $countingComparingEnvelopexmlAndxml := if(count(index-of($comparingEnvelopexmlAndxml, true())) = 0) then false() else true()
             (: end comparing envelope/xml file @link with the xml <gml:fileReference> :)
              
              let $ok := ( $okAllowedFileReference = true() and ( matches($reference, $regex) or matches($referenceHTTPS, $regex) or matches($referenceHTTP, $regex) ) and $countingComparingEnvelopexmlAndxml = true() )
              
              where not($ok)
              return
                  <tr>
                      <td title="@gml:id">{string($x/../@gml:id)}</td>
                      <td title="model local id">{$modelValueLink}</td>
                      <td title="gml:fileReference">{$reference => string()}</td>
                  </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }
    
    let $ms2Eb42 := prof:current-ms()
    
    
    (: Eb43 - When results are provided via an external file and the external file is ESRI shapefile, it must include the *.prj file
      IF resultencoding = external resultformat, AND resultformat = esri-shp, THEN the external results provided must include the correct projection file.

      [Example: if results provided via gml:fileReference (http://cdr.eionet.europa.eu/es/eu/aqd/e1b/envxta1qq/ES_CIEMAT_O3_V_TV_AOT40c-5yr_2018.shp), 
      the  same envelope must include file ES_CIEMAT_O3_V_TV_AOT40c-5yr_2018.prj] :)
    
    let $ms1Eb43 := prof:current-ms()
    
    let $Eb43invalid :=
         try {
          let $processParameterResultencoding := $vocabulary:PROCESS_PARAMETER || "resultencoding"
          let $processParameterResultformat := $vocabulary:PROCESS_PARAMETER || "resultformat"
          let $processParameterModel := $vocabulary:PROCESS_PARAMETER || "model"
          
          (:let $xmlName := tokenize($source_url , "/")[last()]
          let $envelopexml := substring-before($source_url, $xmlName) || "xml"
          let $docEnvelopexml := doc($envelopexml):)
          let $envelopeUrl := common:getCleanUrl($source_url)
          let $xmlName := tokenize($envelopeUrl , "/")[last()]
          let $envelopexml := substring-before($envelopeUrl, $xmlName) || "xml"
          let $docEnvelopexml := doc($envelopexml)
          
          for $x in $docRoot//om:OM_Observation
            let $fileReference := $x/om:result/gml:File/gml:fileReference
            
            let $fileReferenceWithoutFormat := 
              (if (contains($fileReference, ".shp") = true() ) then 
                substring-before($fileReference, ".shp"))
          
            let $prjLink := 
              ( 
                let $fileReferenceWithoutFormatHTTPS := replace($fileReferenceWithoutFormat, "http://", "https://")
                let $fileReferenceWithoutFormatHTTP := replace($fileReferenceWithoutFormat, "https://", "http://")
                
                for $y in $docEnvelopexml/envelope/file
                  where(contains($y/@link, $fileReferenceWithoutFormat || ".prj") = true() or contains($y/@link, $fileReferenceWithoutFormatHTTPS || ".prj") = true() or contains($y/@link, $fileReferenceWithoutFormatHTTP || ".prj") = true() ) 
                  return data($y/@link)
              )
            
            let $resultEncoding := $x/om:parameter/om:NamedValue[om:name/@xlink:href = $processParameterResultencoding]
            let $resultencodingValue := tokenize(common:if-empty($resultEncoding/om:value, $resultEncoding/om:value/@xlink:href), "/")[last()]
            
            let $resultFormat := $x/om:parameter/om:NamedValue[om:name/@xlink:href = $processParameterResultformat]
            let $resultformatValue := tokenize(common:if-empty($resultFormat/om:value, $resultFormat/om:value/@xlink:href), "/")[last()]
            
            let $model := $x/om:parameter/om:NamedValue[om:name/@xlink:href = $processParameterModel]
            let $modelValueLink := common:if-empty($model/om:value, $model/om:value/@xlink:href)
            
            let $ok := ($fileReference and $fileReference != "" and $resultencodingValue = "external" and $resultformatValue != "" and $resultformatValue = "esri-shp" and $prjLink != "")
            
            (: if the files are inside a zip: :)
            let $fileReferenceWithoutFormatZip := 
              (if (contains($fileReference, ".zip") = true() ) then 
                substring-before($fileReference, ".zip"))
                
            let $zipContentUrl :=  
              ( 
                let $fileReferenceWithoutFormatHTTPS := replace($fileReferenceWithoutFormatZip, "http://", "https://")
                let $fileReferenceWithoutFormatHTTP := replace($fileReferenceWithoutFormatZip, "https://", "http://")
                
                for $y in $docEnvelopexml/envelope/file
                  where( $y/@type="application/zip" and (contains($y/@link, $fileReferenceWithoutFormatZip) = true() or contains($y/@link, $fileReferenceWithoutFormatHTTPS) = true() or contains($y/@link, $fileReferenceWithoutFormatHTTP) = true() ) )
                  let $zipLink := data($y/@link)
                  let $eionet := if (contains($zipLink, "https://cdrtest.eionet.europa.eu/"))
                                 then "https://cdrtest.eionet.europa.eu/"
                                 else if (contains($zipLink, "http://cdrtest.eionet.europa.eu/"))
                                      then "http://cdrtest.eionet.europa.eu/"
                                      else if (contains($zipLink, "https://cdr.eionet.europa.eu/"))
                                           then "https://cdr.eionet.europa.eu/"
                                           else if (contains($zipLink, "http://cdr.eionet.europa.eu/"))
                                                then "http://cdr.eionet.europa.eu/"
                  
                  let $envelopeAndZipName := substring-after($zipLink, $eionet)
                  
                  let $zipContentUrl := $eionet || "Converters/run_conversion?file=" || $envelopeAndZipName || "&amp;conv=ziplist&amp;source=local"
                  
                  (: using http:request and http:send-request in order to access to the content of the ZIP files :)
                  let $request := <http:request href="{$zipContentUrl}" method="GET"/> 
                  let $response := http:send-request($request)[2] 
                  let $html2xml := $response
                  
                  let $prjInZip := (
                    if ( contains($html2xml, ".prj") ) then true()
                    else false()
                  )
                  let $ok2 := ( 
                    if($ok = true() ) then true()
                    else
                      $prjInZip
                  )
                  
                  return 
                    <result>
                      <zipContentUrl>{$zipContentUrl}</zipContentUrl>
                      <html2xml>{$html2xml}</html2xml>
                      <prjInZip>{$prjInZip}</prjInZip>
                      <ok2>{$ok2}</ok2>
                    </result>
              )
            
            (: start comparing envelope/xml file @link wih the xml <gml:fileReference> :)
            let $comparingEnvelopexmlAndxml := ( 
                let $fileReferenceWithoutFormatHTTPS := replace($fileReferenceWithoutFormatZip, "http://", "https://")
                let $fileReferenceWithoutFormatHTTP := replace($fileReferenceWithoutFormatZip, "https://", "http://")
                
                for $y in $docEnvelopexml/envelope/file[@type="application/zip"]/@link
                  let $comparingEnvelopexmlAndxml := if ( contains(substring-before($y, ".zip"), $fileReferenceWithoutFormatZip) = false() and contains(substring-before($y, ".zip"), $fileReferenceWithoutFormatHTTPS) = false() and contains(substring-before($y, ".zip"), $fileReferenceWithoutFormatHTTP) = false() ) 
                                then false()
                                else true()        
                  return $comparingEnvelopexmlAndxml
              )
              let $countingComparingEnvelopexmlAndxml := if(count(index-of($comparingEnvelopexmlAndxml, true())) = 0) then false() else true()  
             (: end comparing envelope/xml file @link wih the xml <gml:fileReference> :)
            
            where ( ($zipContentUrl/ok2 = false() and $resultencodingValue = "external" ) or (($ok = false() and $resultencodingValue = "external" and $resultformatValue = "esri-shp" and $countingComparingEnvelopexmlAndxml = false() )))
            return
                <tr>
                    <td title="gml:id">{data($x/@gml:id)}</td>
                    <td title="model local id">{$modelValueLink}</td>
                    <td title="gml:fileReference">{$fileReference}</td>
                    <td title="resultencoding">{$resultencodingValue}</td>
                    <td title="resultformat">{$resultformatValue}</td>
                    <td title="*.prj file">{$prjLink}</td>
                </tr>
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    let $ms2Eb43 := prof:current-ms()
    
    
    (: Eb44 - When results are provided via an external file, the XML must include an om:parameter including the modelprojection via EEA vocabulary
            IF resultencoding = external resultformat, the XML must include an om:parameter with modelprojection
            <om:parameter>
            <om:NamedValue>
            <om:name xlink:href="http://dd.eionet.europa.eu/vocabulary/aq/modelparameter/projection"/>
            <om:value xlink:href="http://dd.eionet.europa.eu/vocabulary/common/epsg/4326"/>
            </om:NamedValue>
            </om:parameter> :)
    
    let $ms1Eb44 := prof:current-ms()
    
    let $Eb44invalid :=
         try {
          let $processParameterResultencoding := $vocabulary:PROCESS_PARAMETER || "resultencoding"
          let $processParameterResultformat := $vocabulary:PROCESS_PARAMETER || "resultformat"
          let $modelParameterProjection := $vocabulary:MODEL_PARAMETER || "projection"
          let $processParameterModel := $vocabulary:PROCESS_PARAMETER || "model"
          
          for $x in $docRoot//om:OM_Observation
            let $resultEncoding := $x/om:parameter/om:NamedValue[om:name/@xlink:href = $processParameterResultencoding]
            let $resultencodingValue := tokenize(common:if-empty($resultEncoding/om:value, $resultEncoding/om:value/@xlink:href), "/")[last()]
            
            let $resultFormat := $x/om:parameter/om:NamedValue[om:name/@xlink:href = $processParameterResultformat]
            let $resultformatValue := tokenize(common:if-empty($resultFormat/om:value, $resultFormat/om:value/@xlink:href), "/")[last()]
            
            let $modelProjection := $x/om:parameter/om:NamedValue[om:name/@xlink:href = $modelParameterProjection]
            let $modelProjectionValue := tokenize(common:if-empty($modelProjection/om:value, $modelProjection/om:value/@xlink:href), "/")[last()]
            
            let $model := $x/om:parameter/om:NamedValue[om:name/@xlink:href = $processParameterModel]
            let $modelValueLink := common:if-empty($model/om:value, $model/om:value/@xlink:href)
            
            let $fileReference := $x/om:result/gml:File/gml:fileReference
            
            let $errorType := 
              if($resultencodingValue = "external" and $resultformatValue = "esri-shp") then "Warning" 
              else if($resultencodingValue = "external" and $resultformatValue != "esri-shp") then functx:capitalize-first($errors:Eb44)
            
            let $ok := ($resultencodingValue = "external" and $resultformatValue != "" and $modelProjectionValue != "")
            
            where not($ok) and $resultencodingValue = "external"
            return
                <tr>
                    <td title="gml:id">{data($x/@gml:id)}</td>
                    <td title="model local id">{$modelValueLink}</td>
                    <td title="projection">{$modelProjectionValue}</td>
                    <td title="resultencoding">{$resultencodingValue}</td>
                    <td title="resultformat">{$resultformatValue}</td>
                    <td title="gml:fileReference">{$fileReference}</td>
                    <td title="error type">{$errorType}</td>
                </tr>
        } catch * {
            <tr class="{$errors:FAILED}">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    let $Eb44ErrorTypeWorkflow := 
          let $processParameterResultencoding := $vocabulary:PROCESS_PARAMETER || "resultencoding"
          let $processParameterResultformat := $vocabulary:PROCESS_PARAMETER || "resultformat"
          
          for $x in $docRoot//om:OM_Observation
            let $resultEncoding := $x/om:parameter/om:NamedValue[om:name/@xlink:href = $processParameterResultencoding]
            let $resultencodingValue := tokenize(common:if-empty($resultEncoding/om:value, $resultEncoding/om:value/@xlink:href), "/")[last()]
            
            let $resultFormat := $x/om:parameter/om:NamedValue[om:name/@xlink:href = $processParameterResultformat]
            let $resultformatValue := tokenize(common:if-empty($resultFormat/om:value, $resultFormat/om:value/@xlink:href), "/")[last()]

            return  
              if($resultencodingValue = "external" and $resultformatValue = "esri-shp") then $errors:WARNING
              else 
                if($resultencodingValue = "external" and $resultformatValue != "esri-shp") then $errors:Eb44
    
    let $Eb44maxErrorLevel := (if ($Eb44ErrorTypeWorkflow = $errors:Eb44)
                            then( $errors:Eb44 )
                            else(if ($Eb44ErrorTypeWorkflow = $errors:WARNING)
                                then( $errors:WARNING )
                                else( $errors:INFO )
                                )
                        )
    
    let $ms2Eb44 := prof:current-ms()
    
    
    let $ms2Total := prof:current-ms()
    return
        <table class="maintable hover">
        <table>
            {html:build2("NS", $labels:NAMESPACES, $labels:NAMESPACES_SHORT, $NSinvalid, "All values are valid", "record", $errors:NS)}
            {html:build2("VOCAB", $labels:VOCAB, $labels:VOCAB_SHORT, $VOCABinvalid, "All values are valid", "record", $errors:VOCAB)}
            <!--{html:buildNoCount2Sparql("VOCABALL", $labels:VOCABALL, $labels:VOCABALL_SHORT, $VOCABALLinvalid, "All values are valid", "Invalid urls found", $errors:VOCABALL)}-->
            {html:build3("Eb0", $labels:Eb0, $labels:Eb0_SHORT, $Eb0table, data($Eb0table/td), errors:getMaxError($Eb0table))}
            {html:build1("Eb01", $labels:Eb01, $labels:Eb01_SHORT, $Eb01table, "", string(count($Eb01table)), "record", "", $errors:Eb01)}
            {html:build2("Eb02", $labels:Eb02, $labels:Eb02_SHORT, $Eb02invalid, "All records are valid", "record", $errors:Eb02)}
            {html:build2("Eb03", $labels:Eb03, $labels:Eb03_SHORT, $Eb03invalid, "All records are valid", "record", $errors:Eb03)}
            {html:build2Sparql("Eb04", $labels:Eb04, $labels:Eb04_SHORT, $Eb04invalid, "All records are valid", "record", $errors:Eb04)}
            {html:build2("Eb05", $labels:Eb05, $labels:Eb05_SHORT, $Eb05invalid, "All records are valid", "record", $errors:Eb05)}
            {html:build2Sparql("Eb06", $labels:Eb06, $labels:Eb06_SHORT, $Eb06invalid, "All records are valid", "record", $errors:Eb06)}
            {html:build2("Eb07", $labels:Eb07, $labels:Eb07_SHORT, $Eb07invalid, "All records are valid", "record", $errors:Eb07)}
            {html:build2("Eb08", $labels:Eb08, $labels:Eb08_SHORT, $Eb08invalid, "All records are valid", "record", $errors:Eb08)}
            {html:build2("Eb09", $labels:Eb09, $labels:Eb09_SHORT, $Eb09invalid, "All records are valid", "record", $errors:Eb09)}
            {html:build2("Eb10", $labels:Eb10, $labels:Eb10_SHORT, $Eb10invalid, "All records are valid", "record", $errors:Eb10)}
            {html:build2Sparql("Eb11", $labels:Eb11, $labels:Eb11_SHORT, $Eb11invalid, "All records are valid", "record", $errors:Eb11)}
            {html:build2Sparql("Eb12", $labels:Eb12, $labels:Eb12_SHORT, $Eb12invalid, "All records are valid", "record", $errors:Eb12)}
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
            {html:build2Sparql("Eb26", $labels:Eb26, $labels:Eb26_SHORT, $Eb26invalid, "All records are valid", "record", $errors:Eb26)}
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
            {html:build2("Eb43", $labels:Eb43, $labels:Eb43_SHORT, $Eb43invalid, "All records are valid", "record", $errors:Eb43)}
            {html:build2("Eb44", $labels:Eb44, $labels:Eb44_SHORT, $Eb44invalid, "All records are valid", "record", $Eb44maxErrorLevel)}
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
       <!--{common:runtime("VOCABALL", $ms1CVOCABALL, $ms2CVOCABALL)}-->
       {common:runtime("Eb0",  $ms1Eb0, $ms2Eb0)}
       {common:runtime("Eb01", $ms1Eb01, $ms2Eb01)}
       {common:runtime("Eb02", $ms1Eb02, $ms2Eb02)}
       {common:runtime("Eb03", $ms1Eb03, $ms2Eb03)}
       {common:runtime("Eb04",  $ms1Eb04, $ms2Eb04)}
       {common:runtime("Eb05", $ms1Eb05, $ms2Eb05)}
       {common:runtime("Eb06",  $ms1Eb06, $ms2Eb06)}
       {common:runtime("Eb07",  $ms1Eb07, $ms2Eb07)}
       {common:runtime("Eb08",  $ms1Eb08, $ms2Eb08)}
       {common:runtime("Eb09",  $ms1Eb09, $ms2Eb09)}
       {common:runtime("Eb10",  $ms1Eb10, $ms2Eb10)}
       {common:runtime("Eb11",  $ms1Eb11, $ms2Eb11)}
       {common:runtime("Eb12",  $ms1Eb12, $ms2Eb12)}
       {common:runtime("Eb13",  $ms1Eb13, $ms2Eb13)}
       {common:runtime("Eb14",  $ms1Eb14, $ms2Eb14)}
       {common:runtime("Eb14b",  $ms1Eb14b, $ms2Eb14b)}
       {common:runtime("Eb15",  $ms1Eb15, $ms2Eb15)}
       {common:runtime("Eb16",  $ms1Eb16, $ms2Eb16)}
       {common:runtime("Eb17",  $ms1Eb17, $ms2Eb17)}
       {common:runtime("Eb18",  $ms1Eb18, $ms2Eb18)}
       {common:runtime("Eb19",  $ms1Eb19, $ms2Eb19)}
       {common:runtime("Eb19b",  $ms1Eb19b, $ms2Eb19b)}
       {common:runtime("Eb20", $ms1Eb20, $ms2Eb20)}
       {common:runtime("Eb21",  $ms1Eb21, $ms2Eb21)}
       {common:runtime("Eb22",  $ms1Eb22, $ms2Eb22)}
       {common:runtime("Eb23",  $ms1Eb23, $ms2Eb23)}
       {common:runtime("Eb24",  $ms1Eb24, $ms2Eb24)}
       {common:runtime("Eb25",  $ms1Eb25, $ms2Eb25)}
       {common:runtime("Eb26",  $ms1Eb26, $ms2Eb26)}
       {common:runtime("Eb27",  $ms1Eb27, $ms2Eb27)}
       {common:runtime("Eb28",  $ms1Eb28, $ms2Eb28)}
       {common:runtime("Eb29",  $ms1Eb29, $ms2Eb29)}
       {common:runtime("Eb31",  $ms1Eb31, $ms2Eb31)}
       {common:runtime("Eb32",  $ms1Eb32, $ms2Eb32)}
       {common:runtime("Eb35",  $ms1Eb35, $ms2Eb35)}
       {common:runtime("Eb36",  $ms1Eb36, $ms2Eb36)}
       {common:runtime("Eb37",  $ms1Eb37, $ms2Eb37)}
       {common:runtime("Eb38",  $ms1Eb38, $ms2Eb38)}
       {common:runtime("Eb39",  $ms1Eb39, $ms2Eb39)}
       {common:runtime("Eb40",  $ms1Eb40, $ms2Eb40)}
       {common:runtime("Eb41",  $ms1Eb41, $ms2Eb41)}
       {common:runtime("Eb42",  $ms1Eb42, $ms2Eb42)}
       {common:runtime("Eb43",  $ms1Eb43, $ms2Eb43)}
       {common:runtime("Eb44",  $ms1Eb44, $ms2Eb44)}
       {common:runtime("Total time",  $ms1Total, $ms2Total)}
    </table>
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
