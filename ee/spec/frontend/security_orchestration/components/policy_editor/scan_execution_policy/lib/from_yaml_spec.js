import {
  createPolicyObject,
  fromYaml,
} from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/lib';
import {
  unsupportedYamlManifest,
  unsupportedYamlObject,
  mockDastScanExecutionManifest,
  mockDastScanExecutionObject,
} from 'ee_jest/security_orchestration/mocks/mock_data';

describe('fromYaml', () => {
  it.each`
    title                                                                                                | input                                                            | output
    ${'returns the policy object for a supported manifest'}                                              | ${{ manifest: mockDastScanExecutionManifest }}                   | ${mockDastScanExecutionObject}
    ${'returns the error object for a policy with an unsupported attribute'}                             | ${{ manifest: unsupportedYamlManifest, validateRuleMode: true }} | ${{ error: true }}
    ${'returns the policy object for a policy with an unsupported attribute when validation is skipped'} | ${{ manifest: unsupportedYamlManifest }}                         | ${unsupportedYamlObject}
  `('$title', ({ input, output }) => {
    expect(fromYaml(input)).toStrictEqual(output);
  });
});

describe('createPolicyObject', () => {
  it.each`
    title                                                                      | input                            | output
    ${'returns the policy object and no errors for a supported manifest'}      | ${mockDastScanExecutionManifest} | ${{ policy: mockDastScanExecutionObject, hasParsingError: false }}
    ${'returns the error policy object and the error an unsupported manifest'} | ${unsupportedYamlManifest}       | ${{ policy: { error: true }, hasParsingError: true }}
  `('$title', ({ input, output }) => {
    expect(createPolicyObject(input)).toStrictEqual(output);
  });
});
