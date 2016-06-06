xquery version "1.0" encoding "UTF-8";
(:
 : Module Name: Implementing Decision 2011/850/EU: AQ info exchange & reporting (Main module)
 :
 : Version:     $Id$
 : Created:     30 December 2014
 : Copyright:   European Environment Agency
 :)
(:~
 : AirQuality obligation dependentent XQuery script call library modules based on the obligation URL extracted from CDR envelope XML.
 : The original request: http://taskman.eionet.europa.eu/issues/21548
 :
 : @author Enriko Käsper
 : @author George Sofianos
 : BLOCKER logic added and other changes by Hermann Peifer, EEA, August 2015
 :)

(: Dataflow B script - Zones :)
import module namespace dfB = "http://converters.eionet.europa.eu/dataflowB" at "aqd_check_b-1.0.xquery";
(: Dataflow C script - Assessment regimes :)
import module namespace dfC = "http://converters.eionet.europa.eu/dataflowC" at "aqd_check_c-1.0.xquery";
(: Dataflow D script -  :)
import module namespace dfD = "http://converters.eionet.europa.eu/dataflowD" at "aqd_check_d-1.0.xquery";
(: Dataflow G script -  :)
import module namespace dfG = "http://converters.eionet.europa.eu/dataflowG" at "aqd_check_g-1.0.xquery";
(: Dataflow M script -  :)
import module namespace dfM = "http://converters.eionet.europa.eu/dataflowM" at "aqd_check_m-1.0.xquery";
import module namespace common = "aqd-common" at "aqd_check_common.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";

declare namespace xmlconv = "http://converters.eionet.europa.eu";

(:===================================================================:)
(: Variable given as an external parameter by the QA service                                                 :)
(:===================================================================:)

declare variable $source_url as xs:string external;

declare variable $xmlconv:ROD_PREFIX as xs:string := "http://rod.eionet.europa.eu/obligations/";
declare variable $xmlconv:B_OBLIGATIONS as xs:string* := (concat($xmlconv:ROD_PREFIX, "670"), concat($xmlconv:ROD_PREFIX, "693"));
declare variable $xmlconv:C_OBLIGATIONS as xs:string* := (concat($xmlconv:ROD_PREFIX, "671"), concat($xmlconv:ROD_PREFIX, "694"));
declare variable $xmlconv:D_OBLIGATIONS as xs:string* := (concat($xmlconv:ROD_PREFIX, "672"));
declare variable $xmlconv:M_OBLIGATIONS as xs:string* := (concat($xmlconv:ROD_PREFIX, "672"));
declare variable $xmlconv:G_OBLIGATIONS as xs:string* := (concat($xmlconv:ROD_PREFIX, "679"));

declare function xmlconv:proceed($source_url as xs:string) {

    (: get reporting obligation & country :)
    let $envelopeUrl := common:getEnvelopeXML($source_url)
    let $obligations := if(string-length($envelopeUrl)>0) then fn:doc($envelopeUrl)/envelope/obligation else ()
    let $countryCode := common:getCountryCode($source_url)

    let $validObligations := common:getSublist($obligations,
            ($xmlconv:B_OBLIGATIONS, $xmlconv:C_OBLIGATIONS, $xmlconv:D_OBLIGATIONS, $xmlconv:G_OBLIGATIONS, $xmlconv:M_OBLIGATIONS))

    let $result := ()
    let $resultB :=
        if (common:containsAny($obligations, $xmlconv:B_OBLIGATIONS)) then
            dfB:proceed($source_url, $countryCode)
        else
            ()
    let $resultC :=
        if (common:containsAny($obligations, $xmlconv:C_OBLIGATIONS)) then
            dfC:proceed($source_url, $countryCode)
        else
            ()
    let $resultD :=
        if (common:containsAny($obligations, $xmlconv:D_OBLIGATIONS)) then
            dfD:proceed($source_url, $countryCode)
        else
            ()
    let $resultG :=
        if (common:containsAny($obligations, $xmlconv:G_OBLIGATIONS)) then
            dfG:proceed($source_url, $countryCode)
        else
            ()
    let $resultM :=
        if (common:containsAny($obligations, $xmlconv:M_OBLIGATIONS)) then
            dfM:proceed($source_url, $countryCode)
        else
            ()

	(: TODO: Catch fatal errors from obligation-dependent tests, handle them as BLOCKERs :)
	let $messages := ($resultB, $resultC, $resultD, $resultG, $resultM)
	let $errorString := normalize-space(string-join($messages//p[@class='error'], ' || '))
    let $warningString := normalize-space(string-join($messages//p[@class='warning'], ' || '))

	let $errorLevel :=
		if ($errorString) then
            "BLOCKER"
        else if ($warningString) then
            "WARNING"
        else
            "INFO"

	let $feedbackmessage :=
		if ($errorLevel = 'BLOCKER') then
            $errorString
        else if ($errorLevel = 'WARNING') then
            $warningString
        else if (empty($validObligations)) then
            "Nothing to check"
        else
            "This XML file passed all checks without errors or warnings"

return
        <div class="feedbacktext">
            {html:getHead()}
			<span id="feedbackStatus" class="{$errorLevel}" style="display:none">{$feedbackmessage}</span>
            <p>Checked XML file: <a href="{common:getCleanUrl($source_url)}">{common:getCleanUrl($source_url)}</a></p>
            {
            if (empty($validObligations)) then
                <p>Nothing to check - the envelope is not attached to any of the Air Quality obligation where QA script is available.</p>
            else
                <div>
                    {html:javaScriptRoot()}
                    {
                    if (count($validObligations) = 1) then
                        <p>The envelope is attached to the following obligation: <a href="{$validObligations[1]}">{$validObligations[1]}</a></p>
                    else
                        <span>
                            <p>The envelope is attached to the following obligations:</p>
                            <ul>
                                {
                                    for $obligation in $validObligations
                                    return
                                        <li><a href="{$obligation}">{$obligation}</a></li>
                                }
                            </ul>
                        </span>
                    }
                    {$messages}
                </div>
            }
            {html:getFoot()}
        </div>
};
xmlconv:proceed( $source_url )
