import React from 'react';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import StatusMessage from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/StatusMessage';

export default class UnauthorizedContainer extends React.PureComponent {
  render() {
    return <StatusMessage title="Drat!">
      You aren't authorized to use eFolder Express yet.
      <br />
      <Link to="/help">Visit the help page</Link> to find out how you can request access to eFolder Express.
    </StatusMessage>;
  }
}
