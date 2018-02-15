import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import { startDocumentDownload } from '../apiActions';
import ManifestDocumentsTable from '../components/ManifestDocumentsTable';
import { aliasForSource } from '../Utils';

const startDownloadButtonLabel = 'Start retrieving efolder';

class DownloadListContainer extends React.PureComponent {
  startDownload = () => this.props.startDocumentDownload(this.props.manifestId, this.props.csrfToken);

  render() {
    const totalDocumentsCount = this.props.documentSources.reduce((cnt, src) => cnt + src.number_of_documents, 0);
    const documentCountNote = this.props.documentSources.map((src) => (
      `${src.number_of_documents} from ${aliasForSource(src.source)}`)).join(' and ');

    return <React.Fragment>
      <AppSegment filledBackground>
        <p>eFolder Express found a total of {totalDocumentsCount} documents ({documentCountNote}) for&nbsp;
          {this.props.veteranName} #{this.props.veteranId}. Verify the Veteran ID and click the&nbsp;
          {startDownloadButtonLabel} button below to start retrieving the eFolder.
        </p>

        <p>
          <input
            className="cf-submit cf-retrieve-button"
            type="button"
            value={startDownloadButtonLabel}
            onClick={this.startDownload}
          />
        </p>

        <ManifestDocumentsTable documents={this.props.documents} summary="Files in veteran's eFolder" />

      </AppSegment>

      <AppSegment>
        <input
          className="cf-submit cf-retrieve-button ee-right-button"
          type="submit"
          value={startDownloadButtonLabel}
          onClick={this.startDownload}
        />
        <Link to="/" className="ee-button-align">Start over</Link>
      </AppSegment>
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
