xquery version "3.0";

(:~
: User: George Sofianos
: Date: 6/28/2016
: Time: 6:10 PM
:)

module namespace xmlconv = "http://converters.eionet.europa.eu/dataflowE";
import module namespace common = "aqd-common" at "aqd-common.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";
import module namespace errors = "aqd-errors" at "aqd-errors.xquery";
import module namespace labels = "aqd-labels" at "aqd-labels.xquery";
import module namespace dd = "aqd-dd" at "aqd-dd.xquery";
import module namespace query = "aqd-query" at "aqd-query.xquery";
import module namespace sparqlx = "aqd-sparql" at "aqd-sparql.xquery";

declare namespace aqd = "http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0";
declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace am = "http://inspire.ec.europa.eu/schemas/am/3.0";
declare namespace ef = "http://inspire.ec.europa.eu/schemas/ef/3.0";
declare namespace base = "http://inspire.ec.europa.eu/schemas/base/3.3";
declare namespace gn = "urn:x-inspire:specification:gmlas:GeographicalNames:3.0";
declare namespace base2 = "http://inspire.ec.europa.eu/schemas/base2/1.0";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace ompr = "http://inspire.ec.europa.eu/schemas/ompr/2.0";
declare namespace om = "http://www.opengis.net/om/2.0";
declare namespace swe = "http://www.opengis.net/swe/2.0";
declare variable $xmlconv:OBLIGATIONS as xs:string* := ("http://rod.eionet.europa.eu/obligations/673");
declare function xmlconv:checkReport($source_url as xs:string, $countryCode as xs:string) as element(table) {

let $envelopeUrl := common:getEnvelopeXML($source_url)
let $docRoot := doc($source_url)
let $reportingYear := common:getReportingYear($docRoot)
let $cdrUrl := common:getCdrUrl($countryCode)

(: E0 :)
let $E0invalid :=
    try {
        if (query:deliveryExists($xmlconv:OBLIGATIONS, $countryCode, "e/", $reportingYear)) then
            <tr>
                <td title="base:localId">{$docRoot//aqd:AQD_ReportingHeader/aqd:inspireId/base:Identifier/base:namespace/string()}</td>
                <td title="base:localId">{$docRoot//aqd:AQD_ReportingHeader/aqd:inspireId/base:Identifier/base:localId/string()}</td>
            </tr>
        else
            ()
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: E01 :)
let $E01count :=
    try {
        count($docRoot//om:OM_Observation)
    } catch * {
        0
    }

(: E1 - /om:OM_Observation gml:id attribute shall be unique code for the group of observations enclosed by /OM_Observation within the delivery. :)
let $E1invalid :=
    try {
        let $all := data($docRoot//om:OM_Observation/@gml:id)
        for $x in $docRoot//om:OM_Observation/@gml:id
        where count(index-of($all, $x)) > 1
        return
            <tr>
                <td title="om:OM_Observation">{string($x)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(:E2 - /om:phenomenonTime/gml:TimePeriod/gml:beginPosition shall be LESS THAN ./om:phenomenonTime/gml:TimePeriod/gml:endPosition. -:)
let $E2invalid :=
    try {
        let $all := $docRoot//om:phenomenonTime/gml:TimePeriod
        for $x in $all
            let $begin := xs:dateTime($x/gml:beginPosition)
            let $end := xs:dateTime($x/gml:endPosition)
        where ($end < $begin)
        return
            <tr>
                <td title="@gml:id">{string($x/../../@gml:id)}</td>
            </tr>
    }
    catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(:E3 - ./om:resultTime/gml:TimeInstant/gml:timePosition shall be GREATER THAN ./om:phenomenonTime/gml:TimePeriod/gml:endPosition :)
let $E3invalid :=
    try {
        let $all := $docRoot//om:OM_Observation
        for $x in $all
            let $timePosition := xs:dateTime($x/om:resultTime/gml:TimeInstant/gml:timePosition)
            let $endPosition := xs:dateTime($x/om:phenomenonTime/gml:TimePeriod/gml:endPosition)
        where ($timePosition < $endPosition)
        return
            <tr>
                <td title="@gml:id">{string($x/@gml:id)}</td>
            </tr>
    }
    catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: E4 - ./om:procedure xlink:href attribute shall resolve to a traversable link process configuration in Data flow D: /aqd:AQD_SamplingPointProcess/ompr:inspireld/base:Identifier/base:localId:)
let $E4invalid :=
    try {
        let $result := sparqlx:executeSparqlQuery(query:getSamplingPointProcess($cdrUrl))
        let $all := $result/sparql:binding[@name = "inspireLabel"]/sparql:literal/string()
        let $procedures := $docRoot//om:procedure/@xlink:href/string()
        for $x in $procedures[not(. = $all)]
        return
            <tr>
                <td title="base:localId">{$x}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: E5 - A valid delivery MUST provide an om:parameter with om:name/@xlink:href to http://dd.eionet.europa.eu/vocabulary/aq/processparameter/SamplingPoint :)
let $E5invalid :=
    try {
        let $all := $docRoot//om:OM_Observation
        for $x in $all
        let $xlinks := data($x/om:parameter/om:NamedValue/om:name/@xlink:href)
        where not("http://dd.eionet.europa.eu/vocabulary/aq/processparameter/SamplingPoint" = $xlinks)
        return
            <tr>
                <td title="@gml:id">{string($x/@gml:id)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: E6 :)
let $E6invalid :=
    try {
        let $latestDfiles := sparqlx:executeSparqlQuery(query:getLatestDEnvelope($cdrUrl))/sparql:binding/sparql:uri/string()
        let $result := sparqlx:executeSparqlQuery(query:getSamplingPointFromFiles($latestDfiles))
        let $all := $result/sparql:binding[@name = "inspireLabel"]/sparql:literal/string()
        let $parameters := $docRoot//om:OM_Observation/om:parameter/om:NamedValue
        for $x in $parameters[om:name/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/processparameter/SamplingPoint"]
            let $name := $x/om:name/@xlink:href/string()
            let $value := $x/om:value/@xlink:href/string()
        where ($value = "" or not($value = $all))
        return
            <tr>
                <td title="base:localId">{string($x/../../@gml:id)}</td>
                <td title="om:value">{$value}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: E7 - A valid delivery SHOULD provide an om:parameter with om:name/@xlink:href to http://dd.eionet.europa.eu/vocabulary/aq/processparameter/AssessmentType :)
let $E7invalid :=
    try {
        let $all := $docRoot//om:OM_Observation
        for $x in $all
            let $xlinks := data($x/om:parameter/om:NamedValue/om:name/@xlink:href)
        where not("http://dd.eionet.europa.eu/vocabulary/aq/processparameter/AssessmentType" = $xlinks)
        return
            <tr>
                <td title="@gml:id">{string($x/@gml:id)}</td>
            </tr>
    }
    catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: E8 :)
let $E8invalid :=
    try {
        let $all := $docRoot//om:OM_Observation/om:parameter/om:NamedValue[om:name/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/processparameter/AssessmentType"]
        let $validCodes := dd:getValidConcepts("http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/rdf")
        for $x in $all
            let $value := string($x/om:value/@xlink:href)
        where not($value = $validCodes)
        return
            <tr>
                <td title="@gml:id">{string($x/../../@gml:id)}</td>
                <td title="om:value">{$value}</td>
            </tr>
    }
    catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: E10 - /om:observedProperty xlink:href attribute shall resolve to a traversable link to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/ :)
let $E10invalid :=
    try {
        let $all := dd:getValidConcepts("http://dd.eionet.europa.eu/vocabulary/aq/pollutant/rdf")
        for $x in $docRoot//om:OM_Observation/om:observedProperty
        where not($x/@xlink:href = $all)
        return
            <tr>
                <td title="@gml:id">{string($x/../@gml:id)}</td>
                <td title="om:value">{string($x/../om:parameter/om:NamedValue[om:name/@xlink:href ="http://dd.eionet.europa.eu/vocabulary/aq/processparameter/SamplingPoint"]/om:value/@xlink:href)}</td>
                <td title="om:observedProperty">{string($x/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: E11 - The pollutant xlinked via /om:observedProperty must match the pollutant code declared via /aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability/ef:observedProperty :)
let $E11invalid :=
    try {
        let $latestDfiles := sparqlx:executeSparqlQuery(query:getLatestDEnvelope($cdrUrl))/sparql:binding/sparql:uri/string()
        let $result := sparqlx:executeSparqlQuery(query:getSamplingPointMetadataFromFiles($latestDfiles))
        let $resultConcat := for $x in $result
        return $x/sparql:binding[@name="featureOfInterest"]/sparql:uri/string() || $x/sparql:binding[@name="observedProperty"]/sparql:uri/string()
        for $x in $docRoot//om:OM_Observation
            let $observedProperty := $x/om:observedProperty/@xlink:href/string()
            let $featureOfInterest := "http://reference.eionet.europa.eu/aq/" || $x/om:featureOfInterest/@xlink:href/string()
            let $concat := $featureOfInterest || $observedProperty
        where not($concat = $resultConcat)
        return
            <tr>
                <td title="@gml:id">{$x/@gml:id/string()}</td>
                <td title="om:value">{string($x/om:parameter/om:NamedValue[om:name/@xlink:href ="http://dd.eionet.europa.eu/vocabulary/aq/processparameter/SamplingPoint"]/om:value/@xlink:href)}</td>
                <td title="om:observedProperty">{$observedProperty}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: E12 :)
let $E12invalid :=
    try {
        let $result := sparqlx:executeSparqlQuery(query:getSamples($cdrUrl))
        let $samples := $result/sparql:binding[@name = "localId"]/sparql:literal/string()
        for $x in $docRoot//om:OM_Observation
            let $featureOfInterest := $x/om:featureOfInterest/@xlink:href/tokenize(string(), "/")[last()]
        where ($featureOfInterest = "") or not($featureOfInterest = $samples)
        return
            <tr>
                <td title="@gml:id">{$x/@gml:id/string()}</td>
                <td title="om:featureOfInterest">{$featureOfInterest}</td>
                <td title="om:observedProperty">{string($x/om:observedProperty/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: E15 :)
let $E15invalid :=
    try {
        for $x in $docRoot//om:OM_Observation/om:result/swe:DataArray/swe:elementType/swe:DataRecord/swe:field[@name = "StartTime"
                and not(swe:Time[@definition = "http://www.opengis.net/def/property/OGC/0/SamplingTime"]/swe:uom/@xlink:href = "http://www.opengis.net/def/uom/ISO-8601/0/Gregorian")]
        return
            <tr>
                <td title="@gml:id">{string($x/../../../../../@gml:id)}</td>
                <td title="swe:uom">{string($x/swe:Time[@definition = "http://www.opengis.net/def/property/OGC/0/SamplingTime"]/swe:uom/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: E16 :)
let $E16invalid :=
    try {
        for $x in $docRoot//om:OM_Observation/om:result/swe:DataArray/swe:elementType/swe:DataRecord/swe:field[@name = "EndTime"
                and not(swe:Time[@definition = "http://www.opengis.net/def/property/OGC/0/SamplingTime"]/swe:uom/@xlink:href = "http://www.opengis.net/def/uom/ISO-8601/0/Gregorian")]
        return
            <tr>
                <td title="@gml:id">{string($x/../../../../../@gml:id)}</td>
                <td title="swe:uom">{string($x/swe:Time[@definition = "http://www.opengis.net/def/property/OGC/0/SamplingTime"]/swe:uom/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: E17 :)
let $E17invalid :=
    try {
        for $x in $docRoot//om:OM_Observation/om:result/swe:DataArray/swe:elementType/swe:DataRecord/swe:field[@name="Validity"
                and not(swe:Category/@definition = "http://dd.eionet.europa.eu/vocabulary/aq/observationvalidity")]
        return
            <tr>
                <td title="@gml:id">{string($x/../../../../../@gml:id)}</td>
                <td title="swe:Category">{string($x/swe:Category/@definition)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: E18 :)
let $E18invalid :=
    try {
        for $x in $docRoot//om:OM_Observation/om:result/swe:DataArray/swe:elementType/swe:DataRecord/swe:field[@name = "Verification"
                and not(swe:Category/@definition = "http://dd.eionet.europa.eu/vocabulary/aq/observationverification")]
        return
            <tr>
                <td title="@gml:id">{string($x/../../../../../@gml:id)}</td>
                <td title="swe:Category">{string($x/swe:Category/@definition)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: E19 :)
let $E19invalid :=
    try {
        let $obs := dd:getValidConcepts("http://dd.eionet.europa.eu/vocabulary/aq/primaryObservation/rdf")
        let $cons := dd:getValidConcepts("http://dd.eionet.europa.eu/vocabulary/uom/concentration/rdf")
        for $x in $docRoot//om:OM_Observation/om:result/swe:DataArray/swe:elementType/swe:DataRecord/swe:field[@name = "Value"
                and (not(swe:Quantity/@definition = $obs) or not(swe:Quantity/swe:uom/@xlink:href = $cons))]
        return
            <tr>
                <td title="@gml:id">{string($x/../../../../../@gml:id)}</td>
                <td title="swe:Quantity">{string($x/swe:Quantity/@definition)}</td>
                <td title="swe:uom">{string($x/swe:Quantity/swe:uom/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: E20 :)
let $E20invalid :=
    try {
        let $all := $docRoot//om:result/swe:DataArray/swe:elementType/swe:DataRecord/swe:field[@name="DataCapture"]
        for $x in $all
        let $def := $x/swe:Quantity/@definition/string()
        let $uom := $x/swe:Quantity/swe:uom/@xlink:href/string()
        where (not($def = "http://dd.eionet.europa.eu/vocabulary/aq/primaryObservation/dc") or not($uom = "http://dd.eionet.europa.eu/vocabulary/uom/statistics/percentage"))
        return
            <tr>
                <td title="@gml:id">{string($x/../../../../../@gml:id)}</td>
                <td title="@definition">{$def}</td>
                <td title="@uom">{$uom}</td>
            </tr>
    }
    catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: E21 - /om:result/swe:DataArray/swe:encoding/swe:TextEncoding shall resolve to decimalSeparator="." tokenSeparator="," blockSeparator="@@" :)
let $E21invalid :=
    try {
        for $x in $docRoot//om:result/swe:DataArray/swe:encoding/swe:TextEncoding[not(@decimalSeparator=".") or not(@tokenSeparator=",") or not(@blockSeparator="@@")]
        return
            <tr>
                <td title="@gml:id">{string($x/../../../../@gml:id)}</td>
            </tr>
    }
    catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: E26 :)
let $E26invalid :=
    try {
        let $latestDfiles := sparqlx:executeSparqlQuery(query:getLatestDEnvelope($cdrUrl))/sparql:binding/sparql:uri/string()
        let $result := sparqlx:executeSparqlQuery(query:getSamplingPointMetadataFromFiles($latestDfiles))
        let $resultsConcat :=
            for $x in $result
            return $x/sparql:binding[@name="localId"]/sparql:literal/string() || $x/sparql:binding[@name="procedure"]/sparql:uri/string() ||
            $x/sparql:binding[@name="featureOfInterest"]/sparql:uri/string() || $x/sparql:binding[@name="observedProperty"]/sparql:uri/string()

        for $x in $docRoot//om:OM_Observation
            let $samplingPoint := $x/om:parameter/om:NamedValue[om:name/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/processparameter/SamplingPoint"]/om:value/@xlink:href/tokenize(., "/")[last()]
            let $procedure := "http://reference.eionet.europa.eu/aq/" || $x/om:procedure/@xlink:href/string()
            let $featureOfInterest := "http://reference.eionet.europa.eu/aq/" || $x/om:featureOfInterest/@xlink:href/string()
            let $observedProperty := $x/om:observedProperty/@xlink:href/string()
            let $concat := $samplingPoint || $procedure || $featureOfInterest || $observedProperty
        where not($concat = $resultsConcat)
        return
            <tr>
                <td title="base:localId">{string($x/@gml:id)}</td>
            </tr>
    }
    catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

return
    <table class="maintable hover">
        {html:buildExists("E0", $labels:E0, $labels:E0_SHORT, $E0invalid, "New Delivery", "Updated Delivery", $errors:WARNING)}
        {html:buildCountRow0("E01", $labels:E01, $labels:E01_SHORT, $E01count, "", "record", $errors:INFO)}
        {html:build2("E1", $labels:E1, $labels:E1_SHORT, $E1invalid, "", "All records are valid", "record", "", $errors:ERROR)}
        {html:build2("E2", $labels:E2, $labels:E2_SHORT, $E2invalid, "", "All records are valid", "record", "", $errors:ERROR)}
        {html:build2("E3", $labels:E3, $labels:E3_SHORT, $E3invalid, "", "All records are valid", "record", "", $errors:ERROR)}
        {html:build2("E4", $labels:E4, $labels:E4_SHORT, $E4invalid, "", "All records are valid", "record", "", $errors:ERROR)}
        {html:build2("E5", $labels:E5, $labels:E5_SHORT, $E5invalid, "", "All records are valid", "record", "", $errors:ERROR)}
        {html:build2("E6", $labels:E6, $labels:E6_SHORT, $E6invalid, "", "All records are valid", "record", "", $errors:ERROR)}
        {html:build2("E7", $labels:E7, $labels:E7_SHORT, $E7invalid, "", "All records are valid", "record", "", $errors:WARNING)}
        {html:build2("E8", $labels:E8, $labels:E8_SHORT, $E8invalid, "", "All records are valid", "record", "", $errors:WARNING)}
        {html:build2("E10", $labels:E10, $labels:E10_SHORT, $E10invalid, "", "All records are valid", "record", "", $errors:ERROR)}
        {html:build2("E11", $labels:E11, $labels:E11_SHORT, $E11invalid, "", "All records are valid", "record", "", $errors:ERROR)}
        {html:build2("E12", $labels:E12, $labels:E12_SHORT, $E12invalid, "", "All records are valid", "record", "", $errors:ERROR)}
        {html:build2("E15", $labels:E15, $labels:E15_SHORT, $E15invalid, "", "All records are valid", "record", "", $errors:ERROR)}
        {html:build2("E16", $labels:E16, $labels:E16_SHORT, $E16invalid, "", "All records are valid", "record", "", $errors:ERROR)}
        {html:build2("E17", $labels:E17, $labels:E17_SHORT, $E17invalid, "", "All records are valid", "record", "", $errors:ERROR)}
        {html:build2("E18", $labels:E18, $labels:E18_SHORT, $E18invalid, "", "All records are valid", "record", "", $errors:ERROR)}
        {html:build2("E19", $labels:E19, $labels:E19_SHORT, $E19invalid, "", "All records are valid", "record", "", $errors:ERROR)}
        {html:build2("E20", $labels:E20, $labels:E20_SHORT, $E20invalid, "", "All records are valid", "record", "", $errors:ERROR)}
        {html:build2("E21", $labels:E21, $labels:E21_SHORT, $E21invalid, "", "All records are valid", "record", "", $errors:WARNING)}
        {html:build2("E26", $labels:E26, $labels:E26_SHORT, $E26invalid, "", "All records are valid", "record", "", $errors:ERROR)}
    </table>

};


declare function xmlconv:proceed($source_url as xs:string, $countryCode as xs:string) as element(div) {
    let $count := count(doc($source_url)//om:OM_Observation)
    let $result := if ($count > 0) then xmlconv:checkReport($source_url, $countryCode) else ()
    let $html :=
        if ($count = 0) then
            <p>No aqd:Zone elements found from this XML.</p>
        else
            <div>
                {
                    if ($result//div/@class = 'error') then
                        <p class="error" style="color:red"><strong>This XML file did NOT pass the following crucial check(s): {string-join($result//div[@class='error'], ',')}</strong></p>
                    else
                        <p>This XML file passed all crucial checks.</p>
                }
                {
                    if ($result//div/@class = 'warning') then
                        <p class="warning" style="color:orange"><strong>This XML file generated warnings during the following check(s): {string-join($result//div[@class = 'warning'], ',')}</strong></p>
                    else
                        ()
                }
                <h3>Test results</h3>
                {$result}
            </div>
return
    <div>
        <h2>Check air quality zones - Dataflow E</h2>
        {$html}
    </div>
};