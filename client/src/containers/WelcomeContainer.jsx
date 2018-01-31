import { css } from 'glamor';
import React from 'react';
import request from 'superagent';
import nocache from 'superagent-no-cache';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import RecentDownloadsContainer from './RecentDownloadsContainer';

const searchBarNoteTextStyling = css({
  fontStyle: 'italic',
  textAlign: 'center'
});

export default class WelcomeContainer extends React.PureComponent {
  updateSearchInput(event) {
    this.searchInputText = event.target.value;
  }

  handleKeyPress(event) {
    if (event.key === 'Enter') {
      this.submitSearchInput();
    }
  }

  submitSearchInput() {
    const headers = {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      FILE_NUMBER: this.searchInputText,
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
    };

    request.
      post('/api/v2/manifests').
      set(headers).
      send().
      use(nocache).
      then(
        (resp) => {
          // TODO: We will need to be able to query for the status of the manifest fetch based on the
          // manifest ID.
          // https://github.com/department-of-veterans-affairs/caseflow-efolder/blob/master/docs/v2/endpoints.md
          this.props.history.push(`/downloads/${resp.body.data.id}`);
        }
      );
  }

  render() {
    return <main className="usa-grid">
      <AppSegment filledBackground>

        <div className="ee-heading">
          <h1>Welcome to eFolder Express</h1>
          <p>eFolder Express allows VA employees to bulk-download VBMS eFolders.
            <br />Search for a Veteran ID number below to get started.
          </p>
        </div>

        <div className="ee-search">

          <div className="usa-search usa-search-big cf-form" id="new_download">
            <div role="search">
              <label className="usa-sr-only" htmlFor="file_number">
                Search for a Veteran ID number below to get started.
              </label>
              <input
                type="search"
                name="file_number"
                id="file_number"
                onChange={this.updateSearchInput.bind(this)}
                onKeyPress={this.handleKeyPress.bind(this)}
              />
              <button type="submit" className="cf-submit" onClick={this.submitSearchInput.bind(this)}>
                <span className="usa-search-submit-text">Search</span>
              </button>
            </div>
          </div>

          <p {...searchBarNoteTextStyling}>
Note: eFolder Express now includes Virtual VA documents from the Legacy Content Manager Documents tab in VBMS.
          </p>
        </div>

        <RecentDownloadsContainer />

      </AppSegment>
    </main>;
  }
}
