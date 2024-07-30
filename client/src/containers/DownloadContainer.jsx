import React, { useEffect } from 'react';
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

const DownloadContainer = (props) => {
  useEffect(() => {
    // Clear all previous error messages. The only errors we care about will happen after this component has mounted.
    props.clearErrorMessage();

    const manifestId = props.match.params.manifestId;
    let forceManifestRequest = false;

    if (props.manifestId && props.manifestId !== manifestId) {
      forceManifestRequest = true;
      props.resetDefaultManifestState();
    }

    props.setManifestId(manifestId);

    if (forceManifestRequest ||
      !manifestFetchComplete(props.documentSources) ||
      props.documentsFetchStatus === MANIFEST_DOWNLOAD_STATE.IN_PROGRESS
    ) {
      props.restartManifestFetch(manifestId, props.csrfToken);
      props.pollManifestFetchEndpoint(0, manifestId, props.csrfToken);
    }
  }, []);

    let pageBody = <React.Fragment>
      <AppSegment filledBackground>
        <PageLoadingIndicator>We are gathering the list of files in the eFolder now...</PageLoadingIndicator>
      </AppSegment>
      <DownloadPageFooter />
    </React.Fragment>;

    if (props.errorMessage.title) {
      pageBody = <React.Fragment>
        <StatusMessage title={props.errorMessage.title}>{props.errorMessage.message}</StatusMessage>
        <DownloadPageFooter />
      </React.Fragment>;
    } else if (documentDownloadStarted(props.documentsFetchStatus)) {
      pageBody = <DownloadProgressContainer />;
    } else if (manifestFetchComplete(props.documentSources)) {
      if (props.documents.length) {
        pageBody = <DownloadListContainer />;
      } else {
        pageBody = <React.Fragment>
          <AppSegment filledBackground>
            <h1 className="cf-msg-screen-heading">No Documents in eFolder</h1>
            <h2 className="cf-msg-screen-deck">
              eFolder Express could not find any documents in the eFolder with Veteran ID #{props.veteranId}.
              It's possible eFolder does not exist.
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
      <DownloadPageHeader veteranId={props.veteranId} veteranName={props.veteranName} />
      { pageBody }
    </React.Fragment>;
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
