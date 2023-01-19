import { toYaml } from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/lib';
import {
  mockDastScanExecutionManifest,
  mockDastScanExecutionObject,
} from 'ee_jest/security_orchestration/mocks/mock_scan_execution_policy_data';

describe('toYaml', () => {
  it('returns policy object as yaml', () => {
    expect(toYaml(mockDastScanExecutionObject)).toBe(mockDastScanExecutionManifest);
  });
});
