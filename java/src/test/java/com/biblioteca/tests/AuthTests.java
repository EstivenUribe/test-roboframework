package com.biblioteca.tests;

import com.biblioteca.base.BaseTest;
import org.testng.Assert;
import org.testng.annotations.*;

import java.util.List;
import java.util.Map;

/**
 * HU-001 · HU-002 · HU-003 — Autenticación y Registro.
 * Datos leídos desde hoja "Login" y "Registro" del Excel.
 */
public class AuthTests extends BaseTest {

    // ─── HU-002: Login ────────────────────────────────────────────────────

    @Test(description = "TC-LGN-001: Login exitoso con admin → Panel Principal")
    public void tc_lgn_001_loginExitosoAdmin() {
        Map<String, String> data = excel.getRowByCase("Login", "TC-LGN-001");
        step("Abrir login");
        loginPage.login(data.get("email"), data.get("password"));
        panelPage.waitForPanel();
        step("Panel Principal visible");
        Assert.assertTrue(
            driver.getPageSource().contains(data.get("texto_esperado_panel")),
            "El Panel Principal debe contener: " + data.get("texto_esperado_panel")
        );
    }

    @Test(description = "TC-LGN-002: Badge de rol visible tras login exitoso")
    public void tc_lgn_002_badgeRolVisible() {
        loginAsAdmin();
        step("Verificar badge de rol");
        Assert.assertTrue(panelPage.isRolBadgeVisible(),
            "El badge del rol debe estar visible en el header (HU-004)");
    }

    @Test(description = "TC-LGN-003: Botón Entrar deshabilitado con campos vacíos")
    public void tc_lgn_003_botonDeshabilitadoVacio() {
        step("Abrir login sin llenar campos");
        loginPage.open();
        step("Verificar que el botón está deshabilitado");
        Assert.assertTrue(loginPage.isEntrarDisabled(),
            "El botón 'Entrar' debe estar deshabilitado si los campos están vacíos (HU-002)");
    }

    @Test(description = "TC-LGN-004: Toast de error con credenciales incorrectas")
    public void tc_lgn_004_credencialesIncorrectas() {
        Map<String, String> data = excel.getRowByCase("Login", "TC-LGN-004");
        step("Intentar login con credenciales incorrectas");
        loginPage.login(data.get("email"), data.get("password"));
        step("Verificar toast de error");
        Assert.assertTrue(
            loginPage.toastContains(data.get("mensaje_esperado")),
            "Debe aparecer toast con: " + data.get("mensaje_esperado")
        );
    }

    @Test(description = "TC-LGN-005: Data-driven login con todos los casos del Excel")
    public void tc_lgn_005_dataDrivenLogin() {
        List<Map<String, String>> rows = excel.getSheetData("Login");
        for (Map<String, String> row : rows) {
            String id = row.get("id_caso");
            test.info("Ejecutando caso: " + id + " — " + row.get("descripcion"));
            loginPage.login(row.get("email"), row.get("password"));
            step(id + "_resultado");

            if ("exito".equals(row.get("resultado_esperado"))) {
                panelPage.waitForPanel();
                test.pass(id + " PASÓ: login exitoso");
                panelPage.logout();
            } else {
                String mensajeEsperado = row.get("mensaje_esperado");
                boolean hasError = loginPage.hasValidationError()
                    || (!mensajeEsperado.isEmpty() && loginPage.toastContains(mensajeEsperado));
                Assert.assertTrue(hasError,
                    id + ": debe mostrar error de validación o toast '" + mensajeEsperado + "'");
                loginPage.open();
            }
        }
    }

    // ─── HU-003: Logout ────────────────────────────────────────────────────

    @Test(description = "TC-LGT-001: Logout limpia localStorage y redirige a login")
    public void tc_lgt_001_logoutLimpiaStorage() {
        loginAsAdmin();
        step("Hacer logout");
        panelPage.logout();
        step("Verificar localStorage limpio");
        String rolStorage = loginPage.getLocalStorageItem("user_rol");
        Assert.assertNull(rolStorage,
            "Después del logout, user_rol en localStorage debe ser null (HU-003)");
    }

    @Test(description = "TC-LGT-002: ProtectedRoute redirige a login sin sesión")
    public void tc_lgt_002_protectedRouteRedirige() {
        step("Navegar a ruta protegida sin sesión");
        driver.get(com.biblioteca.config.Config.BASE_URL + "/catalogo");
        sleep(2000);
        step("Verificar redirección a login");
        Assert.assertTrue(driver.getCurrentUrl().contains(com.biblioteca.config.Config.BASE_URL),
            "Debe redirigir al login (HU-003)");
        Assert.assertTrue(
            !driver.findElements(org.openqa.selenium.By.xpath("//input[@type='email']")).isEmpty(),
            "Debe mostrar el formulario de login"
        );
    }

    // ─── HU-001: Registro ─────────────────────────────────────────────────

    @Test(description = "TC-REG-001: Data-driven registro con todos los casos del Excel")
    public void tc_reg_001_dataDrivenRegistro() {
        List<Map<String, String>> rows = excel.getSheetData("Registro");
        for (Map<String, String> row : rows) {
            String id = row.get("id_caso");
            test.info("Caso: " + id + " — " + row.get("descripcion"));

            loginPage.open();
            loginPage.clickCrearCuenta();
            registerPage.fillForm(
                row.get("nombre"),
                row.get("apellido"),
                row.get("cedula"),
                row.get("email"),
                row.get("password")
            );
            step(id + "_formulario_relleno");
            registerPage.submit();

            if ("exito".equals(row.get("resultado_esperado"))) {
                Assert.assertFalse(registerPage.hasValidationError(),
                    id + ": registro exitoso no debe mostrar errores de validación (HU-001)");
            } else {
                String msgEsperado = row.get("mensaje_error");
                boolean hasError = registerPage.hasValidationError()
                    || (!msgEsperado.isEmpty() && registerPage.toastContains(msgEsperado));
                Assert.assertTrue(hasError,
                    id + ": debe mostrar error de validación o toast '" + msgEsperado + "' (HU-001)");
            }
            step(id + "_fin_caso");
        }
    }
}
