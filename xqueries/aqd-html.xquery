xquery version "1.0";

(:~
: 
: User: George Sofianos
: Date: 5/31/2016
: Time: 11:48 AM
:)

module namespace html = "aqd-html";
import module namespace labels = "aqd-labels" at "aqd-labels.xquery";

declare function html:getHead() as element()* {  
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/foundation/6.2.3/foundation.min.css"/>    
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
        <hr/>
        <p>{$longText}</p>
        <button class="close-button" data-close="" aria-label="Close modal" type="button">x</button>
    </div>)
};


declare function html:getBullet($text as xs:string, $level as xs:string) as element(div) {
    let $color :=
        if ($level = "error") then
            "red"
        else if ($level = "warning") then
            "orange"
        else if ($level = "skipped") then
            "gray"
        else
            "deepskyblue"
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

(: Builds HTML table rows for rules. :)
declare function html:buildResultRows($ruleCode as xs:string, $longText, $text, $records as element(tr)*, $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string) as element(tr)* {
    let $countInvalidValues := count($records)
    let $bulletType := if (string-length($skippedMsg) > 0) then "skipped" else if ($countInvalidValues = 0) then "info" else $errorLevel
    let $result :=
        (
            <tr>
                <td class="bullet">{html:getBullet($ruleCode, $bulletType)}</td>
                <th colspan="2">{$text} {html:getModalInfo($ruleCode, $longText)}</th>
                <td><span class="largeText">{
                    if (string-length($skippedMsg) > 0) then
                        $skippedMsg
                    else if ($countInvalidValues = 0) then
                        $validMsg
                    else
                        concat($countInvalidValues, $invalidMsg, substring("s ", number(not($countInvalidValues > 1)) * 2) ,"found") }
                </span>{
                    if ($countInvalidValues > 0 or count($records)>0) then
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
            else if (count($records)  > 0) then
                <tr>
                    <td></td>
                    <td colspan="3">
                        <table class="smalltable" id="feedbackRow-{$ruleCode}">
                            <tr>
                                <td></td>
                                <th colspan="3">{ $valueHeading}</th>
                                <td>{ string-join($records, ", ")}</td>
                            </tr>
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
        html:buildResultRows($ruleCode, $longText, $text, $records, $valueHeading, $validMsg, $invalidMsg, $skippedMsg, $errorLevel)
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
        html:buildResultRows($ruleCode, $longText, $text, $records, $valueHeading, $validMsg, $invalidMsg, $skippedMsg, $errorLevel)
};


declare function html:buildResultRowsWithTotalCount_M($ruleCode as xs:string, $longText, $text, $records as element(tr)*,
        $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string) as element(tr)*{

    let $countCheckedRecords := count($records)
    let $invalidValues := $records[./@isvalid = "false"]

    let $skippedMsg := if ($countCheckedRecords = 0) then "No values found to check" else ""
    let $invalidMsg := if (count($invalidValues) > 0) then concat(" invalid value", substring("s ", number(not(count($invalidValues) > 1)) * 2), " found out of ", $countCheckedRecords, " checked") else ""
    let $validMsg := if (count($invalidValues) = 0) then concat("Checked ", $countCheckedRecords, " value", substring("s", number(not($countCheckedRecords > 1)) * 2), ", all valid") else ""

    return
        html:buildResultRows($ruleCode, $longText, $text, $records, $valueHeading, $validMsg, $invalidMsg, $skippedMsg,$errorLevel)
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

declare function html:buildResultC31($ruleCode as xs:string, $resultsC as element(results), $resultsB as element(results)) as element(tr)* {
    let $text := $labels:C31_SHORT
    let $longText := $labels:C31
    let $bodyTR :=
        for $x in $resultsC/result
            let $vsName := string($x/pollutantName)
            let $vsCode := string($x/pollutantCode)
            let $countC := string($x/count)
            let $countB := string($resultsB/result[pollutantName = $vsName]/count)
        return
        <tr class="{if ($countB != $countC) then "error" else ()}">
            <td>{$vsName}</td>
            <td>{$vsCode}</td>
            <td>{$countC}</td>
            <td>{$countB}</td>
        </tr>
    let $bulletType := if (count($bodyTR[@class = "error"]) > 0) then "error" else "info"
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

declare function html:buildCountRow($ruleCode as xs:string, $count as xs:integer, $header as xs:string, $validMessage as xs:string?, $unit as xs:string?, $errorClass as xs:string?) as element(tr) {
    let $class :=
        if ($count = 0) then
            "info"
        else if (empty($errorClass)) then "error"
        else $errorClass
    let $unit := if (empty($unit)) then "error" else $unit
    let $validMessage := if (empty($validMessage)) then "All Ids are unique" else $validMessage
    let $message :=
        if ($count = 0) then
            $validMessage
        else
            $count || $unit || substring("s ", number(not($count > 1)) * 2) || "found"
    return
    <tr>
        <td class="bullet">{html:getBullet($ruleCode, $class)}</td>
        <th colspan="2">{$header}</th>
        <td class="largeText">{$message}</td>
    </tr>
};