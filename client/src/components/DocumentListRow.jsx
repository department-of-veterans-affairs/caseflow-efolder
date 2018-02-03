import React from 'react';

export default class DocumentListRow extends React.PureComponent {
  render() {
    return <tr>
      <td className="document-col">{this.props.type}</td>
      <td className="sources-col">{this.props.source}</td>
      <td className="upload-col">{this.props.received_at}</td>
    </tr>;
  }
}
