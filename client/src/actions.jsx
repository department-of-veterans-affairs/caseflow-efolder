import {
  SET_DOCUMENT_SOURCES,
  SET_DOCUMENTS,
  SET_ERROR_MESSAGE,
  SET_VETERAN_ID,
  SET_VETERAN_NAME,
  UPDATE_SEARCH_TEXT
} from './actionTypes';

export const setDocuments = (docs) => ({
  type: SET_DOCUMENTS,
  payload: docs
});

export const setDocumentSources = (sources) => ({
  type: SET_DOCUMENT_SOURCES,
  payload: sources
});

export const setErrorMessage = (msg) => ({
  type: SET_ERROR_MESSAGE,
  payload: msg
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
  dispatch(setErrorMessage(''));
  dispatch(setDocuments([]));
  dispatch(setDocumentSources([]));
};
