import React from 'react';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import StatusMessage from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/StatusMessage';

export default class NotFoundContainer extends React.PureComponent {
  render() {
    return <StatusMessage title="Page Not Found">
      No webpage was found at <strong>{this.props.location.pathname}</strong>
      <br /><br />
      <Link to="/">Return to the start page</Link> to search for an eFolder or&nbsp;
      <Link to="/help">visit the help page</Link> for additional information about eFolder Express.
    </StatusMessage>;
  }
}
