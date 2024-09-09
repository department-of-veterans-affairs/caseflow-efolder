import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import StatusMessage from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/StatusMessage';

import {
  clearErrorMessage,
  resetDefaultManifestState,
  setManifestId
} from '../actions';
import { pollManifestFetchEndpoint, restartManifestFetch } from '../apiActions';
import DownloadPageFooter from '../components/DownloadPageFooter';
import DownloadPageHeader from '../components/DownloadPageHeader';
import PageLoadingIndicator from '../components/PageLoadingIndicator';
import { MANIFEST_DOWNLOAD_STATE } from '../Constants';
import DownloadListContainer from './DownloadListContainer';
import DownloadProgressContainer from './DownloadProgressContainer';
import { documentDownloadStarted, manifestFetchComplete } from '../Utils';

class DownloadContainer extends React.PureComponent {
  componentDidMount() {
    // Clear all previous error messages. The only errors we care about will happen after this component has mounted.
    this.props.clearErrorMessage();

    const manifestId = this.props.match.params.manifestId;
    let forceManifestRequest = false;

    if (this.props.manifestId && this.props.manifestId !== manifestId) {
      forceManifestRequest = true;
      this.props.resetDefaultManifestState();
    }

    this.props.setManifestId(manifestId);

    if (forceManifestRequest ||
      !manifestFetchComplete(this.props.documentSources) ||
      this.props.documentsFetchStatus === MANIFEST_DOWNLOAD_STATE.IN_PROGRESS
    ) {
      this.props.restartManifestFetch(manifestId, this.props.csrfToken);
      this.props.pollManifestFetchEndpoint(0, manifestId, this.props.csrfToken);
    }
  }

  render() {
    let pageBody = <React.Fragment>
      <AppSegment filledBackground>
        <PageLoadingIndicator>We are gathering the list of files in the eFolder now...</PageLoadingIndicator>
      </AppSegment>
      <DownloadPageFooter />
    </React.Fragment>;

    if (this.props.errorMessage.title) {
      pageBody = <React.Fragment>
        <StatusMessage title={this.props.errorMessage.title}>{this.props.errorMessage.message}</StatusMessage>
        <DownloadPageFooter />
      </React.Fragment>;
    } else if (documentDownloadStarted(this.props.documentsFetchStatus)) {
      pageBody = <DownloadProgressContainer />;
    } else if (manifestFetchComplete(this.props.documentSources)) {
      if (this.props.documents.length) {
        pageBody = <DownloadListContainer />;
      } else {
        pageBody = <React.Fragment>
          <AppSegment filledBackground>
            <h1 className="cf-msg-screen-heading">No Documents in eFolder</h1>
            <h2 className="cf-msg-screen-deck">
              eFolder Express could not find any documents in the eFolder with Veteran ID #{this.props.veteranId}.
              It's possible this eFolder does not exist.
            </h2>
            <p className="cf-msg-screen-text">
              Please check the Veteran ID number and <Link to="/">search again</Link>.
            </p>
          </AppSegment>
          <DownloadPageFooter />
        </React.Fragment>;
      }
    }

    return <React.Fragment>
      <DownloadPageHeader veteranId={this.props.veteranId} veteranName={this.props.veteranName} />
      { pageBody }
    </React.Fragment>;
  }
}

const mapStateToProps = (state) => ({
  csrfToken: state.csrfToken,
  documents: state.documents,
  documentsFetchStatus: state.documentsFetchStatus,
  documentSources: state.documentSources,
  errorMessage: state.errorMessage,
  manifestId: state.manifestId,
  veteranId: state.veteranId,
  veteranName: state.veteranName
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  pollManifestFetchEndpoint,
  clearErrorMessage,
  resetDefaultManifestState,
  restartManifestFetch,
  setManifestId
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(DownloadContainer);
