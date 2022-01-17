import {
  humanizeRules,
  humanizeAction,
  NO_RULE_MESSAGE,
} from 'ee/threat_monitoring/components/policy_editor/scan_result_policy/lib';

jest.mock('~/locale', () => ({
  getPreferredLocales: jest.fn().mockReturnValue(['en']),
  sprintf: jest.requireActual('~/locale').sprintf,
  s__: jest.requireActual('~/locale').s__, // eslint-disable-line no-underscore-dangle
  n__: jest.requireActual('~/locale').n__, // eslint-disable-line no-underscore-dangle
}));

const mockActions = [
  { type: 'require_approval', approvals_required: 2, user_approvers: ['o.leticia.conner'] },
  {
    type: 'require_approval',
    approvals_required: 2,
    group_approvers: ['security_group/all_members'],
  },
  {
    type: 'require_approval',
    approvals_required: 2,
    group_approvers_ids: [10],
  },
  {
    type: 'require_approval',
    approvals_required: 2,
    user_approvers_ids: [5],
  },
  {
    type: 'require_approval',
    approvals_required: 2,
    user_approvers: ['o.leticia.conner'],
    group_approvers: ['security_group/all_members'],
    group_approvers_ids: [10],
    user_approvers_ids: [5],
  },
];

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

describe('humanizeRules', () => {
  it('returns the empty rules message in an Array if no rules are specified', () => {
    expect(humanizeRules([])).toStrictEqual([NO_RULE_MESSAGE]);
  });

  it('returns a single rule as a human-readable string for user approvers only', () => {
    expect(humanizeRules([mockRules[0]])).toStrictEqual([
      'The sast scanner finds a critical vulnerability in an open merge request targeting the main branch.',
    ]);
  });

  it('returns multiple rules with different number of branches as human-readable strings', () => {
    expect(humanizeRules(mockRules)).toStrictEqual([
      'The sast scanner finds a critical vulnerability in an open merge request targeting the main branch.',
      'The dast or sast scanners find info or critical vulnerabilities in an open merge request targeting the master or main branches.',
    ]);
  });
});

describe('humanizeAction', () => {
  it('returns a single action as a human-readable string for user approvers only', () => {
    expect(humanizeAction(mockActions[0])).toEqual(
      'Require 2 approvals from o.leticia.conner if any of the following occur:',
    );
  });

  it('returns a single action as a human-readable string for group approvers only', () => {
    expect(humanizeAction(mockActions[1])).toEqual(
      'Require 2 approvals from members of the group security_group/all_members if any of the following occur:',
    );
  });

  it('returns a single action as a human-readable string for group approvers ids only', () => {
    expect(humanizeAction(mockActions[2])).toEqual(
      'Require 2 approvals from members of the group with id 10 if any of the following occur:',
    );
  });

  it('returns a single action as a human-readable string for user approvers ids only', () => {
    expect(humanizeAction(mockActions[3])).toEqual(
      'Require 2 approvals from user with id 5 if any of the following occur:',
    );
  });

  it('returns a single action as a human-readable string with all approvers types', () => {
    expect(humanizeAction(mockActions[4])).toEqual(
      'Require 2 approvals from o.leticia.conner or user with id 5 or members of the group security_group/all_members or members of the group with id 10 if any of the following occur:',
    );
  });
});
