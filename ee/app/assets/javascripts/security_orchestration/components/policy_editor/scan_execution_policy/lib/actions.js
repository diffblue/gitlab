import { SCANNER_DAST } from '../constants';

export function buildScannerAction({ scanner, siteProfile = '', scannerProfile = '' }) {
  const action = { scan: scanner, tags: [] };

  if (scanner === SCANNER_DAST) {
    action.site_profile = siteProfile;
    action.scanner_profile = scannerProfile;
  }

  return action;
}
