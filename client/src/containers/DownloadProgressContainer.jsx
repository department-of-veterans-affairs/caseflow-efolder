import { css } from 'glamor';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import { setActiveDownloadProgressTab } from '../actions';
import { pollManifestFetchEndpoint } from '../apiActions';
import DownloadProgressBanner from '../components/DownloadProgressBanner';
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
import DownloadProgressTable from '../components/DownloadProgressTable';
import { aliasForSource, documentDownloadComplete } from '../Utils';

class DownloadProgressContainer extends React.PureComponent {
  // TODO: Add some request failure handling in here.
  wrapInDownloadLink(element) {
    return <Link href={`/api/v2/manifests/${this.props.manifestId}/zip`}>{element}</Link>;
  }

  inProgressBanner(docs) {
    const percentComplete = 100 * (this.props.documents.length - docs.progress.length) / this.props.documents.length;

    return <React.Fragment>
      <DownloadProgressBanner title='You can close this page at any time.' alertType='info'>
        <p>
          You can close this page at any time and eFolder Express will continue retrieving files in the&nbsp;
          background. View progress and download eFolders from the History on the&nbsp;
          <Link to="/">eFolder Express home page.</Link>
        </p>
        <p>Note: eFolders remain in your History for { EFOLDER_RETENTION_TIME_HOURS } hours.</p>
      </DownloadProgressBanner>

      <h1 {...css({ marginTop: '2rem', textAlign: 'center' })}>Retrieving Files ...</h1>
      <p className="ee-fetching-files">
        Estimated time left: {this.props.documentsFetchCompletionEstimate} ({docs.progress.length} of&nbsp;
        {this.props.documents.length} files remaining)
      </p>

      <div className="progress-bar">
        <span style={{ width: `${percentComplete}%` }}>Progress: {percentComplete}%</span>
      </div>
    </React.Fragment>;
  }

  // TODO: Add caution alert to the download anyway button.
  // TODO: Add action that will kick off the post request again for the "Try retrieving efolder again" button.
  completeBanner(docs) {
    if (docs.failed.length) {
      return <DownloadProgressBanner title="Some files couldn't be added to eFolder" alertType='error'>
        <p>eFolder Express wasn't able to retrieve some files. Click on the 'Errors' tab below to view them</p>
        <p>You can still download the rest of the files by clicking the 'Download anyway' button below.</p>
        <ul className="ee-button-list">
          <li>
            {this.wrapInDownloadLink(<button className="usa-button cf-action-openmodal">Download anyway</button>)}
          </li>
          <li><button className="usa-button usa-button-gray">Try retrieving efolder again</button></li>
        </ul>
      </DownloadProgressBanner>;
    }

    const documentCountNote = this.props.documentSources.map((src) => (
      `${src.number_of_documents} from ${aliasForSource(src.source)}`)).join(' and ');

    return <DownloadProgressBanner title='Success!' alertType='success'>
      <p>
        All of the documents in the VBMS eFolder for #{this.props.veteranId} are ready to download.&nbsp;
        Click the "Download efolder" button below.
      </p>
      <p>This efolder contains {this.props.documents.length} documents: {documentCountNote}.</p>
      { this.wrapInDownloadLink(<button className="usa-button">Download efolder</button>) }
    </DownloadProgressBanner>;
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
    if (!documentDownloadComplete(this.props.documentsFetchStatus)) {
      return <button className="usa-button-disabled ee-right-button">Download efolder</button>;
    }

    if (docs.failed.length) {
      const btn = <button className="usa-button ee-right-button cf-action-openmodal">Download anyway</button>;

      return this.wrapInDownloadLink(btn);
    }

    const btn = <button className="usa-button ee-right-button ee-download-button">Download efolder</button>;

    return this.wrapInDownloadLink(btn);
  }

  render() {
    const documents = {
      progress: this.props.documents.filter((doc) => doc.status === DOCUMENT_DOWNLOAD_STATE.IN_PROGRESS),
      success: this.props.documents.filter((doc) => doc.status === DOCUMENT_DOWNLOAD_STATE.SUCCEEDED),
      failed: this.props.documents.filter((doc) => doc.status === DOCUMENT_DOWNLOAD_STATE.FAILED)
    };

    return <React.Fragment>
      <AppSegment filledBackground>

        { documentDownloadComplete(this.props.documentsFetchStatus) ?
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
