import { css } from 'glamor';
import React from 'react';

const childTextStlying = css({
  '& p': { margin: 0 }
});

export default class AlertBanner extends React.PureComponent {
  render() {
    let alertTypeClass;

    switch (this.props.alertType) {
    case 'error':
      alertTypeClass = 'usa-alert-error';
      break;
    case 'success':
      alertTypeClass = 'usa-alert-success';
      break;
    case 'info':
    default:
      alertTypeClass = 'usa-alert-info';
      break;
    }

    return <div className={`usa-alert ${alertTypeClass}`} role="alert" {...css({ marginBottom: '2.4rem' })}>
      <div className="usa-alert-body">
        <h2 className="usa-alert-heading">{this.props.title}</h2>
        <div className="usa-alert-text" {...childTextStlying}>{this.props.children}</div>
      </div>
    </div>;
  }
}
