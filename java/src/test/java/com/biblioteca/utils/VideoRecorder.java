package com.biblioteca.utils;

import com.biblioteca.config.Config;
import org.openqa.selenium.*;

import javax.imageio.ImageIO;
import javax.imageio.stream.FileImageOutputStream;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.*;
import java.nio.file.*;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.List;
import java.util.concurrent.*;

/**
 * VideoRecorder - Captura pantallas a intervalos regulares y las combina
 * en un GIF animado al finalizar el test. No requiere ffmpeg.
 *
 * Uso:
 *   VideoRecorder rec = new VideoRecorder(driver, "TC-AUTH-001");
 *   rec.start();
 *   // ... acciones del test ...
 *   rec.stop();   // guarda target/videos/TC-AUTH-001_<timestamp>.gif
 */
public class VideoRecorder {

    private final WebDriver driver;
    private final String testName;
    private final List<BufferedImage> frames = new ArrayList<>();
    private ScheduledExecutorService scheduler;
    private volatile boolean recording = false;

    /** Intervalo entre capturas en milisegundos (500ms = 2 fps aprox). */
    private static final int INTERVAL_MS = 500;

    public VideoRecorder(WebDriver driver, String testName) {
        this.driver   = driver;
        this.testName = sanitize(testName);
    }

    public void start() {
        frames.clear();
        recording = true;
        scheduler = Executors.newSingleThreadScheduledExecutor();
        scheduler.scheduleAtFixedRate(() -> {
            if (!recording) return;
            try {
                byte[] raw = ((TakesScreenshot) driver).getScreenshotAs(OutputType.BYTES);
                BufferedImage img = ImageIO.read(new ByteArrayInputStream(raw));
                if (img != null) synchronized (frames) { frames.add(img); }
            } catch (Exception ignored) {}
        }, 0, INTERVAL_MS, TimeUnit.MILLISECONDS);
    }

    public void stop() {
        recording = false;
        if (scheduler != null) {
            scheduler.shutdown();
            try { scheduler.awaitTermination(3, TimeUnit.SECONDS); }
            catch (InterruptedException ignored) {}
        }
        saveGif();
    }

    private void saveGif() {
        if (frames.isEmpty()) return;
        try {
            Files.createDirectories(Paths.get(Config.VIDEOS));
            String ts  = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
            File out   = Paths.get(Config.VIDEOS, testName + "_" + ts + ".gif").toFile();
            writeAnimatedGif(frames, out, INTERVAL_MS / 10);
            System.out.printf("[VideoRecorder] GIF guardado (%d frames): %s%n", frames.size(), out.getAbsolutePath());
        } catch (Exception e) {
            System.err.println("[VideoRecorder] Error al guardar GIF: " + e.getMessage());
        }
    }

    /**
     * Escribe un GIF animado usando la API estándar de Java (javax.imageio).
     * Cada frame se muestra delayCs centésimas de segundo.
     */
    private void writeAnimatedGif(List<BufferedImage> images, File output, int delayCs) throws IOException {
        var writer = ImageIO.getImageWritersByFormatName("gif").next();
        try (var fios = new FileImageOutputStream(output)) {
            writer.setOutput(fios);
            writer.prepareWriteSequence(null);
            for (int i = 0; i < images.size(); i++) {
                BufferedImage img = scaleDown(images.get(i), 1280, 800);
                var iwp = writer.getDefaultWriteParam();
                var imageMetadata = writer.getDefaultImageMetadata(
                    new javax.imageio.ImageTypeSpecifier(img), iwp);
                setGifDelay(imageMetadata, delayCs, i == images.size() - 1);
                writer.writeToSequence(new javax.imageio.IIOImage(img, null, imageMetadata), iwp);
            }
            writer.endWriteSequence();
        }
        writer.dispose();
    }

    private void setGifDelay(javax.imageio.metadata.IIOMetadata meta, int delayCs, boolean last)
            throws javax.imageio.metadata.IIOInvalidTreeException {
        String fmt = meta.getNativeMetadataFormatName();
        var root   = (org.w3c.dom.Element) meta.getAsTree(fmt);
        var gce    = (org.w3c.dom.Element) root.getElementsByTagName("GraphicControlExtension").item(0);
        if (gce == null) return;
        gce.setAttribute("delayTime", String.valueOf(delayCs));
        gce.setAttribute("disposalMethod", "restoreToBackgroundColor");
        if (last) {
            var appExt = root.getElementsByTagName("ApplicationExtensions").item(0);
            if (appExt == null) {
                appExt = root.getOwnerDocument().createElement("ApplicationExtensions");
                root.appendChild(appExt);
            }
            var appExtChild = root.getOwnerDocument().createElement("ApplicationExtension");
            ((org.w3c.dom.Element) appExtChild).setAttribute("applicationID",  "NETSCAPE");
            ((org.w3c.dom.Element) appExtChild).setAttribute("authenticationCode","2.0");
            appExtChild.setUserData("value", new byte[]{0x1, 0x0, 0x0}, null);
            appExt.appendChild(appExtChild);
        }
        meta.setFromTree(fmt, root);
    }

    private BufferedImage scaleDown(BufferedImage src, int maxW, int maxH) {
        int w = src.getWidth(), h = src.getHeight();
        if (w <= maxW && h <= maxH) return src;
        double ratio = Math.min((double) maxW / w, (double) maxH / h);
        int nw = (int)(w * ratio), nh = (int)(h * ratio);
        BufferedImage out = new BufferedImage(nw, nh, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = out.createGraphics();
        g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
        g.drawImage(src, 0, 0, nw, nh, null);
        g.dispose();
        return out;
    }

    private static String sanitize(String name) {
        return name.replaceAll("[^a-zA-Z0-9_\\-]", "_");
    }
}
