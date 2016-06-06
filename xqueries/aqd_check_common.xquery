module namespace common = "aqd-common";


declare namespace base = "http://inspire.ec.europa.eu/schemas/base/3.3";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs = "http://www.w3.org/2000/01/rdf-schema#";
declare namespace adms = "http://www.w3.org/ns/adms#";
declare namespace aqd = "http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0";
declare namespace gml = "http://www.opengis.net/gml/3.2";


declare variable $common:SOURCE_URL_PARAM := "source_url=";
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
    let $eu := if ($countryCode='gi') then 'eea' else 'eu'
    return concat("cdr.eionet.europa.eu/",lower-case($countryCode),"/", $eu, "/aqd/")
};

declare function common:getCountryCode($url as xs:string) as xs:string {
    let $envelopeUrl := common:getEnvelopeXML($url)       
    let $countryCode := if(string-length($envelopeUrl)>0) then lower-case(fn:doc($envelopeUrl)/envelope/countrycode) else ""
    let $countryCode := if ($countryCode = "gb") then "uk" else if ($countryCode = "gr") then "el" else $countryCode
    return $countryCode
};


declare function common:checkNamespaces($source_url) {
    let $validStatus := "http://dd.eionet.europa.eu/vocabulary/datadictionary/status/valid"
    let $namespaceUrl := "http://dd.eionet.europa.eu/vocabulary/aq/namespace/"
    let $country := common:getCountryCode($source_url)
    let $vocDoc := doc("http://dd.eionet.europa.eu/vocabulary/aq/namespace/rdf")
    
    let $prefLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $validStatus and @rdf:about = concat($namespaceUrl, $country)]/skos:prefLabel[1]
    let $altLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $validStatus and @rdf:about = concat($namespaceUrl, $country)]/skos:altLabel[1]
    let $invalidNamespaces :=
    for $i in doc($source_url)//base:Identifier/base:namespace/string()
    return
      if (not($i = $prefLabel) and not($i = $altLabel)) then
        $i
      else
        ()
    return distinct-values($invalidNamespaces)
};

declare function common:getReportingYear($xml as document-node()) {
    let $year := year-from-dateTime($xml//aqd:reportingPeriod/gml:TimePeriod/gml:beginPosition)
    return if (exists($year) and $year castable as xs:integer) then xs:integer($year) else ()
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

(:~
 : Checks if XML element is missing or not.
 : @param $node XML node
 : return Boolean value.
 :)
declare function common:isMissing($node as node()*) as xs:boolean {
    if (fn:count($node) = 0) then
        fn:true()
    else
        fn:false()
};
(:~
 : Checks if XML element is missing or value is empty.
 : @param $node XML element or value
 : return Boolean value.
 :)
declare function common:isMissingOrEmpty($node as item()*) as xs:boolean {
    if (common:isMissing($node)) then
        fn:true()
    else
        common:isEmpty(string-join($node, ""))
};
(:~
 : Checks if element value is empty or not.
 : @param $value Element value.
 : @return Boolean value.
 :)
declare function common:isEmpty($value as xs:string) as xs:boolean {
    if (fn:empty($value) or fn:string(fn:normalize-space($value)) = "") then
        fn:true()
    else
        fn:false()
};