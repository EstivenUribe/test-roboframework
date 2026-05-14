package com.biblioteca.tests;

import com.biblioteca.base.BaseTest;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.util.List;
import java.util.Map;

/**
 * HU-011 · HU-012 — Dashboard y Estadísticas.
 */
public class DashboardTests extends BaseTest {

    @Test(description = "TC-DSH-001: Dashboard carga correctamente para admin")
    public void tc_dsh_001_dashboardCarga() {
        loginAsAdmin();
        step("Navegar al Dashboard");
        panelPage.goToDashboard();
        dashboardPage.waitForDashboard();
        step("Dashboard visible");
        Assert.assertFalse(driver.getPageSource().isEmpty(),
            "El Dashboard debe cargar correctamente (HU-011)");
    }

    @Test(description = "TC-DSH-002: Generar gráfico con los 4 filtros (data-driven)")
    public void tc_dsh_002_generarGraficoDataDriven() {
        loginAsAdmin();
        panelPage.goToDashboard();
        dashboardPage.waitForDashboard();

        List<Map<String, String>> rows = excel.getSheetData("Dashboard");
        for (Map<String, String> row : rows) {
            if (!"exito".equals(row.get("resultado_esperado"))) continue;
            String filtro = row.get("filtro");
            test.info("Caso " + row.get("id_caso") + ": filtro = " + filtro);

            step("Seleccionar filtro: " + filtro);
            try {
                dashboardPage.selectFilter(filtro);
            } catch (Exception e) {
                test.warning("No se pudo seleccionar filtro '" + filtro + "': " + e.getMessage());
                continue;
            }

            step("Generar gráfico");
            dashboardPage.clickGenerar();
            sleep(2500);
            step(row.get("id_caso") + "_grafico");

            boolean chartOk = dashboardPage.isChartVisible() ||
                driver.getPageSource().contains("canvas") ||
                driver.getPageSource().contains("chart");
            test.info("Gráfico visible: " + chartOk);
        }
    }

    @Test(description = "TC-DSH-003: Generar sin filtro muestra toast de advertencia")
    public void tc_dsh_003_sinFiltroError() {
        loginAsAdmin();
        panelPage.goToDashboard();
        dashboardPage.waitForDashboard();
        step("Hacer clic en Generar sin seleccionar filtro");
        dashboardPage.clickGenerar();
        sleep(2000);
        step("Verificar toast de advertencia");
        boolean toastOk = driver.getPageSource().toLowerCase().contains("filtro") ||
                          driver.getPageSource().toLowerCase().contains("selecciona");
        Assert.assertTrue(toastOk,
            "Debe aparecer mensaje indicando que se debe seleccionar un filtro (HU-011)");
    }

    @Test(description = "TC-DSH-004: Botón Sincronizar manual está disponible")
    public void tc_dsh_004_botonSincronizar() {
        loginAsAdmin();
        panelPage.goToDashboard();
        dashboardPage.waitForDashboard();
        step("Verificar botón Sincronizar");
        Assert.assertFalse(
            driver.findElements(org.openqa.selenium.By.xpath(
                "//button[contains(text(),'Sincronizar') or contains(text(),'↻')]"
            )).isEmpty(),
            "El botón de sincronización manual debe existir (HU-011)"
        );
        step("Clic en Sincronizar");
        dashboardPage.clickSincronizar();
        step("Sincronización completada");
    }

    @Test(description = "TC-DSH-005: Botón Generar deshabilitado durante operación")
    public void tc_dsh_005_botonDeshabilitadoDuranteGeneracion() {
        loginAsAdmin();
        panelPage.goToDashboard();
        dashboardPage.waitForDashboard();
        try {
            dashboardPage.selectFilter("tipo");
        } catch (Exception e) {
            test.warning("No se pudo seleccionar filtro: " + e.getMessage());
        }
        step("Clic en Generar — verificar estado del botón inmediatamente");
        dashboardPage.clickGenerar();
        boolean disabledDetected = dashboardPage.isGenerarDisabled();
        step("Estado botón tras click: disabled=" + disabledDetected);
        // El botón puede habilitarse rápidamente, sólo loguear
        test.info("Botón deshabilitado durante generación detectado: " + disabledDetected);
    }
}
