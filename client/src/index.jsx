import React from 'react';
import { render } from 'react-dom';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';

import reducer from './reducer';
import InitContainer from './containers/InitContainer';

const initState = {
  documents: [],
  documentSources: [],
  errorMessage: '',
  searchInputText: '',
  veteranId: '',
  veteranName: ''
};

module.exports = {
  init(props) {
    const store = createStore(reducer, { ...initState,
      ...props }, applyMiddleware(thunk));

    render(<Provider store={store}>
      <InitContainer />
    </Provider>, document.getElementById('efolder_express_app'));
  }
};
