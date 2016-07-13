xquery version "3.0";

(:~
: User: dev-gso
: Date: 5/31/2016
: Time: 12:44 PM
: To change this template use File | Settings | File Templates.
:)

module namespace sparqlx = "aqd-sparql";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
(:~ declare Content Registry SPARQL endpoint :)
declare variable $sparqlx:CR_SPARQL_URL := "http://cr.eionet.europa.eu/sparql";

(: ======================================================================
 :              SPARQL HELPER methods
 : ======================================================================
 :)
(:~ Function executes given SPARQL query and returns result elements in SPARQL result format.
 : URL parameters will be correctly encoded.
 : @param $sparql SPARQL query.
 : @return sparql:results element containing zero or more sparql:result subelements in SPARQL result format.
 :)
declare function sparqlx:executeSimpleSparqlQuery($sparql as xs:string) as element(sparql:results) {
    let $uri := sparqlx:getSparqlEndpointUrl($sparql, "xml")

    return
        fn:doc($uri)//sparql:results
};

(:TODO: Function to replace all SPARQL Calls :)
declare function sparqlx:run($sparql as xs:string) as element(sparql:result)* {
    doc("http://cr.eionet.europa.eu/sparql?query=" || encode-for-uri($sparql) || "&amp;format=application/xml")//sparql:result
};
(:~
 : Get the SPARQL endpoint URL.
 : @param $sparql SPARQL query.
 : @param $format xml or html.
 : @param $inference use inference when executing sparql query.
 : @return link to sparql endpoint
 :)
declare function sparqlx:getSparqlEndpointUrl($sparql as xs:string, $format as xs:string) as xs:string {
    let $sparql := fn:encode-for-uri(fn:normalize-space($sparql))
    let $resultFormat :=
        if ($format = "xml") then
            "application/xml"
        else if ($format = "html") then
            "text/html"
        else
            $format
    let $defaultGraph := ""
    let $uriParams := concat("query=", $sparql, "&amp;format=", $resultFormat, $defaultGraph)
    let $uri := concat($sparqlx:CR_SPARQL_URL, "?", $uriParams)
    return $uri
};

declare function sparqlx:toCountSparql($sparql as xs:string) as xs:string {
    let $s :=if (fn:contains($sparql,"order")) then tokenize($sparql, "order") else tokenize($sparql, "ORDER")
    let $firstPart := tokenize($s[1], "SELECT")
    let $secondPart := tokenize($s[1], "WHERE")
    return concat($firstPart[1], " SELECT count(*) WHERE ", $secondPart[2])
};

declare function sparqlx:countsSparqlResults($sparql as xs:string) as xs:integer {
    let $countingSparql := sparqlx:toCountSparql($sparql)
    let $endpoint := sparqlx:executeSimpleSparqlQuery($countingSparql)

    (: Counting all results:)
    let $count :=  $countingSparql
    let $isCountAvailable := string-length($count) > 0 and doc-available(sparqlx:getSparqlEndpointUrl($count, "xml"))
    let $countResult := if($isCountAvailable) then (data($endpoint//sparql:binding[@name='callret-0']/sparql:literal)) else 0
    return $countResult[1]
};

declare function sparqlx:executeSparqlQuery($sparql as xs:string) as element(sparql:result)* {
    let $limit := number(2000)
    let $countResult := sparqlx:countsSparqlResults($sparql)

    (:integer - how many times must sparql function repeat :)
    let $divCountResult := if($countResult>0) then ceiling(number($countResult) div number($limit)) else number("1")

    (:Collects all sparql results:)
    let $allResults :=
        for $r in (1 to  xs:integer(number($divCountResult)))
        let $offset := if ($r > 1) then string(((number($r)-1) * $limit)) else "0"
        let $resultXml := sparqlx:setLimitAndOffset($sparql,xs:string($limit), $offset)
        let $isResultsAvailable := string-length($resultXml) > 0 and doc-available(sparqlx:getSparqlEndpointUrl($resultXml, "xml"))
        let $result := if($isResultsAvailable) then sparqlx:executeSimpleSparqlQuery($resultXml)//sparql:result else ()
        return $result

    return  $allResults
};

declare function sparqlx:setLimitAndOffset($sparql as xs:string, $limit as xs:string, $offset as xs:string) as xs:string {
    concat($sparql," offset ",$offset," limit ",$limit)
};


(:---------------------------------Old xmlconv:executeSparqlQuery function----------------------------------------------------------------------:)
(:~ Function executes given SPARQL query and returns result elements in SPARQL result format.
 : URL parameters will be correctly encoded.
 : @param $sparql SPARQL query.
 : @return sparql:results element containing zero or more sparql:result subelements in SPARQL result format.
 :)
declare function sparqlx:executeSparqlEndpoint_D($sparql as xs:string)
as element(sparql:results)
{
    let $uri := sparqlx:getSparqlEndpointUrl($sparql, "xml")

    return
        if(doc-available($uri))then
            fn:doc($uri)//sparql:results
        else
            <sparql:results/>

};