#include "vadautocorrelationservice.h"
#include <cmath>
#include <algorithm>
#include <numeric>
#include <utility>
#include <QDebug>

namespace {

std::pair<int,int> computeLagRange(double sampleRate,
                                  double minF0,
                                  double maxF0)
{
    if (sampleRate <= 0.0) sampleRate = 8000.0;
    if (minF0 <= 0.0) minF0 = 80.0;
    if (maxF0 <= 0.0) maxF0 = 200.0;
    if (minF0 > maxF0) std::swap(minF0, maxF0);

    int lagMin = static_cast<int>(std::round(sampleRate / maxF0));
    int lagMax = static_cast<int>(std::round(sampleRate / minF0));
    lagMin = std::max(1, lagMin);
    lagMax = std::max(lagMin, lagMax);
    return {lagMin, lagMax};
}

} // namespace

VADAutocorrelationService::VADAutocorrelationService(QObject* parent)
    : QObject(parent)
{
    auto lagRange = computeLagRange(m_sampleRate, m_minF0, m_maxF0);
    qDebug().nospace()
        << "VAD-ACF: Initialized"
        << " | FRAME=" << FRAME_SIZE << "samples"
        << " HOP="     << HOP_SIZE   << "samples"
        << " K="       << K_FRAMES
        << " LAG["     << lagRange.first    << ".." << lagRange.second << "]"
        << " F0["      << m_minF0          << ".." << m_maxF0 << " Hz]"
        << " | V-thresholds[H=" << QString::number(DEFAULT_VOICE_THRESHOLD_V_HIGH, 'f', 3)
        <<                  " L=" << QString::number(DEFAULT_VOICE_THRESHOLD_V_LOW,  'f', 3) << "]"
        << " | energyGate=" << QString::number(DEFAULT_ENERGY_THRESHOLD, 'f', 6);
}

// ---------------------------------------------------------------------------
// processAudioSamples
// ---------------------------------------------------------------------------
std::vector<double> VADAutocorrelationService::processAudioSamples(
    const qint16* samples, qint64 numSamples)
{
    // 1. Accumulate incoming samples
    m_sampleBuf.reserve(m_sampleBuf.size() + static_cast<std::size_t>(numSamples));
    for (qint64 i = 0; i < numSamples; ++i) {
        m_sampleBuf.push_back(samples[i]);
    }

    // 2. Extract C(n) frames
    while (m_sampleBuf.size() >= static_cast<std::size_t>(FRAME_SIZE)) {
        std::vector<double> frame(FRAME_SIZE);
        for (int i = 0; i < FRAME_SIZE; ++i) {
            frame[i] = static_cast<double>(m_sampleBuf[i]) / 32768.0;
        }
        applyHammingWindow(frame);

        auto lagRange = computeLagRange(m_sampleRate, m_minF0, m_maxF0);
        double C_n = findMaxAutocorrelation(frame, lagRange.first, lagRange.second);
        m_C.push_back(C_n);

        m_sampleBuf.erase(m_sampleBuf.begin(), m_sampleBuf.begin() + HOP_SIZE);
    }

    // Grow U, H, V to match C (new slots initialised to 0.0)
    if (m_U.size() < m_C.size()) m_U.resize(m_C.size(), 0.0);
    if (m_H.size() < m_C.size()) m_H.resize(m_C.size(), 0.0);
    if (m_V.size() < m_C.size()) m_V.resize(m_C.size(), 0.0);

    // 3. First smoothing pass: U(n) = mean(C[n-K+1..n+K-1]), H(n) = |C(n)-U(n)|
    //
    //    Condition: both sides of the window must exist, i.e.
    //      right edge  n + K - 1 < C.size()  →  n < C.size() - K + 1
    //    Rewritten as the loop guard used by VADEnergyService:
    //      m_valid_U + K_FRAMES - 1 < (int)m_C.size()
    //
    for (; m_valid_U + K_FRAMES - 1 < static_cast<int>(m_C.size()); ++m_valid_U) {
        int i  = m_valid_U;
        // Clamp left edge at 0 for boundary frames (mirrors energy service skip behaviour
        // but produces a real value instead of leaving the slot zero).
        int lo = std::max(0,                            i - K_FRAMES + 1);
        int hi = std::min(static_cast<int>(m_C.size()) - 1, i + K_FRAMES - 1);

        double sumC = 0.0;
        for (int j = lo; j <= hi; ++j) sumC += m_C[j];
        m_U[i] = sumC / static_cast<double>(hi - lo + 1);
        m_H[i] = std::abs(m_C[i] - m_U[i]);
    }

    // 4. Second smoothing pass: V(n) = mean(H[n-K+1..n+K-1])
    //
    //    Condition: right edge of H window must be computed, i.e.
    //      n + K - 1 < m_valid_U   →   m_valid_V + K_FRAMES - 1 < m_valid_U
    //
    std::vector<double> newVValues;
    for (; m_valid_V + K_FRAMES - 1 < m_valid_U; ++m_valid_V) {
        int i  = m_valid_V;
        int lo = std::max(0,             i - K_FRAMES + 1);
        int hi = std::min(m_valid_U - 1, i + K_FRAMES - 1);

        double sumH = 0.0;
        for (int j = lo; j <= hi; ++j) sumH += m_H[j];
        m_V[i] = sumH / static_cast<double>(hi - lo + 1);

        // VAD decision on V(n)
        bool frameSpeech = isSpeech(m_V[i], m_currentVadState);
        m_vadDecisions.push_back(frameSpeech);

        bool stateChanged = (frameSpeech != m_currentVadState);
        if (stateChanged || i % 10 == 0) {
            QString stateStr    = frameSpeech       ? "SPEECH"  : "SILENCE";
            QString oldStateStr = m_currentVadState ? "SPEECH"  : "SILENCE";
            QString reason;
            if (stateChanged) {
                if (frameSpeech) {
                    reason = QString(" [TRIGGERED: V=%1 > H=%2]")
                        .arg(QString::number(m_V[i], 'f', 4))
                        .arg(QString::number(m_voiceThresholdVHigh, 'f', 4));
                } else {
                    reason = QString(" [DROPPED: V=%1 < L=%2]")
                        .arg(QString::number(m_V[i], 'f', 4))
                        .arg(QString::number(m_voiceThresholdVLow, 'f', 4));
                }
            }
            qDebug().nospace()
                << "VAD-ACF[F" << i << "]: " << oldStateStr << " → " << stateStr
                << " | C=" << QString::number(m_C[i], 'f', 3)
                << " U="   << QString::number(m_U[i], 'f', 3)
                << " H="   << QString::number(m_H[i], 'f', 3)
                << " V="   << QString::number(m_V[i], 'f', 4)
                << reason;
        }

        m_currentVadState = frameSpeech;
        newVValues.push_back(m_V[i]);
    }

    return newVValues;
}

// ---------------------------------------------------------------------------
// reset
// ---------------------------------------------------------------------------
void VADAutocorrelationService::reset()
{
    m_sampleBuf.clear();
    m_C.clear();
    m_U.clear();
    m_H.clear();
    m_V.clear();
    m_vadDecisions.clear();
    m_currentVadState = false;
    m_valid_U         = 0;
    m_valid_V         = 0;
    m_recentOffset    = 0;
    qDebug() << "VAD-ACF: Reset — cleared all state and buffers";
}

// ---------------------------------------------------------------------------
// isSpeech — V(n) only
// ---------------------------------------------------------------------------
bool VADAutocorrelationService::isSpeech(double V_n, bool currentState) const
{
    if (currentState) {
        return V_n > m_voiceThresholdVLow;
    } else {
        return V_n > m_voiceThresholdVHigh;
    }
}

// ---------------------------------------------------------------------------
// Saved metrics
// ---------------------------------------------------------------------------
void VADAutocorrelationService::updateSavedMetrics()
{
    m_savedC = m_C;
    m_savedU = m_U;
    m_savedV = m_V;

    // Trim to the number of actually computed values
    if (static_cast<int>(m_savedU.size()) > m_valid_U)
        m_savedU.resize(static_cast<std::size_t>(m_valid_U));
    if (static_cast<int>(m_savedV.size()) > m_valid_V)
        m_savedV.resize(static_cast<std::size_t>(m_valid_V));

    double minC = 0.0, maxC = 0.0, avgC = 0.0;
    if (!m_savedC.empty()) {
        minC = *std::min_element(m_savedC.begin(), m_savedC.end());
        maxC = *std::max_element(m_savedC.begin(), m_savedC.end());
        avgC = std::accumulate(m_savedC.begin(), m_savedC.end(), 0.0)
               / static_cast<double>(m_savedC.size());
    }
    int speechFrames = static_cast<int>(
        std::count(m_vadDecisions.begin(), m_vadDecisions.end(), true));

    qDebug().nospace()
        << "VAD-ACF: Saved"
        << " | C=" << m_savedC.size()
        << " U="   << m_savedU.size()
        << " V="   << m_savedV.size()
        << " | speech_frames=" << speechFrames
        << " | C[min=" << QString::number(minC, 'f', 3)
        <<   " max="   << QString::number(maxC, 'f', 3)
        <<   " avg="   << QString::number(avgC, 'f', 3) << "]";
}

void VADAutocorrelationService::cropSavedMetrics(int startFrame, int endFrame)
{
    auto crop = [](std::vector<double>& v, int s, int e) {
        if (s < 0) s = 0;
        int sz = static_cast<int>(v.size());
        if (e > sz) e = sz;
        if (s >= e) { v.clear(); return; }
        v = std::vector<double>(v.begin() + s, v.begin() + e);
    };
    crop(m_savedC, startFrame, endFrame);
    crop(m_savedU, startFrame, endFrame);
    crop(m_savedV, startFrame, endFrame);
}

// ---------------------------------------------------------------------------
// Streaming access
// ---------------------------------------------------------------------------
std::vector<double> VADAutocorrelationService::getAndClearRecentVValues()
{
    // Return V[m_recentOffset .. m_valid_V) without draining m_V
    std::vector<double> recent(
        m_V.begin() + static_cast<std::ptrdiff_t>(m_recentOffset),
        m_V.begin() + static_cast<std::ptrdiff_t>(m_valid_V));
    m_recentOffset = static_cast<std::size_t>(m_valid_V);
    return recent;
}

// ---------------------------------------------------------------------------
// DSP helpers
// ---------------------------------------------------------------------------
void VADAutocorrelationService::applyHammingWindow(std::vector<double>& frame)
{
    int N = static_cast<int>(frame.size());
    for (int n = 0; n < N; ++n) {
        double w = 0.54 - 0.46 * std::cos(2.0 * M_PI * n / (N - 1.0));
        frame[n] *= w;
    }
}

double VADAutocorrelationService::calculateAutocorrelation(
    const std::vector<double>& frame, int lag)
{
    double sum   = 0.0;
    int    limit = static_cast<int>(frame.size()) - lag;
    for (int n = 0; n < limit; ++n) {
        sum += frame[n] * frame[n + lag];
    }
    return sum;
}

double VADAutocorrelationService::findMaxAutocorrelation(
    const std::vector<double>& frame, int lagMin, int lagMax)
{
    // R(0) — frame energy after Hamming windowing
    double r0 = 0.0;
    for (double v : frame) r0 += v * v;

    // Energy gate: forces C=0 for near-silent frames.
    // DEFAULT_ENERGY_THRESHOLD is set very low (0.0001) so quiet Windows
    // microphone input (AGC-reduced amplitude) is not silenced here.
    // Log R0 at trace level to aid per-platform threshold tuning.
    if (r0 < m_energyThreshold) {
        qDebug().nospace()
            << "VAD-ACF: energy gate R0=" << QString::number(r0, 'f', 6)
            << " < threshold=" << QString::number(m_energyThreshold, 'f', 6)
            << " → C=0 (raise threshold to suppress noise, lower to pass quiet mic)";
        return 0.0;
    }

    double maxCorr = 0.0;
    for (int lag = lagMin; lag <= lagMax && lag < static_cast<int>(frame.size()); ++lag) {
        double normalized = calculateAutocorrelation(frame, lag) / r0;
        if (normalized > maxCorr) maxCorr = normalized;
    }
    return maxCorr;
}