import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import request from 'superagent';
import nocache from 'superagent-no-cache';

import StatusMessage from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/StatusMessage';

import {
  clearManifestFetchState,
  setManifestFetchErrorMessage,
  setManifestFetchResponse,
  setManifestFetchStatus
} from '../actions';
import {
  MANIFEST_FETCH_STATUS_LOADING,
  MANIFEST_FETCH_STATUS_LISTED,
  // MANIFEST_FETCH_STATUS_DOWNLOADING,
  // MANIFEST_FETCH_STATUS_COMPLETE,
  MANIFEST_FETCH_STATUS_ERRORED
} from '../Constants';
import DownloadListContainer from './DownloadListContainer';
import DownloadSpinnerContainer from './DownloadSpinnerContainer';

// Reader polls every second for a maximum of 20 seconds. Match that here.
const MANIFEST_FETCH_SLEEP_TIMEOUT_SECONDS = 1;
const MAX_MANIFEST_FETCH_RETRIES = 20;

// TODO: Add modal for confirming that the user wants to download even when the zip does not contain the entire
// list of all documents.
class DownloadContainer extends React.PureComponent {
  componentDidMount() {
    this.props.clearManifestFetchState();
    this.pollManifestFetchEndpoint(0);
  }

  pollManifestFetchEndpoint(retryCnt = 0) {
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
          if (resp.body.data.attributes.manifest_fetch_complete === false) {
            if (retryCnt < MAX_MANIFEST_FETCH_RETRIES) {
              const sleepTime = MANIFEST_FETCH_SLEEP_TIMEOUT_SECONDS * 1000;

              setTimeout(() => {
                this.pollManifestFetchEndpoint(retryCnt + 1);
              }, sleepTime);
            } else {
              const sleepLengthSeconds = MAX_MANIFEST_FETCH_RETRIES * MANIFEST_FETCH_SLEEP_TIMEOUT_SECONDS;
              const errMsg = `Manifest fetch timed out after ${sleepLengthSeconds} seconds`;

              this.props.setManifestFetchErrorMessage(errMsg);
              this.props.setManifestFetchStatus(MANIFEST_FETCH_STATUS_ERRORED);
            }
          } else {
            this.props.setManifestFetchResponse(resp);
            this.props.setManifestFetchStatus(MANIFEST_FETCH_STATUS_LISTED);
          }
        },
        (err) => {
          const errMsg = `${err.response.statusCode} (${err.response.statusText}) ${err.response.body.status}`;

          this.props.setManifestFetchErrorMessage(errMsg);
          this.props.setManifestFetchStatus(MANIFEST_FETCH_STATUS_ERRORED);
        }
      );
  }

  // TODO: Make the DownloadListContainer work.

  render() {
    switch (this.props.manifestFetchStatus) {
    case MANIFEST_FETCH_STATUS_LISTED:
      return <DownloadListContainer />;
    case MANIFEST_FETCH_STATUS_ERRORED:
      return <main className="usa-grid">
        <StatusMessage title="Could not fetch manifest">{this.props.manifestFetchErrorMessage}</StatusMessage>
      </main>;
    // TODO: Add display for in progress.
    // TODO: Add display for download complete.
    // case MANIFEST_FETCH_STATUS_DOWNLOADING:
    // case MANIFEST_FETCH_STATUS_COMPLETE:
    case MANIFEST_FETCH_STATUS_LOADING:
    default:
      return <DownloadSpinnerContainer />;
    }
  }
}

const mapStateToProps = (state) => ({
  csrfToken: state.csrfToken,
  manifestFetchResponse: state.manifestFetchResponse,
  manifestFetchErrorMessage: state.manifestFetchErrorMessage,
  manifestFetchStatus: state.manifestFetchStatus
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearManifestFetchState,
  setManifestFetchErrorMessage,
  setManifestFetchResponse,
  setManifestFetchStatus
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(DownloadContainer);
