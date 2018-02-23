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
  let description = '';

  if (resp.body.status) {
    description = ` ${resp.body.status}`;
  } else if (resp.body.errors[0].detail) {
    description = ` ${resp.body.errors[0].detail}`;
  }

  return `${resp.statusCode} (${resp.statusText})${description}`;
};

export const pollManifestFetchEndpoint = (retryCount, manifestId, csrfToken) => (dispatch) => {
  getRequest(`/api/v2/manifests/${manifestId}`, csrfToken).
    then(
      (response) => { // eslint-disable-line max-statements
        setStateFromResponse(dispatch, response);

        // Reader polls every second for a maximum of 20 seconds. Match that here.
        let maxRetryCount = 20;
        let retrySleepMilliseconds = 1 * 1000;
        let donePollingFunction = (resp) => manifestFetchComplete(resp.body.data.attributes.sources);
        const sleepLengthSeconds = maxRetryCount * retrySleepMilliseconds / 1000;
        let retriesExhaustedErrMsg = `Failed to fetch list of documents within ${sleepLengthSeconds} second time limit`;

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
