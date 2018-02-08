import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import { startDocumentDownload } from '../apiActions';
import { aliasForSource, formatDateString } from '../Utils';

const startDownloadButtonLabel = 'Start retrieving efolder';

class DownloadListContainer extends React.PureComponent {
  startDownload = (event) => {
    this.props.startDocumentDownload({ csrfToken: this.props.csrfToken,
      manifestId: this.props.manifestId });
    event.preventDefault();
  }

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
            type="submit"
            value={startDownloadButtonLabel}
            onClick={this.startDownload}
          />
        </p>

        <div className="ee-document-list">
          <table className="usa-table-borderless ee-documents-table" summary="Files in veteran's eFolder">
            <thead>
              <tr>
                <th className="document-col" scope="col">Document Type</th>
                <th className="sources-col" scope="col">Source</th>
                <th className="upload-col" scope="col">Receipt Date</th>
              </tr>
            </thead>

            <tbody className="ee-document-scroll" >
              { this.props.documents.map((doc) => (
                <tr key={doc.id}>
                  <td className="document-col">{doc.type_description}</td>
                  <td className="sources-col">{aliasForSource(doc.source)}</td>
                  <td className="upload-col">{formatDateString(doc.received_at)}</td>
                </tr>)
              )}
            </tbody>
          </table>
        </div>
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
