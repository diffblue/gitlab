import { SCANNER_DAST } from '../constants';

export function buildScannerAction(scan) {
  const action = { scan };

  if (scan === SCANNER_DAST) {
    action.site_profile = '';
    action.scanner_profile = '';
  }

  return action;
}
