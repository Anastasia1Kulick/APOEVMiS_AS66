#include <iostream>
#include <string>
#include <chrono>

using namespace std;
using namespace chrono;
string asmFunction(const string& a)
{
    string result = a;

    const size_t len = result.size();
    char* str = result.data();
    size_t i = 0;

    while (i < len)
    {
        asm volatile(
            "movb $43, (%[str], %[i], 1)\n\t"
            :
        : [str] "r" (str),
            [i]   "r" (i)
            : "memory"
            );

        i += 2;
    }

    return result;
}
string cppFunction(const string& a)
{
    string result = a;

    for (size_t i = 0; i < result.size(); i += 2)
    {
        result[i] = '+';
    }

    return result;
}

int main()
{
    string a = "ABCDEF";
    string resultCpp = cppFunction(a);
    string resultAsm = asmFunction(a);

    cout << "Original string: " << a << endl;

    cout << "\nC++ result:  " << resultCpp << endl;
    cout << "ASM result:  " << resultAsm << endl;

    if (resultCpp == resultAsm)
        cout << "Results are identical." << endl;
    else
        cout << "ERROR: results are different!" << endl;

    const int N = 1000000;

    string temp;
    temp = cppFunction(a);
    temp = asmFunction(a);
    auto startCpp = high_resolution_clock::now();

    for (int i = 0; i < N; ++i)
    {
        temp = cppFunction(a);
    }

    auto finishCpp = high_resolution_clock::now();

    auto timeCpp =
        duration_cast<nanoseconds>(finishCpp - startCpp).count();
    auto startAsm = high_resolution_clock::now();

    for (int i = 0; i < N; ++i)
    {
        temp = asmFunction(a);
    }

    auto finishAsm = high_resolution_clock::now();

    auto timeAsm =
        duration_cast<nanoseconds>(finishAsm - startAsm).count();
    cout << "\nNumber of calls: " << N << endl;

    cout << "\nC++ total time:  "
        << timeCpp << " ns" << endl;

    cout << "C++ average:     "
        << static_cast<double>(timeCpp) / N
        << " ns" << endl;

    cout << "\nASM total time:  "
        << timeAsm << " ns" << endl;

    cout << "ASM average:     "
        << static_cast<double>(timeAsm) / N
        << " ns" << endl;
    if (timeAsm < timeCpp)
    {
        double percent =
            100.0 * (1.0 - static_cast<double>(timeAsm) / timeCpp);

        cout << "\nASM is faster by approximately "
            << percent << "%." << endl;
    }
    else if (timeCpp < timeAsm)
    {
        double percent =
            100.0 * (1.0 - static_cast<double>(timeCpp) / timeAsm);

        cout << "\nC++ is faster by approximately "
            << percent << "%." << endl;
    }
    else
    {
        cout << "\nExecution times are approximately equal." << endl;
    }

    return 0;
}