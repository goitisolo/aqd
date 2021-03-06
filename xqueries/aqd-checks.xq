module namespace checks = "aqd-checks";

declare namespace xlink = "http://www.w3.org/1999/xlink";

declare function checks:vocab($docRoot as document-node()) {
    let $data := data(($docRoot//*[contains(., "http://dd.eionet.europa.eu/vocabularyconcept/aq/")], $docRoot//@*[contains(., "http://dd.eionet.europa.eu/vocabularyconcept/aq/")]))
    let $all := distinct-values($data)
    for $x in $all
    return
        <tr>
            <td title="Vocabulary link">{$x}</td>
        </tr>
};

declare function checks:vocaballOLD($docRoot as document-node()) {
    
     let $assessmentType := (($docRoot//aqd:assessmentType[contains(@xlink:href, "https://dd.eionet.europa.eu/")], $docRoot//aqd:assessmentType[contains(@xlink:href, "http://dd.eionet.europa.eu/")]))
     let $valid := dd:getValidConcepts($vocabulary:ASSESSMENTTYPE_VOCABULARY || "rdf")
     let $assessmentInvalid:=
     for $x in $assessmentType
      where not(data($x/@xlink:href) = $valid)
      return data($x/@xlink:href)


    let $uom := (($docRoot//swe:uom[contains(@xlink:href, "https://dd.eionet.europa.eu/")], $docRoot//swe:uom[contains(@xlink:href, "http://dd.eionet.europa.eu/")]))
    let $validCons := dd:getValidConceptsLC("http://dd.eionet.europa.eu/vocabulary/uom/concentration/rdf")
    let $uomInvalid:=
     for $x in $uom
      where not(data($x/@xlink:href) = $validCons)
      return data($x/@xlink:href)


    let $organisationLevel := (($docRoot//ef:organisationLevel[contains(@xlink:href, "https://dd.eionet.europa.eu/")], $docRoot//ef:organisationLevel[contains(@xlink:href, "http://dd.eionet.europa.eu/")]))
     let $validOL := dd:getValidConcepts($vocabulary:ORGANISATIONAL_LEVEL_VOCABULARY || "rdf")
     let $organisationInvalid:=
     for $x in $organisationLevel
      where not(data($x/@xlink:href) = $validOL)
      return data($x/@xlink:href)

    let $unit := (($docRoot//aqd:unit[contains(@xlink:href, "https://dd.eionet.europa.eu/")], $docRoot//aqd:unit[contains(@xlink:href, "http://dd.eionet.europa.eu/")]))
    let $validUnit := dd:getValidConcepts($vocabulary:UOM_TIME || "rdf")
    let $unitInvalid:=
     for $x in $unit
      where not(data($x/@xlink:href) = $validUnit)
      return data($x/@xlink:href)

    let $omprname := (($docRoot//ompr:name[contains(@xlink:href, "https://dd.eionet.europa.eu/")], $docRoot//ompr:name[contains(@xlink:href, "http://dd.eionet.europa.eu/")]))
    let $validOmprname := dd:getValidConcepts($vocabulary:PROCESS_PARAMETER || "rdf")
    let $omprnameInvalid:=
     for $x in $omprname
      where not(data($x/@xlink:href) = $validOmprname)
      return data($x/@xlink:href)

   let $altitude := (($docRoot//aqd:altitude[contains(@uom, "https://dd.eionet.europa.eu/")], $docRoot//aqd:altitude[contains(@uom, "http://dd.eionet.europa.eu/")]))
    let $validAltitude := dd:getValidConcepts($vocabulary:UOM_LENGTH || "rdf")
    let $altitudeInvalid:=
     for $x in $altitude
      where not(data($x/@xlink:href) = $validAltitude)
      return data($x/@xlink:href)

    let $category := (($docRoot//swe:Category[contains(@definition, "https://dd.eionet.europa.eu/")], $docRoot//swe:Category[contains(@definition, "http://dd.eionet.europa.eu/")]))
    let $validCategory := dd:getValidConcepts($vocabulary:OBSERVATIONS_VERIFICATION || "rdf")
    let $categoryInvalid:=
     for $x in $category
      where not(data($x/@xlink:href) = $validCategory)
      return data($x/@xlink:href)



let $allRecords:=($assessmentInvalid,$uomInvalid,$organisationInvalid,$unitInvalid,$omprnameInvalid,$altitudeInvalid,$categoryInvalid)
    for $z in $allRecords   
    return
        <tr>
            <td title=" Vocabulary link">{$z}</td>
        </tr>
};

declare function checks:vocaball($docRoot as document-node()) {

 try {   

(: let $xlink := (($docRoot//*[contains(@xlink:href, "https://dd.eionet.europa.eu/")], $docRoot//*[contains(@xlink:href, "http://dd.eionet.europa.eu/")]))
 let $uom := (($docRoot//*[contains(@uom, "https://dd.eionet.europa.eu/")], $docRoot//*[contains(@uom, "http://dd.eionet.europa.eu/")]))
 let $definition := (($docRoot//*[contains(@definition, "https://dd.eionet.europa.eu/")], $docRoot//*[contains(@definition, "http://dd.eionet.europa.eu/")])):)
 let $uom2:=
    (: for $att in $docRoot//*[@uom]:)
    for $att in $docRoot//@uom
     return data($att)

let $xlinkAtt:=
    for $x in (($docRoot//*[contains(@xlink:href, "https://dd.eionet.europa.eu/")], $docRoot//*[contains(@xlink:href, "http://dd.eionet.europa.eu/")]))
        return $x/@xlink:href

(:let $uomAtt:=
    for $x in $uom
        return $x/@uom:)

let $definitionAtt:=
    for $x in (($docRoot//*[contains(@definition, "https://dd.eionet.europa.eu/")], $docRoot//*[contains(@definition, "http://dd.eionet.europa.eu/")]))
        return $x/@definition

let $data:= ($uom2,$xlinkAtt,$definitionAtt)

                        for $x in $data 
                      

                        return 
                         if (starts-with($x,'http://') or starts-with($x,'https://')) then (      
                   
                            let $request := <http:request href="{$x}" method="HEAD"/>
                            let $response := http:send-request($request)[1]  

                            let $url := $request/@href            
                            let $status := $response/@status
                            let $message := $response/@message

                            where ($status!=200)
                           return
                            <tr>

                                <td title=" Vocabulary link">{$url/string()}</td>
                                <td title=" Status">{$status/string()}</td>
                                <td title=" Message">{$message/string()}</td>
                               
                            </tr>  

                         
                        )
                       else (
                        <tr>

                                <td title=" Vocabulary link">{$x}</td>
                                <td title=" Status">{'Not valid host or protocol'}</td>
                                
                                
                            </tr>  
                        
                        )

                 
}

catch * {
           html:createErrorRow($err:code, $err:description)
        }          

};

