import module namespace obligations = "http://converters.eionet.europa.eu" at "aqd-obligation.xquery";
import module namespace common = "aqd-common" at "aqd-common.xquery";
declare option output:method "html";
declare option db:inlinelimit '0';

let $dir := "C:\Users\dev-gso\Desktop\AQD\test\"
let $files := file:list($dir, true(), "*.xml")
(: Save files at main folder true() or false() :)
let $saveAtMainFolder := true()
(: Re-run checks if result already exists :)
let $replaceResultFiles := true()
for $x in $files
let $url := file:path-to-uri($dir || $x)
let $resultPath :=
    try {
        if ($saveAtMainFolder) then
            $dir || replace(replace($x, "/", "-"), "\\", "-") || ".html"
        else
            $dir || $x || ".html"
    } catch * {
        $dir || "error.html"
    }
let $execute :=
    try {
        if (file:exists($resultPath) and $replaceResultFiles = false()) then
            ()
        else
            file:write($resultPath, obligations:proceed($url))
    } catch * {
        try {
            file:write($resultPath,
                    <tr status="failed">
                        <td title="Error code">{$err:code}</td>
                        <td title="Error description">{$err:description}</td>
                    </tr>
            )
        } catch * {
            ()
        }
    }
return out:format("%s", "Executed script for " || $x) || out:nl()
