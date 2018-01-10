import React from 'react';
import { connect } from 'react-redux';

import { UPDATE_TEXTAREA } from '../actionTypes';

class InitContainer extends React.Component {
  onTextareaChange(event) {
    this.props.dispatch({ type: UPDATE_TEXTAREA, payload: event.target.value })
  }

  render() {
    return <div>
      <textarea defaultValue={this.props.text} onChange={this.onTextareaChange.bind(this)} />
      <h1>{this.props.text.length}</h1>
    </div>;
  }
}

const mapStateToProps = state => {
  return {
    text : state.text
  }
}

export default connect(
  mapStateToProps
)(InitContainer)
