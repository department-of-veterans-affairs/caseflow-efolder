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
import { SUCCESS_TAB } from './Constants';
import { documentDownloadComplete, documentDownloadStarted, manifestFetchComplete } from './Utils';

const setStateFromResponse = (dispatch, resp) => {
  const respAttrs = resp.body.data.attributes;

  dispatch(setDocuments(respAttrs.records));
  dispatch(setDocumentsFetchStatus(respAttrs.fetched_files_status));
  dispatch(setDocumentsFetchCompletionEstimate(respAttrs.time_to_complete));
  dispatch(setDocumentSources(respAttrs.sources));
  dispatch(setVeteranId(respAttrs.file_number));
  dispatch(setVeteranName(`${respAttrs.veteran_first_name} ${respAttrs.veteran_last_name}`));

  if (documentDownloadComplete(respAttrs.fetched_files_status)) {
    dispatch(setActiveDownloadProgressTab(SUCCESS_TAB));
  }
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
      (response) => {
        setStateFromResponse(dispatch, response);

        // Reader polls every second for a maximum of 20 seconds. Match that here.
        let maxRetryCount = 20;
        let retrySleepMilliseconds = 1 * 1000;
        let donePollingFunction = (resp) => manifestFetchComplete(resp.body.data.attributes.sources);
        let onRetriesExhaustedFunction = () => {
          const sleepLengthSeconds = maxRetryCount * retrySleepMilliseconds / 1000;
          const errMsg = `Failed to fetch list of documents within ${sleepLengthSeconds} second time limit`;

          dispatch(setErrorMessage(errMsg));
        };

        if (documentDownloadStarted(response.body.data.attributes.fetched_files_status)) {
          // Poll every 10 seconds for 1 day
          maxRetryCount = 1 * 24 * 60 * 60 / 10;
          retrySleepMilliseconds = 10 * 1000;
          donePollingFunction = (resp) => documentDownloadComplete(resp.body.data.attributes.fetched_files_status);
          onRetriesExhaustedFunction = () => {}; // eslint-disable-line no-empty-function
        }

        if (donePollingFunction(response)) {
          return true;
        }

        if (retryCount < maxRetryCount) {
          setTimeout(() => {
            dispatch(pollManifestFetchEndpoint(retryCount + 1, manifestId, csrfToken));
          }, retrySleepMilliseconds);
        } else {
          onRetriesExhaustedFunction();
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

export const startManifestFetch = (options = {}) => (dispatch) => {
  postRequest('/api/v2/manifests/', options.csrfToken, { FILE_NUMBER: options.veteranId }).
    then(
      (resp) => {
        setStateFromResponse(dispatch, resp);

        const manifestId = resp.body.data.id;

        dispatch(setManifestId(manifestId));
        options.redirectFunction(`/downloads/${manifestId}`);
      },
      (err) => dispatch(setErrorMessage(buildErrorMessageFromResponse(err.response)))
    );
};
