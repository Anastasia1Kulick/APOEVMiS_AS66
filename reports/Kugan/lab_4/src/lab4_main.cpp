#include <windows.h>
#include <cstdio>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>

#ifndef _M_IX86
#error Choose Win32 platform.
#endif
extern "C" int CalculateInteger(int x, int y, double* result);
extern "C" int CalculateReal(double x, double y, double* result);

static void OpenConsoleIfNeeded() {
 DWORD type = GetFileType(GetStdHandle(STD_INPUT_HANDLE));
 HWND window = GetConsoleWindow();
 if (type != FILE_TYPE_PIPE && type != FILE_TYPE_DISK && (!window || !IsWindowVisible(window))) {
  FreeConsole();
  AllocConsole();
  FILE* stream;
  freopen_s(&stream, "CONIN$", "r", stdin);
  freopen_s(&stream, "CONOUT$", "w", stdout);
  freopen_s(&stream, "CONOUT$", "w", stderr);
 }
}
template<class T> bool ReadValue(const std::string& line, T& value) {
 std::istringstream input(line);
 if (!(input >> value)) return false; input >> std::ws; return input.eof();
}
static int Run() {
 std::cout << "========================================================\n"
              " Lab 4, variant 9. Kugan N. L., AS-66\n"
              " x87: integer and real operands\n"
              "========================================================\n"
              "1 - integer operands; 2 - real operands\nMode: " << std::flush;
 std::string line; int mode;
 if (!std::getline(std::cin,line) || !ReadValue(line,mode) || (mode != 1 && mode != 2)) {
  std::cout << "Error: choose mode 1 or 2.\n"; return 1;
 }
 std::cout << "Enter x and y separated by a space (absolute value <= 1000000):\n> " << std::flush;
 if (!std::getline(std::cin,line)) { std::cout << "Error: no input.\n"; return 1; }
 std::istringstream input(line); double result = 0; int branch; double dx,dy;
 if (mode == 1) {
  int x,y;
  if (!(input >> x >> y) || !(input >> std::ws).eof() || std::abs(double(x)) > 1000000 || std::abs(double(y)) > 1000000) {
   std::cout << "Error: enter two integers in range [-1000000, 1000000].\n"; return 1;
  }
  dx=x;dy=y;branch=CalculateInteger(x,y,&result);
 } else {
  if (!(input >> dx >> dy) || !(input >> std::ws).eof() || !std::isfinite(dx) || !std::isfinite(dy) || std::abs(dx)>1000000 || std::abs(dy)>1000000) {
   std::cout << "Error: enter two finite numbers in range [-1000000, 1000000].\n"; return 1;
  }
  branch=CalculateReal(dx,dy,&result);
 }
 std::cout << std::setprecision(12) << "x = " << dx << "; y = " << dy << "; x - y = " << dx-dy << '\n';
 const char* rules[] = {"", "x-y > 15: (x*x + 2*y)/(x*x + y*y + 1)", "x-y < -5: (y*y - x)/(x*x + y*y - 1)", "-5 <= x-y <= 15: x*x + 2*y*y + 4"};
 std::cout << "Branch " << branch << ": " << rules[branch] << '\n'
           << std::fixed << std::setprecision(10) << "Result: " << result << '\n';
 return 0;
}
int main() {
 OpenConsoleIfNeeded();
 int status=Run();
 std::cout << "\nPress Enter to close this window." << std::endl;
 std::string line; std::getline(std::cin,line);
 return status;
}

