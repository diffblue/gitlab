import { fromYaml } from 'ee/threat_monitoring/components/policy_editor/scan_execution_policy/lib';
import {
  mockDastScanExecutionManifest,
  mockDastScanExecutionObject,
} from 'ee_jest/threat_monitoring/mocks/mock_data';

describe('fromYaml', () => {
  it('returns policy object', () => {
    expect(fromYaml(mockDastScanExecutionManifest)).toStrictEqual(mockDastScanExecutionObject);
  });
});
