import {
  createPolicyObject,
  fromYaml,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib';
import {
  collidingKeysScanResultManifest,
  mockDefaultBranchesScanResultManifest,
  mockDefaultBranchesScanResultObject,
  mockApprovalSettingsScanResultManifest,
  mockApprovalSettingsScanResultObject,
} from 'ee_jest/security_orchestration/mocks/mock_scan_result_policy_data';
import {
  unsupportedManifest,
  unsupportedManifestObject,
} from 'ee_jest/security_orchestration/mocks/mock_data';

describe('fromYaml', () => {
  it.each`
    title                                                                                                | input                                                                    | output
    ${'returns the policy object for a supported manifest'}                                              | ${{ manifest: mockDefaultBranchesScanResultManifest }}                   | ${mockDefaultBranchesScanResultObject}
    ${'returns the error object for a policy with an unsupported attribute'}                             | ${{ manifest: unsupportedManifest, validateRuleMode: true }}             | ${{ error: true }}
    ${'returns the error object for a policy with colliding self excluded keys'}                         | ${{ manifest: collidingKeysScanResultManifest, validateRuleMode: true }} | ${{ error: true }}
    ${'returns the policy object for a policy with an unsupported attribute when validation is skipped'} | ${{ manifest: unsupportedManifest }}                                     | ${unsupportedManifestObject}
  `('$title', ({ input, output }) => {
    expect(fromYaml(input)).toStrictEqual(output);
  });

  describe('feature flag', () => {
    it.each`
      title                                                                                                               | input                                                                                                                           | output
      ${'returns the policy object for a manifest with `approval_settings` and the `scan_result_policy` feature flag on'} | ${{ manifest: mockApprovalSettingsScanResultManifest, validateRuleMode: true, glFeatures: { scanResultPolicySettings: true } }} | ${mockApprovalSettingsScanResultObject}
      ${'returns the error object for a manifest with `approval_settings` and the `scan_result_policy` feature flag off'} | ${{ manifest: mockApprovalSettingsScanResultManifest, validateRuleMode: true }}                                                 | ${{ error: true }}
    `('$title', ({ input, output }) => {
      expect(fromYaml(input)).toStrictEqual(output);
    });
  });
});

describe('createPolicyObject', () => {
  it.each`
    title                                                                          | input                                      | output
    ${'returns the policy object and no errors for a supported manifest'}          | ${[mockDefaultBranchesScanResultManifest]} | ${{ policy: mockDefaultBranchesScanResultObject, hasParsingError: false }}
    ${'returns the error policy object and the error for an unsupported manifest'} | ${[unsupportedManifest]}                   | ${{ policy: { error: true }, hasParsingError: true }}
    ${'returns the error policy object and the error for an colliding keys'}       | ${[collidingKeysScanResultManifest]}       | ${{ policy: { error: true }, hasParsingError: true }}
  `('$title', ({ input, output }) => {
    expect(createPolicyObject(...input)).toStrictEqual(output);
  });

  describe('feature flag', () => {
    it.each`
      title                                                                                                               | input                                                                           | output
      ${'returns the policy object for a manifest with `approval_settings` and the `scan_result_policy` feature flag on'} | ${[mockApprovalSettingsScanResultManifest, { scanResultPolicySettings: true }]} | ${{ policy: mockApprovalSettingsScanResultObject, hasParsingError: false }}
      ${'returns the error object for a manifest with `approval_settings` and the `scan_result_policy` feature flag off'} | ${[mockApprovalSettingsScanResultManifest]}                                     | ${{ policy: { error: true }, hasParsingError: true }}
    `('$title', ({ input, output }) => {
      expect(createPolicyObject(...input)).toStrictEqual(output);
    });
  });
});
