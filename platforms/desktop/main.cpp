#include "cpp_template/greeting.hpp"

#include <iostream>
#include <string>
#include <string_view>

int main(int argc, char* argv[])
{
    if (argc > 2)
    {
        std::cerr << "Usage: cpp_template_app [name]\n";
        return 2;
    }

    const std::string_view name = argc == 2 ? std::string_view{argv[1]} : "World";
    std::string message;
    if (!cpp_template::greeting(name, message))
    {
        std::cerr << "Error: name must not be empty\n";
        return 1;
    }
    std::cout << message << '\n';
    return 0;
}
