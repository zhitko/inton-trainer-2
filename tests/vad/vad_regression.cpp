#include "../../src/services/vadautocorrelationservice.h"
#include <QCoreApplication>
#include <algorithm>
#include <cmath>
#include <iostream>
#include <stdexcept>

static void require(bool condition, const char* message)
{
    if (!condition)
        throw std::runtime_error(message);
}

static std::vector<double> process(const std::vector<qint16>& samples, int chunk,
                                   std::vector<double>& energies)
{
    VADAutocorrelationService vad;
    vad.setEnergyThreshold(0.0);
    std::vector<double> result;
    for (size_t offset = 0; offset < samples.size(); offset += chunk) {
        auto values = vad.processAudioSamples(samples.data() + offset,
            std::min<size_t>(chunk, samples.size() - offset));
        result.insert(result.end(), values.begin(), values.end());
    }
    energies = vad.getFrameEnergies();
    return result;
}

int main(int argc, char** argv)
{
    QCoreApplication app(argc, argv);
    try {
        // Silence, voiced tone, silence: transitions expose future-frame leakage.
        std::vector<qint16> samples(8000, 0);
        for (size_t i = 2000; i < 6000; ++i)
            samples[i] = static_cast<qint16>(4000 * std::sin(2 * 3.141592653589793 * 180 * i / 8000));
        std::vector<double> energies;
        const auto baseline = process(samples, 8000, energies);
        for (int chunk : {31, 64, 127, 256, 1024}) {
            std::vector<double> chunkEnergies;
            require(process(samples, chunk, chunkEnergies) == baseline,
                    "Detection changes with microphone chunk size");
            require(chunkEnergies == energies, "Calibration energy changes with chunk size");
        }
        require(*std::max_element(baseline.begin(), baseline.end()) > 0.3,
                "Voiced tone was not detected");
        require(baseline.front() == 0 && baseline.back() == 0,
                "Silence must remain finite and zero even with the calibration gate disabled");

        // Verify calibration exposes exactly the live 128-sample Hamming energy.
        double expected = 0;
        for (int i = 0; i < 128; ++i) {
            const double w = 0.54 - 0.46 * std::cos(2 * 3.141592653589793 * i / 127);
            const double value = samples[2048 + i] / 32768.0 * w;
            expected += value * value;
        }
        require(std::abs(energies[32] - expected) < 1e-12, "Calibration/live energy mismatch");
        VADAutocorrelationService gated;
        gated.setEnergyThreshold(*std::max_element(energies.begin(), energies.end()) * 2);
        const auto rejected = gated.processAudioSamples(samples.data(), samples.size());
        require(std::all_of(rejected.begin(), rejected.end(), [](double v) { return v == 0; }),
                "Energy gate failed to reject below-threshold input");
        gated.reset();
        require(gated.getFrameEnergies().empty(), "Reset retained calibration frames");
        std::cout << "VAD regression checks passed\n";
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
