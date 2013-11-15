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
(:===================================================================:)
(: Variable given as an external parameter by the QA service:)
(:===================================================================:)
(:
declare variable $source_url as xs:string :='http://cdr.eionet.europa.eu/dk/eu/aqd/b/envumeiyg/xml';
declare variable $source_url as xs:string external;

:)
declare variable $source_url as xs:string :='http://cdr.eionet.europa.eu/dk/eu/aqd/b/envumeiyg/xml';

declare variable $SCHEMA as xs:string := "http://dd.eionet.europa.eu/schemas/id2011850eu/AirQualityReporting.xsd";
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


declare function xmlconv:getFiles($url as xs:string, $schema as xs:string)   {

    for $pn in fn:doc($url)//file[@schema = $schema and string-length(@link)>0]
        let $fileUrl := xmlconv:replaceSourceUrl($url, string($pn/@link))
        where doc-available($fileUrl)
        return
            $fileUrl
}
;

declare function xmlconv:validateEnvelope($url as xs:string)
as element(div)
{
    let $files := fn:doc($url)//file[string-length(@link)>0]

    let $filesCountAll := count($files)
    let $filesCountCorrectSchema := count($files[@schema = $SCHEMA])
(:    let $filesCountXml := count($files[@type="text/xml"]):)

    let $errorLevel := if ($filesCountCorrectSchema > 0) then "INFO" else "BLOCKER"

    let $description :=
        if ($filesCountCorrectSchema = 0) then
            <span>Your delivery cannot be accepted as you did not provide any XML files with correct XML Schema.</span>
        else
            <span>Your delivery contains {$filesCountCorrectSchema} XML file{ substring("s ", number(not($filesCountCorrectSchema > 1)) * 2)}with correct XML Schema.</span>
    return
    <div class="feedbacktext">
        <h2>Check contents of delivery</h2>
        <span id="feedbackStatus" class="{$errorLevel}" style="display:none">
            {$description}
        </span>
        {
        if ($errorLevel = "BLOCKER") then
            <p><span style="color:red">{ $description }</span></p>
        else
            <p style="color:blue;font-size:1.1em;">{ $description }</p>
        }
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
