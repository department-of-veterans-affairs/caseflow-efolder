import React from 'react';
import StatusMessage from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/StatusMessage';

export default class OutOfServiceContainer extends React.PureComponent {
  render() {
    return <main className="usa-grid">
    <StatusMessage
      title="Technical Difficulties">
      It looks like Caseflow is experiencing technical difficulties right now.<br />
      Please <a href="">refresh the page</a> and try again.
    </StatusMessage></main>;
  }
}
