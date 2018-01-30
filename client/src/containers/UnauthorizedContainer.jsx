import React from 'react';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import StatusMessage from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/StatusMessage';

export default class UnauthorizedContainer extends React.PureComponent {
  render() {
    return <main className="usa-grid">
      <StatusMessage title="Drat!">
        You aren't authorized to use eFolder Express yet.
        <br />
        <Link to="/help">Click here</Link> to find out how you can request access to eFolder Express.
      </StatusMessage>
    </main>;
  }
}
