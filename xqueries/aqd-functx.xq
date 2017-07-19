xquery version "3.0";

(:~
: User: George Sofianos
: Date: 11/14/16
: Time: 2:00 PM
:)

module namespace functx = "http://www.functx.com";
declare function functx:is-leap-year($date as xs:anyAtomicType?) as xs:boolean {
    for $year in xs:integer(substring(string($date),1,4))
    return ($year mod 4 = 0 and
            $year mod 100 != 0) or
            $year mod 400 = 0
};

declare function functx:escape-for-regex($arg as xs:string?) as xs:string {
    replace($arg, '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
};