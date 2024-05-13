import { css } from 'glamor';
import React, { useEffect } from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import {
  clearErrorMessage,
  clearSearchInputText,
  setVeteranId,
  setSearchInputText
} from '../actions';
import { startManifestFetch } from '../apiActions';
import AlertBanner from '../components/AlertBanner';

const searchBarNoteTextStyling = css({
  fontStyle: 'italic',
  textAlign: 'center'
});

const WelcomeContainer = (props) => {
  useEffect(() => {
    props.clearErrorMessage();
    props.clearSearchInputText();
  }, []);

  const handleInputChange = (event) => {
    props.setSearchInputText(event.target.value);
  }

  const handleFormSubmit = (event) => {
    const veteranId = props.searchInputText;

    props.setVeteranId(veteranId);
    props.startManifestFetch(veteranId, props.csrfToken, props.history.push);
    event.preventDefault();
  }

    return <AppSegment filledBackground>
      { props.errorMessage.title &&
        <AlertBanner title="We could not complete the search for  Veteran ID" alertType="error">
          <p>{props.errorMessage.message}</p>
        </AlertBanner>
      }

      <div className="ee-heading">
        <h1>Welcome to eFolder Express</h1>
        <p>eFolder Express allows VA employees to bulk-download VBMS eFolders.
          <br />Search for a Veteran ID number below to get started.
        </p>
      </div>

      <div className="ee-search">

        <form className="usa-search usa-search-big cf-form" id="new_download" onSubmit={handleFormSubmit}>
          <div role="search">
            <label className="usa-sr-only" htmlFor="file_number">
              Search for a Veteran ID number below to get started.
            </label>
            <input
              type="search"
              name="file_number"
              id="file_number"
              value={props.searchInputText}
              onChange={handleInputChange}
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

      <Link to="/recent-downloads">Recent downloads...</Link>
    </AppSegment>;
  }

const mapStateToProps = (state) => ({
  csrfToken: state.csrfToken,
  errorMessage: state.errorMessage,
  searchInputText: state.searchInputText
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearErrorMessage,
  clearSearchInputText,
  setVeteranId,
  startManifestFetch,
  setSearchInputText
}, dispatch);


export default connect(mapStateToProps, mapDispatchToProps)(WelcomeContainer);
