#include "vectorutils.h"
#include "logger.h"
#include "interpolation.h"
#include "linalg.h"
#include "dataanalysis.h"
#include <algorithm>
#include <cmath>
#include <limits>
#include <vector>

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
