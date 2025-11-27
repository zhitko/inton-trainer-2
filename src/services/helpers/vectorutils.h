#ifndef VECTORUTILS_H
#define VECTORUTILS_H

#include <vector>

class VectorUtils {
public:
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
};

#endif // VECTORUTILS_H
