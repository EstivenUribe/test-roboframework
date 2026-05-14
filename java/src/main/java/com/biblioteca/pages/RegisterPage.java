package com.biblioteca.pages;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;

/**
 * Page Object: pantalla de registro.
 * Cubre HU-001.
 */
public class RegisterPage extends BasePage {

    private static final By NOMBRE   = By.xpath("//input[@name='nombre' or @placeholder[contains(translate(.,'NOMBRE','nombre'),'ombre')]]");
    private static final By APELLIDO = By.xpath("//input[@name='apellido' or @placeholder[contains(translate(.,'APELLIDO','apellido'),'pellido')]]");
    private static final By CEDULA   = By.xpath("//input[@name='cedula' or @name='cc' or @placeholder[contains(translate(.,'CÉDULA','cedula'),'dula')]]");
    private static final By EMAIL    = By.xpath("//input[@type='email' or @name='email']");
    private static final By PASSWORD = By.xpath("//input[@type='password']");
    private static final By BTN_CREAR = By.xpath("//button[contains(text(),'Crear cuenta') or contains(text(),'Registrar')]");

    public RegisterPage(WebDriver driver) {
        super(driver);
    }

    public void fillForm(String nombre, String apellido, String cedula,
                         String email, String password) {
        waitVisible(NOMBRE);
        clearAndType(NOMBRE,    nombre);
        clearAndType(APELLIDO,  apellido);
        clearAndType(CEDULA,    cedula);
        clearAndType(EMAIL,     email);
        clearAndType(PASSWORD,  password);
    }

    public void submit() {
        click(BTN_CREAR);
    }

    public void register(String nombre, String apellido, String cedula,
                         String email, String password) {
        fillForm(nombre, apellido, cedula, email, password);
        submit();
    }
}
