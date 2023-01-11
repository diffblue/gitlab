import { s__, __ } from '~/locale';

export const INSTALL_NPM_PACKAGE = `yarn add @gitlab/application-sdk-js

--

npm i @gitlab/application-sdk-js`;

export const ESM_SETUP_WITH_NPM = `import { glClientSDK } from '@gitlab/application-sdk-js';

this.glClient = glClientSDK({ '$applicationId', '$host' });`;

export const COMMON_JS_SETUP_WITH_NPM = `const { glClientSDK } = require('@gitlab/application-sdk-js');

this.glClient = glClientSDK({ '$applicationId', '$host' });`;

export const HTML_SCRIPT_SETUP = `<script src="https://unpkg.com/@gitlab/application-sdk-js/gl-sdk.min.js"></script>
<script>window.glClient = window.glSDK.glClientSDK({
    applicationId: '$applicationId',
    host: '$host',
});</script>`;

export const JITSU_KEY_CHECK_DELAY = 1000;

export const EMPTY_STATE_I18N = {
  empty: {
    title: s__('Product Analytics|Analyze your product with Product Analytics'),
    description: s__(
      'Product Analytics|Set up Product Analytics to track how your product is performing. Combine it with your GitLab data to better understand where you can improve your product and development processes.',
    ),
    setUpBtnText: s__('Product Analytics|Set up product analytics'),
    learnMoreBtnText: __('Learn more'),
  },
  loading: {
    title: s__('Product Analytics|Creating your product analytics instance...'),
    description: s__(
      'Product Analytics|This might take a while, feel free to navigate away from this page and come back later.',
    ),
  },
};
