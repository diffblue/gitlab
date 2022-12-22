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
