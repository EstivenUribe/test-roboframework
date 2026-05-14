package com.biblioteca.base;

import org.testng.*;

/**
 * Listener TestNG que imprime resumen de resultados en consola.
 * El reporte HTML completo lo gestiona BaseTest.
 */
public class ExtentReportListener implements ITestListener, ISuiteListener {

    @Override
    public void onStart(ISuite suite) {
        System.out.println("\n══════════════════════════════════════════════════");
        System.out.println("  BIBLIOTECA PRO — Inicio de Suite: " + suite.getName());
        System.out.println("══════════════════════════════════════════════════\n");
    }

    @Override
    public void onFinish(ISuite suite) {
        System.out.println("\n══════════════════════════════════════════════════");
        System.out.println("  Suite finalizada: " + suite.getName());
        System.out.println("══════════════════════════════════════════════════\n");
    }

    @Override
    public void onTestStart(ITestResult result) {
        System.out.printf("[TEST] Ejecutando: %s%n", result.getName());
    }

    @Override
    public void onTestSuccess(ITestResult result) {
        System.out.printf("[PASS] ✓ %s (%.2fs)%n",
            result.getName(), elapsed(result));
    }

    @Override
    public void onTestFailure(ITestResult result) {
        System.out.printf("[FAIL] ✗ %s — %s%n",
            result.getName(),
            result.getThrowable() != null ? result.getThrowable().getMessage() : "sin mensaje");
    }

    @Override
    public void onTestSkipped(ITestResult result) {
        System.out.printf("[SKIP] - %s%n", result.getName());
    }

    private double elapsed(ITestResult r) {
        return (r.getEndMillis() - r.getStartMillis()) / 1000.0;
    }
}
