xquery version "1.0" encoding "UTF-8";

module namespace envelope = "envelope";

declare function envelope:getEnvelopeXML($url as xs:string) as xs:string{
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
declare function envelope:getCountryCode($url as xs:string) as xs:string {
    let $envelopeUrl := envelope:getEnvelopeXML($url)       
    let $countryCode := if(string-length($envelopeUrl)>0) then lower-case(fn:doc($envelopeUrl)/envelope/countrycode) else ""
    let $countryCode := if ($countryCode = "gb") then "uk" else if ($countryCode = "gr") then "el" else $countryCode
    return $countryCode
};


