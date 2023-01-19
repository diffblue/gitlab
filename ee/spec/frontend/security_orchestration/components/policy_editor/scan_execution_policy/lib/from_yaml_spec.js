import {
  createPolicyObject,
  fromYaml,
  hasRuleModeSupportedScanners,
} from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/lib/from_yaml';
import {
  unsupportedManifest,
  unsupportedManifestObject,
} from 'ee_jest/security_orchestration/mocks/mock_data';
import {
  mockDastScanExecutionManifest,
  mockDastWithTagsScanExecutionManifest,
  mockDastScanExecutionObject,
  mockDastWithTagsScanExecutionObject,
  mockInvalidCadenceScanExecutionObject,
} from 'ee_jest/security_orchestration/mocks/mock_scan_execution_policy_data';

describe('fromYaml', () => {
  it.each`
    title                                                                                                | input                                                                                             | output
    ${'returns the policy object for a supported manifest'}                                              | ${{ manifest: mockDastScanExecutionManifest }}                                                    | ${mockDastScanExecutionObject}
    ${'returns the error object for a policy with an unsupported attribute'}                             | ${{ manifest: unsupportedManifest, validateRuleMode: true }}                                      | ${{ error: true }}
    ${'returns the policy object for a policy with the `tags` attribute when `includeTags` is true'}     | ${{ manifest: mockDastWithTagsScanExecutionManifest, validateRuleMode: true, includeTags: true }} | ${mockDastWithTagsScanExecutionObject}
    ${'returns the error object for a policy with the `tags` attribute when `includeTags` is false'}     | ${{ manifest: mockDastWithTagsScanExecutionManifest, validateRuleMode: true }}                    | ${{ error: true }}
    ${'returns the policy object for a policy with an unsupported attribute when validation is skipped'} | ${{ manifest: unsupportedManifest }}                                                              | ${unsupportedManifestObject}
    ${'returns error object for a policy with invalid cadence cron string'}                              | ${{ manifest: mockInvalidCadenceScanExecutionObject, validateRuleMode: true }}                    | ${{ error: true }}
  `('$title', ({ input, output }) => {
    expect(fromYaml(input)).toStrictEqual(output);
  });
});

describe('createPolicyObject', () => {
  it.each`
    title                                                                                                       | input                                             | output
    ${'returns the policy object and no errors for a supported manifest'}                                       | ${[mockDastScanExecutionManifest]}                | ${{ policy: mockDastScanExecutionObject, hasParsingError: false }}
    ${'returns the error policy object and the error for an unsupported manifest'}                              | ${[unsupportedManifest]}                          | ${{ policy: { error: true }, hasParsingError: true }}
    ${'returns the policy object and no errors for a manifest with tags in it if `includeTags` is true'}        | ${[mockDastWithTagsScanExecutionManifest, true]}  | ${{ policy: mockDastWithTagsScanExecutionObject, hasParsingError: false }}
    ${'returns the error policy object and the error for a manifest with tags in it if `includeTags` is false'} | ${[mockDastWithTagsScanExecutionManifest, false]} | ${{ policy: { error: true }, hasParsingError: true }}
  `('$title', ({ input, output }) => {
    expect(createPolicyObject(...input)).toStrictEqual(output);
  });
});

describe('hasRuleModeSupportedScanners', () => {
  it.each`
    title                                                 | input                                                                    | output
    ${'return true when all scanners are supported'}      | ${{ actions: [{ scan: 'sast' }, { scan: 'dast' }] }}                     | ${true}
    ${'return false when not all scanners are supported'} | ${{ actions: [{ scan: 'sast' }, { scan: 'cluster_image_scanning' }] }}   | ${false}
    ${'return true when no actions on policy'}            | ${{ name: 'test' }}                                                      | ${true}
    ${'return false when no valid scanners'}              | ${{ actions: [{ scan2: 'sast' }, { scan3: 'cluster_image_scanning' }] }} | ${false}
  `('$title', ({ input, output }) => {
    expect(hasRuleModeSupportedScanners(input)).toBe(output);
  });
});
