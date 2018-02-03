import {
  SET_MANIFEST_FETCH_ERROR_MESSAGE,
  SET_MANIFEST_FETCH_RESPONSE,
  SET_MANIFEST_FETCH_STATUS,
  SET_VETERAN_ID,
  SET_VETERAN_NAME,
  UPDATE_SEARCH_TEXT
} from './actionTypes';
import { MANIFEST_FETCH_STATUS_LOADING } from './Constants';

export const setManifestFetchErrorMessage = (msg) => ({
  type: SET_MANIFEST_FETCH_ERROR_MESSAGE,
  payload: msg
});

export const setManifestFetchResponse = (resp) => ({
  type: SET_MANIFEST_FETCH_RESPONSE,
  payload: resp
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
  dispatch(setManifestFetchResponse(null));
  dispatch(setManifestFetchStatus(MANIFEST_FETCH_STATUS_LOADING));
};
