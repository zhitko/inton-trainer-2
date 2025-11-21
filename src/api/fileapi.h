#ifndef FILEAPI_H
#define FILEAPI_H

#include <QObject>
#include <QVariantMap>

class FileApi : public QObject
{
    Q_OBJECT
public:
    explicit FileApi(QObject *parent = nullptr);

    Q_INVOKABLE QVariantMap getFiles(const QString &path, const QStringList &nameFilters);
    Q_INVOKABLE void deleteFile(const QString &file);

};

#endif // FILEAPI_H
