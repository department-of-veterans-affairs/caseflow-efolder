import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import { setVeteranId, setVeteranName } from '../actions';
import DocumentListRow from '../components/DocumentListRow';
import DownloadPageFooter from '../components/DownloadPageFooter';
import DownloadPageHeader from '../components/DownloadPageHeader';

const aliasForSource = function(source) {
  if (source === 'VVA') {
    return 'VVA/LCM';
  }

  return source;
};

const formatDateString = function(str) {
  const date = new Date(str);

  // TODO: Current version of efolder displays months and dates with leading zeroes if < 10.
  return `${date.getMonth() + 1}/${date.getDate()}/${date.getFullYear()}`;
};

class DownloadListContainer extends React.PureComponent {
  componentDidMount() {
    const resp = this.props.manifestFetchResponse;

    this.props.setVeteranName(resp.body.data.attributes.veteran_full_name);
    this.props.setVeteranId(resp.headers.http_file_number);
  }

  render() {
    const resp = this.props.manifestFetchResponse;

    const docSources = resp.body.data.attributes.sources;
    const totalDocumentsCount = docSources.reduce((cnt, src) => cnt + src.number_of_documents, 0);
    const documentCountNote = docSources.map((src) => (
      `${src.number_of_documents} from ${aliasForSource(src.source)}`)).join(' and ');

    return <main className="usa-grid">
      <DownloadPageHeader veteranId={this.props.veteranId} veteranName={this.props.veteranName} />

      <AppSegment filledBackground>
        <p>eFolder Express found a total of {totalDocumentsCount} documents ({documentCountNote}) for&nbsp;
          {this.props.veteranName} #{this.props.veteranId}. Verify the Veteran ID and click the&nbsp;
          {this.props.startDownloadButtonLabel} button below to start retrieving the eFolder.
        </p>

        <p>
          <input className="cf-submit cf-retrieve-button" type="submit" value={this.props.startDownloadButtonLabel} />
        </p>

        <div className="ee-document-list">
          <table className="usa-table-borderless ee-documents-table" summary="Files in veteran's eFolder">
            <thead>
              <tr>
                <th className ="document-col" scope="col">Document Type</th>
                <th className ="sources-col" scope="col">Source</th>
                <th className ="upload-col" scope="col">Receipt Date</th>
              </tr>
            </thead>

            <tbody className ="ee-document-scroll" >
              { resp.body.data.attributes.records.map((record) => (
                <DocumentListRow
                  type={record.type_description}
                  source={aliasForSource(record.source)}
                  received_at={formatDateString(record.received_at)}
                  key={record.id}
                />)
              )}
            </tbody>
          </table>
        </div>
      </AppSegment>

      <DownloadPageFooter label={this.props.startDownloadButtonLabel} />
    </main>;
  }
}

const mapStateToProps = (state) => ({
  manifestFetchResponse: state.manifestFetchResponse,
  startDownloadButtonLabel: state.startDownloadButtonLabel,
  veteranId: state.veteranId,
  veteranName: state.veteranName
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setVeteranId,
  setVeteranName
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(DownloadListContainer);
