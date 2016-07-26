xquery version "3.0";

(:~
: User: George Sofianos
: Date: 6/14/2016
: Time: 1:36 PM
:)

module namespace test = "http://basex.org/modules/xqunit-tests";
import module namespace common = "aqd-common" at "../aqd-common.xquery";

declare %unit:before-module function test:before-all-tests() {
    trace("Testing filter framework")
};

declare %unit:after-module function test:after-all-tests() {
    trace("End filter framework")
};

declare %unit:test function test:getEnvelopeXML() {
    let $res :=         
        common:getEnvelopeXML("file:///C:\Users\dev-gso\Desktop\AQD\test\a\LU_DataFlowB_2014_Correction_corruptB30_B34.xml")        
    return
        unit:assert($res != "", "File not found")
};
