import React from 'react';
import { connect } from 'react-redux';
import { BrowserRouter, Route } from 'react-router-dom';

import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import NavigationBar from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/NavigationBar';

import DownloadContainer from './DownloadContainer';
import HelpContainer from './HelpContainer';
import OutOfServiceContainer from './OutOfServiceContainer';
import UnauthorizedContainer from './UnauthorizedContainer';
import WelcomeContainer from './WelcomeContainer';

class InitContainer extends React.PureComponent {
  render() {
    return <BrowserRouter basename="/">
      <React.Fragment>
        <NavigationBar
          appName="eFolder Express"
          logoProps={{
            accentColor: '#F0835e',
            overlapColor: '#F0835e'
          }}
          userDisplayName={this.props.userDisplayName}
          dropdownUrls={this.props.dropdownUrls}
          defaultUrl="/">
          <main className="usa-grid">
            <Route exact path="/" component={WelcomeContainer} />
            <Route exact path="/downloads/:manifestId" component={DownloadContainer} />
            <Route exact path="/help" component={HelpContainer} />
            <Route exact path="/out-of-service" component={OutOfServiceContainer} />
            <Route path="*" component={UnauthorizedContainer} />
          </main>
        </NavigationBar>
        <Footer
          appName="eFolder Express"
          feedbackUrl={this.props.feedbackUrl} />
      </React.Fragment>
    </BrowserRouter>;
  }
}

const mapStateToProps = (state) => ({
  dropdownUrls: state.dropdownUrls,
  feedbackUrl: state.feedbackUrl,
  userDisplayName: state.userDisplayName
});

export default connect(mapStateToProps)(InitContainer);
