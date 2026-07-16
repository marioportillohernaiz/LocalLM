#ifndef RUNNER_BACKEND_LAUNCHER_H_
#define RUNNER_BACKEND_LAUNCHER_H_

// Starts the bundled LocalLM backend if it is not already reachable on
// 127.0.0.1:8000. Safe to call even if the backend executable is missing
// (e.g. when running via `flutter run` from source) -- it silently no-ops.
void StartBackendIfNeeded();

// Terminates the backend process if this instance started it.
void StopBackendIfStarted();

#endif  // RUNNER_BACKEND_LAUNCHER_H_
