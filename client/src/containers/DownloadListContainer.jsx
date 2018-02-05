import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import { setVeteranId, setVeteranName } from '../actions';
import DownloadPageFooter from '../components/DownloadPageFooter';
import DownloadPageHeader from '../components/DownloadPageHeader';
import { START_DOWNLOAD_BUTTON_LABEL } from '../Constants';

const aliasForSource = (source) => source === 'VVA' ? 'VVA/LCM' : source;

const formatDateString = (str) => {
  const date = new Date(str);

  return `${date.getMonth() + 1}/${date.getDate()}/${date.getFullYear()}`;
};

class DownloadListContainer extends React.PureComponent {
  render() {
    const resp = this.props.manifestFetchResponse;

    const docSources = resp.body.data.attributes.sources;
    const totalDocumentsCount = docSources.reduce((cnt, src) => cnt + src.number_of_documents, 0);
    const documentCountNote = docSources.map((src) => (
      `${src.number_of_documents} from ${aliasForSource(src.source)}`)).join(' and ');

    return <React.Fragment>
      <DownloadPageHeader veteranId={this.props.veteranId} veteranName={this.props.veteranName} />

      <AppSegment filledBackground>
        <p>eFolder Express found a total of {totalDocumentsCount} documents ({documentCountNote}) for&nbsp;
          {this.props.veteranName} #{this.props.veteranId}. Verify the Veteran ID and click the&nbsp;
          {START_DOWNLOAD_BUTTON_LABEL} button below to start retrieving the eFolder.
        </p>

        <p>
          <input className="cf-submit cf-retrieve-button" type="submit" value={START_DOWNLOAD_BUTTON_LABEL} />
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

            <tbody className="ee-document-scroll" >
              { resp.body.data.attributes.records.map((record) => (
                <tr>
                  <td className="document-col">{record.type_description}</td>
                  <td className="sources-col">{aliasForSource(record.source)}</td>
                  <td className="upload-col">{formatDateString(record.received_at)}</td>
                </tr>)
              )}
            </tbody>
          </table>
        </div>
      </AppSegment>

      <DownloadPageFooter label={START_DOWNLOAD_BUTTON_LABEL} />
    </React.Fragment>;
  }
}

const mapStateToProps = (state) => ({
  manifestFetchResponse: state.manifestFetchResponse,
  veteranId: state.veteranId,
  veteranName: state.veteranName
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setVeteranId,
  setVeteranName
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(DownloadListContainer);
