import React from 'react';
import { connect } from 'react-redux';

import RecentDownloadsContainer from './RecentDownloadsContainer';

class WelcomeContainer extends React.PureComponent {
  render() {
    return <main className="usa-grid">
      <div className="cf-app">
        <div className="cf-app-segment cf-app-segment--alt ee-new-download">
          <div className="ee-heading">
            <h1>Welcome to eFolder Express</h1>
            <p>eFolder Express allows VA employees to bulk-download VBMS eFolders.
              <br />Search for a Veteran ID number below to get started.
            </p>
          </div>
          <div className="ee-search">
            <form
              className="usa-search usa-search-big cf-form"
              id="new_download"
              action="/downloads"
              acceptCharset="UTF-8"
              method="post">
              <input
                type="hidden"
                name="authenticity_token"
                value={this.props.authenticityToken} />
              <div role="search">
                <label className="usa-sr-only" htmlFor="file_number">
                  Search for a Veteran ID number below to get started.
                </label>
                <input type="search" name="file_number" id="file_number" />
                <button type="submit" className="cf-submit">
                  <span className="usa-search-submit-text">Search</span>
                </button>
              </div>
            </form>
            <p className="cf-txt-c"><i>
Note: eFolder Express now includes Virtual VA documents from the Legacy Content Manager Documents tab in VBMS.
            </i></p>
          </div>
          <RecentDownloadsContainer />
        </div>
      </div>
    </main>;
  }
}

const mapStateToProps = (state) => {
  return {
    authenticityToken: state.authenticityToken
  };
};

export default connect(mapStateToProps)(WelcomeContainer);
