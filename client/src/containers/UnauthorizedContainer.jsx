import React from 'react';
import { Link } from 'react-router-dom';

import AppSegment from '@department-of-veterans-affairs/appeals-frontend-toolkit/components/AppSegment';

export default class UnauthorizedContainer extends React.PureComponent {
  render() {
    return <main className="usa-grid">
      <AppSegment extraClassNames="cf-app-msg-screen" filledBackground>
        <h1 className="cf-msg-screen-heading">Drat!</h1>
        <h2 className="cf-msg-screen-deck">You aren't authorized to use eFolder Express yet.</h2>
        <p className="cf-msg-screen-text">
          <Link to="/help">Click here</Link> to find out how you can request access to eFolder Express.
        </p>
      </AppSegment>
    </main>;
  }
}
