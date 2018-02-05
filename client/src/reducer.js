import * as Actions from './actionTypes';

export default function reducer(state = {}, action = {}) {
  switch (action.type) {

  case Actions.SET_DOCUMENT_SOURCES:
    return { ...state,
      documentSources: action.payload };

  case Actions.SET_DOCUMENTS:
    return { ...state,
      documents: action.payload };

  case Actions.SET_ERROR_MESSAGE:
    return { ...state,
      errorMessage: action.payload };

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
