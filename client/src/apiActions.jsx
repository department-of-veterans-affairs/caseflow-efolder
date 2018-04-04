import request from 'superagent';
import nocache from 'superagent-no-cache';

import {
  setActiveDownloadProgressTab,
  setDocuments,
  setDocumentsFetchCompletionEstimate,
  setDocumentsFetchStatus,
  setDocumentSources,
  setErrorMessage,
  setManifestId,
  setRecentDownloads,
  setVeteranId,
  setVeteranName
} from './actions';
import {
  MANIFEST_DOWNLOAD_STATE,
  ERRORS_TAB,
  IN_PROGRESS_TAB,
  SUCCESS_TAB
} from './Constants';
import { documentDownloadComplete, documentDownloadStarted, manifestFetchComplete } from './Utils';

let currentManifestId = null;

const setStateFromResponse = (dispatch, resp) => {
  const respAttrs = resp.body.data.attributes;

  dispatch(setDocuments(respAttrs.records));
  dispatch(setDocumentsFetchStatus(respAttrs.fetched_files_status));
  dispatch(setDocumentsFetchCompletionEstimate(respAttrs.time_to_complete));
  dispatch(setDocumentSources(respAttrs.sources));
  dispatch(setVeteranId(respAttrs.file_number));
  dispatch(setVeteranName(`${respAttrs.veteran_first_name} ${respAttrs.veteran_last_name}`));

  let activeTab = IN_PROGRESS_TAB;

  switch (respAttrs.fetched_files_status) {
  case MANIFEST_DOWNLOAD_STATE.SUCCEEDED:
    activeTab = SUCCESS_TAB;
    break;
  case MANIFEST_DOWNLOAD_STATE.FAILED:
    activeTab = ERRORS_TAB;
    break;
  default:
    activeTab = IN_PROGRESS_TAB;
    break;
  }
  dispatch(setActiveDownloadProgressTab(activeTab));
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
  let description = `${resp.statusCode} (${resp.statusText})`;

  if (resp.body.status) {
    description = resp.body.status;
  } else if (resp.body.errors[0].detail) {
    description = resp.body.errors[0].detail;
  }

  return description;
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
        const sleepLengthSeconds = maxRetryCount * retrySleepMilliseconds / 1000;
        let retriesExhaustedErrMsg = 'Continuing to fetch list of documents in the background. Stopped checking for ' +
          `updates on the status because we reached the ${sleepLengthSeconds} second time limit. Refresh this pages ` +
          `to check for updates again and start a new ${sleepLengthSeconds} second timer`;

        if (documentDownloadStarted(response.body.data.attributes.fetched_files_status)) {
          // Poll every 2 seconds for 1 day
          const pollFrequencySeconds = 2;

          maxRetryCount = 1 * 24 * 60 * 60 / pollFrequencySeconds;
          retrySleepMilliseconds = pollFrequencySeconds * 1000;
          donePollingFunction = (resp) => documentDownloadComplete(resp.body.data.attributes.fetched_files_status);
          retriesExhaustedErrMsg = 'Failed to complete documents download within 24 hours. ' +
            'Please refresh page to see current download progress';
        }

        if (donePollingFunction(response)) {
          return true;
        }

        if (retryCount < maxRetryCount) {
          setTimeout(() => {
            dispatch(pollManifestFetchEndpoint(retryCount + 1, manifestId, csrfToken));
          }, retrySleepMilliseconds);
        } else {
          dispatch(setErrorMessage(retriesExhaustedErrMsg));
        }
      },
      (err) => dispatch(setErrorMessage(buildErrorMessageFromResponse(err.response)))
    );
};

export const startDocumentDownload = (manifestId, csrfToken) => (dispatch) => {
  postRequest(`/api/v2/manifests/${manifestId}/files_downloads`, csrfToken).
    then(
      (resp) => {
        setStateFromResponse(dispatch, resp);
        dispatch(pollManifestFetchEndpoint(0, manifestId, csrfToken));
      },
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
      (err) => dispatch(setErrorMessage(buildErrorMessageFromResponse(err.response)))
    );
};

export const getDownloadHistory = (csrfToken) => (dispatch) => {
  getRequest('/api/v2/manifests/history', csrfToken).
    then(
      (resp) => dispatch(setRecentDownloads(resp.body.data)),
      (err) => dispatch(setErrorMessage(buildErrorMessageFromResponse(err.response)))
    );
};
