xquery version "3.0" encoding "UTF-8";
(:
 : Module Name: Implementing Decision 2011/850/EU: AQ info exchange & reporting (Library module)
 :
 : Version:     $Id$
 : Created:     13 September 2013
 : Copyright:   European Environment Agency
 :
 : XQuery script implements dataflow C tier-1 checks as documented in http://taskman.eionet.europa.eu/documents/3 .
 :
 : @author Enriko Käsper
 : @author George Sofianos
 : small modification added by Jaume Targa (ETC/ACM) to align with QA document & polish some checks
 :)

module namespace dataflowC = "http://converters.eionet.europa.eu/dataflowC";
import module namespace common = "aqd-common" at "aqd-common.xquery";
import module namespace sparqlx = "aqd-sparql" at "aqd-sparql.xquery";
import module namespace labels = "aqd-labels" at "aqd-labels.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";
import module namespace vocabulary = "aqd-vocabulary" at "aqd-vocabulary.xquery";
import module namespace dd = "aqd-dd" at "aqd-dd.xquery";
import module namespace filter = "aqd-filter" at "aqd-filter.xquery";
import module namespace query = "aqd-query" at "aqd-query.xquery";
import module namespace errors = "aqd-errors" at "aqd-errors.xquery";
import module namespace schemax = "aqd-schema" at "aqd-schema.xquery";
import module namespace checks = "aqd-checks" at "aqd-checks.xq";
import module namespace functx = "http://www.functx.com" at "functx-1.0-doc-2007-01.xq";

declare namespace aqd = "http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0";
declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace am = "http://inspire.ec.europa.eu/schemas/am/3.0";
declare namespace ef = "http://inspire.ec.europa.eu/schemas/ef/3.0";
declare namespace base = "http://inspire.ec.europa.eu/schemas/base/3.3";
declare namespace ad = "urn:x-inspire:specification:gmlas:Addresses:3.0";
declare namespace gn = "urn:x-inspire:specification:gmlas:GeographicalNames:3.0";
declare namespace base2 = "http://inspire.ec.europa.eu/schemas/base2/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace om = "http://www.opengis.net/om/2.0";
declare namespace swe = "http://www.opengis.net/swe/2.0";
declare namespace ompr="http://inspire.ec.europa.eu/schemas/ompr/2.0";
declare namespace sams="http://www.opengis.net/samplingSpatial/2.0";
declare namespace sam = "http://www.opengis.net/sampling/2.0";
declare namespace gmd = "http://www.isotc211.org/2005/gmd";
declare namespace gco = "http://www.isotc211.org/2005/gco";

declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace prop = "http://dd.eionet.europa.eu/property/";
declare namespace adms = "http://www.w3.org/ns/adms#";


declare variable $dataflowC:ISO2_CODES as xs:string* := ("AL","AT","BA","BE","BG","CH","CY","CZ","DE","DK","DZ","EE","EG","ES","FI",
    "FR","GB","GR","HR","HU","IE","IL","IS","IT","JO","LB","LI","LT","LU","LV","MA","ME","MK","MT","NL","NO","PL","PS","PT",
     "RO","RS","SE","SI","SK","TN","TR","XK","UK");
declare variable $dataflowC:VALID_POLLUTANT_IDS as xs:string* := ("1", "7", "8", "9", "5", "6001", "10","20", "5012", "5014", "5015", "5018", "5029");
declare variable $dataflowC:VALID_POLLUTANT_IDS_18 as xs:string* := ("5014", "5015", "5018", "5029");
declare variable $dataflowC:MANDATORY_POLLUTANT_IDS_8 as xs:string* := ("1","7","8","9","5","6001","10","20","5012","5014","5015","5018","5029");
declare variable $dataflowC:UNIQUE_POLLUTANT_IDS_9 as xs:string* := ("1","7","8","9","5","6001","10","20","5012","5014","5015","5018","5029","1045",
"1046","1047","1771","1772","1629","1659","1657","1668","1631","2012","2014","2015","2018","7013","4013","4813","653","5013","5610","5617","5759",
"5626","5655","5763","7029","611","618","760","627","656","7419","20","428","430","432","503","505","394","447","6005","6006","6007","24","486",
"316","6008","6009","451","443","316","441","475","449","21","431","464","482","6011","6012","32","25");

declare variable $dataflowC:VALID_POLLUTANT_IDS_19 as xs:string* := ("1045","1046","1047","1771","1772","1629","1659","1657","1668","1631","2012","2014","2015","2018","7013","4013","4813","653","5013","5610","5617",
"5759","5626","5655","5763","7029","611","618","760","627","656","7419","428","430","432","503","505","394","447","6005","6006","6007","24","486","316","6008","6009","451","443","441","475","449","21","431","464",
"482","6011","6012","32","25");

declare variable $dataflowC:VALID_POLLUTANT_IDS_27 as xs:string* := ('1045','1046','1047','1771','1772','1629','1659','1657','1668','1631','2012','2014','2015','2018','7013','4013','4813','653','5013','5610','5617',
'5759','5626','5655','5763','7029','611','618','760','627','656','7419','20','428','430','432','503','505','394','447','6005','6006','6007','24','486','316','6008','6009',
'451','443','316','441','475','449','21','431','464','482','6011','6012','32','25','6001');

declare variable $dataflowC:VALID_POLLUTANT_IDS_40 as xs:string* := ($dataflowC:MANDATORY_POLLUTANT_IDS_8, $dataflowC:UNIQUE_POLLUTANT_IDS_9);

declare variable $dataflowC:VALID_POLLUTANT_IDS_21 as xs:string* := ("1","8","9","10","5","6001","5014","5018","5015","5029","5012","20");
declare variable $dataflowC:OBLIGATIONS as xs:string* := ($vocabulary:ROD_PREFIX || "671", $vocabulary:ROD_PREFIX || "694");
(: Rule implementations :)
declare function dataflowC:checkReport($source_url as xs:string, $countryCode as xs:string) as element(table) {

let $ms1Total := prof:current-ms()

let $ms1GeneralParameters:= prof:current-ms()
(: SETUP COMMON VARIABLES :)
let $envelopeUrl := common:getEnvelopeXML($source_url)
let $docRoot := doc($source_url)
let $cdrUrl := common:getCdrUrl($countryCode)
let $bdir := if (contains($source_url, "c_preliminary")) then "b_preliminary/" else "b/"
let $cdir := if (contains($source_url, "c_preliminary")) then "c_preliminary/" else "c/"
let $zonesUrl := concat($cdrUrl, $bdir)
let $reportingYear := common:getReportingYear($docRoot)
let $latestEnvelopeBperYear := query:getLatestEnvelope($zonesUrl, $reportingYear)
let $prelimEnvelopeC := query:getLatestEnvelope($cdrUrl || "c_preliminary/", $reportingYear)
let $namespaces := distinct-values($docRoot//base:namespace)



let $latestEnvelopeB := query:getLatestEnvelope($cdrUrl || $bdir)
let $latestEnvelopeC := query:getLatestEnvelope($cdrUrl || $cdir, $reportingYear)
let $latestEnvelopeD := query:getLatestEnvelope($cdrUrl || "d/")
let $latestEnvelopeD1b := query:getLatestEnvelope($cdrUrl || "d1b/", $reportingYear)
let $getEnvelopeD1b := query:getEnvelopes($cdrUrl || "d1b/")
let $knownRegimes := distinct-values(data(sparqlx:run(query:getAssessmentRegime($latestEnvelopeC))/sparql:binding[@name = 'inspireLabel']/sparql:literal))
let $allRegimes := query:getAllRegimeIds($namespaces)
let $countRegimes := count($docRoot//aqd:AQD_AssessmentRegime)

let $zoneIds := if ((fn:string-length($countryCode) = 2) and exists($latestEnvelopeB)) then distinct-values(data(sparqlx:run(query:getZone($latestEnvelopeB))//sparql:binding[@name = 'inspireLabel']/sparql:literal)) else ()
let $countZoneIds1 := count($zoneIds)
let $countZoneIds2 := count(distinct-values($docRoot//aqd:AQD_AssessmentRegime/aqd:zone/@xlink:href))

let $headerBeginPosition := $docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:beginPosition
let $headerEndPosition := $docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:endPosition


let $latestModels :=
    try {
        distinct-values(data(sparqlx:run(query:getModel($latestEnvelopeD1b))//sparql:binding[@name = 'inspireLabel']/sparql:literal))
    } catch * {
        ()
    }
let $modelsEnvelope := if (empty($latestModels)) then $latestEnvelopeD else $latestEnvelopeD1b



let $latestModels :=
    try {
        if (empty($latestModels)) then distinct-values(data(sparqlx:run(query:getModel($latestEnvelopeD))//sparql:binding[@name = 'inspireLabel']/sparql:literal)) else $latestModels
    } catch * {
        ()
    }
let $latestSamplingPoints := data(sparqlx:run(query:getSamplingPoint($latestEnvelopeD))/sparql:binding[@name = 'inspireLabel']/sparql:literal)


let $models := 
            for $x in $getEnvelopeD1b
                let $test := data(sparqlx:run(query:getModelSampling2($x)))
            return $test

let $latestModels2 :=
    try {
        distinct-values(data($models))
    } catch * {
        ()
    }
let $modelsEnvelope2 := if (empty($latestModels2)) then $latestEnvelopeD else $getEnvelopeD1b


let $ms2GeneralParameters:= prof:current-ms()
(: File prefix/namespace check :)

let $ms1NS := prof:current-ms()
let $NSinvalid :=
    try {
        let $XQmap := inspect:static-context((), 'namespaces')
        let $fileMap := map:merge((
            for $x in in-scope-prefixes($docRoot/*)
            return map:entry($x, string(namespace-uri-for-prefix($x, $docRoot/*)))))

        return map:for-each($fileMap, function($a, $b) {
            let $x := map:get($XQmap, $a)
            return
                if ($x != "" and not($x = $b)) then
                    <tr>
                        <td title="Prefix">{$a}</td>
                        <td title="File namespace">{$b}</td>
                        <td title="XQuery namespace">{$x}</td>
                    </tr>
                else
                    ()
        })
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
   let $ms2NS := prof:current-ms()
(: VOCAB check:)
let $VOCABinvalid := checks:vocab($docRoot)

(: C0 :)
let $ms1C0 := prof:current-ms()
let $C0table :=
    try {
        if ($reportingYear = "") then
            <tr class="{$errors:ERROR}">
                <td title="Status">Reporting Year is missing.</td>
            </tr>
        else if($headerBeginPosition > $headerEndPosition) then
            <tr class="{$errors:BLOCKER}">
                <td title="Status">Start position must be less than end position</td>
            </tr>
        else if (query:deliveryExists($dataflowC:OBLIGATIONS, $countryCode, $cdir, $reportingYear)) then
            <tr class="{$errors:WARNING}">
                <td title="Status">Updating delivery for {$reportingYear}</td>
            </tr>
        else
            <tr class="{$errors:INFO}">
                <td title="Status">New delivery for {$reportingYear}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
    let $ms2C0 := prof:current-ms()
let $isNewDelivery := errors:getMaxError($C0table) = $errors:INFO

(: C01 :)
let $ms1C01 := prof:current-ms()
let $C01table :=
    try {
        for $rec in $docRoot//aqd:AQD_AssessmentRegime
        return
            <tr>
                <td title="gml:id">{data($rec/@gml:id)}</td>
                <td title="base:localId">{data($rec/aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="base:namespace">{data($rec/aqd:inspireId/base:Identifier/base:namespace)}</td>
                <td title="aqd:zone">{common:checkLink(data($rec/aqd:zone/@xlink:href))}</td>
                <td title="aqd:pollutant">{common:checkLink(data($rec/aqd:pollutant/@xlink:href))}</td>
                <td title="aqd:protectionTarget">{common:checkLink(data($rec/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2C01 := prof:current-ms()

(: C02 :)

let $ms1C02 := prof:current-ms()
let $C02table :=
    try {
        for $x in $docRoot//aqd:AQD_AssessmentRegime
        let $id := $x/aqd:inspireId/base:Identifier/base:namespace || "/" || $x/aqd:inspireId/base:Identifier/base:localId
        where (not($knownRegimes = $id))
        return
            <tr>
                    <td title="gml:id">{data($x/@gml:id)}</td>
                <td title="base:localId">{data($x/aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="base:namespace">{data($x/aqd:inspireId/base:Identifier/base:namespace)}</td>
                <td title="aqd:zone">{common:checkLink(data($x/aqd:zone/@xlink:href))}</td>
                <td title="aqd:pollutant">{common:checkLink(data($x/aqd:pollutant/@xlink:href))}</td>
                <td title="aqd:protectionTarget">{common:checkLink(data($x/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href))}</td>
                <td title="Sparql">{sparqlx:getLink(query:getAllRegimeIdsQuery($namespaces))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $C02errorLevel :=
    if ($isNewDelivery and count(
        for $x in $docRoot//aqd:AQD_AssessmentRegime
        let $id := $x/aqd:inspireId/base:Identifier/base:namespace || "/" || $x/aqd:inspireId/base:Identifier/base:localId
        where ($allRegimes = $id)
        return 1) > 0) then
            $errors:C02
    else
        $errors:INFO


let $ms2C02 := prof:current-ms()

(: C03 :)

let $ms1C03 := prof:current-ms()
let $C03table :=
    try {
        for $x in $docRoot//aqd:AQD_AssessmentRegime
        let $id := $x/aqd:inspireId/base:Identifier/base:namespace || "/" || $x/aqd:inspireId/base:Identifier/base:localId
        where ($knownRegimes = $id)
        return
            <tr>
                <td title="gml:id">{data($x/@gml:id)}</td>
                <td title="base:localId">{data($x/aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="base:versionId">{data($x/aqd:inspireId/base:Identifier/base:versionId)}</td>
                <td title="base:namespace">{data($x/aqd:inspireId/base:Identifier/base:namespace)}</td>
                <td title="aqd:zone">{common:checkLink(data($x/aqd:zone/@xlink:href))}</td>
                <td title="aqd:pollutant">{common:checkLink(data($x/aqd:pollutant/@xlink:href))}</td>
                <td title="aqd:protectionTarget">{common:checkLink(data($x/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $C03errorLevel :=
    if (not($isNewDelivery) and count($C03table) = 0) then
        $errors:C03
    else
        $errors:INFO


let $ms2C03 := prof:current-ms()

(:C03a:)
(:Compare CPreliminary assesment method vs list of C assesment method:)

let $ms1C03a := prof:current-ms()

let $C03afunc :=
try{
    let $previousCombinations := query:getC03a($prelimEnvelopeC)
    let $previousCombinations_query := sparqlx:getLink(query:getC03aQuery($prelimEnvelopeC))
    let $assesmentRegimeInC :=
        for $x in $docRoot//aqd:AQD_AssessmentRegime
            let $localIdInC := $x//base:localId => string()
            let $namespace := $x//base:namespace => string()
        return $localIdInC
    
    
    for $x in $previousCombinations
     let $localId := $x

    where not($x = $assesmentRegimeInC)
    (:let $assessmentCPrelimi := tokenize($x, "###")[2]:)
    
    return
        if(not(contains($source_url, "c_preliminary"))) then 
        <tr>
            <td title="Assessment Regime (C preliminary) not found in C">{$localId}</td>
            <td title="Assessment Regime (C) not found in C preliminary"></td>
            <td title="Sparql">{$previousCombinations_query}</td>
        </tr>
    else()
        }
        catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2C03a := prof:current-ms()

(:Compare  C assesment method vs list of CPreliminary assesment method:)

let $ms1C03a2 := prof:current-ms()

let $C03a2func :=
try{
    let $previousCombinations := query:getC03a($prelimEnvelopeC)
    let $previousCombinations_query := sparqlx:getLink(query:getC03aQuery($prelimEnvelopeC))
    let $assesmentRegimeInCPreliminary :=
        for $x in $previousCombinations
        return $x
    
    for $x in $docRoot//aqd:AQD_AssessmentRegime
        let $localIdInC := $x//base:localId => string()
     

    where not($assesmentRegimeInCPreliminary = $localIdInC)
    
    return
        if(not(contains($source_url, "c_preliminary"))) then
        <tr>
            <td title="Assessment Regime (C preliminary) not found in C"></td>
            <td title="Assessment Regime (C) not found in C preliminary">{$localIdInC}</td>
            <td title="Sparql">{$previousCombinations_query}</td>
        </tr>
        else()
        }
        catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

    
    let $ms2C03a2 := prof:current-ms()


let $ms1C03b := prof:current-ms()
let $C03b :=
    let $previousCombinations := query:getC03b($prelimEnvelopeC)
    let $previousCombinations_query := sparqlx:getLink(query:getC03bquery($prelimEnvelopeC))
    let $currentCombinations :=
     for $x in $docRoot//aqd:AQD_AssessmentRegime
        let $localId := $x//base:localId => string()
        let $namespace := $x//base:namespace => string()
             for $i in $x/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata/@xlink:href
                 let $samplingpoint := substring-after($i, $namespace || "/")
                 let $combination := string-join(($localId || "###" || $samplingpoint))
     return $combination

    for $x in $previousCombinations
        let $localId := tokenize($x, "###")[1]
        let $samplingPoint := tokenize($x, "###")[2]
    where not($x = $currentCombinations)
    return
         <result>
                <xPreviousComb>{$x}</xPreviousComb>
                <samplingPoint>{$samplingPoint}</samplingPoint>
                <query>{$previousCombinations_query}</query>
        </result>

let $C03bfunc :=
try{
    
    let $count := count($C03b)
    for $i in $C03b
         let $previousComb:= $i/xPreviousComb
         let $samplin := $i/samplingPoint
         let $sparql := $i/query
         
    where not($count = 0)

    return
      if(not(contains($source_url, "c_preliminary"))) then 
        <tr>
            <td title="Assessment Regime (C)">{$previousComb}</td>
            <td title="Missing SamplingPoint compared to C preliminary">{$samplin}</td>
            <td title="Sparql">{$sparql}</td>
        </tr>
      else()
        }
        catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2C03b := prof:current-ms()

(: C03c :)
(:let $C03cfunc := 
    try {   
        let $previousCombinations := sparqlx:run(query:getC03c($prelimEnvelopeC))
        let $previousCombinationsConcat :=
            for $x in $previousCombinations
            
       
            return $x/sparql:binding[@name="localId"]/sparql:literal || "###" || $x/sparql:binding[@name="samplingPoint"]/sparql:literal || "###" || substring-after($x/sparql:binding[@name="assessmentType"]/sparql:uri, "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/")
     

        let $currentCombinations :=
            for $x in $docRoot//aqd:AQD_AssessmentRegime

                let $localId := $x//base:localId => string()
                let $namespace := $x//base:namespace => string()
                
                for $i in $x/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata/@xlink:href

                    let $samplingpoint := substring-after($i, $namespace || "/")
                        for $j in $x/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:assessmentType/@xlink:href
                        let $assessmentType := substring-after($j, "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/")
            
            let $combination := string-join(($localId || "###" || $samplingpoint|| "###" || $assessmentType))
            return $combination

        for $x at $j in $previousCombinationsConcat 
            let $localId := tokenize($x, "###")[1]
            let $samplingPoint := tokenize($x, "###")[2]    
            let $typeCPrel := tokenize($x, "###")[3] 
       
        
        where not($x = $currentCombinations)
        

        return
            <tr>
                <td title="Assessment Regime (C)">{$localId}</td>
                <td title="aqd:AQD_SamplingPoint">{$samplingPoint}</td>
                <td title="Assessment Type in C preliminary">{$typeCPrel}</td> 
              

            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }:)


(: C03c 
let $C03cfunc := 
    try {   
        let $previousCombinations := sparqlx:run(query:getC03c($prelimEnvelopeC))
        let $previousCombinationsConcat :=
            for $x in $previousCombinations
            
                 return
                    <result>
                        <localId>{string($x/sparql:binding[@name="localId"]/sparql:literal)}</localId>
                        <samplingPoint>{string($x/sparql:binding[@name="samplingPoint"]/sparql:literal)}</samplingPoint>
                        <assessmentType>{string(substring-after($x/sparql:binding[@name="assessmentType"]/sparql:uri, "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/"))}</assessmentType>                        
                    </result>
            
     

        let $currentCombinations :=
            for $x in $docRoot//aqd:AQD_AssessmentRegime

                let $localId := $x//base:localId => string()
                let $namespace := $x//base:namespace => string()
                
                for $i in $x/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata/@xlink:href

                    let $samplingpoint := substring-after($i, $namespace || "/")
                        for $j in $x/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:assessmentType/@xlink:href
                        let $assessmentType := substring-after($j, "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/")
                        return
                         <result>
                            <localId>{$localId}</localId>
                            <samplingPoint>{$samplingpoint}</samplingPoint>
                            <assessmentType>{$assessmentType}</assessmentType>                            
                         </result>
            
           

        for $x in $previousCombinationsConcat 
            let $localId := string($x/localId)
            let $samplingPoint := string($x/samplingPoint)  
            let $typeCPrel :=string($x/assessmentType) 
            let $typeC:=
             for $i in $currentCombinations 
                let $TypeTemp:=
                     if ($i[localId = $localId and samplingPoint = $samplingPoint]) then 
                         string($i/assessmentType)
                    else ()
                    return $TypeTemp
        
        where not($typeCPrel = $typeC)  and not($typeC='')    

        return
            <tr>
                <td title="Assessment Regime (C)">{$localId}</td>
                <td title="aqd:AQD_SamplingPoint">{$samplingPoint}</td>
                <td title="Assessment Type in C preliminary">{$typeCPrel}</td> 
                <td title="Assessment Type in C">{$typeC}</td>
    

            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }:)


(: C03c :)

let $ms1C03c := prof:current-ms()

(:let $C03cfunc := 
    try {   
        let $previousCombinations := sparqlx:run(query:getC03c($prelimEnvelopeC))
        let $previousCombinationsConcat :=
            for $x in $previousCombinations
            
                 return
                    <result>
                        <localId>{string($x/sparql:binding[@name="localId"]/sparql:literal)}</localId>
                        <samplingPoint>{string($x/sparql:binding[@name="samplingPoint"]/sparql:literal)}</samplingPoint>
                        <assessmentType>{string(substring-after($x/sparql:binding[@name="assessmentType"]/sparql:uri, "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/"))}</assessmentType>                        
                    </result>

        let $currentCombinations :=
            for $x in $docRoot//aqd:AQD_AssessmentRegime

                let $localId := $x//base:localId => string()
                let $namespace := $x//base:namespace => string()
                
                for $i in $x/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata/@xlink:href

                    let $samplingpoint := substring-after($i, $namespace || "/")
                        for $j in $x/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:assessmentType/@xlink:href
                        let $assessmentType := substring-after($j, "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/")
                        return
                         <result>
                            <localId>{$localId}</localId>
                            <samplingPoint>{$samplingpoint}</samplingPoint>
                            <assessmentType>{$assessmentType}</assessmentType>
                         </result>
        
        let $C03Blist :=
            for $x in $C03b
                let $C03blisted := $x/xPreviousComb
            return $C03blisted

        for $x in $previousCombinationsConcat

            let $localId := string($x/localId)
            let $samplingPoint := string($x/samplingPoint)  
            let $typeCPrel :=string($x/assessmentType) 
            let $combination := string-join(($localId || "###" || $samplingPoint))
            
            let $C03Bquery :=
            for $x in $C03b
                let $C03blisted := $x[xPreviousComb != combination, 1]/query
            return $C03blisted
            
            let $typeC:=

             for $i in $currentCombinations
                 let $TypeTemp:=
                     if ($i[localId = $localId and samplingPoint = $samplingPoint]) then 
                         string($i/assessmentType)
                    else ()

                    return $TypeTemp

                 
            where not($typeCPrel = $typeC) and not($combination = $C03Blist)
            return
      if(not(contains($source_url, "c_preliminary"))) then 
            <tr>
               <td title="Assessment Regime">{$localId}</td>
                <td title="aqd:AQD_SamplingPoint">{$samplingPoint}</td>
                <td title="Assessment Type in C">{$typeC}</td>
                <td title="Assessment Type in C preliminary">{$typeCPrel}</td> 
                <td title="Sparql">{sparqlx:getLink(query:getC03c($prelimEnvelopeC))}</td>
            </tr>
        else()
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }:)
let $C03cfunc :=
    try {  
        let $previousCombinations := sparqlx:run(query:getC03c($prelimEnvelopeC))
        let $previousCombinationsConcat :=
            for $x in $previousCombinations
           
                 return
                    <result>
                        <localId>{string($x/sparql:binding[@name="localId"]/sparql:literal)}</localId>
                        <samplingPoint>{string($x/sparql:binding[@name="samplingPoint"]/sparql:literal)}</samplingPoint>
                        <assessmentType>{string(substring-after($x/sparql:binding[@name="assessmentType"]/sparql:uri, "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/"))}</assessmentType>          
                        <combination>string-join(string($x/sparql:binding[@name="localId"]/sparql:literal) || "###" || string(substring-after($x/sparql:binding[@name="assessmentType"]/sparql:uri, "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/"))</combination>              
                    </result>

      let $currentCombinations :=
            for $x in $docRoot//aqd:AQD_AssessmentRegime

                let $localId := $x//base:localId => string()
                let $namespace := $x//base:namespace => string()
               
                for $j in $x/aqd:assessmentMethods/aqd:AssessmentMethods

                 let $assessmentType := substring-after($j/aqd:assessmentType/@xlink:href, "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/")
                 
                  for $i in $j/aqd:samplingPointAssessmentMetadata/@xlink:href

                    let $samplingpoint := substring-after($i, $namespace || "/")
                       
                        return
                         <result>
                            <localId>{$localId}</localId>
                            <samplingPoint>{$samplingpoint}</samplingPoint>
                            <assessmentType>{$assessmentType}</assessmentType>
                         </result>
       
      for $x in $currentCombinations

            let $localId := string($x/localId)
            let $samplingPoint := string($x/samplingPoint)  
            let $typeCPrel :=string($x/assessmentType) 
            let $combination := string-join(($localId || "###" || $samplingPoint))
            
            
            
            let $typeC:=

             for $i in $previousCombinationsConcat
                 let $TypeTemp:=
                     if ($i[localId = $localId and samplingPoint = $samplingPoint]) then 
                         string($i/assessmentType)
                    else ()
                    where $i/localId = $localId and $i/samplingPoint = $samplingPoint
                    return 
                    <result>
                            <localId>{$i/localId}</localId>
                            <samplingPoint>{$i/samplingPoint}</samplingPoint>
                            <assessmentType>{$i/assessmentType}</assessmentType>
                         </result>

                 
            where not($typeCPrel = $typeC/assessmentType) and not(functx:if-empty($typeC/assessmentType, '') = '') 
            
            return
      if(not(contains($source_url, "c_preliminary"))) then
            <tr>
               <td title="Assessment Regime XML">{$localId}</td>
                <td title="aqd:AQD_SamplingPoint  XML">{$samplingPoint}</td>
                <td title="Assessment Type in C  XML">{$typeCPrel}</td>
                <td title="Assessment Regime SPARQL">{$typeC/localId}</td>
                <td title="aqd:AQD_SamplingPoint SPARQL">{$typeC/samplingPoint}</td>
                <td title="Assessment Type in C preliminary SPARQL">{$typeC/assessmentType}</td>
                <td title="Sparql">{sparqlx:getLink(query:getC03c($prelimEnvelopeC))}</td>
            </tr>
        else()
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

  let $ms2C03c := prof:current-ms()

(: C03d :)

let $ms1C03d := prof:current-ms()

let $C03dinvalid := 
    try {
        let $previousCombinations := query:getC03b($prelimEnvelopeC)
        let $previousCombinations_query := sparqlx:getLink(query:getC03bquery($prelimEnvelopeC))
        let $currentCombinations :=
        for $x in $docRoot//aqd:AQD_AssessmentRegime

        let $localId := $x//base:localId => string()
        let $namespace := $x//base:namespace => string()
        for $i in $x/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata/@xlink:href
        let $samplingpoint := substring-after($i, $namespace || "/")
        let $combination := string-join(($localId || "###" || $samplingpoint))
        return $combination

        for $x in $currentCombinations
        let $localId := tokenize($x, "###")[1]
        let $samplingPoint := tokenize($x, "###")[2]
        where not($x = $previousCombinations)

     
        return
         if(not(contains($source_url, "c_preliminary"))) then 
            <tr>
                <td title="Assessment Regime (C)">{$localId}</td>
                <td title="New SamplingPoint compared to C preliminary">{$samplingPoint}</td>
                <td title="Sparql">{sparqlx:getLink(query:getC03bquery($prelimEnvelopeC))}</td>
            </tr>
      else()
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ms2C03d := prof:current-ms()

(: C04 - duplicate @gml:ids :)

let $ms1C04 := prof:current-ms()

let $C04invalid :=
    try {
        let $gmlIds := $docRoot//aqd:AQD_AssessmentRegime/lower-case(normalize-space(@gml:id))
        for $id in $docRoot//aqd:AQD_AssessmentRegime/@gml:id
        where count(index-of($gmlIds, lower-case(normalize-space($id)))) > 1
        return
            <tr>
                <td title="@gml:id">{$id}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2C04 := prof:current-ms()

(: C05 - duplicate ./aqd:inspireId/base:Identifier/base:localId :)

let $ms1C05 := prof:current-ms()

let $C05invalid :=
    try {
        let $localIds := $docRoot//aqd:AQD_AssessmentRegime/aqd:inspireId/base:Identifier/lower-case(normalize-space(base:localId))
        for $id in $docRoot//aqd:inspireId/base:Identifier/base:localId
        where count(index-of($localIds, lower-case(normalize-space($id)))) > 1
        return
            <tr>
                <td title="base:localId">{$id}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

    let $ms2C05 := prof:current-ms()

(: C06 - :)

let $ms1C06 := prof:current-ms()

let $C06table :=
    try {
        let $allBaseNamespace := distinct-values($docRoot//aqd:AQD_AssessmentRegime/aqd:inspireId/base:Identifier/base:namespace)
        for $id in $allBaseNamespace
        let $localId := $docRoot//aqd:AQD_AssessmentRegime/aqd:inspireId/base:Identifier[base:namespace = $id]/base:localId
        return
            <tr>
                <td title="base:namespace">{$id}</td>
                <td title="base:localId">{count($localId)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2C06 := prof:current-ms()
        
(: C06.1 :)

let $ms1C06.1 := prof:current-ms()

let $C06.1invalid :=
    try {
        let $vocDoc := doc($vocabulary:NAMESPACE || "rdf")
        let $prefLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE and @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)]/skos:prefLabel[1]
        let $altLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE and @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)]/skos:altLabel[1]
        for $x in distinct-values($docRoot//base:namespace)
        where (not($x = $prefLabel) and not($x = $altLabel))
        return
            <tr>
                <td title="base:namespace">{$x}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2C06.1 := prof:current-ms()

(: C07 :)
let $ms1C07 := prof:current-ms()

let $C07invalid :=
    try {
        for $aqdAQD_AssessmentRegim in $docRoot//aqd:AQD_AssessmentRegime
        where $aqdAQD_AssessmentRegim[count(aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href) = 0]
        return
            <tr>
                <td title="base:localId">{string($aqdAQD_AssessmentRegim/aqd:inspireId/base:Identifier/base:localId)}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2C07 := prof:current-ms()

(: C08 - if a regime is missing for a pollutant in the list, warning should be thrown :)

let $ms1C08 := prof:current-ms()

let $C08invalid :=
    try {
        let $mandatory := ("1","7","8","9","5","6001","10","20","5012","5014","5015","5018","5029")
        let $pollutants :=
            if ($countryCode = "gi") then remove($mandatory, index-of($mandatory, "9"))
            else $mandatory
        for $code in $pollutants
        let $pollutantLink := $vocabulary:POLLUTANT_VOCABULARY || $code
        where count($docRoot//aqd:AQD_AssessmentRegime/aqd:pollutant[@xlink:href = $pollutantLink]) < 1
        return
            <tr>
                <td title="Pollutant"><a href="{$pollutantLink}">{$code}</a></td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2C08 := prof:current-ms()

(: C09 - Provides a count of unique pollutants and lists them :)

let $ms1C09 := prof:current-ms()

let $C09table :=
    try {
        let $pollutants :=
            for $x in $docRoot//aqd:AQD_AssessmentRegime[aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO"]
            return $x/aqd:pollutant/@xlink:href/string()
        for $i in distinct-values($pollutants)
        return
            <tr>
                <td title="pollutant">{$i}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2C09 := prof:current-ms()

(: C10 :)

let $ms1C10 := prof:current-ms()

let $C10invalid :=
    try {
        let $exceptions := ($vocabulary:OBJECTIVETYPE_VOCABULARY || "MO")
        let $all :=
            for $x in doc($vocabulary:ENVIRONMENTALOBJECTIVE || "rdf")//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE]
            return $x/prop:relatedPollutant/@rdf:resource || "#" || $x/prop:hasObjectiveType/@rdf:resource || "#" || $x/prop:hasReportingMetric/@rdf:resource || "#" || $x/prop:hasProtectionTarget/@rdf:resource

        for $x in $docRoot//aqd:AQD_AssessmentRegime
        let $pollutant := $x/aqd:pollutant/@xlink:href
        let $objectiveType := $x/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href
        let $reportingMetric := $x/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href
        let $protectionTarget := $x/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href
        let $combination := $pollutant || "#" || $objectiveType || "#" || $reportingMetric || "#" || $protectionTarget
        where not($objectiveType = $exceptions) and not($combination = $all)
        return
            <tr>
                <td title="aqd:AQD_AssessmentRegime">{data($x/aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="Pollutant">{data($pollutant)}</td>
                <td title="ObjectiveType">{data($objectiveType)}</td>
                <td title="ReportingMetric">{data($reportingMetric)}</td>
                <td title="ProtectionTarget">{data($protectionTarget)}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2C10 := prof:current-ms()
(: C20 :)

let $ms1C20 := prof:current-ms()

let $C20invalid :=
    try {
        let $rdf := doc($vocabulary:ENVIRONMENTALOBJECTIVE || "rdf")
        let $rdf := distinct-values(
            for $x in $rdf//skos:Concept[string-length(prop:exceedanceThreshold) > 0]
            where not($x/prop:hasObjectiveType/@rdf:resource = ($vocabulary:OBJECTIVETYPE_VOCABULARY || "MO", $vocabulary:OBJECTIVETYPE_VOCABULARY || "LVMOT", $vocabulary:OBJECTIVETYPE_VOCABULARY || "LVmaxMOT"))
                and not($countryCode = "gi" and ($x/prop:hasObjectiveType/@rdf:resource = ($vocabulary:OBJECTIVETYPE_VOCABULARY || "ECO") or $x/prop:hasProtectionTarget/@rdf:resource = ($vocabulary:PROTECTIONTARGET_VOCABULARY || "V")))
            return $x/prop:relatedPollutant/@rdf:resource || "#" || $x/prop:hasObjectiveType/@rdf:resource || "#" || $x/prop:hasReportingMetric/@rdf:resource || "#" || $x/prop:hasProtectionTarget/@rdf:resource
        )
        let $exception := $vocabulary:POLLUTANT_VOCABULARY || "6001" || "#" || $vocabulary:OBJECTIVETYPE_VOCABULARY || "TV" || "#" || $vocabulary:REPMETRIC_VOCABULARY || "aMean" || "#" || $vocabulary:PROTECTIONTARGET_VOCABULARY || "H"
        let $rdf :=
            if (number($reportingYear) >= 2015 and index-of($rdf, $exception) > 0) then
                remove($rdf, index-of($rdf, $exception))
            else
                $rdf

        for $i in $rdf
            let $tokens := tokenize($i, "#")
        where count($docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentThreshold/aqd:AssessmentThreshold/
                aqd:environmentalObjective/aqd:EnvironmentalObjective[concat(../../../../aqd:pollutant/@xlink:href, "#", aqd:objectiveType/@xlink:href, "#", aqd:reportingMetric/@xlink:href, "#", aqd:protectionTarget/@xlink:href) = $i]) = 0
        return
            <tr>
                <td title="pollutant">{$tokens[1]}</td>
                <td title="objectiveType">{$tokens[2]}</td>
                <td title="reportingMetric">{$tokens[3]}</td>
                <td title="hasProtectionTarget">{$tokens[4]}</td>
            </tr>

    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2C20 := prof:current-ms()

(: C21 :)

let $ms1C21 := prof:current-ms()

let $C21invalid :=
    try {
        let $exceptions := ($vocabulary:OBJECTIVETYPE_VOCABULARY || "MO")
        let $environmentalObjectiveCombinations := doc($vocabulary:ENVIRONMENTALOBJECTIVE || "rdf")
        for $x in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
        let $pollutant := string($x/../../../../aqd:pollutant/@xlink:href)
        let $objectiveType := string($x/aqd:objectiveType/@xlink:href)
        let $reportingMetric := string($x/aqd:reportingMetric/@xlink:href)
        let $protectionTarget := string($x/aqd:protectionTarget/@xlink:href)
        let $exceedance := string($x/../../aqd:exceedanceAttainment/@xlink:href)
        where not($objectiveType = $exceptions) and (not($environmentalObjectiveCombinations//skos:Concept[prop:relatedPollutant/@rdf:resource = $pollutant and prop:hasProtectionTarget/@rdf:resource = $protectionTarget
                and prop:hasObjectiveType/@rdf:resource = $objectiveType and prop:hasReportingMetric/@rdf:resource = $reportingMetric
                and prop:assessmentThreshold/@rdf:resource = $exceedance]))
        return
            <tr>
                <td title="aqd:AQD_AssessmentRegime">{string($x/../../../../aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="Pollutant">{data($pollutant)}</td>
                <td title="ObjectiveType">{data($objectiveType)}</td>
                <td title="ReportingMetric">{data($reportingMetric)}</td>
                <td title="ProtectionTarget">{data($protectionTarget)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2C21 := prof:current-ms()

(: C23a :)

let $ms1C23a := prof:current-ms()

let $C23ainvalid :=
    try {
        (let $valid := for $i in ("fixed", "model", "indicative", "objective", "fixedrandom") return $vocabulary:ASSESSMENTTYPE_VOCABULARY || $i
        for $x in $docRoot//aqd:AQD_AssessmentRegime[count(aqd:assessmentMethods/aqd:AssessmentMethods/aqd:assessmentType/@xlink:href) > 0]/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:assessmentType
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="base:localId">{string($x/../../../aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:assessmentType">{data($x/@xlink:href)}</td>
            </tr>)[position() = 1 to $errors:MEDIUM_LIMIT]
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

    let $ms2C23a := prof:current-ms()

(: C23B - Warning :)

let $ms1C23b := prof:current-ms()

let $C23binvalid :=
    try {
        for $x in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods
            let $type := $x/aqd:assessmentType/@xlink:href
            let $desc := $x/aqd:assessmentTypeDescription
        where empty($desc) or data($desc = "")
        return
            <tr>
                <td title="base:localId">{string($x/../../aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:assessmentType">{data($type)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2C23b := prof:current-ms()

(: C24 :)

let $ms1C24 := prof:current-ms()

let $C24errorClass := if (contains($source_url, "c_preliminary")) then $errors:WARNING else $errors:C24
let $C24invalid :=
    try {
        for $x in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:modelAssessmentMetadata
        where not($x/@xlink:href = distinct-values($models)) 
        return
            <tr>
                <td title="aqd:AQD_AssessmentRegime">{string($x/../../../aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:modelAssessmentMetadata">{data($x/@xlink:href)}</td>
                <td title="Sparql">{sparqlx:getLink(query:getModelSampling2($getEnvelopeD1b[1]))}</td>
            </tr>

    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

    let $ms2C24 := prof:current-ms()
    
    (: C25 :)
    let $ms1C25 := prof:current-ms()

    let $C25invalid :=
    for $x in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata
    where not($x/@xlink:href = $latestSamplingPoints)
    return
        <tr>
            <td title="aqd:AQD_AssessmentRegime">{string($x/../../../aqd:inspireId/base:Identifier/base:localId)}</td>
            <td title="aqd:samplingPointAssessmentMetadata">{data($x/@xlink:href)}</td>
        </tr>

let $ms2C25 := prof:current-ms()

(: C26 - :)

let $ms1C26 := prof:current-ms()

let $C26table :=
    try {
        let $startDate := $reportingYear || "-01-01"
        let $endDate := $reportingYear || "-12-31"
        let $modelMethods := distinct-values(data(sparqlx:run(query:getModelEndPosition($modelsEnvelope, $startDate, $endDate))//sparql:binding[@name='inspireLabel']/sparql:literal))
        let $sampingPointMethods := distinct-values(data(sparqlx:run(query:getSamplingPointEndPosition($latestEnvelopeD,$startDate,$endDate))//sparql:binding[@name='inspireLabel']/sparql:literal))

        let $startDate := xs:string(xs:integer($reportingYear) - 2) || "-01-01"
        let $endDate := $reportingYear || "-12-31"
        let $modelMethods2Y := distinct-values(data(sparqlx:run(query:getModelEndPosition($modelsEnvelope, $startDate, $endDate))//sparql:binding[@name='inspireLabel']/sparql:literal))
        let $sampingPointMethods2Y := distinct-values(data(sparqlx:run(query:getSamplingPointEndPosition($latestEnvelopeD,$startDate,$endDate))//sparql:binding[@name='inspireLabel']/sparql:literal))

        let $startDate := xs:string(xs:integer($reportingYear) - 4) || "-01-01"
        let $endDate := $reportingYear || "-12-31"
        let $modelMethods4Y := distinct-values(data(sparqlx:run(query:getModelEndPosition($modelsEnvelope, $startDate, $endDate))//sparql:binding[@name='inspireLabel']/sparql:literal))
        let $sampingPointMethods4Y := distinct-values(data(sparqlx:run(query:getSamplingPointEndPosition($latestEnvelopeD,$startDate,$endDate))//sparql:binding[@name='inspireLabel']/sparql:literal))

        for $method in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods
        let $modelMetaCount := count($method/aqd:modelAssessmentMetadata)
        let $samplingPointMetaCount := count($method/aqd:samplingPointAssessmentMetadata)

        let $invalidModel :=
            for $meta1 in $method/aqd:modelAssessmentMetadata
            let $samplingPoint := $meta1/@xlink:href => string()

            let $reportingMetric := $meta1/../../../aqd:assessmentThreshold//aqd:reportingMetric/@xlink:href => string()
            let $missing :=
                if ($reportingMetric = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove-3yr") then
                    if (not($samplingPoint = $modelMethods2Y)) then 1 else 0
                else if ($reportingMetric = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AOT40c-5yr") then
                    if (not($samplingPoint = $modelMethods4Y)) then 1 else 0
                else
                    if (not($samplingPoint = $modelMethods)) then 1 else 0
            where ($missing = 1)
            return
                <tr>
                    <td title="AQD_AssessmentRegime">{data($meta1/../../../aqd:inspireId/base:Identifier/base:localId)}</td>
                    <td title="aqd:modelAssessmentMetadata">{data($meta1/@xlink:href)}</td>
                    <td title="aqd:samplingPointAssessmentMetadata"></td>
                </tr>

        let $invalidSampingPoint :=
            for $meta2 in $method/aqd:samplingPointAssessmentMetadata
            let $samplingPoint := $meta2/@xlink:href => string()

            let $reportingMetric := $meta2/../../../aqd:assessmentThreshold//aqd:reportingMetric/@xlink:href => string()
            let $missing :=
                if ($reportingMetric = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove-3yr") then
                    if (not($samplingPoint = $sampingPointMethods2Y)) then 1 else 0
                else if ($reportingMetric = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AOT40c-5yr") then
                    if (not($samplingPoint = $sampingPointMethods4Y)) then 1 else 0
                else
                    if (not($samplingPoint = $sampingPointMethods)) then 1 else 0
            where ($missing = 1)
            return
                <tr>
                    <td title="AQD_AssessmentRegime">{data($meta2/../../../aqd:inspireId/base:Identifier/base:localId)}</td>
                    <td title="aqd:modelAssessmentMetadata"></td>
                    <td title="aqd:samplingPointAssessmentMetadata">{data($meta2/@xlink:href)}</td>
                </tr>

        return
            if ($modelMetaCount = 0 and $samplingPointMetaCount = 0) then
                <tr>
                    <td title="AQD_AssessmentRegime">{data($method/../../aqd:inspireId/base:Identifier/base:localId)}</td>
                    <td title="aqd:modelAssessmentMetadata">None specified</td>
                    <td title="aqd:samplingPointAssessmentMetadata">None specified</td>
                </tr>
            else
                (($invalidModel), ($invalidSampingPoint))
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $C26errorClass := if (contains($source_url, "c_preliminary")) then $errors:WARNING else $errors:C26

let $ms2C26 := prof:current-ms()

(: C27 - return all zones listed in the doc :)

let $ms1C27 := prof:current-ms()

let $C27table :=
    try {
        let $results := sparqlx:run(query:getC27($latestEnvelopeB))
        let $latestZones := data($results//sparql:binding[@name = 'inspireLabel']/sparql:literal)
        let $validZones := if ((fn:string-length($countryCode) = 2) and exists($latestEnvelopeB)) then
            for $zone in $results
            let $zoneId := $zone//sparql:binding[@name = 'inspireLabel']/sparql:literal => string()
            (: let $beginPosition := $zone//sparql:binding[@name = 'beginPosition']/sparql:literal => string()
            let $endPosition := $zone//sparql:binding[@name = 'endPosition']/sparql:literal => string() :)
            let $beginPosition := (xs:dateTime($zone//sparql:binding[@name = 'beginPosition']/sparql:literal) + xs:dayTimeDuration("P2D")) => string()
            let $endPosition := (xs:dateTime($zone//sparql:binding[@name = 'endPosition']/sparql:literal) - xs:dayTimeDuration("P2D")) => string()
            let $endPositionWOTime := substring-before($endPosition, 'T')
            let $beginYear := year-from-dateTime(common:getUTCDateTime($beginPosition))
            let $endYear := if ($endPosition = '') then () else year-from-date(common:getUTCDate($endPositionWOTime))
            let $reportingYear := xs:integer($reportingYear)
            where $beginYear <= $reportingYear and (empty($endYear) or $endYear >= $reportingYear)
            return $zoneId
        else ()
        (: return zones not listed in B :)
        let $invalidEqual :=
            for $regime in $docRoot//aqd:AQD_AssessmentRegime
            let $zoneId := string($regime/aqd:zone/@xlink:href)
            where ($zoneId != "" and $zoneId = $latestZones and not($validZones = $zoneId))
            return
                <tr>
                    <td title="AQD_AssessmentRegime">{data($regime/aqd:inspireId/base:Identifier/base:localId)}</td>
                    <td title="aqd:zoneId">{$zoneId}</td>
                    <td title="AQD_Zone">Not existing</td>
                    <td title="Sparql">{sparqlx:getLink(query:getC27($latestEnvelopeB))}</td>
                </tr>
        let $invalidEqual2 :=
            for $zoneId in $validZones
            where ($zoneId != "" and count($docRoot//aqd:AQD_AssessmentRegime/aqd:zone[@xlink:href = $zoneId]) = 0)
            return
                <tr>
                    <td title="AQD_AssessmentRegime">Not existing</td>
                    <td title="aqd:zoneId"></td>
                    <td title="AQD_Zone">{$zoneId}</td>
                    <td title="Sparql">{sparqlx:getLink(query:getC27($latestEnvelopeB))}</td>
                </tr>

        return (($invalidEqual), ($invalidEqual2))
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2C27 := prof:current-ms()

(: C29 - :)

let $ms1C29 := prof:current-ms()

let $C29invalid :=
    try {
        let $validZones :=
            for $zoneId in $zoneIds
            return
                if ($zoneId != "" and count($docRoot//aqd:AQD_AssessmentRegime/aqd:zone[@xlink:href = $zoneId]) > 0) then
                    $zoneId
                else
                    ()
        let $combinations := sparqlx:run(query:getPollutantCodeAndProtectionTarge($cdrUrl, $bdir))
        let $validRows :=
            for $rec in $combinations
            return
                concat(data($rec//sparql:binding[@name = 'inspireLabel']/sparql:literal), "#", data($rec//sparql:binding[@name = 'pollutantCode']/sparql:uri), "#", data($rec//sparql:binding[@name = 'protectionTarget']/sparql:uri))
        let $validRows := distinct-values($validRows)

        let $exceptionPollutantIds := ("6001")

            for $x in $docRoot//aqd:AQD_AssessmentRegime[aqd:zone/@xlink:href = $validZones]
            let $pollutantCode := fn:substring-after(data($x//aqd:pollutant/@xlink:href), "pollutant/")
            let $key :=
                if (not(empty(index-of($exceptionPollutantIds, $pollutantCode))) and data($x//aqd:zone/@nilReason) = "inapplicable") then
                    "EXC"
                else
                    concat(data($x//aqd:zone/@xlink:href), '#', data($x//aqd:pollutant/@xlink:href), '#', data($x//aqd:protectionTarget/@xlink:href))
            where empty(index-of($validRows, $key)) and not(empty(index-of($dataflowC:MANDATORY_POLLUTANT_IDS_8, $pollutantCode))) and ($key != "EXC")
            return
                <tr>
                    <td title="AQD_AssessmentRegime">{data($x/aqd:inspireId/base:Identifier/base:localId)}</td>
                    <td title="aqd:zone">{data($x//aqd:zone/@xlink:href)}</td>
                    <td title="aqd:pollutant">{data($x//aqd:pollutant/@xlink:href)}</td>
                    <td title="aqd:protectionTarget">{data($x//aqd:protectionTarget/@xlink:href)}</td>
                    <td title="Sparql">{sparqlx:getLink(query:getPollutantCodeAndProtectionTarge($cdrUrl, $bdir))}</td>
                </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2C29 := prof:current-ms()

(: C28 If ./aqd:zone xlink:href shall be current, then ./AQD_zone/aqd:operationActivityPeriod/gml:endPosition shall be equal to “9999-12-31 23:59:59Z” or nulled (blank)  :)

let $ms1C28 := prof:current-ms()

let $C28invalid :=
    try {
        for $zone in $docRoot//aqd:zone[@xlink:href = '.']/aqd:AQD_Zone
        let $endPosition := normalize-space($zone/aqd:operationActivityPeriod/gml:endPosition)
        where upper-case($endPosition) != '9999-12-31 23:59:59Z' and $endPosition != ''
        return
            <tr>
                <td title="aqd:AQD_AssessmentRegime/aqd:inspireId/base:Identifier/base:localId">{data($zone/../../aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:AQD_Zone/am:inspireId/base:Identifier/base:localId">{data($zone/am:inspireId/base:Identifier/base:localId)}</td>
                {html:getErrorTD(data($endPosition), "gml:endPosition", fn:true())}

            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2C28 := prof:current-ms()

(: C31 :)
let $ms1C31 := prof:current-ms()

let $C31table :=
    try {
        let $C31ResultB :=
            for $i in sparqlx:run(query:getC31($latestEnvelopeBperYear, $reportingYear))
            return
                <result>
                    <pollutantName>{string($i/sparql:binding[@name = "Pollutant"]/sparql:literal)}</pollutantName>
                    <protectionTarget>{string($i/sparql:binding[@name = "ProtectionTarget"]/sparql:uri)}</protectionTarget>
                    <count>{
                        let $x := string($i/sparql:binding[@name = "countOnB"]/sparql:literal)
                        return if ($x castable as xs:integer) then xs:integer($x) else 0
                    }</count>
                </result>

        let $C31tmp :=
            for $x in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/
                    aqd:EnvironmentalObjective/aqd:protectionTarget[not(../string(aqd:objectiveType/@xlink:href) = ("http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO",
                    "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ECO", "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ALT", "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/INT"))]
            let $pollutant := string($x/../../../../../aqd:pollutant/@xlink:href)
            let $zone := string($x/../../../../../aqd:zone/@xlink:href)
            let $protectionTarget := string($x/@xlink:href)
            let $key := string-join(($zone, $pollutant, $protectionTarget), "#")
            group by $pollutant, $protectionTarget
            return
                <result>
                    <pollutantName>{dd:getNameFromPollutantCode($pollutant)}</pollutantName>
                    <pollutantCode>{tokenize($pollutant, "/")[last()]}</pollutantCode>
                    <protectionTarget>{$protectionTarget}</protectionTarget>
                    <count>{count(distinct-values($key))}</count>
                </result>
        let $C31ResultC := filter:filterByName($C31tmp, "pollutantCode", (
            "1", "7", "8", "9", "5", "6001", "10", "20", "5012", "5018", "5014", "5015", "5029"
        ))
        for $x in $C31ResultC
            let $vsName := string($x/pollutantName)
            let $vsCode := string($x/pollutantCode)
            let $protectionTarget := string($x/protectionTarget)
            let $countC := number($x/count)
            let $countB := number($C31ResultB[pollutantName = $vsName and protectionTarget = $protectionTarget]/count)
            let $errorClass :=
                if ((string($countC), string($countB)) = "NaN") then $errors:C31
                else if ($countC > $countB) then $errors:C31
                else if ($countB > $countC) then $errors:WARNING
                else $errors:INFO
        order by $vsName
        return
            <tr class="{$errorClass}">                   
                <td title="Pollutant Name">{$vsName}</td>
                <td title="Pollutant Code">{$vsCode}</td>
                <td title="Protection Target">{$protectionTarget}</td>
                <td title="Count C">{string($countC)}</td>
                <td title="Count B">{string($countB)}</td>
                <td title="Sparql">{sparqlx:getLink(query:getC31($latestEnvelopeBperYear, $reportingYear))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

    let $ms2C31 := prof:current-ms()


(: C31b :)

let $ms1C31b := prof:current-ms()

let $C31btable :=
    try {
        let $C31ResultPrelimC :=
            for $i in sparqlx:run(query:getC31b($prelimEnvelopeC))
            return
                <result>
                    <pollutantName>{string($i/sparql:binding[@name = "Pollutant"]/sparql:literal)}</pollutantName>
                    <protectionTarget>{string($i/sparql:binding[@name = "ProtectionTarget"]/sparql:uri)}</protectionTarget>
                    <count>{
                        let $x := string($i/sparql:binding[@name = "countOnPrelimC"]/sparql:literal)
                        return if ($x castable as xs:integer) then xs:integer($x) else 0
                    }</count>
                </result>

        let $C31tmp :=
            for $x in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/
                    aqd:EnvironmentalObjective/aqd:protectionTarget[not(../string(aqd:objectiveType/@xlink:href) = ("http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO",
                    "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ECO", "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ALT", "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/INT"))]
            let $pollutant := string($x/../../../../../aqd:pollutant/@xlink:href)
            let $zone := string($x/../../../../../aqd:zone/@xlink:href)
            let $protectionTarget := string($x/@xlink:href)
            let $key := string-join(($zone, $pollutant, $protectionTarget), "#")
            group by $pollutant, $protectionTarget
            return
                <result>
                    <pollutantName>{dd:getNameFromPollutantCode($pollutant)}</pollutantName>
                    <pollutantCode>{tokenize($pollutant, "/")[last()]}</pollutantCode>
                    <protectionTarget>{$protectionTarget}</protectionTarget>
                    <count>{count(distinct-values($key))}</count>
                </result>
        let $C31ResultC := filter:filterByName($C31tmp, "pollutantCode", (
            "1", "7", "8", "9", "5", "6001", "10", "20", "5012", "5018", "5014", "5015", "5029"
        ))
        for $x in $C31ResultC
            let $vsName := string($x/pollutantName)
            let $vsCode := string($x/pollutantCode)
            let $protectionTarget := string($x/protectionTarget)
            let $countC := number($x/count)
            let $countPrelimC := number($C31ResultPrelimC[pollutantName = $vsName and protectionTarget = $protectionTarget]/count)
            let $errorClass :=
                if ((string($countC), string($countPrelimC)) = "NaN") then $errors:C31b
                else if ($countC > $countPrelimC) then $errors:C31b
                else if ($countPrelimC > $countC) then $errors:WARNING
                else $errors:INFO
        order by $vsName
        where doc($envelopeUrl)/envelope/obligation != 'http://rod.eionet.europa.eu/obligations/694'
        return
            <tr class="{$errorClass}">
            
            
<!--pruebas C31 local
             <td title="rlatestEnvelopeB">{$latestEnvelopeB}</td>
             <td title="latestEnvelopeBperYearv">{$latestEnvelopeBperYear}</td>           
pruebas C31 local-->

                <td title="Pollutant Name">{$vsName}</td>
                <td title="Pollutant Code">{$vsCode}</td>
                <td title="Protection Target">{$protectionTarget}</td>
                <td title="Count C">{string($countC)}</td>
                <td title="Count C preliminary">{string($countPrelimC)}</td>
                <td title="Sparql">{sparqlx:getLink(query:getC31b($prelimEnvelopeC))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
 

    let $ms2C31b := prof:current-ms()

(: C32 - :)

let $ms1C32 := prof:current-ms()

let $C32table :=
    try {
       (: let $query1 :=
        "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
         PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
         PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

         SELECT ?zone ?inspireId ?inspireLabel ?assessmentType
         WHERE {
            ?zone a aqd:AQD_SamplingPoint ;
            aqd:inspireId ?inspireId .
            ?inspireId rdfs:label ?inspireLabel .
            ?zone aqd:assessmentType ?assessmentType
            FILTER (CONTAINS(str(?zone), '" || $latestEnvelopeD || "'))
         }":)
          let $query1 :=
                "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
                PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
                PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
                PREFIX dcterms: <http://purl.org/dc/terms/>
                PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>

                SELECT DISTINCT ?zone ?inspireId ?inspireLabel ?assessmentType
                WHERE {

                    values ?envelope { <" || $latestEnvelopeD || "> }
                    ?graph dcterms:isPartOf ?envelope.
                    ?graph contreg:xmlSchema ?xmlSchema .
                        GRAPH ?graph {
                         ?zone a aqd:AQD_SamplingPoint .
                         ?zone aqd:inspireId ?inspireId .
                         ?inspireId rdfs:label ?inspireLabel .
                         ?zone aqd:assessmentType ?assessmentType                      
                        }
                }"
        let $aqdSamplingPointAssessMEntTypes :=
            for $i in sparqlx:run($query1)
            let $ii := concat($i/sparql:binding[@name = 'inspireLabel']/sparql:literal, "#", $i/sparql:binding[@name = 'assessmentType']/sparql:uri)
            return $ii

       (: let $query2 :=
        "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
         PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
         PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

         SELECT ?zone ?inspireId ?inspireLabel ?assessmentType
         WHERE {
            ?zone a aqd:AQD_Model ;
            aqd:inspireId ?inspireId .
            ?inspireId rdfs:label ?inspireLabel .
            ?zone aqd:assessmentType ?assessmentType
            FILTER (CONTAINS(str(?zone), '" || $modelsEnvelope || "'))
         }":)

         let $query2 :=
        " PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
          PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
          PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
          PREFIX dcterms: <http://purl.org/dc/terms/>
          PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
         
          SELECT DISTINCT ?zone ?inspireId ?inspireLabel ?assessmentType
          WHERE {
          
          values ?envelope { <" || $modelsEnvelope || "> }
          ?graph dcterms:isPartOf ?envelope .
          ?graph contreg:xmlSchema ?xmlSchema .
                GRAPH ?graph {
                ?zone a aqd:AQD_Model .
                 ?zone aqd:inspireId ?inspireId .
                }
          
          ?inspireId rdfs:label ?inspireLabel .
          ?zone aqd:assessmentType ?assessmentType
         
          }"

        let $aqdModelAssessMentTypes :=
            for $i in sparqlx:run($query2)
            let $ii := concat($i/sparql:binding[@name = 'inspireLabel']/sparql:literal, "#", $i/sparql:binding[@name = 'assessmentType']/sparql:uri)
            return $ii

        let $allAssessmentTypes := ($aqdSamplingPointAssessMEntTypes, $aqdModelAssessMentTypes)
        for $sMetadata in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata
        let $id := string($sMetadata/@xlink:href)
        let $docType := string($sMetadata/../aqd:assessmentType/@xlink:href)

        let $typeInDoc := lower-case(substring-after($docType, $vocabulary:ASSESSMENTTYPE_VOCABULARY))
        let $combination := $id || "#" || $docType
        let $combinationFixed := $id || "#" || $vocabulary:ASSESSMENTTYPE_VOCABULARY || "fixed"
        let $combinationFixedRandom := $id || "#" || $vocabulary:ASSESSMENTTYPE_VOCABULARY || "fixedrandom"
        let $combinationIndicative := $id || "#" || $vocabulary:ASSESSMENTTYPE_VOCABULARY || "indicative"
        let $combinationModel := $id || "#" || $vocabulary:ASSESSMENTTYPE_VOCABULARY || "model"
        let $combinationObjective := $id || "#" || $vocabulary:ASSESSMENTTYPE_VOCABULARY || "objective"

        let $condition :=
            if ($typeInDoc = ("fixed")) then
                $combination = ($combinationFixed, $combinationFixedRandom)
            else if ($typeInDoc = ("fixedrandom")) then
                $combination = ($combinationFixedRandom)
            else if ($typeInDoc = "indicative") then
                $combination = ($combinationIndicative, $combinationFixed, $combinationFixedRandom)
            else if ($typeInDoc = "objective") then
                $combination = ($combinationObjective, $combinationFixed, $combinationFixedRandom, $combinationIndicative, $combinationModel)
            else
                false()
        where (not($condition))
        return
            <tr>
                <td title="AQD_AssessmentRegime">{string($sMetadata/../../../aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:samplingPointAssessmentMetadata">{$id}</td>
                <td title="aqd:assessmentType">{substring-after($docType, $vocabulary:ASSESSMENTTYPE_VOCABULARY)}</td>
                <td title="Sparql1">{sparqlx:getLink($query1)}</td>
                <td title="Sparql2">{sparqlx:getLink($query2)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
        

let $ms2C32 := prof:current-ms()

(: C33 If The lifecycle information of ./aqd:assessmentMethods/aqd:AssessmentMethods/aqd:*AssessmentMetadata xlink:href shall be current,
    then /AQD_SamplingPoint/aqd:operationActivityPeriod/gml:endPosition or /AQD_ModelType/aqd:operationActivityPeriod/gml:endPosition shall be equal to “9999-12-31 23:59:59Z” or nulled (blank):)

    let $ms1C33 := prof:current-ms()

    let $C33invalid :=
    try {
        for $assessmentMetadata in $docRoot//aqd:assessmentMethods/aqd:AssessmentMethods/*[ends-with(local-name(), 'AssessmentMetadata') and @xlink:href = '.']

        let $endPosition :=
            if ($assessmentMetadata/local-name() = 'modelAssessmentMetadata') then
                normalize-space($assessmentMetadata/aqd:AQD_Model/aqd:operationActivityPeriod/gml:endPosition)
            else if ($assessmentMetadata/local-name() = 'samplingPointAssessmentMetadata') then
                normalize-space($assessmentMetadata/aqd:AQD_SamplingPoint/aqd:operationActivityPeriod/gml:endPosition)
            else
                ""
        where upper-case($endPosition) != '9999-12-31 23:59:59Z' and $endPosition != ''
        return
            <tr>
                <td title="aqd:AQD_AssessmentRegime/aqd:inspireId/base:Identifier/base:localId">{data($assessmentMetadata/../../../aqd:inspireId/base:Identifier/base:localId)}</td>{
                if ($assessmentMetadata/local-name() = 'modelAssessmentMetadata') then
                    (<td title="aqd:AQD_Model/ @gml:id">{data($assessmentMetadata/aqd:AQD_Model/@gml:id)}</td>,
                    html:getErrorTD(data($endPosition), "gml:endPosition", fn:true())
                    , <td title="aqd:AQD_SamplingPoint/ @gml:id"/>, <td title="gml:endPosition"/>)
                else if ($assessmentMetadata/local-name() = 'samplingPointAssessmentMetadata') then
                    (<td title="aqd:AQD_Model/ @gml:id"/>, <td title="gml:endPosition"/>,
                    <td title="aqd:AQD_SamplingPoint/ @gml:id">{data($assessmentMetadata/aqd:AQD_SamplingPoint/@gml:id)}</td>,
                    html:getErrorTD(data($endPosition), "gml:endPosition", fn:true())
                    )
                else
                    ()
            }
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ms2C33 := prof:current-ms()

(: C35 /aqd:AQD_SamplingPoint/aqd:usedAQD or /aqd:AQD_ModelType/aqd:used shall EQUAL “true” for all ./aqd:assessmentMethods/aqd:AssessmentMethods/aqd:*AssessmentMetadata xlink:href citations :)

let $ms1C35 := prof:current-ms()

let $C35invalid :=
    try {
        for $assessmentMetadata in $docRoot//aqd:assessmentMethods/aqd:AssessmentMethods/*[ends-with(local-name(), 'AssessmentMetadata') and @xlink:href = '.']

        let $used :=
            if ($assessmentMetadata/local-name() = 'modelAssessmentMetadata') then
                normalize-space($assessmentMetadata/aqd:AQD_Model/aqd:used)
            else if ($assessmentMetadata/local-name() = 'samplingPointAssessmentMetadata') then
                normalize-space($assessmentMetadata/aqd:AQD_SamplingPoint/aqd:usedAQD)
            else
                ""

        where $used != 'true'
        return
            <tr>
                <td title="aqd:AQD_AssessmentRegime">{data($assessmentMetadata/../../../aqd:inspireId/base:Identifier/base:localId)}</td>{
                if ($assessmentMetadata/local-name() = 'modelAssessmentMetadata') then
                    (<td title="aqd:AQD_Model/ @gml:id">{data($assessmentMetadata/aqd:AQD_Model/@gml:id)}</td>,
                    html:getErrorTD(data($used), "aqd:used", fn:true())
                    , <td title="aqd:AQD_SamplingPoint/ @gml:id"/>, <td title="aqd:usedAQD"/>)
                else if ($assessmentMetadata/local-name() = 'samplingPointAssessmentMetadata') then
                    (<td title="aqd:AQD_Model/ @gml:id"/>, <td title="aqd:used"/>,
                    <td title="aqd:AQD_SamplingPoint/ @gml:id">{data($assessmentMetadata/aqd:AQD_SamplingPoint/@gml:id)}</td>,
                    html:getErrorTD(data($used), "aqd:usedAQD", fn:true())
                    )
                else
                    ()
            }
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2C35 := prof:current-ms()

(: C37 - :)

let $ms1C37 := prof:current-ms()

let $C37invalid :=
    try {
        let $reportingMetric := $docRoot//aqd:AQD_AssessmentRegime[aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AEI"]/@gml:id
        return
            if (count($reportingMetric) > 1) then
                for $i in $reportingMetric
                return
                    <tr><td title="@gml:id">{string($i)}</td></tr>
            else
                ()
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2C37 := prof:current-ms()

(: C38 :)

let $ms1C38 := prof:current-ms()

let $C38invalid :=
    try {
        (:let $query :=
            "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
             PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
             PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

             SELECT ?zone ?inspireId ?inspireLabel ?relevantEmissions ?stationClassification
             WHERE {
                    ?zone a aqd:AQD_SamplingPoint ;
                    aqd:inspireId ?inspireId .
                    ?inspireId rdfs:label ?inspireLabel .
                    ?zone aqd:relevantEmissions ?relevantEmissions .
                    ?relevantEmissions aqd:stationClassification ?stationClassification
             FILTER (CONTAINS(str(?zone), '" || $latestEnvelopeD || "') and str(?stationClassification)='http://dd.eionet.europa.eu/vocabulary/aq/stationclassification/background')
             }":)
             let $query :=
                 "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
                  PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
                  PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
                  PREFIX dcterms: <http://purl.org/dc/terms/>
                  PREfIX contreg: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
                 
                  SELECT DISTINCT ?zone ?inspireId ?inspireLabel ?relevantEmissions ?stationClassification
                  WHERE {
                  
                  values ?envelope { <" || $latestEnvelopeD || "> }
                    ?graph dcterms:isPartOf ?envelope .
                    ?graph contreg:xmlSchema ?xmlSchema .
                    GRAPH ?graph {
                        ?zone a aqd:AQD_SamplingPoint .
                        ?zone aqd:inspireId ?inspireId .
                    }


                 
                  ?inspireId rdfs:label ?inspireLabel .
                  ?zone aqd:relevantEmissions ?relevantEmissions .
                  ?relevantEmissions aqd:stationClassification ?stationClassification
                  
                  FILTER (str(?stationClassification)='http://dd.eionet.europa.eu/vocabulary/aq/stationclassification/background')
             }"
        let $valid := distinct-values(data(sparqlx:run($query)/sparql:binding[@name = 'inspireLabel']/sparql:literal))

        for $x in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric[@xlink:href = $vocabulary:REPMETRIC_VOCABULARY || "AEI"]
        for $xlink in $x/../../../../../aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata/@xlink:href
       
        where not($xlink = $valid) 
        return
            <tr>
                <td title="aqd:AQD_AssessmentRegime">{data($x/../../../../../aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:AQD_SamplingPoint">{data($xlink)}</td>
                <td title="Sparql">{sparqlx:getLink($query)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

    let $ms2C38 := prof:current-ms()

(: C40 :)

let $ms1C40 := prof:current-ms()

let $C40invalid :=
    try {
        for $aqdPollutantC40 in $docRoot//aqd:AQD_AssessmentRegime
        let $pollutantXlinkC40 := fn:substring-after(data($aqdPollutantC40/aqd:pollutant/@xlink:href), "pollutant/")
        where not(empty(index-of($dataflowC:VALID_POLLUTANT_IDS_40, $pollutantXlinkC40))) and not((count($aqdPollutantC40/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata) >= 1
                or count($aqdPollutantC40/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:modelAssessmentMetadata) >= 1))
        return
            <tr>
                <td title="@gml:id">{string($aqdPollutantC40/@gml:id)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2C40 := prof:current-ms()

(: C40b :)

let $ms1C40b := prof:current-ms()

let $C40binvalid :=
    try {
       
       let $C40count := count($C40invalid)
       let $C01count := count($C01table)
      
        
        where $C01count = $C40count
        return
            <tr>
                <td title="C01">{$C01count}</td>
                <td title="C40">{$C40count}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2C40b := prof:current-ms()

(: C41 gml:timePosition MUST be provided and must be equal or greater than (aqd:reportingPeriod – 5 years) included in the ReportingHeader :)

let $ms1C41 := prof:current-ms()

let $C41invalid :=
    try {
        let $C41minYear := if ($reportingYear castable as xs:integer) then xs:integer($reportingYear) - 5 else ()
        for $x in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:classificationDate/gml:TimeInstant
        let $timePosition := string($x/gml:timePosition)
        let $timePosition :=
            if ($timePosition castable as xs:integer) then
                xs:integer($timePosition)
            else if ($timePosition castable as xs:date) then
                year-from-date(xs:date($x/gml:timePosition))
            else
                ()
        where empty($timePosition) or ($timePosition < $C41minYear)
        return
            <tr>
                <td title="aqd:AQD_AssessmentRegime">{string($x/../../../../aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="gml:timePosition">{$timePosition}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

    let $ms2C41 := prof:current-ms()

(: C42 - :)
    let $ms1C42 := prof:current-ms()

let $C42invalid :=
    try {
        for $x in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:classificationReport
        where (string($x) = "") or (not(common:includesURL($x)))
        return
            <tr>
                <td title="base:localId">{$x/../../../aqd:inspireId/base:Identifier/base:localId}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

    let $ms2C42 := prof:current-ms()

let $ms2Total := prof:current-ms()

return
    <table class="maintable hover">
    <table>
        {html:build2("NS", $labels:NAMESPACES, $labels:NAMESPACES_SHORT, $NSinvalid, "All values are valid", "record", $errors:NS)}
        {html:build2("VOCAB", $labels:VOCAB, $labels:VOCAB_SHORT, $VOCABinvalid, "All values are valid", "record", $errors:VOCAB)}
        {html:build3("C0", $labels:C0, $labels:C0_SHORT, $C0table, string($C0table/td), errors:getMaxError($C0table))}
        {html:build1("C01", $labels:C01, $labels:C01_SHORT, $C01table, "", string(count($C01table)), "", "", $errors:C01)}
        {html:buildSimpleSparql("C02", $labels:C02, $labels:C02_SHORT, $C02table, "", "record", $C02errorLevel)}
        {html:buildSimple("C03", $labels:C03, $labels:C03_SHORT, $C03table, "", "record", $C03errorLevel)}
        {html:build2Sparql("C03a", $labels:C03a, $labels:C03a_SHORT, ($C03afunc, $C03a2func), "All values are valid", " Assessment Regime missing", $errors:C03a)}
       <!-- {html:build2("C03b", $labels:C03b, $labels:C03b_SHORT, $C03bfunc, "All values are valid", " Assessment Methods missing", $errors:C03b)}-->
        {html:buildNoCountSparql("C03b", $labels:C03b, $labels:C03b_SHORT, $C03bfunc, "All values are valid", "Missing Assessment Method", $errors:C03b)}
        {html:buildNoCount2Sparql("C03c", $labels:C03c, $labels:C03c_SHORT, $C03cfunc, "All values are valid", "Mismatches of assessment type found", $errors:C03c)}
        {html:build2Sparql("C03d", $labels:C03d, $labels:C03d_SHORT, $C03dinvalid, "All values are valid", " New Assessment Methods", $errors:C03d)}
        {html:build2("C04", $labels:C04, $labels:C04_SHORT, $C04invalid, "No duplicates found", " duplicate", $errors:C04)}
        {html:build2("C05", $labels:C05, $labels:C05_SHORT, $C05invalid, "No duplicates found", " duplicate", $errors:C05)}
        {html:build2("C06", $labels:C06, $labels:C06_SHORT, $C06table, string(count($C06table)), "", $errors:C06)}
        {html:build2("C06.1", $labels:C06.1, $labels:C06.1_SHORT, $C06.1invalid, "All values are valid", " invalid namespaces", $errors:C06.1)}
        {html:build2("C07", $labels:C07, $labels:C07_SHORT, $C07invalid, "All values are valid", " invalid value", $errors:C07)}
        {html:build2("C08", $labels:C08, $labels:C08_SHORT, $C08invalid, "All values are valid", " missing pollutant", $errors:C08)}
        {html:build0("C09", $labels:C09, $labels:C09_SHORT, $C09table, "pollutant")}
        {html:build2("C10", $labels:C10, $labels:C10_SHORT, $C10invalid, "All values are valid", " invalid value", $errors:C10)}
        {html:build2("C20", $labels:C20, $labels:C20_SHORT, $C20invalid, "All combinations have been found", "record", $errors:C20)}
        {html:build2("C21", $labels:C21, $labels:C21_SHORT, $C21invalid, "All values are valid", " invalid value", $errors:C21)}
        {html:build2("C23a", $labels:C23a, $labels:C23a_SHORT, $C23ainvalid, "All values are valid", " invalid value", $errors:C23a)}
        {html:build2("C23b", $labels:C23b, $labels:C23b_SHORT, $C23binvalid, "All values are valid", " invalid value", $errors:C23b)}
        {html:build2Sparql("C24", $labels:C24, $labels:C24_SHORT, $C24invalid, "All values are valid", "", $C24errorClass)}
        {html:build2("C25", $labels:C25, $labels:C25_SHORT, $C25invalid, "All values are valid", "", $errors:C25)}
        {html:build2("C26", $labels:C26, $labels:C26_SHORT, $C26table, "All values are valid", " invalid value", $C26errorClass)}
        {html:build2Sparql("C27", labels:interpolate($labels:C27, ($countZoneIds2, $countZoneIds1)), $labels:C27_SHORT, $C27table, "", " not unique zone", $errors:C27)}
        {html:build2("C28", $labels:C28, $labels:C28_SHORT, $C28invalid, "All values are valid", " invalid value", $errors:C28)}
        {html:build2Sparql("C29", $labels:C29, $labels:C29_SHORT,  $C29invalid, "All values are valid", " invalid value", $errors:C29)}
        {html:build2Sparql("C31", $labels:C31, $labels:C31_SHORT, $C31table, "", "record", errors:getMaxError($C31table))}
        {html:build4Sparql("C31b", $labels:C31b, $labels:C31b_SHORT, $C31btable, "", "record", errors:getMaxError($C31btable))}
        {html:build2Sparql("C32", $labels:C32, $labels:C32_SHORT, $C32table, "All values are valid", " invalid value", $errors:C32)}
        {html:build2("C33", $labels:C33, $labels:C33_SHORT, $C33invalid, "All values are valid", " invalid value", $errors:C33)}
        {html:build2("C35", $labels:C35, $labels:C35_SHORT, $C35invalid, "All values are valid", " invalid value", $errors:C35)}
        {html:build2("C37", $labels:C37, $labels:C37_SHORT, $C37invalid, "All values are valid", " invalid value", $errors:C37)}
        {html:build2Sparql("C38", $labels:C38, $labels:C38_SHORT, $C38invalid, "All values are valid", " invalid value", $errors:C38)}
        {html:build2("C40", $labels:C40, $labels:C40_SHORT, $C40invalid, "All values are valid", " invalid value", $errors:C40)}
        {html:build2("C40b", $labels:C40b, $labels:C40b_SHORT, $C40binvalid, "All values are valid", " invalid value", $errors:C40b)}
        {html:build2("C41", $labels:C41, $labels:C41_SHORT, $C41invalid, "All values are valid", " invalid value", $errors:C41)}
        {html:build2("C42", $labels:C42, $labels:C42_SHORT, $C42invalid, "All values are valid", " invalid value", $errors:C42)}
    </table>
    <table>
    <br/>
    <caption> {$labels:TIMINGTABLEHEADER} </caption>
        <tr>
            <th>Query</th>
            <th>Process time in miliseconds</th>
            <th>Process time in seconds</th>
        </tr>

       {common:runtime("Common variables",  $ms1GeneralParameters, $ms2GeneralParameters)}
       {common:runtime("NS", $ms1NS, $ms2NS)}
       {common:runtime("C0",  $ms1C0, $ms2C0)}
       {common:runtime("C01", $ms1C01, $ms2C01)}
       {common:runtime("C02", $ms1C02, $ms2C02)}
       {common:runtime("C03", $ms1C03, $ms2C03)}
       {common:runtime("C03a",  $ms1C03a, $ms2C03a)}  
       {common:runtime("C03a2",  $ms1C03a2, $ms2C03a2)} 
       {common:runtime("C03b",  $ms1C03b, $ms2C03b)}
       {common:runtime("C03c", $ms1C03c, $ms2C03c)}
       {common:runtime("C03d",  $ms1C03d, $ms2C03d)}
       {common:runtime("C04",  $ms1C04, $ms2C04)}
       {common:runtime("C05", $ms1C05, $ms2C05)}
       {common:runtime("C06",  $ms1C06, $ms2C06)}
       {common:runtime("C06.1",  $ms1C06.1, $ms2C06.1)}
       {common:runtime("C07",  $ms1C07, $ms2C07)}
       {common:runtime("C08",  $ms1C08, $ms2C08)}
       {common:runtime("C09",  $ms1C09, $ms2C09)}
       {common:runtime("C10",  $ms1C10, $ms2C10)}
       {common:runtime("C20", $ms1C20, $ms2C20)}
       {common:runtime("C21",  $ms1C21, $ms2C21)}
       {common:runtime("C23a",  $ms1C23a, $ms2C23a)}
       {common:runtime("C23b",  $ms1C23b, $ms2C23b)}
       {common:runtime("C24",  $ms1C24, $ms2C24)}
       {common:runtime("C25",  $ms1C25, $ms2C25)}
       {common:runtime("C26",  $ms1C26, $ms2C26)}
       {common:runtime("C27",  $ms1C27, $ms2C27)}
       {common:runtime("C28",  $ms1C28, $ms2C28)}
       {common:runtime("C29",  $ms1C29, $ms2C29)}
       <!--{common:runtime("C31",  $ms1C31, $ms2C31)}-->
       {common:runtime("C31b",  $ms1C31b, $ms2C31b)}
       {common:runtime("C32",  $ms1C32, $ms2C32)}
       {common:runtime("C33",  $ms1C33, $ms2C33)}
       {common:runtime("C35",  $ms1C35, $ms2C35)}
       {common:runtime("C37",  $ms1C37, $ms2C37)}
       {common:runtime("C38",  $ms1C38, $ms2C38)}
       {common:runtime("C40",  $ms1C40, $ms2C40)}
       {common:runtime("C40b",  $ms1C40b, $ms2C40b)}
       {common:runtime("C41",  $ms1C41, $ms2C41)}
       {common:runtime("C42",  $ms1C42, $ms2C42)}
       {common:runtime("Total time",  $ms1Total, $ms2Total)}
    </table>
    </table>
};

declare function dataflowC:proceed($source_url as xs:string, $countryCode as xs:string) {

let $countZones := count(doc($source_url)//aqd:AQD_AssessmentRegime)
let $result := if ($countZones > 0) then dataflowC:checkReport($source_url, $countryCode) else ()

let $meta := map:merge((
    map:entry("count", $countZones),
    map:entry("header", "Check air quality assessment regimes"),
    map:entry("dataflow", "Dataflow C"),
    map:entry("zeroCount", <p>No aqd:AQD_AssessmentRegime elements found in this XML.</p>),
    map:entry("report", <p>This check evaluated the delivery by executing tier-1 tests on air quality assessment regimes data in Dataflow C as specified in <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a>.</p>)
))
return
    html:buildResultDiv($meta, $result)
};
