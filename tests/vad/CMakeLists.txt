cmake_minimum_required(VERSION 3.16)
project(vad_regression LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)
find_package(Qt6 REQUIRED COMPONENTS Core)
enable_testing()
add_executable(vad_regression vad_regression.cpp
    ../../src/services/vadautocorrelationservice.cpp
    ../../src/services/vadautocorrelationservice.h)
target_link_libraries(vad_regression PRIVATE Qt6::Core)
add_test(NAME vad_regression COMMAND vad_regression)
