xquery version "3.0" encoding "UTF-8";

module namespace common = "aqd-common";

import module namespace html = "aqd-html" at "aqd-html.xquery";
import module namespace vocabulary = "aqd-vocabulary" at "aqd-vocabulary.xquery";
import module namespace dd = "aqd-dd" at "aqd-dd.xquery";
import module namespace functx = "http://www.functx.com" at "functx-1.0-doc-2007-01.xq";
import module namespace errors = "aqd-errors" at "aqd-errors.xquery";

declare namespace base = "http://inspire.ec.europa.eu/schemas/base/3.3";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs = "http://www.w3.org/2000/01/rdf-schema#";
declare namespace adms = "http://www.w3.org/ns/adms#";
declare namespace aqd = "http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0";
declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace xlink = "http://www.w3.org/1999/xlink";

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

(: returns year from aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod
gml:beginPosition
or
gml:timePosition
:)
declare function common:getReportingYear($xml as document-node()) as xs:string {
    let $year1 := if($xml//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:beginPosition castable as xs:dateTime) then  
                    year-from-dateTime($xml//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:beginPosition)
                else
                    ""
    let $year2 := string($xml//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimeInstant/gml:timePosition)
    return
        if (exists($year1) and $year1 castable as xs:integer) then xs:string($year1)
        else if (string-length($year2) > 0 and $year2 castable as xs:integer) then $year2
        else ""
};

(: Transforms local dateTime to UTC dateTime :)
declare function common:getUTCDateTime($dateTime as xs:string) {
    adjust-dateTime-to-timezone(xs:dateTime($dateTime), xs:dayTimeDuration("PT0H"))
};

(: Transforms local date to UTC date :)
declare function common:getUTCDate($dateTime as xs:string) {
    adjust-date-to-timezone(xs:date($dateTime), ())
};

(:~ Returns true if $seq1 contains any element from $seq2 :)
declare function common:containsAny(
    $seq1 as xs:string*,
    $seq2 as xs:string*
) as xs:boolean {
    not(empty(
            for $str in $seq2
            where not(empty(index-of($seq1, $str)))
            return
                true()
    ))
};

(:~ Returns intersection (common elements) of seq1 and seq1 :)
declare function common:getSublist(
    $seq1 as xs:string*,
    $seq2 as xs:string*
) as xs:string* {

    distinct-values(
            for $str in $seq2
            where not(empty(index-of($seq1, $str)))
            return
                $str
    )
};

(:~ Returns a <span> with <a> links for each valid link in given sequence :)
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

(:~ Test if a given value matches a positive number (either integer or decimal)
(with two places after dot)
:)
declare function common:is-a-number(
    $value as xs:anyAtomicType?
) as xs:boolean {
    let $n := string(number($value))
    let $matches := matches($n, "^\d+(\.\d{0,9}?){0,1}$")
    let $positive := number($value) >= 0
    return $matches and $positive
};

declare function common:is-a-number2(
 $value as xs:anyAtomicType? )  as xs:boolean {

   string(number($value)) != 'NaN'
 } ;

declare function common:includesURL($x as xs:string) {
    contains($x, "http://") or contains($x, "https://") or contains($x, "ftp://") or contains($x, "www.")
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
};

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

declare function common:containsAnyNumber($values as xs:string*) as xs:boolean {
    let $result :=
        for $i in $values
        where $i castable as xs:double
        return 1
    return $result = 1
};

(: This is to be used only for dateTimes with <= 1 year difference :)
declare function common:isDateTimeDifferenceOneYear($startDateTime as xs:dateTime, $endDateTime as xs:dateTime) as xs:boolean {
    let $year1 := year-from-dateTime($startDateTime)
    let $year2 := year-from-dateTime($endDateTime)
    (: TODO check again corner cases :)
    let $difference :=
        if (functx:is-leap-year($year1) and $startDateTime < xs:dateTime(concat($year1,"-02-29T24:00:00Z"))
                or functx:is-leap-year($year2) and $endDateTime > xs:dateTime(concat($year2,"-02-29T00:00:00Z"))) then
            8784
        else
            8760
    return
        if (($endDateTime - $startDateTime) div xs:dayTimeDuration("PT1H") = $difference) then
            true()
        else
            false()
};

declare function common:isDateTimeIncluded($reportingYear as xs:string, $beginPosition as xs:dateTime?, $endPosition as xs:dateTime?) {
    let $reportingYearDateTimeStart := xs:dateTime($reportingYear || "-01-01T00:00:00Z")
    let $reportingYearDateTimeEnd := xs:dateTime($reportingYear || "-01-01T00:00:00Z")
    return
        if (empty($endPosition)) then
            if ($reportingYearDateTimeStart >= $beginPosition) then
                true()
            else
                false()
        else if ($endPosition >= $reportingYearDateTimeEnd) then
            if ($reportingYearDateTimeStart >= $beginPosition) then
                true()
            else false()
        else
            false()
};

declare function common:isDateTimeIncludedB11B12($reportingYear as xs:string, $beginPosition as xs:dateTime?, $endPosition as xs:dateTime?) {
    let $reportingYearDateTimeStart := xs:dateTime($reportingYear || "-01-01T00:00:00Z")
    let $reportingYearDateTimeEnd := xs:dateTime($reportingYear || "-12-31T24:00:00Z")
    return
        if (empty($endPosition)) then
            if ($reportingYearDateTimeStart >= $beginPosition) then
                true()
            else
                false()
        else if ($endPosition >= $reportingYearDateTimeEnd) then
                (:if ($reportingYearDateTimeStart >= $beginPosition) then
                    true()
                else false():)
                true()
            else 
             false()
};

declare function common:isDateTimeIncludedB11B12New($reportingYear as xs:string, $beginPosition as xs:dateTime?, $endPosition as xs:dateTime?) {
    let $reportingYearDateTimeStart := xs:dateTime($reportingYear || "-01-01T00:00:00Z")
    let $reportingYearDateTimeEnd := xs:dateTime($reportingYear || "-12-31T24:00:00Z")
    return
        if ($beginPosition <= $reportingYearDateTimeStart) then
            if (empty($endPosition) or ($beginPosition <= $reportingYearDateTimeEnd and $beginPosition >= $reportingYearDateTimeStart)) then
                true()
            else
                false()
        else if ($beginPosition >= $reportingYearDateTimeStart and $beginPosition <= $reportingYearDateTimeEnd) then
                true()
              else 
               false()
};


(: Returns error report for ?0 check :)
declare function common:checkDeliveryReport (
    $errorClass as xs:string,
    $statusMessage as xs:string
) as element(tr) {
    <tr class="{$errorClass}">
        <td title="Status">{$statusMessage}</td>
    </tr>
};

(: Returns structure with error if node is empty :)
(: TODO: test if node doesn't exist :)
declare function common:needsValidString(
    $parent as node()*,
    $nodeName as xs:string,
    $ancestor-name as xs:string
) as element(tr)* {
    let $main := $parent/*[name() = $nodeName]
    for $el in $main
    return try {
        if (string-length(normalize-space($el/text())) = 0)
        then
            <tr>
                <td title="gml:id">{data($el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id)}</td>
                <td title="{$nodeName}">{$nodeName} needs a valid input</td>
            </tr>
        else
            ()
    }  catch * {
        html:createErrorRow($err:code, $err:description)
    }
};

(: Check if the given node links to a term that is defined in the vocabulary :)
declare function common:isInVocabulary(
  $uri as xs:string?,
  $vocabularyName as xs:string
) as xs:boolean {
    let $validUris := dd:getValidConcepts($vocabularyName || "rdf")
    return $uri and $uri = $validUris
};

declare function common:isInVocabularyReport(
  $main as node()+,
  $vocabularyName as xs:string,
  $ancestor-name as xs:string
) as element(tr)* {
    try {
        for $el in $main
            let $uri := $el/@xlink:href
            return
            if (not(common:isInVocabulary($uri, $vocabularyName)))
            then
                <tr>
                    <td title="gml:id">{data($el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id)}</td>
                    <td title="{node-name($el)}"> not conform to vocabulary</td>
                </tr>
            else
                ()
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }
};


(: Type independent method of getting value at index in an array or sequence :)
declare function common:get(
    $seq,
    $index as xs:integer
) {
    if ($seq instance of array(*))
    then
        $seq($index)
    else
        $seq[$index]
};


(:~ Constructs table rows from provided title/value pairs :)
declare function common:conditionalReportRow (
    $ok as xs:boolean,
    $vals as array(item()*)
) as element(tr)* {
    if (not($ok))
    then
        <tr>{
        array:flatten(
            array:for-each($vals, function($row) {
                <td title="{common:get($row, 1)}">
                    {
                    functx:if-empty(
                        data(common:get($row, 2)),
                        "no value provided"
                    )
                    }
                </td>
            })
        )
        }</tr>
    else
        ()
};

declare function common:conditionalReportRowI18 (
    $ok as xs:boolean,
    $vals as array(item()*)
) as element(tr)* {
    if (not($ok))
    then
        <tr>{
        array:flatten(
            array:for-each($vals, function($row) {
                <td title="{common:get($row, 1)}">
                    {
                    functx:if-empty(
                        data(common:get($row, 2)),
                        "Attainment not found"
                    )
                    }
                </td>
            })
        )
        }</tr>
    else
        ()
};

declare function common:conditionalReportRowI21I20I19 (
    $ok as xs:boolean,
    $vals as array(item()*)
) as element(tr)* {
    if (not($ok))
    then
        <tr>{
        array:flatten(
            array:for-each($vals, function($row) {
                <td title="{common:get($row, 1)}">
                    {
                    functx:if-empty(
                        data(common:get($row, 2)),
                        "no data"
                    )
                    }
                </td>
            })
        )
        }</tr>
    else
        ()
};

(: returns if a specific node exists in a parent :)
declare function common:isNodeInParent(
    $parent as node(),
    $nodeName as xs:string
) as xs:boolean {
    exists($parent/*[name() = $nodeName])
};

(: prints error if a specific node does not exist in a parent :)
declare function common:isNodeNotInParentReport(
    $parent as node()*,
    $nodeName as xs:string,
    $ancestor-name as xs:string
) as element(tr)* {
    try {
        for $el in $parent
            return
            if (not(common:isNodeInParent($el, $nodeName)))
            then
                <tr>
                    <td title="gml:id">{data($el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id)}</td>
                    <td title="{$nodeName}"> needs valid input</td>
                </tr>
            else
                ()
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }
};

(: if node has value, then that value should be an integer :)
declare function common:maybeNodeValueIsInteger($el) as xs:boolean {
    (: TODO: is possible to use or :)
    let $v := data($el)
    return
        if (exists($v))
        then
            common:is-a-number($v)
        else
            true()
};

(: prints error if a specific node has value and is not an integer :)
declare function common:maybeNodeValueIsIntegerReport(
    $parent as node()?,
    $nodeName as xs:string,
    $ancestor-name
) as element(tr)* {
    let $el := $parent/*[name() = $nodeName]
    return try {
        if (not(common:maybeNodeValueIsInteger($el)))
        then
            <tr>
                <td title="gml:id">{data($el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id)}</td>
                <td title="{$nodeName}"> needs valid input</td>
            </tr>
        else
            ()
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }
};

(: If node exists, validate it :)
declare function common:validatePossibleNodeValue(
    $el,
    $validator as function(item()) as xs:boolean
) {
    let $v := data($el)
    return
        if (exists($v))
        then
            $validator($v)
        else
            true()
};

(: Prints an error if validation for a possible existing node fails :)
declare function common:validatePossibleNodeValueReport(
    $parent as node()*,
    $nodeName as xs:string,
    $validator as function(item()) as xs:boolean,
    $ancestor-name as xs:string
) {
    let $main := $parent/*[name() = $nodeName]
    for $el in $main
    return try {
        if (not(common:validatePossibleNodeValue($el, $validator)))
        then
            <tr>
                <td title="gml:id"> {data($el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id)}</td>
                <td title="{$nodeName}"> needs valid input</td>
            </tr>
        else
            ()
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }
};


(: Given a node, if it exists, print error based on provided value :)
declare function common:validateMaybeNodeWithValueReport(
    $parent as node()?,
    $nodeName as xs:string,
    $val as xs:boolean,
    $ancestor-name as xs:string
) as element(tr)* {
    let $el := $parent/*[name() = $nodeName]
    return try {
        if (exists($el))
        then
            if (not($val))
            then
                <tr>
                    <td title="gml:id"> {data($el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id)}</td>
                    <td title="{$nodeName}"> needs valid input</td>
                </tr>
            else
                ()
        else
            ()
    } catch * {
        html:createErrorRow($err:code, $err:description)
    }
};

(: Check if a given string is a full ISO date type:)
declare function common:isDateFullISO(
    $date as xs:string?
) as xs:boolean {
    if ($date castable as xs:dateTime)
    then
        true()
    else
        false()
    (:try {
        let $asd := xs:dateTime($date)
        return true()
    } catch *{
        false()
    }:)

};
(: Create report :)
declare function common:isDateFullISOReport(
    $main as node()*,
    $ancestor-name as xs:string
) as element(tr)*
{
    for $el in $main
        let $date := data($el)
        return
        try {
            if (not(common:isDateFullISO($date)))
            then
                <tr>
                    <td title="gml:id">{data($el/ancestor-or-self::*[name() = $ancestor-name]/@gml:id)}</td>
                    <td title="{node-name($el)}">{$date}</td>
                </tr>
            else
                ()
        } catch * {
            html:createErrorRow($err:code, $err:description)
        }
};

declare function common:getYearDaysCount($reportingYear as xs:string) {
    if (functx:is-leap-year($reportingYear)) then
        366
    else
        365
};

declare function common:getYearHoursCount($reportingYear as xs:string) {
    if (functx:is-leap-year($reportingYear)) then
        8784
    else
        8760
};

(:~ returns True if $seq has one one given node :)
declare function common:has-one-node(
    $seq as item()*,
    $item as item()?
) as xs:boolean {
    let $norm-seq :=
        for $x in $seq
        return $x => normalize-space() => lower-case()
    return count(index-of($norm-seq, lower-case(normalize-space($item)))) = 1
};

(: Check if end date is after begin date and if both are in full ISO format:)
declare function common:isEndDateAfterBeginDate(
        $begin as node()?,
        $end as node()?
) as xs:boolean
{
    if(common:isDateFullISO($begin) and common:isDateFullISO($end) and $end > $begin)
    then
        true()
    else
        false()
};

(:~ Returns a sum of numbers contained in nodes :)
declare function common:sum-of-nodes(
    $nodes as item()*
) as xs:double {
    let $numbers :=
        for $n in $nodes
            let $d := data($n)
            let $i :=
                if ($d castable as xs:double)
                then
                    xs:double($d)
                else
                    0
        return $i
    return sum($numbers)
};

(:~ Returns true if the given node has no attributes or children :)
declare function common:has-content(
    $nodes as element()*
) as xs:boolean {
    let $res :=
        for $node in $nodes
            let $attr := empty($node/@*)
            let $children := empty($node/*)
        return $attr or $children
    return exists($nodes) and ($res = true())
};

(:~ Returns true if provided pollutant is one of special values :)
declare function common:is-polutant-air(
    $uri as xs:string
) as xs:boolean {
    let $okv := (
        "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/1",
        "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5",
        "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/10",
        "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001"
        )
    return $uri = $okv
};

declare function common:is-polutant-I40(
    $uri as xs:string
) as xs:boolean {
    let $okv := (
        "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/1",
        "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5",
        "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/10"
        )
    return $uri = $okv
};

(:~ Returns true if provided status is one of special values :)
declare function common:is-status-in-progress(
        $uri as xs:string
) as xs:boolean {
    let $okv := (
        "http://dd.eionet.europa.eu/vocabulary/aq/statusaqplan/preparation",
        "http://dd.eionet.europa.eu/vocabulary/aq/statusaqplan/adoption-process",
        "http://dd.eionet.europa.eu/vocabulary/aq/statusaqplan/under-revision"
    )
    return $uri = $okv
};

(:~ Returns true if provided status is one of special values :)
declare function common:is-status-in-progressH26(
        $uri as xs:string
) as xs:boolean {
    let $okv := (
        "http://dd.eionet.europa.eu/vocabulary/aq/statusaqplan/preparation",
        "http://dd.eionet.europa.eu/vocabulary/aq/statusaqplan/adoption-process",
        "http://dd.eionet.europa.eu/vocabulary/aq/statusaqplan/under-implementation"
    )
    return $uri = $okv
};

(: Given a list of envelopes, returns true if is lates envelope :)
declare function common:isLatestEnvelope(
    $envelopes as xs:string*,
    $latestEnvelopes as xs:string*
) as xs:boolean {
    let $result :=
        for $envelope in $envelopes
            return
            if($envelope = $latestEnvelopes)
            then
                $envelope
            else
                ()
    return exists($result)
};

declare function common:runtime($queryName as xs:string ,$ns1 as xs:double ,$ns2 as xs:double ){

  let $ms := ($ns2 - $ns1)
  let $seconds := $ms div 1000
  return  
  <tr>
    <td> {$queryName}</td>
    <td>{$ms} ms.</td> 
    <td>{$seconds} s.</td>
</tr>
};

