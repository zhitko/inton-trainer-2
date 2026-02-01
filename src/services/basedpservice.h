#ifndef BASEDPSERVICE_H
#define BASEDPSERVICE_H

#include <climits>
#include <cmath>
#include <limits>
#include <cstddef>
#include <iostream>
#include <vector>
#include <sstream>

#define DP_GLOBAL_LIMIT_ERROR 0.001

/**
 * @brief Operation types for Dynamic Programming state transitions
 */
enum DPStateOperation{
    trHoriz = -1,   ///< Horizontal transition
    trDiag = 0,     ///< Diagonal transition
    trVert = 1,     ///< Vertical transition
    opNone = 2,     ///< No operation / uninitialized
    opFirst = 3     ///< First state
};

/**
 * @brief Structure representing the state of a DP cell
 */
struct DPState{
    double localError;      ///< Error at this specific node
    double globalError;     ///< Accumulated global error
    DPStateOperation operation; ///< Operation leading to this state
    int signalPos;          ///< Position in signal
    int patternPos;         ///< Position in pattern
    int time;               ///< Time steps taken
};

/**
 * @brief Linked list node for DP states (acting as a stack/path)
 */
struct DPStateStack{
    DPState value;
    DPStateStack * next;
};

/**
 * @brief Point in the DP warping path
 */
struct DPMaskPoint {
    int signalPos;
    int patternPos;
};

/**
 * @brief Abstract interface for a signal wrapper
 * @tparam ValueType Data type of the signal values
 */
template< typename ValueType >
class Signal
{
public:
    virtual ~Signal() = default;

    /**
     * @brief Creates a new signal instance of the given size
     * @param size Size of the new signal
     * @return Pointer to the new Signal instance
     */
    virtual Signal<ValueType> * makeSignal(int size) = 0;

    /**
     * @brief Frees the resources associated with the signal
     */
    virtual void freeSignal() = 0;

    /**
     * @brief Returns the size of the signal
     * @return Size of the signal
     */
    virtual int size() = 0;

    /**
     * @brief Gets value at specified index
     * @param index Index to retrieve
     * @return Value at index
     */
    virtual ValueType valueAt(int index) = 0;

    /**
     * @brief Sets value at specified index
     * @param value Value to set
     * @param index Target index
     */
    virtual void setValueAt(ValueType value, int index) = 0;
};

/**
 * @brief Base service template for Dynamic Programming matching algorithms
 * @tparam ValueType Data type of the signal values
 */
template< typename ValueType >
class BaseDPService
{
protected:
    int globalLimit;
    double localLimit;      ///< Weight for the local error
    double a, b, c1, c2, d, aabb;
    DPStateStack * mask;
    double kH, kV, kD, kT, kQ;
    DPStateStack ** stateCache;
    Signal<ValueType> * pattern;
    Signal<ValueType> * signal;
    int signalSize;
    int patternSize;

    /**
     * @brief Retrieves or initializes the cache for a specific cell
     * @param signalPos Position in the signal
     * @param patternPos Position in the pattern
     * @return Pointer to the DPStateStack for the cell
     */
    virtual DPStateStack * getStateCache(const int signalPos, const int patternPos)
    {
        if (stateCache == 0) this->reinitCache();
        return &(stateCache[signalPos][patternPos]);
    }

    /**
     * @brief Calculates normalized time coefficient/penalty
     * @param signalPos Position in the signal
     * @param patternPos Position in the pattern
     * @param t Time parameter
     * @return Normalized coefficient
     */
    virtual double getNormKt(const int signalPos, const int patternPos, int t)
    {
        // Use double to prevent integer overflow for large signals
        return kT * std::abs((double)signalSize * patternPos - (double)patternSize * signalPos) / kQ;
    }

    /**
     * @brief Calculates the next state for a specific cell (Iterative step)
     * @param signalPos Position in the signal
     * @param patternPos Position in the pattern
     * @return Pointer to the computed DPStateStack
     */
    virtual DPStateStack * calcNextIter(const int signalPos, const int patternPos)
    {
        DPStateStack * currentBranch = this->getStateCache(signalPos, patternPos);
        // Check state cache for value
        if(currentBranch->value.operation != opNone)
            return currentBranch;

        // Init current errors
        double localError = this->calculateError(signalPos, patternPos);

        DPState currentState = {localLimit * localError, localError, opFirst, signalPos, patternPos, 0};
        currentBranch->value = currentState;

        if (patternPos == 0) return currentBranch;

        DPStateStack * branchVert    = 0;
        DPStateStack * branchDiag    = 0;
        DPStateStack * branchHoriz   = 0;

        // Try next operations (Lookup previously computed states)
        if(patternPos > 0 && signalPos > 0 && isGlobalPass(signalPos-1, patternPos-1)) {
            DPStateStack* tmp = getStateCache(signalPos-1, patternPos-1);
            if(tmp->value.operation != opNone) branchDiag = tmp;
        }
        if(signalPos > 0 && isGlobalPass(signalPos-1, patternPos)) {
            DPStateStack* tmp = getStateCache(signalPos-1, patternPos);
            if(tmp->value.operation != opNone) branchHoriz = tmp;
        }
        if(patternPos > 0 && isGlobalPass(signalPos, patternPos-1)) {
            DPStateStack* tmp = getStateCache(signalPos, patternPos-1);
            if(tmp->value.operation != opNone) branchVert = tmp;
        }

        // If this is last iteration (no valid predecessors), return current branch as a start point
        if(branchHoriz == 0 && branchDiag == 0 && branchVert == 0)
            return currentBranch;

        // Init last states for all branches
        DPState stateDiag    = {localError, localError, trDiag,  signalPos-1, patternPos-1, 0};
        DPState stateVert = {localError, localError, trVert,  signalPos,   patternPos-1, 0};
        DPState stateHoriz   = {localError, localError, trHoriz, signalPos-1, patternPos, 0};

        double globalDiag = std::numeric_limits<double>::max();
        double globalVert = std::numeric_limits<double>::max();
        double globalHoriz = std::numeric_limits<double>::max();

        // Set value to state if branch calculated
        if(branchDiag != 0)
        {
            stateDiag = branchDiag->value;
            globalDiag = currentBranch->value.localError*kD
                    + stateDiag.globalError
                    + this->getNormKt(signalPos-1, patternPos-1, branchDiag->value.time+1);
        }
        if(branchVert != 0)
        {
            stateVert = branchVert->value;
            globalVert = currentBranch->value.localError*kV
                    + stateVert.globalError
                    + this->getNormKt(signalPos,   patternPos-1, branchVert->value.time);
        }
        if(branchHoriz != 0)
        {
            stateHoriz = branchHoriz->value;
            globalHoriz = currentBranch->value.localError*kH
                    + stateHoriz.globalError
                    + this->getNormKt(signalPos-1, patternPos, branchHoriz->value.time+1);
        }

        // Search branch with minimal global error
        if( globalDiag <= globalHoriz && globalDiag <= globalVert)
        { // Add operation
            currentBranch->next = branchDiag;
            currentBranch->value.globalError = globalDiag;
            currentBranch->value.operation = trDiag;
            if(patternPos != 0)
                currentBranch->value.time = branchDiag->value.time + 1;
        }
        else
        if( globalHoriz <= globalDiag && globalHoriz <= globalVert)
        { // Drop operation
            currentBranch->next = branchHoriz;
            currentBranch->value.globalError = globalHoriz;
            currentBranch->value.operation = trHoriz;
            if(patternPos != 0)
                currentBranch->value.time = branchHoriz->value.time + 1;
        }
        else
        if( globalVert <= globalDiag && globalVert <= globalHoriz)
        { // Repeat operation
            currentBranch->next = branchVert;
            currentBranch->value.globalError = globalVert;
            currentBranch->value.operation = trVert;
            if(patternPos != 0)
                currentBranch->value.time = branchVert->value.time;
        }

        return currentBranch;
    }

public:
    /**
     * @brief Constructs the BaseDPService
     * @param pttrn Pointer to the pattern signal
     * @param sig Pointer to the input signal
     * @param global Global limit parameter
     * @param local Local limit parameter
     */
    BaseDPService(Signal<ValueType> * pttrn, Signal<ValueType> * sig, int global, double local) :
        kH(0.1),
        kV(1.0),
        kD(0.5),
        kT(20),
        pattern(pttrn),
        signal(sig),
        mask(0),
        stateCache(0),
        globalLimit(global),
        localLimit(local),
        signalSize(sig->size()),
        patternSize(pttrn->size())
    {
        {
            std::ostringstream __dp_oss;
            __dp_oss << "Start: BaseDPService constructor";
            this->log(__dp_oss.str());
        }
        kQ = std::sqrt(patternSize*patternSize + signalSize*signalSize);
        double x11 = 0.0;
        double y11 = global;
        double x12 = signalSize - global;
        double y12 = patternSize;
        double x21 = global;
        double y21 = 0.0;
        double x22 = signalSize;
        double y22 = patternSize - global;
        a = y11 - y12;
        b = x12 - x11;
        c1 = x11 * y12 - x12 * y11;
        c2 = x21 * y22 - x22 * y21;
        aabb = std::sqrt(a*a+b*b);
        d = std::abs(c1-c2)/aabb;
        {
            std::ostringstream __dp_oss;
            __dp_oss << "Finish: BaseDPService constructor - signalSize=" << signalSize << ", patternSize=" << patternSize;
            this->log(__dp_oss.str());
        }
    }

    virtual ~BaseDPService()
    {
        {
            std::ostringstream __dp_oss;
            __dp_oss << "Start: BaseDPService destructor";
            this->log(__dp_oss.str());
        }
        if(stateCache)
        {
            for(int i=0; i<this->signalSize; i++)
                delete[] stateCache[i];
            delete[] stateCache;
            stateCache = nullptr;
        }
        pattern->freeSignal();
        signal->freeSignal();
        delete pattern;
        delete signal;
        {
            std::ostringstream __dp_oss;
            __dp_oss << "Finish: BaseDPService destructor";
            this->log(__dp_oss.str());
        }
    }

    /**
     * @brief Logging hook - override in derived classes to forward logs
     */
    virtual void log(const std::string& /*message*/) { /* no-op by default */ }

    /**
     * @brief Applies configuration settings
     * @param kh Horizontal coefficient
     * @param kv Vertical coefficient
     * @param kd Diagonal coefficient
     * @param kt Time coefficient
     */
    void applySettings(double kh, double kv, double kd, double kt)
    {
        {
            std::ostringstream __dp_oss;
            __dp_oss << "applySettings: kH " << this->kH << " to " << kh;
            this->log(__dp_oss.str());
        }
        this->kH = kh;
        {
            std::ostringstream __dp_oss;
            __dp_oss << "applySettings: kD " << this->kD << " to " << kd;
            this->log(__dp_oss.str());
        }
        this->kD = kd;
        {
            std::ostringstream __dp_oss;
            __dp_oss << "applySettings: kT " << this->kT << " to " << kt;
            this->log(__dp_oss.str());
        }
        this->kT = kt;
        {
            std::ostringstream __dp_oss;
            __dp_oss << "applySettings: kV " << this->kV << " to " << kv;
            this->log(__dp_oss.str());
        }
        this->kV = kv;
    }

    /**
     * @brief Checks if the point is within the global pass band
     * @param sX Signal X coordinate
     * @param pY Pattern Y coordinate
     * @return True if within bounds, false otherwise
     */
    virtual bool isGlobalPass(int sX,int pY)
    {
        return true;
    }

    /**
     * @brief Gets the signal size
     * @return Signal size
     */
    virtual int getSignalSize()
    {
        return this->signalSize;
    }

    /**
     * @brief Gets the pattern size
     * @return Pattern size
     */
    virtual int getPatternSize()
    {
        return this->patternSize;
    }

    /**
     * @brief Computes or retrieves the optimal path mask (warping path)
     * @return Pointer to the start of the path state stack
     */
    virtual DPStateStack * getSignalMask()
    {
        if(!this->mask)
        {
            {
                std::ostringstream __dp_oss;
                __dp_oss << "DP Init " << this->signalSize << " : " << this->patternSize << " iterations->" << this->signalSize*this->patternSize;
                this->log(__dp_oss.str());
            }
            
            if (stateCache == 0) this->reinitCache();
            
            // Iterative DP approach to prevent stack overflow
            for (int i = 0; i < this->signalSize; ++i) {
                for (int j = 0; j < this->patternSize; ++j) {
                    if (this->isGlobalPass(i, j)) {
                        this->calcNextIter(i, j);
                    }
                }
            }

            this->mask = this->getStateCache(this->signalSize - 1, this->patternSize - 1);
            {
                std::ostringstream __dp_oss;
                __dp_oss << "DP Finish " << this->mask->value.globalError;
                this->log(__dp_oss.str());
            }
        }
        return this->mask;
    }

    /**
     * @brief Returns a scaled/warped version of the signal based on the calculated mask
     * @return Pointer to the new signal
     */
    virtual Signal<ValueType> * getScaledSignal()
    {
        return this->applyMask(this->signal);
    }

    /**
     * @brief Reinitializes the state cache, clearing previous calculations
     */
    virtual void reinitCache()
    {
        if(stateCache)
        {
            for(int i=0; i<this->signalSize; i++)
                delete[] stateCache[i];
            delete[] stateCache;
        }

        DPState stubState = {0, 0, opNone, 0, 0, 0};
        stateCache = new DPStateStack* [this->signalSize];
        for(int i=0; i<this->signalSize; i++)
        {
            stateCache[i] = new DPStateStack[this->patternSize];
            for(int j=0; j<this->patternSize; j++)
            {
                stateCache[i][j].value = stubState;
                stateCache[i][j].next = 0;
            }
        }
    }

    /**
     * @brief Applies the calculated warping path to a given signal array
     * @param array Input signal to wrap
     * @return Warped signal
     */
    template< typename SignalValueType >
    Signal<SignalValueType> * applyMask(Signal<SignalValueType> * array)
    {
        if(!this->mask){
            reinitCache();
            getSignalMask();
        }
        if(signal->size() != array->size()){
            {
                std::ostringstream __dp_oss;
                __dp_oss << "Array has different size (" << signal->size() << " - " << array->size() << ")";
                this->log(__dp_oss.str());
            }
            return array;
        }

        Signal<SignalValueType> * result = array->makeSignal(this->patternSize);

        DPStateStack * stateStep = this->mask;
        DPStateOperation operation = opNone;
        while(stateStep != 0)
        {
            operation = stateStep->value.operation;
            switch (operation) {
                case trDiag:
                case trVert:
                    result->setValueAt(array->valueAt(stateStep->value.signalPos), stateStep->value.patternPos);
                    break;
                case trHoriz:
                    break;
                default:
                    break;
            }
            stateStep = stateStep->next;
        }

        return result;
    }

    /**
     * @brief Gets the mapping indices from pattern to signal
     * @return Array of indices
     */
    int * getTemplateMapping()
    {
        if(!this->mask){
            reinitCache();
            getSignalMask();
        }

        int * templateIndex = new int[this->patternSize];
        for (int i=0; i<this->patternSize; i++) templateIndex[i] = i;

        int * templateMapping = new int[this->patternSize];
        for (int i=0; i<this->patternSize; i++) templateMapping[i] = 0;

        DPStateStack * stateStep = this->mask;
        DPStateOperation operation = opNone;
        while(stateStep != 0)
        {
            operation = stateStep->value.operation;
            switch (operation) {
                case trDiag:
                case trVert:
                    templateMapping[stateStep->value.patternPos] = templateIndex[stateStep->value.signalPos];
                    break;
                case trHoriz:
                    break;
                default:
                    break;
            }
            stateStep = stateStep->next;
        }

        delete[] templateIndex; // Fixed delete to delete[]

        return templateMapping;
    }

    /**
     * @brief Retrieves the mask data as a list of points
     * @return Vector of DPMaskPoint
     */
    virtual std::vector<DPMaskPoint> getMaskData()
    {
        if(!this->mask){
            reinitCache();
            getSignalMask();
        }

        std::vector<DPMaskPoint> points;
        DPStateStack * stateStep = this->mask;
        DPStateOperation operation = opNone;
        
        while(stateStep != 0)
        {
            operation = stateStep->value.operation;
            switch (operation) {
                case trDiag:
                case trVert:
                    points.push_back({stateStep->value.signalPos, stateStep->value.patternPos});
                    break;
                case trHoriz:
                    break;
                default:
                    break;
            }
            stateStep = stateStep->next;
        }
        
        return points;
    }

protected:
    /**
     * @brief Calculates the local error between two points
     * @param value1Pos Position in signal 1
     * @param value2Pos Position in signal 2
     * @return Error value
     */
    virtual double calculateError(int value1Pos, int value2Pos) = 0;
};

#endif // BASEDPSERVICE_H
