import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import request from 'superagent';
import nocache from 'superagent-no-cache';

import StatusMessage from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/StatusMessage';

import {
  clearManifestFetchState,
  setDocuments,
  setDocumentSources,
  setErrorMessage,
  setManifestFetchResponse,
  setManifestFetchStatus,
  setVeteranId,
  setVeteranName
} from '../actions';
import DownloadListContainer from './DownloadListContainer';
import DownloadSpinnerContainer from './DownloadSpinnerContainer';

// Reader polls every second for a maximum of 20 seconds. Match that here.
const MANIFEST_FETCH_SLEEP_TIMEOUT_SECONDS = 1;
const MAX_MANIFEST_FETCH_RETRIES = 20;

// Before the manifest fetch request documentSources will be an empty array. The manifest fetch POST request kicks off
// a job on the backend that should (at the time of this writing) put two items in the documentSources array (one each
// for VVA and VBMS). If either of those document sources have anything other than a finished state, the entire
// manifest fetch is incomplete.
const manifestFetchComplete = (sources) => {
  if (!sources) {
    return false;
  }

  for (const src of sources) {
    if (['initialized', 'pending'].includes(src.status)) {
      return false;
    }
  }

  return true;
};

const buildErrorMessageFromResponse = (resp) => {
  let description = '';

  if (resp.body.status) {
    description = ` ${resp.body.status}`;
  } else if (resp.body.errors[0].detail) {
    description = ` ${resp.body.errors[0].detail}`;
  }

  return `${resp.statusCode} (${resp.statusText})${description}`;
};

// TODO: Add modal for confirming that the user wants to download even when the zip does not contain the entire
// list of all documents.
class DownloadContainer extends React.PureComponent {
  componentDidMount() {
    if (!manifestFetchComplete(this.props.documentSources)) {
      this.pollManifestFetchEndpoint(0);
    }
  }

  pollManifestFetchEndpoint(retryCount = 0) {
    const headers = {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      'X-CSRF-Token': this.props.csrfToken
    };

    request.
      get(`/api/v2/manifests/${this.props.match.params.manifestId}`).
      set(headers).
      send().
      use(nocache).
      then(
        (resp) => {
          const respAttrs = resp.body.data.attributes;

          if (manifestFetchComplete(respAttrs.sources)) {
            this.props.setDocuments(respAttrs.records);
            this.props.setDocumentSources(respAttrs.sources);
            this.props.setVeteranId(respAttrs.file_number);
            this.props.setVeteranName(`${respAttrs.veteran_first_name} ${respAttrs.veteran_last_name}`);
          } else if (retryCount < MAX_MANIFEST_FETCH_RETRIES) {
            const sleepTimeMs = MANIFEST_FETCH_SLEEP_TIMEOUT_SECONDS * 1000;

            setTimeout(() => {
              this.pollManifestFetchEndpoint(retryCount + 1);
            }, sleepTimeMs);
          } else {
            const sleepLengthSeconds = MAX_MANIFEST_FETCH_RETRIES * MANIFEST_FETCH_SLEEP_TIMEOUT_SECONDS;
            const errMsg = `Failed to fetch list of documents within ${sleepLengthSeconds} second time limit`;

            this.props.setErrorMessage(errMsg);
          }
        },
        (err) => {
          this.props.setErrorMessage(buildErrorMessageFromResponse(err.response));
        }
      );
  }

  // TODO: Add display for in progress.
  // TODO: Add display for download complete.
  render() {
    if (manifestFetchComplete(this.props.documentSources)) {
      return <DownloadListContainer />;
    }
    if (this.props.errorMessage) {
      return <StatusMessage title="Could not fetch manifest">{this.props.errorMessage}</StatusMessage>;
    }

    return <DownloadSpinnerContainer />;
  }
}

const mapStateToProps = (state) => ({
  csrfToken: state.csrfToken,
  documentSources: state.documentSources,
  errorMessage: state.errorMessage
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearManifestFetchState,
  setDocuments,
  setDocumentSources,
  setErrorMessage,
  setManifestFetchResponse,
  setManifestFetchStatus,
  setVeteranId,
  setVeteranName
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(DownloadContainer);
