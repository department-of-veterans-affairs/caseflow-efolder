import React from 'react';
import { render } from 'react-dom';

import ReduxBase from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/ReduxBase';

import reducer, { initState } from './reducer';
import InitContainer from './containers/InitContainer';

const efolderExpress = {
  init(props) {
    render(
      <ReduxBase reducer={reducer} initialState={{ 
        ...initState,
        ...props
      }}>
        <InitContainer />
      </ReduxBase>,
      document.getElementById('efolder_express_app')
    );
  }
};

export default efolderExpress;
