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

declare namespace xmlconv="http://converters.eionet.europa.eu/aqd";
declare namespace aqd = "http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0";
declare namespace gml = "http://www.opengis.net/gml/3.2";

(:===================================================================:)
(: Variable given as an external parameter by the QA service:)
(:===================================================================:)

declare variable $source_url as xs:string external;

declare variable $xmlconv:SCHEMA as xs:string := "http://dd.eionet.europa.eu/schemas/id2011850eu-1.0/AirQualityReporting.xsd";

(:~ Separator used in lists expressed as string :)
declare variable $xmlconv:LIST_ITEM_SEP := "##";

(:~ Source file URL parameter name :)
declare variable $xmlconv:SOURCE_URL_PARAM := "source_url=";

(:==================================================================:)
(:==================================================================:)
(:==================================================================:)
(:					QA rules related functions				       :)
(:==================================================================:)
(:==================================================================:)
(:==================================================================:)

(:~
 : Get the cleaned URL without authorisation info
 : @param $url URL of the source XML file
 : @return String
 :)
declare function xmlconv:getCleanUrl($url)
as xs:string
{
    if ( contains($url, $xmlconv:SOURCE_URL_PARAM)) then
        fn:substring-after($url, $xmlconv:SOURCE_URL_PARAM)
    else
        $url
};

(: XMLCONV QA sends the file URL to XQuery engine as source_file paramter value in URL which is able to retreive restricted content from CDR.
   This method replaces the source file url value in source_url parameter with another URL. source_file url must be the last parameter :)
declare function xmlconv:replaceSourceUrl($url as xs:string, $url2 as xs:string) as xs:string{

    if (contains($url,$xmlconv:SOURCE_URL_PARAM)) then
        fn:concat(fn:substring-before($url, $xmlconv:SOURCE_URL_PARAM), $xmlconv:SOURCE_URL_PARAM, $url2)
    else
        $url2
}
;

(: Not documented in QA doc: count only XML files related to AQ e-Reporting :)
declare function xmlconv:getAQFiles($url as xs:string)   {

    for $pn in fn:doc($url)//file[contains(@schema,'AirQualityReporting.xsd') and string-length(@link)>0]
    let $fileUrl := xmlconv:replaceSourceUrl($url, string($pn/@link))
    return
        $fileUrl
}
;

(: QA doc 2.1.3 Check for Reporting Header within an envelope :)
declare function xmlconv:checkFileReportingHeader($envelope as node()*, $file as xs:string, $pos as xs:integer)
{
(:  If AQ e-Reporting XML files in the envelope, at least one must have an aqd:AQD_ReportingHeader element. :)
    let $containsAqdReportingHeader :=
        count(index-of(
                count(doc($file)//aqd:AQD_ReportingHeader) > 0
                , fn:true()
        )) > 0

    (: The aqd:AQD_ReportingHeader must have the same value for year in aqd:reportingPeriod/beginPosition as in the envelope :)
    let $falseTimePeriod :=
        if (count(doc($file)//aqd:AQD_ReportingHeader) > 0 and doc($file)//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:beginPosition/year-from-dateTime(text()) != $envelope/year/number()) then
            true()
        else
            false()

    (: The aqd:AQD_ReportingHeader must include aqd:inspireId, aqd:reportingAuthority, aqd:reportingPeriod and aqd:change elements :)
    let $mandatoryReportingHeaderElements := ("aqd:inspireId", "aqd:reportingAuthority", "aqd:change", "aqd:reportingPeriod")
    let $missingAqdReportingHeaderSubElements :=
        distinct-values(
                for $elem in $mandatoryReportingHeaderElements
                where count(doc($file)//aqd:AQD_ReportingHeader) > 0 and count(doc($file)//aqd:AQD_ReportingHeader/*[name()=$elem and string-length(normalize-space(.)) > 0]) = 0
                return
                    $elem
        )

    (: If aqd:change='true' the following information must also be provided :)
    let $mandatoryAqdChangeElements := ("aqd:changeDescription", "aqd:content")
    let $missingElementsIfAqdChangeIsTrue :=
        distinct-values(
                for $elem in $mandatoryAqdChangeElements
                where count(doc($file)//aqd:AQD_ReportingHeader[aqd:change=true()]) > 0 and count(doc($file)//aqd:AQD_ReportingHeader[
                (aqd:change=true() and count(child::*[name()=$elem]) = 0)]) > 0
                return
                    $elem
        )
    (: If aqd:change='false', then aqd:content IS NOT expected. :)
    let $appearingElementsIfAqdChangeIsFalse :=
        count(index-of(
                count(doc($file)//aqd:AQD_ReportingHeader) > 0 and count(doc($file)//aqd:AQD_ReportingHeader/*[name()='aqd:content' and ../aqd:change=false()]) > 0
                , true()
        )) > 0

    (: set variables for envelope year :)
    let $minimumYear := 2012
    let $maximumYear := 2016

    let $description :=
        if (not($containsAqdReportingHeader)) then
            (<p class="error">The file cannot be accepted as you did not provide any <strong>aqd:AQD_ReportingHeader</strong> element.</p>)
        else
            ()
    (: check for valid year value on XML file :)
    let $description :=
        if ($falseTimePeriod) then
            ($description, <p class="error">Issue with year value of the envelope discovered in relation to this file! The (start) year value must be equal to the year in gml:beginPosition element (in aqd:AQD_ReportingHeader) specified in the XML file and it must be between {$minimumYear} - {$maximumYear}.</p>)
        else
            $description
    let $description :=
        if (count($missingAqdReportingHeaderSubElements) > 0) then
            ($description, <p class="error">The file cannot be accepted as you did not provide <strong>{string-join($missingAqdReportingHeaderSubElements, ',')}</strong>
                element{substring("s ", number(not(count($missingAqdReportingHeaderSubElements) > 1)) * 2)} in aqd:AQD_ReportingHeader element.</p>)
        else
            $description
    let $description :=
        if (count($missingElementsIfAqdChangeIsTrue) > 0) then
            ($description, <p class="error">The file cannot be accepted as you did not provide <strong>{string-join($missingElementsIfAqdChangeIsTrue, ', ')}</strong>
                element{substring("s ", number(not(count($missingElementsIfAqdChangeIsTrue) > 1)) * 2)} in aqd:AQD_ReportingHeader element although aqd:change="true".
                If aqd:change="true", the following information must also be provided: aqd:AQD_ReportingHeader/aqd:changeDescription and aqd:AQD_ReportingHeader/aqd:content</p>)
        else
            $description
    let $description :=
        if ($appearingElementsIfAqdChangeIsFalse) then
            ($description, <p class="error">The file cannot be accepted as you provided <strong>aqd:content</strong>
                in aqd:AQD_ReportingHeader element although aqd:change="false". If aqd:change="false", aqd:content IS NOT expected.</p>)
        else
            $description
    let $description :=
        if (count($description)=0) then
            <p class="info">The file can be accepted. Reporting header element (aqd:AQD_ReportingHeader) is reported correctly<sup>*</sup>.</p>
        else
            $description
    return
        (<p>{$pos}. Checked file: { xmlconv:getCleanUrl($file) }</p>, $description)
};

(: File count logic changed :)
declare function xmlconv:validateEnvelope($url as xs:string)
as element(div)
{
(: set variable for envelope path :)
    let $envelope := doc($url)/envelope

    (: set variables for envelope year :)
    let $minimumYear := 2012
    let $maximumYear := 2016

    (: Count of string values :)
    let $xmlFilesWithAQSchema := xmlconv:getAQFiles($url)
    let $filesCountAQSchema := count($xmlFilesWithAQSchema)

    (: Count of nodes :)
    let $filesWithAQSchema := fn:doc($url)//file[contains(@schema,'AirQualityReporting.xsd') and string-length(@link)>0]
    let $filesCountCorrectSchema := count($filesWithAQSchema[@schema = $xmlconv:SCHEMA])

    let $reportingHeaderCheck :=
        for $file at $pos in $xmlFilesWithAQSchema
        return
            if (doc-available($file)) then
                xmlconv:checkFileReportingHeader($envelope, $file, $pos)
            else
                <p class="warning">{$pos}. File is not available for aqd:AQD_ReportingHeader check: { xmlconv:getCleanUrl($file) }</p>

    let $messageEnvelopeSeparator :=
        <p>Checked contents of envelope:</p>
    let $correctFileCountMessage :=
        if ($filesCountCorrectSchema = 0) then
            (
                <p class="error">Your delivery cannot be accepted as you did not provide any XML file with correct XML Schema location.<br />
                    Valid XML Schema location is: <strong>{$xmlconv:SCHEMA}</strong></p>
            )
        else if ($filesCountCorrectSchema != $filesCountAQSchema) then
            (
                <p class="error">1 or more AQ e-Reporting XML file(s) with incorrect XML Schema location<br />
                    Valid XML Schema location is: <strong>{$xmlconv:SCHEMA}</strong></p>
            )
        else
            (<p class="info">Your delivery contains {$filesCountCorrectSchema} AQ e-Reporting XML file{ substring("s ", number(not($filesCountCorrectSchema > 1)) * 2)}with correct XML Schema.</p>)

    let $correctEnvelopeYear :=
        if ($envelope/year[number() != number()])  then
            <p class="error">Year has not been specified in the envelope period! Keep in mind that the year value must be between {$minimumYear} - {$maximumYear} and it must be equal to the year in gml:beginPosition element (in aqd:AQD_ReportingHeader).</p>
        else if ($envelope/year/number() < $minimumYear or $envelope/year/number() > $maximumYear) then
            <p class="error">Year specified in the envelope period is outside the allowed range of {$minimumYear} - {$maximumYear}! Keep in mind that the year value must be between {$minimumYear} - {$maximumYear} and it must be equal to the year in gml:beginPosition element (in aqd:AQD_ReportingHeader).</p>
        else
            ()
    (: Commented out check for the end year, we might need it in the future

        let $correctEnvelopeYear :=
        if ($envelope/endyear[number() = number()] and ($envelope/endyear/number() < $minimumYear or $envelope/endyear/number() > $maximumYear)) then
            ($correctEnvelopeYear, <p class="error">The end year on the envelope is different than the year given in gml:endPosition element (in aqd:AQD_ReportingHeader) or/and outside the allowed range of {$minimumYear} - {$maximumYear}!</p>)
        else
            $correctEnvelopeYear
        :)

    let $messages := ($messageEnvelopeSeparator, $correctFileCountMessage, $correctEnvelopeYear, $reportingHeaderCheck)

    let $errorCount := count($messages[@class = 'error'])

    let $errorLevel :=
        if ($errorCount = 0)
        then "INFO" else "BLOCKER"

    let $feedbackMessage :=
        if ($errorCount = 0) then
            "No envelope-level errors found" 
        else
            concat($errorCount, ' envelope-level error', substring('s ', number(not($errorCount > 1)) * 2), 'found')

    return
        <div class="feedbacktext">
            <style type="text/css">
                <![CDATA[
                .info {color:blue; margin-left: 15px;}
                .error {color:red; margin-left: 15px;}
                .warning {color:orange; margin-left: 15px;}
                .hidden {display:none}
                .footnote {font-style:italic}
            ]]>
            </style>
            <h2>Check contents of delivery</h2>
            <span id="feedbackStatus" class="{$errorLevel}" style="display:none">{$feedbackMessage}</span>
            {$messages}
            <br/>
            <div class="footnote"><sup>*</sup>Detailed information about the QA/QC rules checked in this routine can be found from the <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a> in chapter "2.1.3 Check for Reporting Header within an envelope".</div>
        </div>

};
declare function xmlconv:buildDocNotAvailableError($url as xs:string)
as element(div)
{
    <div class="feedbacktext">
        <span id="feedbackStatus" class="INFO">Could not execute the script because the source XML is not available: { xmlconv:getCleanUrl($url) }</span>
    </div>

};

(:======================================================================:)
(: Main function calls the different get function and returns the result:)
(:======================================================================:)

declare function xmlconv:proceed($url as xs:string) {

    let $sourceDocAvailable := doc-available($source_url)
    let $results := if ($sourceDocAvailable) then xmlconv:validateEnvelope($source_url) else ()

    return
        if ($sourceDocAvailable) then
            $results
        else
            xmlconv:buildDocNotAvailableError($source_url)
}
;

xmlconv:proceed($source_url)
