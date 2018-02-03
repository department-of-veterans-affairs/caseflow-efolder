import React from 'react';
import { connect } from 'react-redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import DownloadPageFooter from '../components/DownloadPageFooter';
import DownloadPageHeader from '../components/DownloadPageHeader';
import PageLoadingIndicator from '../components/PageLoadingIndicator';

class DownloadSpinnerContainer extends React.PureComponent {
  render() {
    return <main className="usa-grid">
      <DownloadPageHeader veteranId={this.props.veteranId} veteranName={this.props.veteranName} />

      <AppSegment filledBackground>
        <PageLoadingIndicator>We are gathering the list of files in the eFolder now...</PageLoadingIndicator>
      </AppSegment>

      <DownloadPageFooter label={this.props.startDownloadButtonLabel} />
    </main>;
  }
}

const mapStateToProps = (state) => ({
  veteranId: state.veteranId,
  startDownloadButtonLabel: state.startDownloadButtonLabel,
  veteranName: state.veteranName
});

export default connect(mapStateToProps)(DownloadSpinnerContainer);
