xquery version "3.0";

(:~
: User: George Sofianos
: Date: 7/19/2016
: Time: 4:40 PM
:)

module namespace schemax = "aqd-schema";
import module namespace errors = "aqd-errors" at "aqd-errors.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";

declare variable $schemax:INVALIDSTATUS := "invalid";
declare variable $schemax:SCHEMA := "http://dd.eionet.europa.eu/schemas/id2011850eu-1.0/AirQualityReporting.xsd";

declare variable $schemax:IGNORED := ("cvc-elt.1: Cannot find the declaration of element 'gml:FeatureCollection'.",
"cvc-elt.4.2: Cannot resolve 'gco:RecordType_Type' to a type definition for element 'gco:Record'.",
"cvc-elt.4.2: Cannot resolve 'ns:DataArrayType' to a type definition for element 'om:result'.",
"cvc-elt.4.2: Cannot resolve 'ns:ReferenceType' to a type definition for element 'om:value'.");
declare variable $schemax:IGNORED_NEW := ("cvc-elt.1.a: Cannot find the declaration of element 'gml:FeatureCollection'.",
"cvc-elt.4.2.a: Cannot resolve 'gco:RecordType_Type' to a type definition for element 'gco:Record'.",
"cvc-elt.4.2.a: Cannot resolve 'ns:DataArrayType' to a type definition for element 'om:result'.",
"cvc-elt.4.2.a: Cannot resolve 'ns:ReferenceType' to a type definition for element 'om:value'.");

declare function schemax:validateXmlSchema($source_url as xs:string) {
    (: Change this to doc($source_url) after the BaseX bug is fixed :)
    let $validationResult := validate:xsd-report(($source_url))
    let $finalResult :=
        for $node in $validationResult/message
        where not($node = $schemax:IGNORED) and not($node = $schemax:IGNORED_NEW)
        return
            <tr>
                <td title="Status">{string($node/@level)}</td>
                <td title="Line">{string($node/@line)}</td>
                <td title="Column">{string($node/@column)}</td>
                <td title="Message">{string($node)}</td>
            </tr>
    return $finalResult
(:    let $hasErrors := count($validationResult//*[local-name() = "tr"]) > 1

    let $filteredResult :=
        if ($hasErrors) then
            <div class="feedbacktext">
                {
                    for $elem in $validationResult/child::div/child::*
                    return
                        if ($elem/local-name() = "table") then
                            <table class="datatable" border="1">
                                {
                                    for $tr in $elem//tr
                                    return
                                        if (not(empty(index-of($schema:IGNORED, normalize-space($tr/td[3]/text()))))) then
                                            ()
                                        else
                                            $tr
                                }
                            </table>
                        else
                            $elem
                }
            </div>
        else
            $validationResult

    let $hasErrorsAfterFiltering := count($filteredResult//*[local-name()="tr"]) > 1

    return
        if ($hasErrors and not($hasErrorsAfterFiltering)) then
            $successfulResult
        else
            $filteredResult:)
};
declare function schemax:getErrorClass($result as element(report)) {
    let $status := string($result/status)
    return
        if ($status = $schemax:INVALIDSTATUS) then
            $errors:XML
        else
            $errors:INFO
};
