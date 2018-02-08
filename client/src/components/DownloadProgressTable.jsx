import React from 'react';

import { aliasForSource, formatDateString } from '../Utils';

export default class DownloadProgressTable extends React.PureComponent {
  render() {
    return <div className="ee-document-list">
      <table className="usa-table-borderless ee-documents-table" summary="Status of veteran eFolder file downloads">
        <thead>
          <tr>
            <th className="ee-status" scope="col"><span className="usa-sr-only">Status</span></th>
            <th className="ee-filename-row" scope="col">Document Type</th>
            { this.props.showDocumentId && <th className="ee-document-id" scope="col">Document ID</th> }
            <th className="source-col" scope="col">Source</th>
            <th className="receipt-col" scope="col">Receipt Date</th>
          </tr>
        </thead>

        <tbody className="ee-document-scroll">
          { this.props.documents.map((doc) => (
            <tr key={doc.id} className={`document-${doc.status}`}>
              <td className="ee-status">{this.props.icon}</td>
              <td className="ee-filename-row">{doc.type_description}</td>
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
