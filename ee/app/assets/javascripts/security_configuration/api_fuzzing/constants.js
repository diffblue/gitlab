import { __, s__ } from '~/locale';

export const SCAN_MODES = {
  HAR: {
    scanModeLabel: __('HAR (HTTP Archive)'),
    label: __('HAR file path or URL'),
    placeholder: s__('APIFuzzing|folder/example_fuzz.har'),
    description: s__(
      "APIFuzzing|File path or URL to APIs to be tested. For example, folder/example_fuzz.har. HAR files may contain sensitive information such as authentication tokens, API keys, and session cookies. We recommend that you review the HAR files' contents before adding them to a repository.",
    ),
  },
  OPENAPI: {
    scanModeLabel: __('OpenAPI'),
    label: __('OpenAPI Specification file path or URL'),
    placeholder: s__('APIFuzzing|folder/openapi.json'),
    description: s__(
      'APIFuzzing|File path or URL to OpenAPI specification. For example, folder/openapi.json or http://www.example.com/openapi.json.',
    ),
  },
  POSTMAN: {
    scanModeLabel: __('Postman collection'),
    label: __('Postman collection file path or URL'),
    placeholder: s__('APIFuzzing|folder/example.postman_collection.json'),
    description: s__(
      'APIFuzzing|File path or URL to requests to be tested. For example, folder/example.postman_collection.json.',
    ),
  },
};

export const API_FUZZING_TARGET_URL_PLACEHOLDER = '#API_FUZZING_TARGET_URL_PLACEHOLDER';
export const API_FUZZING_SCAN_MODE_PLACEHOLDER = '#API_FUZZING_SCAN_MODE_PLACEHOLDER';
export const API_FUZZING_SPECIFICATION_FILE_PATH_PLACEHOLDER =
  '#API_FUZZING_SPECIFICATION_FILE_PATH_PLACEHOLDER';
export const API_FUZZING_PROFILE_PLACEHOLDER = '#API_FUZZING_PROFILE_PLACEHOLDER';

export const API_FUZZING_YAML_CONFIGURATION_TEMPLATE = `---
# ${s__('APIFuzzing|Tip: Insert this part below all stages')}
stages:
- fuzz

# ${s__('APIFuzzing|Tip: Insert this part below all include')}
include:
- template: Security/API-Fuzzing.gitlab-ci.yml

# ${s__('APIFuzzing|Tip: Insert the following variables anywhere below stages and include')}
variables:
  FUZZAPI_TARGET_URL: ${API_FUZZING_TARGET_URL_PLACEHOLDER}
  FUZZAPI_${API_FUZZING_SCAN_MODE_PLACEHOLDER}: ${API_FUZZING_SPECIFICATION_FILE_PATH_PLACEHOLDER}
  FUZZAPI_PROFILE: ${API_FUZZING_PROFILE_PLACEHOLDER}`;
