#ifndef ANALYSISAPI_H
#define ANALYSISAPI_H

#include <QObject>
#include <QVariant>

/*
 * AnalysisApi class provides methods for analyzing and comparing pitch contours
 * represented as UMP (Unified Melody Profile) data. The compareUMP method takes
 * two UMP contours (reference and user) along with the full range of values
 * (fullMin and fullMax) and returns a QVariantMap containing the analysis
 * results, such as similarity scores, error metrics, or any other relevant
 * information.
 *
 * This class is designed to be used in a QML context, allowing for easy
 * integration with the UI components of the application. The analysis results
 * can be displayed in the UI to provide feedback to the user about their pitch
 * accuracy compared to a reference contour.
 */
class AnalysisApi : public QObject {
    Q_OBJECT
public:
    explicit AnalysisApi(QObject* parent = nullptr);

public slots:
    /**
     * Compares the reference UMP contour with the user UMP contour and returns
     * analysis results in a QVariantMap. The fullMin and fullMax parameters
     * represent the range of values for normalization or scaling purposes.
     *
     * @param referenceUmp - The reference UMP contour as a QVariantList.
     * @param userUmp - The user UMP contour as a QVariantList.
     * @param fullMin - The minimum value in the full range of UMP values.
      * @param fullMax - The maximum value in the full range of UMP values.
     * @param referenceCuePoints - Optional processed cue point metadata for the
     *        reference UMP contour.
     * @param userCuePoints - Optional processed cue point metadata for the user
     *        UMP contour.
     * @param useOnlyN - If true, compare only frames inside NUCLEUS segments.
     * @return A QVariantMap containing analysis results such as similarity scores
     *         or error metrics.
     */
    Q_INVOKABLE QVariantMap compareUMP(const QVariantList& referenceUmp,
        const QVariantList& userUmp,
        const QVariantList& referenceCuePoints,
        const QVariantList& userCuePoints,
        double fullMin, double fullMax,
        bool useOnlyN = false);
};

#endif // ANALYSISAPI_H
