# Intonation Trainer 2

A desktop application for recording, analyzing, and training speech intonation patterns. The application provides real-time pitch visualization, template-based training, and comprehensive audio analysis tools.

## Features

- Audio recording and playback
- Real-time pitch analysis and visualization
- Waveform visualization
- Template-based intonation training
- Multi-language support (English, Russian)
- Audio file management
- Customizable settings

## Requirements

### Build Requirements

- **CMake**: 3.16 or higher
- **Qt**: 6.10 or higher with the following modules:
  - Qt Quick
  - Qt Multimedia
  - Qt Linguist Tools
- **C++ Compiler**: Supporting C++17 or higher
- **Git**: For cloning the repository and submodules

### Runtime Requirements

- Operating System: Windows, Linux, or macOS
- Audio input/output device

## Build Instructions

### Clone the Repository

```bash
git clone <repository-url>
cd inton-trainer-2
```

### Clone 3rd-Party Dependencies

The SPTK (Speech Signal Processing Toolkit) library is required but not included in the repository. Clone it into the `3rdparty` directory:

```bash
git clone https://github.com/sp-nitech/SPTK.git 3rdparty/SPTK
```

The ALGLIB library is required but not included in the repository. Download it into the `3rdparty` directory:

```bash
wget https://www.alglib.net/translator/re/alglib-4.06.0.cpp.gpl.zip
unzip alglib-4.06.0.cpp.gpl.zip -d 3rdparty/alglib-cpp
```

### Build Steps

#### Linux/macOS

```bash
mkdir build
cd build
cmake ..
cmake --build .
```

#### Windows (with MSVC)

```bash
mkdir build
cd build
cmake -G "Visual Studio 17 2022" ..
cmake --build . --config Release
```

### Run the Application

After building, the executable will be located in the build directory:

- **Linux/macOS**: `./appinton-trainer-2`
- **Windows**: `Release\appinton-trainer-2.exe`

## Project Structure

```
inton-trainer-2/
├── src/              # C++ source code
│   ├── api/          # QML API classes
│   └── services/     # Business logic and services
├── ui/               # QML user interface files
│   ├── pages/        # Application pages
│   ├── components/   # Reusable UI components
│   └── utils/        # QML utilities
├── res/              # Resources (fonts, icons)
├── i18n/             # Translation files
├── 3rdparty/         # Third-party libraries
│   ├── SPTK/         # Speech Signal Processing Toolkit 4.3 https://sp-tk.sourceforge.net/
│   └── alglib-cpp/   # ALGLIB library 4.06.0 https://www.alglib.net/
└── CMakeLists.txt    # CMake configuration
```

## Authors

- **Zhitko Vladimir** - Development - [LinkedIn](https://www.linkedin.com/in/zhitko-vladimir-92662255/)
- **Boris Lobanov** - Scientific - [LinkedIn](https://www.linkedin.com/in/boris-lobanov-50628384/)

## License

This project is licensed under the MIT License - see below for details:

```
MIT License

Copyright (c) 2025 Zhitko Vladimir, Boris Lobanov

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Third-Party Libraries

- **SPTK (Speech Signal Processing Toolkit)** - Used for pitch analysis and audio processing
