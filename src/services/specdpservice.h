#ifndef SPECDPSERVICE_H
#define SPECDPSERVICE_H

#include "basedpservice.h"
#include <vector>

/**
 * @brief Signal implementation for Spectrum data (vector of vector of doubles)
 */
class SpectrumSignal : public Signal<std::vector<double>>
{
private:
    std::vector<std::vector<double>>* internalData;
    const std::vector<std::vector<double>>* externalData;
    bool isExternal;
    int dataSize;

public:
    // Constructor for wrapping existing data (read-only access intended for DP input)
    SpectrumSignal(const std::vector<std::vector<double>>* data);

    // Constructor for owning data (for DP output/results)
    SpectrumSignal(int size);

    virtual ~SpectrumSignal();

    Signal<std::vector<double>>* makeSignal(int size) override;
    void freeSignal() override;
    int size() override;
    std::vector<double> valueAt(int index) override;
    void setValueAt(std::vector<double> value, int index) override;

    // Helper to get the underlying data
    const std::vector<std::vector<double>>& getData() const;
};

/**
 * @brief Service for applying DP algorithm to Spectrum data
 */
class SpecDPService : public BaseDPService<std::vector<double>>
{
public:
    SpecDPService(const std::vector<std::vector<double>>& patternData, 
                  const std::vector<std::vector<double>>& signalData, 
                  int globalLimit, 
                  double localLimit);

    // Helper to get the result as a standard vector structure
    std::vector<std::vector<double>> getScaledSpectrum();
    virtual void log(const std::string&);

protected:
    double calculateError(int value1Pos, int value2Pos) override;
};

#endif // SPECDPSERVICE_H
