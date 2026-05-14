package com.biblioteca.tests;

import com.biblioteca.base.BaseTest;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.util.List;
import java.util.Map;

/**
 * HU-006 · HU-007 · HU-008 · HU-009 — Catálogo de Libros.
 */
public class CatalogTests extends BaseTest {

    // ─── HU-006: Ver catálogo ─────────────────────────────────────────────

    @Test(description = "TC-CAT-001: Catálogo carga con lista de libros")
    public void tc_cat_001_catalogoCarga() {
        loginAsAdmin();
        step("Navegar al catálogo");
        panelPage.goToCatalog();
        catalogPage.waitForList();
        step("Catálogo visible");
        Assert.assertTrue(catalogPage.isCreateButtonVisible(),
            "El formulario de creación debe ser visible para admin (HU-006)");
    }

    @Test(description = "TC-CAT-002: Búsqueda en tiempo real filtra resultados")
    public void tc_cat_002_busquedaTiempoReal() {
        Map<String, String> data = excel.getRowByCase("Catalogo", "TC-CAT-002");
        loginAsAdmin();
        panelPage.goToCatalog();
        catalogPage.waitForList();
        step("Escribir término de búsqueda: " + data.get("termino_busqueda"));
        catalogPage.search(data.get("termino_busqueda"));
        step("Verificar resultados filtrados");
        // La lista debe contener el término O mostrar "Sin resultados"
        String listText = catalogPage.getListText();
        boolean filtered = listText.toLowerCase().contains(data.get("termino_busqueda").toLowerCase())
            || listText.contains("Sin resultados");
        Assert.assertTrue(filtered, "La búsqueda debe filtrar la lista o mostrar 'Sin resultados'");
    }

    @Test(description = "TC-CAT-003: Búsqueda sin resultados muestra mensaje")
    public void tc_cat_003_sinResultados() {
        loginAsAdmin();
        panelPage.goToCatalog();
        catalogPage.waitForList();
        step("Buscar término inexistente");
        catalogPage.search("XXXXXXXXXNOTEXISTS99999");
        step("Verificar mensaje sin resultados");
        Assert.assertTrue(
            driver.getPageSource().contains("Sin resultados") ||
            driver.getPageSource().contains("sin resultados") ||
            driver.getPageSource().contains("no hay"),
            "Debe mostrar mensaje cuando no hay resultados (HU-006)"
        );
    }

    // ─── HU-007: Crear libro ──────────────────────────────────────────────

    @Test(description = "TC-CAT-004: Crear libros data-driven desde Excel")
    public void tc_cat_004_crearLibrosDataDriven() {
        loginAsAdmin();
        panelPage.goToCatalog();
        catalogPage.waitForList();

        List<Map<String, String>> rows = excel.getSheetData("Catalogo");
        for (Map<String, String> row : rows) {
            if (!"crear".equals(row.get("accion"))) continue;
            String id = row.get("id_caso");
            test.info("Caso " + id + ": crear '" + row.get("titulo") + "'");

            catalogPage.createBook(
                row.get("titulo"),
                row.get("autor"),
                row.get("año"),
                row.get("tipo"),
                row.get("genero")
            );
            step(id + "_despues_crear");

            if ("exito".equals(row.get("resultado_esperado"))) {
                boolean inList = catalogPage.isBookInList(row.get("titulo"));
                boolean hasToast = catalogPage.toastContains("agregado") ||
                                   catalogPage.toastContains("creado");
                test.info(id + ": en lista=" + inList + ", toast=" + hasToast);
                Assert.assertTrue(inList || hasToast,
                    "El libro debe aparecer en la lista o toast de éxito: " + row.get("titulo"));
            } else {
                Assert.assertTrue(catalogPage.hasValidationError(),
                    "Debe mostrar error de validación para caso: " + id);
            }
        }
    }

    @Test(description = "TC-CAT-005: Campos vacíos muestran errores")
    public void tc_cat_005_camposVacios() {
        loginAsAdmin();
        panelPage.goToCatalog();
        catalogPage.waitForList();
        step("Clic en Crear sin rellenar campos");
        catalogPage.clickCrear();
        step("Verificar errores de validación");
        Assert.assertTrue(catalogPage.hasValidationError(),
            "Deben aparecer errores de validación con campos vacíos (HU-007)");
    }

    // ─── HU-008: Editar libro ─────────────────────────────────────────────

    @Test(description = "TC-CAT-008: Editar primer libro de la lista")
    public void tc_cat_008_editarLibro() {
        loginAsAdmin();
        panelPage.goToCatalog();
        catalogPage.waitForList();

        List<Map<String, String>> rows = excel.getSheetData("Catalogo");
        for (Map<String, String> row : rows) {
            if (!"editar".equals(row.get("accion"))) continue;
            test.info("Editando — nuevo título: " + row.get("titulo_nuevo"));
            step("Clic en Editar");
            catalogPage.clickEditFirst();
            step("Actualizar título");
            catalogPage.updateTitle(row.get("titulo_nuevo"));
            step("Verificar actualización");
            boolean updated = catalogPage.isBookInList(row.get("titulo_nuevo")) ||
                              catalogPage.toastContains("actualizado");
            Assert.assertTrue(updated, "El libro debe actualizarse en la lista (HU-008)");
        }
    }

    @Test(description = "TC-CAT-009: Cancelar edición vuelve a estado creación")
    public void tc_cat_009_cancelarEdicion() {
        loginAsAdmin();
        panelPage.goToCatalog();
        catalogPage.waitForList();
        step("Entrar en modo edición");
        catalogPage.clickEditFirst();
        step("Cancelar edición");
        catalogPage.cancelEdit();
        step("Verificar botón Crear visible de nuevo");
        Assert.assertTrue(catalogPage.isCreateButtonVisible(),
            "Tras cancelar, el formulario debe volver al estado de creación (HU-008)");
    }

    // ─── HU-009: Eliminar libro ───────────────────────────────────────────

    @Test(description = "TC-CAT-011: Eliminar libro requiere confirmación modal")
    public void tc_cat_011_eliminarConModal() {
        loginAsAdmin();
        panelPage.goToCatalog();
        catalogPage.waitForList();
        String listaBefore = catalogPage.getListText();
        step("Clic en Borrar");
        catalogPage.clickDeleteFirst();
        step("Confirmar modal de eliminación");
        confirmModal();
        sleep(1500);
        step("Verificar toast de eliminación");
        Assert.assertTrue(
            catalogPage.toastContains("eliminado") || catalogPage.toastContains("borrado"),
            "Debe aparecer toast de éxito tras eliminar (HU-009)"
        );
    }

    @Test(description = "TC-CAT-012: Cancelar eliminación no borra el libro")
    public void tc_cat_012_cancelarEliminacion() {
        loginAsAdmin();
        panelPage.goToCatalog();
        catalogPage.waitForList();
        String before = catalogPage.getListText();
        step("Clic en Borrar");
        catalogPage.clickDeleteFirst();
        step("Cancelar modal");
        cancelModal();
        sleep(500);
        step("Verificar lista sin cambios");
        String after = catalogPage.getListText();
        Assert.assertEquals(after, before,
            "Cancelar debe dejar la lista sin cambios (HU-009)");
    }

    private void confirmModal() { catalogPage.confirmModal(); }
    private void cancelModal()  { catalogPage.cancelModal(); }
}
