import { uniqueId } from 'lodash';

const CALLBACK_NAME = '_initArkoseLabsScript_callback_';

const getCallbackName = () => uniqueId(CALLBACK_NAME);

export const initArkoseLabsScript = ({ publicKey }) => {
  const callbackFunctionName = getCallbackName();

  return new Promise((resolve) => {
    window[callbackFunctionName] = (enforcement) => {
      delete window[callbackFunctionName];
      resolve(enforcement);
    };

    const tag = document.createElement('script');
    [
      ['type', 'text/javascript'],
      ['src', `https://client-api.arkoselabs.com/v2/${publicKey}/api.js`],
      ['data-callback', callbackFunctionName],
    ].forEach(([attr, value]) => {
      tag.setAttribute(attr, value);
    });
    document.head.appendChild(tag);
  });
};
