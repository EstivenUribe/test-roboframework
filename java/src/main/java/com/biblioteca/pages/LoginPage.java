package com.biblioteca.pages;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;

/**
 * Page Object: pantalla de login.
 * Cubre HU-002 y HU-003.
 */
public class LoginPage extends BasePage {

    private static final By EMAIL    = By.xpath("//input[@type='email' or @name='email']");
    private static final By PASSWORD = By.xpath("//input[@type='password']");
    private static final By BTN_ENTRAR = By.xpath(
        "//button[contains(translate(text(),'ENTRAR','entrar'),'entrar')" +
        " or @type='submit'][not(contains(text(),'Crear'))]"
    );
    private static final By LINK_CREAR_CUENTA = By.xpath(
        "//*[contains(text(),'Crear cuenta') or contains(text(),'Registrarse')]"
    );

    public LoginPage(WebDriver driver) {
        super(driver);
    }

    public void open() {
        navigate("/");
        waitVisible(EMAIL);
    }

    public void enterEmail(String email) {
        clearAndType(EMAIL, email);
    }

    public void enterPassword(String password) {
        clearAndType(PASSWORD, password);
    }

    public void clickEntrar() {
        click(BTN_ENTRAR);
    }

    public void login(String email, String password) {
        open();
        enterEmail(email);
        enterPassword(password);
        clickEntrar();
    }

    public void loginAsAdmin() {
        login(com.biblioteca.config.Config.ADMIN_EMAIL,
              com.biblioteca.config.Config.ADMIN_PASSWORD);
    }

    public boolean isEntrarDisabled() {
        String disabled = driver.findElement(BTN_ENTRAR).getAttribute("disabled");
        return disabled != null;
    }

    public void clickCrearCuenta() {
        click(LINK_CREAR_CUENTA);
    }
}
