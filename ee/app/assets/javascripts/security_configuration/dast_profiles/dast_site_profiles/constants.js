import { s__, __ } from '~/locale';

export const MAX_CHAR_LIMIT_EXCLUDED_URLS = 2048;
export const MAX_CHAR_LIMIT_REQUEST_HEADERS = 2048;
export const EXCLUDED_URLS_SEPARATOR = ',';
export const REDACTED_PASSWORD = '••••••••';
export const REDACTED_REQUEST_HEADERS = '••••••••';

export const TARGET_TYPES = {
  WEBSITE: { value: 'WEBSITE', text: s__('DastProfiles|Website') },
  API: { value: 'API', text: s__('DastProfiles|API') },
};

export const SCAN_METHODS = {
  HAR: {
    text: __('HTTP Archive (HAR)'),
    value: 'HAR',
    inputLabel: __('HAR file path or URL'),
    placeholder: s__(
      'DastProfiles|folder/dast_example.har or https://example.com/dast_example.har',
    ),
  },
  OPENAPI: {
    text: __('OpenAPI'),
    value: 'OPENAPI',
    inputLabel: __('OpenAPI Specification file path or URL'),
    placeholder: s__('DastProfiles|folder/openapi.json or https://example.com/openapi.json'),
  },
  POSTMAN_COLLECTION: {
    text: __('Postman collection'),
    value: 'POSTMAN_COLLECTION',
    inputLabel: __('Postman collection file path or URL'),
    placeholder: s__('DastProfiles|folder/example.postman_collection.json or https://example.com/'),
  },
};
