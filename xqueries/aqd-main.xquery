xquery version "3.0";

(:~
: User: George Sofianos
: Date: 7/26/2016
: Time: 1:41 PM
:)

import module namespace obligations = "http://converters.eionet.europa.eu" at "aqd-obligation.xquery";

declare variable $source_url as xs:string external;
declare option output:method "html";
declare option db:inlinelimit '0';

obligations:proceed($source_url)
