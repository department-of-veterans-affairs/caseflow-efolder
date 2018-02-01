import { UPDATE_SEARCH_TEXT } from './actionTypes';

export default function reducer(state = {}, action = {}) {
  switch (action.type) {
  case UPDATE_SEARCH_TEXT:
    return { ...state,
      searchInputText: action.payload };
  default:
    return state;
  }
}
