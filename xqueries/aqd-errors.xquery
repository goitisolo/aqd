xquery version "3.0";

(:~
: User: George Sofianos
: Date: 6/23/2016
: Time: 3:59 PM
:)

module namespace errors = "aqd-errors";


declare variable $errors:WARNING := "warning";
declare variable $errors:ERROR := "error";
declare variable $errors:INFO := "info";
declare variable $errors:SKIPPED := "skipped";
declare variable $errors:UNKNOWN := "unknown";
declare variable $errors:BLOCKER := "blocker";
declare variable $errors:FAILED := "failed";

declare variable $errors:COLOR_WARNING := "orange";
declare variable $errors:COLOR_ERROR := "red";
declare variable $errors:COLOR_INFO := "deepskyblue";
declare variable $errors:COLOR_SKIPPED := "grey";
declare variable $errors:COLOR_UNKNOWN := "grey";
declare variable $errors:COLOR_BLOCKER := "red";
declare variable $errors:COLOR_FAILED := "firebrick";

declare variable $errors:LOW_LIMIT := 100;
declare variable $errors:MEDIUM_LIMIT := 250;
declare variable $errors:HIGH_LIMIT := 500;
declare variable $errors:HIGHER_LIMIT := 1000;
declare variable $errors:MAX_LIMIT := 1500;
(: Returns error class if there are more than 0 error elements :)
declare function errors:getClass($elems) {
  if (count($elems) > 0) then
      "error"
  else
      "info"
};

declare function errors:getClassColor($class as xs:string) {
    switch ($class)
    case $errors:FAILED return $errors:COLOR_FAILED
    case $errors:ERROR return $errors:COLOR_ERROR
    case $errors:WARNING return $errors:COLOR_WARNING
    case $errors:INFO return $errors:COLOR_INFO
    default return $errors:COLOR_SKIPPED
};

declare function errors:getMaxError($records as element()*) as xs:string {
    if (count($records[@status = $errors:FAILED]) > 0) then $errors:FAILED
    else if (count($records[@class = $errors:FAILED]) > 0) then $errors:FAILED
    else if (count($records[@class = $errors:ERROR]) > 0) then $errors:ERROR
    else if (count($records[@class = $errors:WARNING]) > 0) then $errors:WARNING
    else if (count($records[@class = $errors:SKIPPED]) > 0) then $errors:SKIPPED
    else $errors:INFO
};