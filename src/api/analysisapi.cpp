#include "analysisapi.h"
#include "helpers/logger.h"
#include "src/services/helpers/vectorutils.h"
#include "src/services/umpservice.h"
#include <QPointF>
#include <algorithm>

AnalysisApi::AnalysisApi(QObject* parent)
    : QObject(parent)
{
}

QVariantMap AnalysisApi::compareUMP(const QVariantList& referenceUmp,
    const QVariantList& userUmp,
    const QVariantList& referenceCuePoints,
    const QVariantList& userCuePoints,
    double fullMin,
    double fullMax,
    bool useOnlyN)
{
    LOG_DEBUG() << "Start: AnalysisApi::compareUMP - reference.size="
                << referenceUmp.size() << ", user.size=" << userUmp.size();

    QVariantMap out;

    // Convert QVariantList -> std::vector<double>
    auto toVector = [](const QVariantList& list) {
        std::vector<double> vec;
        vec.reserve(list.size());
        for (const auto& v : list) {
            if (v.canConvert<QPointF>()) {
                vec.push_back(v.toPointF().y());
            } else {
                vec.push_back(v.toDouble());
            }
        }
        return vec;
    };

    auto buildNucleusMask = [](const QVariantList& cuePoints, size_t length) {
        std::vector<bool> mask(length, false);
        for (const auto& cp : cuePoints) {
            QVariantMap cpMap = cp.toMap();
            if (!cpMap.contains("type") || !cpMap["type"].canConvert<int>()) {
                continue;
            }
            int type = cpMap["type"].toInt();
            if (type != static_cast<int>(CuePointType::NUCLEUS)) {
                continue;
            }
            unsigned int pos = cpMap["position"].toUInt();
            unsigned int len = cpMap["length"].toUInt();
            if (pos >= length) {
                continue;
            }
            unsigned int end = std::min(static_cast<unsigned int>(length), pos + len);
            for (unsigned int i = pos; i < end; ++i) {
                mask[i] = true;
            }
        }
        return mask;
    };

    std::vector<double> refVec = toVector(referenceUmp);
    std::vector<double> userVec = toVector(userUmp);

    if (useOnlyN) {
        std::vector<bool> refMask = buildNucleusMask(referenceCuePoints, refVec.size());
        std::vector<bool> userMask = buildNucleusMask(userCuePoints, userVec.size());

        if (!refMask.empty() && !userMask.empty()) {
            std::vector<double> refNucleus;
            std::vector<double> userNucleus;
            size_t commonLength = std::min(refVec.size(), userVec.size());
            for (size_t i = 0; i < commonLength; ++i) {
                if (i < refMask.size() && i < userMask.size() && refMask[i] && userMask[i]) {
                    refNucleus.push_back(refVec[i]);
                    userNucleus.push_back(userVec[i]);
                }
            }
            if (!refNucleus.empty() && !userNucleus.empty()) {
                refVec.swap(refNucleus);
                userVec.swap(userNucleus);
            } else {
                LOG_WARNING() << "compareUMP: useOnlyN=true but no matching NUCLEUS frames found";
            }
        } else {
            LOG_WARNING() << "compareUMP: useOnlyN=true but cue point metadata is missing";
        }
    }

    UMPComparison cmp = UMPService::compareUMP(refVec, userVec, fullMin, fullMax);

    out["referenceRange"] = cmp.referenceRange;
    out["userRange"] = cmp.userRange;
    out["rangeSimilarity"] = cmp.rangeSimilarity;
    out["shapeSimilarity"] = cmp.shapeSimilarity;

    LOG_DEBUG() << "Finish: AnalysisApi::compareUMP - refRange="
                << cmp.referenceRange << ", userRange=" << cmp.userRange
                << ", rangeSim=" << cmp.rangeSimilarity
                << ", shapeSim=" << cmp.shapeSimilarity;

    return out;
}
