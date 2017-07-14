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

declare function geox:parseDateTime($x as xs:string) {
  if ($x castable as xs:dateTime) then xs:dateTime($x) else
    if ($x castable as xs:date) then xs:dateTime(xs:date($x))
    else $x
};
