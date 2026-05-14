package com.biblioteca.utils;

import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import java.io.*;
import java.util.*;

/**
 * Utilidad para leer datos de prueba desde archivos Excel (.xlsx).
 * Usa Apache POI. Devuelve listas de mapas {columna → valor}.
 */
public class ExcelReader {

    private final Workbook workbook;

    public ExcelReader(String filePath) throws IOException {
        try (FileInputStream fis = new FileInputStream(filePath)) {
            this.workbook = new XSSFWorkbook(fis);
        }
    }

    /**
     * Lee todos los datos de una hoja.
     * La primera fila son encabezados (claves del mapa).
     * Las filas completamente vacías se omiten.
     */
    public List<Map<String, String>> getSheetData(String sheetName) {
        Sheet sheet = workbook.getSheet(sheetName);
        if (sheet == null) {
            throw new IllegalArgumentException("Hoja no encontrada: " + sheetName);
        }

        Row headerRow = sheet.getRow(0);
        List<String> headers = new ArrayList<>();
        for (Cell cell : headerRow) {
            headers.add(cell.getStringCellValue().trim());
        }

        List<Map<String, String>> rows = new ArrayList<>();
        for (int i = 1; i <= sheet.getLastRowNum(); i++) {
            Row row = sheet.getRow(i);
            if (row == null) continue;

            Map<String, String> data = new LinkedHashMap<>();
            boolean hasData = false;
            for (int j = 0; j < headers.size(); j++) {
                Cell cell = row.getCell(j, Row.MissingCellPolicy.CREATE_NULL_AS_BLANK);
                String value = getCellValue(cell);
                data.put(headers.get(j), value);
                if (!value.isEmpty()) hasData = true;
            }
            if (hasData) rows.add(data);
        }
        return rows;
    }

    /**
     * Devuelve la fila cuyo campo "id_caso" coincide (case-insensitive).
     */
    public Map<String, String> getRowByCase(String sheetName, String caseId) {
        return getSheetData(sheetName).stream()
            .filter(row -> caseId.equalsIgnoreCase(row.get("id_caso")))
            .findFirst()
            .orElseThrow(() -> new IllegalArgumentException(
                "Caso '" + caseId + "' no encontrado en hoja '" + sheetName + "'"));
    }

    private String getCellValue(Cell cell) {
        if (cell == null) return "";
        switch (cell.getCellType()) {
            case STRING:  return cell.getStringCellValue().trim();
            case NUMERIC:
                double v = cell.getNumericCellValue();
                return (v == Math.floor(v)) ? String.valueOf((long) v) : String.valueOf(v);
            case BOOLEAN: return String.valueOf(cell.getBooleanCellValue());
            case FORMULA:
                try { return cell.getStringCellValue().trim(); }
                catch (Exception e) { return String.valueOf(cell.getNumericCellValue()); }
            default: return "";
        }
    }

    public void close() throws IOException {
        workbook.close();
    }
}
