import { invalidScanners } from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib/rules';

describe('invalidScanners', () => {
  describe('with undefined rules', () => {
    it('returns false', () => {
      expect(invalidScanners(undefined)).toBe(false);
    });
  });

  describe('with empty rules', () => {
    it('returns false', () => {
      expect(invalidScanners([])).toBe(false);
    });
  });

  describe('with rules with valid scanners', () => {
    it('returns false', () => {
      expect(invalidScanners([{ scanners: ['sast'] }])).toBe(false);
    });
  });

  describe('with rules without scanners', () => {
    it('returns true', () => {
      expect(invalidScanners([{ anotherKey: 'anotherValue' }])).toBe(true);
    });
  });

  describe('with rules with invalid scanners', () => {
    it('returns true', () => {
      expect(invalidScanners([{ scanners: ['notValid'] }])).toBe(true);
    });
  });
});
