import { css } from 'glamor';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import {
  hideConfirmDownloadModal,
  setActiveDownloadProgressTab,
  showConfirmDownloadModal
} from '../actions';
import { startDocumentDownload } from '../apiActions';
import AlertBanner from '../components/AlertBanner';
import {
  CloseIcon,
  FailedIcon,
  ProgressIcon,
  SuccessIcon
} from '../components/Icons';
import DownloadPageFooter from '../components/DownloadPageFooter';
import {
  EFOLDER_RETENTION_TIME_HOURS,
  ERRORS_TAB,
  IN_PROGRESS_TAB,
  SUCCESS_TAB,
  DOCUMENT_DOWNLOAD_STATE,
  MANIFEST_SOURCE_FETCH_STATE
} from '../Constants';
import DownloadProgressTab from './DownloadProgressTab';
import ManifestDocumentsTable from '../components/ManifestDocumentsTable';
import { aliasForSource, documentDownloadComplete } from '../Utils';

class DownloadProgressContainer extends React.PureComponent {
  startDownloadZip = () => location.assign(`/api/v2/manifests/${this.props.manifestId}/zip`);
  downloadZipAndHideModal = () => {
    this.startDownloadZip();
    this.props.hideConfirmDownloadModal();
  }

  inProgressBanner() {
    const totalDocCount = this.props.documents.length;
    const percentComplete = 100 * (totalDocCount - this.props.documentsForStatus.progress.length) / totalDocCount;

    return <React.Fragment>
      <AlertBanner title="You can close this page at any time." alertType="info">
        <p>
          You can close this page at any time and eFolder Express will continue retrieving files in the&nbsp;
          background. View progress and download eFolders from the History on the&nbsp;
          <Link to="/">eFolder Express home page.</Link>
        </p>
        <p>Note: eFolders remain in your History for { EFOLDER_RETENTION_TIME_HOURS } hours.</p>
      </AlertBanner>

      <h1 {...css({ marginTop: '2rem',
        textAlign: 'center' })}>Retrieving Files ...</h1>
      <p className="ee-fetching-files">
        Estimated time left: {this.props.documentsFetchCompletionEstimate}&nbsp;
        ({this.props.documentsForStatus.progress.length} of {this.props.documents.length} files remaining)
      </p>

      <div className="progress-bar">
        <span style={{ width: `${percentComplete}%` }}>Progress: {percentComplete}%</span>
      </div>
    </React.Fragment>;
  }

  restartDocumentDownload = () => this.props.startDocumentDownload(this.props.manifestId, this.props.csrfToken);

  /* eslint-disable max-statements */
  completeBanner() {
    const successSources = [];
    const failedSources = [];

    // Assume only success or failed status by the time we reach here.
    for (const src of this.props.documentSources) {
      if (src.status === MANIFEST_SOURCE_FETCH_STATE.FAILED) {
        failedSources.push(src.source);
      } else {
        successSources.push(src.source);
      }
    }

    // If any of the document sources are unavailable, display a banner with a specific message about that source.
    if (failedSources.length) {
      const successSourcesString = successSources.join(', ');
      const failedSourcesString = failedSources.join(', ');
      const downloadButtonText = `Download ${successSourcesString} documents`;

      return <AlertBanner
        title={`We could not retrieve ${failedSourcesString} documents at this time`}
        alertType="warning"
      >
        <p>To continue downloading {successSourcesString} files without {failedSourcesString}&nbsp;
          documents, click the ‘{downloadButtonText}' button below.</p>
        <p>You can also try again by clicking the ‘Retry download’ button below or search for another efolder.</p>
        <ul className="ee-button-list">
          <li><button className="usa-button" onClick={this.startDownloadZip}>{downloadButtonText}</button></li>
          <li>
            <button
              className="usa-button-outline"
              onClick={this.restartDocumentDownload}
              {...css({ marginLeft: '2rem' })}
            >
              Retry download
            </button>
          </li>
        </ul>
      </AlertBanner>;
    }

    if (this.props.documentsForStatus.failed.length) {
      return <AlertBanner title="Some files couldn't be added to eFolder" alertType="error">
        <p>eFolder Express wasn't able to retrieve some files. Click on the 'Errors' tab below to view them</p>
        <p>You can still download the rest of the files by clicking the 'Download anyway' button below.</p>
        <ul className="ee-button-list">
          <li>
            <button className="usa-button" onClick={this.props.showConfirmDownloadModal}>Download anyway</button>
          </li>
          <li>
            <button
              className="usa-button-outline"
              onClick={this.restartDocumentDownload}
              {...css({ marginLeft: '2rem' })}
            >
              Retry missing files
            </button>
          </li>
        </ul>
      </AlertBanner>;
    }

    const documentCountNote = this.props.documentSources.map((src) => (
      `${src.number_of_documents} from ${aliasForSource(src.source)}`)).join(' and ');

    return <AlertBanner title="Success!" alertType="success">
      <p>
        All of the documents in the VBMS eFolder for #{this.props.veteranId} are ready to download.&nbsp;
        Click the "Download efolder" button below.
      </p>
      <p>This efolder contains {this.props.documents.length} documents: {documentCountNote}.</p>
      <button className="usa-button" onClick={this.startDownloadZip}>Download efolder</button>
    </AlertBanner>;
  }
  /* eslint-enable max-statements */

  getActiveTable() {
    const summary = 'Status of veteran eFolder file downloads';

    switch (this.props.activeDownloadProgressTab) {
    case SUCCESS_TAB:
      return <ManifestDocumentsTable
        documents={this.props.documentsForStatus.success}
        icon={<SuccessIcon />}
        summary={summary}
      />;
    case ERRORS_TAB:
      return <ManifestDocumentsTable
        documents={this.props.documentsForStatus.failed}
        icon={<FailedIcon />}
        summary={summary}
        showDocumentId
      />;
    case IN_PROGRESS_TAB:
    default:
      return <ManifestDocumentsTable
        documents={this.props.documentsForStatus.progress}
        icon={<ProgressIcon />}
        summary={summary}
      />;
    }
  }

  // TODO: These buttons can probably be factored out in some way... later
  getFooterDownloadButton() {
    if (!documentDownloadComplete(this.props.documentsFetchStatus)) {
      return <button className="usa-button-disabled ee-right-button">Download efolder</button>;
    }

    if (this.props.documentsForStatus.failed.length) {
      return <button
        className="usa-button ee-right-button cf-action-openmodal"
        onClick={this.props.showConfirmDownloadModal}
      >
        Download anyway
      </button>;
    }

    return <button className="usa-button ee-right-button ee-download-button" onClick={this.startDownloadZip}>
      Download efolder
    </button>;
  }

  displayConfirmDownloadModal() {
    return <section
      className="cf-modal active"
      id="confirm-download-anyway"
      role="alertdialog"
      aria-labelledby="confirm-download-anyway-title"
      aria-describedby="confirm-download-anyway-desc"
    >
      <div className="cf-modal-body">
        <button
          type="button"
          aria-label="Close modal"
          className="cf-modal-close cf-action-closemodal cf-modal-startfocus"
          onClick={this.props.hideConfirmDownloadModal}
        >
          <CloseIcon />
        </button>
        <h1 className="cf-modal-title" id="confirm-download-anyway-title">Download incomplete efolder?</h1>
        <p className="cf-modal-normal-text" id="confirm-download-anyway-desc">
          We encountered errors when retrieving some documents and they won’t be included in the eFolder download.&nbsp;
          If you elect to "Download anyway" you may want to retrieve these files individually from VBMS.
        </p>
        <div className="cf-modal-divider"></div>
        <div className="cf-push-row cf-modal-controls">
          <button
            type="button"
            className="usa-button-outline cf-action-closemodal cf-push-left"
            data-controls="#confirm-download-anyway"
            onClick={this.props.hideConfirmDownloadModal}
          >
            Go back
          </button>
          <button className="cf-push-right usa-button usa-button-secondary" onClick={this.downloadZipAndHideModal}>
            Download anyway
          </button>
        </div>
      </div>
    </section>;
  }

  render() {
    return <React.Fragment>
      <AppSegment filledBackground>

        { documentDownloadComplete(this.props.documentsFetchStatus) ? this.completeBanner() : this.inProgressBanner() }

        <div className="cf-tab-navigation">
          <DownloadProgressTab name={IN_PROGRESS_TAB} documentCount={this.props.documentsForStatus.progress.length}>
            <ProgressIcon /> Progress ({this.props.documentsForStatus.progress.length})
          </DownloadProgressTab>

          <DownloadProgressTab name={SUCCESS_TAB} documentCount={this.props.documentsForStatus.success.length}>
            <SuccessIcon /> Completed ({this.props.documentsForStatus.success.length})
          </DownloadProgressTab>

          <DownloadProgressTab name={ERRORS_TAB} documentCount={this.props.documentsForStatus.failed.length}>
            <FailedIcon /> Errors ({this.props.documentsForStatus.failed.length})
          </DownloadProgressTab>
        </div>

        { this.getActiveTable() }
      </AppSegment>

      <DownloadPageFooter>{ this.getFooterDownloadButton() }</DownloadPageFooter>

      { this.props.confirmDownloadModalIsVisible && this.displayConfirmDownloadModal() }

    </React.Fragment>;
  }
}

const mapStateToProps = (state) => ({
  activeDownloadProgressTab: state.activeDownloadProgressTab,
  confirmDownloadModalIsVisible: state.confirmDownloadModalIsVisible,
  csrfToken: state.csrfToken,
  documents: state.documents,
  documentsFetchCompletionEstimate: state.documentsFetchCompletionEstimate,
  documentsFetchStatus: state.documentsFetchStatus,
  documentsForStatus: {
    progress: state.documents.filter((doc) => doc.status === DOCUMENT_DOWNLOAD_STATE.IN_PROGRESS),
    success: state.documents.filter((doc) => doc.status === DOCUMENT_DOWNLOAD_STATE.SUCCEEDED),
    failed: state.documents.filter((doc) => doc.status === DOCUMENT_DOWNLOAD_STATE.FAILED)
  },
  documentSources: state.documentSources,
  manifestId: state.manifestId,
  veteranId: state.veteranId
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  hideConfirmDownloadModal,
  setActiveDownloadProgressTab,
  showConfirmDownloadModal,
  startDocumentDownload
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(DownloadProgressContainer);
