import module namespace obligations = "http://converters.eionet.europa.eu" at "aqd-obligation.xquery";
import module namespace common = "aqd-common" at "aqd-common.xquery";
declare option output:method "html";
declare option db:inlinelimit '0';

let $dir := "C:\Users\dev-gso\Desktop\AQD\test\"
let $files := file:list($dir, true(), "*.xml")
for $x in $files
let $url := file:path-to-uri($dir || $x)
let $resultPath := $dir || $x || ".html"
let $execute := file:write($resultPath, obligations:proceed($url))
return out:format("%s", "Executed script for " || $x) || out:nl()