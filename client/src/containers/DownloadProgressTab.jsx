import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import { setActiveDownloadProgressTab } from '../actions';

class DownloadProgressTab extends React.PureComponent {
  setActiveTab = (event) => {
    if (this.props.documentCount) {
      this.props.setActiveDownloadProgressTab(this.props.name);
    }
    event.preventDefault();
  }

  render() {
    let classNames = 'cf-tab';

    if (this.props.name === this.props.activeDownloadProgressTab) {
      classNames = `${classNames} cf-active`;
    }

    return <button className={classNames} onClick={this.setActiveTab}>
      <span>{this.props.children}</span>
    </button>;
  }
}

const mapStateToProps = (state) => ({ activeDownloadProgressTab: state.activeDownloadProgressTab });

const mapDispatchToProps = (dispatch) => bindActionCreators({ setActiveDownloadProgressTab }, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(DownloadProgressTab);
