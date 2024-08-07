import request from 'superagent';
import nocache from 'superagent-no-cache';

import {
  setActiveDownloadProgressTab,
  setDocuments,
  setDocumentsFetchCompletionEstimate,
  setDocumentsFetchStatus,
  setDocumentSources,
  setErrorMessage,
  setShowUnauthorizedVeteranMessage,
  setManifestId,
  setRecentDownloads,
  setVeteranId,
  setVeteranName
} from './actions';
import {
  DOCUMENT_DOWNLOAD_STATE,
  ERRORS_TAB,
  SUCCESS_TAB,
  IN_PROGRESS_TAB
} from './Constants';
import { documentDownloadComplete, documentDownloadStarted, manifestFetchComplete } from './Utils';

let currentManifestId = null;

const setActiveTab = (dispatch, respAttrs) => {
  const failedRecords = respAttrs.records.some((record) => record.status === DOCUMENT_DOWNLOAD_STATE.FAILED);
  const pendingRecords = respAttrs.records.some((record) => record.status === DOCUMENT_DOWNLOAD_STATE.IN_PROGRESS);
  const allPendingRecords = respAttrs.records.every((record) => record.status === DOCUMENT_DOWNLOAD_STATE.IN_PROGRESS);

  // When all the records are pending, the pending tab will be selected. Once a single document is completed or
  // failed the user can choose any tab. Once the download is complete either the completed tab (if there are no errors)
  // or the error tab (if there are any errors) is automatically selected for the user. Then the user can switch
  // to any tab with documents.
  if (allPendingRecords) {
    dispatch(setActiveDownloadProgressTab(IN_PROGRESS_TAB));
  } else if (!pendingRecords) {
    if (failedRecords) {
      dispatch(setActiveDownloadProgressTab(ERRORS_TAB));
    } else {
      dispatch(setActiveDownloadProgressTab(SUCCESS_TAB));
    }
  }
};

const setStateFromResponse = (dispatch, resp) => {
  const respAttrs = resp.body.data.attributes;

  dispatch(setDocuments(respAttrs.records));
  dispatch(setDocumentsFetchStatus(respAttrs.fetched_files_status));
  dispatch(setDocumentsFetchCompletionEstimate(respAttrs.time_to_complete));
  dispatch(setDocumentSources(respAttrs.sources));
  dispatch(setVeteranId(respAttrs.file_number));
  dispatch(setVeteranName(`${respAttrs.veteran_first_name} ${respAttrs.veteran_last_name}`));

  setActiveTab(dispatch, respAttrs);
};

const baseRequest = (endpoint, csrfToken, method, options = {}) => {
  const headers = {
    Accept: 'application/json',
    'Content-Type': 'application/json',
    'X-CSRF-Token': csrfToken,
    ...options
  };

  return request[method](endpoint).set(headers).
    send().
    use(nocache);
};
const getRequest = (endpoint, csrfToken, options) => baseRequest(endpoint, csrfToken, 'get', options);
const postRequest = (endpoint, csrfToken, options) => baseRequest(endpoint, csrfToken, 'post', options);

const buildErrorMessageFromResponse = (resp) => {
  let message = `${resp.statusCode} (${resp.statusText})`;

  if (resp.body.status) {
    message = resp.body.status;
  } else if (resp.body.errors[0].detail) {
    message = resp.body.errors[0].detail;
  }

  return {
    title: 'An unexpected error occurred',
    message: `Error message: ${message} Please try again and if you continue to see an error, submit a support ticket.`
  };
};

export const pollManifestFetchEndpoint = (retryCount = 0, manifestId, csrfToken) => (dispatch) => {
  // When a user attempts to download multiple case files, we end up in a state where we
  // have multiple case files polling at the same time. We then alternate updating the UI
  // between the multiple case files. This code checks to see if this is the first call to
  // polling, if it is, then we set the currentManifestId. If in a future poll we find that
  // the currentManifestId is set to a new manifestId then we know a user has moved on to
  // a new case file and we cancel this manifest's polling.
  if (retryCount > 0 && currentManifestId !== manifestId) {
    return;
  }

  currentManifestId = manifestId;

  getRequest(`/api/v2/manifests/${manifestId}`, csrfToken).
    then(
      (response) => { // eslint-disable-line max-statements
        setStateFromResponse(dispatch, response);

        // efolder #959: Large efolders can take more than 20 seconds to fetch manifests. Set timeout to 90 seconds
        // so we have more than enough time to fetch these large efolders.
        let maxRetryCount = 90;
        let retrySleepMilliseconds = 1 * 1000;

        let donePollingFunction = (resp) => manifestFetchComplete(resp.body.data.attributes.sources);

        const respAttrs = response.body.data.attributes;
        let bannerTitle = 'Currently fetching the list of documents';
        let bannerMsg = 'The list of documents is being fetched from ' +
          `${respAttrs.veteran_first_name} ${respAttrs.veteran_last_name}'s ` +
          'eFolder in the background. If the list of documents does not display after 2 minutes, ' +
          'please refresh the page to check again.';

        if (documentDownloadStarted(respAttrs.fetched_files_status)) {
          // Poll every 2 seconds for 1 day
          const pollFrequencySeconds = 2;

          maxRetryCount = 1 * 24 * 60 * 60 / pollFrequencySeconds;
          retrySleepMilliseconds = pollFrequencySeconds * 1000;
          donePollingFunction = (resp) => documentDownloadComplete(resp.body.data.attributes.fetched_files_status);
          bannerTitle = 'Timed out trying to download the eFolder';
          bannerMsg = `Failed to download ${respAttrs.veteran_first_name} ${respAttrs.veteran_last_name}'s ` +
            'eFolder after trying for 24 hours. ' +
            'Please refresh the page to try again.';
        }

        if (donePollingFunction(response)) {
          return true;
        }

        if (retryCount < maxRetryCount) {
          setTimeout(() => {
            dispatch(pollManifestFetchEndpoint(retryCount + 1, manifestId, csrfToken));
          }, retrySleepMilliseconds);
        } else {
          dispatch(setErrorMessage({ title: bannerTitle, message: bannerMsg }));
        }
      }, (err) => dispatch(setErrorMessage(buildErrorMessageFromResponse(err.response)))
    );
};

export const startDocumentDownload = (manifestId, csrfToken) => (dispatch) => {
  postRequest(`/api/v2/manifests/${manifestId}/files_downloads`, csrfToken).
    then(
      (resp) => {
        setStateFromResponse(dispatch, resp);
        dispatch(pollManifestFetchEndpoint(0, manifestId, csrfToken));
      }, (err) => dispatch(setErrorMessage(buildErrorMessageFromResponse(err.response)))
    );
};

export const restartManifestFetch = (manifestId, csrfToken) => (dispatch) => {
  postRequest(`/api/v2/manifests/${manifestId}`, csrfToken).
    then(
      (resp) => setStateFromResponse(dispatch, resp),
      (err) => dispatch(setErrorMessage(buildErrorMessageFromResponse(err.response)))
    );
};

export const startManifestFetch = (veteranId, csrfToken, redirectFunction) => (dispatch) => {
  postRequest('/api/v2/manifests/', csrfToken, { 'FILE-NUMBER': veteranId }).
    then(
      (resp) => {
        setStateFromResponse(dispatch, resp);

        const manifestId = resp.body.data.id;

        dispatch(setManifestId(manifestId));
        redirectFunction(`/downloads/${manifestId}`);
      },
      (err) => {
        if (err.response.statusCode === 403) {
          dispatch(setShowUnauthorizedVeteranMessage(true));
        } else {
          dispatch(setErrorMessage(buildErrorMessageFromResponse(err.response)));
        }
      }
    );
};

export const getDownloadHistory = (csrfToken) => (dispatch) => {
  getRequest('/api/v2/manifests/history', csrfToken).
    then(
      (resp) => dispatch(setRecentDownloads(resp.body.data)),
      (err) => dispatch(setErrorMessage(buildErrorMessageFromResponse(err.response)))
    );
};
