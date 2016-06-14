xquery version "3.0";

(:~
: User: George Sofianos
: Date: 6/14/2016
: Time: 1:36 PM
:)

module namespace test = "http://basex.org/modules/xqunit-tests";
import module namespace filter = "aqd-filter" at "../aqd-filter.xquery";

declare %unit:before-module function test:before-all-tests() {
  trace("Testing filter framework")
};

declare %unit:after-module function test:after-all-tests() {
  trace("End filter framework")
};

declare %unit:test function test:filterEmptyPollutant() {    
  let $res := 
    filter:filterByName(<results>
            <result>
                <pollutant>test</pollutant>
                <code>test</code>
            </result>
        </results>, "pollutant", "test1")
  return
  unit:assert(empty($res/result), "Expected empty sequence")
};
