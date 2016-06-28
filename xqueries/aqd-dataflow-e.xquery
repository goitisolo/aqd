xquery version "3.0";

(:~
: User: George Sofianos
: Date: 6/28/2016
: Time: 6:10 PM
:)

module namespace xmlconv = "http://converters.eionet.europa.eu/dataflowE";
import module namespace common = "aqd-common" at "aqd_check_common.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";
import module namespace errors = "aqd-errors" at "aqd-errors.xquery";
import module namespace labels = "aqd-labels" at "aqd-labels.xquery";

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

declare function xmlconv:checkReport($source_url as xs:string, $countryCode as xs:string) as element(table) {

let $envelopeUrl := common:getEnvelopeXML($source_url)
let $docRoot := doc($source_url)

(: E1 - /om:OM_Observation gml:id attribute shall be unique code for the group of observations enclosed by /OM_Observation within the delivery. :)
let $E1invalid :=
    try {
        let $all := data(//om:OM_Observation/@gml:id)
        for $x in $docRoot//om:OM_Observation/@gml:id
        where count(index-of($all, $x)) > 0
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
return
    <table class="maintable hover">
        {html:buildResultRows("E1", $labels:E1, $labels:E1_SHORT, $E1invalid, "", "", "", "", $errors:ERROR)}
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
        <h2>Check air quality zones - Dataflow B</h2>
        {$html}
    </div>
};