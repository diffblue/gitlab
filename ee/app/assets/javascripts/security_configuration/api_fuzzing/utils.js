import {
  API_FUZZING_TARGET_URL_PLACEHOLDER,
  API_FUZZING_SCAN_MODE_PLACEHOLDER,
  API_FUZZING_SPECIFICATION_FILE_PATH_PLACEHOLDER,
  API_FUZZING_PROFILE_PLACEHOLDER,
  API_FUZZING_AUTH_PASSWORD_VAR_PLACEHOLDER,
  API_FUZZING_AUTH_USERNAME_VAR_PLACEHOLDER,
  API_FUZZING_YAML_CONFIGURATION_TEMPLATE,
  API_FUZZING_YAML_CONFIGURATION_AUTH_TEMPLATE,
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
    template += API_FUZZING_YAML_CONFIGURATION_AUTH_TEMPLATE.replace(
      API_FUZZING_AUTH_USERNAME_VAR_PLACEHOLDER,
      authUsername,
    ).replace(API_FUZZING_AUTH_PASSWORD_VAR_PLACEHOLDER, authPassword);
  }
  return template;
};
