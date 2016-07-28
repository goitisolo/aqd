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
        table.maintable.hover tbody tr th {
            text-align:left;
            width: 75%;
        }
        table.maintable.hover tbody tr {
            border-top:1px solid #666666;
        }
        table.maintable.hover tbody tr th.separator {
            font-size: 1.1em;
            text-align:center;
            color:#666666;
        }
        .datatable {
            font-size: 0.9em;
            text-align:left;
            vertical-align:top;
            display:none;
            border:0px;
        }
        .datatable tbody tr.warning {
            font-size: 1.2em;
            color:red;
        }
        .datatable tbody tr.error {
            font-size: 1.2em;
            color:red;
        }
        .datatable tbody tr {
            font-size: 0.9em;
            color:#666666;
        }
        .smalltable {
            display:none;
        }
        .smalltable tbody tr {
             font-size: 0.9em;
             color:grey;
        }
        .smalltable tbody td {
            font-style:italic;
            vertical-align:top;
        }
        .header {
            text-align:right;
            vertical-align:top;
            background-color:#F6F6F6;
            font-weight: bold;
        }
        .largeText {
            font-size:1.3em;
        }
        .box {
            padding:10px;
            border:1px solid rgba(0,0,0,0.5);
        }
        .bg-info {
            background:#A0D3E8;
        }
        .bg-error {
            background:pink;
        }
        .bg-warning {
            background:bisque;
        }
        .reveal {
            width:900px;
            border: 7px solid #cacaca;
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
        <hr/>
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
        <th class="separator" colspan="4">{$text}</th>
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
declare function html:buildXML($ruleCode as xs:string, $longText, $text, $records as element(tr)*, $validMessage as xs:string, $invalidMessage as xs:string, $errorLevel as xs:string) {
    let $countRecords := count($records)
    let $ruleCode := "XML"(: || string(random:double() * 100):)
    let $errorClass :=
        if ($countRecords > 0) then
            $errorLevel
        else
            $errors:INFO
    let $message :=
        if ($countRecords > 0) then
            $invalidMessage
        else
            $validMessage
    let $result :=
            (
                <tr>
                    <td class="bullet">{html:getBullet($ruleCode, $errorClass)}</td>
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
    return html:buildGeneric($ruleCode, $longText, $text, $records, $message, $bulletType)
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

        return html:buildGeneric($ruleCode, $longText, $text, $records, $message, $bulletType)
};
declare function html:buildUnique($ruleCode as xs:string, $longText, $text, $records as element(tr)*, $valueHeading as xs:string, $validMsg as xs:string, $unit as xs:string, $errorLevel as xs:string) {
    let $countRecords := count($records)
    let $bulletType :=
        if (count($records) = 1) then
            $errors:INFO
        else
            $errorLevel
    let $message := $countRecords || " " || $unit || substring("s ", number(not($countRecords > 1)) * 2) || " found"
    return
        if (count($records) = 1) then
            <tr>
                <td class="bullet">{html:getBullet($ruleCode, $bulletType)}</td>
                <th colspan="2">{$text} {html:getModalInfo($ruleCode, $longText)}</th>
                <td><span class="largeText">{$message}</span></td>
            </tr>
        else
            html:buildGeneric($ruleCode, $longText, $text, $records, $message, $bulletType)
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
    return html:buildGeneric($ruleCode, $longText, $text, $records, $validMsg, $bulletType)
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
    return html:buildGeneric($ruleCode, $longText, $text, $records, $message, $bulletType)
};
declare function html:build3($ruleCode as xs:string, $longText, $text, $records as element(tr)*, $message as xs:string, $errorLevel as xs:string) as element(tr)* {
    let $countRecords := count($records)
    let $bulletType := $errorLevel
    return
        <tr>
            <td class="bullet">{html:getBullet($ruleCode, $bulletType)}</td>
            <th colspan="2">{$text} {html:getModalInfo($ruleCode, $longText)}</th>
            <td><span class="largeText">{$message}</span></td>
        </tr>
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
    return html:buildGeneric($ruleCode, $longText, $text, $records, $message, $bulletType)
};
(: TODO: maybe remove :)
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

    return html:buildGeneric($ruleCode, $longText, $text, $records, $validMsg, $bulletType)
};

(: Builds HTML table rows for rules. :)
declare %private function html:buildGeneric($ruleCode as xs:string, $longText, $text, $records as element(tr)*, $message as xs:string, $bulletType as xs:string) as element(tr)* {
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
        html:build2($ruleCode, $longText, $text, $invalidValues, $valueHeading, $validMsg, $invalidMsg, $skippedMsg,$errorLevel)
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

declare function html:buildResultDiv($meta as map(*), $result as element(table)) {
    let $count := map:get($meta, "count")
    let $header := map:get($meta, "header")
    let $dataflow := map:get($meta, "dataflow")
    let $zeroCount := map:get($meta, "zeroCount")
    let $report := map:get($meta, "report")
    return
    <div>
        <h2>{$header} - {$dataflow}</h2>
        {
            if ($count = 0) then
                $zeroCount
            else
                <div>
                    {
                        if ($result//div/tokenize(@class, "\s+") = $errors:ERROR) then
                            <p class="{$errors:ERROR} bg-error box" style="color:{$errors:COLOR_ERROR}">
                                <strong>This XML file did NOT pass the following crucial check(s): {string-join($result//div[tokenize(@class, "\s+") = $errors:ERROR], ',')}</strong>
                            </p>
                        else
                            <p class="{$errors:INFO} bg-info box" style="color:#0080FF">
                                <strong>This XML file passed all crucial checks.</strong>
                            </p>
                    }
                    {
                        if ($result//div/tokenize(@class, "\s+") = $errors:WARNING) then
                            <p class="{$errors:WARNING} bg-warning box" style="color:{$errors:COLOR_WARNING}">
                                <strong>This XML file generated warnings during the following check(s): {string-join($result//div[tokenize(@class, "\s+") = $errors:WARNING], ',')}</strong>
                            </p>
                        else
                            ()
                    }
                    {$report}
                    <div><a id='legendLink' href="javascript: showLegend()" style="padding-left:10px;">How to read the test results?</a></div>
                    <fieldset style="font-size: 90%; display:none" id="legend">
                        <legend>How to read the test results</legend>
                        All test results are labeled with coloured bullets. The number in the bullet reffers to the rule code. The background colour of the bullets means:
                        <ul style="list-style-type: none;">
                            <li><div style="width:50px; display:inline-block;margin-left:10px">{html:getBullet('Blue', $errors:INFO)}</div> - the data confirms to the rule, but additional feedback could be provided in QA result.</li>
                            <li><div style="width:50px; display:inline-block;margin-left:10px">{html:getBullet('Red', $errors:ERROR)}</div> - the crucial check did NOT pass and errenous records found from the delivery.</li>
                            <li><div style="width:50px; display:inline-block;margin-left:10px">{html:getBullet('Orange', $errors:WARNING)}</div> - the non-crucial check did NOT pass.</li>
                            <li><div style="width:50px; display:inline-block;margin-left:10px">{html:getBullet('Grey', $errors:SKIPPED)}</div> - the check was skipped due to no relevant values found to check.</li>
                        </ul>
                        <p>Click on the "{$labels:SHOWRECORDS}" link to see more details about the test result.</p>
                    </fieldset>
                    <h3>Test results</h3>
                    {$result}
                </div>
        }
    </div>
};