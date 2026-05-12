package ro.uaic.sii.docxlsx;

import java.time.LocalDate;

public record MacroRecord(
        LocalDate periodDate,
        Double mortgage30yRate,
        Double caseShillerHpi,
        Double cpiAllUrban,
        Double fedFundsRate,
        Integer housingStartsThousands
) {}
