package com.biblioteca.pages;

import org.openqa.selenium.*;
import org.openqa.selenium.support.ui.*;
import java.util.List;

/**
 * Page Object: Catálogo de Libros.
 * Cubre HU-006, HU-007, HU-008, HU-009.
 */
public class CatalogPage extends BasePage {

    private static final By TITULO    = By.xpath("//input[@name='titulo' or @placeholder[contains(translate(.,'TÍTULO','titulo'),'tulo')]]");
    private static final By AUTOR     = By.xpath("//input[@name='autor' or @placeholder[contains(translate(.,'AUTOR','autor'),'utor')]]");
    private static final By ANNO      = By.xpath("//input[@name='año' or @name='year' or @type='number' or @placeholder[contains(.,'ño')]]");
    private static final By SEL_TIPO  = By.xpath("//select[@name='tipo' or @name='type']");
    private static final By SEL_GENERO= By.xpath("//select[@name='genero' or @name='genre']");
    private static final By BTN_CREAR = By.xpath("//button[contains(text(),'Crear')][not(contains(text(),'Cuenta'))]");
    private static final By BUSQUEDA  = By.xpath("//input[@type='search' or @placeholder[contains(translate(.,'BUSCAR','buscar'),'uscar')]]");
    private static final By LISTA     = By.xpath("//*[@class[contains(.,'list') or contains(.,'table') or contains(.,'books') or contains(.,'catalogo')]] | //ul | //tbody");

    public CatalogPage(WebDriver driver) {
        super(driver);
    }

    public void waitForList() {
        waitVisible(LISTA);
    }

    public void fillBookForm(String titulo, String autor, String anno,
                             String tipo, String genero) {
        clearAndType(TITULO, titulo);
        clearAndType(AUTOR,  autor);
        clearAndType(ANNO,   anno);
        try { selectByVisibleText(SEL_TIPO,   tipo);   } catch (Exception ignored) {}
        try { selectByVisibleText(SEL_GENERO, genero); } catch (Exception ignored) {}
    }

    public void clickCrear() {
        click(BTN_CREAR);
    }

    public void createBook(String titulo, String autor, String anno,
                           String tipo, String genero) {
        fillBookForm(titulo, autor, anno, tipo, genero);
        clickCrear();
    }

    public void search(String term) {
        waitVisible(BUSQUEDA);
        clearAndType(BUSQUEDA, term);
        try { Thread.sleep(800); } catch (InterruptedException ignored) {}
    }

    public boolean isBookInList(String titulo) {
        try {
            waitVisible(By.xpath("//*[contains(text(),'" + titulo + "')]"));
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public void clickEditFirst() {
        click(By.xpath("(//button[contains(text(),'Editar')])[1]"));
    }

    public void updateTitle(String nuevoTitulo) {
        clearAndType(TITULO, nuevoTitulo);
        click(By.xpath("//button[contains(text(),'Actualizar') or contains(text(),'Guardar')]"));
    }

    public void cancelEdit() {
        click(By.xpath("//button[contains(text(),'Cancelar')]"));
    }

    public void clickDeleteFirst() {
        click(By.xpath("(//button[contains(text(),'Borrar') or contains(text(),'Eliminar')])[1]"));
    }

    public String getListText() {
        try {
            return waitVisible(LISTA).getText();
        } catch (Exception e) {
            return "";
        }
    }

    public boolean isCreateButtonVisible() {
        return isPresent(BTN_CREAR);
    }

    public boolean isDeleteButtonVisible() {
        return isPresent(By.xpath("//button[contains(text(),'Borrar')]"));
    }
}
