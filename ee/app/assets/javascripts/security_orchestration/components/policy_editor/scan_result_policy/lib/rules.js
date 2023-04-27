import { s__ } from '~/locale';
import Api from 'ee/api';
import { REPORT_TYPES_DEFAULT } from 'ee/security_dashboard/store/constants';

const REPORT_TYPES_KEYS = Object.keys(REPORT_TYPES_DEFAULT);

export const SCAN_FINDING = 'scan_finding';
export const LICENSE_FINDING = 'license_finding';
export const MATCHING = s__('ScanResultPolicy|matching');
export const EXCEPT = s__('ScanResultPolicy|except');

export const LICENSE_STATES = {
  newly_detected: s__('ScanResultPolicy|Newly Detected'),
  detected: s__('ScanResultPolicy|Pre-existing'),
};

/*
  Construct a new rule object.
*/
export function securityScanBuildRule() {
  return {
    type: SCAN_FINDING,
    branches: [],
    scanners: [],
    vulnerabilities_allowed: 0,
    severity_levels: [],
    vulnerability_states: [],
  };
}

export function licenseScanBuildRule() {
  return {
    type: LICENSE_FINDING,
    branches: [],
    match_on_inclusion: true,
    license_types: [],
    license_states: [],
  };
}

/*
  Construct a new rule object for when the licenseScanningPolocies flag is on
*/
export function emptyBuildRule() {
  return {
    type: '',
  };
}

/*
  Check if scanners are valid for each rule.
*/
export function invalidScanners(rules) {
  return (
    rules
      ?.filter((rule) => rule.scanners)
      .flatMap((rule) => rule.scanners)
      .some((scanner) => !REPORT_TYPES_KEYS.includes(scanner)) || false
  );
}

export function invalidVulnerabilitiesAllowed(rules) {
  return rules
    .map((rule) => rule.vulnerabilities_allowed)
    .some((value) => Boolean(value) && !/^\d+$/.test(value));
}
/*
  Returns the config for a particular rule type
*/
export const getDefaultRule = (scanType) => {
  switch (scanType) {
    case SCAN_FINDING:
      return securityScanBuildRule();
    case LICENSE_FINDING:
      return licenseScanBuildRule();
    default:
      return emptyBuildRule();
  }
};

const doesBranchExist = async ({ branch, projectId }) => {
  try {
    await Api.projectProtectedBranch(projectId, branch);
    return true;
  } catch {
    return false;
  }
};

export const getInvalidBranches = async ({ branches, projectId }) => {
  const uniqueBranches = [...new Set(branches)];
  const invalidBranches = [];

  for await (const branch of uniqueBranches) {
    if (!(await doesBranchExist({ branch, projectId }))) {
      invalidBranches.push(branch);
    }
  }

  return invalidBranches;
};
