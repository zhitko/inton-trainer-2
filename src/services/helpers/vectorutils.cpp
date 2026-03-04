#include "vectorutils.h"
#include "logger.h"
#include <algorithm>
#include <cmath>

double VectorUtils::pearsonCorrelation(const std::vector<double>& vec1,
    const std::vector<double>& vec2)
{
    LOG_DEBUG() << "Start: pearsonCorrelation - vec1.size=" << vec1.size()
                << ", vec2.size=" << vec2.size();

    // Validate inputs
    if (vec1.empty() || vec2.empty() || vec1.size() != vec2.size()) {
        LOG_WARNING() << "pearsonCorrelation: Invalid input - vec1 size="
                      << vec1.size() << ", vec2 size=" << vec2.size();
        return 0.0;
    }

    size_t n = vec1.size();

    // Calculate means
    double mean1 = 0.0, mean2 = 0.0;
    for (size_t i = 0; i < n; ++i) {
        mean1 += vec1[i];
        mean2 += vec2[i];
    }
    mean1 /= n;
    mean2 /= n;

    // Calculate covariance and variances
    double covariance = 0.0;
    double variance1 = 0.0;
    double variance2 = 0.0;

    for (size_t i = 0; i < n; ++i) {
        double dev1 = vec1[i] - mean1;
        double dev2 = vec2[i] - mean2;

        covariance += dev1 * dev2;
        variance1 += dev1 * dev1;
        variance2 += dev2 * dev2;
    }

    // Calculate Pearson correlation coefficient
    double correlation = 0.0;
    if (variance1 > 0 && variance2 > 0) {
        correlation = covariance / std::sqrt(variance1 * variance2);
    }

    // Clamp correlation to [-1, 1] (floating point errors can exceed bounds)
    correlation = std::max(-1.0, std::min(1.0, correlation));

    LOG_DEBUG() << "Finish: pearsonCorrelation - correlation=" << correlation;

    return correlation;
}
