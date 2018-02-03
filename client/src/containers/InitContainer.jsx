import React from 'react';
import { connect } from 'react-redux';
import { BrowserRouter, Route } from 'react-router-dom';

import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import NavigationBar from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/NavigationBar';

import OutOfServiceContainer from './OutOfServiceContainer';
import HelpContainer from './HelpContainer';
import DownloadContainer from './DownloadContainer';
import WelcomeContainer from './WelcomeContainer';

class InitContainer extends React.PureComponent {
  render() {
    return <BrowserRouter basename="/react">
      <div>
        <NavigationBar
          appName="eFolder Express"
          logoProps={{
            accentColor: '#F0835e',
            overlapColor: '#F0835e'
          }}
          userDisplayName={this.props.userDisplayName}
          dropdownUrls={this.props.dropdownUrls}
          defaultUrl="/">
          <Route exact path="/" component={WelcomeContainer} />
          <Route exact path="/out-of-service" component={OutOfServiceContainer} />
          <Route exact path="/help" component={HelpContainer} />
          <Route exact path="/downloads/:manifestId" component={DownloadContainer} />
        </NavigationBar>
        <Footer
          appName="eFolder Express"
          feedbackUrl={this.props.feedbackUrl} />
      </div>
    </BrowserRouter>;
  }
}

const mapStateToProps = (state) => ({
  dropdownUrls: state.dropdownUrls,
  feedbackUrl: state.feedbackUrl,
  userDisplayName: state.userDisplayName
});

export default connect(mapStateToProps)(InitContainer);
