import React from 'react';
import { render } from 'react-dom';
import { Provider } from 'react-redux';
import { createStore } from 'redux';

import reducer from './reducer';
import InitContainer from './containers/InitContainer';

module.exports = {
  init(props) {
    const initState = { text: 'some text' };
    const store = createStore(reducer, { ...initState,
      ...props });

    render(<Provider store={store}>
      <InitContainer />
    </Provider>, document.getElementById('efx_app_v2'));
  }
};
