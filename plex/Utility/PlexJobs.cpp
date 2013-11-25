//
//  PlexJobs.cpp
//  Plex Home Theater
//
//  Created by Tobias Hieta on 2013-08-14.
//
//

#include "PlexJobs.h"
#include "FileSystem/PlexDirectory.h"

#include "FileSystem/PlexFile.h"

#include "TextureCache.h"
#include "File.h"
#include "utils/Crc32.h"
#include "PlexFile.h"
#include "video/VideoInfoTag.h"

////////////////////////////////////////////////////////////////////////////////
bool CPlexHTTPFetchJob::DoWork()
{
  return m_http.Get(m_url.Get(), m_data);
}

////////////////////////////////////////////////////////////////////////////////
bool CPlexHTTPFetchJob::operator==(const CJob* job) const
{
  const CPlexHTTPFetchJob *f = static_cast<const CPlexHTTPFetchJob*>(job);
  return m_url.Get() == f->m_url.Get();
}

////////////////////////////////////////////////////////////////////////////////
bool CPlexDirectoryFetchJob::DoWork()
{
  return m_dir.GetDirectory(m_url.Get(), m_items);
}

////////////////////////////////////////////////////////////////////////////////
bool CPlexMediaServerClientJob::DoWork()
{
  XFILE::CPlexFile file;
  bool success = false;
  
  if (m_verb == "PUT")
    success = file.Put(m_url.Get(), m_data);
  else if (m_verb == "GET")
    success = file.Get(m_url.Get(), m_data);
  else if (m_verb == "DELETE")
    success = file.Delete(m_url.Get(), m_data);
  else if (m_verb == "POST")
    success = file.Post(m_url.Get(), m_postData, m_data);
  
  return success;
}

////////////////////////////////////////////////////////////////////////////////////////
bool CPlexVideoThumbLoaderJob::DoWork()
{
  if (!m_item->IsPlexMediaServer())
    return false;

  if (m_item->HasArt("thumb") &&
      !CTextureCache::Get().HasCachedImage(m_item->GetArt("thumb")))
    CTextureCache::Get().BackgroundCacheImage(m_item->GetArt("thumb"));

  if (ShouldCancel(1, 5))
    return false;

  if (m_item->HasArt("fanart") &&
      !CTextureCache::Get().HasCachedImage(m_item->GetArt("fanart")))
    CTextureCache::Get().BackgroundCacheImage(m_item->GetArt("fanart"));

  if (ShouldCancel(2, 5))
    return false;

  if (m_item->HasArt("grandParentThumb") &&
      !CTextureCache::Get().HasCachedImage(m_item->GetArt("grandParentThumb")))
    CTextureCache::Get().BackgroundCacheImage(m_item->GetArt("grandParentThumb"));

  if (ShouldCancel(3, 5))
    return false;

  if (m_item->HasArt("bigPoster") &&
      !CTextureCache::Get().HasCachedImage(m_item->GetArt("bigPoster")))
    CTextureCache::Get().BackgroundCacheImage(m_item->GetArt("bigPoster"));

  return true;
}

using namespace XFILE;

////////////////////////////////////////////////////////////////////////////////////////
bool
CPlexDownloadFileJob::DoWork()
{
  CCurlFile http;
  CFile file;
  CURL theUrl(m_url);
  http.SetRequestHeader("X-Plex-Client", PLEX_TARGET_NAME);

  if (!file.OpenForWrite(m_destination, true))
  {
    CLog::Log(LOGWARNING, "[DownloadJob] Couldn't open file %s for writing", m_destination.c_str());
    return false;
  }

  if (http.Open(theUrl))
  {
    CLog::Log(LOGINFO, "[DownloadJob] Downloading %s to %s", m_url.c_str(), m_destination.c_str());

    bool done = false;
    bool failed = false;
    int64_t read;
    int64_t leftToDownload = http.GetLength();
    int64_t total = leftToDownload;

    while (!done)
    {
      char buffer[4096];
      read = http.Read(buffer, 4096);
      if (read > 0)
      {
        leftToDownload -= read;
        file.Write(buffer, read);
        done = ShouldCancel(total-leftToDownload, total);
        if(done) failed = true;
      }
      else if (read == 0)
      {
        done = true;
        failed = total == 0;
        continue;
      }

      if (total == 0)
        done = true;
    }

    CLog::Log(LOGINFO, "[DownloadJob] Done with the download.");

    http.Close();
    file.Close();

    return !failed;
  }

  CLog::Log(LOGWARNING, "[DownloadJob] Failed to download file.");
  return false;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
bool CPlexThemeMusicPlayerJob::DoWork()
{
  CStdString themeMusicUrl = m_item.GetProperty("theme").asString();
  if (themeMusicUrl.empty())
    return false;

  Crc32 crc;
  crc.ComputeFromLowerCase(themeMusicUrl);

  CStdString hex;
  hex.Format("%08x", (unsigned int)crc);

  m_fileToPlay = "special://masterprofile/ThemeMusicCache/" + hex + ".mp3";

  if (!XFILE::CFile::Exists(m_fileToPlay))
  {
    CPlexFile plex;
    CFile localFile;

    if (!localFile.OpenForWrite(m_fileToPlay, true))
    {
      CLog::Log(LOGWARNING, "CPlexThemeMusicPlayerJob::DoWork failed to open %s for writing.", m_fileToPlay.c_str());
      return false;
    }

    bool failed = false;

    if (plex.Open(themeMusicUrl))
    {
      bool done = false;
      int64_t read = 0;

      while(!done)
      {
        char buffer[4096];
        read = plex.Read(buffer, 4096);
        if (read > 0)
        {
          localFile.Write(buffer, read);
          done = ShouldCancel(0, 0);
          if (done) failed = true;
        }
        else if (read == 0)
        {
          done = true;
          continue;
        }
      }
    }

    CLog::Log(LOGDEBUG, "CPlexThemeMusicPlayerJob::DoWork cached %s => %s", themeMusicUrl.c_str(), m_fileToPlay.c_str());

    plex.Close();
    localFile.Close();

    return !failed;
  }
  else
    return true;
}
