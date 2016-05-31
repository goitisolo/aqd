xquery version "3.0";

(:~
: User: dev-gso
: Date: 5/31/2016
: Time: 12:44 PM
: To change this template use File | Settings | File Templates.
:)

module namespace sparqlx = "aqd-sparql";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
(:~ declare Content Registry SPARQL endpoint:)
declare variable $sparqlx:CR_SPARQL_URL := "http://cr.eionet.europa.eu/sparql";
(:
 : ======================================================================
 :              SPARQL HELPER methods
 : ======================================================================
 :)
(:~ Function executes given SPARQL query and returns result elements in SPARQL result format.
 : URL parameters will be correctly encoded.
 : @param $sparql SPARQL query.
 : @return sparql:results element containing zero or more sparql:result subelements in SPARQL result format.
 :)
declare function sparqlx:executeSparqlQuery($sparql as xs:string) as element(sparql:results) {
    let $uri := sparqlx:getSparqlEndpointUrl($sparql, "xml")

    return
        fn:doc($uri)//sparql:results
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