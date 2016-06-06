xquery version "1.0" encoding "UTF-8";
(:
 : Module Name: Implementing Decision 2011/850/EU: AQ info exchange & reporting (Library module)
 :
 : Version:     $Id$
 : Created:     13 September 2013
 : Copyright:   European Environment Agency
 :)
(:~
 : XQuery script implements dataflow M tier-1 checks as documented in http://taskman.eionet.europa.eu/documents/3 .
 :
 : @author Juri Tõnisson
 : small modification added by Jaume Targa (ETC/ACM) to align with QA document
 :Quality Assurance and Control rules version: 3.9d
 :)

module namespace xmlconv = "http://converters.eionet.europa.eu/dataflowM";
import module namespace common = "aqd-common" at "aqd_check_common.xquery";
import module namespace sparqlx = "aqd-sparql" at "aqd-sparql.xquery";
import module namespace labels = "aqd-labels" at "aqd-labels.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";

declare namespace aqd = "http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0";
declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace am = "http://inspire.ec.europa.eu/schemas/am/3.0";
declare namespace ef = "http://inspire.ec.europa.eu/schemas/ef/3.0";
declare namespace base = "http://inspire.ec.europa.eu/schemas/base/3.3";
declare namespace gn = "urn:x-inspire:specification:gmlas:GeographicalNames:3.0";
declare namespace base2 = "http://inspire.ec.europa.eu/schemas/base2/1.0";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace ompr="http://inspire.ec.europa.eu/schemas/ompr/2.0";
declare namespace sams="http://www.opengis.net/samplingSpatial/2.0";

(:~ declare Content Registry SPARQL endpoint:)
declare variable $xmlconv:CR_SPARQL_URL := "http://cr.eionet.europa.eu/sparql";

declare variable $xmlconv:ISO2_CODES as xs:string* := ("AL","AT","BA","BE","BG","CH","CY","CZ","DE","DK","DZ","EE","EG","ES","FI",
    "FR","GB","GR","HR","HU","IE","IL","IS","IT","JO","LB","LI","LT","LU","LV","MA","ME","MK","MT","NL","NO","PL","PS","PT",
     "RO","RS","SE","SI","SK","TN","TR","XK","UK");

declare variable $xmlconv:FEATURE_TYPES := ("aqd:AQD_Model", "aqd:AQD_ModelProcess", "aqd:AQD_ModelArea");


declare variable $xmlconv:MEDIA_VALUE_VOCABULARY_BASE_URI := "http://inspire.ec.europa.eu/codeList/MediaValue/";
declare variable $xmlconv:MEDIA_VALUE_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/inspire/MediaValue/";
declare variable $xmlconv:ORGANISATIONAL_LEVEL_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/organisationallevel/";
declare variable $xmlconv:NETWORK_TYPE_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/networktype/";
declare variable $xmlconv:METEO_PARAMS_VOCABULARY := "http://vocab.nerc.ac.uk/collection/P07/current/";
declare variable $xmlconv:AREA_CLASSIFICATION_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/areaclassification/";
declare variable $xmlconv:DISPERSION_LOCAL_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/dispersionlocal/";
declare variable $xmlconv:DISPERSION_REGIONAL_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/dispersionregional/";
declare variable $xmlconv:TIMEZONE_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/timezone/";
declare variable $xmlconv:POLLUTANT_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/";
declare variable $xmlconv:MEASUREMENTTYPE_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/measurementtype/";
declare variable $xmlconv:MEASUREMENTMETHOD_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/measurementmethod/";
declare variable $xmlconv:ANALYTICALTECHNIQUE_VOCABULARY :=  "http://dd.eionet.europa.eu/vocabulary/aq/analyticaltechnique/";
declare variable $xmlconv:SAMPLINGEQUIPMENT_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/samplingequipment/";
declare variable $xmlconv:MEASUREMENTEQUIPMENT_VOCABULARY :="http://dd.eionet.europa.eu/vocabulary/aq/measurementequipment/";
declare variable $xmlconv:UOM_CONCENTRATION_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/uom/concentration/";
declare variable $xmlconv:EQUIVALENCEDEMONSTRATED_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/equivalencedemonstrated/";

declare function xmlconv:getErrorTD($errValue,  $element as xs:string, $showMissing as xs:boolean) as element(td) {
    let $val := if ($showMissing and string-length($errValue)=0) then "-blank-" else $errValue
    return
        <td title="{ $element }" style="color:red">{
            $val
        }
        </td>
};


declare function xmlconv:buildResultRowsWithTotalCount($ruleCode as xs:string, $text, $invalidStrValues as xs:string*, $invalidValues as element()*,
    $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $errorLevel as xs:string,$recordDetails as element(tr)*)
as element(tr)*{

    let $countCheckedRecords := count($recordDetails)
    let $invalidValues := $recordDetails[./@isvalid = "false"]

    let $skippedMsg := if ($countCheckedRecords = 0) then "No values found to check" else ""
    let $invalidMsg := if (count($invalidValues) > 0) then concat(" invalid value", substring("s ", number(not(count($invalidValues) > 1)) * 2), " found out of ", $countCheckedRecords, " checked") else ""
    let $validMsg := if (count($invalidValues) = 0) then concat("Checked ", $countCheckedRecords, " value", substring("s", number(not($countCheckedRecords > 1)) * 2), ", all valid") else ""

    return
        html:buildResultRows_M($ruleCode, $text, $invalidStrValues, $invalidValues,
            $valueHeading, $validMsg, $invalidMsg, $skippedMsg,$errorLevel, ())
};
declare function xmlconv:getSamplingPointAssessment($inspireId as xs:string, $inspireNamespace as xs:string)
as xs:string
{
    concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
           PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
           PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
           PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>

        SELECT *
            where {
                    ?assessmentRegime a aqd:AQD_AssessmentRegime;
                    aqd:assessmentMethods  ?assessmentMethods .
                    ?assessmentMethods aqd:samplingPointAssessmentMetadata ?samplingPointAssessment .
                    ?samplingPointAssessment aq:inspireId ?inspireId.
                    ?samplingPointAssessment aq:inspireNamespace ?inspireNamespace.
                    FILTER(?inspireId='",$inspireId,"' and ?inspireNamespace='",$inspireNamespace,"')
                  }")
};

declare function xmlconv:getZonesSparql($nameSpaces as xs:string*)
as xs:string
{
    let $nameSpacesStr :=
        for $nameSpace in $nameSpaces
        return concat("""", $nameSpace, """")

    let $nameSpacesStr :=
        fn:string-join($nameSpacesStr, ",")

    return     concat(
            "PREFIX aqr: <http://reference.eionet.europa.eu/aq/ontology/>

            SELECT ?inspireid
            FROM <http://rdfdata.eionet.europa.eu/airquality/zones.ttl>
            WHERE {
              ?zoneuri a aqr:Zone ;
                        aqr:inspireNamespace ?namespace;
                         aqr:inspireId ?inspireid .
            filter (?namespace in (", $nameSpacesStr,  "))
    } order by ?inspireid"
    )
};

declare function xmlconv:getSamplingPointZone($zoneId as xs:string*)
as xs:string
{
    concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
            PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
            PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

            SELECT *
            WHERE {
                    ?zone a aqd:AQD_Zone;
                    aqd:inspireId ?inspireId .
                    ?inspireId rdfs:label ?inspireLabel
                    FILTER(?inspireLabel = '",$zoneId,"')
                  }")
};

(: Rule implementations :)
declare function xmlconv:checkReport($source_url as xs:string, $countryCode as xs:string) as element(table) {
let $docRoot := doc($source_url)

(: M1 :)
let $countFeatureTypes :=
    for $featureType in $xmlconv:FEATURE_TYPES
    return
        count(doc($source_url)//gml:featureMember/descendant::*[name()=$featureType])
let $tblAllFeatureTypes :=
    for $featureType at $pos in $xmlconv:FEATURE_TYPES
    where $countFeatureTypes[$pos] > 0
    return
        <tr>
            <td title="Feature type">{$featureType }</td>
            <td title="Total number">{$countFeatureTypes[$pos]}</td>
        </tr>

(: M2 :)
let $M2Combinations :=
    for $featureType in $xmlconv:FEATURE_TYPES
    return
        doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

let $nameSpaces := distinct-values($docRoot//base:namespace)
let $zonesSparql := xmlconv:getZonesSparql($nameSpaces)
let $isZonesAvailable := string-length($zonesSparql) > 0 and doc-available(sparqlx:getSparqlEndpointUrl($zonesSparql, "xml"))
let $knownZones := if ($isZonesAvailable ) then distinct-values(data(sparqlx:executeSparqlQuery($zonesSparql)//sparql:binding[@name='inspireid']/sparql:literal)) else ()
let $unknownZones :=
    for $zone in $M2Combinations
    let $id := if (empty($zone/@gml:id)) then "" else data($zone/@gml:id)
    where empty(index-of($knownZones, $id))
    return $zone

let $tblM2 :=
    for $rec in $unknownZones
    return
        $rec/@gml:id


(: M3 :)

let $M3Combinations :=
    for $featureType in $xmlconv:FEATURE_TYPES
    return
        doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

let $nameSpaces := distinct-values($docRoot//base:namespace)
let $zonesSparql := xmlconv:getZonesSparql($nameSpaces)
let $isZonesAvailable := string-length($zonesSparql) > 0 and doc-available(sparqlx:getSparqlEndpointUrl($zonesSparql, "xml"))
let $knownZones := if ($isZonesAvailable ) then distinct-values(data(sparqlx:executeSparqlQuery($zonesSparql)//sparql:binding[@name='inspireid']/sparql:literal)) else ()
let $unknownZones :=
    for $zone in $M3Combinations
    let $id := if (empty($zone/@gml:id)) then "" else data($zone/@gml:id)
    where empty(index-of($knownZones, $id))=false()
    return $zone

let $tblM3 :=
    for $rec in $unknownZones
    return
        $rec/@gml:id

(: M4 :)


    let $M4Combinations :=
        for $featureType in $xmlconv:FEATURE_TYPES
        return
            doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

    let $allM4Combinations :=
    for $aqdModel in $M4Combinations
    return concat(data($aqdModel/@gml:id), "#", $aqdModel/ef:inspireId, "#", $aqdModel/ompr:inspireId, "#", $aqdModel/ef:name, "#", $aqdModel/ompr:name )

let $allM4Combinations := fn:distinct-values($allM4Combinations)
let $tblM4 :=
    for $rec in $allM4Combinations
    let $modelType := substring-before($rec, "#")
    let $tmpStr := substring-after($rec, concat($modelType, "#"))
    let $inspireId := substring-before($tmpStr, "#")
    let $tmpInspireId := substring-after($tmpStr, concat($inspireId, "#"))
    let $aqdInspireId := substring-before($tmpInspireId, "#")
    let $tmpEfName := substring-after($tmpInspireId, concat($aqdInspireId, "#"))
    let $efName := substring-before($tmpEfName, "#")
    let $omprName := substring-after($tmpEfName,concat($efName,"#"))
    return
        <tr>

            <td title="gml:id">{common:checkLink($modelType)}</td>
            <td title="ef:inspireId">{common:checkLink($inspireId)}</td>
            <td title="ompr:inspireId">{common:checkLink($aqdInspireId)}</td>
            <td title="ef:name">{common:checkLink($efName)}</td>
            <td title="ompr:name">{common:checkLink($omprName)}</td>
        </tr>

(: M5 :)
let $M5Combinations :=
    for $featureType in $xmlconv:FEATURE_TYPES
    return
        doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

let $gmlIds := $M5Combinations/lower-case(normalize-space(@gml:id))
let $duplicateGmlIds := distinct-values(
        for $id in $M5Combinations/@gml:id
        where string-length(normalize-space($id)) > 0 and count(index-of($gmlIds, lower-case(normalize-space($id)))) > 1
        return
            $id
)
let $amInspireIds := for $id in $M5Combinations/ef:inspireId
return
    lower-case(concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
            ", ", normalize-space($id/base:Identifier/base:versionId), "]"))
let $duplicateamInspireIds := distinct-values(
        for $id in $M5Combinations/ef:inspireId
        let $key :=
            concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
                    ", ", normalize-space($id/base:Identifier/base:versionId), "]")
        where string-length(normalize-space($id/base:Identifier/base:localId)) > 0 and count(index-of($amInspireIds, lower-case($key))) > 1
        return
            $key
)


let $aqdInspireIds := for $id in $M5Combinations/ef:inspireId
return
    lower-case(concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
            ", ", normalize-space($id/base:Identifier/base:versionId), "]"))
let $duplicateaqdInspireIds := distinct-values(
        for $id in $M5Combinations/ef:inspireId
        let $key :=
            concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
                    ", ", normalize-space($id/base:Identifier/base:versionId), "]")
        where  string-length(normalize-space($id/base:Identifier/base:localId)) > 0 and count(index-of($aqdInspireIds, lower-case($key))) > 1
        return
            $key
)


let $countGmlIdDuplicates := count($duplicateGmlIds)
let $countamInspireIdDuplicates := count($duplicateamInspireIds)
let $countaqdInspireIdDuplicates := count($duplicateaqdInspireIds)
let $countB8duplicates := $countGmlIdDuplicates + $countamInspireIdDuplicates + $countaqdInspireIdDuplicates

(: M6 :)
let $amInspireIds := $docRoot//aqd:AQD_Model/ef:inspireId/base:Identifier/concat(lower-case(normalize-space(base:namespace)), '##',
        lower-case(normalize-space(base:localId)))
let $duplicateEUStationCode := distinct-values(
        for $identifier in $docRoot//aqd:AQD_Model/ef:inspireId/base:Identifier
        where string-length(normalize-space($identifier/base:localId)) > 0 and count(index-of($amInspireIds,
                concat(lower-case(normalize-space($identifier/base:namespace)), '##', lower-case(normalize-space($identifier/base:localId))))) > 1
        return
            concat(normalize-space($identifier/base:namespace), ':', normalize-space($identifier/base:localId))
)
let $countAmInspireIdDuplicates := count($duplicateEUStationCode)
let $countM6duplicates := $countAmInspireIdDuplicates

(: M7 :)
let $allBaseNamespace := distinct-values($docRoot//aqd:AQD_Model/ef:inspireId/base:Identifier/base:namespace)
let  $tblM7 :=
    for $id in $allBaseNamespace
    let $localId := $docRoot//aqd:AQD_Model/ef:inspireId/base:Identifier[base:namespace = $id]/base:localId
    return
        <tr>
            <td title="base:namespace">{$id}</td>
            <td title="base:localId">{count($localId)}</td>
        </tr>

(: M7.1 :)
let $invalidNamespaces := common:checkNamespaces($source_url) 

(: M12 :)

let $invalidGeometry := distinct-values($docRoot//aqd:AQD_Model[count(ef:geometry) >0 and ef:geometry/@srsName != "urn:ogc:def:crs:EPSG::4258" and ef:geometry/@srsName != "urn:ogc:def:crs:EPSG::4326"]/@gml:id)

(: M15 :)

let $allNotNullEndPeriods :=
    for $allPeriod in $docRoot//aqd:AQD_Model/ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod
    where ($allPeriod/gml:endPosition[normalize-space(@indeterminatePosition)!="unknown"]
            or fn:string-length($allPeriod/gml:endPosition) > 0)
    return $allPeriod

let $allObservingCapabilityPeriod :=
    for $observingCapabilityPeriod in $allNotNullEndPeriods
    where ((xs:dateTime($observingCapabilityPeriod/gml:endPosition) < xs:dateTime($observingCapabilityPeriod/gml:beginPosition)))
    return
        <tr>
            <td title="aqd:AQD_Model">{data($observingCapabilityPeriod/../../../../@gml:id)}</td>
            <td title="gml:TimePeriod">{data($observingCapabilityPeriod/@gml:id)}</td>
            <td title="gml:beginPosition">{$observingCapabilityPeriod/gml:beginPosition}</td>
            <td title="gml:endPosition">{$observingCapabilityPeriod/gml:endPosition}</td>
        </tr>

(: M18 :)

let $invalidObservedProperty := xmlconv:checkVocabularyConceptValues($source_url, "ef:ObservingCapability", "ef:observedProperty", $xmlconv:POLLUTANT_VOCABULARY)

(: M19 :)

let $aqdModelArea :=
    for $allModelArea in $docRoot//aqd:AQD_ModelArea
    return $allModelArea/@gml:id

let $invalideFeatureOfInterest :=
    for $x in $docRoot//aqd:AQD_Model/ef:observingCapability/ef:ObservingCapability/ef:featureOfInterest
    where empty(index-of($aqdModelArea,fn:normalize-space(fn:substring-after($x/@xlink:href,"/"))))
    return
        <tr>
            <td title="aqd:AQD_AQD_Model">{data($x/../../../@gml:id)}</td>
            <td title="ef:featureOfInterest">{data(fn:normalize-space(fn:substring-after($x/@xlink:href,"/")))}</td>
        </tr>

(: M23 :)
let $invalidObservedPropertyCombinations :=
    for $oPC in $docRoot//gml:featureMember/aqd:AQD_Model/aqd:environmentalObjective/aqd:EnvironmentalObjective
    where
        (($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/1" and
                not(
                        (($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                                $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove" and
                                $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                                or
                                ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove" and
                                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                                or
                                ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL" and
                                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V")
                               or
                                ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL" and
                                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/wMean" and
                                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V")
                        )
                )
        )
                or
                ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/7" and
                        not(
                                ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV" and
                                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove-3yr" and
                                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                                        or
                                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV" and
                                                $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove-3yr" and
                                                $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                                        or
                                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LTO" and
                                                $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove" and
                                                $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                                        or
                                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV" and
                                                $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AOT40c-5yr" and
                                                $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V")
                                        or
                                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LTO" and
                                                $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AOT40c" and
                                                $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V")
                        )
                )
                or

                ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/8" and
                        not(
                                ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove" and
                                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                                        or
                                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                                                $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                                                $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                        ))
                or
                ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/9" and
                        not(
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V")
                    or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/NA" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/NA")
                     ))
                or
                ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5" and
                        not(
                                ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove" and
                                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                                        or
                                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                                                $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                                                $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                        )
                )
                or

                ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001" and
                        not(
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ECO" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AEI" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                        or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                        or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S1")
                        or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S2")
                        or
                        ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV" and
                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                        )
                   )
                or
                ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/10" and
                        not(
                                ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove" and
                                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                        ))
                or
                (($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5012" or
                        ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5012")) and
                        not(
                                ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                        ))
                or
                (($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5014" or
                        $oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5018" or
                        $oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5015" or
                        $oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5029") and
                        not(
                                ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV" and
                                        $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                                        $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                        )
                )
        )
    return
        <tr>
            <td title="gml:id">{data($oPC/../../@gml:id)}</td>
            <td title="ef:observedProperty">{data($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href)}</td>
            <td title="aqd:objectiveType">{data($oPC/aqd:objectiveType/@xlink:href)}</td>
            <td title="aqd:objectiveType">{data($oPC/aqd:reportingMetric/@xlink:href)}</td>
            <td title="aqd:objectiveType">{data($oPC/aqd:protectionTarget/@xlink:href)}</td>

        </tr>

(: M24 :)
    let $invalidAssessmentType := $docRoot//aqd:AQD_Model/aqd:assessmentType[fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/model" and fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/objective" ]/../@gml:id

(: M25 :)
    let $allTrueUsedAQD :=
        for $trueUsedAQD in $docRoot//gml:featureMember/aqd:AQD_Model
        where $trueUsedAQD/aqd:usedAQD = true()
        return $trueUsedAQD

    let $allInvalidTrueUsedAQD :=
        for $invalidTrueUsedAQD in $allTrueUsedAQD
        where
            count(sparqlx:executeSparqlQuery(xmlconv:getSamplingPointAssessment($invalidTrueUsedAQD/ef:inspireId/base:Identifier/base:localId ,$invalidTrueUsedAQD/ef:inspireId/base:Identifier/base:namespace))/*) = 0
        return
            <tr>
                <td title="gml:id">{data($invalidTrueUsedAQD/@gml:id)}</td>
                <td title="base:localId">{data($invalidTrueUsedAQD/ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="base:namespace">{data($invalidTrueUsedAQD/ef:inspireId/base:Identifier/base:namespace)}</td>
            </tr>

(: M26 :)
(:
let $allInvalZoneXlinks :=
   for $invalidZoneXlinks in $docRoot//gml:featureMember/aqd:AQD_Model/aqd:zone
        where
            count(xmlconv:executeSparqlQuery(xmlconv:getSamplingPointZone($invalidZoneXlinks/@xlink:href))/*) = 0
        return
            <tr>
                <td title="gml:id">{data($invalidZoneXlinks/../@gml:id)}</td>
                <td title="aqd:zone">{data($invalidZoneXlinks/@xlink:href)}</td>
            </tr>
:)

(: M26 Amended by Jaume Targa to add nilReason; also updated line 978 to pick $allInvalZoneXlinks :)
let $allInvalZoneXlinks :=
   for $invalidZoneXlinks in $docRoot//gml:featureMember/aqd:AQD_Model/aqd:zone
       where count(sparqlx:executeSparqlQuery(xmlconv:getSamplingPointZone($invalidZoneXlinks/@xlink:href))/*) = 0

       return if (not($invalidZoneXlinks/@nilReason="inapplicable")) then
           (<tr>
                <td title="gml:id">{data($invalidZoneXlinks/../@gml:id)}</td>
                <td title="aqd:zone">{data($invalidZoneXlinks/@xlink:href)}</td>
            </tr>)

	else ()

(: M27 :)
    let $localModelProcessIds := $docRoot//gml:featureMember/aqd:AQD_ModelProcess/ompr:inspireId/base:Identifier
    let $invalidDuplicateModelProcessIds :=
        for $idModelProcessCode in $docRoot//gml:featureMember/aqd:AQD_ModelProcess/ompr:inspireId/base:Identifier
        where
            count(index-of($localModelProcessIds/base:localId, normalize-space($idModelProcessCode/base:localId))) > 1 and
                    count(index-of($localModelProcessIds/base:namespace, normalize-space($idModelProcessCode/base:namespace))) > 1
        return
            <tr>
                <td title="aqd:AQD_ModelProcess">{data($idModelProcessCode/../../@gml:id)}</td>
                <td title="base:localId">{data($idModelProcessCode/base:localId)}</td>
                <td title="base:namespace">{data($idModelProcessCode/base:namespace)}</td>
            </tr>
(: M28 :)
    let $allBaseNamespace := distinct-values($docRoot//aqd:AQD_ModelProcess/ompr:inspireld/base:Identifier/base:namespace)
    let  $tblM28 :=
        for $id in $allBaseNamespace
        let $localId := $docRoot//aqd:AQD_ModelProcess/ompr:inspireld/base:Identifier[base:namespace = $id]/base:localId
        return
            <tr>
                <td title="base:namespace">{$id}</td>
                <td title="base:localId">{count($localId)}</td>
            </tr>

(: M29 :)

let $invalidBase2link :=
    for $baseLink in  $docRoot//aqd:AQD_ModelProcess/ompr:documentation/base2:DocumentationCitation/base2:link
    let $invalidLink:= fn:substring-before($baseLink,":")
where (fn:lower-case($invalidLink) !="http")and(fn:lower-case($invalidLink) !="https")
return
<tr>
    <td title="aqd:AQD_ModelProcess">{data($baseLink/../../../@gml:id)}</td>
    <td title="base2:link">{data($baseLink)}</td>
</tr>

(: M39 :)

let $invalidDataQualityReport :=
    for $dataQualityReport in  $docRoot//aqd:AQD_ModelProcess/dataQualityReport
    let $invalidLink:= fn:substring-before($dataQualityReport,":")
where (fn:lower-case($invalidLink) !="http")and(fn:lower-case($invalidLink) !="https")
return
<tr>
    <td title="aqd:AQD_ModelProcess">{data($dataQualityReport/../@gml:id)}</td>
    <td title="base2:link">{data($dataQualityReport)}</td>
</tr>

    (: M40 :)
let $localModelAreaIds := $docRoot//gml:featureMember/aqd:AQD_ModelArea/ompr:inspireId/base:Identifier
let $invalidDuplicateModelAreaIds :=
    for $idModelAreaCode in $docRoot//gml:featureMember/aqd:AQD_ModelArea/ompr:inspireId/base:Identifier
    where
        count(index-of($localModelAreaIds/base:localId, normalize-space($idModelAreaCode/base:localId))) > 1 and
                count(index-of($localModelAreaIds/base:namespace, normalize-space($idModelAreaCode/base:namespace))) > 1
    return
        <tr>
            <td title="aqd:AQD_ModelProcess">{data($idModelAreaCode/../../@gml:id)}</td>
            <td title="base:localId">{data($idModelAreaCode/base:localId)}</td>
            <td title="base:namespace">{data($idModelAreaCode/base:namespace)}</td>
        </tr>

(: M41 :)
let $allBaseNamespace := distinct-values($docRoot//aqd:AQD_ModelArea/aqd:inspireId/base:Identifier/base:namespace)
let  $tblM41 :=
    for $id in $allBaseNamespace
    let $localId := $docRoot//aqd:AQD_ModelArea/aqd:inspireId/base:Identifier[base:namespace = $id]/base:localId
    return
        <tr>
            <td title="base:namespace">{$id}</td>
            <td title="base:localId">{count($localId)}</td>
        </tr>

(: M43 :)

    let $invalidSrsName := distinct-values($docRoot//aqd:AQD_Sample[count(sams:shape) >0 and sams:shape/@srsName != "urn:ogc:def:crs:EPSG::4258" and sams:shape/@srsName != "urn:ogc:def:crs:EPSG::4326"]/@gml:id)

    return
    <table style="border-collapse:collapse;display:inline">
        <colgroup>
            <col width="15px" style="text-align:center"/>
            <col width="500px" style="text-align:left"/>
            <col width="350px" style="text-align:left"/>
            <col width="*"/>
        </colgroup>
        {html:buildResultRows_M("M1", $labels:M1, $labels:M1_SHORT, (), (), "", string(sum($countFeatureTypes)), "", "","error", $tblAllFeatureTypes)}
        {html:buildResultRows_M("M2", $labels:M2, $labels:M2_SHORT, (), (), "", string(count($tblM2)), "", "","error",())}
        {html:buildResultRows_M("M3", $labels:M3, $labels:M3_SHORT, (), (), "", string(count($tblM3)), "", "","error",())}
        {html:buildResultRows_M("M4", $labels:M4, $labels:M4_SHORT, (), (), "", string(count($tblM4)), "", "","error",$tblM4)}
        <tr style="border-top:1px solid #666666">
        <tr>
            <td style="vertical-align:top;">{ html:getBullet("M5", if ($countB8duplicates = 0) then "info" else "error") }</td>
            <th style="vertical-align:top;">{ $labels:M5 }</th>
            <td style="vertical-align:top;">{
                if ($countB8duplicates = 0) then
                    "All Ids are unique"
                else
                    concat($countB8duplicates, " duplicate", substring("s ", number(not($countB8duplicates > 1)) * 2) ,"found") }</td>
        </tr>
        {
            if ($countGmlIdDuplicates > 0) then
                <tr style="font-size: 0.9em;color:grey;">
                    <td colspan="2" style="text-align:right;vertical-align:top;">aqd:AQD_Model/@gml:id - </td>
                    <td style="font-style:italic;vertical-align:top;">{ string-join($duplicateGmlIds, ", ")}</td>
                </tr>
            else
                ()
        }
        {
            if ($countamInspireIdDuplicates > 0) then
                <tr style="font-size: 0.9em;color:grey;">
                    <td colspan="2" style="text-align:right;vertical-align:top;">am:inspireId - </td>
                    <td style="font-style:italic;vertical-align:top;">{ string-join($duplicateamInspireIds, ", ")}</td>
                </tr>
            else
                ()
        }
        {
            if ($countaqdInspireIdDuplicates > 0) then
                <tr style="font-size: 0.9em;color:grey;">
                    <td colspan="2" style="text-align:right;vertical-align:top;">aqd:inspireId - </td>
                    <td style="font-style:italic;vertical-align:top;">{ string-join($duplicateaqdInspireIds, ", ")}</td>
                </tr>
            else
                ()
        }
        </tr>
        <tr style="border-top:1px solid #666666">
            <td style="vertical-align:top;">{ html:getBullet("M6", if ($countM6duplicates = 0) then "info" else "error") }</td>
            <th style="vertical-align:top;">{ $labels:M6 }</th>
            <td style="vertical-align:top;">{
                if ($countM6duplicates = 0) then
                    <span style="font-size:1.3em;">All Ids are unique</span>
                else
                    concat($countM6duplicates, " error", substring("s ", number(not($countM6duplicates > 1)) * 2) ,"found") }</td>
        </tr>
        {html:buildResultRows_M("M7", $labels:M7, $labels:M7_SHORT, (), (), "", string(count($tblM7)), "", "","error",$tblM7)}
        {html:buildResultRows_M("M7.1", $labels:M7.1, $labels:M7.1_SHORT, $invalidNamespaces, (), "base:Identifier/base:namespace", "All values are valid", " invalid namespaces", "", "error", ())}
        {html:buildResultRows_M("M12", $labels:M12, $labels:M12_SHORT, $invalidGeometry,(), "aqd:AQD_Model/@gml:id","All srsName attributes are valid"," invalid attribute","","error", ())}
        {html:buildResultRows_M("M15", $labels:M15, $labels:M15_SHORT, (), $allObservingCapabilityPeriod, "", concat(fn:string(count($allObservingCapabilityPeriod))," errors found"), "", "","error", ())}
        {xmlconv:buildResultRowsWithTotalCount("M18", <span>The content of ./ef:observedProperty shall resolve to a valid code within
            <a href="{ $xmlconv:POLLUTANT_VOCABULARY }">{ $xmlconv:POLLUTANT_VOCABULARY }</a></span>,
                (), (), "ef:observedProperty", "", "", "", "error", $invalidObservedProperty)}
        {html:buildResultRows_M("M19", $labels:M19, $labels:M19_SHORT, (),$invalideFeatureOfInterest,"aqd:AQD_Model/@gml:id", "All attributes is invalid", " invalid attribute", "","warning", ())}
        {html:buildResultRows_M("M23", $labels:M23, $labels:M23_SHORT, (), $invalidObservedPropertyCombinations, "", concat(fn:string(count($invalidObservedPropertyCombinations))," errors found"), "", "","error", ())}
        {html:buildResultRows_M("M24", $labels:M24, $labels:M24_SHORT, $invalidAssessmentType, (), "", concat(fn:string(count($invalidAssessmentType))," errors found"), "", "","error", ())}
        {html:buildResultRows_M("M25", $labels:M25, $labels:M25_SHORT, (), $allInvalidTrueUsedAQD, "", concat(fn:string(count($allInvalidTrueUsedAQD))," errors found"), "", "","warning", ())}
        {html:buildResultRows_M("M26", $labels:M26, $labels:M26_SHORT, (),  $allInvalZoneXlinks, "", concat(fn:string(count( $allInvalZoneXlinks))," errors found"), "", "","error", ())}
        {html:buildResultRows_M("M27", $labels:M27, $labels:M27_SHORT, (),$invalidDuplicateModelProcessIds, "", concat(string(count($invalidDuplicateModelProcessIds))," errors found.") , "", "","error", ())}
        {html:buildResultRows_M("M28", $labels:M28, $labels:M28_SHORT, (), (), "", string(count($tblM28)), "", "","error",$tblM28)}
        {html:buildResultRows_M("M29", $labels:M29, $labels:M29_SHORT, (),$invalidBase2link, "aqd:AQD_ModelProcess/@gml:id","All attributes are valid"," invalid attribute","","error", ())}
        {html:buildResultRows_M("M39", $labels:M39, $labels:M39_SHORT, (),$invalidDataQualityReport, "aqd:AQD_ModelProcess/@gml:id","All attributes are valid"," invalid attribute","","error", ())}
        {html:buildResultRows_M("M40", $labels:M40, $labels:M40_SHORT, (),$invalidDuplicateModelAreaIds, "", concat(string(count($invalidDuplicateModelAreaIds))," errors found.") , "", "","error",())}
        {html:buildResultRows_M("M41", $labels:M41, $labels:M41_SHORT, (), (), "", string(count($tblM41)), "", "","error",$tblM41)}
        {html:buildResultRows_M("M43", $labels:M43, $labels:M43_SHORT, $invalidSrsName,(), "aqd:AQD_ModelArea/@gml:id","All srsDimension attributes are valid"," invalid attribute","","error", ())}

    </table>
};

declare function xmlconv:checkVocabularyConceptValues($source_url as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string) as element(tr)* {
    xmlconv:checkVocabularyConceptValues($source_url, $featureType, $element, $vocabularyUrl, "")
};

declare function xmlconv:checkVocabularyConceptValues($source_url as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $vocabularyType as xs:string) as element(tr)* {
    if (doc-available($source_url)) then
        let $sparql :=
            if ($vocabularyType = "collection") then
                xmlconv:getCollectionConceptUrlSparql($vocabularyUrl)
            else
                xmlconv:getConceptUrlSparql($vocabularyUrl)
        let $crConcepts := sparqlx:executeSparqlQuery($sparql)
        for $rec in doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]
        for $conceptUrl in $rec/child::*[name() = $element]/@xlink:href
        let $conceptUrl := normalize-space($conceptUrl)
        where string-length($conceptUrl) > 0

        return
            <tr isvalid="{ xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl) }">
                <td title="Feature type">{ $featureType }</td>
                <td title="gml:id">{data($rec/@gml:id)}</td>
                <td title="ef:name">{data($rec/ef:name)}</td>
                <td title="{ $element }" style="color:red">{$conceptUrl}</td>
            </tr>
        else
            ()
};

declare function xmlconv:checkVocabularyConceptValues2($source_url as xs:string, $concept , $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $vocabularyType as xs:string) as element(tr)* {
    if (doc-available($source_url)) then
        let $sparql :=
            if ($vocabularyType = "collection") then
                xmlconv:getCollectionConceptUrlSparql($vocabularyUrl)
            else
                xmlconv:getConceptUrlSparql($vocabularyUrl)
        let $crConcepts := sparqlx:executeSparqlQuery($sparql)
        for $rec in $concept/ancestor::*[name()=$featureType]
        for $conceptUrl in $concept
        let $conceptUrl := normalize-space($conceptUrl)
        where string-length($conceptUrl) > 0

        return
            <tr isvalid="{ xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl) }">
                <td title="Feature type">{ $featureType }</td>
                <td title="gml:id">{data($rec/@gml:id)}</td>
                <td title="ef:name">{data($rec/ef:name)}</td>
                <td title="{ $element }" style="color:red">{$conceptUrl}</td>
            </tr>
        else
            ()
};

declare function xmlconv:checkVocabularyConceptValues3($source_url as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $vocabularyType as xs:string) {
    if (doc-available($source_url)) then
        let $sparql :=
            if ($vocabularyType = "collection") then
                xmlconv:getCollectionConceptUrlSparql($vocabularyUrl)
            else
                xmlconv:getConceptUrlSparql($vocabularyUrl)
        let $crConcepts := sparqlx:executeSparqlQuery($sparql)
        for $rec in doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]
        for $conceptUrl in $rec/child::*[name() = $element]
        where  not(xmlconv:isMatchingVocabCode($crConcepts, normalize-space($conceptUrl/@xlink:href)))
        return
            $conceptUrl
        else
            ()
};


declare function xmlconv:checkVocabularyaqdAnalyticalTechniqueValues($source_url as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $vocabularyType as xs:string) as element(tr)* {
    if(doc-available($source_url)) then
        let $sparql :=
            if ($vocabularyType = "collection") then
                xmlconv:getCollectionConceptUrlSparql($vocabularyUrl)
            else
                xmlconv:getConceptUrlSparql($vocabularyUrl)
        let $crConcepts := sparqlx:executeSparqlQuery($sparql)
        for $rec in doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]
        for $conceptUrl in $rec/child::*[name() = $element]/aqd:AnalyticalTechnique/child::*[name() = $element]/@xlink:href
        let $conceptUrl := normalize-space($conceptUrl)
        where string-length($conceptUrl) > 0
        return
            <tr isvalid="{ xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl) }">
                <td title="Feature type">{ $featureType }</td>
                <td title="gml:id">{data($rec/@gml:id)}</td>
                <td title="ef:name">{data($rec/ef:name)}</td>
                <td title="{ $element }" style="color:red">{$conceptUrl}</td>
            </tr>
        else
            ()
};


declare function xmlconv:checkVocabularyConceptEquipmentValues($source_url as xs:string,  $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $vocabularyType as xs:string) as element(tr)* {
    if (doc-available($source_url)) then
        let $sparql :=
            if ($vocabularyType = "collection") then
                xmlconv:getCollectionConceptUrlSparql($vocabularyUrl)
            else
                xmlconv:getConceptUrlSparql($vocabularyUrl)
        let $crConcepts := sparqlx:executeSparqlQuery($sparql)
        for $rec in doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]
        for $conceptUrl in $rec/child::*[name() = $element]/*/aqd:equipment/@xlink:href
        let $conceptUrl := normalize-space($conceptUrl)
        where string-length($conceptUrl) > 0
        return
            <tr isvalid="{ xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl) }">
                <td title="Feature type">{ $featureType }</td>
                <td title="gml:id">{data($rec/@gml:id)}</td>
                <td title="ef:name">{data($rec/ef:name)}</td>
                <td title="{ $element }" style="color:red">{$conceptUrl}</td>
            </tr>
    else
        ()
};
declare function xmlconv:checkMeasurementMethodLinkValues($source_url as xs:string,  $concept,$featureType as xs:string,  $vocabularyUrl as xs:string, $vocabularyType as xs:string) as element(tr)* {
    if (doc-available($source_url)) then
        let $sparql :=
            if ($vocabularyType = "collection") then
                xmlconv:getCollectionConceptUrlSparql($vocabularyUrl)
            else
                xmlconv:getConceptUrlSparql($vocabularyUrl)
        let $crConcepts := sparqlx:executeSparqlQuery($sparql)
        for $conceptUrl in $concept/../../aqd:measurementMethod/aqd:MeasurementMethod/aqd:measurementMethod/@xlink:href
            let $measurementMethodStyle := if(xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl))then "" else "color:red"
            let $analyticalTechniqueStyle := if(count($conceptUrl/../../../../*[name(.) = "aqd:analyticalTechnique"])=0)then "" else "color:red"
            let $samplingMethod := if(count($conceptUrl/../../../../*[name(.) = "aqd:samplingMethod"])=0)then "" else "color:red"
        return
            <tr isvalid="{ xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl) and count($conceptUrl/../../../../*[name(.) = "aqd:analyticalTechnique"])=0  and count($conceptUrl/../../../../*[name(.) = "aqd:samplingMethod"])=0}">
                <td title="gml:id">{data($conceptUrl/../../../../@gml:id)}</td>
                <td style="{$measurementMethodStyle}" title="{name($conceptUrl/..)}" >{data($conceptUrl)}</td>
                <td style="{$analyticalTechniqueStyle}" title=" aqd:analyticalTechnique " >{if(count($conceptUrl/../../../../*[name(.) = "aqd:analyticalTechnique"])=0)then "Valid." else "Error, shall not be provided."}</td>
                <td style="{$samplingMethod}" title=" aqd:samplingMethod " >{if(count($conceptUrl/../../../../*[name(.) = "aqd:samplingMethod"])=0)then "Valid." else "Error, shall not be provided."}</td>
            </tr>
    else
        ()
};

declare function xmlconv:getConceptUrlSparql($scheme as xs:string) as xs:string {
    concat("PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    SELECT ?concepturl ?label
    WHERE {
      ?concepturl skos:inScheme <", $scheme, ">;
                  skos:prefLabel ?label
    }")
};

declare function xmlconv:getCollectionConceptUrlSparql($collection as xs:string) as xs:string {
    concat("PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    SELECT ?concepturl
    WHERE {
        GRAPH <", $collection, "> {
            <", $collection, "> skos:member ?concepturl .
            ?concepturl a skos:Concept
        }
    }")
};

declare function xmlconv:isMatchingVocabCode($crConcepts as element(sparql:result)*, $concept as xs:string) as xs:boolean {
    count($crConcepts/sparql:binding[@name="concepturl" and sparql:uri=$concept]) > 0
};

(:
 : ======================================================================
 : Main function
 : ======================================================================
 :)
declare function xmlconv:proceed($source_url as xs:string, $countryCode as xs:string) {

let $countFeatures := count(doc($source_url)//gml:featureMember/descendant::*[
    not(empty(index-of($xmlconv:FEATURE_TYPES, name())))]
    )
let $result := if ($countFeatures > 0) then xmlconv:checkReport($source_url, $countryCode) else ()

return
    <div>
        <h2>Check environmental monitoring feature types - Dataflow D on Models and Objective Estimation</h2>
        {
        if ( $countFeatures = 0) then
            <p>No environmental monitoring feature type elements ({string-join($xmlconv:FEATURE_TYPES, ", ")}) found from this XML.</p>
        else
        <div>
            {
                if ($result//div/@class = 'error') then
                    <p class="error" style="color:red"><strong>This XML file did NOT pass the following crucial check(s): {string-join($result//div[@class = 'error'], ',')}</strong></p>
                else
                    <p>This XML file passed all crucial checks.</p>
            }
            {
                if ($result//div/@class = 'warning') then
                    <p class="warning" style="color:orange"><strong>This XML file generated warnings during the following check(s): {string-join($result//div[@class = 'warning'], ',')}</strong></p>
                else
                    ()
            }
            <p>This feedback report provides a summary overview of feature types reported and some consistency checks defined in Dataflow D on Models and Objective Estimation as specified in <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a>.</p>
            <div><a id='legendLink' href="javascript: showLegend()" style="padding-left:10px;">How to read the test results?</a></div>
            <fieldset style="font-size: 90%; display:none" id="legend">
                <legend>How to read the test results</legend>
                All test results are labeled with coloured bullets. The number in the bullet reffers to the rule code. The background colour of the bullets means:
                <ul style="list-style-type: none;">
                    <li><div style="width:50px; display:inline-block;margin-left:10px">{html:getBullet('Blue', 'info')}</div> - the data confirms to the rule, but additional feedback could be provided in QA result.</li>
                    <li><div style="width:50px; display:inline-block;margin-left:10px">{html:getBullet('Red', 'error')}</div> - the crucial check did NOT pass and errenous records found from the delivery.</li>
                    <li><div style="width:50px; display:inline-block;margin-left:10px">{html:getBullet('Orange', 'warning')}</div> - the non-crucial check did NOT pass.</li>
                    <li><div style="width:50px; display:inline-block;margin-left:10px">{html:getBullet('Grey', 'skipped')}</div> - the check was skipped due to no relevant values found to check.</li>
                </ul>
                <p>Click on the "Show records" link to see more details about the test result.</p>
            </fieldset>
            <h3>Test results</h3>
            {$result}
        </div>

        }
    </div>

};