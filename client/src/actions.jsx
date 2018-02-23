import {
  HIDE_CONFIRM_DOWNLOAD_MODAL,
  SET_ACTIVE_DOWNLOAD_PROGRESS_TAB,
  SET_DOCUMENT_SOURCES,
  SET_DOCUMENTS,
  SET_DOCUMENTS_FETCH_COMPLETION_ESTIMATE,
  SET_DOCUMENTS_FETCH_STATUS,
  SET_ERROR_MESSAGE,
  SET_MANIFEST_ID,
  SET_VETERAN_ID,
  SET_VETERAN_NAME,
  SHOW_CONFIRM_DOWNLOAD_MODAL,
  UPDATE_SEARCH_TEXT
} from './actionTypes';

export const hideConfirmDownloadModal = () => ({ type: HIDE_CONFIRM_DOWNLOAD_MODAL });

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

export const setVeteranId = (id) => ({
  type: SET_VETERAN_ID,
  payload: id
});

export const setVeteranName = (name) => ({
  type: SET_VETERAN_NAME,
  payload: name
});

export const showConfirmDownloadModal = () => ({ type: SHOW_CONFIRM_DOWNLOAD_MODAL });

export const updateSearchInputText = (text) => ({
  type: UPDATE_SEARCH_TEXT,
  payload: text
});
