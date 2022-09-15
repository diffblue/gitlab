import { fromYaml } from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/lib';
import {
  unsupportedYaml,
  mockDastScanExecutionManifest,
  mockDastScanExecutionObject,
} from 'ee_jest/security_orchestration/mocks/mock_data';

describe('fromYaml', () => {
  it('returns policy object', () => {
    expect(fromYaml(mockDastScanExecutionManifest)).toStrictEqual(mockDastScanExecutionObject);
  });

  it('returns the error object if there is an error', () => {
    expect(fromYaml(unsupportedYaml)).toStrictEqual({ error: true });
  });
});
