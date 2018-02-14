import { css } from 'glamor';
import React from 'react';

import { aliasForSource, formatDateString } from '../Utils';

const documentTypeStyle = css({ width: '100%' });

export default class DownloadProgressTable extends React.PureComponent {
  render() {
    return <div className="ee-document-list">
      <table className="usa-table-borderless ee-documents-table" summary={this.props.summary}>
        <thead>
          <tr>
            { this.props.icon &&
              <th className="ee-status" scope="col"><span className="usa-sr-only">Status</span></th>
            }
            <th scope="col" {...documentTypeStyle}>Document Type</th>
            { this.props.showDocumentId && <th className="ee-document-id" scope="col">Document ID</th> }
            <th className="source-col" scope="col">Source</th>
            <th className="receipt-col" scope="col">Receipt Date</th>
          </tr>
        </thead>

        <tbody className="ee-document-scroll">
          { this.props.documents.map((doc) => (
            <tr key={doc.id} className={`document-${doc.status}`}>
              { this.props.icon && <td className="ee-status">{this.props.icon}</td> }
              <td scope="col" {...documentTypeStyle}>{doc.type_description}</td>
              { this.props.showDocumentId && <td className="ee-doc-id-row">{doc.version_id}</td> }
              <td className="source-col">{aliasForSource(doc.source)}</td>
              <td className="receipt-col">{formatDateString(doc.received_at)}</td>
            </tr>)
          )}
        </tbody>
      </table>
    </div>;
  }
}
