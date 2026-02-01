#ifndef DPMASKSERVICE_H
#define DPMASKSERVICE_H

#include "basedpservice.h"
#include <vector>
#include <algorithm>

/**
 * @brief Service to apply pre-calculated DP mask to signals
 */
class DPMaskService
{
private:
    std::vector<DPMaskPoint> maskData;
    int maxPatternPos;

public:
    DPMaskService(const std::vector<DPMaskPoint>& mask) : maskData(mask), maxPatternPos(0)
    {
        for (const auto& point : maskData) {
            if (point.patternPos > maxPatternPos) {
                maxPatternPos = point.patternPos;
            }
        }
    }

    /**
     * @brief Applies the mask to the input signal
     * @tparam T Value type of the signal
     * @param inputSignal Signal to transform
     * @return New transformed signal (caller owns memory)
     */
    template <typename T>
    Signal<T>* applyMask(Signal<T>* inputSignal)
    {
        int outputSize = maxPatternPos + 1;
        Signal<T>* result = inputSignal->makeSignal(outputSize);
        
        // Initialize with default values if necessary, or rely on coverage
        // Since mask coverage might not be contiguous for all pattern positions if there are jumps (unlikely in this DP), 
        // or multiple signal points mapping to one pattern point (vertical), 
        // we iterate the mask path which describes the correspondence.
        
        // Note: The mask path acts as a set of instructions. 
        // If we iterate the mask path from start to end (which is usually end to start in the linked list in BaseDP),
        // we write values.
        // BaseDPService::applyMask iterates the stack (which is reversed path, from end to start).
        // Let's assume maskData is ordered as retrieved from BaseDPService::getMaskData, 
        // which iterates the same stack.
        
        for (const auto& point : maskData) {
             // Check bounds just in case
             if (point.patternPos >= 0 && point.patternPos < outputSize && point.signalPos >= 0 && point.signalPos < inputSignal->size()) {
                 result->setValueAt(inputSignal->valueAt(point.signalPos), point.patternPos);
             }
        }
        
        return result;
    }
    
    /**
     * @brief Get the mask data
     */
    const std::vector<DPMaskPoint>& getMask() const {
        return maskData;
    }
};

#endif // DPMASKSERVICE_H
