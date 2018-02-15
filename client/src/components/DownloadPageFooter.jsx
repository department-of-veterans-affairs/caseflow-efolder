import React from 'react';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

export default class DownloadPageFooter extends React.PureComponent {
  render() {
    return <AppSegment>
      { this.props.children }
      <Link to="/" className="ee-button-align">{ this.props.linkLabel ? this.props.linkLabel : 'Start over' }</Link>
    </AppSegment>;
  }
}
