import React from 'react';

import AppSegment from '@department-of-veterans-affairs/appeals-frontend-toolkit/components/AppSegment';

export default class OutOfServiceContainer extends React.PureComponent {
  render() {
    return <main className="usa-grid">
      <AppSegment filledBackground>
        <h1 className="cf-msg-screen-heading">Technical Difficulties</h1>
        <h2 className="cf-msg-screen-deck">It looks like Caseflow is experiencing technical difficulties right now.
        We apologize for any inconvenience. Please check back in a little bit.</h2>
      </AppSegment>
    </main>;
  }
}
