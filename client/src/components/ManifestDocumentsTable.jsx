import { css } from 'glamor';
import React from 'react';

import { aliasForSource, formatDateString } from '../Utils';

const centeredTextMessageStyle = css({
  borderBottom: '1px solid #d6d7d9',
  paddingBottom: '2.4rem',
  textAlign: 'center'
});

const documentTypeStyle = css({ width: '100%' });

export default class DownloadProgressTable extends React.PureComponent {
  render() {
    if (!this.props.documents.length) {
      return <div className="ee-document-list">
        <p {...centeredTextMessageStyle}>There are no documents here.</p>
      </div>;
    }

    return <div className="ee-document-list">
      <table className="usa-table-borderless ee-documents-table" summary={this.props.summary} role="grid">
        <thead role="presentation">
          <tr role="row">
            {this.props.icon &&
              <th className="ee-status" scope="col" role="columnheader"><span className="usa-sr-only">Status</span></th>
            }
            <th scope="col" role="columnheader"{...documentTypeStyle}>Document Type</th>
            {this.props.showDocumentId && <th className="ee-document-id"
              scope="col" role="columnheader">Document ID</th>}
            <th className="source-col" scope="col" role="columnheader">Source</th>
            <th className="receipt-col" scope="col" role="columnheader">Receipt Date</th>
          </tr>
        </thead>

        <tbody className="ee-document-scroll" role="presentation">
          {this.props.documents.map((doc) => (
            <tr key={doc.id} className={`document-${doc.status}`} role="row">
              {this.props.icon && <td className="ee-status" role="gridcell">{this.props.icon}</td>}
              <td scope="col" role="gridcell"{...documentTypeStyle}>{doc.type_description}</td>
              {this.props.showDocumentId && <td className="ee-doc-id-row" role="gridcell">{doc.version_id}</td>}
              <td className="source-col" role="gridcell">{aliasForSource(doc.source)}</td>
              <td className="receipt-col" role="gridcell">{formatDateString(doc.received_at)}</td>
            </tr>)
          )}
        </tbody>
      </table>
    </div>;
  }
}
