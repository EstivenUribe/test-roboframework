package com.biblioteca.tests;

import com.biblioteca.base.BaseTest;
import org.openqa.selenium.By;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.util.List;
import java.util.Map;

/**
 * HU-010 — Gestión de Tipos y Géneros.
 */
public class TypesGenresTests extends BaseTest {

    private static final By INPUT_TIPO   = By.xpath("(//input[@name='tipo' or @placeholder[contains(translate(.,'TIPO','tipo'),'tipo')]])[1]");
    private static final By INPUT_GENERO = By.xpath("(//input[@name='genero' or @placeholder[contains(translate(.,'GÉNERO','género'),'nero')]])[1]");
    private static final By BTN_AGREGAR  = By.xpath("(//button[contains(text(),'Agregar')])[1]");
    private static final By BTN_ACTUALIZAR = By.xpath("//button[contains(text(),'Actualizar')]");
    private static final By BTN_EDITAR   = By.xpath("(//button[contains(text(),'Editar')])[1]");

    @Test(description = "TC-TGN-001: Data-driven agregar tipos y géneros")
    public void tc_tgn_001_agregarDataDriven() {
        loginAsAdmin();
        step("Navegar a Tipos/Géneros");
        panelPage.goToTypesGenres();
        sleep(1000);

        List<Map<String, String>> rows = excel.getSheetData("TiposGeneros");
        for (Map<String, String> row : rows) {
            if (!"agregar".equals(row.get("accion"))) continue;
            String id  = row.get("id_caso");
            String cat = row.get("categoria");
            test.info("Caso " + id + ": agregar " + cat + " = '" + row.get("nombre") + "'");

            By inputLoc = "tipo".equals(cat) ? INPUT_TIPO : INPUT_GENERO;
            driver.findElement(inputLoc).clear();
            driver.findElement(inputLoc).sendKeys(row.get("nombre"));
            step(id + "_antes_agregar");
            click(By.xpath("(//button[contains(text(),'Agregar')])[" + ("tipo".equals(cat) ? "1" : "2") + "]"));

            sleep(800);
            step(id + "_resultado");

            if ("exito".equals(row.get("resultado_esperado"))) {
                boolean ok = driver.getPageSource().contains(row.get("nombre")) ||
                             toastContains("agregado") || toastContains("creado");
                Assert.assertTrue(ok,
                    id + ": el tipo/género '" + row.get("nombre") + "' debe aparecer en la lista (HU-010)");
            } else {
                boolean err = hasValidationError() || toastContains("existe") || toastContains("obligatorio");
                Assert.assertTrue(err,
                    id + ": debe mostrar error de validación o duplicado (HU-010)");
            }
        }
    }

    @Test(description = "TC-TGN-002: Campo vacío muestra error 'obligatorio'")
    public void tc_tgn_002_campoVacio() {
        loginAsAdmin();
        panelPage.goToTypesGenres();
        sleep(1000);
        step("Clic en Agregar sin texto");
        click(BTN_AGREGAR);
        step("Verificar mensaje obligatorio");
        Assert.assertTrue(
            driver.getPageSource().contains("obligatorio") || hasValidationError(),
            "Debe mostrar error cuando el campo está vacío (HU-010)"
        );
    }

    @Test(description = "TC-TGN-003: Duplicado case-insensitive muestra error")
    public void tc_tgn_003_duplicado() {
        Map<String, String> data = excel.getRowByCase("TiposGeneros", "TC-TGN-003");
        loginAsAdmin();
        panelPage.goToTypesGenres();
        sleep(1000);

        // Agregar original
        driver.findElement(INPUT_TIPO).clear();
        driver.findElement(INPUT_TIPO).sendKeys(data.get("nombre"));
        click(BTN_AGREGAR);
        sleep(1000);

        // Intentar duplicado
        step("Intentar agregar duplicado: " + data.get("nombre_duplicado"));
        driver.findElement(INPUT_TIPO).clear();
        driver.findElement(INPUT_TIPO).sendKeys(data.get("nombre_duplicado"));
        click(BTN_AGREGAR);
        sleep(800);
        step("Verificar mensaje de duplicado");
        Assert.assertTrue(
            driver.getPageSource().contains("ya existe") || toastContains("existe"),
            "Debe rechazar nombre duplicado (HU-010)"
        );
    }

    @Test(description = "TC-TGN-004: Editar tipo existente y actualizar")
    public void tc_tgn_004_editarTipo() {
        Map<String, String> data = excel.getRowByCase("TiposGeneros", "TC-TGN-004");
        loginAsAdmin();
        panelPage.goToTypesGenres();
        sleep(1000);
        step("Clic en Editar primer tipo");
        click(BTN_EDITAR);
        sleep(500);
        driver.findElement(INPUT_TIPO).clear();
        driver.findElement(INPUT_TIPO).sendKeys(data.get("nombre_nuevo"));
        step("Clic en Actualizar");
        click(BTN_ACTUALIZAR);
        sleep(1000);
        step("Verificar nombre actualizado");
        Assert.assertTrue(
            driver.getPageSource().contains(data.get("nombre_nuevo")) || toastContains("actualizado"),
            "El nombre debe actualizarse (HU-010)"
        );
    }

    @Test(description = "TC-TGN-005: Eliminar tipo requiere confirmación modal")
    public void tc_tgn_005_eliminarConModal() {
        loginAsAdmin();
        panelPage.goToTypesGenres();
        sleep(1000);
        step("Clic en Borrar primer ítem");
        click(By.xpath("(//button[contains(text(),'Borrar') or contains(text(),'Eliminar')])[1]"));
        sleep(500);
        step("Verificar modal de confirmación");
        boolean modalVisible = !driver.findElements(By.xpath(
            "//button[contains(text(),'Sí') or contains(text(),'Confirmar') or contains(text(),'eliminar')]"
        )).isEmpty();
        Assert.assertTrue(modalVisible, "Debe aparecer modal antes de eliminar (HU-010)");
        step("Confirmar eliminación");
        click(By.xpath("//button[contains(text(),'Sí') or contains(text(),'Confirmar') or contains(text(),'eliminar')]"));
        sleep(1000);
        Assert.assertTrue(toastContains("eliminado") || toastContains("borrado"),
            "Toast de eliminación debe aparecer (HU-010)");
    }

    // ── helpers ──────────────────────────────────────────────────────────

    private void click(By by) {
        new org.openqa.selenium.support.ui.WebDriverWait(
                driver,
                java.time.Duration.ofSeconds(com.biblioteca.config.Config.TIMEOUT_EXPLICIT))
            .until(org.openqa.selenium.support.ui.ExpectedConditions.elementToBeClickable(by))
            .click();
    }

    private boolean toastContains(String text) {
        return driver.getPageSource().toLowerCase().contains(text.toLowerCase());
    }

    private boolean hasValidationError() {
        return !driver.findElements(By.xpath(
            "//*[contains(@class,'error') or contains(@class,'invalid')][string-length(normalize-space(.))>0]"
        )).isEmpty();
    }
}
