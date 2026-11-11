#pragma once

#include <string>
#include <string_view>

namespace cpp_template
{

// Returns false and clears output when name is empty.
[[nodiscard]] bool greeting(std::string_view name, std::string& output);

} // namespace cpp_template
