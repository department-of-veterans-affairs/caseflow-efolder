import React from 'react';
import { connect } from 'react-redux';
import { Route, Redirect } from 'react-router-dom';

class PrivateRoute extends React.PureComponent {
  render() {
    if (!this.props.userIsAuthorized) {
      return <Redirect to="/unauthorized" />;
    }

    return <Route {...this.props} />;
  }
}

const mapStateToProps = (state) => ({ userIsAuthorized: state.userIsAuthorized });

export default connect(mapStateToProps)(PrivateRoute);
