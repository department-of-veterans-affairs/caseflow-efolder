import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import AlertBanner from '../components/AlertBanner';
import { startDocumentDownload } from '../apiActions';
import ManifestDocumentsTable from '../components/ManifestDocumentsTable';
import DownloadPageFooter from '../components/DownloadPageFooter';
import { MANIFEST_SOURCE_FETCH_STATE } from '../Constants';
import { aliasForSource } from '../Utils';

const startDownloadButtonLabel = 'Start retrieving efolder';

class DownloadListContainer extends React.PureComponent {
  startDownload = () => this.props.startDocumentDownload(this.props.manifestId, this.props.csrfToken);

  render() {
    let totalDocumentsCount = 0;
    const documentCountDescriptions = [];
    const unavailableDocumentSources = [];

    for (const src of this.props.documentSources) {
      totalDocumentsCount += src.number_of_documents;
      documentCountDescriptions.push(`${src.number_of_documents} from ${aliasForSource(src.source)}`);
      if (src.status === MANIFEST_SOURCE_FETCH_STATE.FAILED) {
        unavailableDocumentSources.push(src.source);
      }
    }

    const unavailableSourceText = unavailableDocumentSources.join(', ');

    return <React.Fragment>
      <AppSegment filledBackground>
        { unavailableSourceText &&
          <AlertBanner title={`Can't connect to ${unavailableSourceText}`} alertType="warning">
            <p>Please give {unavailableSourceText} a few moments to come back online,
              then try searching for the eFolder again.</p>
            <p><Link to="/">Try again</Link></p>
          </AlertBanner>
        }

        <p>eFolder Express found a total of {totalDocumentsCount} documents ({documentCountDescriptions.join(' and ')})
          for {this.props.veteranName} #{this.props.veteranId}. Verify the Veteran ID and click the&nbsp;
          {startDownloadButtonLabel} button below to start retrieving the eFolder.
        </p>
        <p>
          <button className="cf-submit cf-retrieve-button" onClick={this.startDownload}>
            {startDownloadButtonLabel}
          </button>
        </p>
        <ManifestDocumentsTable documents={this.props.documents} summary="Files in veteran's eFolder" />
      </AppSegment>
      <DownloadPageFooter>
        <button className="cf-submit cf-retrieve-button ee-right-button" onClick={this.startDownload}>
          {startDownloadButtonLabel}
        </button>
      </DownloadPageFooter>
    </React.Fragment>;
  }
}

const mapStateToProps = (state) => ({
  csrfToken: state.csrfToken,
  documents: state.documents,
  documentSources: state.documentSources,
  manifestId: state.manifestId,
  veteranId: state.veteranId,
  veteranName: state.veteranName
});

const mapDispatchToProps = (dispatch) => bindActionCreators({ startDocumentDownload }, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(DownloadListContainer);
