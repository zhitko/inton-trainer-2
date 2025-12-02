#include "fileapi.h"
#include "helpers/logger.h"
#include <QDirIterator>
#include <QDebug>
#include <QFileInfo>
#include <QRegularExpression>
#include <QFile>
#include <QCoreApplication>
#include <QDir>

namespace {
void insert(QVariantMap& map, const QStringList& path, bool isFile) {
    if (path.isEmpty()) {
        return;
    }

    QString key = path.first();
    QStringList remainingPath = path.mid(1);

    if (remainingPath.isEmpty()) {
        if (isFile) {
            map.insert(key, QVariant()); // It's a file, represented by a null QVariant
        } else { // It's a directory
            if (!map.contains(key)) {
                map.insert(key, QVariantMap());
            }
        }
        return;
    }

    if (!map.contains(key) || map[key].typeId() != QMetaType::QVariantMap) {
        map[key] = QVariant(QVariantMap());
    }

    QVariantMap innerMap = map[key].toMap();
    insert(innerMap, remainingPath, isFile);
    map[key] = innerMap;
}
}

FileApi::FileApi(QObject *parent) : QObject(parent)
{

}

void FileApi::deleteFile(const QString &file)
{
    LOG_DEBUG() << "Start: deleteFile - file=" << file;
    QString basePath = QCoreApplication::applicationDirPath();
    QString searchPath = QDir(basePath).filePath(file);
    QFile f(searchPath);
    f.remove();
    LOG_DEBUG() << "Finish: deleteFile";
}

QVariantMap FileApi::getFiles(const QString &path, const QStringList &nameFilters)
{
    LOG_DEBUG() << "Start: getFiles - path=" << path << ", nameFilters=" << nameFilters;
    QString basePath = QCoreApplication::applicationDirPath();
    QString searchPath = QDir(basePath).filePath(path);

    QVariantMap fileTree;
    QDirIterator it(searchPath, QDir::AllEntries | QDir::NoDotAndDotDot, QDirIterator::Subdirectories);

    while (it.hasNext()) {
        it.next();

        QFileInfo fileInfo = it.fileInfo();
        if (fileInfo.isFile()) {
            bool match = false;
            if (nameFilters.isEmpty()) {
                match = true;
            } else {
                for (const QString &filter : nameFilters) {
                    QRegularExpression re(QRegularExpression::wildcardToRegularExpression(filter));
                    if (re.match(fileInfo.fileName()).hasMatch()) {
                        match = true;
                        break;
                    }
                }
            }

            if (!match) {
                continue; // Skip files that don't match the filter
            }
        }

        QString fullPath = fileInfo.filePath();
        QString relativePath = fullPath;
        if (searchPath.endsWith("/")) {
            relativePath.remove(0, searchPath.length());
        } else {
            relativePath.remove(0, searchPath.length() + 1);
        }
        
        if (relativePath.isEmpty()) {
            continue;
        }

        QStringList pathParts = relativePath.split('/');
        insert(fileTree, pathParts, fileInfo.isFile());
    }
    LOG_DEBUG() << "Finish: getFiles - fileCount=" << fileTree.keys().count();
    return fileTree;
}