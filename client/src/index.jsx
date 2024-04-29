import React from 'react';
import { createRoot } from 'react-dom/client';

import ReduxBase from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/ReduxBase';

import reducer, { initState } from './reducer';
import InitContainer from './containers/InitContainer';

const efolderExpress = {
  init(props) {
    const container = document.getElementById('efolder_express_app');
    const root = createRoot(container);
    root.render(
      <ReduxBase reducer={reducer} initialState={{
        ...initState,
        ...props
      }}>
        <InitContainer />
      </ReduxBase>
    );
  }
};

export default efolderExpress;