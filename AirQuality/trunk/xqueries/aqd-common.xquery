xquery version "3.0" encoding "UTF-8";

module namespace common = "aqd-common";
import module namespace vocabulary = "aqd-vocabulary" at "aqd-vocabulary.xquery";
import module namespace dd = "aqd-dd" at "aqd-dd.xquery";
import module namespace functx = "http://www.functx.com" at "aqd-functx.xq";

declare namespace base = "http://inspire.ec.europa.eu/schemas/base/3.3";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs = "http://www.w3.org/2000/01/rdf-schema#";
declare namespace adms = "http://www.w3.org/ns/adms#";
declare namespace aqd = "http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0";
declare namespace gml = "http://www.opengis.net/gml/3.2";

declare variable $common:SOURCE_URL_PARAM := "source_url=";

(: Lower case equals string :)
declare function common:equalsLC($value as xs:string, $target as xs:string) {
    lower-case($value) = lower-case($target)
};

(:~
 : Get the cleaned URL without authorisation info
 : @param $url URL of the source XML file
 : @return String
 :)
declare function common:getCleanUrl($url) as xs:string {
    if (contains($url, $common:SOURCE_URL_PARAM)) then
        fn:substring-after($url, $common:SOURCE_URL_PARAM)
    else
        $url
};

(: XMLCONV QA sends the file URL to XQuery engine as source_file paramter value in URL which is able to retreive restricted content from CDR.
   This method replaces the source file url value in source_url parameter with another URL. source_file url must be the last parameter :)
declare function common:replaceSourceUrl($url as xs:string, $url2 as xs:string) as xs:string {
    if (contains($url, $common:SOURCE_URL_PARAM)) then
        fn:concat(fn:substring-before($url, $common:SOURCE_URL_PARAM), $common:SOURCE_URL_PARAM, $url2)
    else
        $url2
};

declare function common:getEnvelopeXML($url as xs:string) as xs:string{
    let $col := fn:tokenize($url,'/')
    let $col := fn:remove($col, fn:count($col))
    let $ret := fn:string-join($col,'/')
    let $ret := fn:concat($ret,'/xml')
    return
        if(fn:doc-available($ret)) then
            $ret
        else
            ""
};

declare function common:getCdrUrl($countryCode as xs:string) as xs:string {
    let $countryCode :=
        if ($countryCode = "uk") then
            "gb"
        else if ($countryCode = "el") then
            "gr"
        else
            $countryCode
    let $eu :=
        if ($countryCode='gi') then
            'eea'
        else
            'eu'
    return "cdr.eionet.europa.eu/" || lower-case($countryCode) || "/" || $eu || "/aqd/"
};

declare function common:getReportingYear($xml as document-node()) as xs:string {
    let $year1 := year-from-dateTime($xml//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:beginPosition)
    let $year2 := string($xml//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimeInstant/gml:timePosition)
    return
        if (exists($year1) and $year1 castable as xs:integer) then xs:string($year1)
        else if (string-length($year2) > 0 and $year2 castable as xs:integer) then $year2
        else ""
};

declare function common:containsAny($seq1 as xs:string*, $seq2 as xs:string*) as xs:boolean {
    not(empty(
            for $str in $seq2
            where not(empty(index-of($seq1, $str)))
            return
                true()
    ))
};

declare function common:getSublist($seq1 as xs:string*, $seq2 as xs:string*)
as xs:string* {

    distinct-values(
            for $str in $seq2
            where not(empty(index-of($seq1, $str)))
            return
                $str
    )
};

declare function common:checkLink($text as xs:string*) as element(span)*{
    for $c at $pos in $text
    return
        <span>{
            if (starts-with($c, "http://")) then
                <a href="{$c}">{$c}</a>
            else
                $c
            }{
            if ($pos < count($text)) then
                ", "
            else
                ""
        }</span>
};

declare function common:is-a-number( $value as xs:anyAtomicType? ) as xs:boolean {
    string(number($value)) != 'NaN'
};

declare function common:includesURL($x as xs:string) {
    contains($x, "http://") or contains($x, "https://")
};

declare function common:isInvalidYear($value as xs:string?) {
    let $year := if (empty($value)) then ()
    else
        if ($value castable as xs:integer) then xs:integer($value) else ()

    return
        if ((empty($year) and empty($value)) or (not(empty($year)) and $year > 1800 and $year < 9999)) then fn:false() else fn:true()

};
declare function common:if-empty($first as item()?, $second as item()?) as item()* {
    if (not(data($first) = '')) then
        data($first)
    else
        data($second)
} ;

(: This is to be used only for dates with <= 1 year difference :)
declare function common:isDateDifferenceOverYear($startDate as xs:date, $endDate as xs:date) as xs:boolean {
    let $year1 := year-from-date($startDate)
    let $year2 := year-from-date($endDate)
    let $difference :=
        if (functx:is-leap-year($year1) and $startDate < xs:date(concat($year1,"-02-29"))
                or functx:is-leap-year($year2) and $endDate > xs:date(concat($year2,"-02-29"))) then
            366
        else
            365
    return
        if (($endDate - $startDate) div xs:dayTimeDuration("P1D") > $difference) then
            true()
        else
            false()
};

(: This is to be used only for dateTimes with <= 1 year difference :)
declare function common:isDateTimeDifferenceOneYear($startDateTime as xs:dateTime, $endDateTime as xs:dateTime) as xs:boolean {
    let $year1 := year-from-dateTime($startDateTime)
    let $year2 := year-from-dateTime($endDateTime)
    (: TODO check again corner cases :)
    let $difference :=
        if (functx:is-leap-year($year1) and $startDateTime < xs:dateTime(concat($year1,"-02-29T24:00:00"))
                or functx:is-leap-year($year2) and $endDateTime > xs:dateTime(concat($year2,"-02-29T00:00:00"))) then
            8784
        else
            8760
    return
        if (($endDateTime - $startDateTime) div xs:dayTimeDuration("PT1H") = $difference) then
            true()
        else
            false()
};