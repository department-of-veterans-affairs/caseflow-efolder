import { css } from 'glamor';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import { clearErrorMessage, setVeteranId, setSearchInputText } from '../actions';
import { startManifestFetch } from '../apiActions';
import AlertBanner from '../components/AlertBanner';
import RecentDownloadsContainer from './RecentDownloadsContainer';

const searchBarNoteTextStyling = css({
  fontStyle: 'italic',
  textAlign: 'center'
});

class WelcomeContainer extends React.PureComponent {
  componentDidMount() {
    this.props.clearErrorMessage();
  }

  handleInputChange = (event) => {
    this.props.setSearchInputText(event.target.value);
  }

  handleFormSubmit = (event) => {
    const veteranId = this.props.searchInputText;

    this.props.setVeteranId(veteranId);
    this.props.startManifestFetch(veteranId, this.props.csrfToken, this.props.history.push);
    event.preventDefault();
  }

  render() {
    return <AppSegment filledBackground>
      { this.props.errorMessage &&
        <AlertBanner title="We could not complete the search for this Veteran ID" alertType="error">
          <p>{this.props.errorMessage}</p>
        </AlertBanner>
      }

      <div className="ee-heading">
        <h1>Welcome to eFolder Express</h1>
        <p>eFolder Express allows VA employees to bulk-download VBMS eFolders.
          <br />Search for a Veteran ID number below to get started.
        </p>
      </div>

      <div className="ee-search">

        <form className="usa-search usa-search-big cf-form" id="new_download" onSubmit={this.handleFormSubmit}>
          <div role="search">
            <label className="usa-sr-only" htmlFor="file_number">
              Search for a Veteran ID number below to get started.
            </label>
            <input
              type="search"
              name="file_number"
              id="file_number"
              value={this.props.searchInputText}
              onChange={this.handleInputChange}
            />
            <button type="submit" className="cf-submit">
              <span className="usa-search-submit-text">Search</span>
            </button>
          </div>
        </form>

        <p {...searchBarNoteTextStyling}>
Note: eFolder Express now includes Virtual VA documents from the Legacy Content Manager Documents tab in VBMS.
        </p>
      </div>

      <RecentDownloadsContainer />
    </AppSegment>;
  }
}

const mapStateToProps = (state) => ({
  csrfToken: state.csrfToken,
  errorMessage: state.errorMessage,
  searchInputText: state.searchInputText
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearErrorMessage,
  setVeteranId,
  startManifestFetch,
  setSearchInputText
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(WelcomeContainer);
