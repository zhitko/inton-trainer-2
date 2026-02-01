#include "specdpservice.h"
#include <cmath>
#include <stdexcept>
#include "helpers/logger.h"

// --- SpectrumSignal Implementation ---

SpectrumSignal::SpectrumSignal(const std::vector<std::vector<double>>* data)
    : internalData(nullptr), externalData(data), isExternal(true)
{
    if (data) {
        dataSize = data->size();
    } else {
        dataSize = 0;
    }
}

SpectrumSignal::SpectrumSignal(int size)
    : internalData(new std::vector<std::vector<double>>(size)), externalData(nullptr), isExternal(false), dataSize(size)
{
}

SpectrumSignal::~SpectrumSignal()
{
    if (!isExternal && internalData) {
        delete internalData;
        internalData = nullptr;
    }
}

Signal<std::vector<double>>* SpectrumSignal::makeSignal(int size)
{
    return new SpectrumSignal(size);
}

void SpectrumSignal::freeSignal()
{
    if (!isExternal && internalData) {
        delete internalData;
        internalData = nullptr;
    }
}

int SpectrumSignal::size()
{
    if (isExternal && externalData) {
        return externalData->size();
    } else if (!isExternal && internalData) {
        return internalData->size();
    }
    return 0;
}

std::vector<double> SpectrumSignal::valueAt(int index)
{
    if (isExternal && externalData) {
        if (index >= 0 && index < externalData->size()) {
            return (*externalData)[index];
        }
    } else if (!isExternal && internalData) {
        if (index >= 0 && index < internalData->size()) {
            return (*internalData)[index];
        }
    }
    return std::vector<double>();
}

void SpectrumSignal::setValueAt(std::vector<double> value, int index)
{
    if (!isExternal && internalData) {
        if (index >= 0 && index < internalData->size()) {
            (*internalData)[index] = value;
        }
    }
    // Cannot set value on external read-only data
}

const std::vector<std::vector<double>>& SpectrumSignal::getData() const
{
    if (isExternal && externalData) {
        return *externalData;
    } else if (!isExternal && internalData) {
        return *internalData;
    }
    static std::vector<std::vector<double>> empty;
    return empty;
}

// --- SpecDPService Implementation ---

SpecDPService::SpecDPService(const std::vector<std::vector<double>>& patternData, 
                             const std::vector<std::vector<double>>& signalData, 
                             int globalLimit, 
                             double localLimit)
    : BaseDPService<std::vector<double>>(
        new SpectrumSignal(&patternData), 
        new SpectrumSignal(&signalData), 
        globalLimit, 
        localLimit)
{
}

std::vector<std::vector<double>> SpecDPService::getScaledSpectrum()
{
    Signal<std::vector<double>>* scaledSignal = this->getScaledSignal();
    SpectrumSignal* specSignal = dynamic_cast<SpectrumSignal*>(scaledSignal);
    
    std::vector<std::vector<double>> result;
    if (specSignal) {
        result = specSignal->getData(); // Copy data
    }
    
    // The scaledSignal is created by applyMask which allocates it. 
    // We own it and should delete it, or manage it via BaseDPService if it held it, 
    // but BaseDPService::getScaledSignal() returns a new Signal* that the caller is responsible for?
    // Looking at BaseDPService::getScaledSignal(): returns applyMask(signal).
    // applyMask returns result from makeSignal.
    // So we are responsible for deleting it.
    
    if (scaledSignal) {
        scaledSignal->freeSignal();
        delete scaledSignal;
    }

    return result;
}

double SpecDPService::calculateError(int value1Pos, int value2Pos)
{
    std::vector<double> val1 = this->signal->valueAt(value1Pos);
    std::vector<double> val2 = this->pattern->valueAt(value2Pos);

    if (val1.empty() || val2.empty() || val1.size() != val2.size()) {
        // Handle size mismatch or empty vectors. 
        // For DP, returning a large error is appropriate if they can't match.
        // However, assuming consistent spectrum dimension.
        return 1e9; // Large value
    }

    double sumSq = 0.0;
    for (size_t i = 0; i < val1.size(); ++i) {
        double diff = val1[i] - val2[i];
        sumSq += diff * diff;
    }

    return std::sqrt(sumSq);
}

// Simple forwarding log implementation - forwards to project logger
void SpecDPService::log(const std::string& message)
{
    LOG_DEBUG() << message;
}
