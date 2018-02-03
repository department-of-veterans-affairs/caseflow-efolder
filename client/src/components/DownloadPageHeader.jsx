import React from 'react';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import CopyIcon from '../components/CopyIcon';

// TODO: Get copy-paste feature working.
export default class DownloadPageHeader extends React.PureComponent {
  render() {
    return <AppSegment extraClassNames="cf-efolder-header">
      <h3 className="cf-push-left cf-name-header cf-efolder-name">{this.props.veteranName}</h3>
      <div className="cf-txt-uc cf-efolder-id-control cf-push-right ">Veteran ID &nbsp;
        <button
          type="submit"
          title="Copy to clipboard"
          className="cf-apppeal-id ee-copy-button"
          data-clipboard-text={this.props.veteranId}
        >
          {this.props.veteranId} <CopyIcon />
        </button>
      </div>
    </AppSegment>;
  }
}
