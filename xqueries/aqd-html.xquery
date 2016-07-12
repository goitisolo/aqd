xquery version "3.0";

(:~
: 
: User: George Sofianos
: Date: 5/31/2016
: Time: 11:48 AM
:)

module namespace html = "aqd-html";
import module namespace labels = "aqd-labels" at "aqd-labels.xquery";
import module namespace errors = "aqd-errors" at "aqd-errors.xquery";

declare function html:getHead() as element()* {  
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/foundation/6.2.3/foundation.min.css">&#32;</link>
};

declare function html:getCSS() as element(style) {
    <style>
        <![CDATA[
        .bullet {
            font-size: 0.8em;
            color: white;
            padding-left:5px;
            padding-right:5px;
            margin-right:5px;
            margin-top:2px;
            text-align:center;
            width: 5%;
        }
        .maintable > tbody > tr > th {
            text-align:left;
            width: 75%;
        }
        .maintable > tbody > tr {
            border-top:1px solid #666666;
        }
        .aaaa {
            padding-left:10px;
        }
        .datatable {
            font-size: 0.9em;
            text-align:left;
            vertical-align:top;
            display:none;
            border:0px;
        }
        .datatable > tbody > tr {
            font-size: 0.9em;
            color:#666666;
        }
        .smalltable {
            display:none;
        }
        .smalltable > tbody > tr {
             font-size: 0.9em;
             color:grey;
        }
        .smalltable > tbody > td {
            font-style:italic;
            vertical-align:top;
        }
        .header {
            text-align:right;
            vertical-align:top;
            background-color:#F6F6F6;
            font-weight: bold;
        }
        .resultTD {

        }
        .largeText {
            font-size:1.3em;
        }
        ]]>
    </style>
};

declare function html:getFoot() as element()* {
    (<script src="https://cdn.jsdelivr.net/jquery/2.2.4/jquery.min.js">&#32;</script>,
    <script src="https://cdn.jsdelivr.net/foundation/6.2.3/foundation.min.js">&#32;</script>,
    <script type="text/javascript">
        $(document).foundation();
    </script>)
};

declare function html:getModalInfo($ruleCode, $longText) as element()* {
    (<span><a class="largeText" data-open="{concat('text-modal-', $ruleCode)}">&#8520;</a></span>,
    <div class="reveal" id="{concat('text-modal-', $ruleCode)}" data-reveal="">
        <h4>{$ruleCode}</h4>
        <hr>&#32;</hr>
        <p>{$longText}</p>
        <button class="close-button" data-close="" aria-label="Close modal" type="button">x</button>
    </div>)
};


declare function html:getBullet($text as xs:string, $level as xs:string) as element(div) {
    let $color :=
        switch ($level)
        case $errors:FAILED return $errors:COLOR_FAILED
        case $errors:ERROR return $errors:COLOR_ERROR
        case $errors:WARNING return $errors:COLOR_WARNING
        case $errors:SKIPPED return $errors:COLOR_SKIPPED
        default return $errors:COLOR_INFO
    return
        <div class="{$level}" style="background-color: { $color };">{ $text }</div>
};

declare function html:buildInfoTR($text as xs:string) as element(tr) {
    <tr>
        <th colspan="4">{$text}</th>
    </tr>
};

(: JavaScript :)
declare function html:javaScriptRoot(){

    let $js :=
        <script type="text/javascript">
            <![CDATA[
    function showLegend(){
        document.getElementById('legend').style.display='table';
        document.getElementById('legendLink').style.display='none';
    }
    function hideLegend(){
        document.getElementById('legend').style.display='none';
        document.getElementById('legendLink').style.display='table';
    }
    function toggle(divName, linkName, checkId) {{
         toggleItem(divName, linkName, checkId, 'record');
    }}

   function toggleItem(divName, linkName, checkId, itemLabel) {{
        divName = divName + "-" + checkId;
        linkName = linkName + "-" + checkId;

        var elem = document.getElementById(divName);
        var text = document.getElementById(linkName);
        if(elem.style.display == "table") {{
            elem.style.display = "none";
            text.innerHTML = "Show " + itemLabel + "s";
            }}
            else {{
              elem.style.display = "table";
              text.innerHTML = "Hide " + itemLabel + "s";
            }}
      }}

      function toggleComb(divName, linkName, checkId, itemLabel) {{
        divName = divName + "-" + checkId;
        linkName = linkName + "-" + checkId;

        var elem = document.getElementById(divName);
        var text = document.getElementById(linkName);
        if(elem.style.display == "table") {{
            elem.style.display = "none";
            text.innerHTML = "Show " + itemLabel + "s";
            }}
            else {{
              elem.style.display = "table";
              text.innerHTML = "Hide " + itemLabel + "s";
            }}
      }}

            ]]>
        </script>
    return
        <script type="text/javascript">{normalize-space($js)}</script>
};
declare function html:buildExists($ruleCode as xs:string, $longText, $text, $records as element(tr)*, $validMessage as xs:string, $invalidMessage as xs:string, $errorLevel as xs:string) {
    let $countRecords := count($records)
    let $bulletType :=
        if (count($records) = 0) then
            $errors:INFO
        else
            $errorLevel
    let $message :=
        if ($bulletType = $errors:INFO) then
            $validMessage
        else
            $invalidMessage

    let $result :=
        <tr>
            <td class="bullet">{html:getBullet($ruleCode, $bulletType)}</td>
            <th colspan="2">{$text} {html:getModalInfo($ruleCode, $longText)}</th>
            <td><span class="largeText">{$message}</span></td>
        </tr>

    return $result
};
declare function html:buildSimple($ruleCode as xs:string, $longText, $text, $records as element(tr)*, $message as xs:string, $unit as xs:string, $errorLevel as xs:string) {
    let $countRecords := count($records)
    let $message :=
        if ($countRecords = 0) then
            "No records found"
        else if ($message) then
            $message
        else
            $countRecords || " " || $unit || substring("s ", number(not($countRecords > 1)) * 2) || " found"
    let $bulletType := $errorLevel
    return html:buildGeneric($ruleCode, $longText, $text, $records, $message, $unit, $bulletType)
};
declare function html:build0($ruleCode as xs:string, $longText, $text, $records as element(tr)*, $valueHeading as xs:string, $validMsg as xs:string, $unit as xs:string) {
    let $countRecords := count($records)
    let $bulletType :=
        if (count($records) = 0) then
            $errors:SKIPPED
        else
            $errors:INFO
    let $message :=
        if ($bulletType = $errors:SKIPPED) then
            "No records found"
        else
            $countRecords || " " || $unit || substring("s ", number(not($countRecords > 1)) * 2) || " found"

        return html:buildGeneric($ruleCode, $longText, $text, $records, $message, $unit, $bulletType)
};
declare function html:build1($ruleCode as xs:string, $longText, $text, $records as element(tr)*, $valueHeading as xs:string, $validMsg as xs:string, $unit as xs:string, $skippedMsg, $errorLevel as xs:string) as element(tr)* {
    let $countRecords := count($records)
    let $bulletType :=
        if (string-length($skippedMsg) > 0) then
            $errors:SKIPPED
        else if (count($records) > 0) then
            $errors:INFO
        else
            $errorLevel
    let $message :=
        if (string-length($skippedMsg) > 0) then
            $skippedMsg
        else if ($countRecords > 0) then
            $validMsg
        else
            $countRecords || " " || $unit || " found"
    return html:buildGeneric($ruleCode, $longText, $text, $records, $validMsg, $unit, $bulletType)
};
declare function html:build2($ruleCode as xs:string, $longText, $text, $records as element(tr)*, $valueHeading as xs:string, $validMsg as xs:string, $unit as xs:string, $skippedMsg, $errorLevel as xs:string) as element(tr)* {
    let $countRecords := count($records)
    let $bulletType :=
        if (string-length($skippedMsg) > 0) then
            $errors:SKIPPED
        else if (count($records) = 0) then
            $errors:INFO
        else
            $errorLevel
    let $message :=
        if (string-length($skippedMsg) > 0) then
            $skippedMsg
        else if ($countRecords = 0) then
            $validMsg
        else
            $countRecords || " " || $unit || substring("s ", number(not($countRecords > 1)) * 2) || " found"
    return html:buildGeneric($ruleCode, $longText, $text, $records, $message, $unit, $bulletType)
};
declare function html:build9($ruleCode as xs:string, $longText, $text, $records as element(tr)*, $valueHeading as xs:string, $validMsg as xs:string, $unit as xs:string, $skippedMsg, $errorLevel as xs:string) as element(tr)* {
    let $countRecords := count($records)
    let $countInvalid := count($records/@valid = "false")
    let $bulletType :=
        if ($countRecords = 0) then
            $errors:SKIPPED
        else if ($countInvalid > 0) then
            $errorLevel
        else
            $errors:INFO
    let $message :=
        if ($countRecords = 0) then
            $skippedMsg
        else if ($countInvalid > 0) then
            $countInvalid || " " || $unit || substring("s ", number(not($countRecords > 1)) * 2) || " found"
        else
            $validMsg
    return html:buildGeneric($ruleCode, $longText, $text, $records, $message, $unit, $bulletType)
};
declare function html:build7($ruleCode as xs:string, $longText, $text, $records as element(tr)*, $valueHeading as xs:string, $validMsg as xs:string, $unit as xs:string, $skippedMsg, $errorLevel as xs:string) as element(tr)* {
    let $countRecords := count($records)
    let $countInvalid := count($records/@valid = "false")
    let $bulletType :=
        if ($countRecords = 0) then
            $errors:SKIPPED
        else if ($countRecords = 1) then
            $errors:INFO
        else
            $errorLevel
    let $message :=
        if ($countRecords = 0) then
            $skippedMsg
        else if ($countRecords > 1) then
            $unit || "is not unique"
        else if ($countRecords = 1) then
            $validMsg
        else
            "unknown error"

    return html:buildGeneric($ruleCode, $longText, $text, $records, $validMsg, $unit, $bulletType)
};

(: Deprecated, remove after migration :)
declare function html:buildResultRows($ruleCode as xs:string, $longText, $text, $records as element(tr)*, $valueHeading as xs:string, $validMsg as xs:string, $unit as xs:string, $skippedMsg, $errorLevel as xs:string) as element(tr)* {
    html:build2($ruleCode, $longText, $text, $records, $valueHeading, $validMsg, $unit, $skippedMsg, $errorLevel)
};

(: Builds HTML table rows for rules. :)
declare %private function html:buildGeneric($ruleCode as xs:string, $longText, $text, $records as element(tr)*, $message as xs:string, $unit as xs:string, $bulletType as xs:string) as element(tr)* {
    let $countRecords := count($records)
    let $result :=
        (
            <tr>
                <td class="bullet">{html:getBullet($ruleCode, $bulletType)}</td>
                <th colspan="2">{$text} {html:getModalInfo($ruleCode, $longText)}</th>
                <td><span class="largeText">{$message}</span>{
                    if ($countRecords > 0 or count($records)>0) then
                        <a id='feedbackLink-{$ruleCode}' href='javascript:toggle("feedbackRow","feedbackLink", "{$ruleCode}")'>{$labels:SHOWRECORDS}</a>
                    else
                        ()
                }
                </td>
            </tr>,
            if (count($records) > 0) then
                <tr>
                    <td></td>
                    <td colspan="3">
                        <table class="datatable" id="feedbackRow-{$ruleCode}">
                            <tr>{
                                for $th in $records[1]//td return <th>{ data($th/@title) }</th>
                            }</tr>
                            {$records}
                        </table>
                    </td>
                </tr>
            else
                ()
        )
    return $result

};

declare function html:buildResultRows_B($ruleCode as xs:string, $longText, $text, $invalidValues as xs:string*, $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string) as element(tr)*{
    let $countInvalidValues := count($invalidValues)
    let $bulletType := if (string-length($skippedMsg) > 0) then "skipped" else if ($countInvalidValues = 0) then "info" else $errorLevel
    let $result :=
        (
            <tr>
                <td class="bullet">{html:getBullet($ruleCode, $bulletType)}</td>
                <th colspan="2">{$text} {html:getModalInfo($ruleCode, $longText)}</th>
                <td class="largeText">{
                    if (string-length($skippedMsg) > 0) then
                        $skippedMsg
                    else if ($countInvalidValues = 0) then
                        $validMsg
                    else
                        concat($countInvalidValues, $invalidMsg, substring("s ", number(not($countInvalidValues > 1)) * 2) ,"found") }</td>
            </tr>,
            if ($countInvalidValues > 0) then
                <tr>
                    <td colspan="2">{ $valueHeading} - </td>
                    <td>{ string-join($invalidValues, ", ")}</td>
                </tr>
            else
                ()
        )
    return $result
};

declare function html:buildResultTable($ruleCode as xs:string, $longText, $text, $records as element(tr)*, $valueHeading as xs:string*, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string) as element(tr)* {
    let $countInvalidValues := count($records)
    let $bulletType := if (string-length($skippedMsg) > 0) then "skipped" else if ($countInvalidValues = 0) then "info" else $errorLevel
    let $result :=
        (
            <tr>
                <td class="bullet">{ html:getBullet($ruleCode, $bulletType) }</td>
                <th colspan="2">{ $text } {html:getModalInfo($ruleCode, $longText)}</th>
                <td><span class="largeText">{
                    if (string-length($skippedMsg) > 0) then
                        $skippedMsg
                    else if ($countInvalidValues = 0) then
                        $validMsg
                    else
                        concat($countInvalidValues, $invalidMsg, substring("s ", number(not($countInvalidValues > 1)) * 2) ," found") }
                </span>{
                    if ($countInvalidValues > 0 or count($records)>0) then
                        <a id='feedbackLink-{$ruleCode}' href='javascript:toggle("feedbackRow","feedbackLink", "{$ruleCode}")' style="padding-left:10px;">{$labels:SHOWRECORDS}</a>
                    else
                        ()
                }
                </td>
            </tr>,
            if (count($records)>0) then
                <tr>
                    <td></td>
                    <td colspan="3">
                        <table class="datatable" id="feedbackRow-{$ruleCode}">
                            <tr>{
                                for $th in $records[1]//td return <th>{ data($th/@title) }</th>
                            }</tr>
                            {$records}
                        </table>
                    </td>
                </tr>
            else
                ()
        )
    return $result

};
declare function html:buildResultsSimpleRow($ruleCode as xs:string, $longText, $text, $count, $errorLevel) {
    let $bulletType := $errorLevel
    return
    <tr>
        <td class="bullet">{html:getBullet($ruleCode, $bulletType)}</td>
        <th colspan="2">{$text} {html:getModalInfo($ruleCode, $longText)}</th>
        <td class="largeText">{$count}</td>
    </tr>
};

declare function html:buildResultRowsWithTotalCount_D($ruleCode as xs:string, $longText, $text, $records as element(tr)*,
        $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string)
as element(tr)*{

    let $countCheckedRecords := count($records)
    let $invalidValues := $records[./@isvalid = "false"]

    let $skippedMsg := if ($countCheckedRecords = 0) then "No values found to check" else ""
    let $invalidMsg := if (count($invalidValues) > 0) then concat(" invalid value", substring("s ", number(not(count($invalidValues) > 1)) * 2), " found out of ", $countCheckedRecords, " checked") else ""
    let $validMsg := if (count($invalidValues) = 0) then concat("Checked ", $countCheckedRecords, " value", substring("s", number(not($countCheckedRecords > 1)) * 2), ", all valid") else ""

    return
        html:build2($ruleCode, $longText, $text, $invalidValues, $valueHeading, $validMsg, $invalidMsg, $skippedMsg, $errorLevel)
};

declare function html:buildResultRowsWithTotalCount_G($ruleCode as xs:string, $longText, $text, $records as element(tr)*,
        $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string)
as element(tr)*{

    let $countCheckedRecords := count($records)
    let $invalidValues := $records[./@isvalid = "false"]

    let $skippedMsg := if ($countCheckedRecords = 0) then "No values found to check" else ""
    let $invalidMsg := if (count($invalidValues) > 0) then concat(" invalid value", substring("s ", number(not(count($invalidValues) > 1)) * 2), " found out of ", $countCheckedRecords, " checked") else ""
    let $validMsg := if (count($invalidValues) = 0) then concat("Checked ", $countCheckedRecords, " value", substring("s", number(not($countCheckedRecords > 1)) * 2), ", all valid") else ""

    return
        html:build2($ruleCode, $longText, $text, $invalidValues, $valueHeading, $validMsg, $invalidMsg, $skippedMsg, $errorLevel)
};


declare function html:buildResultRowsWithTotalCount_M($ruleCode as xs:string, $longText, $text, $records as element(tr)*,
        $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string) as element(tr)*{

    let $countCheckedRecords := count($records)
    let $invalidValues := $records[./@isvalid = "false"]

    let $skippedMsg := if ($countCheckedRecords = 0) then "No values found to check" else ""
    let $invalidMsg := if (count($invalidValues) > 0) then concat(" invalid value", substring("s ", number(not(count($invalidValues) > 1)) * 2), " found out of ", $countCheckedRecords, " checked") else ""
    let $validMsg := if (count($invalidValues) = 0) then concat("Checked ", $countCheckedRecords, " value", substring("s", number(not($countCheckedRecords > 1)) * 2), ", all valid") else ""

    return
        html:buildResultRows($ruleCode, $longText, $text, $invalidValues, $valueHeading, $validMsg, $invalidMsg, $skippedMsg,$errorLevel)
};

declare function html:buildItemsList($ruleId as xs:string, $vocabularyUrl as xs:string, $ids as xs:string*) as element(div) {
    let $list :=
        for $id in $ids
        let $refUrl := concat($vocabularyUrl, $id)
        return
            <p>{ $refUrl }</p>

    return
        <div>
            <a id='vocLink-{$ruleId}' href='javascript:toggleItem("vocValuesDiv","vocLink", "{$ruleId}", "combination")'>{$labels:SHOWCOMBINATIONS}</a>
            <div id="vocValuesDiv-{$ruleId}" style="display:none">{ $list }</div>
        </div>
};

declare function html:buildResultC31($ruleCode as xs:string, $resultsC as element(result)*, $resultsB as element(result)*) as element(tr)* {
    let $text := $labels:C31_SHORT
    let $longText := $labels:C31
    let $errorTmp :=
        for $x in $resultsC
            let $vsName := string($x/pollutantName)
            let $vsCode := string($x/pollutantCode)
            let $countC := xs:integer($x/count)
            let $countB := xs:integer($resultsB[pollutantName = $vsName]/count)
        return
            if ($countC > $countB) then $errors:ERROR
            else if ($countB > $countC) then $errors:WARNING
            else ()
    let $errorClass :=
        if ($errorTmp = $errors:ERROR) then $errors:ERROR
        else if ($errorTmp = $errors:WARNING) then $errors:WARNING
        else $errors:INFO

    let $bodyTR :=
        for $x in $resultsC
            let $vsName := string($x/pollutantName)
            let $vsCode := string($x/pollutantCode)
            let $countC := string($x/count)
            let $countB := string($resultsB[pollutantName = $vsName]/count)
        return
        <tr class="{$errorClass}">
            <td>{$vsName}</td>
            <td>{$vsCode}</td>
            <td>{$countC}</td>
            <td>{$countB}</td>
        </tr>
    let $bulletType := errors:getMaxError($bodyTR)
    return
        (<tr>
            <td class="bullet">{ html:getBullet($ruleCode, $bulletType) }</td>
            <th colspan="2">{ $text } {html:getModalInfo($ruleCode, $longText)}</th>
            <td>
                <a id='feedbackLink-{$ruleCode}' href='javascript:toggle("feedbackRow","feedbackLink", "{$ruleCode}")'>{$labels:SHOWRECORDS}</a>
            </td>
        </tr>,
        <tr>
            <td></td>
            <td>
                <table class="datatable" id="feedbackRow-{$ruleCode}">
                    <thead>
                        <tr>
                            <th>Pollutant Name</th>
                            <th>Pollutant Code</th>
                            <th>Count C</th>
                            <th>Count B</th>
                        </tr>
                    </thead>
                    <tbody>
                        {$bodyTR}
                    </tbody>
                </table>
            </td>
        </tr>)
};
declare function html:buildResultG14($ruleCode as xs:string, $longText, $text, $resultsBC as element(result)*, $resultsG as element(result)*) as element(tr)* {
    let $errorTmp :=
        for $x in $resultsBC
        let $vsName := string($x/pollutantName)
        let $vsCode := string($x/pollutantCode)
        let $countB := xs:integer($x/countB)
        let $countC := xs:integer($x/countC)
        let $countG := xs:integer($resultsG[pollutantName = $vsName]/count)
        return
            if ($countG > $countC) then $errors:ERROR
            else if ($countC > $countG) then $errors:WARNING
            else ()
    let $errorClass :=
        if ($errorTmp = $errors:ERROR) then $errors:ERROR
        else if ($errorTmp = $errors:WARNING) then $errors:WARNING
        else $errors:INFO

    let $bodyTR :=
        for $x in $resultsBC
        let $vsName := string($x/pollutantName)
        let $vsCode := string($x/pollutantCode)
        let $countB := string($x/countB)
        let $countC := string($x/countC)
        let $countG := string($resultsG[pollutantName = $vsName]/count)
        return
            <tr class="{$errorClass}">
                <td>{$vsName}</td>
                <td>{$vsCode}</td>
                <td>{$countB}</td>
                <td>{$countC}</td>
                <td>{$countG}</td>
            </tr>
    let $bulletType := errors:getMaxError($bodyTR)
    return
        (<tr>
            <td class="bullet">{ html:getBullet($ruleCode, $bulletType) }</td>
            <th colspan="2">{ $text } {html:getModalInfo($ruleCode, $longText)}</th>
            <td>
                <a id='feedbackLink-{$ruleCode}' href='javascript:toggle("feedbackRow","feedbackLink", "{$ruleCode}")'>{$labels:SHOWRECORDS}</a>
            </td>
        </tr>,
        <tr>
            <td></td>
            <td>
                <table class="datatable" id="feedbackRow-{$ruleCode}">
                    <thead>
                        <tr>
                            <th>Pollutant Name</th>
                            <th>Pollutant Code</th>
                            <th>Count B</th>
                            <th>Count C</th>
                            <th>Count G</th>
                        </tr>
                    </thead>
                    <tbody>
                        {$bodyTR}
                    </tbody>
                </table>
            </td>
        </tr>)
};

declare function html:buildInfoTable($ruleId as xs:string, $table as element(table)) {
    <div>
        <a id='vocLink-{$ruleId}' href='javascript:toggleItem("vocValuesDiv","vocLink", "{$ruleId}", "combination")'>{$labels:SHOWCOMBINATIONS}</a>
        <div id="vocValuesDiv-{$ruleId}" style="display:none">{ $table }</div>
    </div>
};

declare function html:getErrorTD($errValue,  $element as xs:string, $showMissing as xs:boolean) as element(td) {
    let $val := if ($showMissing and string-length($errValue)=0) then "-blank-" else $errValue
    return
        <td title="{$element}" style="color:red">{$val}</td>
};

declare function html:buildConcatRow($elems, $header as xs:string) as element(tr)? {
    if (count($elems) > 0) then
        <tr style="font-size: 0.9em;color:grey;">
            <td colspan="2" style="text-align:right;vertical-align:top;">{$header}</td>
            <td style="font-style:italic;vertical-align:top;">{ string-join($elems, ", ")}</td>
        </tr>
    else
        ()
};
declare function html:buildCountRow0($ruleCode as xs:string, $longText, $text, $count as xs:integer, $validMessage as xs:string?, $unit as xs:string?, $errorClass as xs:string?) as element(tr) {
    let $errorClsas :=
        if ($count > 0) then
            $errors:INFO
        else if (empty($errorClass)) then $errors:ERROR
        else $errorClass
    let $message :=
        if ($count = 0) then
            "No " || $unit || "s found"
        else
            $count || " " || $unit || substring("s ", number(not($count > 1)) * 2) || "found"
    return
        <tr>
            <td class="bullet">{html:getBullet($ruleCode, $errorClsas)}</td>
            <th colspan="2">{$text} {html:getModalInfo($ruleCode, $longText)}</th>
            <td class="largeText">{$message}</td>
        </tr>
};

declare function html:buildCountRow($ruleCode as xs:string, $longText, $text, $count as xs:integer, $validMessage as xs:string?, $unit as xs:string?, $errorClass as xs:string?) as element(tr) {
    let $class :=
        if ($count = 0) then
            $errors:INFO
        else if (empty($errorClass)) then $errors:ERROR
        else $errorClass
    let $validMessage := if (empty($validMessage)) then "All Ids are unique" else $validMessage
    let $message :=
        if ($count = 0) then
            $validMessage
        else
            $count || $unit || substring("s ", number(not($count > 1)) * 2) || "found"
    return
    <tr>
        <td class="bullet">{html:getBullet($ruleCode, $class)}</td>
        <th colspan="2">{$text} {html:getModalInfo($ruleCode, $longText)}</th>
        <td class="largeText">{$message}</td>
    </tr>
};
declare function html:buildCountRow2($ruleCode as xs:string, $longText, $text, $records as element(tr), $header as xs:string,
        $validMessage as xs:string?, $unit as xs:string?, $errorClass as xs:string?) as element(tr)* {
    let $status := xs:string($records/@status)
    let $count := $records/@count
    let $class :=
        if ($status = $errors:FAILED) then
            $errors:FAILED
        else if ($count = 0) then
            if (empty($errorClass)) then
                $errors:ERROR
            else
                $errorClass
        else
            $errors:INFO
    let $unit := if (empty($unit)) then "error" else $unit
    let $validMessage := if (empty($validMessage)) then "All Ids are unique" else $validMessage
    let $message :=
        if ($status = $errors:FAILED) then
            "Check failed:"
        else if ($count = 0) then
            "No " || $unit || "s found"
        else
            $validMessage
    return
        (<tr>
            <td class="bullet">{html:getBullet($ruleCode, $class)}</td>
            <th colspan="2">{$text} {html:getModalInfo($ruleCode, $longText)}</th>
            <td><span class="largeText">{$message}</span>{
                if ($status = $errors:FAILED) then
                    <a id='feedbackLink-{$ruleCode}' href='javascript:toggle("feedbackRow","feedbackLink", "{$ruleCode}")' style="padding-left:10px;">{$labels:SHOWERRORS}</a>
                else ()}
            </td>
        </tr>,
        if ($status = $errors:FAILED) then
        <tr>
            <td></td>
            <td colspan="3">
                <table class="datatable" id="feedbackRow-{$ruleCode}">
                    <tr>{
                        for $th in $records[1]//td return <th>{ data($th/@title) }</th>
                    }</tr>
                    {$records}
                </table>
            </td>
        </tr> else ())
};