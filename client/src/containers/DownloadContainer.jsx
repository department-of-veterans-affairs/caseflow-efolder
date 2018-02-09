import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import StatusMessage from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/StatusMessage';

import { setErrorMessage, setManifestId } from '../actions';
import { pollManifestFetchEndpoint } from '../apiActions';
import {
  MANIFEST_DOWNLOAD_NOT_STARTED_STATUS,
  MANIFEST_SOURCE_FETCH_NOT_STARTED_STATUS,
  MANIFEST_SOURCE_FETCH_IN_PROGRESS_STATUS
} from '../Constants';
import DownloadPageHeader from '../components/DownloadPageHeader';
import PageLoadingIndicator from '../components/PageLoadingIndicator';
import DownloadListContainer from './DownloadListContainer';
import DownloadProgressContainer from './DownloadProgressContainer';

// Reader polls every second for a maximum of 20 seconds. Match that here.
const MANIFEST_FETCH_SLEEP_TIMEOUT_SECONDS = 1;
const MAX_MANIFEST_FETCH_RETRIES = 20;

// Before the manifest fetch request documentSources will be an empty array. The manifest fetch POST request kicks off
// a job on the backend that should (at the time of this writing) put two items in the documentSources array (one each
// for VVA and VBMS). If either of those document sources have anything other than a finished state, the entire
// manifest fetch is incomplete.
const manifestFetchComplete = (sources) => {
  if (!sources.length) {
    return false;
  }

  for (const src of sources) {
    if ([MANIFEST_SOURCE_FETCH_NOT_STARTED_STATUS, MANIFEST_SOURCE_FETCH_IN_PROGRESS_STATUS].includes(src.status)) {
      return false;
    }
  }

  return true;
};

const stopPollingFunction = (resp, dispatch) => manifestFetchComplete(resp.body.data.attributes.sources);

// TODO: Add modal for confirming that the user wants to download even when the zip does not contain the entire
// list of all documents.
class DownloadContainer extends React.PureComponent {
  componentDidMount() {
    // Clear all previous error messages. The only errors we care about will happen after this component has mounted.
    this.props.setErrorMessage('');

    const manifestId = this.props.match.params.manifestId;
    this.props.setManifestId(manifestId);

    if (!manifestFetchComplete(this.props.documentSources)) {
      const pollOptions = {
        csrfToken: this.props.csrfToken,
        manifestId: manifestId,
        maxRetryCount: MAX_MANIFEST_FETCH_RETRIES,
        retrySleepSeconds: MANIFEST_FETCH_SLEEP_TIMEOUT_SECONDS,
        stopPollingFunction
      };

      this.props.pollManifestFetchEndpoint(0, pollOptions);
    }
  }

  getPageBody() {
    if (this.props.documentsFetchStatus && this.props.documentsFetchStatus !== MANIFEST_DOWNLOAD_NOT_STARTED_STATUS) {
      return <DownloadProgressContainer />;
    }

    if (manifestFetchComplete(this.props.documentSources)) {
      return <DownloadListContainer />;
    }

    return <AppSegment filledBackground>
      <PageLoadingIndicator>We are gathering the list of files in the eFolder now...</PageLoadingIndicator>
    </AppSegment>;
  }

  render() {
    if (this.props.errorMessage) {
      return <StatusMessage title="Could not fetch manifest">{this.props.errorMessage}</StatusMessage>;
    }

    return <React.Fragment>
      <DownloadPageHeader veteranId={this.props.veteranId} veteranName={this.props.veteranName} />
      { this.getPageBody() }
    </React.Fragment>;
  }
}

const mapStateToProps = (state) => ({
  csrfToken: state.csrfToken,
  documentsFetchStatus: state.documentsFetchStatus,
  documentSources: state.documentSources,
  errorMessage: state.errorMessage,
  manifestId: state.manifestId,
  veteranId: state.veteranId,
  veteranName: state.veteranName
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  pollManifestFetchEndpoint,
  setErrorMessage,
  setManifestId
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(DownloadContainer);
