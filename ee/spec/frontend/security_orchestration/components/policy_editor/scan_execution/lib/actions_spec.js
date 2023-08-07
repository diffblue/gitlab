import { buildScannerAction } from 'ee/security_orchestration/components/policy_editor/scan_execution/lib/actions';
import { SCANNER_DAST } from 'ee/security_orchestration/components/policy_editor/scan_execution/constants';

describe('buildScannerAction', () => {
  describe('DAST', () => {
    it('returns a DAST scanner action with empty profiles', () => {
      expect(buildScannerAction({ scanner: SCANNER_DAST })).toEqual({
        scan: SCANNER_DAST,
        site_profile: '',
        scanner_profile: '',
      });
    });

    it('returns a DAST scanner action with filled profiles', () => {
      const siteProfile = 'test_site_profile';
      const scannerProfile = 'test_scanner_profile';

      expect(buildScannerAction({ scanner: SCANNER_DAST, siteProfile, scannerProfile })).toEqual({
        scan: SCANNER_DAST,
        site_profile: siteProfile,
        scanner_profile: scannerProfile,
      });
    });
  });

  describe('non-DAST', () => {
    it('returns a non-DAST scanner action', () => {
      const scanner = 'sast';
      expect(buildScannerAction({ scanner })).toEqual({
        scan: scanner,
      });
    });
  });
});
