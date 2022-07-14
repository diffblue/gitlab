import {
  API_FUZZING_TARGET_URL_PLACEHOLDER,
  API_FUZZING_SCAN_MODE_PLACEHOLDER,
  API_FUZZING_SPECIFICATION_FILE_PATH_PLACEHOLDER,
  API_FUZZING_PROFILE_PLACEHOLDER,
  API_FUZZING_YAML_CONFIGURATION_TEMPLATE,
} from './constants';

export const buildConfigurationSnippet = ({
  target,
  scanMode,
  apiSpecificationFile,
  scanProfile,
  authUsername,
  authPassword,
} = {}) => {
  if (!target || !scanMode || !apiSpecificationFile || !scanProfile) {
    return '';
  }

  let template = API_FUZZING_YAML_CONFIGURATION_TEMPLATE.replace(
    API_FUZZING_TARGET_URL_PLACEHOLDER,
    target,
  )
    .replace(API_FUZZING_SCAN_MODE_PLACEHOLDER, scanMode)
    .replace(API_FUZZING_SPECIFICATION_FILE_PATH_PLACEHOLDER, apiSpecificationFile)
    .replace(API_FUZZING_PROFILE_PLACEHOLDER, scanProfile);

  if (authUsername && authPassword) {
    // eslint-disable-next-line @gitlab/require-i18n-strings
    template += `
  FUZZAPI_HTTP_USERNAME: "${authUsername}"
  FUZZAPI_HTTP_PASSWORD: "${authPassword}"`;
  }
  return template;
};
