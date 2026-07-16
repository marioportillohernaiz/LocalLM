#include "backend_launcher.h"

#define WIN32_LEAN_AND_MEAN
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <shlobj.h>

#include <string>

#pragma comment(lib, "ws2_32.lib")

namespace {

PROCESS_INFORMATION g_backend_process = {};
bool g_backend_started_by_us = false;

std::wstring GetExecutableDirectory() {
  wchar_t path[MAX_PATH];
  DWORD length = GetModuleFileNameW(nullptr, path, MAX_PATH);
  if (length == 0 || length == MAX_PATH) {
    return L"";
  }
  std::wstring full_path(path, length);
  size_t last_slash = full_path.find_last_of(L"\\/");
  if (last_slash == std::wstring::npos) {
    return L"";
  }
  return full_path.substr(0, last_slash);
}

bool IsBackendReachable() {
  WSADATA wsa_data;
  if (WSAStartup(MAKEWORD(2, 2), &wsa_data) != 0) {
    return false;
  }

  SOCKET sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if (sock == INVALID_SOCKET) {
    WSACleanup();
    return false;
  }

  // Non-blocking connect with a short timeout so we don't stall app startup.
  u_long mode = 1;
  ioctlsocket(sock, FIONBIO, &mode);

  sockaddr_in addr = {};
  addr.sin_family = AF_INET;
  addr.sin_port = htons(8000);
  inet_pton(AF_INET, "127.0.0.1", &addr.sin_addr);

  bool reachable = false;
  connect(sock, reinterpret_cast<sockaddr*>(&addr), sizeof(addr));

  fd_set write_set;
  FD_ZERO(&write_set);
  FD_SET(sock, &write_set);
  timeval timeout = {1, 500000};  // 1.5s

  if (select(0, nullptr, &write_set, nullptr, &timeout) > 0) {
    int error = 0;
    int error_len = sizeof(error);
    if (getsockopt(sock, SOL_SOCKET, SO_ERROR,
                    reinterpret_cast<char*>(&error), &error_len) == 0) {
      reachable = (error == 0);
    }
  }

  closesocket(sock);
  WSACleanup();
  return reachable;
}

std::wstring EnsureDataDirectory() {
  wchar_t* local_app_data = nullptr;
  if (FAILED(SHGetKnownFolderPath(FOLDERID_LocalAppData, 0, nullptr,
                                   &local_app_data))) {
    return L"";
  }
  std::wstring data_dir = std::wstring(local_app_data) + L"\\LocalLM\\data";
  CoTaskMemFree(local_app_data);

  SHCreateDirectoryExW(nullptr, data_dir.c_str(), nullptr);
  return data_dir;
}

}  // namespace

void StartBackendIfNeeded() {
  if (IsBackendReachable()) {
    return;
  }

  std::wstring exe_dir = GetExecutableDirectory();
  if (exe_dir.empty()) {
    return;
  }

  std::wstring backend_exe = exe_dir + L"\\backend\\locallm-backend.exe";
  if (GetFileAttributesW(backend_exe.c_str()) == INVALID_FILE_ATTRIBUTES) {
    return;
  }

  std::wstring data_dir = EnsureDataDirectory();
  if (!data_dir.empty()) {
    SetEnvironmentVariableW(L"LOCALLM_DATA_DIR", data_dir.c_str());
  }

  std::wstring command_line = L"\"" + backend_exe + L"\"";

  STARTUPINFOW startup_info = {sizeof(STARTUPINFOW)};
  PROCESS_INFORMATION process_info = {};

  BOOL created = CreateProcessW(
      backend_exe.c_str(), command_line.data(), nullptr, nullptr, FALSE,
      CREATE_NO_WINDOW, nullptr, exe_dir.c_str(), &startup_info,
      &process_info);

  if (created) {
    g_backend_process = process_info;
    g_backend_started_by_us = true;
  }
}

void StopBackendIfStarted() {
  if (g_backend_started_by_us && g_backend_process.hProcess != nullptr) {
    TerminateProcess(g_backend_process.hProcess, 0);
    CloseHandle(g_backend_process.hProcess);
    CloseHandle(g_backend_process.hThread);
    g_backend_started_by_us = false;
  }
}
