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
import module namespace labels = "aqd-labels" at "aqd-labels.xquery";
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
            if (count($docRoot//aqd:AQD_ReportingHeader) = 0) then
                <tr>
                    <td title="Element">aqd:AQD_ReportingHeader</td>
                    <td title="Status">Missing</td>
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
            let $xmlYear := common:getReportingYear($docRoot)
            let $envelopeYear := $envelope/year
            return
                if ($xmlYear = '' or $xmlYear != $envelopeYear) then
                <tr>
                    <td title="aqd:AQD_ReportingHeader">{data($xmlYear)}</td>
                    <td title="Envelope Year">{data($envelope/year)}</td>
                    <td title="Status">Not equal</td>
                </tr>
            else
                ()
        }  catch * {
            <tr status="failed">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }
    (: The aqd:AQD_ReportingHeader must include aqd:inspireId, aqd:reportingAuthority, aqd:change elements :)
    let $missingAqdReportingHeaderSubElements :=
        try {
            for $elem in ("aqd:inspireId", "aqd:reportingAuthority", "aqd:change")
            where count($docRoot//aqd:AQD_ReportingHeader/*[name()=$elem and string-length(.) > 0]) = 0
            return
                <tr>
                    <td title="Element">{$elem}</td>
                    <td title="Status">Missing</td>
                </tr>
            }  catch * {
                <tr status="failed">
                    <td title="Error code">{$err:code}</td>
                    <td title="Error description">{$err:description}</td>
                </tr>
            }
    (: If aqd:change='true' aqd:content and aqd:changeDescription must be provided:)
    let $missingElementsIfAqdChangeIsTrue :=
        try {
            for $x in $docRoot//aqd:AQD_ReportingHeader[aqd:change = 'true']
            let $part1 :=
                if (count($x/aqd:content) = 0) then
                    <tr>
                        <td title="Element">aqd:content</td>
                        <td title="Status">Missing</td>
                    </tr>
                else ()
            let $part2 :=
                if ($x/aqd:changeDescription = '') then
                    <tr>
                        <td title="Element">aqd:changeDescription</td>
                        <td title="Status">Missing or empty</td>
                    </tr>
                else ()
            return
                ($part1, $part2)
        }  catch * {
            <tr status="failed">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }
    (: If aqd:change='false', then aqd:content IS NOT expected. :)
    let $appearingElementsIfAqdChangeIsFalse :=
        try {
            if (count($docRoot//aqd:AQD_ReportingHeader[aqd:change = 'false']/aqd:content) > 0) then
                <tr>
                    <td title="Element">aqd:content</td>
                    <td title="Status">Not expected</td>
                </tr>
            else
                ()
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
                <a id='envelopeLink-{$pos}' href='javascript:toggleItem("fileLink","envelopeLink", "{$pos}", "Check")'>Show Check</a>
            </td>
        </tr>,
        <tr>
            <td></td>
            <td colspan="3">
                <table class="maintable hover" id="fileLink-{$pos}" style="display:none">
                    {html:build2("1", $labels:ENV1, $labels:ENV1, $containsAqdReportingHeader, "", "Check passed", "", "", $errors:ERROR)}
                    {html:build2("2", $labels:ENV2, labels:interpolate($labels:ENV2, ($minimumYear, $maximumYear)), $falseTimePeriod, "", "Check passed", "", "", $errors:ERROR)}
                    {html:build2("3", $labels:ENV3, $labels:ENV3, $missingAqdReportingHeaderSubElements, "", "Check passed", "", "", $errors:ERROR)}
                    {html:build2("4", $labels:ENV4, $labels:ENV4, $missingElementsIfAqdChangeIsTrue, "", "Check passed", "", "", $errors:ERROR)}
                    {html:build2("5", $labels:ENV5, $labels:ENV5, $appearingElementsIfAqdChangeIsFalse, "", "Check passed", "", "", $errors:ERROR)}
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

declare function xmlconv:warningTable($pos, $file) {
    <tr class="{$errors:WARNING}">
        <td>{$pos}</td>
        <td colspan="3">File is not available for aqd:AQD_ReportingHeader check: { common:getCleanUrl($file) }</td>
    </tr>
};

declare function xmlconv:validateEnvelope() as element(div) {

    let $envelope := doc($source_url)/envelope
    let $minimumYear := number(xmlconv:getObligationMinMaxYear($envelope)/min)
    let $maximumYear := number(xmlconv:getObligationMinMaxYear($envelope)/max)
    let $xmlFilesWithAQSchema := xmlconv:getAQFiles($source_url)
    let $filesWithAQSchema := $envelope/file[contains(@schema,'AirQualityReporting.xsd') and string-length(@link)>0]

    let $env1 :=
        try {
            let $validCount := count($filesWithAQSchema[@schema = $schemax:SCHEMA])
            return if ($validCount = 0) then
                <tr>
                    <p>Your delivery cannot be accepted as you did not provide any XML file with correct XML Schema location.<br />
                        Valid XML Schema location is: <strong>{$schemax:SCHEMA}</strong></p>
                </tr>
            else if ($validCount != count($xmlFilesWithAQSchema)) then
                <tr class="{$errors:ERROR}">
                    <p>1 or more AQ e-Reporting XML file(s) with incorrect XML Schema location<br />
                        Valid XML Schema location is: <strong>{$schemax:SCHEMA}</strong></p>
                </tr>
            else
                <tr class="{$errors:INFO}">
                    <p>Your delivery contains {$validCount} AQ e-Reporting XML file{substring("s ", number(not($validCount > 1)) * 2)}with correct XML Schema.</p>
                </tr>
        } catch * {
            <tr status="failed">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    let $env2 :=
        try {
            if ($envelope/year[number() != number()])  then
                <tr class="{$errors:ERROR}">
                    <p>Year has not been specified in the envelope period! Keep in mind that the year value must be between {$minimumYear} - {$maximumYear} and it must be equal to the year in gml:beginPosition element (in aqd:AQD_ReportingHeader).</p>
                </tr>
            else if ($envelope/year/number() < $minimumYear or $envelope/year/number() > $maximumYear) then
                <tr class="{$errors:ERROR}">
                    <p>Year specified in the envelope period is outside the allowed range of {$minimumYear} - {$maximumYear}! Keep in mind that the year value must be between {$minimumYear} - {$maximumYear} and it must be equal to the year in gml:beginPosition element (in aqd:AQD_ReportingHeader).</p>
                </tr>
            else
                ()
        } catch * {
            <tr status="failed">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }

    let $env3 :=
        try {
            for $file at $pos in $xmlFilesWithAQSchema
            return
                if (doc-available($file)) then
                    xmlconv:checkFileReportingHeader($envelope, $file, $pos)
                else
                    xmlconv:warningTable($pos, common:getCleanUrl($file))
        } catch * {
            <tr status="failed">
                <td title="Error code">{$err:code}</td>
                <td title="Error description">{$err:description}</td>
            </tr>
        }


    let $errorCount := count($env1[@class = $errors:ERROR]) + count($env2[@class = $errors:ERROR]) + count($env3//tr[@class = $errors:ERROR])
    let $errorLevel :=
        if ($errorCount = 0) then
            $errors:INFO
        else
            $errors:BLOCKER

    let $feedbackMessage :=
        if ($errorCount = 0) then
            "No envelope-level errors found" 
        else
            $errorCount || ' envelope-level error' || substring('s ', number(not($errorCount > 1)) * 2) || 'found'

    return
        <div class="feedbacktext">
            {html:getHead()}
            {html:getCSS()}
            <div class="row column">
                <span id="feedbackStatus" class="{$errorLevel}" style="display:none">{$feedbackMessage}</span>
                <h3>Checked contents of envelope:</h3>
                {$env1}
                {$env2}
                <table class="maintable hover">
                {$env3}
                </table>
                <br/>
                <div class="footnote"><sup>*</sup>Detailed information about the QA/QC rules checked in this routine can be found from the <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a> in chapter "2.1.3 Check for Reporting Header within an envelope".</div>
                {html:getFoot()}
                {html:javaScriptRoot()}
            </div>
        </div>
};

xmlconv:validateEnvelope()