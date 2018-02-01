import { UPDATE_SEARCH_TEXT } from './actionTypes';

export const updateSearchInputText = (text) => ({
  type: UPDATE_SEARCH_TEXT,
  payload: text
});
