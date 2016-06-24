xquery version "3.0";

(:~
: User: George Sofianos
: Date: 6/14/2016
: Time: 1:36 PM
:)

module namespace test = "http://basex.org/modules/xqunit-tests";
import module namespace labels = "aqd-labels" at "../aqd-labels.xquery";

declare %unit:before-module function test:before-all-tests() {
    trace("Testing labels framework")
};

declare %unit:after-module function test:after-all-tests() {
    trace("End labels framework")
};

declare %unit:test function test:labelsInterpolation() {
    let $label := "Country $1 reports this AQR data for year $2"
    let $result := labels:interpolate(label, ("Greece", 2016))
    let $expected := "Country Greece reports this AQR data for year 2016"
    return
        unit:assert($expected, "Interpolation not working")
};
