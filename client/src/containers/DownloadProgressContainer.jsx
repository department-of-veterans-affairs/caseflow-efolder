import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import { setActiveDownloadProgressTab } from '../actions';
import { pollManifestFetchEndpoint } from '../apiActions';
import FailedIcon from '../components/FailedIcon';
import ProgressIcon from '../components/ProgressIcon';
import SuccessIcon from '../components/SuccessIcon';
import {
  EFOLDER_RETENTION_TIME_HOURS,
  ERRORS_TAB,
  IN_PROGRESS_TAB,
  SUCCESS_TAB,
  DOCUMENT_DOWNLOAD_IN_PROGRESS_STATUS,
  DOCUMENT_DOWNLOAD_SUCCESS_STATUS,
  DOCUMENT_DOWNLOAD_FAILED_STATUS
} from '../Constants';
import DownloadProgressTab from './DownloadProgressTab';
import DownloadProgressTable from '../components/DownloadProgressTable';
import { aliasForSource } from '../Utils';

// TODO: We don't currently account for the case where there are no documents. This is probably fine.
const documentDownloadComplete = (docs) => {
  for (const doc of docs) {
    if (doc.status === DOCUMENT_DOWNLOAD_IN_PROGRESS_STATUS) {
      return false;
    }
  }

  return true;
};

const stopPollingFunction = (resp, dispatch) => documentDownloadComplete(resp.body.data.attributes.records) && dispatch(setActiveDownloadProgressTab(SUCCESS_TAB));

class DownloadProgressContainer extends React.PureComponent {
  componentDidMount() {
    this.props.setActiveDownloadProgressTab(IN_PROGRESS_TAB);

    const pollOptions = {
      csrfToken: this.props.csrfToken,
      hideErrorAfterRetryComplete: true,
      manifestId: this.props.manifestId,
      maxRetryCount: 2 * 60 / 5,
      retrySleepSeconds: 5,
      stopPollingFunction
    };

    this.props.pollManifestFetchEndpoint(0, pollOptions);
  }

  // TODO: Add some request failure handling in here.
  wrapInDownloadZipForm(element) {
    return <form action={`/api/v2/manifests/${this.props.manifestId}/zip`} method="GET">{element}</form>;
  }

  inProgressBanner(docs) {
    const pctComplete = 100 * (this.props.documents.length - docs.progress.length) / this.props.documents.length;

    return <React.Fragment>
      <div className="usa-alert usa-alert-info" role="alert">
        <div className="usa-alert-body">
          <h2 className="usa-alert-heading">You can close this page at any time.</h2>
          <p className="usa-alert-text">
            You can close this page at any time and eFolder Express will continue retrieving files in the&nbsp;
            background. View progress and download eFolders from the History on the&nbsp;
            <Link to="/">eFolder Express home page.</Link>
          </p>
          <p>Note: eFolders remain in your History for { EFOLDER_RETENTION_TIME_HOURS } hours.</p>
        </div>
      </div>

      <h1 style={{ marginTop: '2rem',
        textAlign: 'center' }}>Retrieving Files ...</h1>
      <p className="ee-fetching-files">
        Estimated time left: {this.props.documentsFetchCompletionEstimate} ({docs.progress.length} of&nbsp;
        {this.props.documents.length} files remaining)
      </p>

      <div className="progress-bar">
        <span style={{ width: `${pctComplete}%` }}>Progress: {pctComplete}%</span>
      </div>
    </React.Fragment>;
  }

  // TODO: Add caution alert to the download anyway button.
  // TODO: Add action that will kick off the post request again for the "Try retrieving efolder again" button.
  completeBanner(docs) {
    if (docs.failed.length) {
      return <div className="usa-alert usa-alert-error" role="alert">
        <div className="usa-alert-body">
          <h2 className="usa-alert-heading">Some files couldn't be added to eFolder</h2>
          <p className="usa-alert-text">
            eFolder Express wasn't able to retrieve some files. Click on the 'Errors' tab below to view them
          </p>
          <p>
            You can still download the rest of the files by clicking the 'Download anyway' button below.
          </p>
          <ul className="ee-button-list">
            <li>
              {this.wrapInDownloadZipForm(<button className="usa-button cf-action-openmodal">Download anyway</button>)}
            </li>
            <li><button className="usa-button usa-button-gray">Try retrieving efolder again</button></li>
          </ul>
        </div>
      </div>;
    }

    const documentCountNote = this.props.documentSources.map((src) => (
      `${src.number_of_documents} from ${aliasForSource(src.source)}`)).join(' and ');

    return <div className="usa-alert usa-alert-success" role="alert">
      <div className="usa-alert-body">
        <h2 className="usa-alert-heading">Success!</h2>
        <p className="usa-alert-text">
          All of the documents in the VBMS eFolder for #{this.props.veteranId} are ready to download.
          Click the "Download efolder" button below.
        </p>
        <p>
          This efolder contains {this.props.documents.length} documents: {documentCountNote}.
        </p>
        { this.wrapInDownloadZipForm(<button className="usa-button">Download efolder</button>) }
      </div>
    </div>;
  }

  getActiveTable(docs) {
    switch (this.props.activeDownloadProgressTab) {
    case SUCCESS_TAB:
      return <DownloadProgressTable documents={docs.success} icon={<SuccessIcon />} />;
    case ERRORS_TAB:
      return <DownloadProgressTable documents={docs.failed} icon={<FailedIcon />} showDocumentId />;
    case IN_PROGRESS_TAB:
    default:
      return <DownloadProgressTable documents={docs.progress} icon={<ProgressIcon />} />;
    }
  }

  // TODO: These buttons can probably be factored out in some way... later
  getFooterDownloadButton(docs) {
    if (!documentDownloadComplete(this.props.documents)) {
      return <button className="usa-button-disabled ee-right-button">Download efolder</button>;
    }

    if (docs.failed.length) {
      return this.wrapInDownloadZipForm(<button className="usa-button ee-right-button cf-action-openmodal">Download anyway</button>);
    }

    return this.wrapInDownloadZipForm(<button className="usa-button ee-right-button ee-download-button">Download efolder</button>);
  }

  render() {
    const documents = {
      progress: this.props.documents.filter((doc) => doc.status === DOCUMENT_DOWNLOAD_IN_PROGRESS_STATUS),
      success: this.props.documents.filter((doc) => doc.status === DOCUMENT_DOWNLOAD_SUCCESS_STATUS),
      failed: this.props.documents.filter((doc) => doc.status === DOCUMENT_DOWNLOAD_FAILED_STATUS)
    };

    return <React.Fragment>
      <AppSegment filledBackground>

        { documentDownloadComplete(this.props.documents) ?
          this.completeBanner(documents) :
          this.inProgressBanner(documents)
        }

        <div className="cf-tab-navigation">
          <DownloadProgressTab name={IN_PROGRESS_TAB} documentCount={documents.progress.length}>
            <ProgressIcon /> Progress ({documents.progress.length})
          </DownloadProgressTab>

          <DownloadProgressTab name={SUCCESS_TAB} documentCount={documents.success.length}>
            <SuccessIcon /> Completed ({documents.success.length})
          </DownloadProgressTab>

          <DownloadProgressTab name={ERRORS_TAB} documentCount={documents.failed.length}>
            <FailedIcon /> Errors ({documents.failed.length})
          </DownloadProgressTab>
        </div>

        { this.getActiveTable(documents) }
      </AppSegment>

      <AppSegment>
        { this.getFooterDownloadButton(documents) }
        <span className="ee-button-align"><Link to="/">Search for another efolder</Link></span>
      </AppSegment>

    </React.Fragment>;
  }
}

const mapStateToProps = (state) => ({
  activeDownloadProgressTab: state.activeDownloadProgressTab,
  documents: state.documents,
  documentsFetchCompletionEstimate: state.documentsFetchCompletionEstimate,
  documentsFetchStatus: state.documentsFetchStatus,
  documentSources: state.documentSources,
  manifestId: state.manifestId,
  veteranId: state.veteranId
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  pollManifestFetchEndpoint,
  setActiveDownloadProgressTab
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(DownloadProgressContainer);
