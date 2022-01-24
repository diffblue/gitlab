import {
  humanizeActions,
  humanizeRules,
} from 'ee/threat_monitoring/components/policy_editor/scan_execution_policy/lib';

import { NO_RULE_MESSAGE } from 'ee/threat_monitoring/components/policy_editor/constants';

jest.mock('~/locale', () => ({
  getPreferredLocales: jest.fn().mockReturnValue(['en']),
  sprintf: jest.requireActual('~/locale').sprintf,
  s__: jest.requireActual('~/locale').s__, // eslint-disable-line no-underscore-dangle
  n__: jest.requireActual('~/locale').n__, // eslint-disable-line no-underscore-dangle
  __: jest.requireActual('~/locale').__,
}));

const mockActions = [
  { scan: 'dast', scanner_profile: 'Scanner Profile', site_profile: 'Site Profile' },
  { scan: 'dast', scanner_profile: 'Scanner Profile 01', site_profile: 'Site Profile 01' },
  { scan: 'secret_detection' },
];

const mockRules = [
  { type: 'schedule', cadence: '*/10 * * * *', branches: ['main'] },
  { type: 'pipeline', branches: ['release/*', 'staging'] },
  { type: 'pipeline', branches: ['release/1.*', 'canary', 'staging'] },
  {
    type: 'schedule',
    cadence: '* */20 4 * *',
    clusters: { protect: { namespaces: ['default-cluster'] } },
  },
  { type: 'pipeline' },
];

describe('humanizeActions', () => {
  it('returns an empty Array of actions as an empty Set', () => {
    expect(humanizeActions([])).toStrictEqual(new Set());
  });

  it('returns a single action as human-readable string', () => {
    expect(humanizeActions([mockActions[0]])).toStrictEqual(new Set(['Executes a Dast scan']));
  });

  it('returns multiple actions as human-readable strings', () => {
    expect(humanizeActions(mockActions)).toStrictEqual(
      new Set(['Executes a Dast scan', 'Executes a Secret Detection scan']),
    );
  });
});

describe('humanizeRules', () => {
  it('returns the empty rules message in an Array if no rules are specified', () => {
    expect(humanizeRules([])).toStrictEqual([NO_RULE_MESSAGE]);
  });

  it('returns the empty rules message in an Array if a single rule is passed in without a branch or cluster', () => {
    expect(humanizeRules([mockRules[4]])).toStrictEqual([NO_RULE_MESSAGE]);
  });

  it('returns a single rule as a human-readable string', () => {
    expect(humanizeRules([mockRules[0]])).toStrictEqual([
      'Scan to be performed every 10 minutes, every hour, every day on the main branch',
    ]);
  });

  it('returns multiple rules with different number of branches as human-readable strings', () => {
    expect(humanizeRules(mockRules)).toStrictEqual([
      'Scan to be performed every 10 minutes, every hour, every day on the main branch',
      'Scan to be performed on every pipeline on the release/* and staging branches',
      'Scan to be performed on every pipeline on the release/1.*, canary and staging branches',
      'Scan to be performed every minute, every 20 hours, on day 4 of the month',
    ]);
  });
});
