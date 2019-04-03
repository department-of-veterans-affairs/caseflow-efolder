import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import { MANIFEST_DOWNLOAD_STATE } from '../Constants';
import { getDownloadHistory } from '../apiActions';
import { AlertIcon } from '../components/Icons';
import StatusMessage from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/StatusMessage';



const linkText = (status, failedDocCount) => {
  const icon = failedDocCount ? <AlertIcon /> : null;
  const text = status === MANIFEST_DOWNLOAD_STATE.IN_PROGRESS ? 'progress' : 'results';

  return <React.Fragment>{icon} View {text} »</React.Fragment>;
};

class RecentDownloadsContainer extends React.PureComponent {
  componentDidMount() {
    this.props.getDownloadHistory(this.props.csrfToken);
  }

  render() {
    if (!this.props.recentDownloads.length) {
      return <StatusMessage>
        No recent downloads.
        <br />
      <Link to="/">Back to search</Link>
    </StatusMessage>;
    }

    return <div>
      <h2 className="ee-recent-searches">History</h2>
      <table className="usa-table-borderless" summary="List of recent downloads and links to download their contents">
        <thead>
          <tr className="usa-sr-only">
            <th scope="col">File Number</th>
            <th scope="col">Actions</th>
          </tr>
        </thead>
        <tbody>
          { this.props.recentDownloads.map((download) => (
            <tr id={`download-${download.id}`} key={download.id}>
              <td>
                {`${download.attributes.veteran_first_name} ${download.attributes.veteran_last_name}`}
                <span className="cf-subtext"> ({download.attributes.file_number}) - Expires on&nbsp;
                  {download.attributes.zip_expiration_date} </span>
              </td>
              <td className="ee-actions-cell">
                <Link to={`/downloads/${download.id}`}>
                  { linkText(download.attributes.fetched_files_status, download.attributes.number_failed_documents) }
                </Link>
              </td>
            </tr>)
          )}
        </tbody>
      </table>
      <Link to="/">Back to search</Link>
    </div>;
  }
}

const mapStateToProps = (state) => ({
  csrfToken: state.csrfToken,
  recentDownloads: state.recentDownloads
});

const mapDispatchToProps = (dispatch) => bindActionCreators({ getDownloadHistory }, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(RecentDownloadsContainer);
