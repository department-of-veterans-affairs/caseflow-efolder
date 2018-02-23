import { css } from 'glamor';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import { setActiveDownloadProgressTab } from '../actions';
import { startDocumentDownload } from '../apiActions';
import AlertBanner from '../components/AlertBanner';
import DownloadPageFooter from '../components/DownloadPageFooter';
import FailedIcon from '../components/FailedIcon';
import ProgressIcon from '../components/ProgressIcon';
import SuccessIcon from '../components/SuccessIcon';
import {
  EFOLDER_RETENTION_TIME_HOURS,
  ERRORS_TAB,
  IN_PROGRESS_TAB,
  SUCCESS_TAB,
  DOCUMENT_DOWNLOAD_STATE
} from '../Constants';
import DownloadProgressTab from './DownloadProgressTab';
import ManifestDocumentsTable from '../components/ManifestDocumentsTable';
import { aliasForSource, documentDownloadComplete } from '../Utils';

class DownloadProgressContainer extends React.PureComponent {
  // TODO: Add some request failure handling in here.
  wrapInDownloadLink(element) {
    return <Link href={`/api/v2/manifests/${this.props.manifestId}/zip`}>{element}</Link>;
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

  // TODO: Add caution alert to the download anyway button.
  completeBanner() {
    if (this.props.documentsForStatus.failed.length) {
      return <AlertBanner title="Some files couldn't be added to eFolder" alertType="error">
        <p>eFolder Express wasn't able to retrieve some files. Click on the 'Errors' tab below to view them</p>
        <p>You can still download the rest of the files by clicking the 'Download anyway' button below.</p>
        <ul className="ee-button-list">
          <li>
            {this.wrapInDownloadLink(<button className="usa-button cf-action-openmodal">Download anyway</button>)}
          </li>&nbsp;
          <li>
            <button className="usa-button usa-button-gray" onClick={this.restartDocumentDownload}>
              Try retrieving efolder again
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
      { this.wrapInDownloadLink(<button className="usa-button">Download efolder</button>) }
    </AlertBanner>;
  }

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
      const btn = <button className="usa-button ee-right-button cf-action-openmodal">Download anyway</button>;

      return this.wrapInDownloadLink(btn);
    }

    const btn = <button className="usa-button ee-right-button ee-download-button">Download efolder</button>;

    return this.wrapInDownloadLink(btn);
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

    </React.Fragment>;
  }
}

const mapStateToProps = (state) => ({
  activeDownloadProgressTab: state.activeDownloadProgressTab,
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
  setActiveDownloadProgressTab,
  startDocumentDownload
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(DownloadProgressContainer);
