import React from 'react';

export default class PageLoadingIndicator extends React.PureComponent {
  render() {
    return <div className="ee-page-loading">
      <div className="ee-page-loading-icon">

        <svg
          width="200"
          height="200"
          version="1.1"
          xmlns="http://www.w3.org/2000/svg"
          xmlnsXlink="http://www.w3.org/1999/xlink"
          viewBox="0 0 500 500"
          className="ee-icon-loading-front">
          <path
            opacity="1"
            fill="#d6d7d9"
            fillOpacity="1"
            d = "M250.9,469.4c-13.9,0-25.8-8.1-30.9-21l-29.9-75.3c-2.3-5.8-7.9-9.6-14.2-9.6c-0.8,0-1.6,0.1-2.4,0.2
            l-77,12.4c-1.8,0.3-3.7,0.4-5.5,0.4c-12.7,0-24.1-7.2-29.8-18.9c-5.6-11.6-4.1-25,3.9-35.1
            l50.2-63.4c4.5-5.7,4.4-13.5-0.1-19.1
            l-49.3-60.5c-8.2-10.1-9.8-23.6-4.3-35.3c5.6-11.8,17-19.1,29.9-19.1c1.7,0,3.4,0.1,5.1,0.4
            l80,11.7c0.7,0.1,1.5,0.2,2.2,0.2
            c6.3,0,12-4,14.2-9.8l27.8-72.9c5-13,17.2-21.5,31.1-21.5c13.9,0,25.8,8.1,30.9,21
            l29.8,75.2c2.3,5.8,7.9,9.6,14.2,9.6
            c0.8,0,1.6-0.1,2.4-0.2l77.1-12.4c1.8-0.3,3.7-0.4,5.5-0.4c12.7,0,24.1,7.2,29.8,18.9c5.6,11.6,4.1,25-3.9,35.1
            l-50.2,63.5
            c-4.5,5.7-4.4,13.5,0.1,19.1L437,323c8.2,10.1,9.8,23.6,4.3,35.3c-5.6,11.8-17,19.1-29.9,19.1c0,0,0,0,0,0
            c-1.7,0-3.4-0.1-5.1-0.4
            l-80.1-11.8c-0.7-0.1-1.5-0.2-2.2-0.2c-6.3,0-12,4-14.2,9.8l-27.8,73C277.1,460.9,264.8,469.4,250.9,469.4z
            M175.9,345.4
            c13.7,0,25.9,8.2,30.9,21l29.9,75.3c2.4,6,7.7,9.6,14.2,9.6c5.1,0,11.5-2.6,14.3-9.8l27.8-73
            c4.9-12.8,17.4-21.5,31.1-21.5
            c1.6,0,3.2,0.1,4.8,0.4l80.1,11.8c0.8,0.1,1.6,0.2,2.4,0.2h0c6.9,0,11.6-4.5,13.6-8.8c2.6-5.4,1.8-11.4-2-16.1
            l-49.3-60.5
            c-9.9-12.2-10.1-29.3-0.3-41.7l50.2-63.5c5.4-6.8,3-13.5,1.8-16c-2-4.2-6.7-8.7-13.5-8.7
            c-0.9,0-1.8,0.1-2.7,0.2l-77.1,12.4
            c-1.8,0.3-3.5,0.4-5.3,0.4c-13.7,0-25.9-8.2-30.9-21L266,60.9c-2.4-6-7.7-9.6-14.2-9.6
            c-5.1,0-11.5,2.6-14.3,9.8L209.8,134
            c-4.9,12.8-17.4,21.5-31.1,21.5c-1.6,0-3.2-0.1-4.8-0.4l-80-11.7c-0.8-0.1-1.6-0.2-2.4-0.2
            c-6.9,0-11.6,4.5-13.6,8.8
            c-2.6,5.4-1.8,11.4,2,16.1l49.3,60.5c9.9,12.2,10.1,29.3,0.3,41.7l-50.2,63.4c-5.4,6.8-3,13.5-1.8,16
            c2,4.2,6.7,8.7,13.5,8.7
            c0.9,0,1.8-0.1,2.7-0.2l77-12.4C172.3,345.5,174.1,345.4,175.9,345.4z">
          </path>
        </svg>

        <svg
          width="200"
          height="200"
          version="1.1"
          xmlns="http://www.w3.org/2000/svg"
          xmlnsXlink="http://www.w3.org/1999/xlink"
          viewBox="0 0 500 500"
          className="ee-icon-loading-back">

          <path
            opacity="1"
            fill="#F15A24"
            fillOpacity="1"
            d = "M250.9,469.4c-13.9,0-25.8-8.1-30.9-21l-29.9-75.3c-2.3-5.8-7.9-9.6-14.2-9.6c-0.8,0-1.6,0.1-2.4,0.2
            l-77,12.4c-1.8,0.3-3.7,0.4-5.5,0.4c-12.7,0-24.1-7.2-29.8-18.9c-5.6-11.6-4.1-25,3.9-35.1
            l50.2-63.4c4.5-5.7,4.4-13.5-0.1-19.1
            l-49.3-60.5c-8.2-10.1-9.8-23.6-4.3-35.3c5.6-11.8,17-19.1,29.9-19.1c1.7,0,3.4,0.1,5.1,0.4
            l80,11.7c0.7,0.1,1.5,0.2,2.2,0.2
            c6.3,0,12-4,14.2-9.8l27.8-72.9c5-13,17.2-21.5,31.1-21.5c13.9,0,25.8,8.1,30.9,21
            l29.8,75.2c2.3,5.8,7.9,9.6,14.2,9.6
            c0.8,0,1.6-0.1,2.4-0.2l77.1-12.4c1.8-0.3,3.7-0.4,5.5-0.4c12.7,0,24.1,7.2,29.8,18.9c5.6,11.6,4.1,25-3.9,35.1
            l-50.2,63.5
            c-4.5,5.7-4.4,13.5,0.1,19.1L437,323c8.2,10.1,9.8,23.6,4.3,35.3c-5.6,11.8-17,19.1-29.9,19.1c0,0,0,0,0,0
            c-1.7,0-3.4-0.1-5.1-0.4
            l-80.1-11.8c-0.7-0.1-1.5-0.2-2.2-0.2c-6.3,0-12,4-14.2,9.8l-27.8,73C277.1,460.9,264.8,469.4,250.9,469.4z
            M175.9,345.4
            c13.7,0,25.9,8.2,30.9,21l29.9,75.3c2.4,6,7.7,9.6,14.2,9.6c5.1,0,11.5-2.6,14.3-9.8l27.8-73
            c4.9-12.8,17.4-21.5,31.1-21.5
            c1.6,0,3.2,0.1,4.8,0.4l80.1,11.8c0.8,0.1,1.6,0.2,2.4,0.2h0c6.9,0,11.6-4.5,13.6-8.8c2.6-5.4,1.8-11.4-2-16.1
            l-49.3-60.5
            c-9.9-12.2-10.1-29.3-0.3-41.7l50.2-63.5c5.4-6.8,3-13.5,1.8-16c-2-4.2-6.7-8.7-13.5-8.7
            c-0.9,0-1.8,0.1-2.7,0.2l-77.1,12.4
            c-1.8,0.3-3.5,0.4-5.3,0.4c-13.7,0-25.9-8.2-30.9-21L266,60.9c-2.4-6-7.7-9.6-14.2-9.6
            c-5.1,0-11.5,2.6-14.3,9.8L209.8,134
            c-4.9,12.8-17.4,21.5-31.1,21.5c-1.6,0-3.2-0.1-4.8-0.4l-80-11.7c-0.8-0.1-1.6-0.2-2.4-0.2
            c-6.9,0-11.6,4.5-13.6,8.8
            c-2.6,5.4-1.8,11.4,2,16.1l49.3,60.5c9.9,12.2,10.1,29.3,0.3,41.7l-50.2,63.4c-5.4,6.8-3,13.5-1.8,16
            c2,4.2,6.7,8.7,13.5,8.7
            c0.9,0,1.8-0.1,2.7-0.2l77-12.4C172.3,345.5,174.1,345.4,175.9,345.4z">
          </path>
        </svg>

      </div>
      {this.props.children}
    </div>;
  }
}
