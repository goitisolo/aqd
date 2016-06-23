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
declare variable $errors:UNKNOWN := "unknown";
declare variable $errors:BLOCKER := "blocker";

(: Returns error class if there are more than 0 error elements :)
declare function errors:getClass($elems) {
  if (count($elems) > 0) then
      "error"
  else
      "info"
};