import React from 'react';
import { connect } from 'react-redux';

import RecentDownloadRow from '../components/RecentDownloadRow';

class RecentDownloadsContainer extends React.PureComponent {
  render() {
    if (this.props.recentDownloads.length === 0) {
      return null;
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
          {this.props.recentDownloads.map((dl, i) => <RecentDownloadRow download={dl} key={i} />)}
        </tbody>
      </table>
    </div>;
  }
}

const mapStateToProps = (state) => {
  return {
    recentDownloads: state.recentDownloads
  };
};

export default connect(mapStateToProps)(RecentDownloadsContainer);
