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
 :)

(: Dataflow B script - Zones :)
import module namespace dfB = "http://converters.eionet.europa.eu/dataflowB" at "aqd_check_zones-1.0.xquery";
(: Dataflow C script - Assessment regimes :)
import module namespace dfC = "http://converters.eionet.europa.eu/dataflowC" at "aqd_check_c-1.0.xquery";
(: Dataflow D script -  :)
import module namespace dfD = "http://converters.eionet.europa.eu/dataflowD" at "aqd_check_d-1.0.xquery";
(: Dataflow G script -  :)
import module namespace dfG = "http://converters.eionet.europa.eu/dataflowG" at "aqd_check_g-1.0.xquery";
(: Dataflow M script -  :)
import module namespace dfM = "http://converters.eionet.europa.eu/dataflowM" at "aqd_check_m-1.0.xquery";

declare namespace xmlconv = "http://converters.eionet.europa.eu";

(:===================================================================:)
(: Variable given as an external parameter by the QA service                                                 :)
(:===================================================================:)

declare variable $source_url as xs:string external;

(:
declare variable $source_url as xs:string external;
declare variable $source_url as xs:string := "";
declare variable $source_url as xs:string := "../test/HR_G_201407281307.xml";
B
http://cdrtest.eionet.europa.eu/es/eu/aqd/b/envveunkq/ES_B_Zones.xml
C
http://cdrtest.eionet.europa.eu/es/eu/aqd/c/envvfnnpg/ES_C_AssessmentRegime_period_chngd.xml
declare variable $source_url as xs:string := "../test/ES_C_AssessmentRegime_period_chngd.xml";
D
http://cdrtest.eionet.europa.eu/es/eu/aqd/d/envvcqwog/ES_D_SamplingPoint.xml
declare variable $source_url as xs:string := "../test/ES_D_SamplingPoint-1.xml";
declare variable $source_url as xs:string := "../test/ES_D_SamplingPoint-2.xml";

G
declare variable $source_url as xs:string := "../test/ES_G_Attainment.xml";
http://cdrtest.eionet.europa.eu/es/eu/aqd/g/envvbgwea/ES_G_Attainment.xml
http://cdrtest.eionet.europa.eu/es/eu/aqd/g/envvbgwea/ES_G_Attainment.xml
M
http://cdrtest.eionet.europa.eu/es/eu/aqd/d/envvcqwog/ES_D_Model.xml
declare variable $source_url as xs:string := "../test/ES_D_Model.xml";
:)
declare variable $xmlconv:ROD_PREFIX as xs:string := "http://rod.eionet.europa.eu/obligations/";
declare variable $xmlconv:B_OBLIGATIONS as xs:string* := (concat($xmlconv:ROD_PREFIX, "670"), concat($xmlconv:ROD_PREFIX, "693"));
declare variable $xmlconv:C_OBLIGATIONS as xs:string* := (concat($xmlconv:ROD_PREFIX, "671"), concat($xmlconv:ROD_PREFIX, "694"));
declare variable $xmlconv:D_OBLIGATIONS as xs:string* := (concat($xmlconv:ROD_PREFIX, "672"));
declare variable $xmlconv:M_OBLIGATIONS as xs:string* := (concat($xmlconv:ROD_PREFIX, "672"));
declare variable $xmlconv:G_OBLIGATIONS as xs:string* := (concat($xmlconv:ROD_PREFIX, "679"));

declare variable $xmlconv:SOURCE_URL_PARAM := "source_url=";

(:~
: JavaScript
:)
declare function xmlconv:javaScript(){

    let $js :=
        <script type="text/javascript">
            <![CDATA[
    function showLegend(){
        document.getElementById('legend').style.display='inline';
        document.getElementById('legendLink').style.display='none';
    }
    function hideLegend(){
        document.getElementById('legend').style.display='none';
        document.getElementById('legendLink').style.display='inline';
    }
    function toggle(divName, linkName, checkId) {{
         toggleItem(divName, linkName, checkId, 'record');
    }}

   function toggleItem(divName, linkName, checkId, itemLabel) {{
        divName = divName + "-" + checkId;
        linkName = linkName + "-" + checkId;

        var elem = document.getElementById(divName);
        var text = document.getElementById(linkName);
        if(elem.style.display == "inline") {{
            elem.style.display = "none";
            text.innerHTML = "Show " + itemLabel + "s";
            }}
            else {{
              elem.style.display = "inline";
              text.innerHTML = "Hide " + itemLabel + "s";
            }}
      }}

      function toggleComb(divName, linkName, checkId, itemLabel) {{
        divName = divName + "-" + checkId;
        linkName = linkName + "-" + checkId;

        var elem = document.getElementById(divName);
        var text = document.getElementById(linkName);
        if(elem.style.display == "inline") {{
            elem.style.display = "none";
            text.innerHTML = "Show " + itemLabel + "s";
            }}
            else {{
              elem.style.display = "inline";
              text.innerHTML = "Hide " + itemLabel + "s";
            }}
      }}

                ]]>
        </script>
    return
        <script type="text/javascript">{normalize-space($js)}</script>
};

(: removes the file part from the end of URL and appends 'xml' for getting the envelope xml description :)
declare function xmlconv:getEnvelopeXML($url as xs:string) as xs:string{

    let $col := fn:tokenize($url,'/')
    let $col := fn:remove($col, fn:count($col))
    let $ret := fn:string-join($col,'/')
    let $ret := fn:concat($ret,'/xml')
    return
        if(fn:doc-available($ret)) then
            $ret
        else
            ""
(:              "http://cdrtest.eionet.europa.eu/ee/eu/art17/envriytkg/xml" :)
}
;
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

declare function xmlconv:containsAny($seq1 as xs:string*, $seq2 as xs:string*)
as xs:boolean {

    not(empty(
        for $str in $seq2
        where not(empty(index-of($seq1, $str)))
        return
            true()
    ))
};

declare function xmlconv:getSublist($seq1 as xs:string*, $seq2 as xs:string*)
as xs:string* {

    distinct-values(
            for $str in $seq2
            where not(empty(index-of($seq1, $str)))
            return
                $str
    )
};
declare function xmlconv:proceed($source_url as xs:string) {

    (: get reporting obligation & country :)
    let $envelopeUrl := xmlconv:getEnvelopeXML($source_url)
    let $obligations := if(string-length($envelopeUrl)>0) then fn:doc($envelopeUrl)/envelope/obligation else ()
    let $countryCode := if(string-length($envelopeUrl)>0) then lower-case(fn:doc($envelopeUrl)/envelope/countrycode) else ""
    let $countryCode := if ($countryCode = "gb") then "uk" else if ($countryCode = "gr") then "el" else $countryCode

    (: FIXME - testing properties +++++++++++++++++++  :)
    (:
    let $obligations := $xmlconv:B_OBLIGATIONS
    let $countryCode := "ES"
:)
    (: END - testing properties -------------------  :)

    let $validObligations := xmlconv:getSublist($obligations,
            ($xmlconv:B_OBLIGATIONS, $xmlconv:C_OBLIGATIONS, $xmlconv:D_OBLIGATIONS, $xmlconv:G_OBLIGATIONS, $xmlconv:M_OBLIGATIONS))

    let $result := ()
    let $resultB :=
        if (xmlconv:containsAny($obligations, $xmlconv:B_OBLIGATIONS)) then
            dfB:proceed($source_url, $countryCode)
        else
            ()
    let $resultC :=
        if (xmlconv:containsAny($obligations, $xmlconv:C_OBLIGATIONS)) then
            dfC:proceed($source_url, $countryCode)
        else
            ()
    let $resultD :=
        if (xmlconv:containsAny($obligations, $xmlconv:D_OBLIGATIONS)) then
            dfD:proceed($source_url, $countryCode)
        else
            ()
    let $resultG :=
        if (xmlconv:containsAny($obligations, $xmlconv:G_OBLIGATIONS)) then
            dfG:proceed($source_url, $countryCode)
        else
            ()
    let $resultM :=
        if (xmlconv:containsAny($obligations, $xmlconv:M_OBLIGATIONS)) then
            dfM:proceed($source_url, $countryCode)
        else
            ()


return
        <div class="feedbacktext">
            <p>Checked XML file: <a href="{xmlconv:getCleanUrl($source_url)}">{xmlconv:getCleanUrl($source_url)}</a></p>
            {
            if (empty($validObligations)) then
                <p>Nothing to check - the envelope is not attached to any of the Air Quiality obligation where QA script is available.</p>
            else
                <div>
                    {xmlconv:javaScript()}
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
                    {$resultB}
                    {$resultC}
                    {$resultD}
                    {$resultG}
                    {$resultM}
                </div>
            }
        </div>
};
xmlconv:proceed( $source_url )
