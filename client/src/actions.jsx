import {
  SET_DOCUMENT_SOURCES,
  SET_DOCUMENTS,
  SET_MANIFEST_FETCH_ERROR_MESSAGE,
  SET_MANIFEST_FETCH_STATUS,
  SET_VETERAN_ID,
  SET_VETERAN_NAME,
  UPDATE_SEARCH_TEXT
} from './actionTypes';
import { MANIFEST_FETCH_STATUS_LOADING } from './Constants';

export const setDocuments = (docs) => ({
  type: SET_DOCUMENTS,
  payload: docs
});

export const setDocumentSources = (sources) => ({
  type: SET_DOCUMENT_SOURCES,
  payload: sources
});

export const setManifestFetchErrorMessage = (msg) => ({
  type: SET_MANIFEST_FETCH_ERROR_MESSAGE,
  payload: msg
});

export const setManifestFetchStatus = (status) => ({
  type: SET_MANIFEST_FETCH_STATUS,
  payload: status
});

export const setVeteranId = (id) => ({
  type: SET_VETERAN_ID,
  payload: id
});

export const setVeteranName = (name) => ({
  type: SET_VETERAN_NAME,
  payload: name
});

export const updateSearchInputText = (text) => ({
  type: UPDATE_SEARCH_TEXT,
  payload: text
});

export const clearManifestFetchState = () => (dispatch) => {
  dispatch(setManifestFetchErrorMessage(''));
  dispatch(setDocuments([]));
  dispatch(setDocumentSources([]));
  dispatch(setManifestFetchStatus(MANIFEST_FETCH_STATUS_LOADING));
};
