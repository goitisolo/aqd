xquery version "3.0";

(:~
: User: George Sofianos
: Date: 7/23/17
: Time: 11:00 PM
:)

import module namespace envelope = "http://converters.eionet.europa.eu/aqd" at "aqd-envelope.xquery";

declare option output:method "html";
declare option db:inlinelimit '0';

declare variable $source_url as xs:string external;

envelope:validateEnvelope($source_url)