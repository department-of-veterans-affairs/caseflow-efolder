import * as Actions from './actionTypes';
import { IN_PROGRESS_TAB, MANIFEST_DOWNLOAD_STATE } from './Constants';

const defaultManifestState = {
  activeDownloadProgressTab: IN_PROGRESS_TAB,
  confirmDownloadModalIsVisible: false,
  documents: [],
  documentsFetchCompletionEstimate: '',
  documentsFetchStatus: MANIFEST_DOWNLOAD_STATE.NOT_STARTED,
  documentSources: [],
  veteranId: '',
  veteranName: ''
};

export const initState = {
  errorMessage: '',
  downloadContainerErrorMessage: {
    title: '',
    message: ''
  },
  recentDownloads: [],
  searchInputText: '',
  ...defaultManifestState
};

export default function reducer(state = {}, action = {}) {
  switch (action.type) {

  case Actions.CLEAR_ERROR_MESSAGE:
    return { ...state,
      errorMessage: initState.errorMessage };

  case Actions.CLEAR_DOWNLOAD_CONTAINER_ERROR_MESSAGE:
    return { ...state,
      downloadContainerErrorMessage: initState.downloadContainerErrorMessage };

  case Actions.CLEAR_SEARCH_TEXT:
    return { ...state,
      searchInputText: initState.searchInputText };

  case Actions.HIDE_CONFIRM_DOWNLOAD_MODAL:
    return { ...state,
      confirmDownloadModalIsVisible: false };

  case Actions.RESET_DEFAULT_MANIFEST_STATE:
    return { ...state,
      ...defaultManifestState };

  case Actions.SET_ACTIVE_DOWNLOAD_PROGRESS_TAB:
    return { ...state,
      activeDownloadProgressTab: action.payload };

  case Actions.SET_DOCUMENT_SOURCES:
    return { ...state,
      documentSources: action.payload };

  case Actions.SET_DOCUMENTS:
    return { ...state,
      documents: action.payload };

  case Actions.SET_DOWNLOAD_CONTAINER_ERROR_MESSAGE:
    return { ...state,
      downloadContainerErrorMessage: {
        title: action.payload.title,
        message: action.payload.message } };

  case Actions.SET_DOCUMENTS_FETCH_COMPLETION_ESTIMATE:
    return { ...state,
      documentsFetchCompletionEstimate: action.payload };

  case Actions.SET_DOCUMENTS_FETCH_STATUS:
    return { ...state,
      documentsFetchStatus: action.payload };

  case Actions.SET_ERROR_MESSAGE:
    return { ...state,
      errorMessage: action.payload };

  case Actions.SET_MANIFEST_ID:
    return { ...state,
      manifestId: action.payload };

  case Actions.SET_RECENT_DOWNLOADS:
    return { ...state,
      recentDownloads: action.payload };

  case Actions.SET_SEARCH_TEXT:
    return { ...state,
      searchInputText: action.payload };

  case Actions.SET_VETERAN_ID:
    return { ...state,
      veteranId: action.payload };

  case Actions.SET_VETERAN_NAME:
    return { ...state,
      veteranName: action.payload };

  case Actions.SHOW_CONFIRM_DOWNLOAD_MODAL:
    return { ...state,
      confirmDownloadModalIsVisible: true };

  default:
    return state;
  }
}
