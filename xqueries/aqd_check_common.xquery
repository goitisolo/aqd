module namespace common = "common";


declare namespace base = "http://inspire.ec.europa.eu/schemas/base/3.3";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs = "http://www.w3.org/2000/01/rdf-schema#";
declare namespace adms = "http://www.w3.org/ns/adms#";
declare namespace aqd = "http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0";
declare namespace gml = "http://www.opengis.net/gml/3.2";


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