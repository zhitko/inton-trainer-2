#ifndef VECTORUTILS_H
#define VECTORUTILS_H

#include <vector>
#include <string>

class VectorUtils {
public:
    /**
     * @brief Normalizes data so that the minimum value becomes 0 and the maximum value becomes maximum - minimum.
     * @param data Input vector.
     * @param skipZeros If true, zero values are not considered when finding the minimum value.
     * @return Normalized vector.
     */
    static std::vector<double> normalizeByMinMax(const std::vector<double>& data, bool skipZeros = true);
    /**
     * @brief Normalizes data so that the minimum value becomes 'from' and the maximum value becomes 'to'.
     * @param from Target minimum value.
     * @param to Target maximum value.
     * @param data Input vector.
     * @return Normalized vector.
     */
    static std::vector<double> normalizeFromTo(double from, double to, const std::vector<double>& data);

    /**
     * @brief Normalizes data by scaling the maximum value to 'to'.
     * @param to Target maximum value.
     * @param data Input vector.
     * @return Normalized vector.
     */
    static std::vector<double> normalizeTo(double to, const std::vector<double>& data);

    /**
     * @brief Normalizes data by subtracting the mean from each element.
     * @param data Input vector.
     * @param skipZeros If true, zero values are not considered when calculating the mean.
     * @return Normalized vector.
     */
    static std::vector<double> normalizeByMean(const std::vector<double>& data, bool skipZeros = true);

    /**
     * @brief Normalizes data by subtracting the mean and dividing by the mean absolute deviation.
     * @param data Input vector.
     * @param skipZeros If true, zero values are not considered when calculating the mean and deviation.
     * @return Normalized vector.
     */
    static std::vector<double> normalizeByMeanDeviation(const std::vector<double>& data, bool skipZeros = true);

    /**
     * @brief Resamples the input vector to the target length using linear interpolation.
     * @param data Input vector.
     * @param targetLength Target length of the output vector.
     * @return Resampled vector.
     */
    static std::vector<double> linearInterpolation(const std::vector<double>& data, int targetLength);

    /**
     * @brief Resamples the input vector to the target length using Linear spline interpolation (Alglib).
     * @param data Input vector.
     * @param targetLength Target length of the output vector.
     * @return Resampled vector.
     */
    static std::vector<double> interpolationSplineLinear(const std::vector<double>& data, int targetLength);



    /**
     * @brief Resamples the input vector to the target length using Cubic spline interpolation (Alglib).
     * @param data Input vector.
     * @param targetLength Target length of the output vector.
     * @return Resampled vector.
     */
    static std::vector<double> interpolationSplineCubic(const std::vector<double>& data, int targetLength);

    /**
     * @brief Resamples the input vector to the target length using Akima spline interpolation (Alglib).
     * @param data Input vector.
     * @param targetLength Target length of the output vector.
     * @return Resampled vector.
     */
    static std::vector<double> interpolationSplineAkima(const std::vector<double>& data, int targetLength);

    /**
     * @brief Resamples the input vector to the target length using Monotone spline interpolation (Alglib).
     * @param data Input vector.
     * @param targetLength Target length of the output vector.
     * @return Resampled vector.
     */
    static std::vector<double> interpolationSplineMonotone(const std::vector<double>& data, int targetLength);

    /**
     * @brief Dispatches interpolation based on type string.
     * @param type Interpolation type ("Linear", "Hermite", etc.).
     * @param data Input vector.
     * @param targetLength Target length.
     * @return Resampled vector.
     */
    static std::vector<double> interpolate(const std::string& type, const std::vector<double>& data, int targetLength);

    /**
     * @brief Smooths data using a Simple Moving Average.
     * @param data Input vector.
     * @param windowSize Size of the smoothing window (must be odd).
     * @return Smoothed vector.
     */
    static std::vector<double> smoothMovingAverage(const std::vector<double>& data, int windowSize);

    /**
     * @brief Smooths data using a Median filter.
     * @param data Input vector.
     * @param windowSize Size of the smoothing window (must be odd).
     * @return Smoothed vector.
     */
    static std::vector<double> smoothMedian(const std::vector<double>& data, int windowSize);

    /**
     * @brief Smooths data using a Gaussian filter.
     * @param data Input vector.
     * @param windowSize Size of the smoothing window (must be odd).
     * @param sigma Standard deviation of the Gaussian kernel.
     * @return Smoothed vector.
     */
    static std::vector<double> smoothGaussian(const std::vector<double>& data, int windowSize, double sigma);

    /**
     * @brief Smooths data using Alglib's Penalized Spline.
     * @param data Input vector.
     * @param penalty Penalty coefficient (rho). Large rho = smoother (linear-like), Small rho = closer to data.
     * @return Smoothed vector.
     */
    static std::vector<double> smoothSpline(const std::vector<double>& data, double penalty);
    
    /**
     * @brief General dispatch for smoothing.
     * @param type Smoothing type ("MovingAverage", "Median", "Gaussian", "Spline").
     * @param data Input vector.
     * @param param1 Primary parameter (windowSize or penalty).
     * @param param2 Secondary parameter (polynomialOrder or sigma), if applicable.
     * @return Smoothed vector.
     */
    static std::vector<double> smooth(const std::string& type, const std::vector<double>& data, double param1, double param2 = 0.0);
};

#endif // VECTORUTILS_H
