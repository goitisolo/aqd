xquery version "1.0";
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
 :)


declare namespace xmlconv="http://converters.eionet.europa.eu/aqd";
declare namespace aqd = "http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0";
(:===================================================================:)
(: Variable given as an external parameter by the QA service:)
(:===================================================================:)
(:
declare variable $source_url as xs:string external;
http://cdrtest.eionet.europa.eu/ee/eu/colujh9jw/envujh9qa/xml
http://cdr.eionet.europa.eu/at/eu/aqd/d/envvbbjdw/xml
:)
declare variable $source_url as xs:string external;

declare variable $xmlconv:SCHEMA as xs:string := "http://dd.eionet.europa.eu/schemas/id2011850eu-1.0/AirQualityReporting.xsd";
declare variable $xmlconv:SCHEMA2 as xs:string := "http://dd.eionet.europa.eu/schemas/id2011850eu-1.0/AirQualityReporting.xsd http://schemas.opengis.net/sweCommon/2.0/swe.xsd";
declare variable $xmlconv:SCHEMA3 as xs:string := "http://dd.eionet.europa.eu/schemas/id2011850eu-1.0/AirQualityReporting.xsd http://schemas.opengis.net/sweCommon/2.0/swe.xsd http://schemas.opengis.net/gml/3.2.1/gml.xsd";
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


declare function xmlconv:getFiles($url as xs:string)   {

    for $pn in fn:doc($url)//file[(@schema = $xmlconv:SCHEMA or @schema = $xmlconv:SCHEMA2 or @schema = $xmlconv:SCHEMA3) and string-length(@link)>0]
        let $fileUrl := xmlconv:replaceSourceUrl($url, string($pn/@link))
        return
            $fileUrl
}
;

(: QA doc 2.1.3 Check for Reporting Header within an envelope – NEW – VERY IMPORTANT :)
declare function xmlconv:checkFileReportingHeader($file as xs:string, $pos as xs:integer)
{
(:  At least one XML file in the envelope must have an aqd:AQD_ReportingHeader element. :)
    let $containsAqdReportingHeader :=
        count(index-of(
            count(doc($file)//aqd:AQD_ReportingHeader) > 0
                , fn:true()
        )) > 0

    (: The aqd:AQD_ReportingHeadear must include aqd:inspireId, aqd:reportingAuthority, aqd:reportingPeriod and aqd:change elements, "aqd:reportingPeriod" :)
    let $mandatoryReportingHeaderElements := ("aqd:inspireId", "aqd:reportingAuthority", "aqd:change")
    let $missingAqdReportingHeaderSubElements :=
        distinct-values(
                    for $elem in $mandatoryReportingHeaderElements
                    where count(doc($file)//aqd:AQD_ReportingHeader) > 0 and count(doc($file)//aqd:AQD_ReportingHeader/*[name()=$elem and string-length(normalize-space(.)) > 0]) = 0
                    return
                        $elem
        )

    (: If aqd:change=”true”, the following information must also be provided:)
    let $mandatoryAqdChangeElements := ("aqd:changeDescription", "aqd:content")
    let $missingElementsIfAqdChangeIsTrue :=
        distinct-values(
                    for $elem in $mandatoryAqdChangeElements
                    where count(doc($file)//aqd:AQD_ReportingHeader[aqd:change=true()]) > 0 and count(doc($file)//aqd:AQD_ReportingHeader[
                        (aqd:change=true() and count(child::*[name()=$elem]) = 0)]) > 0
                    return
                        $elem
        )
    (: If aqd:change=”false”, aqd:content IS NOT expected. :)
    let $appearingElementsIfAqdChangeIsFalse :=
        count(index-of(
                    count(doc($file)//aqd:AQD_ReportingHeader) > 0 and count(doc($file)//aqd:AQD_ReportingHeader/*[name()='aqd:content' and ../aqd:change=false()]) > 0
                , true()
        )) > 0


    let $description :=
        if (not($containsAqdReportingHeader)) then
            (<p class="error">The file cannot be accepted as you did not provide any <strong>aqd:AQD_ReportingHeader</strong> element.</p>)
        else
            ()
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
                If aqd:change="true", the following information must also be provided: aqd:AQD_ReportingHeadear/aqd:changeDescription and aqd:AQD_ReportingHeadear/aqd:content</p>)
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

declare function xmlconv:validateEnvelope($url as xs:string)
as element(div)
{
    let $files := fn:doc($url)//file[string-length(@link)>0]
    let $xmlFilesWithValidSchema := xmlconv:getFiles($url)

    let $filesCountAll := count($files)
    let $filesCountCorrectSchema := count($files[@schema = $xmlconv:SCHEMA or @schema = $xmlconv:SCHEMA2 or @schema = $xmlconv:SCHEMA3])

    let $reportingHeaderCheck :=
        for $file at $pos in $xmlFilesWithValidSchema
        return
            if (doc-available($file)) then
                xmlconv:checkFileReportingHeader($file, $pos)
            else
                <p>{$pos}. File is not available for QA: { xmlconv:getCleanUrl($file) }</p>

    let $errorLevel :=
        if ($filesCountCorrectSchema > 0 and count($reportingHeaderCheck//p[class="error"])=0)
        then "INFO" else "BLOCKER"

    let $correctFileCountMessage :=
        if ($filesCountCorrectSchema = 0) then
            (<div>
                <p class="error">Your delivery cannot be accepted as you did not provide any XML files with correct XML Schema location.</p>
                <p>Valid XML Schema location is: {$xmlconv:SCHEMA2}</p>
            </div>)
        else
            (<span>Your delivery contains {$filesCountCorrectSchema} XML file{ substring("s ", number(not($filesCountCorrectSchema > 1)) * 2)}with correct XML Schema.</span>)

    let $messages := ($correctFileCountMessage, $reportingHeaderCheck)
    return
    <div class="feedbacktext">
        <style type="text/css">
            <![CDATA[
                .info {color:blue; margin-left: 15px;}
                .error {color:red; margin-left: 15px;}
                .hidden {display:none}
                .footnote {font-style:italic}
            ]]>
        </style>
        <h2>Check contents of delivery</h2>
        <span id="feedbackStatus" class="hidden">
            {$errorLevel}
        </span>{
            $messages
        }
        <br/>
        <div class="footnote"><sup>*</sup>Detailed information about the QA/QC rules checked in this routine can be found from the <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a> in chapter "2.1.3 Check for Reporting Header within an envelope".</div>
    </div>

};
declare function xmlconv:buildDocNotAvailableError($url as xs:string)
as element(div)
{
    <div class="feedbacktext">
        Could not execute the script because the source XML is not available: { xmlconv:getCleanUrl($url) }
    </div>

};

(:===================================================================:)
(: Main function calls the different get function and returns the result:)
(:===================================================================:)

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
