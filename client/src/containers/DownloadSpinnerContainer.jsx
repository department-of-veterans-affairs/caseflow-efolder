import React from 'react';
import { connect } from 'react-redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import { START_DOWNLOAD_BUTTON_LABEL } from '../Constants';
import DownloadPageFooter from '../components/DownloadPageFooter';
import DownloadPageHeader from '../components/DownloadPageHeader';
import PageLoadingIndicator from '../components/PageLoadingIndicator';

class DownloadSpinnerContainer extends React.PureComponent {
  render() {
    return <React.Fragment>
      <DownloadPageHeader veteranId={this.props.veteranId} veteranName={this.props.veteranName} />

      <AppSegment filledBackground>
        <PageLoadingIndicator>We are gathering the list of files in the eFolder now...</PageLoadingIndicator>
      </AppSegment>

      <DownloadPageFooter label={START_DOWNLOAD_BUTTON_LABEL} />
    </React.Fragment>;
  }
}

const mapStateToProps = (state) => ({
  veteranId: state.veteranId,
  veteranName: state.veteranName
});

export default connect(mapStateToProps)(DownloadSpinnerContainer);
