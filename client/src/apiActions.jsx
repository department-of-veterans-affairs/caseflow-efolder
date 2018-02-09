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

const setStateFromResponse = (resp) => (dispatch) => {
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

const retryPollManifestFetchEndpoint = (retryCount = 0, options = {}) => (dispatch) => {
  if (retryCount < options.maxRetryCount) {
    setTimeout(() => {
      dispatch(pollManifestFetchEndpoint(retryCount + 1, options)); // eslint-disable-line no-use-before-define
    }, options.retrySleepMilliseconds);

    return true;
  }

  return false;
};

const pollDocumentDownload = (retryCount = 0, resp, options = {}) => (dispatch) => {
  const retryOptions = {
    ...options,
    // Poll every 2 seconds for 1 day
    maxRetryCount: 1 * 24 * 60 * 60 / 2,
    retrySleepMilliseconds: 2 * 1000
  };

  if (!documentDownloadComplete(resp.body.data.attributes.fetched_files_status)) {
    dispatch(retryPollManifestFetchEndpoint(retryCount, retryOptions));
  }
};

const pollUntilFetchComplete = (retryCount = 0, resp, options = {}) => (dispatch) => {
  if (manifestFetchComplete(resp.body.data.attributes.sources)) {
    return true;
  }

  const retryOptions = {
    ...options,
    // Reader polls every second for a maximum of 20 seconds. Match that here.
    maxRetryCount: 20,
    retrySleepMilliseconds: 1 * 1000
  };

  if (!dispatch(retryPollManifestFetchEndpoint(retryCount, retryOptions))) {
    const sleepLengthSeconds = retryOptions.maxRetryCount * retryOptions.retrySleepSeconds / 1000;
    const errMsg = `Failed to fetch list of documents within ${sleepLengthSeconds} second time limit`;

    dispatch(setErrorMessage(errMsg));
  }
};

export const pollManifestFetchEndpoint = (retryCount = 0, options = {}) => (dispatch) => {
  getRequest(`/api/v2/manifests/${options.manifestId}`, options.csrfToken).
    then(
      (resp) => {
        dispatch(setStateFromResponse(resp));
        if (documentDownloadStarted(resp.body.data.attributes.fetched_files_status)) {
          dispatch(pollDocumentDownload(retryCount, resp, options));
        } else {
          dispatch(pollUntilFetchComplete(retryCount, resp, options));
        }
      },
      (err) => dispatch(setErrorMessage(buildErrorMessageFromResponse(err.response)))
    );
};

export const startDocumentDownload = (options = {}) => (dispatch) => {
  postRequest(`/api/v2/manifests/${options.manifestId}/files_downloads`, options.csrfToken).
    then(
      (resp) => {
        dispatch(setStateFromResponse(resp));
        dispatch(pollManifestFetchEndpoint(0, options));
      },
      (err) => dispatch(setErrorMessage(buildErrorMessageFromResponse(err.response)))
    );
};

export const startManifestFetch = (options = {}) => (dispatch) => {
  postRequest('/api/v2/manifests/', options.csrfToken, { FILE_NUMBER: options.veteranId }).
    then(
      (resp) => {
        dispatch(setStateFromResponse(resp));

        const manifestId = resp.body.data.id;

        dispatch(setManifestId(manifestId));
        options.redirectFunction(`/downloads/${manifestId}`);
      },
      (err) => dispatch(setErrorMessage(buildErrorMessageFromResponse(err.response)))
    );
};
