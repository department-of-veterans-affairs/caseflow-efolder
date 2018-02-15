import {
  RESET_DEFAULT_MANIFEST_STATE,
  SET_ACTIVE_DOWNLOAD_PROGRESS_TAB,
  SET_DOCUMENT_SOURCES,
  SET_DOCUMENTS,
  SET_DOCUMENTS_FETCH_COMPLETION_ESTIMATE,
  SET_DOCUMENTS_FETCH_STATUS,
  SET_ERROR_MESSAGE,
  SET_MANIFEST_ID,
  SET_RECENT_DOWNLOADS,
  SET_VETERAN_ID,
  SET_VETERAN_NAME,
  SET_SEARCH_TEXT
} from './actionTypes';

export const resetDefaultManifestState = () => ({
  type: RESET_DEFAULT_MANIFEST_STATE
});

export const setActiveDownloadProgressTab = (tab) => ({
  type: SET_ACTIVE_DOWNLOAD_PROGRESS_TAB,
  payload: tab
});

export const setDocuments = (docs) => ({
  type: SET_DOCUMENTS,
  payload: docs
});

export const setDocumentsFetchCompletionEstimate = (estimate) => ({
  type: SET_DOCUMENTS_FETCH_COMPLETION_ESTIMATE,
  payload: estimate
});

export const setDocumentsFetchStatus = (status) => ({
  type: SET_DOCUMENTS_FETCH_STATUS,
  payload: status
});

export const setDocumentSources = (sources) => ({
  type: SET_DOCUMENT_SOURCES,
  payload: sources
});

export const setErrorMessage = (msg) => ({
  type: SET_ERROR_MESSAGE,
  payload: msg
});

export const setManifestId = (id) => ({
  type: SET_MANIFEST_ID,
  payload: id
});

export const setRecentDownloads = (downloads) => ({
  type: SET_RECENT_DOWNLOADS,
  payload: downloads
});

export const setSearchInputText = (text) => ({
  type: SET_SEARCH_TEXT,
  payload: text
});

export const setVeteranId = (id) => ({
  type: SET_VETERAN_ID,
  payload: id
});

export const setVeteranName = (name) => ({
  type: SET_VETERAN_NAME,
  payload: name
});
