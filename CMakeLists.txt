cmake_minimum_required(VERSION 3.16)

project(inton-trainer-2 VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.8 REQUIRED COMPONENTS Quick Multimedia)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appinton-trainer-2
    main.cpp
    src/api/audioapi.h
    src/api/audioapi.cpp
    src/api/fileapi.h
    src/api/fileapi.cpp
    src/services/wavfileservice.cpp
)

target_include_directories(appinton-trainer-2 PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR}/src/api
    ${CMAKE_CURRENT_SOURCE_DIR}/src/services
)

qt_add_qml_module(appinton-trainer-2
    URI inton-trainer-2
    VERSION 1.0
    QML_FILES
        ui/Main.qml
        ui/pages/RecordingPage.qml
        ui/pages/HomePage.qml
        ui/pages/RecordsPage.qml
        ui/pages/TemplatesPage.qml
        ui/components/cards/Card.qml
        ui/components/FileTreeView.qml
        ui/components/PlayButton.qml
    RESOURCES
        res/icons/menu.svg
        res/icons/microphone_off.svg
        res/icons/microphone_on.svg
        res/icons/play.svg
        res/icons/stop.svg
        res/icons/home.svg
)

set_target_properties(appinton-trainer-2 PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appinton-trainer-2
    PRIVATE Qt6::Quick Qt6::Multimedia
)

include(GNUInstallDirs)
install(TARGETS appinton-trainer-2
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
