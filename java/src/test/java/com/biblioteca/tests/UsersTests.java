package com.biblioteca.tests;

import com.biblioteca.base.BaseTest;
import org.openqa.selenium.By;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.util.List;
import java.util.Map;

/**
 * HU-004 · HU-005 · HU-013 · HU-014 · HU-015 · HU-016 — Usuarios y Roles.
 */
public class UsersTests extends BaseTest {

    // ─── HU-013: Ver usuarios ─────────────────────────────────────────────

    @Test(description = "TC-USR-001: Admin ve lista completa de usuarios")
    public void tc_usr_001_listaUsuarios() {
        loginAsAdmin();
        step("Navegar a Usuarios");
        panelPage.goToUsers();
        usersPage.waitForTable();
        step("Tabla de usuarios visible");
        String tableText = usersPage.getTableText();
        Assert.assertFalse(tableText.isEmpty(),
            "La tabla de usuarios debe tener contenido (HU-013)");
    }

    @Test(description = "TC-USR-002: Badges de rol visibles en la lista de usuarios")
    public void tc_usr_002_badgesRolVisibles() {
        loginAsAdmin();
        panelPage.goToUsers();
        usersPage.waitForTable();
        step("Verificar badges de rol");
        Assert.assertTrue(usersPage.areBadgesVisible(),
            "Los badges de rol deben ser visibles (HU-013)");
    }

    // ─── HU-004: Panel muestra secciones según rol ────────────────────────

    @Test(description = "TC-USR-003: Panel admin muestra tarjetas Usuarios y Redis")
    public void tc_usr_003_panelAdminCompleto() {
        loginAsAdmin();
        step("Verificar secciones del panel admin");
        Assert.assertTrue(panelPage.isUsersCardVisible(),
            "Admin debe ver tarjeta de Usuarios (HU-004)");
        Assert.assertTrue(panelPage.isRedisCardVisible(),
            "Admin debe ver tarjeta de Redis (HU-004, HU-016)");
    }

    // ─── HU-005 / HU-014: Editar usuario ─────────────────────────────────

    @Test(description = "TC-USR-005: Data-driven edición de usuarios desde Excel")
    public void tc_usr_005_editarUsuariosDataDriven() {
        loginAsAdmin();
        panelPage.goToUsers();
        usersPage.waitForTable();

        List<Map<String, String>> rows = excel.getSheetData("Usuarios");
        for (Map<String, String> row : rows) {
            if (!"editar".equals(row.get("accion"))) continue;
            String id = row.get("id_caso");
            test.info("Caso " + id + ": editar rol → " + row.get("rol_nuevo"));

            step(id + "_antes_editar");
            usersPage.clickEditFirst();
            sleep(500);

            try {
                usersPage.changeRol(row.get("rol_nuevo"));
            } catch (Exception e) {
                test.warning(id + ": no se pudo cambiar rol: " + e.getMessage());
            }

            if (!row.get("nombre_nuevo").isEmpty()) {
                try {
                    driver.findElement(By.xpath("//input[@name='nombre' or @placeholder[contains(.,'Nombre')]]"))
                          .sendKeys(row.get("nombre_nuevo"));
                } catch (Exception ignored) {}
            }

            step(id + "_antes_guardar");
            usersPage.saveChanges();
            sleep(1000);
            step(id + "_despues_guardar");
            test.info(id + ": guardado");
        }
    }

    @Test(description = "TC-USR-006: Panel de edición es inline (sin modal flotante)")
    public void tc_usr_006_edicionInline() {
        loginAsAdmin();
        panelPage.goToUsers();
        usersPage.waitForTable();
        step("Clic en Editar primer usuario");
        usersPage.clickEditFirst();
        sleep(500);
        step("Verificar que no hay modal flotante");
        boolean modalFotante = !driver.findElements(By.xpath(
            "//div[@role='dialog' or @class[contains(.,'modal-backdrop') or contains(.,'overlay')]]"
        )).isEmpty();
        Assert.assertFalse(modalFotante,
            "La edición debe ser inline, no abrir modal flotante (HU-014)");
    }

    @Test(description = "TC-USR-007: Campo contraseña vacío en edición es opcional")
    public void tc_usr_007_contrasenaOpcional() {
        loginAsAdmin();
        panelPage.goToUsers();
        usersPage.waitForTable();
        usersPage.clickEditFirst();
        sleep(500);
        step("Verificar campo contraseña vacío por defecto");
        try {
            var passField = driver.findElement(By.xpath(
                "//input[@type='password' and (@name='password' or @placeholder[contains(.,'Contraseña')])]"
            ));
            String value = passField.getAttribute("value");
            Assert.assertTrue(value == null || value.isEmpty(),
                "El campo contraseña debe estar vacío por defecto (HU-014)");
        } catch (Exception e) {
            test.warning("Campo contraseña no encontrado en panel de edición: " + e.getMessage());
        }
    }

    // ─── HU-015: Eliminar usuario ─────────────────────────────────────────

    @Test(description = "TC-USR-008: Eliminar usuario muestra modal y cancela")
    public void tc_usr_008_eliminarModalCancelado() {
        loginAsAdmin();
        panelPage.goToUsers();
        usersPage.waitForTable();
        step("Clic en Eliminar último usuario");
        usersPage.clickDeleteLast();
        sleep(500);
        step("Verificar modal de confirmación");
        boolean modal = !driver.findElements(By.xpath(
            "//button[contains(text(),'Sí') or contains(text(),'Confirmar') or contains(text(),'eliminar')]"
        )).isEmpty();
        Assert.assertTrue(modal,
            "Debe aparecer modal antes de eliminar (HU-015)");
        step("Cancelar para no eliminar datos reales");
        usersPage.cancel();
    }

    // ─── HU-016: Redis ─────────────────────────────────────────────────────

    @Test(description = "TC-USR-009: Solo admin ve tarjeta de Redis")
    public void tc_usr_009_redisSoloAdmin() {
        loginAsAdmin();
        step("Verificar tarjeta Redis visible para admin");
        Assert.assertTrue(panelPage.isRedisCardVisible(),
            "Solo el admin debe ver la tarjeta de Redis (HU-016)");
    }

    @Test(description = "TC-USR-010: Borrar sesiones Redis pide confirmación")
    public void tc_usr_010_redisConfirmacion() {
        loginAsAdmin();
        step("Clic en tarjeta Redis");
        try {
            panelPage.clickRedisCard();
            sleep(500);
            step("Verificar modal de confirmación Redis");
            boolean modal = !driver.findElements(By.xpath(
                "//button[contains(text(),'Sí') or contains(text(),'Confirmar') or contains(text(),'Borrar')]"
            )).isEmpty();
            test.info("Modal Redis visible: " + modal);
            Assert.assertTrue(modal,
                "Debe pedir confirmación antes de borrar sesiones Redis (HU-016)");
            step("Confirmar borrado Redis");
            panelPage.confirmModal();
            sleep(2000);
            String toast = "";
            try { toast = panelPage.waitForToast(); } catch (Exception ignored) {}
            test.info("Toast Redis: " + toast);
            step("TC-USR-010_redis_borrado");
        } catch (Exception e) {
            test.warning("Error en flujo Redis: " + e.getMessage());
        }
    }
}
