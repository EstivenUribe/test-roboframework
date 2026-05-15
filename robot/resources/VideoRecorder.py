"""
Screen recorder for Robot Framework — uses XVID/AVI codec (Windows-compatible).

ScreenCapLibrary 1.6.0 uses VP08/webm which OpenCV cannot encode on Windows
(files are created empty, ~1910 B regardless of content). This library replaces
that recording path with XVID/AVI, which works correctly on all platforms.
"""

import os
import threading
import time

import cv2
import numpy as np

try:
    from mss import MSS as _MSS
except ImportError:
    from mss import mss as _MSS  # deprecated fallback, still works


class VideoRecorder:
    """Robot Framework library for recording the screen to AVI video."""

    ROBOT_LIBRARY_SCOPE = "SUITE"

    def __init__(self):
        self._thread = None
        self._recording = False
        self._writer = None
        self._output_path = None

    # ── Public Robot keywords ────────────────────────────────────────────────

    def start_recording(self, path, fps=10, size_percentage=0.75, monitor=1):
        """Start recording the screen.

        Arguments:
        - ``path``: output path without extension; ``.avi`` is appended automatically.
        - ``fps``: frames per second (default 10).
        - ``size_percentage``: resize factor 0.0–1.0 (default 0.75, reduces file size).
        - ``monitor``: 1-based monitor index (default 1).

        Returns the final output path (with ``.avi`` extension).
        """
        if self._recording:
            return self._output_path or ""

        fps = int(fps)
        size_percentage = float(size_percentage)
        monitor = int(monitor)

        output_path = str(path) + ".avi"
        self._output_path = output_path

        out_dir = os.path.dirname(os.path.abspath(output_path))
        os.makedirs(out_dir, exist_ok=True)

        with _MSS() as sct:
            mon = sct.monitors[monitor]
            w = int(mon["width"]  * size_percentage)
            h = int(mon["height"] * size_percentage)

        fourcc = cv2.VideoWriter_fourcc(*"XVID")
        self._writer = cv2.VideoWriter(output_path, fourcc, fps, (w, h))

        if not self._writer.isOpened():
            self._writer = None
            raise RuntimeError(
                f"VideoRecorder: could not open writer for '{output_path}'. "
                "Verify that XVID codec (OpenCV) is available."
            )

        self._recording = True
        self._thread = threading.Thread(
            target=self._record_loop,
            args=(fps, size_percentage, monitor),
            daemon=True,
        )
        self._thread.start()
        return output_path

    def stop_recording(self):
        """Stop the recording and flush the video file.

        Returns the path to the saved ``.avi`` file, or an empty string if
        recording was not active.
        """
        if not self._recording:
            return self._output_path or ""

        self._recording = False

        if self._thread:
            self._thread.join(timeout=10)
            self._thread = None

        if self._writer:
            self._writer.release()
            self._writer = None

        return self._output_path or ""

    # ── Internal capture loop ────────────────────────────────────────────────

    def _record_loop(self, fps, size_percentage, monitor):
        interval = 1.0 / fps

        with _MSS() as sct:
            mon = sct.monitors[monitor]
            w = int(mon["width"]  * size_percentage)
            h = int(mon["height"] * size_percentage)

            while self._recording:
                t0 = time.perf_counter()
                try:
                    shot  = sct.grab(mon)
                    frame = np.frombuffer(shot.bgra, dtype=np.uint8).reshape(
                        shot.height, shot.width, 4
                    )
                    frame = cv2.cvtColor(frame, cv2.COLOR_BGRA2BGR)
                    if (shot.width, shot.height) != (w, h):
                        frame = cv2.resize(frame, (w, h))
                    self._writer.write(frame)
                except Exception:
                    pass

                elapsed = time.perf_counter() - t0
                remaining = interval - elapsed
                if remaining > 0:
                    time.sleep(remaining)
