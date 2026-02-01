#ifndef FILEAPI_H
#define FILEAPI_H

#include <QObject>
#include <QVariantMap>
#include <QString>

class FileApi : public QObject
{
    Q_OBJECT
public:
    explicit FileApi(QObject *parent = nullptr);

    Q_INVOKABLE QVariantMap getFiles(const QString &path, const QStringList &nameFilters);
    Q_INVOKABLE QVariantList getFolders(const QString &path);
    Q_INVOKABLE QVariantList getFilesList(const QString &path, const QStringList &nameFilters);
    Q_INVOKABLE void deleteFile(const QString &file);

    Q_INVOKABLE QString getApplicationDirPath();

};

#endif // FILEAPI_H
