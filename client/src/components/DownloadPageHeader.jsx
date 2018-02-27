import React from 'react';
import CopyToClipboard from 'react-copy-to-clipboard';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import { CopyIcon } from '../components/Icons';

export default class DownloadPageHeader extends React.PureComponent {
  render() {
    return <AppSegment extraClassNames="cf-efolder-header">
      <h3 className="cf-push-left cf-name-header cf-efolder-name">{this.props.veteranName}</h3>
      <div className="cf-txt-uc cf-efolder-id-control cf-push-right">Veteran ID &nbsp;
        <CopyToClipboard text={this.props.veteranId}>
          <button type="submit" title="Copy to clipboard" className="cf-apppeal-id ee-copy-button">
            {this.props.veteranId} <CopyIcon />
          </button>
        </CopyToClipboard>
      </div>
    </AppSegment>;
  }
}
