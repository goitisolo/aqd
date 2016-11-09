xquery version "3.0";

(:~
: User: George Sofianos
: Date: 7/26/2016
: Time: 1:41 PM
:)

import module namespace obligations = "http://converters.eionet.europa.eu" at "aqd-obligation.xquery";

declare variable $source_url as xs:string external;
declare option db:inlinelimit '0';

let $file := "/home/dev-gso/Desktop/output.html"
let $result := file:write($file, obligations:proceed($source_url), map { "method": "html"})
return out:format("%s", "XQuery script Completed, please check: " || $file)