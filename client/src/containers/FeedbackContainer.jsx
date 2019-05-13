import React from 'react';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import StatusMessage from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/StatusMessage';

export default class FeedbackContainer extends React.PureComponent {
  render() {
    return <StatusMessage title="Having a technical difficulty?">
      Submit a ticket to the Caseflow team using <a href="https://yourIT.va.gov" target="_blank">YourIT</a>. The YourIT link is also available on most VA issued workstations. To better assist, please ensure you provide the URL or web address associated to the issue in the ticket.<br /><br />

The Caseflow Technical Support Team does not issue or manage access to Caseflow. Please do not submit a ticket through YourIT to the Caseflow team if you are looking for access to Caseflow or another VA product.<br /><br />

Access is approved and granted via email through your management team and your local CSEM Information Security Officer (ISO). Please email your management team for access guidance.
      </StatusMessage>;
  }
}
