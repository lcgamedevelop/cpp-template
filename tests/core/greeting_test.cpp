#include "cpp_template/greeting.hpp"

#include <iostream>
#include <string>
#include <string_view>

namespace
{

bool expect_greeting(std::string_view label, std::string_view name, std::string_view expected)
{
    std::string actual;
    if (cpp_template::greeting(name, actual) && actual == expected)
    {
        return true;
    }

    std::cerr << label << ": expected [" << expected << "], got [" << actual << "]\n";
    return false;
}

bool rejects_empty_name_and_clears_output()
{
    std::string output = "previous result";
    if (cpp_template::greeting({}, output) || !output.empty())
    {
        std::cerr << "empty name: expected failure and empty output\n";
        return false;
    }
    return true;
}

} // namespace

int main()
{
    int failures = 0;
    if (!expect_greeting("normal name", "World", "Hello, World!"))
    {
        ++failures;
    }
    if (!expect_greeting("bounded string view", std::string_view{"Alice_extra", 5},
                         "Hello, Alice!"))
    {
        ++failures;
    }
    if (!expect_greeting("embedded null", std::string_view{"A\0B", 3},
                         std::string{"Hello, A\0B!", 11}))
    {
        ++failures;
    }
    if (!rejects_empty_name_and_clears_output())
    {
        ++failures;
    }

    return failures == 0 ? 0 : 1;
}
