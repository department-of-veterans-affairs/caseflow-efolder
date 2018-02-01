import { UPDATE_SEARCH_TEXT } from './actionTypes';

export const updateSearchInputText = (text) => (dispatch) => {
  dispatch({ type: UPDATE_SEARCH_TEXT,
    payload: text });
};
