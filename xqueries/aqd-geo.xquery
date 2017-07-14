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
(:~
 : In Europe, lat values tend to be bigger than lon values. We use this observation as a poor farmer's son test to check that in a coordinate value pair,
 : the lat value comes first, as defined in the GML schema)
 : Normally lat should be larger than long
 :)
declare function geox:compareLatLong($srsName as xs:string, $lat as xs:double, $long as xs:double) {
    let $inverseSrs := ("urn:ogc:def:crs:EPSG::3035")
    return
        if ($srsName = $inverseSrs) then
            $long > $lat
        else
            $lat > $long
};