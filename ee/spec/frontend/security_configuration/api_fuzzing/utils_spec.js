import { omit } from 'lodash';
import { buildConfigurationSnippet } from 'ee/security_configuration/api_fuzzing/utils';

describe('buildConfigurationSnippet', () => {
  const basicOptions = {
    target: '/api/fuzzing/target/url',
    scanMode: 'SCANMODE',
    apiSpecificationFile: '/api/specification/file',
    scanProfile: 'ScanProfile-1',
  };
  const authOptions = {
    authUsername: '$USERNAME',
    authPassword: '$PASSWORD',
  };

  it('returns an empty string if basic options are missing', () => {
    expect(buildConfigurationSnippet()).toBe('');
  });

  it.each(Object.keys(basicOptions))(
    'returns an empty string if %s option is missing',
    (option) => {
      const options = omit(basicOptions, option);

      expect(buildConfigurationSnippet(options)).toBe('');
    },
  );

  it('returns basic configuration YAML', () => {
    expect(buildConfigurationSnippet(basicOptions)).toBe(`---
# Tip: Insert this part below all stages
stages:
- fuzz

# Tip: Insert this part below all include
include:
- template: Security/API-Fuzzing.gitlab-ci.yml

# Tip: Insert the following variables anywhere below stages and include
variables:
  FUZZAPI_TARGET_URL: /api/fuzzing/target/url
  FUZZAPI_SCANMODE: /api/specification/file
  FUZZAPI_PROFILE: ScanProfile-1`);
  });

  it.each(Object.keys(authOptions))(
    'does not include authentication variables if %s option is missing',
    (option) => {
      const options = omit({ ...basicOptions, ...authOptions }, option);
      const output = buildConfigurationSnippet(options);

      expect(output).not.toBe('');
      expect(output).not.toContain('FUZZAPI_HTTP_PASSWORD');
      expect(output).not.toContain('FUZZAPI_HTTP_USERNAME');
    },
  );

  it('adds authentication variables if both options are provided', () => {
    const output = buildConfigurationSnippet({ ...basicOptions, ...authOptions });

    expect(output).toContain(`  FUZZAPI_HTTP_USERNAME: "$USERNAME"`);
    expect(output).toContain(`  FUZZAPI_HTTP_PASSWORD: "$PASSWORD"`);
  });
});
