cmake_minimum_required(VERSION 3.16)

project(inton-trainer-2 VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.8 REQUIRED COMPONENTS Quick Multimedia LinguistTools)

qt_standard_project_setup(REQUIRES 6.8 I18N_TRANSLATED_LANGUAGES en ru)

qt_add_executable(appinton-trainer-2
    main.cpp
    src/api/audioapi.h
    src/api/audioapi.cpp
    src/api/fileapi.h
    src/api/fileapi.cpp
    src/api/wavfileapi.h
    src/api/wavfileapi.cpp
    src/api/analysisapi.h
    src/api/analysisapi.cpp
    src/api/settingsapi.h
    src/api/settingsapi.cpp
    src/api/qmllogger.h
    src/api/qmllogger.cpp
    src/api/helpers/settings.h
    src/api/helpers/settings.cpp
    src/services/wavfileservice.h
    src/services/wavfileservice.cpp
    src/services/pitchservice.h
    src/services/pitchservice.cpp
    src/services/specservice.h
    src/services/specservice.cpp
    src/services/amplitudeservice.h
    src/services/amplitudeservice.cpp
    src/services/umpservice.h
    src/services/umpservice.cpp
    src/services/dpservice.h
    src/services/dpservice.cpp
    src/services/cdtwservice.h
    src/services/cdtwservice.cpp
    src/services/helpers/wavFile.h
    src/services/helpers/wavFile.cpp
    src/services/helpers/vectorutils.h
    src/services/helpers/vectorutils.cpp
    src/services/helpers/vectorutils_normalization.cpp
    src/services/helpers/vectorutils_interpolation.cpp
    src/services/helpers/vectorutils_smoothing.cpp
    src/services/helpers/fileLogger.h
)

target_include_directories(appinton-trainer-2 PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR}/src/api
    ${CMAKE_CURRENT_SOURCE_DIR}/src/services
    ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/alglib-cpp/src
)

target_sources(appinton-trainer-2 PRIVATE
    3rdparty/alglib-cpp/src/alglibinternal.cpp
    3rdparty/alglib-cpp/src/alglibmisc.cpp
    3rdparty/alglib-cpp/src/ap.cpp
    3rdparty/alglib-cpp/src/dataanalysis.cpp
    3rdparty/alglib-cpp/src/diffequations.cpp
    3rdparty/alglib-cpp/src/fasttransforms.cpp
    3rdparty/alglib-cpp/src/integration.cpp
    3rdparty/alglib-cpp/src/interpolation.cpp
    3rdparty/alglib-cpp/src/kernels_avx2.cpp
    3rdparty/alglib-cpp/src/kernels_fma.cpp
    3rdparty/alglib-cpp/src/kernels_sse2.cpp
    3rdparty/alglib-cpp/src/linalg.cpp
    3rdparty/alglib-cpp/src/minlp.cpp
    3rdparty/alglib-cpp/src/optimization.cpp
    3rdparty/alglib-cpp/src/solvers.cpp
    3rdparty/alglib-cpp/src/specialfunctions.cpp
    3rdparty/alglib-cpp/src/statistics.cpp
)

set(SPTK_BUILD_COMMANDS OFF CACHE BOOL "Build SPTK commands" FORCE)
add_subdirectory(3rdparty/SPTK)

set(qml_singletons
    ui/utils/AppScale.qml
    ui/utils/Icons.qml
    ui/utils/Logger.qml
    ui/utils/Theme.qml
)

set_source_files_properties(${qml_singletons}
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(appinton-trainer-2
    URI inton-trainer-2
    VERSION 1.0
    QML_FILES
        ui/Main.qml
        ui/pages/RecordingPage.qml
        ui/pages/HomePage.qml
        ui/pages/CategoriesPage.qml
        ui/pages/RecordsPage.qml
        ui/pages/TemplatesPage.qml
        ui/pages/TemplatePage.qml
        ui/pages/TrainingPage.qml
        ui/pages/SettingsPage.qml
        ui/components/cards/Card.qml
        ui/components/GraphCard.qml
        ui/components/FileTreeView.qml
        ui/components/FileTreeViewItem.qml
        ui/components/ListItem.qml
        ui/components/PlayButton.qml
        ui/components/PlayRoundButton.qml
        ui/components/RecordRoundButton.qml
        ui/components/CustomButton.qml
        ui/components/DeleteButton.qml
        ui/components/WaveFormGraph.qml
        ui/components/Spectrogram2DGraph.qml
        ui/components/CircularProgress.qml
        ui/components/StatBox.qml
        ui/components/StartTrainingButton.qml
        ui/components/SearchBar.qml
        ${qml_singletons}
    RESOURCES
        res/fonts/fa-brands-400.ttf
        res/fonts/fa-regular-400.ttf
        res/fonts/fa-solid-900.ttf
)

qt_add_translations(appinton-trainer-2
    TS_FILES
        i18n/inton-trainer-2_en.ts
        i18n/inton-trainer-2_ru.ts
    QM_FILES_OUTPUT_VARIABLE
        qm_files
)

set_target_properties(appinton-trainer-2 PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appinton-trainer-2
    PRIVATE Qt6::Quick Qt6::Multimedia sptk
)

include(GNUInstallDirs)
install(TARGETS appinton-trainer-2
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
