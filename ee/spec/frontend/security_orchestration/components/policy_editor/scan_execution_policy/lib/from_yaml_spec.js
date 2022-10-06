import {
  createPolicyObject,
  fromYaml,
  hasRuleModeSupportedScanners,
} from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/lib/from_yaml';
import {
  unsupportedYamlManifest,
  unsupportedYamlObject,
  mockDastScanExecutionManifest,
  mockDastScanExecutionObject,
  rulesWithInvalidCadence,
} from 'ee_jest/security_orchestration/mocks/mock_data';

describe('fromYaml', () => {
  it.each`
    title                                                                                                | input                                                            | output
    ${'returns the policy object for a supported manifest'}                                              | ${{ manifest: mockDastScanExecutionManifest }}                   | ${mockDastScanExecutionObject}
    ${'returns the error object for a policy with an unsupported attribute'}                             | ${{ manifest: unsupportedYamlManifest, validateRuleMode: true }} | ${{ error: true }}
    ${'returns the policy object for a policy with an unsupported attribute when validation is skipped'} | ${{ manifest: unsupportedYamlManifest }}                         | ${unsupportedYamlObject}
    ${'returns error object for a policy with invalid cadence cron string'}                              | ${{ manifest: rulesWithInvalidCadence, validateRuleMode: true }} | ${{ error: true }}
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
