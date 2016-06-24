xquery version "3.0";

(:~
: User: George Sofianos
: Date: 6/14/2016
: Time: 1:36 PM
:)

module namespace test = "http://basex.org/modules/xqunit-tests";
import module namespace html = "aqd-html" at "../aqd-html.xquery";

declare %unit:before-module function test:before-all-tests() {
  trace("Testing html framework")
};

declare %unit:after-module function test:after-all-tests() {
  trace("End html framework")
};

declare %unit:test function test:modalInfo() {
  let $res :=
    html:getModalInfo("T1", "Modal test")
    return
      unit:assert($res != "", "Expected modal")
};