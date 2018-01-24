import React from 'react';
import { Link } from 'react-router-dom';

import AlertIcon from './AlertIcon';

export default class RecentDownloadRow extends React.PureComponent {
  render() {
    // After efolder issue 813 is merged to master we can address the following todos. manifest_serializer.rb may
    // need to be modified slightly to include some additional fields (expiration_date, pending_documents, etc.)

    // TODO: This should probably be built in the model/serializer and passed as this.props.download.veteran_full_name
    const veteranFullName = `${this.props.download.veteran_first_name} ${this.props.download.veteran_last_name}`;

    // TODO: Use this.props.download.expiration_date or equivalent in UserManifest when it is built out.
    const expirationDate = '01/26';

    // TODO: Switch the link text based on this.props.download.in_progress or equivalent.
    const downloadInProgress = true;

    // TODO: Add alert icon based on this.props.download.had_errors or equivalent.
    const downloadEncounteredErrors = true;

    return <tr id={`download-${this.props.download.id}`}>
      <td>
        {veteranFullName}
        <span className="cf-subtext"> ({this.props.download.file_number}) - Expires on {expirationDate} </span>
      </td>
      <td className="ee-actions-cell">
        <Link to={`/downloads/${this.props.download.id}`}>
          { downloadEncounteredErrors ? <AlertIcon /> : '' }
          { downloadInProgress ? ' View progress »' : ' View results »' }
        </Link>
      </td>
    </tr>;
  }
}
