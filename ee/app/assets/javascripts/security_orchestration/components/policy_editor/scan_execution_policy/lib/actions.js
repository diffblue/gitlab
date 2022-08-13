import { DEFAULT_SCAN } from '../constants';

export function buildDefaultAction() {
  return {
    scan: DEFAULT_SCAN,
    site_profile: '',
    scanner_profile: '',
  };
}
