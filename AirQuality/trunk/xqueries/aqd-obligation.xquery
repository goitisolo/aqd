xquery version "3.0" encoding "UTF-8";
(:
 : Module Name: Implementing Decision 2011/850/EU: AQ info exchange & reporting (Main module)
 :
 : Version:     $Id$
 : Created:     30 December 2014
 : Copyright:   European Environment Agency
 :
 : AirQuality obligation dependentent XQuery script call library modules based on the obligation URL extracted from CDR envelope XML.
 : The original request: http://taskman.eionet.europa.eu/issues/21548
 :
 : @author Enriko Käsper
 : @author George Sofianos
 : BLOCKER logic added and other changes by Hermann Peifer, EEA, August 2015
 :)

(:~
 : Dataflow B script - Zones
 : Dataflow C script - Assessment regimes
 : Dataflow D script -
 : Dataflow G script -
 : Dataflow M script -
 :)
module namespace obligations = "http://converters.eionet.europa.eu";
import module namespace dfB = "http://converters.eionet.europa.eu/dataflowB" at "aqd-dataflow-b.xquery";
import module namespace dfC = "http://converters.eionet.europa.eu/dataflowC" at "aqd-dataflow-c.xquery";
import module namespace dfD = "http://converters.eionet.europa.eu/dataflowD" at "aqd-dataflow-d.xquery";
import module namespace dfG = "http://converters.eionet.europa.eu/dataflowG" at "aqd-dataflow-g.xquery";
import module namespace dfM = "http://converters.eionet.europa.eu/dataflowM" at "aqd-dataflow-m.xquery";
import module namespace dfE = "http://converters.eionet.europa.eu/dataflowE" at "aqd-dataflow-e.xquery";
import module namespace dfEb = "http://converters.eionet.europa.eu/dataflowEb" at "aqd-dataflow-eb.xquery";

import module namespace common = "aqd-common" at "aqd-common.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";
import module namespace schemax = "aqd-schema" at "aqd-schema.xquery";
import module namespace errors = "aqd-errors" at "aqd-errors.xquery";

declare function obligations:proceed($source_url as xs:string) {

    (: get reporting obligation & country :)
    let $envelopeUrl := common:getEnvelopeXML($source_url)
    let $obligations := doc($envelopeUrl)/envelope/obligation
    let $countryCode := lower-case(doc($envelopeUrl)/envelope/countrycode)

    let $validObligations := common:getSublist($obligations,
            ($dfB:OBLIGATIONS, $dfC:OBLIGATIONS, $dfD:OBLIGATIONS, $dfG:OBLIGATIONS, $dfM:OBLIGATIONS, $dfE:OBLIGATIONS, $dfEb:OBLIGATIONS))

    let $result := ()
    let $resultB :=
        if (common:containsAny($obligations, $dfB:OBLIGATIONS)) then
            dfB:proceed($source_url, $countryCode)
        else
            ()
    let $resultC :=
        if (common:containsAny($obligations, $dfC:OBLIGATIONS)) then
            dfC:proceed($source_url, $countryCode)
        else
            ()
    let $resultD :=
        if (common:containsAny($obligations, $dfD:OBLIGATIONS)) then
            dfD:proceed($source_url, $countryCode)
        else
            ()
    let $resultG :=
        if (common:containsAny($obligations, $dfG:OBLIGATIONS)) then
            dfG:proceed($source_url, $countryCode)
        else
            ()
    let $resultM :=
        if (common:containsAny($obligations, $dfM:OBLIGATIONS)) then
            dfM:proceed($source_url, $countryCode)
        else
            ()
    let $resultE :=
        if (common:containsAny($obligations, $dfE:OBLIGATIONS)) then
            dfE:proceed($source_url, $countryCode)
        else
            ()
    let $resultEb :=
        if (common:containsAny($obligations, $dfEb:OBLIGATIONS)) then
            dfEb:proceed($source_url, $countryCode)
        else
            ()

    let $messages := ($resultB, $resultC, $resultD, $resultE, $resultEb, $resultG, $resultM)
    let $failedString := string-join($messages//p[tokenize(@class, "\s+") = $errors:FAILED], ' || ')
    let $blockerString := normalize-space(string-join($messages//p[tokenize(@class, "\s+") = $errors:BLOCKER], ' || '))
    let $errorString := normalize-space(string-join($messages//p[tokenize(@class, "\s+") = $errors:ERROR], ' || '))
    let $warningString := normalize-space(string-join($messages//p[tokenize(@class, "\s+") = $errors:WARNING], ' || '))

	let $errorLevel :=
        if ($blockerString) then
            "BLOCKER"
		else if ($errorString) then
            "ERROR"
        else if ($warningString or $failedString) then
            "WARNING"
        else
            "INFO"

	let $feedbackmessage :=
		if ($errorLevel = 'BLOCKER') then
            $blockerString
        else if ($errorLevel = 'ERROR') then
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
        {html:getCSS()}
        <span id="feedbackStatus" class="{$errorLevel}" style="display:none">{$feedbackmessage}</span>
        <div class="column row">
            <p>Checked XML file: <a href="{common:getCleanUrl($source_url)}">{common:getCleanUrl($source_url)}</a></p>
        </div>
        <div class="column row">{
            if (empty($validObligations)) then
                <p>Nothing to check - the envelope is not attached to any of the Air Quality obligation where QA script is available.</p>
            else
                <div>
                    {html:javaScriptRoot()}
                    {
                    if (count($validObligations) = 1) then
                        <p>The envelope is attached to the following obligation: <a href="{$validObligations[1]}">{$validObligations[1]}</a></p>
                    else
                        (<p>The envelope is attached to the following obligations:</p>,
                        <ul>
                            {
                                for $obligation in $validObligations
                                return
                                    <li><a href="{$obligation}">{$obligation}</a></li>
                            }
                        </ul>)
                    }
                    {$messages}
                </div>
            }
            {html:getFoot()}
        </div>
    </div>
};
