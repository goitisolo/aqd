xquery version "3.0";
(:
 : Module Name: AirQuality dataflow envelope level check(Main module)
 :
 : Version:     $Id$
 : Created:     15 November 2013
 : Copyright:   European Environment Agency
 :)
(:~
 : Reporting Obligation: http://rod.eionet.europa.eu/obligations/670
 : XML Schema: http://dd.eionet.europa.eu/schemas/id2011850eu/AirQualityReporting.xsd
 :
 : Air Quality QA Rules implementation
 :
 : @author Enriko Käsper
 : BLOCKER logic fixed and other changes by Hermann Peifer, EEA, August 2015
 : @author George Sofianos
 :)

import module namespace schemax = "aqd-schema" at "aqd-schema.xquery";
import module namespace common = "aqd-common" at "aqd-common.xquery";
import module namespace sparqlx = "aqd-sparql" at "aqd-sparql.xquery";
import module namespace query = "aqd-query" at "aqd-query.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";
import module namespace errors = "aqd-errors" at "aqd-errors.xquery";
import module namespace vocabulary = "aqd-vocabulary" at "aqd-vocabulary.xquery";

declare namespace xmlconv="http://converters.eionet.europa.eu/aqd";
declare namespace aqd = "http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0";
declare namespace gml = "http://www.opengis.net/gml/3.2";

declare option output:method "html";
declare option db:inlinelimit '0';

declare variable $source_url as xs:string external;

(:~ Separator used in lists expressed as string :)
declare variable $xmlconv:LIST_ITEM_SEP := "##";

(:~ Source file URL parameter name :)
declare variable $xmlconv:SOURCE_URL_PARAM := "source_url=";

(: Not documented in QA doc: count only XML files related to AQ e-Reporting :)
declare function xmlconv:getAQFiles($url as xs:string) {
    for $pn in fn:doc($url)//file[contains(@schema,'AirQualityReporting.xsd') and string-length(@link)>0]
    let $fileUrl := common:replaceSourceUrl($url, string($pn/@link))
    return
        $fileUrl
};

(: QA doc 2.1.3 Check for Reporting Header within an envelope :)
declare function xmlconv:checkFileReportingHeader($envelope as element(envelope)*, $file as xs:string, $pos as xs:integer) {
    (:let $obligationYears := sparqlx:run(query:getObligationYears()):)
    let $docRoot := doc($file)

    (: set variables for envelope year :)
    let $minimumYear := number(xmlconv:getObligationMinMaxYear($envelope)/min)
    let $maximumYear := number(xmlconv:getObligationMinMaxYear($envelope)/max)

    (:  If AQ e-Reporting XML files in the envelope, at least one must have an aqd:AQD_ReportingHeader element. :)
    let $containsAqdReportingHeader :=
        try {
            if (count($docRoot//aqd:AQD_ReportingHeader) > 0) then
                <tr>
                </tr>
            else
                ()
        }  catch * {
            <tr status="failed">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    (: The aqd:AQD_ReportingHeader must have the same value for year in aqd:reportingPeriod/beginPosition as in the envelope :)
    let $falseTimePeriod :=
        try {
            if (common:getReportingYear($docRoot) != $envelope/year) then
                <tr>
                </tr>
            else
                ()
        }  catch * {
            <tr status="failed">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }
    (: The aqd:AQD_ReportingHeader must include aqd:inspireId, aqd:reportingAuthority, aqd:reportingPeriod and aqd:change elements :)
    let $missingAqdReportingHeaderSubElements :=
        try {
            if (distinct-values(
                        for $elem in ("aqd:inspireId", "aqd:reportingAuthority", "aqd:change", "aqd:reportingPeriod")
                        where count(doc($file)//aqd:AQD_ReportingHeader) > 0 and count(doc($file)//aqd:AQD_ReportingHeader/*[name()=$elem and string-length(normalize-space(.)) > 0]) = 0
                        return
                            $elem
                )) then
                <tr></tr>
            else ()
            }  catch * {
                <tr status="failed">
                    <td title="Error code">{$err:code}</td>
                    <td title="Error description">{$err:description}</td>
                </tr>
            }
    (: If aqd:change='true' the following information must also be provided :)
    let $missingElementsIfAqdChangeIsTrue :=
        try {
            if (
                distinct-values(
                        for $elem in ("aqd:changeDescription", "aqd:content")
                        where count(doc($file)//aqd:AQD_ReportingHeader[aqd:change=true()]) > 0 and count(doc($file)//aqd:AQD_ReportingHeader[
                        (aqd:change=true() and count(child::*[name()=$elem]) = 0)]) > 0
                        return
                            $elem
                )) then
                    <tr></tr>
                else
                    ()
        }  catch * {
            <tr status="failed">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }
    (: If aqd:change='false', then aqd:content IS NOT expected. :)
    let $appearingElementsIfAqdChangeIsFalse :=
        try {

            if (
                count(index-of(
                        count(doc($file)//aqd:AQD_ReportingHeader) > 0 and count(doc($file)//aqd:AQD_ReportingHeader/*[name()='aqd:content' and ../aqd:change=false()]) > 0
                        , true()
                )) > 0) then
                <tr>
                </tr>
            else ()
        }  catch * {
            <tr status="failed">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    return
        (
        <tr>
            <td>{$pos}</td>
            <td colspan="2">Checked file: { common:getCleanUrl($file) }</td>
            <td>
                <a id='envelopeLink-{$pos}' href='javascript:toggleItem("fileLink","envelopeLink", "{$pos}", "Info")'>Show Info</a>
            </td>
        </tr>,
        <tr>
            <td></td>
            <td colspan="3">
                <table class="maintable hover" id="fileLink-{$pos}" style="display:none">
                    {html:build2("1", "", "", $containsAqdReportingHeader, "", "Check passed", "", "", $errors:ERROR)}
                    {html:build2("2", "", "", $falseTimePeriod, "", "Check passed", "", "", $errors:ERROR)}
                    {html:build2("3", "", "", $missingAqdReportingHeaderSubElements, "", "Check passed", "", "", $errors:ERROR)}
                    {html:build2("4", "", "", $missingElementsIfAqdChangeIsTrue, "", "Check passed", "", "", $errors:ERROR)}
                    {html:build2("5", "", "", $appearingElementsIfAqdChangeIsFalse, "", "Check passed", "", "", $errors:ERROR)}
                </table>
            </td>
        </tr>)
};

declare function xmlconv:getObligationMinMaxYear($envelope as element(envelope)) as element(year) {
    let $deadline := 2016
    let $id := substring-after($envelope/obligation, $vocabulary:OBLIGATIONS)
    let $part1 := ("670", "671", "672", "673", "674", "675", "679", "742")
    let $part2 := ("680", "681", "682", "683")
    let $part3 := ("693", "694")
    let $minYear :=
        if ($id = $part1) then
            $deadline - 2
        else if ($id = $part2) then
            $deadline - 3
        else if ($id = $part3) then
            $deadline
        else
            ()
    let $maxYear :=
        if ($id = $part1) then
            $deadline - 1
        else if ($id = $part2) then
            $deadline - 2
        else if ($id = $part3) then
            $deadline + 1
        else
            ()
    return
        <year>
            <min>{$minYear}</min>
            <max>{$maxYear}</max>
        </year>
};

(: File count logic changed :)
declare function xmlconv:validateEnvelope() as element(div) {
    (: set variable for envelope path :)
    let $envelope := doc($source_url)/envelope

    (: set variables for envelope year :)
    let $minimumYear := number(xmlconv:getObligationMinMaxYear($envelope)/min)
    let $maximumYear := number(xmlconv:getObligationMinMaxYear($envelope)/max)

    (: Count of string values :)
    let $xmlFilesWithAQSchema := xmlconv:getAQFiles($source_url)
    let $filesCountAQSchema := count($xmlFilesWithAQSchema)

    (: Count of nodes :)
    let $filesWithAQSchema := $envelope/file[contains(@schema,'AirQualityReporting.xsd') and string-length(@link)>0]

    let $reportingHeaderCheck :=
        for $file at $pos in $xmlFilesWithAQSchema
        return
            if (doc-available($file)) then
                xmlconv:checkFileReportingHeader($envelope, $file, $pos)
            else
                xmlconv:warningTable($pos, common:getCleanUrl($file))

    let $correctFileCountMessage :=
        try {
            let $filesCountCorrectSchema := count($filesWithAQSchema[@schema = $schemax:SCHEMA])
            return if ($filesCountCorrectSchema = 0) then
                (
                    <p class="error">Your delivery cannot be accepted as you did not provide any XML file with correct XML Schema location.<br />
                        Valid XML Schema location is: <strong>{$schemax:SCHEMA}</strong></p>
                )
            else if ($filesCountCorrectSchema != $filesCountAQSchema) then
                (
                    <p class="error">1 or more AQ e-Reporting XML file(s) with incorrect XML Schema location<br />
                        Valid XML Schema location is: <strong>{$schemax:SCHEMA}</strong></p>
                )
            else
                (<p class="info">Your delivery contains {$filesCountCorrectSchema} AQ e-Reporting XML file{substring("s ", number(not($filesCountCorrectSchema > 1)) * 2)}with correct XML Schema.</p>)
        } catch * {
            <tr status="failed">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    let $correctEnvelopeYear :=
        try {
            if ($envelope/year[number() != number()])  then
                <tr>
                    <p class="error">Year has not been specified in the envelope period! Keep in mind that the year value must be between {$minimumYear} - {$maximumYear} and it must be equal to the year in gml:beginPosition element (in aqd:AQD_ReportingHeader).</p>
                </tr>
            else if ($envelope/year/number() < $minimumYear or $envelope/year/number() > $maximumYear) then
                <tr>
                    <p class="error">Year specified in the envelope period is outside the allowed range of {$minimumYear} - {$maximumYear}! Keep in mind that the year value must be between {$minimumYear} - {$maximumYear} and it must be equal to the year in gml:beginPosition element (in aqd:AQD_ReportingHeader).</p>
                </tr>
            else
                ()
        } catch * {
            <tr status="failed">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }
    (: Commented out check for the end year, we might need it in the future

        let $correctEnvelopeYear :=
        if ($envelope/endyear[number() = number()] and ($envelope/endyear/number() < $minimumYear or $envelope/endyear/number() > $maximumYear)) then
            ($correctEnvelopeYear, <p class="error">The end year on the envelope is different than the year given in gml:endPosition element (in aqd:AQD_ReportingHeader) or/and outside the allowed range of {$minimumYear} - {$maximumYear}!</p>)
        else
            $correctEnvelopeYear
        :)

    let $messages := ($correctFileCountMessage, $correctEnvelopeYear, $reportingHeaderCheck)

    let $errorCount := count($messages[@class = $errors:ERROR])

    let $errorLevel :=
        if ($errorCount = 0) then
            $errors:INFO
        else
            $errors:BLOCKER

    let $feedbackMessage :=
        if ($errorCount = 0) then
            "No envelope-level errors found" 
        else
            concat($errorCount, ' envelope-level error', substring('s ', number(not($errorCount > 1)) * 2), 'found')

    return
        <div class="feedbacktext">
            {html:getHead()}
            {html:getCSS()}
            <div class="row column">
                <h2>Check contents of delivery</h2>
                <span id="feedbackStatus" class="{$errorLevel}" style="display:none">{$feedbackMessage}</span>
                <p>Checked contents of envelope:</p>
                <table class="maintable hover">
                {$messages}
                </table>
                <br/>
                <div class="footnote"><sup>*</sup>Detailed information about the QA/QC rules checked in this routine can be found from the <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a> in chapter "2.1.3 Check for Reporting Header within an envelope".</div>
                {html:getFoot()}
                {html:javaScriptRoot()}
            </div>
        </div>
};
declare function xmlconv:warningTable($pos, $file) {
    <tr class="{$errors:WARNING}">
        <td>{$pos}</td>
        <td colspan="3">File is not available for aqd:AQD_ReportingHeader check: { common:getCleanUrl($file) }</td>
    </tr>
};

xmlconv:validateEnvelope()