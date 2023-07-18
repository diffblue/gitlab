import { s__, __ } from '~/locale';

export const I18N_ONBOARDING_BREADCRUMB = s__('ProductAnalytics|Product analytics onboarding');

export const INSTALL_NPM_PACKAGE = `yarn add @gitlab/application-sdk-browser

OR

npm install @gitlab/application-sdk-browser`;

export const IMPORT_NPM_PACKAGE = `// import as an ES module
import { glClientSDK } from '@gitlab/application-sdk-browser';

OR

// import as a CommonJS module
const { glClientSDK } = require('@gitlab/application-sdk-browser');
`;

export const INIT_TRACKING = `this.glClient = glClientSDK({ appId: '%{appId}', host: '%{host}' });`;

export const HTML_SCRIPT_SETUP = `<script src="https://unpkg.com/@gitlab/application-sdk-browser/dist/gl-sdk.min.js"></script>
<script>window.glClient = window.glSDK.glClientSDK({
    appId: '%{appId}',
    host: '%{host}',
});
// Tracks the current page view
window.glClient.page();
</script>`;

export const BROWSER_SDK_DOCS_URL =
  'https://gitlab.com/gitlab-org/analytics-section/product-analytics/gl-application-sdk-browser#browser-sdk-initialization-options';

export const SHORT_POLLING_INTERVAL = 1000;

export const LONG_POLLING_INTERVAL = 2500;

export const STATE_CREATE_INSTANCE = 'CREATE_INSTANCE';

export const STATE_LOADING_INSTANCE = 'LOADING_INSTANCE';

export const STATE_WAITING_FOR_EVENTS = 'WAITING_FOR_EVENTS';

export const STATE_COMPLETE = 'COMPLETE';

export const EMPTY_STATE_I18N = {
  empty: {
    title: s__('ProductAnalytics|Analyze your product with Product Analytics'),
    description: s__(
      'ProductAnalytics|Set up Product Analytics to track how your product is performing. Combine it with your GitLab data to better understand where you can improve your product and development processes.',
    ),
    setUpBtnText: s__('ProductAnalytics|Set up product analytics'),
    learnMoreBtnText: __('Learn more'),
  },
  loading: {
    title: s__('ProductAnalytics|Creating your product analytics instance...'),
    description: s__(
      'ProductAnalytics|This might take a while, feel free to navigate away from this page and come back later.',
    ),
  },
};

export const FETCH_ERROR_MESSAGE = s__(
  'ProductAnalytics|An error occurred while fetching data. Refresh the page to try again.',
);

export const ONBOARDING_LIST_ITEM_I18N = {
  title: __('Product Analytics'),
  description: s__(
    'ProductAnalytics|Set up to track how your product is performing and optimize your product and development processes.',
  ),
  waitingForEvents: s__('ProductAnalytics|Waiting for events'),
  loadingInstance: s__('ProductAnalytics|Loading instance'),
};
