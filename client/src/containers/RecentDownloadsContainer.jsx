import React from 'react';
import { connect } from 'react-redux';

class RecentDownloadsContainer extends React.Component {
  render() {
    if (this.props.recentDownloads.length == 0) {
      return null;  
    }


    return <h2 class="ee-recent-searches">History</h2>;
  }
}

const mapStateToProps = (state) => {
  return {
    recentDownloads: state.recentDownloads
  };
};

export default connect(mapStateToProps)(RecentDownloadsContainer);
