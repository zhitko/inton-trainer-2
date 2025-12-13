#include "vectorutils.h"
#include "logger.h"
#include "interpolation.h" // Alglib interpolation
#include <algorithm>
#include <cmath>
#include <limits>
#include <vector>

std::vector<double> VectorUtils::linearInterpolation(const std::vector<double>& data, int targetLength) {
    LOG_DEBUG() << "Start: linearInterpolation - data.size=" << data.size() << ", targetLength=" << targetLength;
    
    if (data.empty() || targetLength <= 0) {
        LOG_DEBUG() << "Finish: linearInterpolation - result.size=0 (invalid input)";
        return {};
    }

    if (targetLength == 1) {
        return {data[0]};
    }

    int inputSize = data.size();
    if (inputSize == 1) {
        return std::vector<double>(targetLength, data[0]);
    }

    std::vector<double> result;
    result.reserve(targetLength);

    for (int i = 0; i < targetLength; ++i) {
        double t = static_cast<double>(i) * (inputSize - 1) / (targetLength - 1);
        int idx = static_cast<int>(std::floor(t));
        double frac = t - idx;

        if (idx >= inputSize - 1) {
            // This handles the last point or precision issues
            result.push_back(data[std::min(idx, inputSize - 1)]);
        } else {
            double val = data[idx] * (1.0 - frac) + data[idx + 1] * frac;
            result.push_back(val);
        }
    }

    LOG_DEBUG() << "Finish: linearInterpolation - result.size=" << result.size();
    return result;
}

namespace {
    struct SplineData {
        std::vector<double> xVec;
        std::vector<double> yVec;
        double firstNonZeroIdx = -1.0;
        double lastNonZeroIdx = -1.0;
    };

    SplineData prepareSplineVectors(const std::vector<double>& data) {
        SplineData sd;
        sd.xVec.reserve(data.size());
        sd.yVec.reserve(data.size());

        for (size_t i = 0; i < data.size(); ++i) {
            if (std::abs(data[i]) > std::numeric_limits<double>::epsilon()) {
                if (sd.firstNonZeroIdx < -0.5) sd.firstNonZeroIdx = static_cast<double>(i);
                sd.lastNonZeroIdx = static_cast<double>(i);
                sd.xVec.push_back(static_cast<double>(i));
                sd.yVec.push_back(data[i]);
            }
        }
        return sd;
    }
}

std::vector<double> VectorUtils::interpolationSplineLinear(const std::vector<double>& data, int targetLength) {
    LOG_DEBUG() << "Start: interpolationSplineLinear - data.size=" << data.size() << ", targetLength=" << targetLength;
    
    if (data.empty() || targetLength <= 0) {
        return {};
    }
    if (targetLength == 1) return {data[0]};
    if (data.size() == 1) return std::vector<double>(targetLength, data[0]);

    SplineData sd = prepareSplineVectors(data);

    if (sd.xVec.empty()) return std::vector<double>(targetLength, 0.0);
    if (sd.xVec.size() == 1) {
        return std::vector<double>(targetLength, 0.0);
    }

    alglib::real_1d_array x, y;
    x.setcontent(sd.xVec.size(), sd.xVec.data());
    y.setcontent(sd.yVec.size(), sd.yVec.data());

    alglib::spline1dinterpolant s;
    try {
        alglib::spline1dbuildlinear(x, y, s);
    } catch (...) {
        LOG_CRITICAL() << "Alglib error in interpolationSplineLinear";
        return {};
    }

    std::vector<double> result;
    result.reserve(targetLength);
    double step = static_cast<double>(data.size() - 1) / (targetLength - 1);

    for (int i = 0; i < targetLength; ++i) {
        double t = i * step;
        if (t < sd.firstNonZeroIdx || t > sd.lastNonZeroIdx) {
            result.push_back(0.0);
        } else {
            result.push_back(alglib::spline1dcalc(s, t));
        }
    }

    LOG_DEBUG() << "Finish: interpolationSplineLinear - result.size=" << result.size();
    return result;
}



std::vector<double> VectorUtils::interpolationSplineCubic(const std::vector<double>& data, int targetLength) {
    LOG_DEBUG() << "Start: interpolationSplineCubic - data.size=" << data.size() << ", targetLength=" << targetLength;
    
    if (data.empty() || targetLength <= 0) return {};
    if (targetLength == 1) return {data[0]};
    if (data.size() == 1) return std::vector<double>(targetLength, data[0]);

    SplineData sd = prepareSplineVectors(data);

    if (sd.xVec.empty()) return std::vector<double>(targetLength, 0.0);
    if (sd.xVec.size() == 1) return std::vector<double>(targetLength, 0.0);

    alglib::real_1d_array x, y;
    x.setcontent(sd.xVec.size(), sd.xVec.data());
    y.setcontent(sd.yVec.size(), sd.yVec.data());

    alglib::spline1dinterpolant s;
    try {
        alglib::spline1dbuildcubic(x, y, s);
    } catch (...) {
        LOG_CRITICAL() << "Alglib error in interpolationSplineCubic";
        return {};
    }

    std::vector<double> result;
    result.reserve(targetLength);
    double step = static_cast<double>(data.size() - 1) / (targetLength - 1);

    for (int i = 0; i < targetLength; ++i) {
        double t = i * step;
        if (t < sd.firstNonZeroIdx || t > sd.lastNonZeroIdx) {
            result.push_back(0.0);
        } else {
            result.push_back(alglib::spline1dcalc(s, t));
        }
    }

    LOG_DEBUG() << "Finish: interpolationSplineCubic - result.size=" << result.size();
    return result;
}

std::vector<double> VectorUtils::interpolationSplineAkima(const std::vector<double>& data, int targetLength) {
    LOG_DEBUG() << "Start: interpolationSplineAkima - data.size=" << data.size() << ", targetLength=" << targetLength;
    
    if (data.empty() || targetLength <= 0) return {};
    if (targetLength == 1) return {data[0]};
    if (data.size() == 1) return std::vector<double>(targetLength, data[0]);

    SplineData sd = prepareSplineVectors(data);

    if (sd.xVec.empty()) return std::vector<double>(targetLength, 0.0);
    if (sd.xVec.size() == 1) return std::vector<double>(targetLength, 0.0);

    alglib::real_1d_array x, y;
    x.setcontent(sd.xVec.size(), sd.xVec.data());
    y.setcontent(sd.yVec.size(), sd.yVec.data());

    alglib::spline1dinterpolant s;
    try {
        alglib::spline1dbuildakima(x, y, s);
    } catch (...) {
        LOG_CRITICAL() << "Alglib error in interpolationSplineAkima";
        return {};
    }

    std::vector<double> result;
    result.reserve(targetLength);
    double step = static_cast<double>(data.size() - 1) / (targetLength - 1);

    for (int i = 0; i < targetLength; ++i) {
        double t = i * step;
        if (t < sd.firstNonZeroIdx || t > sd.lastNonZeroIdx) {
            result.push_back(0.0);
        } else {
            result.push_back(alglib::spline1dcalc(s, t));
        }
    }

    LOG_DEBUG() << "Finish: interpolationSplineAkima - result.size=" << result.size();
    return result;
}

std::vector<double> VectorUtils::interpolationSplineMonotone(const std::vector<double>& data, int targetLength) {
    LOG_DEBUG() << "Start: interpolationSplineMonotone - data.size=" << data.size() << ", targetLength=" << targetLength;
    
    if (data.empty() || targetLength <= 0) return {};
    if (targetLength == 1) return {data[0]};
    if (data.size() == 1) return std::vector<double>(targetLength, data[0]);

    SplineData sd = prepareSplineVectors(data);

    if (sd.xVec.empty()) return std::vector<double>(targetLength, 0.0);
    if (sd.xVec.size() == 1) return std::vector<double>(targetLength, 0.0);

    alglib::real_1d_array x, y;
    x.setcontent(sd.xVec.size(), sd.xVec.data());
    y.setcontent(sd.yVec.size(), sd.yVec.data());

    alglib::spline1dinterpolant s;
    try {
        alglib::spline1dbuildmonotone(x, y, s);
    } catch (...) {
        LOG_CRITICAL() << "Alglib error in interpolationSplineMonotone";
        return {};
    }

    std::vector<double> result;
    result.reserve(targetLength);
    double step = static_cast<double>(data.size() - 1) / (targetLength - 1);

    for (int i = 0; i < targetLength; ++i) {
        double t = i * step;
        if (t < sd.firstNonZeroIdx || t > sd.lastNonZeroIdx) {
            result.push_back(0.0);
        } else {
            result.push_back(alglib::spline1dcalc(s, t));
        }
    }

    LOG_DEBUG() << "Finish: interpolationSplineMonotone - result.size=" << result.size();
    return result;
}

std::vector<double> VectorUtils::interpolate(const std::string& type, const std::vector<double>& data, int targetLength) {
    if (type == "None") {
        if (static_cast<int>(data.size()) == targetLength) {
            return data;
        }
        // Fallback to Linear for resizing if "None" is selected but resizing is needed.
        return interpolationSplineLinear(data, targetLength);
    }
    
    if (type == "Linear") return interpolationSplineLinear(data, targetLength);
    if (type == "Cubic") return interpolationSplineCubic(data, targetLength);
    if (type == "Akima") return interpolationSplineAkima(data, targetLength);
    if (type == "Monotone") return interpolationSplineMonotone(data, targetLength);
    
    // Default fallback
    return interpolationSplineLinear(data, targetLength);
}
