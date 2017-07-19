xquery version "3.0";

(:~
: User: George Sofianos
: Date: 6/14/2016
: Time: 1:22 PM
:)

module namespace filter = "aqd-filter";

declare function filter:filterByName($results as element(result)*, $elem as xs:string, $string as xs:string*) as element(result)* {
    for $x in $results
    where ($x/*[local-name() = $elem] = $string)
    return $x
};
