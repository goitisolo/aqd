xquery version "1.0";

(:~
: 
: User: George Sofianos
: Date: 5/31/2016
: Time: 11:48 AM
:)

module namespace html = "aqd-html";

declare function html:getHead() as element()* {  
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/foundation/6.2.3/foundation.min.css"/>    
};

declare function html:getFoot() as element()* {
    <script src="https://cdn.jsdelivr.net/jquery/2.2.4/jquery.min.js"></script>,
    <script src="https://cdn.jsdelivr.net/foundation/6.2.3/foundation.min.js"></script>,
    <script type="text/javascript">
        $(document).foundation();
    </script>
};

declare function html:getModalInfo($ruleCode, $longText) as element()* {
    (<span><a class="small" data-open="{concat('text-modal-', $ruleCode)}">&#8505;</a></span>,
    <div class="reveal" id="{concat('text-modal-', $ruleCode)}" data-reveal="">
        <p>{$longText}</p>
        <button class="close-button" data-close="" aria-label="Close modal" type="button"/>
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
        <div class="{$level}" style="background-color: { $color }; font-size: 0.8em; color: white; padding-left:5px;padding-right:5px;margin-right:5px;margin-top:2px;text-align:center">{ $text }</div>
};


(:~
: JavaScript
:)
declare function html:javaScriptRoot(){

    let $js :=
        <script type="text/javascript">
            <![CDATA[
    function showLegend(){
        document.getElementById('legend').style.display='inline';
        document.getElementById('legendLink').style.display='none';
    }
    function hideLegend(){
        document.getElementById('legend').style.display='none';
        document.getElementById('legendLink').style.display='inline';
    }
    function toggle(divName, linkName, checkId) {{
         toggleItem(divName, linkName, checkId, 'record');
    }}

   function toggleItem(divName, linkName, checkId, itemLabel) {{
        divName = divName + "-" + checkId;
        linkName = linkName + "-" + checkId;

        var elem = document.getElementById(divName);
        var text = document.getElementById(linkName);
        if(elem.style.display == "inline") {{
            elem.style.display = "none";
            text.innerHTML = "Show " + itemLabel + "s";
            }}
            else {{
              elem.style.display = "inline";
              text.innerHTML = "Hide " + itemLabel + "s";
            }}
      }}

      function toggleComb(divName, linkName, checkId, itemLabel) {{
        divName = divName + "-" + checkId;
        linkName = linkName + "-" + checkId;

        var elem = document.getElementById(divName);
        var text = document.getElementById(linkName);
        if(elem.style.display == "inline") {{
            elem.style.display = "none";
            text.innerHTML = "Show " + itemLabel + "s";
            }}
            else {{
              elem.style.display = "inline";
              text.innerHTML = "Hide " + itemLabel + "s";
            }}
      }}

                ]]>
        </script>
    return
        <script type="text/javascript">{normalize-space($js)}</script>
};

(:~
: JavaScript
:)

declare function html:javaScript_B(){

    let $js :=
        <script type="text/javascript">
            <![CDATA[
    function toggle(divName, linkName, checkId) {{
         toggleItem(divName, linkName, checkId, 'record');
    }}


    function toggleItem(divName, linkName, checkId, itemLabel) {{
        divName = divName + "-" + checkId;
        linkName = linkName + "-" + checkId;

        var elem = document.getElementById(divName);
        var text = document.getElementById(linkName);
        if(elem.style.display == "inline") {{
            elem.style.display = "none";
            text.innerHTML = "Show " + itemLabel + "s";
            }}
            else {{
              elem.style.display = "inline";
              text.innerHTML = "Hide " + itemLabel + "s";
            }}
      }}

                ]]>
        </script>
    return
        <script type="text/javascript">{normalize-space($js)}</script>
};


(:~
: JavaScript
:)
declare function html:javaScript_C(){

    let $js :=
        <script type="text/javascript">
            <![CDATA[
    function toggle(divName, linkName, checkId) {{
         toggleItem(divName, linkName, checkId, 'record');
    }}

   function toggleItem(divName, linkName, checkId, itemLabel) {{
        divName = divName + "-" + checkId;
        linkName = linkName + "-" + checkId;

        var elem = document.getElementById(divName);
        var text = document.getElementById(linkName);
        if(elem.style.display == "inline") {{
            elem.style.display = "none";
            text.innerHTML = "Show " + itemLabel + "s";
            }}
            else {{
              elem.style.display = "inline";
              text.innerHTML = "Hide " + itemLabel + "s";
            }}
      }}

      function toggleComb(divName, linkName, checkId, itemLabel) {{
        divName = divName + "-" + checkId;
        linkName = linkName + "-" + checkId;

        var elem = document.getElementById(divName);
        var text = document.getElementById(linkName);
        if(elem.style.display == "inline") {{
            elem.style.display = "none";
            text.innerHTML = "Show " + itemLabel + "s";
            }}
            else {{
              elem.style.display = "inline";
              text.innerHTML = "Hide " + itemLabel + "s";
            }}
      }}

                ]]>
        </script>
    return
        <script type="text/javascript">{normalize-space($js)}</script>
};
(:~
: JavaScript
:)
declare function html:javaScript_D(){

    let $js :=
        <script type="text/javascript">
            <![CDATA[
    function toggle(divName, linkName, checkId) {{
        divName = divName + "-" + checkId;
        linkName = linkName + "-" + checkId;

        var elem = document.getElementById(divName);
        var text = document.getElementById(linkName);
        if(elem.style.display == "inline") {{
            elem.style.display = "none";
            text.innerHTML = "Show records";
            }}
            else {{
              elem.style.display = "inline";
              text.innerHTML = "Hide records";
            }}
      }}
                ]]>
        </script>
    return
        <script type="text/javascript">{normalize-space($js)}</script>
};

(:~
: JavaScript
:)
declare function html:javaScript_G(){

    let $js :=
        <script type="text/javascript">
            <![CDATA[
    function toggle(divName, linkName, checkId) {{
         toggleItem(divName, linkName, checkId, 'record');
    }}


    function toggleItem(divName, linkName, checkId, itemLabel) {{
        divName = divName + "-" + checkId;
        linkName = linkName + "-" + checkId;

        var elem = document.getElementById(divName);
        var text = document.getElementById(linkName);
        if(elem.style.display == "inline") {{
            elem.style.display = "none";
            text.innerHTML = "Show " + itemLabel + "s";
            }}
            else {{
              elem.style.display = "inline";
              text.innerHTML = "Hide " + itemLabel + "s";
            }}
      }}

                ]]>
        </script>
    return
        <script type="text/javascript">{normalize-space($js)}</script>
};

(:~
: JavaScript
:)
declare function html:javaScript_M(){

    let $js :=
        <script type="text/javascript">
            <![CDATA[
    function toggle(divName, linkName, checkId) {{
        divName = divName + "-" + checkId;
        linkName = linkName + "-" + checkId;

        var elem = document.getElementById(divName);
        var text = document.getElementById(linkName);
        if(elem.style.display == "inline") {{
            elem.style.display = "none";
            text.innerHTML = "Show records";
            }}
            else {{
              elem.style.display = "inline";
              text.innerHTML = "Hide records";
            }}
      }}
                ]]>
        </script>
    return
        <script type="text/javascript">{normalize-space($js)}</script>
};

declare function html:buildResultRows_B($ruleCode as xs:string, $longText, $text, $invalidValues as xs:string*,
        $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string)
as element(tr)*{
    let $countInvalidValues := count($invalidValues)
    let $bulletType := if (string-length($skippedMsg) > 0) then "skipped" else if ($countInvalidValues = 0) then "info" else $errorLevel
    let $result :=
        (
            <tr>
                <td style="vertical-align:top;">{ html:getBullet($ruleCode, $bulletType) }</td>
                <th style="vertical-align:top;">{ $text } {html:getModalInfo($ruleCode, $longText)}</th>
                <td style="vertical-align:top;">{
                    if (string-length($skippedMsg) > 0) then
                        $skippedMsg
                    else if ($countInvalidValues = 0) then
                        $validMsg
                    else
                        concat($countInvalidValues, $invalidMsg, substring("s ", number(not($countInvalidValues > 1)) * 2) ,"found") }</td>
            </tr>,
            if ($countInvalidValues > 0) then
                <tr style="font-size: 0.9em;color:grey;">
                    <td colspan="2" style="text-align:right;vertical-align:top;">{ $valueHeading} - </td>
                    <td style="font-style:italic;vertical-align:top;">{ string-join($invalidValues, ", ")}</td>
                </tr>
            else
                ()
        )
    return $result

};

declare function html:buildResultTable_B($ruleCode as xs:string, $longText, $text,
        $valueHeading as xs:string*, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string, $recordDetails as element(tr)*)
as element(tr)*{
    let $countInvalidValues := count($recordDetails)

    let $bulletType := if (string-length($skippedMsg) > 0) then "skipped" else if ($countInvalidValues = 0) then "info" else $errorLevel
    let $result :=
        (
            <tr style="border-top:1px solid #666666;">
                <td style="padding-top:3px;vertical-align:top;">{ html:getBullet($ruleCode, $bulletType) }</td>
                <th style="padding-top:3px;vertical-align:top;text-align:left;">{ $text } {html:getModalInfo($ruleCode, $longText)}</th>
                <td style="padding-top:3px;vertical-align:top;"><span style="font-size:1.3em;">{
                    if (string-length($skippedMsg) > 0) then
                        $skippedMsg
                    else if ($countInvalidValues = 0) then
                        $validMsg
                    else
                        concat($countInvalidValues, $invalidMsg, substring("s ", number(not($countInvalidValues > 1)) * 2) ," found") }
                </span>{
                    if ($countInvalidValues > 0 or count($recordDetails)>0) then
                        <a id='feedbackLink-{$ruleCode}' href='javascript:toggle("feedbackRow","feedbackLink", "{$ruleCode}")' style="padding-left:10px;">Show records</a>
                    else
                        ()
                }
                </td>
                <td></td>
            </tr>,
            if (count($recordDetails)>0) then
                <tr>
                    <td></td>
                    <td colspan="3">
                        <table class="datatable" style="font-size: 0.9em;text-align:left;vertical-align:top;display:none;border:0px;" id="feedbackRow-{$ruleCode}">
                            <tr>{
                                for $th in $recordDetails[1]//td return <th>{ data($th/@title) }</th>
                            }</tr>
                            {$recordDetails}
                        </table>
                    </td>
                </tr>
            else
                ()
        )
    return $result

};
(: Builds HTML table rows for rules. :)
declare function html:buildResultRowsHTML_B($ruleCode as xs:string, $longText, $text, $invalidStrValues as xs:string*, $invalidValues as element()*,
        $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $recordDetails as element(tr)*)
as element(tr)*{
    let $countInvalidValues := count($invalidStrValues) + count($invalidValues)

    let $recordDetails := if (count($invalidValues) > 0) then $invalidValues else $recordDetails

    let $bulletType := if (string-length($skippedMsg) > 0) then "skipped" else if ($countInvalidValues = 0) then "info" else "error"
    let $result :=
        (
            <tr style="border-top:1px solid #666666;">
                <td style="padding-top:3px;vertical-align:top;">{ html:getBullet($ruleCode, $bulletType) }</td>
                <th style="padding-top:3px;vertical-align:top;text-align:left;">{ $text } {html:getModalInfo($ruleCode, $longText)}</th>
                <td style="padding-top:3px;vertical-align:top;"><span style="font-size:1.3em;">{
                    if (string-length($skippedMsg) > 0) then
                        $skippedMsg
                    else if ($countInvalidValues = 0) then
                        $validMsg
                    else
                        concat($countInvalidValues, $invalidMsg, substring("s ", number(not($countInvalidValues > 1)) * 2) ,"found") }
                </span>{
                    if ($countInvalidValues > 0 or count($recordDetails)>0) then
                        <a id='feedbackLink-{$ruleCode}' href='javascript:toggle("feedbackRow","feedbackLink", "{$ruleCode}")' style="padding-left:10px;">Show records</a>
                    else
                        ()
                }
                </td>
                <td></td>
            </tr>,
            if (count($recordDetails)>0) then
                <tr>
                    <td></td>
                    <td colspan="3">
                        <table class="datatable" style="font-size: 0.9em;text-align:left;vertical-align:top;display:none;border:0px;" id="feedbackRow-{$ruleCode}">
                            <tr>{
                                for $th in $recordDetails[1]//td return <th>{ data($th/@title) }</th>
                            }</tr>
                            {$recordDetails}
                        </table>
                    </td>
                </tr>
            else if (count($invalidStrValues)  > 0) then
                <tr>
                    <td></td>
                    <td colspan="3">
                        <table style="display:none;margin-top:1em;" id="feedbackRow-{$ruleCode}">
                            <tr style="font-size: 0.9em;color:#666666;">
                                <td></td>
                                <th colspan="3" style="text-align:right;vertical-align:top;background-color:#F6F6F6;font-weight: bold;">{ $valueHeading}</th>
                                <td style="font-style:italic;vertical-align:top;">{ string-join($invalidStrValues, ", ")}</td>
                            </tr>
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
    <tr style="border-top:1px solid #666666;">
        <td style="padding-top:3px;vertical-align:top;">{ html:getBullet($ruleCode, $bulletType) }</td>
        <th style="padding-top:3px;vertical-align:top;text-align:left;">{ $text } {html:getModalInfo($ruleCode, $longText)}</th>
        <td style="padding-top:3px;vertical-align:top;"><span style="font-size:1.3em;">{ $count } </span></td>
    </tr>
};

(: Builds HTML table rows for rules. :)
declare function html:buildResultRows_C($ruleCode as xs:string, $longText, $text, $invalidStrValues as xs:string*, $invalidValues as element()*,
        $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string, $recordDetails as element(tr)*)
as element(tr)*{
    let $countInvalidValues := count($invalidStrValues) + count($invalidValues)

    let $recordDetails := if (count($invalidValues) > 0) then $invalidValues else $recordDetails

    let $bulletType := if (string-length($skippedMsg) > 0) then "skipped" else if ($countInvalidValues = 0) then "info" else $errorLevel
    let $result :=
        (
            <tr style="border-top:1px solid #666666;">
                <td style="padding-top:3px;vertical-align:top;">{ html:getBullet($ruleCode, $bulletType) }</td>
                <th style="padding-top:3px;vertical-align:top;text-align:left;">{ $text } {html:getModalInfo($ruleCode, $longText)}</th>
                <td style="padding-top:3px;vertical-align:top;"><span style="font-size:1.3em;">{
                    if (string-length($skippedMsg) > 0) then
                        $skippedMsg
                    else if ($countInvalidValues = 0) then
                        $validMsg
                    else
                        concat($countInvalidValues, $invalidMsg, substring("s ", number(not($countInvalidValues > 1)) * 2) ,"found") }
                </span>{
                    if ($countInvalidValues > 0 or count($recordDetails)>0) then
                        <a id='feedbackLink-{$ruleCode}' href='javascript:toggle("feedbackRow","feedbackLink", "{$ruleCode}")' style="padding-left:10px;">Show records</a>
                    else
                        ()
                }
                </td>
                <td></td>
            </tr>,
            if (count($recordDetails)>0) then
                <tr>
                    <td></td>
                    <td colspan="3">
                        <table class="datatable" style="font-size: 0.9em;text-align:left;vertical-align:top;display:none;border:0px;" id="feedbackRow-{$ruleCode}">
                            <tr>{
                                for $th in $recordDetails[1]//td return <th>{ data($th/@title) }</th>
                            }</tr>
                            {$recordDetails}
                        </table>
                    </td>
                </tr>
            else if (count($invalidStrValues)  > 0) then
                <tr>
                    <td></td>
                    <td colspan="3">
                        <table style="display:none;margin-top:1em;" id="feedbackRow-{$ruleCode}">
                            <tr style="font-size: 0.9em;color:#666666;">
                                <td></td>
                                <th colspan="3" style="text-align:right;vertical-align:top;background-color:#F6F6F6;font-weight: bold;">{ $valueHeading}</th>
                                <td style="font-style:italic;vertical-align:top;">{ string-join($invalidStrValues, ", ")}</td>
                            </tr>
                        </table>
                    </td>
                </tr>

            else
                ()
        )
    return $result

};

declare function html:buildResultTable_C($ruleCode as xs:string, $longText, $text, $valueHeading as xs:string*, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string, $recordDetails as element(tr)*) as element(tr)*{
    let $countInvalidValues := count($recordDetails)

    let $bulletType := if (string-length($skippedMsg) > 0) then "skipped" else if ($countInvalidValues = 0) then "info" else $errorLevel
    let $result :=
        (
            <tr style="border-top:1px solid #666666;">
                <td style="padding-top:3px;vertical-align:top;">{ html:getBullet($ruleCode, $bulletType) }</td>
                <th style="padding-top:3px;vertical-align:top;text-align:left;">{ $text } {html:getModalInfo($ruleCode, $longText)}</th>
                <td style="padding-top:3px;vertical-align:top;"><span style="font-size:1.3em;">{
                    if (string-length($skippedMsg) > 0) then
                        $skippedMsg
                    else if ($countInvalidValues = 0) then
                        $validMsg
                    else
                        concat($countInvalidValues, $invalidMsg, substring("s ", number(not($countInvalidValues > 1)) * 2) ," found") }
                </span>{
                    if ($countInvalidValues > 0 or count($recordDetails)>0) then
                        <a id='feedbackLink-{$ruleCode}' href='javascript:toggle("feedbackRow","feedbackLink", "{$ruleCode}")' style="padding-left:10px;">Show records</a>
                    else
                        ()
                }
                </td>
                <td></td>
            </tr>,
            if (count($recordDetails)>0) then
                <tr>
                    <td></td>
                    <td colspan="3">
                        <table class="datatable" style="font-size: 0.9em;text-align:left;vertical-align:top;display:none;border:0px;" id="feedbackRow-{$ruleCode}">
                            <tr>{
                                for $th in $recordDetails[1]//td return <th>{ data($th/@title) }</th>
                            }</tr>
                            {$recordDetails}
                        </table>
                    </td>
                </tr>
            else
                ()
        )
    return $result

};
(: Builds HTML table rows for rules. :)
declare function html:buildResultRows_D($ruleCode as xs:string, $longText, $text, $invalidStrValues as xs:string*, $invalidValues as element()*,
        $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string, $recordDetails as element(tr)*)
as element(tr)*{
    html:buildResultRows_D($ruleCode, $longText, $text, $invalidStrValues, $invalidValues,
            $valueHeading, $validMsg, $invalidMsg, $skippedMsg, $errorLevel, $recordDetails, fn:true())
};


declare function html:buildResultRows_D($ruleCode as xs:string, $longText, $text, $invalidStrValues as xs:string*, $invalidValues as element()*,
        $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string, $recordDetails as element(tr)*,
        $invalidValuesAreInvalid as xs:boolean)
as element(tr)*{

    let $countInvalidValues := count($invalidStrValues) + count($invalidValues)

    let $recordDetails := if (count($invalidValues) > 0) then $invalidValues else $recordDetails

    let $bulletType := if (string-length($skippedMsg) > 0) then "skipped" else if ($countInvalidValues = 0) then "info" else $errorLevel


    (: sometimes warning is needed if count is 0 :)
    let $bulletType :=
        if (not($invalidValuesAreInvalid)) then
            if (string-length($skippedMsg) > 0) then "skipped" else if ($countInvalidValues = 0) then $errorLevel else "info"
        else
            $bulletType


    let $result :=
        (
            <tr style="border-top:1px solid #666666;">
                <td style="padding-top:3px;vertical-align:top;">{ html:getBullet($ruleCode, $bulletType) }</td>
                <th style="padding-top:3px;vertical-align:top;text-align:left;">{ $text } {html:getModalInfo($ruleCode, $longText)}</th>
                <td style="padding-top:3px;vertical-align:top;"><span style="font-size:1.3em;">{
                    if (string-length($skippedMsg) > 0) then
                        $skippedMsg
                    else if ($countInvalidValues = 0) then
                        $validMsg
                    else
                        if (contains($invalidMsg, " found")) then
                            concat($countInvalidValues, $invalidMsg)
                        else
                            concat($countInvalidValues, $invalidMsg, substring(" ", number(not($countInvalidValues > 1)) * 2) ," found")
                }
                </span>{
                    if ($countInvalidValues > 0 or count($recordDetails)>0) then
                        <a id='feedbackLink-{$ruleCode}' href='javascript:toggle("feedbackRow","feedbackLink", "{$ruleCode}")' style="padding-left:10px;">Show records</a>
                    else
                        ()
                }
                </td>
                <td></td>
            </tr>,
            if (count($recordDetails)>0) then
                <tr>
                    <td></td>
                    <td colspan="3">
                        <table class="datatable" style="font-size: 0.9em;text-align:left;vertical-align:top;display:none;border:0px;" id="feedbackRow-{$ruleCode}">
                            <tr>{
                                for $th in $recordDetails[1]//td return <th>{ data($th/@title) }</th>
                            }</tr>
                            {$recordDetails}
                        </table>
                    </td>
                </tr>
            else if (count($invalidStrValues)  > 0) then
                <tr>
                    <td></td>
                    <td colspan="3">
                        <table style="display:none;margin-top:1em;" id="feedbackRow-{$ruleCode}">
                            <tr style="font-size: 0.9em;color:#666666;">
                                <td></td>
                                <th colspan="3" style="text-align:right;vertical-align:top;background-color:#F6F6F6;font-weight: bold;">{ $valueHeading}</th>
                                <td style="font-style:italic;vertical-align:top;">{ string-join($invalidStrValues, ", ")}</td>
                            </tr>
                        </table>
                    </td>
                </tr>

            else
                ()
        )
    return $result

};
(: Builds HTML table rows for rules. :)
declare function html:buildResultRows_G($ruleCode as xs:string, $longText, $text, $invalidStrValues as xs:string*, $invalidValues as element()*,
        $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string, $recordDetails as element(tr)*)
as element(tr)*{
    let $countInvalidValues := count($invalidStrValues) + count($invalidValues)

    let $recordDetails := if (count($invalidValues) > 0) then $invalidValues else $recordDetails

    let $bulletType := if (string-length($skippedMsg) > 0) then "skipped" else if ($countInvalidValues = 0) then "info" else $errorLevel
    let $result :=
        (
            <tr style="border-top:1px solid #666666;">
                <td style="padding-top:3px;vertical-align:top;">{ html:getBullet($ruleCode, $bulletType) }</td>
                <th style="padding-top:3px;vertical-align:top;text-align:left;">{ $text } {html:getModalInfo($ruleCode, $longText)}</th>
                <td style="padding-top:3px;vertical-align:top;"><span style="font-size:1.3em;">{
                    if (string-length($skippedMsg) > 0) then
                        $skippedMsg
                    else if ($countInvalidValues = 0) then
                        $validMsg
                    else
                        concat($countInvalidValues, $invalidMsg, substring("s ", number(not($countInvalidValues > 1)) * 2) ,"found") }
                </span>{
                    if ($countInvalidValues > 0 or count($recordDetails)>0) then
                        <a id='feedbackLink-{$ruleCode}' href='javascript:toggle("feedbackRow","feedbackLink", "{$ruleCode}")' style="padding-left:10px;">Show records</a>
                    else
                        ()
                }
                </td>
                <td></td>
            </tr>,
            if (count($recordDetails)>0) then
                <tr>
                    <td></td>
                    <td colspan="3">
                        <table class="datatable" style="font-size: 0.9em;text-align:left;vertical-align:top;display:none;border:0px;" id="feedbackRow-{$ruleCode}">
                            <tr>{
                                for $th in $recordDetails[1]//td return <th>{ data($th/@title) }</th>
                            }</tr>
                            {$recordDetails}
                        </table>
                    </td>
                </tr>
            else if (count($invalidStrValues)  > 0) then
                <tr>
                    <td></td>
                    <td colspan="3">
                        <table style="display:none;margin-top:1em;" id="feedbackRow-{$ruleCode}">
                            <tr style="font-size: 0.9em;color:#666666;">
                                <td></td>
                                <th colspan="3" style="text-align:right;vertical-align:top;background-color:#F6F6F6;font-weight: bold;">{ $valueHeading}</th>
                                <td style="font-style:italic;vertical-align:top;">{ string-join($invalidStrValues, ", ")}</td>
                            </tr>
                        </table>
                    </td>
                </tr>

            else
                ()
        )
    return $result

};

(: Builds HTML table rows for rules. :)
declare function html:buildResultRows_M($ruleCode as xs:string, $longText, $text, $invalidStrValues as xs:string*, $invalidValues as element()*,
        $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string, $recordDetails as element(tr)*)
as element(tr)*{

    let $countInvalidValues := count($invalidStrValues) + count($invalidValues)
    let $recordDetails := if (count($invalidValues) > 0) then $invalidValues else $recordDetails
    let $bulletType := if (string-length($skippedMsg) > 0) then "skipped" else if ($countInvalidValues = 0) then "info" else $errorLevel
    let $result :=
        (
            <tr style="border-top:1px solid #666666;">
                <td style="padding-top:3px;vertical-align:top;">{ html:getBullet($ruleCode, $bulletType) }</td>
                <th style="padding-top:3px;vertical-align:top;text-align:left;">{ $text } {html:getModalInfo($ruleCode, $longText)}</th>
                <td style="padding-top:3px;vertical-align:top;"><span style="font-size:1.3em;">{
                    if (string-length($skippedMsg) > 0) then
                        $skippedMsg
                    else if ($countInvalidValues = 0) then
                        $validMsg
                    else
                        if (contains($invalidMsg, " found")) then
                            concat($countInvalidValues, $invalidMsg)
                        else
                            concat($countInvalidValues, $invalidMsg, substring(" ", number(not($countInvalidValues > 1)) * 2) ,"found")
                }
                </span>{
                    if ($countInvalidValues > 0 or count($recordDetails)>0) then
                        <a id='feedbackLink-{$ruleCode}' href='javascript:toggle("feedbackRow","feedbackLink", "{$ruleCode}")' style="padding-left:10px;">Show records</a>
                    else
                        ()
                }
                </td>
                <td></td>
            </tr>,
            if (count($recordDetails)>0) then
                <tr>
                    <td></td>
                    <td colspan="3">
                        <table class="datatable" style="font-size: 0.9em;text-align:left;vertical-align:top;display:none;border:0px;" id="feedbackRow-{$ruleCode}">
                            <tr>{
                                for $th in $recordDetails[1]//td return <th>{ data($th/@title) }</th>
                            }</tr>
                            {$recordDetails}
                        </table>
                    </td>
                </tr>
            else if (count($invalidStrValues)  > 0) then
                <tr>
                    <td></td>
                    <td colspan="3">
                        <table style="display:none;margin-top:1em;" id="feedbackRow-{$ruleCode}">
                            <tr style="font-size: 0.9em;color:#666666;">
                                <td></td>
                                <th colspan="3" style="text-align:right;vertical-align:top;background-color:#F6F6F6;font-weight: bold;">{ $valueHeading}</th>
                                <td style="font-style:italic;vertical-align:top;">{ string-join($invalidStrValues, ", ")}</td>
                            </tr>
                        </table>
                    </td>
                </tr>

            else
                ()
        )
    return $result

};

declare function html:buildResultRowsWithTotalCount_D($ruleCode as xs:string, $longText, $text, $invalidStrValues as xs:string*, $invalidValues as element()*,
        $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string,$recordDetails as element(tr)*)
as element(tr)*{

    let $countCheckedRecords := count($recordDetails)
    let $invalidValues := $recordDetails[./@isvalid = "false"]

    let $skippedMsg := if ($countCheckedRecords = 0) then "No values found to check" else ""
    let $invalidMsg := if (count($invalidValues) > 0) then concat(" invalid value", substring("s ", number(not(count($invalidValues) > 1)) * 2), " found out of ", $countCheckedRecords, " checked") else ""
    let $validMsg := if (count($invalidValues) = 0) then concat("Checked ", $countCheckedRecords, " value", substring("s", number(not($countCheckedRecords > 1)) * 2), ", all valid") else ""

    return
        html:buildResultRows_D($ruleCode, $longText, $text, $invalidStrValues, $invalidValues,
                $valueHeading, $validMsg, $invalidMsg, $skippedMsg,$errorLevel, ())
};

declare function html:buildResultRowsWithTotalCount_G($ruleCode as xs:string, $longText, $text, $invalidStrValues as xs:string*, $invalidValues as element()*,
        $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string, $recordDetails as element(tr)*)
as element(tr)*{

    let $countCheckedRecords := count($recordDetails)
    let $invalidValues := $recordDetails[./@isvalid = "false"]

    let $skippedMsg := if ($countCheckedRecords = 0) then "No values found to check" else ""
    let $invalidMsg := if (count($invalidValues) > 0) then concat(" invalid value", substring("s ", number(not(count($invalidValues) > 1)) * 2), " found out of ", $countCheckedRecords, " checked") else ""
    let $validMsg := if (count($invalidValues) = 0) then concat("Checked ", $countCheckedRecords, " value", substring("s", number(not($countCheckedRecords > 1)) * 2), ", all valid") else ""

    return
        html:buildResultRows_G($ruleCode, $longText, $text, $invalidStrValues, $invalidValues,
                $valueHeading, $validMsg, $invalidMsg, $skippedMsg, $errorLevel, ())
};


declare function html:buildResultRowsWithTotalCount_M($ruleCode as xs:string, $longText, $text, $invalidStrValues as xs:string*, $invalidValues as element()*,
        $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string,$recordDetails as element(tr)*)
as element(tr)*{

    let $countCheckedRecords := count($recordDetails)
    let $invalidValues := $recordDetails[./@isvalid = "false"]

    let $skippedMsg := if ($countCheckedRecords = 0) then "No values found to check" else ""
    let $invalidMsg := if (count($invalidValues) > 0) then concat(" invalid value", substring("s ", number(not(count($invalidValues) > 1)) * 2), " found out of ", $countCheckedRecords, " checked") else ""
    let $validMsg := if (count($invalidValues) = 0) then concat("Checked ", $countCheckedRecords, " value", substring("s", number(not($countCheckedRecords > 1)) * 2), ", all valid") else ""

    return
        html:buildResultRows_M($ruleCode, $longText, $text, $invalidStrValues, $invalidValues,
                $valueHeading, $validMsg, $invalidMsg, $skippedMsg,$errorLevel, ())
};