import { s__ } from '~/locale';

export const MAX_CHAR_LIMIT_EXCLUDED_URLS = 2048;
export const MAX_CHAR_LIMIT_REQUEST_HEADERS = 2048;
export const EXCLUDED_URLS_SEPARATOR = ',';
export const REDACTED_PASSWORD = '••••••••';
export const REDACTED_REQUEST_HEADERS = '••••••••';

export const TARGET_TYPES = {
  WEBSITE: { value: 'WEBSITE', text: s__('DastProfiles|Website') },
  API: { value: 'API', text: s__('DastProfiles|Rest API') },
};
