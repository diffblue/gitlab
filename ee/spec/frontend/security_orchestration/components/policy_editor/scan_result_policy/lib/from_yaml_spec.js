import {
  createPolicyObject,
  fromYaml,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib';
import {
  mockDefaultBranchesScanResultManifest,
  mockDefaultBranchesScanResultObject,
} from 'ee_jest/security_orchestration/mocks/mock_scan_result_policy_data';
import {
  unsupportedManifest,
  unsupportedManifestObject,
} from 'ee_jest/security_orchestration/mocks/mock_data';

describe('fromYaml', () => {
  it.each`
    title                                                                                                | input                                                        | output
    ${'returns the policy object for a supported manifest'}                                              | ${{ manifest: mockDefaultBranchesScanResultManifest }}       | ${mockDefaultBranchesScanResultObject}
    ${'returns the error object for a policy with an unsupported attribute'}                             | ${{ manifest: unsupportedManifest, validateRuleMode: true }} | ${{ error: true }}
    ${'returns the policy object for a policy with an unsupported attribute when validation is skipped'} | ${{ manifest: unsupportedManifest }}                         | ${unsupportedManifestObject}
  `('$title', ({ input, output }) => {
    expect(fromYaml(input)).toStrictEqual(output);
  });
});

describe('createPolicyObject', () => {
  it.each`
    title                                                                          | input                                      | output
    ${'returns the policy object and no errors for a supported manifest'}          | ${[mockDefaultBranchesScanResultManifest]} | ${{ policy: mockDefaultBranchesScanResultObject, hasParsingError: false }}
    ${'returns the error policy object and the error for an unsupported manifest'} | ${[unsupportedManifest]}                   | ${{ policy: { error: true }, hasParsingError: true }}
  `('$title', ({ input, output }) => {
    expect(createPolicyObject(...input)).toStrictEqual(output);
  });
});
