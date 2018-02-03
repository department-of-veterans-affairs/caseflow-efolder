import * as Actions from './actionTypes';

export default function reducer(state = {}, action = {}) {
  switch (action.type) {

  case Actions.SET_MANIFEST_FETCH_ERROR_MESSAGE:
    return { ...state,
      manifestFetchErrorMessage: action.payload };

  case Actions.SET_MANIFEST_FETCH_RESPONSE:
    return { ...state,
      manifestFetchResponse: action.payload };

  case Actions.SET_MANIFEST_FETCH_STATUS:
    return { ...state,
      manifestFetchStatus: action.payload };

  case Actions.SET_VETERAN_ID:
    return { ...state,
      veteranId: action.payload };

  case Actions.SET_VETERAN_NAME:
    return { ...state,
      veteranName: action.payload };

  case Actions.UPDATE_SEARCH_TEXT:
    return { ...state,
      searchInputText: action.payload };

  default:
    return state;
  }
}
