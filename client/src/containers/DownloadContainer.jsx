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

const DownloadContainer = ({
  csrfToken,
  documents,
  documentsFetchStatus,
  documentSources,
  errorMessage,
  manifestId,
  veteranId,
  veteranName,
  match,
  pollManifestFetchEndpoint,
  clearErrorMessage,
  resetDefaultManifestState,
  restartManifestFetch,
  setManifestId
}) => {
  useEffect(() => {
    clearErrorMessage();

    const currentManifestId = match.params.manifestId;
    let forceManifestRequest = false;

    if (manifestId && manifestId !== currentManifestId) {
      forceManifestRequest = true;
      resetDefaultManifestState();
    }

    setManifestId(currentManifestId);

    if (forceManifestRequest ||
      !manifestFetchComplete(documentSources) ||
      documentsFetchStatus === MANIFEST_DOWNLOAD_STATE.IN_PROGRESS
    ) {
      restartManifestFetch(currentManifestId, csrfToken);
      pollManifestFetchEndpoint(0, currentManifestId, csrfToken);
    }
  }, [manifestId, match.params.manifestId, csrfToken, documentSources, documentsFetchStatus, clearErrorMessage, resetDefaultManifestState, setManifestId, restartManifestFetch, pollManifestFetchEndpoint]);

  let pageBody = <React.Fragment>
    <AppSegment filledBackground>
      <PageLoadingIndicator>We are gathering the list of files in the eFolder now...</PageLoadingIndicator>
    </AppSegment>
    <DownloadPageFooter />
  </React.Fragment>;

  if (errorMessage.title) {
    pageBody = <React.Fragment>
      <StatusMessage title={errorMessage.title}>{errorMessage.message}</StatusMessage>
      <DownloadPageFooter />
    </React.Fragment>;
  } else if (documentDownloadStarted(documentsFetchStatus)) {
    pageBody = <DownloadProgressContainer />;
  } else if (manifestFetchComplete(documentSources)) {
    if (documents.length) {
      pageBody = <DownloadListContainer />;
    } else {
      pageBody = <React.Fragment>
        <AppSegment filledBackground>
          <h1 className="cf-msg-screen-heading">No Documents in eFolder</h1>
          <h2 className="cf-msg-screen-deck">
            eFolder Express could not find any documents in the eFolder with Veteran ID #{veteranId}.
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
    <DownloadPageHeader veteranId={veteranId} veteranName={veteranName} />
    { pageBody }
  </React.Fragment>;
};

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