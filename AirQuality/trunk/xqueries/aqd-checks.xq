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
