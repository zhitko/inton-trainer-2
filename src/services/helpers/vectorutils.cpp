#include "vectorutils.h"
#include "logger.h"
#include "interpolation.h"
#include "linalg.h"       // For Savitzky-Golay matrix math
#include "dataanalysis.h" // For potential fitting tools
#include <algorithm>
#include <cmath>
#include <limits>

std::vector<double> VectorUtils::normalizeFromTo(double from, double to, const std::vector<double>& data) {
    LOG_DEBUG() << "Start: normalizeFromTo - from=" << from << ", to=" << to << ", data.size=" << data.size();
    
    if (data.empty()) {
        LOG_DEBUG() << "Finish: normalizeFromTo - result.size=0 (empty input)";
        return {};
    }

    double minVal = std::numeric_limits<double>::max();
    double maxVal = std::numeric_limits<double>::lowest();

    for (double val : data) {
        if (val < minVal) minVal = val;
        if (val > maxVal) maxVal = val;
    }

    if (std::abs(maxVal - minVal) < std::numeric_limits<double>::epsilon()) {
        // All values are the same, return a vector of 'from'
        return std::vector<double>(data.size(), from);
    }

    std::vector<double> result;
    result.reserve(data.size());

    double range = maxVal - minVal;
    double targetRange = to - from;

    for (double val : data) {
        double normalized = from + ((val - minVal) / range) * targetRange;
        result.push_back(normalized);
    }

    LOG_DEBUG() << "Finish: normalizeFromTo - result.size=" << result.size();
    return result;
}

std::vector<double> VectorUtils::normalizeByMinMax(const std::vector<double>& data, bool skipZeros) {
    LOG_DEBUG() << "Start: normalizeByMinMax - data.size=" << data.size() << ", skipZeros=" << skipZeros;
    
    if (data.empty()) {
        LOG_DEBUG() << "Finish: normalizeByMinMax - result.size=0 (empty input)";
        return {};
    }

    double minVal = std::numeric_limits<double>::max();
    double maxVal = std::numeric_limits<double>::lowest();

    for (double val : data) {
        if (skipZeros && std::abs(val) < std::numeric_limits<double>::epsilon()) {
            // Skip zero values when skipZeros is true
            if (val > maxVal) maxVal = val;
            continue;
        }
        if (val < minVal) minVal = val;
        if (val > maxVal) maxVal = val;
    }

    if (std::abs(maxVal - minVal) < std::numeric_limits<double>::epsilon()) {
        // All values are the same, return a vector of 'from'
        return std::vector<double>(data.size(), 0.0);
    }

    std::vector<double> result;
    result.reserve(data.size());

    for (double val : data) {
        if (skipZeros && std::abs(val) < std::numeric_limits<double>::epsilon()) {
            // Skip zero values when skipZeros is true
            result.push_back(0.0);
            continue;
        }
        double normalized = val - minVal;
        result.push_back(normalized);
    }

    LOG_DEBUG() << "Finish: normalizeByMinMax - result.size=" << result.size();
    return result;
}

std::vector<double> VectorUtils::normalizeTo(double to, const std::vector<double>& data) {
    LOG_DEBUG() << "Start: normalizeTo - to=" << to << ", data.size=" << data.size();
    
    if (data.empty()) {
        LOG_DEBUG() << "Finish: normalizeTo - result.size=0 (empty input)";
        return {};
    }

    double maxVal = std::numeric_limits<double>::lowest();
    for (double val : data) {
        if (val > maxVal) maxVal = val;
    }

    if (std::abs(maxVal) < std::numeric_limits<double>::epsilon()) {
        // Max value is 0, cannot scale. Return 0s.
        return std::vector<double>(data.size(), 0.0);
    }

    std::vector<double> result;
    result.reserve(data.size());

    for (double val : data) {
        result.push_back((val / maxVal) * to);
    }

    LOG_DEBUG() << "Finish: normalizeTo - result.size=" << result.size();
    return result;
}

std::vector<double> VectorUtils::normalizeByMean(const std::vector<double>& data, bool skipZeros) {
    LOG_DEBUG() << "Start: normalizeByMean - data.size=" << data.size() << ", skipZeros=" << skipZeros;
    
    if (data.empty()) {
        LOG_DEBUG() << "Finish: normalizeByMean - result.size=0 (empty input)";
        return {};
    }

    double sum = 0.0;
    int count = 0;
    for (double val : data) {
        if (skipZeros && std::abs(val) < std::numeric_limits<double>::epsilon()) {
            // Skip zero values when skipZeros is true
            continue;
        }
        sum += val;
        count++;
    }
    
    // If all values are zero (or count is 0), mean is 0
    double mean = (count > 0) ? (sum / count) : 0.0;

    std::vector<double> result;
    result.reserve(data.size());

    for (double val : data) {
        if (skipZeros && std::abs(val) < std::numeric_limits<double>::epsilon()) {
            // Skip zero values when skipZeros is true
            result.push_back(0.0);
            continue;
        }
        result.push_back(val - mean);
    }

    LOG_DEBUG() << "Finish: normalizeByMean - result.size=" << result.size();
    return result;
}

std::vector<double> VectorUtils::normalizeByMeanDeviation(const std::vector<double>& data, bool skipZeros) {
    LOG_DEBUG() << "Start: normalizeByMeanDeviation - data.size=" << data.size() << ", skipZeros=" << skipZeros;
    
    if (data.empty()) {
        LOG_DEBUG() << "Finish: normalizeByMeanDeviation - result.size=0 (empty input)";
        return {};
    }

    double sum = 0.0;
    int count = 0;
    for (double val : data) {
        if (skipZeros && std::abs(val) < std::numeric_limits<double>::epsilon()) {
            // Skip zero values when skipZeros is true
            continue;
        }
        sum += val;
        count++;
    }
    
    // If all values are zero (or count is 0), mean is 0
    double mean = (count > 0) ? (sum / count) : 0.0;

    double deviationSum = 0.0;
    for (double val : data) {
        if (skipZeros && std::abs(val) < std::numeric_limits<double>::epsilon()) {
            // Skip zero values when skipZeros is true
            continue;
        }
        deviationSum += std::abs(val - mean);
    }
    
    // Calculate deviation only from non-zero values
    double deviation = (count > 0) ? (deviationSum / count) : 0.0;

    if (std::abs(deviation) < std::numeric_limits<double>::epsilon()) {
        // Deviation is 0 (all values are the same), return 0s
        return std::vector<double>(data.size(), 0.0);
    }

    std::vector<double> result;
    result.reserve(data.size());

    for (double val : data) {
        if (skipZeros && std::abs(val) < std::numeric_limits<double>::epsilon()) {
            // Skip zero values when skipZeros is true
            result.push_back(0.0);
            continue;
        }
        result.push_back((val - mean) / deviation);
    }

    LOG_DEBUG() << "Finish: normalizeByMeanDeviation - result.size=" << result.size();
    return result;
}

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

// --------------------------------------------------------------------------------------
// Smoothing Implementations
// --------------------------------------------------------------------------------------

std::vector<double> VectorUtils::smoothMovingAverage(const std::vector<double>& data, int windowSize) {
    LOG_DEBUG() << "Start: smoothMovingAverage - data.size=" << data.size() << ", windowSize=" << windowSize;

    if (data.empty()) return {};
    if (windowSize <= 1) return data;

    int n = data.size();
    std::vector<double> result;
    result.reserve(n);
    int hw = windowSize / 2;

    for (int i = 0; i < n; ++i) {
        double sum = 0.0;
        int count = 0;
        // Symmetric window around i, clipped to bounds
        int start = std::max(0, i - hw);
        int end = std::min(n - 1, i + hw);
        
        for (int j = start; j <= end; ++j) {
            sum += data[j];
            count++;
        }
        
        if (count > 0) {
            result.push_back(sum / count);
        } else {
            result.push_back(0.0);
        }
    }

    LOG_DEBUG() << "Finish: smoothMovingAverage - result.size=" << result.size();
    return result;
}

std::vector<double> VectorUtils::smoothMedian(const std::vector<double>& data, int windowSize) {
    LOG_DEBUG() << "Start: smoothMedian - data.size=" << data.size() << ", windowSize=" << windowSize;

    if (data.empty()) return {};
    if (windowSize <= 1) return data;

    int n = data.size();
    std::vector<double> result;
    result.reserve(n);
    int hw = windowSize / 2;
    std::vector<double> windowRef;
    windowRef.reserve(windowSize);

    for (int i = 0; i < n; ++i) {
        windowRef.clear();
        int start = std::max(0, i - hw);
        int end = std::min(n - 1, i + hw);

        for (int j = start; j <= end; ++j) {
            windowRef.push_back(data[j]);
        }

        if (windowRef.empty()) {
            result.push_back(0.0);
            continue;
        }

        auto m = windowRef.begin() + windowRef.size() / 2;
        std::nth_element(windowRef.begin(), m, windowRef.end());
        result.push_back(*m);
    }

    LOG_DEBUG() << "Finish: smoothMedian - result.size=" << result.size();
    return result;
}

std::vector<double> VectorUtils::smoothGaussian(const std::vector<double>& data, int windowSize, double sigma) {
    LOG_DEBUG() << "Start: smoothGaussian - data.size=" << data.size() << ", windowSize=" << windowSize << ", sigma=" << sigma;

    if (data.empty()) return {};
    if (windowSize <= 1 || sigma <= 0.0) return data;

    // Ensure windowSize is odd for symmetry
    if (windowSize % 2 == 0) windowSize++;
    int hw = windowSize / 2;

    // Generate kernel
    std::vector<double> kernel(windowSize);
    double sumKernel = 0.0;
    for (int i = 0; i < windowSize; ++i) {
        double x = i - hw;
        double g = std::exp(-(x * x) / (2 * sigma * sigma));
        kernel[i] = g;
        sumKernel += g;
    }
    // Normalize kernel
    for (double& v : kernel) v /= sumKernel;

    int n = data.size();
    std::vector<double> result;
    result.reserve(n);

    for (int i = 0; i < n; ++i) {
        double sum = 0.0;
        double sumWeights = 0.0;
        
        for (int k = 0; k < windowSize; ++k) {
            int idx = i - hw + k;
             // Valid boundary check: use only valid indices. 
             // To handle edges properly with normalized kernel, we only sum weights of valid neighbors and re-normalize.
            if (idx >= 0 && idx < n) {
                sum += data[idx] * kernel[k];
                sumWeights += kernel[k];
            }
        }
        
        if (sumWeights > std::numeric_limits<double>::epsilon()) {
            result.push_back(sum / sumWeights);
        } else {
            result.push_back(data[i]); // Fallback
        }
    }

    LOG_DEBUG() << "Finish: smoothGaussian - result.size=" << result.size();
    return result;
}

namespace {
    // Helper to compute Savitzky-Golay coefficients
    std::vector<double> computeSGCoefficients(int m, int order) {
        LOG_DEBUG() << "computeSGCoefficients: m=" << m << ", order=" << order;
        int windowSize = 2 * m + 1;
        int p = order + 1; 
        LOG_DEBUG() << "computeSGCoefficients: windowSize=" << windowSize << ", p=" << p;

        alglib::real_2d_array x_mat;
        x_mat.setlength(windowSize, p);
        
        for (int i = 0; i < windowSize; ++i) {
            int k = i - m;
            for (int j = 0; j < p; ++j) {
                if (k == 0 && j == 0) x_mat[i][j] = 1.0;
                else x_mat[i][j] = std::pow(k, j);
            }
        }

        alglib::real_2d_array a_t_a; 
        a_t_a.setlength(p, p);
        
        try {
            LOG_DEBUG() << "computeSGCoefficients: calling rmatrixgemm";
            alglib::rmatrixgemm(p, p, windowSize, 1.0, x_mat, 0, 0, 1, x_mat, 0, 0, 0, 0.0, a_t_a, 0, 0);
            LOG_DEBUG() << "computeSGCoefficients: rmatrixgemm finished";
        } catch (alglib::ap_error& e) {
             LOG_CRITICAL() << "Alglib error in rmatrixgemm: " << e.msg.c_str();
             throw;
        } catch (...) {
             LOG_CRITICAL() << "Unknown error in rmatrixgemm";
             throw;
        }

        alglib::ae_int_t info;
        alglib::matinvreport rep;
        
        try {
            LOG_DEBUG() << "computeSGCoefficients: a_t_a rows=" << a_t_a.rows() << ", cols=" << a_t_a.cols();
            LOG_DEBUG() << "computeSGCoefficients: calling spdmatrixinverse";
            // A^T * A is symmetric positive definite (mostly), so spdmatrixinverse is appropriate
            bool isUpper = true;
            alglib::spdmatrixinverse(a_t_a, info, rep);
            LOG_DEBUG() << "computeSGCoefficients: spdmatrixinverse finished, info=" << info;
        } catch (alglib::ap_error& e) {
             LOG_CRITICAL() << "Alglib error in spdmatrixinverse: " << e.msg.c_str();
             throw;
        }

        if (info <= 0) {
            LOG_WARNING() << "computeSGCoefficients: Matrix inversion failed, info=" << info;
            return {};
        }

        std::vector<double> coeffs(windowSize);
        for (int i = 0; i < windowSize; ++i) {
            double val = 0.0;
            // Dot product of R0 and i-th column of A^T (aka i-th row of A)
            for (int j = 0; j < p; ++j) {
                val += a_t_a[0][j] * x_mat[i][j];
            }
            coeffs[i] = val;
        }
        
        return coeffs;
    }
}

std::vector<double> VectorUtils::smoothSavitzkyGolay(const std::vector<double>& data, int windowSize, int polynomialOrder) {
    LOG_DEBUG() << "Start: smoothSavitzkyGolay - data.size=" << data.size() << ", windowSize=" << windowSize << ", order=" << polynomialOrder;

    if (data.empty()) return {};
    if (windowSize <= 1) return data;
    if (windowSize % 2 == 0) windowSize++; // Force odd
    if (windowSize < polynomialOrder + 2) {
         // Window too small for order
         LOG_WARNING() << "smoothSavitzkyGolay: windowSize < order + 2";
         return data; 
    }

    int m = windowSize / 2;
    std::vector<double> coeffs;
    
    try {
        coeffs = computeSGCoefficients(m, polynomialOrder);
    } catch (...) {
        LOG_CRITICAL() << "Alglib error in computeSGCoefficients";
        return data; 
    }

    if (coeffs.empty()) {
        LOG_WARNING() << "Failed to compute SG coefficients";
        return data;
    }

    int n = data.size();
    std::vector<double> result;
    result.reserve(n);

    for (int i = 0; i < n; ++i) {
        // For edges, we can't apply full window. 
        // Simple strategy: copy original data at edges, or reduce order/window?
        // Standard SG preserves data length but edge handling varies.
        // We will just copy original values if window doesn't fit.
        if (i < m || i >= n - m) {
            result.push_back(data[i]);
        } else {
            double sum = 0.0;
            for (int k = 0; k < windowSize; ++k) {
                sum += data[i - m + k] * coeffs[k];
            }
            result.push_back(sum);
        }
    }

    LOG_DEBUG() << "Finish: smoothSavitzkyGolay - result.size=" << result.size();
    return result;
}

std::vector<double> VectorUtils::smoothSpline(const std::vector<double>& data, double penalty) {
    LOG_DEBUG() << "Start: smoothSpline - data.size=" << data.size() << ", penalty=" << penalty;

    // Use Alglib's spline1dfitpenalized
    if (data.empty()) return {};
    
    SplineData sd = prepareSplineVectors(data);
    if (sd.xVec.size() < 2) return data;

    alglib::real_1d_array x, y;
    x.setcontent(sd.xVec.size(), sd.xVec.data());
    y.setcontent(sd.yVec.size(), sd.yVec.data());
    
    // M: number of basis functions. The more, the closer to interpolation.
    // Recommended M is usually N/2 or N (but penalized). 
    // If M is small, it acts as regression. 
    // We'll set M = min(50, N) to allow reasonable flexibility.
    int m = std::min((int)sd.xVec.size(), 50); 
    if (m < 4) m = sd.xVec.size(); // minimum 4 points for cubic spline

    alglib::spline1dinterpolant s;
    alglib::spline1dfitreport rep;
    double rho = penalty; 
    // Note: rho is usually log scale or so. In alglib:
    // Minimize S = E + rho*C (C is curvature).
    // If rho is -ve, it's automatically selected? No, documentation says rho >= 0.
    // If rho is very large -> linear fit. If rho -> 0, natural spline interpolation.
    
    alglib::ae_int_t info;
    try {
        alglib::spline1dfitpenalized(x, y, m, rho, info, s, rep);
    } catch (...) {
        LOG_CRITICAL() << "Alglib error in smoothSpline";
        return data;
    }

    int n = data.size();
    std::vector<double> result;
    result.reserve(n);

    for (int i = 0; i < n; ++i) {
        double t = static_cast<double>(i);
        // Only evaluate if within range of valid points?
        // Spline is defined on [x_min, x_max].
        // Our xVec is subset of indices.
        if (t < sd.firstNonZeroIdx || t > sd.lastNonZeroIdx) {
             // Outside valid data range, keep 0 or original?
             // Since prepareSplineVectors skipped zeros/small values, those were considered 'missing'.
             // We should probably keep them as 0.0 or interpolate?
             // If we smooth, we probably want to fill gaps? 
             // But existing code sets them to 0.0.
             result.push_back(0.0);
        } else {
             // Evaluate spline
             result.push_back(alglib::spline1dcalc(s, t));
        }
    }

    LOG_DEBUG() << "Finish: smoothSpline - result.size=" << result.size();
    return result;
}

std::vector<double> VectorUtils::smooth(const std::string& type, const std::vector<double>& data, double param1, double param2) {
    if (type == "MovingAverage") return smoothMovingAverage(data, static_cast<int>(param1));
    if (type == "Median") return smoothMedian(data, static_cast<int>(param1));
    if (type == "Gaussian") return smoothGaussian(data, static_cast<int>(param1), param2 > 0 ? param2 : 1.0);
    if (type == "SavitzkyGolay") return smoothSavitzkyGolay(data, static_cast<int>(param1), static_cast<int>(param2 > 0 ? param2 : 2));
    if (type == "Spline") return smoothSpline(data, param1);
    
    // Default or unknown
    return smoothMovingAverage(data, static_cast<int>(param1));
}
