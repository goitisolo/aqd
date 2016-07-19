xquery version "3.0";

(:~
: User: George Sofianos
: Date: 6/13/2016
: Time: 5:49 PM
:)

module namespace dd = "aqd-dd";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace adms="http://www.w3.org/ns/adms#";
declare namespace rdfs="http://www.w3.org/2000/01/rdf-schema#";
declare namespace dctype="http://purl.org/dc/dcmitype/";
declare namespace owl="http://www.w3.org/2002/07/owl#";
declare namespace dcterms="http://purl.org/dc/terms/";
declare namespace prop = "http://dd.eionet.europa.eu/property/";

import module namespace vocabulary = "aqd-vocabulary" at "aqd-vocabulary.xquery";

declare variable $dd:VALIDRESOURCE := "http://dd.eionet.europa.eu/vocabulary/datadictionary/status/valid";
declare variable $dd:VALIDPOLLUTANTS as xs:string* := dd:getValidPollutants();

declare function dd:getNameFromPollutantCode($code as xs:string) as xs:string? {
    let $code := tokenize($code, "/")[last()]
    let $codes := doc(concat($vocabulary:POLLUTANT_VOCABULARY, "/rdf"))    
    let $num := concat($vocabulary:POLLUTANT_VOCABULARY, $code)
    let $name := $codes//skos:Concept[@rdf:about = $num]/string(skos:prefLabel)
    return $name
};

declare function dd:getValidPollutants() as xs:string* {
    let $codes := doc(concat($vocabulary:POLLUTANT_VOCABULARY, "/rdf"))
    let $validCodes := $codes//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE]/string(@rdf:about)
    return $validCodes
};

declare function dd:getValidConcepts($url as xs:string) as xs:string* {    
    data(doc($url)//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE]/@rdf:about)
};

(: Lower case version :)
declare function dd:getValidConceptsLC($url as xs:string) as xs:string* {
    data(doc($url)//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE]/lower-case(@rdf:about))
};

declare function dd:getRecommendedUnit($pollutant as xs:string) as xs:string* {
    data(doc($vocabulary:POLLUTANT_VOCABULARY || "rdf")//skos:Concept[@rdf:about = $pollutant and adms:status/@rdf:resource = $dd:VALIDRESOURCE]/prop:recommendedUnit/@rdf:resource)
};