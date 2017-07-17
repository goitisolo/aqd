xquery version "3.0";

(:~
: User: George Sofianos
: Date: 6/23/2016
: Time: 3:59 PM
:)

module namespace errors = "aqd-errors";

import module namespace dd = "aqd-dd" at "aqd-dd.xquery";

declare variable $errors:XML := errors:getError("XML");
declare variable $errors:NS := errors:getError("NS");

declare variable $errors:B0 := errors:getError("B0");
declare variable $errors:B01 := errors:getError("B1");
declare variable $errors:B02 :=  errors:getError("B2");
declare variable $errors:B03 := errors:getError("B3");
declare variable $errors:B04 := errors:getError("B4");
declare variable $errors:B05 := errors:getError("B5");
declare variable $errors:B06a := errors:getError("B6a");
declare variable $errors:B06b := errors:getError("B6b");
declare variable $errors:B07 := errors:getError("B7");
declare variable $errors:B08 := errors:getError("B8");
declare variable $errors:B09 := errors:getError("B9");
declare variable $errors:B10 := errors:getError("B10");
declare variable $errors:B10.1 := errors:getError("B10.1");
declare variable $errors:B11 := errors:getError("B11");
declare variable $errors:B12 := errors:getError("B12");
declare variable $errors:B13 := errors:getError("B13");
declare variable $errors:B14 := errors:getError("B14");
declare variable $errors:B15 := errors:getError("B15");
declare variable $errors:B16 := errors:getError("B16");
declare variable $errors:B17 := errors:getError("B17");
declare variable $errors:B18 := errors:getError("B18");
declare variable $errors:B19 := errors:getError("B19");
declare variable $errors:B20 := errors:getError("B20");
declare variable $errors:B21 := errors:getError("B21");
declare variable $errors:B22 := errors:getError("B22");
declare variable $errors:B23 := errors:getError("B23");
declare variable $errors:B24 := errors:getError("B24");
declare variable $errors:B25 := errors:getError("B25");
declare variable $errors:B26 := errors:getError("B26");
declare variable $errors:B27 := errors:getError("B27");
declare variable $errors:B28 := errors:getError("B28");
declare variable $errors:B29 := errors:getError("B29");
declare variable $errors:B30 := errors:getError("B30");
declare variable $errors:B31 := errors:getError("B31");
declare variable $errors:B32 := errors:getError("B32");
declare variable $errors:B33 := errors:getError("B33");
declare variable $errors:B34 := errors:getError("B34");
declare variable $errors:B35 := errors:getError("B35");
declare variable $errors:B36 := errors:getError("B36");
declare variable $errors:B37 := errors:getError("B37");
declare variable $errors:B38 := errors:getError("B38");
declare variable $errors:B39a := errors:getError("B39a");
declare variable $errors:B39b := errors:getError("B39b");
declare variable $errors:B39c := errors:getError("B39c");
declare variable $errors:B40 := errors:getError("B40");
declare variable $errors:B41 := errors:getError("B41");
declare variable $errors:B42 := errors:getError("B42");
declare variable $errors:B43 := errors:getError("B43");
declare variable $errors:B44 := errors:getError("B44");
declare variable $errors:B45 := errors:getError("B45");
declare variable $errors:B46 := errors:getError("B46");
declare variable $errors:B47 := errors:getError("B47");

declare variable $errors:C0 := errors:getError("C0");
declare variable $errors:C01 := errors:getError("C01");
declare variable $errors:C02 := errors:getError("C02");
declare variable $errors:C03 := errors:getError("C03");
declare variable $errors:C04 := errors:getError("C04");
declare variable $errors:C05 := errors:getError("C05");
declare variable $errors:C06 := errors:getError("C06");
declare variable $errors:C06.1 := errors:getError("C06.1");
declare variable $errors:C07 := errors:getError("C07");
declare variable $errors:C08 := errors:getError("C08");
declare variable $errors:C09 := errors:getError("C09");
declare variable $errors:C10 := errors:getError("C10");
declare variable $errors:C11 := errors:getError("C11");
declare variable $errors:C12 := errors:getError("C12");
declare variable $errors:C13 := errors:getError("C13");
declare variable $errors:C14 := errors:getError("C14");
declare variable $errors:C15 := errors:getError("C15");
declare variable $errors:C16 := errors:getError("C16");
declare variable $errors:C17 := errors:getError("C17");
declare variable $errors:C18 := errors:getError("C18");
declare variable $errors:C19 := errors:getError("C19");
declare variable $errors:C20 := errors:getError("C20");
declare variable $errors:C21 := errors:getError("C21");
declare variable $errors:C22 := errors:getError("C22");
declare variable $errors:C23 := errors:getError("C23");
declare variable $errors:C23a := errors:getError("C23a");
declare variable $errors:C23b := errors:getError("C23b");
declare variable $errors:C24 := errors:getError("C24");
declare variable $errors:C25 := errors:getError("C25");
declare variable $errors:C26 := errors:getError("C26");
declare variable $errors:C27 := errors:getError("C27");
declare variable $errors:C28 := errors:getError("C28");
declare variable $errors:C29 := errors:getError("C29");
declare variable $errors:C31 := errors:getError("C31");
declare variable $errors:C32 := errors:getError("C32");
declare variable $errors:C33 := errors:getError("C33");
declare variable $errors:C35 := errors:getError("C35");
declare variable $errors:C37 := errors:getError("C37");
declare variable $errors:C38 := errors:getError("C38");
declare variable $errors:C40 := errors:getError("C40");
declare variable $errors:C41 := errors:getError("C41");
declare variable $errors:C42 := errors:getError("C42");

declare variable $errors:D0 := errors:getError("D0");
declare variable $errors:D01 := errors:getError("D01");
declare variable $errors:D02 := errors:getError("D02");
declare variable $errors:D03 := errors:getError("D03");
declare variable $errors:D04 := errors:getError("D04");
declare variable $errors:D05 := errors:getError("D05");
declare variable $errors:D06 := errors:getError("D06");
declare variable $errors:D07 := errors:getError("D07");
declare variable $errors:D07.1 := errors:getError("D07.1");
declare variable $errors:D08 := errors:getError("D08");
declare variable $errors:D09 := errors:getError("D09");
declare variable $errors:D10 := errors:getError("D10");
declare variable $errors:D11 := errors:getError("D11");
declare variable $errors:D12 := errors:getError("D12");
declare variable $errors:D14 := errors:getError("D14");
declare variable $errors:D15 := errors:getError("D15");
declare variable $errors:D16 := errors:getError("D16");
declare variable $errors:D16.1 := errors:getError("D16.1");
declare variable $errors:D17 := errors:getError("D17");
declare variable $errors:D18 := errors:getError("D18");
declare variable $errors:D19 := errors:getError("D19");
declare variable $errors:D20 := errors:getError("D20");
declare variable $errors:D21 := errors:getError("D21");
declare variable $errors:D23 := errors:getError("D23");
declare variable $errors:D24 := errors:getError("D24");
declare variable $errors:D26 := errors:getError("D26");
declare variable $errors:D27 := errors:getError("D27");
declare variable $errors:D28 := errors:getError("D28");
declare variable $errors:D29 := errors:getError("D29");
declare variable $errors:D30 := errors:getError("D30");
declare variable $errors:D31 := errors:getError("D31");
declare variable $errors:D32 := errors:getError("D32");
declare variable $errors:D32.1 := errors:getError("D32.1");
declare variable $errors:D33 := errors:getError("D33");
declare variable $errors:D34 := errors:getError("D34");
declare variable $errors:D35 := errors:getError("D35");
declare variable $errors:D36 := errors:getError("D36");
declare variable $errors:D37 := errors:getError("D37");
declare variable $errors:D40 := errors:getError("D40");
declare variable $errors:D41 := errors:getError("D41");
declare variable $errors:D42 := errors:getError("D42");
declare variable $errors:D43 := errors:getError("D43");
declare variable $errors:D44 := errors:getError("D44");
declare variable $errors:D44b := errors:getError("D44b");
declare variable $errors:D45 := errors:getError("D45");
declare variable $errors:D46 := errors:getError("D46");
declare variable $errors:D48 := errors:getError("D48");
declare variable $errors:D50 := errors:getError("D50");
declare variable $errors:D51 := errors:getError("D51");
declare variable $errors:D52 := errors:getError("D52");
declare variable $errors:D53 := errors:getError("D53");
declare variable $errors:D54 := errors:getError("D54");
declare variable $errors:D55 := errors:getError("D55");
declare variable $errors:D55.1 := errors:getError("D55.1");
declare variable $errors:D56 := errors:getError("D56");
declare variable $errors:D57 := errors:getError("D57");
declare variable $errors:D58 := errors:getError("D58");
declare variable $errors:D59 := errors:getError("D59");
declare variable $errors:D60a := errors:getError("D60a");
declare variable $errors:D60b := errors:getError("D60b");
declare variable $errors:D61 := errors:getError("D61");
declare variable $errors:D62 := errors:getError("D62");
declare variable $errors:D63 := errors:getError("D63");
declare variable $errors:D65 := errors:getError("D65");
declare variable $errors:D67a := errors:getError("D67a");
declare variable $errors:D67b := errors:getError("D67b");
declare variable $errors:D68 := errors:getError("D68");
declare variable $errors:D69 := errors:getError("D69");
declare variable $errors:D71 := errors:getError("D71");
declare variable $errors:D72 := errors:getError("D72");
declare variable $errors:D72.1 := errors:getError("D72.1");
declare variable $errors:D73 := errors:getError("D73");
declare variable $errors:D74 := errors:getError("D74");
declare variable $errors:D75 := errors:getError("D75");
declare variable $errors:D76 := errors:getError("D76");
declare variable $errors:D77 := errors:getError("D77");
declare variable $errors:D78 := errors:getError("D78");
declare variable $errors:D91 := errors:getError("D91");
declare variable $errors:D92 := errors:getError("D92");
declare variable $errors:D93 := errors:getError("D93");
declare variable $errors:D94 := errors:getError("D94");

declare variable $errors:E0 := errors:getError("E0");
declare variable $errors:E01a := errors:getError("E01a");
declare variable $errors:E01b := errors:getError("E01b");
declare variable $errors:E02 := errors:getError("E02");
declare variable $errors:E03 := errors:getError("E03");
declare variable $errors:E04 := errors:getError("E04");
declare variable $errors:E05 := errors:getError("E05");
declare variable $errors:E06 := errors:getError("E06");
declare variable $errors:E07 := errors:getError("E07");
declare variable $errors:E08 := errors:getError("E08");
declare variable $errors:E09 := errors:getError("E09");
declare variable $errors:E10 := errors:getError("E10");
declare variable $errors:E11 := errors:getError("E11");
declare variable $errors:E12 := errors:getError("E12");
declare variable $errors:E15 := errors:getError("E15");
declare variable $errors:E16 := errors:getError("E16");
declare variable $errors:E17 := errors:getError("E17");
declare variable $errors:E18 := errors:getError("E18");
declare variable $errors:E19 := errors:getError("E19");
declare variable $errors:E19b := errors:getError("E19b");
declare variable $errors:E20 := errors:getError("E20");
declare variable $errors:E21 := errors:getError("E21");
declare variable $errors:E22 := errors:getError("E22");
declare variable $errors:E23 := errors:getError("E23");
declare variable $errors:E24 := errors:getError("E24");
declare variable $errors:E25 := errors:getError("E25");
declare variable $errors:E26 := errors:getError("E26");
declare variable $errors:E27 := errors:getError("E27");
declare variable $errors:E28 := errors:getError("E28");
declare variable $errors:E29 := errors:getError("E29");
declare variable $errors:E30 := errors:getError("E30");
declare variable $errors:E31 := errors:getError("E31");
declare variable $errors:E32 := errors:getError("E32");

declare variable $errors:Eb0 := errors:getError("E0");
declare variable $errors:Eb01a := errors:getError("E01a");
declare variable $errors:Eb01b := errors:getError("E01b");
declare variable $errors:Eb02 := errors:getError("E02");
declare variable $errors:Eb03 := errors:getError("E03");
declare variable $errors:Eb04 := errors:getError("E04");
declare variable $errors:Eb05 := errors:getError("E05");
declare variable $errors:Eb06 := errors:getError("E06");
declare variable $errors:Eb07 := errors:getError("E07");
declare variable $errors:Eb08 := errors:getError("E08");
declare variable $errors:Eb09 := errors:getError("E09");
declare variable $errors:Eb10 := errors:getError("E10");
declare variable $errors:Eb11 := errors:getError("E11");
declare variable $errors:Eb12 := errors:getError("E12");
declare variable $errors:Eb15 := errors:getError("E15");
declare variable $errors:Eb16 := errors:getError("E16");
declare variable $errors:Eb17 := errors:getError("E17");
declare variable $errors:Eb18 := errors:getError("E18");
declare variable $errors:Eb19 := errors:getError("E19");
declare variable $errors:Eb19b := errors:getError("E19b");
declare variable $errors:Eb20 := errors:getError("E20");
declare variable $errors:Eb21 := errors:getError("E21");
declare variable $errors:Eb22 := errors:getError("E22");
declare variable $errors:Eb23 := errors:getError("E23");
declare variable $errors:Eb24 := errors:getError("E24");
declare variable $errors:Eb25 := errors:getError("E25");
declare variable $errors:Eb26 := errors:getError("E26");
declare variable $errors:Eb27 := errors:getError("E27");
declare variable $errors:Eb28 := errors:getError("E28");
declare variable $errors:Eb29 := errors:getError("E29");
declare variable $errors:Eb30 := errors:getError("E30");
declare variable $errors:Eb31 := errors:getError("E31");
declare variable $errors:Eb32 := errors:getError("E32");
declare variable $errors:Eb35 := errors:getError("E35");
declare variable $errors:Eb36 := errors:getError("E36");
declare variable $errors:Eb37 := errors:getError("E37");
declare variable $errors:Eb38 := errors:getError("E38");
declare variable $errors:Eb39 := errors:getError("E39");
declare variable $errors:Eb40 := errors:getError("E40");
declare variable $errors:Eb41 := errors:getError("E41");
declare variable $errors:Eb42 := errors:getError("E42");

declare variable $errors:G0 := errors:getError("G0");
declare variable $errors:G01 := errors:getError("G01");
declare variable $errors:G02 := errors:getError("G02");
declare variable $errors:G03 := errors:getError("G03");
declare variable $errors:G04 := errors:getError("G04");
declare variable $errors:G05 := errors:getError("G05");
declare variable $errors:G06 := errors:getError("G06");
declare variable $errors:G07 := errors:getError("G07");
declare variable $errors:G08 := errors:getError("G08");
declare variable $errors:G09 := errors:getError("G08");
declare variable $errors:G09.1 := errors:getError("G09.1");
declare variable $errors:G10 := errors:getError("G10");
declare variable $errors:G11 := errors:getError("G11");
declare variable $errors:G12 := errors:getError("G12");
declare variable $errors:G13 := errors:getError("G13");
declare variable $errors:G13b := errors:getError("G13b");
declare variable $errors:G13c := errors:getError("G13c");
declare variable $errors:G14 := errors:getError("G14");
declare variable $errors:G14b := errors:getError("G14b");
declare variable $errors:G15 := errors:getError("G15");
declare variable $errors:G17 := errors:getError("G17");
declare variable $errors:G18 := errors:getError("G18");
declare variable $errors:G19 := errors:getError("G19");
declare variable $errors:G20 := errors:getError("G20");
declare variable $errors:G21 := errors:getError("G21");
declare variable $errors:G22 := errors:getError("G22");
declare variable $errors:G23 := errors:getError("G23");
declare variable $errors:G24 := errors:getError("G24");
declare variable $errors:G25 := errors:getError("G25");
declare variable $errors:G26 := errors:getError("G26");
declare variable $errors:G27 := errors:getError("G27");
declare variable $errors:G28 := errors:getError("G28");
declare variable $errors:G29 := errors:getError("G29");
declare variable $errors:G30 := errors:getError("G30");
declare variable $errors:G31 := errors:getError("G31");
declare variable $errors:G32 := errors:getError("G32");
declare variable $errors:G33 := errors:getError("G33");
declare variable $errors:G38 := errors:getError("G38");
declare variable $errors:G39 := errors:getError("G39");
declare variable $errors:G40 := errors:getError("G40");
declare variable $errors:G41 := errors:getError("G41");
declare variable $errors:G42 := errors:getError("G42");
declare variable $errors:G44 := errors:getError("G44");
declare variable $errors:G45 := errors:getError("G45");
declare variable $errors:G46 := errors:getError("G46");
declare variable $errors:G47 := errors:getError("G47");
declare variable $errors:G52 := errors:getError("G52");
declare variable $errors:G53 := errors:getError("G53");
declare variable $errors:G54 := errors:getError("G54");
declare variable $errors:G55 := errors:getError("G55");
declare variable $errors:G56 := errors:getError("G56");
declare variable $errors:G58 := errors:getError("G58");
declare variable $errors:G59 := errors:getError("G59");
declare variable $errors:G60 := errors:getError("G60");
declare variable $errors:G61 := errors:getError("G61");
declare variable $errors:G62 := errors:getError("G62");
declare variable $errors:G63 := errors:getError("G63");
declare variable $errors:G64 := errors:getError("G64");
declare variable $errors:G65 := errors:getError("G65");
declare variable $errors:G66 := errors:getError("G66");
declare variable $errors:G67 := errors:getError("G67");
declare variable $errors:G70 := errors:getError("G70");
declare variable $errors:G71 := errors:getError("G71");
declare variable $errors:G72 := errors:getError("G72");
declare variable $errors:G73 := errors:getError("G73");
declare variable $errors:G74 := errors:getError("G714");
declare variable $errors:G75 := errors:getError("G75");
declare variable $errors:G76 := errors:getError("G76");
declare variable $errors:G78 := errors:getError("G78");
declare variable $errors:G79 := errors:getError("G79");
declare variable $errors:G80 := errors:getError("G80");
declare variable $errors:G81 := errors:getError("G81");
declare variable $errors:G85 := errors:getError("G85");
declare variable $errors:G86 := errors:getError("G86");

declare variable $errors:M0 := errors:getError("M0");
declare variable $errors:M01 := errors:getError("M01");
declare variable $errors:M02 := errors:getError("M02");
declare variable $errors:M03 := errors:getError("M03");
declare variable $errors:M04 := errors:getError("M04");
declare variable $errors:M05 := errors:getError("M05");
declare variable $errors:M06 := errors:getError("M06");
declare variable $errors:M07 := errors:getError("M07");
declare variable $errors:M07.1 := errors:getError("M7.1");
declare variable $errors:M08 := errors:getError("M08");
declare variable $errors:M12 := errors:getError("M12");
declare variable $errors:M15 := errors:getError("M15");
declare variable $errors:M18 := errors:getError("M18");
declare variable $errors:M19 := errors:getError("M19");
declare variable $errors:M20 := errors:getError("M20");
declare variable $errors:M23 := errors:getError("M23");
declare variable $errors:M24 := errors:getError("M24");
declare variable $errors:M25 := errors:getError("M25");
declare variable $errors:M26 := errors:getError("M26");
declare variable $errors:M27 := errors:getError("M27");
declare variable $errors:M28 := errors:getError("M28");
declare variable $errors:M28.1 := errors:getError("M28.1");
declare variable $errors:M29 := errors:getError("M29");
declare variable $errors:M30 := errors:getError("M30");
declare variable $errors:M34 := errors:getError("M34");
declare variable $errors:M35 := errors:getError("M35");
declare variable $errors:M39 := errors:getError("M39");
declare variable $errors:M40 := errors:getError("M40");
declare variable $errors:M41 := errors:getError("M41");
declare variable $errors:M41.1 := errors:getError("M41.1");
declare variable $errors:M43 := errors:getError("M43");
declare variable $errors:M45 := errors:getError("M45");
declare variable $errors:M46 := errors:getError("M46");

declare variable $errors:C6.1 := "Check that namespace is registered in vocabulary";

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
declare variable $errors:COLOR_BLOCKER := "firebrick";
declare variable $errors:COLOR_FAILED := "black";

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
    case $errors:BLOCKER return $errors:COLOR_BLOCKER
    case $errors:ERROR return $errors:COLOR_ERROR
    case $errors:WARNING return $errors:COLOR_WARNING
    case $errors:INFO return $errors:COLOR_INFO
    default return $errors:COLOR_SKIPPED
};

declare function errors:getMaxError($records as element()*) as xs:string {
    if (count($records[@status = $errors:FAILED]) > 0) then $errors:FAILED
    else if (count($records[@class = $errors:FAILED]) > 0) then $errors:FAILED
    else if (count($records[@class = $errors:BLOCKER]) > 0) then $errors:BLOCKER
    else if (count($records[@class = $errors:ERROR]) > 0) then $errors:ERROR
    else if (count($records[@class = $errors:WARNING]) > 0) then $errors:WARNING
    else if (count($records[@class = $errors:SKIPPED]) > 0) then $errors:SKIPPED
    else $errors:INFO
};

declare function errors:getError($notation as xs:string) {
    dd:getQAQCErrorType($notation)
};