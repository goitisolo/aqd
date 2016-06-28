xquery version "1.0" encoding "UTF-8";
(:
 : Module Name: Implementing Decision 2011/850/EU: AQ info exchange & reporting (Main module)
 :
 : Version:     $Id$
 : Created:     22 November 2013
 : Copyright:   European Environment Agency
 :)
(:~
 : The script removes irrelevant GML XML Schema validation errors.
 : @author Enriko Käsper
 : @author George Sofianos
 :)

declare namespace xmlconv="http://converters.eionet.europa.eu";
declare namespace aqd = "http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0";

declare variable $xmlconv:xmlValidatorUrl as xs:string := 'http://converters.eionet.europa.eu/api/runQAScript?script_id=-1&amp;url=';

declare variable $ignoredMessages := ("cvc-elt.1: Cannot find the declaration of element 'gml:FeatureCollection'.",
    "cvc-elt.4.2: Cannot resolve 'gco:RecordType_Type' to a type definition for element 'gco:Record'.",
    "cvc-elt.4.2: Cannot resolve 'ns:DataArrayType' to a type definition for element 'om:result'.",
    "cvc-elt.4.2: Cannot resolve 'ns:ReferenceType' to a type definition for element 'om:value'.");

(:===================================================================:)
(: Variable given as an external parameter by the QA service                                                 :)
(:===================================================================:)

declare variable $source_url as xs:string external;
(:
declare variable $source_url as xs:string external;
Change it for testing locally:
declare variable $source_url as xs:string external;
declare variable $source_url as xs:untypedAtomic external;
declare variable $source_url := "http://cdr.eionet.europa.eu/gb/eu/aqd/e2a/colutn32a/envuvlxkq/E2a_GB2013032713version4.xml";
:)

(:
Remove the irrelevant GML XML Schema validation errors. It happens when the gml.xsd is not explicitly defined in schemaLocation attribute.
:)
declare function xmlconv:validateXmlSchema($source_url)
{
    let $successfulResult := <div class="feedbacktext">
    <span id="feedbackStatus" class="INFO" style="display:none">XML Schema validation passed without errors.</span>
    <span style="display:none"><p>OK</p></span>
    <h2>XML Schema validation</h2>
    <p><span style="background-color: green; font-size: 0.8em; color: white; padding-left:5px;padding-right:5px;margin-right:5px;text-align:center">OK</span>XML Schema validation passed without errors.</p><p>The file was validated against <a href="http://dd.eionet.europa.eu/schemas/id2011850eu-1.0/AirQualityReporting.xsd">http://dd.eionet.europa.eu/schemas/id2011850eu-1.0/AirQualityReporting.xsd</a></p></div>

    let $fullUrl := concat($xmlconv:xmlValidatorUrl, fn:encode-for-uri($source_url))
    let $validationResult := doc($fullUrl)

    let $hasErrors := count($validationResult//*[local-name() = "tr"]) > 1

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
                                if (not(empty(index-of($ignoredMessages, normalize-space($tr/td[3]/text()))))) then
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
            $filteredResult

};

(:
 : ======================================================================
 : Main function
 : ======================================================================
 :)
declare function xmlconv:proceed($source_url as xs:string)
{

    xmlconv:validateXmlSchema($source_url)
};

xmlconv:proceed( $source_url )
