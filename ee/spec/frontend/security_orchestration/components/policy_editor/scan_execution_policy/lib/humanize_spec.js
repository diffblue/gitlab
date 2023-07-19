import {
  humanizeActions,
  humanizeRules,
} from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/lib';
import {
  ACTIONS,
  INVALID_RULE_MESSAGE,
  NO_RULE_MESSAGE,
} from 'ee/security_orchestration/components/policy_editor/constants';

jest.mock('~/locale', () => ({
  getPreferredLocales: jest.fn().mockReturnValue(['en']),
  sprintf: jest.requireActual('~/locale').sprintf,
  languageCode: jest.requireActual('~/locale').languageCode,
  s__: jest.requireActual('~/locale').s__, // eslint-disable-line no-underscore-dangle
  n__: jest.requireActual('~/locale').n__, // eslint-disable-line no-underscore-dangle
  __: jest.requireActual('~/locale').__,
}));

const mockActions = [
  { scan: 'dast', scanner_profile: 'Scanner Profile', site_profile: 'Site Profile' },
  { scan: 'dast', scanner_profile: 'Scanner Profile 01', site_profile: 'Site Profile 01' },
  { scan: 'secret_detection' },
  { scan: 'container_scanning' },
];

const mockRules = [
  { type: 'pipeline' },
  { type: 'schedule', cadence: '*/10 * * * *', branches: ['main'] },
  { type: 'pipeline', branches: ['release/*', 'staging'] },
  { type: 'pipeline', branches: ['release/1.*', 'canary', 'staging'] },
  {
    type: 'schedule',
    cadence: '* */20 4 * *',
    agents: { 'default-agent': null },
  },
  {
    type: 'schedule',
    cadence: '* */20 4 * *',
    agents: { 'default-agent': { namespaces: [] } },
  },
  {
    type: 'schedule',
    cadence: '* */20 4 * *',
    agents: {
      'default-agent': { namespaces: ['production'] },
    },
  },
  {
    type: 'schedule',
    cadence: '* */20 4 * *',
    agents: {
      'default-agent': { namespaces: ['staging', 'releases'] },
    },
  },
  {
    type: 'schedule',
    cadence: '* */20 4 * *',
    agents: {
      'default-agent': { namespaces: ['staging', 'releases', 'dev'] },
    },
  },
];
const mockDefaultTagsAction = {
  message: 'Automatically selected runners',
  tags: [],
  action: ACTIONS.tags,
};

const mockRulesBranchType = [
  { type: 'pipeline', branch_type: 'invalid' },
  { type: 'pipeline', branch_type: 'protected' },
  { type: 'pipeline', branch_type: 'default' },
  {
    type: 'schedule',
    cadence: '* */20 4 * *',
    branch_type: 'protected',
  },
];

describe('humanizeActions', () => {
  it('returns an empty Array of actions as an empty Set', () => {
    expect(humanizeActions([])).toStrictEqual([]);
  });

  it('returns a single action as human-readable string', () => {
    expect(humanizeActions([mockActions[0]])).toStrictEqual([
      {
        message: 'Run %{scannerStart}DAST%{scannerEnd} with the following options:',
        criteriaList: [mockDefaultTagsAction],
      },
    ]);
  });

  it('returns multiple actions as human-readable strings', () => {
    expect(humanizeActions(mockActions)).toStrictEqual([
      {
        message: 'Run %{scannerStart}DAST%{scannerEnd} with the following options:',
        criteriaList: [mockDefaultTagsAction],
      },
      {
        message: 'Run %{scannerStart}Secret Detection%{scannerEnd} with the following options:',
        criteriaList: [mockDefaultTagsAction],
      },
      {
        message: 'Run %{scannerStart}Container Scanning%{scannerEnd} with the following options:',
        criteriaList: [mockDefaultTagsAction],
      },
    ]);
  });

  describe('with tags', () => {
    const mockActionsWithTags = [
      { scan: 'sast', tags: ['one-tag'] },
      { scan: 'secret_detection', tags: ['two-tag', 'three-tag'] },
      { scan: 'container_scanning', tags: ['four-tag', 'five-tag', 'six-tag'] },
    ];

    it.each`
      title                   | input                       | output
      ${'one tag'}            | ${[mockActionsWithTags[0]]} | ${[{ message: 'Run %{scannerStart}SAST%{scannerEnd} with the following options:', criteriaList: [{ message: 'On runners with tag:', tags: mockActionsWithTags[0].tags, action: ACTIONS.tags }] }]}
      ${'two tags'}           | ${[mockActionsWithTags[1]]} | ${[{ message: 'Run %{scannerStart}Secret Detection%{scannerEnd} with the following options:', criteriaList: [{ message: 'On runners with the tags:', tags: mockActionsWithTags[1].tags, action: ACTIONS.tags }] }]}
      ${'more than two tags'} | ${[mockActionsWithTags[2]]} | ${[{ message: 'Run %{scannerStart}Container Scanning%{scannerEnd} with the following options:', criteriaList: [{ message: 'On runners with the tags:', tags: mockActionsWithTags[2].tags, action: ACTIONS.tags }] }]}
    `('$title', ({ input, output }) => {
      expect(humanizeActions(input)).toStrictEqual(output);
    });
  });

  describe('with variables', () => {
    const mockActionsWithVariables = [
      { scan: 'sast', variables: [] },
      { scan: 'secret_detection', variables: { variable1: 'value1', variable2: 'value2' } },
    ];

    it.each`
      title             | input                            | output
      ${'no variables'} | ${[mockActionsWithVariables[0]]} | ${[{ message: 'Run %{scannerStart}SAST%{scannerEnd} with the following options:', criteriaList: [mockDefaultTagsAction] }]}
      ${'variables'}    | ${[mockActionsWithVariables[1]]} | ${[{ message: 'Run %{scannerStart}Secret Detection%{scannerEnd} with the following options:', criteriaList: [mockDefaultTagsAction, { message: 'With the following customized CI variables:', variables: [{ variable: 'variable1', value: 'value1' }, { variable: 'variable2', value: 'value2' }], action: ACTIONS.variables }] }]}
    `('$title', ({ input, output }) => {
      expect(humanizeActions(input)).toStrictEqual(output);
    });
  });
});

describe('humanizeRules', () => {
  it('returns the empty rules message in an Array if no rules are specified', () => {
    expect(humanizeRules([])).toStrictEqual([NO_RULE_MESSAGE]);
  });

  it('returns the empty rules message in an Array if a single rule is passed in without a branch or agent', () => {
    expect(humanizeRules([mockRules[0]])).toStrictEqual([NO_RULE_MESSAGE]);
  });

  it('returns rules with different number of branches as human-readable strings', () => {
    expect(humanizeRules(mockRules)).toStrictEqual([
      'every 10 minutes, every hour, every day on the main branch',
      'Every time a pipeline runs for the release/* and staging branches',
      'Every time a pipeline runs for the release/1.*, canary and staging branches',
      'by the agent named default-agent for all namespaces every minute, every 20 hours, on day 4 of the month',
      'by the agent named default-agent for all namespaces every minute, every 20 hours, on day 4 of the month',
      'by the agent named default-agent for the production namespace every minute, every 20 hours, on day 4 of the month',
      'by the agent named default-agent for the staging and releases namespaces every minute, every 20 hours, on day 4 of the month',
      'by the agent named default-agent for the staging, releases and dev namespaces every minute, every 20 hours, on day 4 of the month',
    ]);
  });

  it('returns the empty rules message in an Array if a single rule is passed in without an invalid branch type', () => {
    expect(humanizeRules([mockRulesBranchType[0]])).toStrictEqual([INVALID_RULE_MESSAGE]);
  });

  it('returns rules with different branch types as human-readable strings', () => {
    expect(humanizeRules(mockRulesBranchType)).toStrictEqual([
      INVALID_RULE_MESSAGE,
      'Every time a pipeline runs for any protected branch',
      'Every time a pipeline runs for the default branch',
      'every minute, every 20 hours, on day 4 of the month on any protected branch',
    ]);
  });
});
