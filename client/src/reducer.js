import * as Actions from './actionTypes';

export default function reducer(state = {}, action = {}) {
  switch (action.type) {

  case Actions.CLEAR_ERROR:
    return { ...state,
      error: null };

  case Actions.SET_ACTIVE_DOWNLOAD_PROGRESS_TAB:
    return { ...state,
      activeDownloadProgressTab: action.payload };

  case Actions.SET_DOCUMENT_SOURCES:
    return { ...state,
      documentSources: action.payload };

  case Actions.SET_DOCUMENTS:
    return { ...state,
      documents: action.payload };

  case Actions.SET_DOCUMENTS_FETCH_COMPLETION_ESTIMATE:
    return { ...state,
      documentsFetchCompletionEstimate: action.payload };

  case Actions.SET_DOCUMENTS_FETCH_STATUS:
    return { ...state,
      documentsFetchStatus: action.payload };

  case Actions.SET_ERROR:
    return { ...state,
      error: action.payload };

  case Actions.SET_MANIFEST_ID:
    return { ...state,
      manifestId: action.payload };

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
