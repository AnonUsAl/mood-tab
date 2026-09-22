#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);

  // Default window size in logical pixels. The UI is designed for a
  // portrait phone layout; on desktop the app is centered inside a
  // 480pt-wide canvas, so a taller window gives that canvas room.
  //
  // The size is then clamped to the primary monitor's work area: on a
  // high-DPI small screen a 1280x720 logical window gets scaled up larger
  // than the screen itself, which clips the bottom of the UI behind the
  // taskbar.
  unsigned int window_width = 1100;
  unsigned int window_height = 820;

  RECT work_area{};
  if (::SystemParametersInfo(SPI_GETWORKAREA, 0, &work_area, 0)) {
    HDC screen_dc = ::GetDC(nullptr);
    const int dpi = screen_dc ? ::GetDeviceCaps(screen_dc, LOGPIXELSX) : 96;
    if (screen_dc) {
      ::ReleaseDC(nullptr, screen_dc);
    }
    const double dpi_scale = dpi / 96.0;
    const auto available_width =
        static_cast<unsigned int>((work_area.right - work_area.left) / dpi_scale);
    const auto available_height =
        static_cast<unsigned int>((work_area.bottom - work_area.top) / dpi_scale);

    if (window_width > available_width) {
      window_width = available_width;
    }
    if (window_height > available_height) {
      window_height = available_height;
    }
  }

  Win32Window::Size size(window_width, window_height);
  if (!window.Create(L"mood_tab", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
