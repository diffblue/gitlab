import {
  humanizeRules,
  humanizeInvalidBranchesError,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib';
import { NO_RULE_MESSAGE } from 'ee/security_orchestration/components/policy_editor/constants';

jest.mock('~/locale', () => ({
  getPreferredLocales: jest.fn().mockReturnValue(['en']),
  sprintf: jest.requireActual('~/locale').sprintf,
  s__: jest.requireActual('~/locale').s__, // eslint-disable-line no-underscore-dangle
  n__: jest.requireActual('~/locale').n__, // eslint-disable-line no-underscore-dangle
  __: jest.requireActual('~/locale').__,
}));

const mockRules = [
  {
    type: 'scan_finding',
    branches: ['main'],
    scanners: ['sast'],
    vulnerabilities_allowed: 1,
    severity_levels: ['critical'],
    vulnerability_states: ['newly_detected'],
  },
  {
    type: 'scan_finding',
    branches: ['master', 'main'],
    scanners: ['dast', 'sast'],
    vulnerabilities_allowed: 2,
    severity_levels: ['info', 'critical'],
    vulnerability_states: ['resolved'],
  },
];

const ALL_SCANNERS_RULE = {
  type: 'scan_finding',
  branches: ['master', 'main'],
  scanners: [],
  vulnerabilities_allowed: 2,
  severity_levels: ['info', 'critical'],
  vulnerability_states: ['resolved'],
};

const mockRulesHumanized = [
  'Sast scanner finds a critical vulnerability in an open merge request targeting the main branch.',
  'Dast or Sast scanners find info or critical vulnerabilities in an open merge request targeting the master or main branches.',
];

const mockRulesEmptyBranch = {
  type: 'scan_finding',
  branches: [],
  scanners: ['sast'],
  vulnerabilities_allowed: 1,
  severity_levels: ['critical'],
  vulnerability_states: ['newly_detected'],
};

describe('humanizeRules', () => {
  it('returns the empty rules message in an Array if no rules are specified', () => {
    expect(humanizeRules([])).toStrictEqual([NO_RULE_MESSAGE]);
  });

  it('returns a single rule as a human-readable string for user approvers only', () => {
    expect(humanizeRules([mockRules[0]])).toStrictEqual([mockRulesHumanized[0]]);
  });

  it('returns multiple rules with different number of branches as human-readable strings', () => {
    expect(humanizeRules(mockRules)).toStrictEqual(mockRulesHumanized);
  });

  it('returns a single rule as a human-readable string for all protected branches', () => {
    expect(humanizeRules([mockRulesEmptyBranch])).toStrictEqual([
      'Sast scanner finds a critical vulnerability in an open merge request targeting all protected branches.',
    ]);
  });

  it('returns a single rule as a human-readable string for all scanners', () => {
    expect(humanizeRules([ALL_SCANNERS_RULE])).toStrictEqual([
      'Any scanner finds info or critical vulnerabilities in an open merge request targeting the master or main branches.',
    ]);
  });
});

describe('humanizeInvalidBranchesError', () => {
  it('returns message without any branch name for an empty array', () => {
    expect(humanizeInvalidBranchesError([])).toEqual(
      'The following branches do not exist on this development project: . Please review all protected branches to ensure the values are accurate before updating this policy.',
    );
  });

  it('returns message with a single branch name for an array with single element', () => {
    expect(humanizeInvalidBranchesError(['main'])).toEqual(
      'The following branches do not exist on this development project: main. Please review all protected branches to ensure the values are accurate before updating this policy.',
    );
  });

  it('returns message with multiple branch names for array with multiple elements', () => {
    expect(humanizeInvalidBranchesError(['main', 'protected', 'master'])).toEqual(
      'The following branches do not exist on this development project: main, protected and master. Please review all protected branches to ensure the values are accurate before updating this policy.',
    );
  });
});
