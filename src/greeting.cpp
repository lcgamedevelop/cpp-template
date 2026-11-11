#include "cpp_template/greeting.hpp"

#include <fmt/format.h>

namespace cpp_template
{

bool greeting(std::string_view name, std::string& output)
{
    if (name.empty())
    {
        output.clear();
        return false;
    }

    output = fmt::format("Hello, {}!", name);
    return true;
}

} // namespace cpp_template
