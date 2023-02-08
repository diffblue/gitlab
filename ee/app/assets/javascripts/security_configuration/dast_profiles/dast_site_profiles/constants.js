import { s__, __ } from '~/locale';

export const MAX_CHAR_LIMIT_EXCLUDED_URLS = 2048;
export const MAX_CHAR_LIMIT_REQUEST_HEADERS = 2048;
export const EXCLUDED_URLS_SEPARATOR = ',';
export const REDACTED_PASSWORD = '••••••••';
export const REDACTED_REQUEST_HEADERS = '••••••••';
export const DAST_API_DOC_PATH_BASE = 'user/application_security/dast_api/index';
export const DAST_PROXY_DOC_PATH_BASE = 'user/application_security/dast/proxy-based';

export const TARGET_TYPES = {
  WEBSITE: { value: 'WEBSITE', text: s__('DastProfiles|Website') },
  API: { value: 'API', text: s__('DastProfiles|API') },
};

export const SCAN_METHODS = {
  HAR: {
    text: __('HTTP Archive (HAR)'),
    value: 'HAR',
    inputLabel: __('HAR file URL'),
    placeholder: s__('DastProfiles|https://example.com/dast_example.har'),
  },
  GRAPHQL: {
    text: __('GraphQL'),
    value: 'GRAPHQL',
    inputLabel: __('GraphQL endpoint path'),
    placeholder: s__('DastProfiles|/graphql'),
  },
  OPENAPI: {
    text: __('OpenAPI'),
    value: 'OPENAPI',
    inputLabel: __('OpenAPI Specification file URL'),
    placeholder: s__('DastProfiles|https://example.com/openapi.json'),
  },
  POSTMAN_COLLECTION: {
    text: __('Postman collection'),
    value: 'POSTMAN_COLLECTION',
    inputLabel: __('Postman collection file URL'),
    placeholder: s__('DastProfiles|https://example.com/postman_collection.json'),
  },
};

export const generateFormDastSiteFields = (isPasswordRequired, showBasicAuthOption = false) => [
  {
    label: s__('DastProfiles|Authentication URL'),
    fieldName: 'url',
    newLine: true,
    type: 'text',
    isRequired: true,
    showBasicAuthOption,
  },
  {
    autocomplete: 'off',
    label: s__('DastProfiles|Username'),
    fieldName: 'username',
    type: 'text',
    isRequired: true,
    showBasicAuthOption: false,
  },
  {
    autocomplete: 'off',
    label: s__('DastProfiles|Password'),
    fieldName: 'password',
    type: 'password',
    isRequired: isPasswordRequired,
    showBasicAuthOption: false,
  },
  {
    label: s__('DastProfiles|Username form field'),
    fieldName: 'usernameField',
    type: 'text',
    isRequired: true,
    showBasicAuthOption,
  },
  {
    label: s__('DastProfiles|Password form field'),
    fieldName: 'passwordField',
    type: 'text',
    isRequired: true,
    showBasicAuthOption,
  },
  {
    label: s__('DastProfiles|Submit button (optional)'),
    fieldName: 'submitField',
    type: 'text',
    isRequired: false,
    showBasicAuthOption,
  },
];
