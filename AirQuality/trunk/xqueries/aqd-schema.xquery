xquery version "3.0";

(:~
: User: George Sofianos
: Date: 7/19/2016
: Time: 4:40 PM
:)

module namespace schema = "aqd-schema";
import module namespace errors = "aqd-errors" at "aqd-errors.xquery";

declare variable $schema:INVALIDSTATUS := "invalid";
declare variable $schema:IGNORED := ("cvc-elt.1: Cannot find the declaration of element 'gml:FeatureCollection'.",
"cvc-elt.4.2: Cannot resolve 'gco:RecordType_Type' to a type definition for element 'gco:Record'.",
"cvc-elt.4.2: Cannot resolve 'ns:DataArrayType' to a type definition for element 'om:result'.",
"cvc-elt.4.2: Cannot resolve 'ns:ReferenceType' to a type definition for element 'om:value'.");

declare function schema:validateXmlSchema($source_url as xs:string) {
    let $successfulResult := <div class="feedbacktext">
        <span id="feedbackStatus" class="INFO" style="display:none">XML Schema validation passed without errors.</span>
        <span style="display:none"><p>OK</p></span>
        <h2>XML Schema validation</h2>
        <p><span style="background-color: green; font-size: 0.8em; color: white; padding-left:5px;padding-right:5px;margin-right:5px;text-align:center">OK</span>XML Schema validation passed without errors.</p><p>The file was validated against <a href="http://dd.eionet.europa.eu/schemas/id2011850eu-1.0/AirQualityReporting.xsd">http://dd.eionet.europa.eu/schemas/id2011850eu-1.0/AirQualityReporting.xsd</a></p></div>

    let $validationResult := validate:xsd-report(doc($source_url))
    return $validationResult
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
declare function schema:getErrorClass($result as element(report)) {
    let $status := string($result/status)
    return
        if ($status = $schema:INVALIDSTATUS) then
            $errors:ERROR
        else
            $errors:INFO
};