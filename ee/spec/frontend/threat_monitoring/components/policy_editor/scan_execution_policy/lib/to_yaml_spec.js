import { toYaml } from 'ee/threat_monitoring/components/policy_editor/scan_execution_policy/lib';
import {
  mockDastScanExecutionManifest,
  mockDastScanExecutionObject,
} from 'ee_jest/threat_monitoring/mocks/mock_data';

describe('toYaml', () => {
  it('returns policy object as yaml', () => {
    expect(toYaml(mockDastScanExecutionObject)).toBe(mockDastScanExecutionManifest);
  });
});
