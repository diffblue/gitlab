import { s__ } from '~/locale';
import Api from 'ee/api';
import { REPORT_TYPES_DEFAULT } from 'ee/security_dashboard/store/constants';
import { isPositiveInteger } from '~/lib/utils/number_utils';
import {
  APPROVAL_VULNERABILITY_STATES,
  NEWLY_DETECTED,
  PREVIOUSLY_EXISTING,
} from '../scan_filters/constants';

const REPORT_TYPES_KEYS = Object.keys(REPORT_TYPES_DEFAULT);

export const VULNERABILITY_STATE_KEYS = [
  NEWLY_DETECTED,
  ...Object.keys(APPROVAL_VULNERABILITY_STATES[NEWLY_DETECTED]),
  ...Object.keys(APPROVAL_VULNERABILITY_STATES[PREVIOUSLY_EXISTING]),
];

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

/**
 * Check if all rule values of certain key are included in the allowedValues list
 * @param {Array} rules - List of rules
 * @param {String} key - Rule key to check
 * @param {Array} allowedValues - List of possible values
 * @returns
 */
const invalidRuleValues = (rules, key, allowedValues) => {
  if (!rules) {
    return false;
  }

  return rules
    .filter((rule) => rule[key])
    .flatMap((rule) => rule[key])
    .some((value) => !allowedValues.includes(value));
};

export const invalidScanners = (rules) => invalidRuleValues(rules, 'scanners', REPORT_TYPES_KEYS);

export const invalidVulnerabilityStates = (rules) =>
  invalidRuleValues(rules, 'vulnerability_states', VULNERABILITY_STATE_KEYS);

export const invalidVulnerabilitiesAllowed = (rules) => {
  if (!rules) {
    return false;
  }

  return rules
    .filter((rule) => rule.vulnerabilities_allowed)
    .map((rule) => rule.vulnerabilities_allowed)
    .some((value) => !isPositiveInteger(value));
};
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
