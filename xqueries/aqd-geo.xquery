xquery version "3.0";

(:~
: User: George Sofianos
: Date: 6/17/2016
: Time: 12:03 PM
:)

module namespace geox = "aqd-geo";

declare function geox:getX($point) as xs:string {
  substring-before($point, " ")
};

declare function geox:getY($point) as xs:string {
  substring-after($point, " ")
};