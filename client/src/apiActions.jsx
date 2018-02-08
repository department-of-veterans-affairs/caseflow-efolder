import request from 'superagent';
import nocache from 'superagent-no-cache';

import {
  setDocuments,
  setDocumentsFetchCompletionEstimate,
  setDocumentsFetchStatus,
  setDocumentSources,
  setErrorMessage,
  setManifestId,
  setVeteranId,
  setVeteranName
} from './actions';

const setStateFromResponse = (resp) => (dispatch) => {
  const respAttrs = resp.body.data.attributes;

  dispatch(setDocuments(respAttrs.records));
  dispatch(setDocumentsFetchStatus(respAttrs.fetched_files_status));
  dispatch(setDocumentsFetchCompletionEstimate(respAttrs.time_to_complete));
  dispatch(setDocumentSources(respAttrs.sources));
  dispatch(setVeteranId(respAttrs.file_number));
  dispatch(setVeteranName(`${respAttrs.veteran_first_name} ${respAttrs.veteran_last_name}`));
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

export const pollManifestFetchEndpoint = (retryCount = 0, options = {}) => (dispatch) => {
  getRequest(`/api/v2/manifests/${options.manifestId}`, options.csrfToken).
    then(
      (resp) => {
        dispatch(setStateFromResponse(resp));

        if (options.stopPollingFunction(resp, dispatch)) {
          return true;
        }

        if (retryCount < options.maxRetryCount) {
          setTimeout(() => {
            dispatch(pollManifestFetchEndpoint(retryCount + 1, options));
          }, options.retrySleepSeconds * 1000);
        } else {
          const sleepLengthSeconds = options.maxRetryCount * options.retrySleepSeconds;
          const errMsg = `Failed to ${options.jobDescription} within ${sleepLengthSeconds} second time limit`;

          dispatch(setErrorMessage(errMsg));
        }
      },
      (err) => dispatch(setErrorMessage(buildErrorMessageFromResponse(err.response)))
    );
};

export const startDocumentDownload = (options = {}) => (dispatch) => {
  postRequest(`/api/v2/manifests/${options.manifestId}/files_downloads`, options.csrfToken).
    then(
      (resp) => dispatch(setStateFromResponse(resp)),
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
