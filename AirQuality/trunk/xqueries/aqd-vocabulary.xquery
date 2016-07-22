xquery version "3.0";

(:~
: User: George Sofianos
: Date: 6/6/2016
: Time: 6:30 PM
:)

module namespace vocabulary = "aqd-vocabulary";

declare variable $vocabulary:OBLIGATIONS := "http://rod.eionet.europa.eu/obligations/";
declare variable $vocabulary:UOM_TIME := "http://dd.eionet.europa.eu/vocabulary/uom/time/";
declare variable $vocabulary:ENVIRONMENTALOBJECTIVE := "http://dd.eionet.europa.eu/vocabulary/aq/environmentalobjective/";
declare variable $vocabulary:AQ_MANAGEMENET_ZONE := "http://inspire.ec.europa.eu/codeList/ZoneTypeCode/airQualityManagementZone";
declare variable $vocabulary:AQ_MANAGEMENET_ZONE_LC := "http://inspire.ec.europa.eu/codelist/ZoneTypeCode/airQualityManagementZone";
declare variable $vocabulary:LEGISLATION_LEVEL := "http://inspire.ec.europa.eu/codeList/LegislationLevelValue/";
declare variable $vocabulary:LEGISLATION_LEVEL_LC := "http://inspire.ec.europa.eu/codelist/LegislationLevelValue/";
declare variable $vocabulary:MEDIA_VALUE_VOCABULARY_BASE_URI := "http://inspire.ec.europa.eu/codelist/MediaValue/";
declare variable $vocabulary:MEDIA_VALUE_VOCABULARY_BASE_URI_UC := "http://inspire.ec.europa.eu/codeList/MediaValue/";
declare variable $vocabulary:MEDIA_VALUE_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/inspire/MediaValue/";
declare variable $vocabulary:ORGANISATIONAL_LEVEL_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/organisationallevel/";
declare variable $vocabulary:NETWORK_TYPE_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/networktype/";
declare variable $vocabulary:METEO_PARAMS_VOCABULARY := ("http://vocab.nerc.ac.uk/collection/P07/current/","http://vocab.nerc.ac.uk/collection/I01/current/","http://dd.eionet.europa.eu/vocabulary/aq/meteoparameter/");
declare variable $vocabulary:METEO_PARAMS_VOCABULARY_I01 := "http://vocab.nerc.ac.uk/collection/I01/current/";
declare variable $vocabulary:METEO_PARAMS_VOCABULARY_aq := "http://dd.eionet.europa.eu/vocabulary/aq/meteoparameter/";
declare variable $vocabulary:AREA_CLASSIFICATION_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/areaclassification/";
declare variable $vocabulary:DISPERSION_LOCAL_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/dispersionlocal/";
declare variable $vocabulary:DISPERSION_REGIONAL_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/dispersionregional/";
declare variable $vocabulary:TIMEZONE_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/timezone/";
declare variable $vocabulary:POLLUTANT_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/";
declare variable $vocabulary:MEASUREMENTTYPE_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/measurementtype/";
declare variable $vocabulary:MEASUREMENTMETHOD_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/measurementmethod/";
declare variable $vocabulary:ANALYTICALTECHNIQUE_VOCABULARY :=  "http://dd.eionet.europa.eu/vocabulary/aq/analyticaltechnique/";
declare variable $vocabulary:SAMPLINGEQUIPMENT_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/samplingequipment/";
declare variable $vocabulary:MEASUREMENTEQUIPMENT_VOCABULARY :="http://dd.eionet.europa.eu/vocabulary/aq/measurementequipment/";
declare variable $vocabulary:UOM_CONCENTRATION_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/uom/concentration/";
declare variable $vocabulary:EQUIVALENCEDEMONSTRATED_VOCABULARY := "http://dd.eionet.europa.eu/vocabulary/aq/equivalencedemonstrated/";
declare variable $vocabulary:REPMETRIC_VOCABULARY as xs:string := "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/";
declare variable $vocabulary:OBJECTIVETYPE_VOCABULARY as xs:string := "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/";
declare variable $vocabulary:ADJUSTMENTTYPE_VOCABULARY as xs:string := "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/";
declare variable $vocabulary:ADJUSTMENTSOURCE_VOCABULARY as xs:string := "http://dd.eionet.europa.eu/vocabulary/aq/adjustmentsourcetype/";
declare variable $vocabulary:ASSESSMENTTYPE_VOCABULARY as xs:string := "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/";
declare variable $vocabulary:PROTECTIONTARGET_VOCABULARY as xs:string := "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/";
declare variable $vocabulary:METEO_PARAMS_VOCABULARY_M := "http://vocab.nerc.ac.uk/collection/P07/current/";
declare variable $vocabulary:ZONETYPE_VOCABULARY as xs:string := "http://dd.eionet.europa.eu/vocabulary/aq/zonetype/";
declare variable $vocabulary:PROCESS_PARAMETER as xs:string := "http://dd.eionet.europa.eu/vocabulary/aq/processparameter/";