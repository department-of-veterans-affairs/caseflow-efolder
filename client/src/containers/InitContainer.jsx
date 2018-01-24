import React from 'react';
import { connect } from 'react-redux';
import { BrowserRouter, Route } from 'react-router-dom';

import Footer from '@department-of-veterans-affairs/appeals-frontend-toolkit/components/Footer';
import NavigationBar from '@department-of-veterans-affairs/appeals-frontend-toolkit/components/NavigationBar';

import WelcomeContainer from './WelcomeContainer';

class InitContainer extends React.PureComponent {
  render() {
    return <BrowserRouter>
      <div>
        <NavigationBar
          appName="eFolder Express"
          logoProps={{
            accentColor: '#F0835e',
            overlapColor: '#F0835e'
          }}
          userDisplayName={this.props.userDisplayName}
          dropdownUrls={this.props.dropdownUrls}
          defaultUrl="/react">
          <Route path="/" component={WelcomeContainer} />
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
