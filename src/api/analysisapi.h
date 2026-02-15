#ifndef ANALYSISAPI_H
#define ANALYSISAPI_H

#include <QObject>
#include <QVariant>

class AnalysisApi : public QObject
{
    Q_OBJECT
public:
    explicit AnalysisApi(QObject *parent = nullptr);

public slots:
    Q_INVOKABLE QVariantMap compareUMP(const QVariantList& referenceUmp,
                                       const QVariantList& userUmp,
                                       double fullMin,
                                       double fullMax);
};

#endif // ANALYSISAPI_H
