import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import StatusMessage from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/StatusMessage';

import { setErrorMessage, setManifestId } from '../actions';
import { pollManifestFetchEndpoint } from '../apiActions';
import { MANIFEST_DOWNLOAD_STATE } from '../Constants';
import DownloadPageHeader from '../components/DownloadPageHeader';
import PageLoadingIndicator from '../components/PageLoadingIndicator';
import DownloadListContainer from './DownloadListContainer';
import DownloadProgressContainer from './DownloadProgressContainer';
import { documentDownloadStarted, manifestFetchComplete } from '../Utils';

// TODO: Add modal for confirming that the user wants to download even when the zip does not contain the entire
// list of all documents.
class DownloadContainer extends React.PureComponent {
  componentDidMount() {
    // Clear all previous error messages. The only errors we care about will happen after this component has mounted.
    this.props.setErrorMessage('');

    const manifestId = this.props.match.params.manifestId;

    this.props.setManifestId(manifestId);

    if (!manifestFetchComplete(this.props.documentSources) ||
      this.props.documentsFetchStatus === MANIFEST_DOWNLOAD_STATE.IN_PROGRESS
    ) {
      this.props.pollManifestFetchEndpoint(0, manifestId, this.props.csrfToken);
    }
  }

  getPageBody() {
    if (documentDownloadStarted(this.props.documentsFetchStatus)) {
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
