import * as Constants from './actionTypes';

export default function reducer(state, action) {
  switch (action.type) {
  case Constants.UPDATE_TEXTAREA:
    return { ...state,
      text: action.payload };
  default:
    return state;
  }
}
