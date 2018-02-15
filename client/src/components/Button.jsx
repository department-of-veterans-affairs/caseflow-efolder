import React from 'react';

export const BUTTON_ALIGN_RIGHT = 'BUTTON_ALIGN_RIGHT';

export default class Button extends React.PureComponent {
  render() {
    let classNames = 'cf-submit cf-retrieve-button';

    if (this.props.align && this.props.align === BUTTON_ALIGN_RIGHT) {
      classNames = `${classNames} ee-right-button`;
    }

    // TODO: Is this too lenient? Should we be filtering out some properties?
    return <button className={classNames} {...this.props}>{this.props.children}</button>;
  }
}
