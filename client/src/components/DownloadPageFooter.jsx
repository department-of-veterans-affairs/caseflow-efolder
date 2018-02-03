import React from 'react';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

export default class DownloadPageFooter extends React.PureComponent {
  render() {
    return <AppSegment>
      <input
        className="cf-submit cf-retrieve-button ee-right-button"
        type="submit"
        value={this.props.label}
      />
      <Link href="/" className="ee-button-align">Start over</Link>
    </AppSegment>;
  }
}
