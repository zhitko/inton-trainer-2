#include "analysisapi.h"
#include "helpers/logger.h"
#include "src/services/helpers/vectorutils.h"
#include "src/services/umpservice.h"
#include <QPointF>

AnalysisApi::AnalysisApi(QObject* parent)
    : QObject(parent)
{
}

QVariantMap AnalysisApi::compareUMP(const QVariantList& referenceUmp,
    const QVariantList& userUmp, double fullMin,
    double fullMax)
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

    std::vector<double> refVec = toVector(referenceUmp);
    std::vector<double> userVec = toVector(userUmp);

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
