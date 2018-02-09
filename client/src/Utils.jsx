import {
  MANIFEST_DOWNLOAD_NOT_STARTED_STATUS,
  MANIFEST_DOWNLOAD_SUCCESS_STATUS,
  MANIFEST_DOWNLOAD_FAILED_STATUS,
  MANIFEST_SOURCE_FETCH_NOT_STARTED_STATUS,
  MANIFEST_SOURCE_FETCH_IN_PROGRESS_STATUS
} from './Constants';

export const aliasForSource = (source) => source === 'VVA' ? 'VVA/LCM' : source;

export const documentDownloadComplete = (status) =>
  [MANIFEST_DOWNLOAD_SUCCESS_STATUS, MANIFEST_DOWNLOAD_FAILED_STATUS].includes(status);

export const documentDownloadStarted = (status) => status !== MANIFEST_DOWNLOAD_NOT_STARTED_STATUS;

export const formatDateString = (str) => {
  const date = new Date(str);

  return `${date.getMonth() + 1}/${date.getDate()}/${date.getFullYear()}`;
};

// Before the manifest fetch request documentSources will be an empty array. The manifest fetch POST request kicks off
// a job on the backend that should (at the time of this writing) put two items in the documentSources array (one each
// for VVA and VBMS). If either of those document sources have anything other than a finished state, the entire
// manifest fetch is incomplete.
export const manifestFetchComplete = (sources) => {
  if (!sources.length) {
    return false;
  }

  for (const src of sources) {
    if ([MANIFEST_SOURCE_FETCH_NOT_STARTED_STATUS, MANIFEST_SOURCE_FETCH_IN_PROGRESS_STATUS].includes(src.status)) {
      return false;
    }
  }

  return true;
};
