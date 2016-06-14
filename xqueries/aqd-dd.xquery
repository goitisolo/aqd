xquery version "3.0";

(:~
: User: George Sofianos
: Date: 6/13/2016
: Time: 5:49 PM
:)

module namespace dd = "aqd-dd";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";

import module namespace vocabulary = "aqd-vocabulary" at "aqd-vocabulary.xquery";

declare function dd:getNameFromPollutantCode($code as xs:string) as xs:string? {
  try {
    let $code := tokenize($code, "/")[last()]
    let $codes := doc(concat($vocabulary:POLLUTANT_VOCABULARY, "/rdf"))    
    let $num := concat($vocabulary:POLLUTANT_VOCABULARY, $code)
    let $name := $codes//skos:Concept[@rdf:about = $num]/string(skos:prefLabel)
    return $name
  } catch * {
    'Error while retrieving document' || $err:code
  }
};
