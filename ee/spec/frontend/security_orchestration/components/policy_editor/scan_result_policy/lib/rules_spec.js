import MockAdapter from 'axios-mock-adapter';
import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import axios from '~/lib/utils/axios_utils';
import {
  getInvalidBranches,
  invalidScanners,
  invalidVulnerabilitiesAllowed,
  invalidVulnerabilityStates,
  invalidBranchType,
  invalidVulnerabilityAge,
  VULNERABILITY_STATE_KEYS,
  humanizeInvalidBranchesError,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib/rules';
import {
  APPROVAL_VULNERABILITY_STATES,
  NEWLY_DETECTED,
  PREVIOUSLY_EXISTING,
  AGE_DAY,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/constants';
import {
  ANY_OPERATOR,
  GREATER_THAN_OPERATOR,
} from 'ee/security_orchestration/components/policy_editor/constants';

describe('invalidScanners', () => {
  describe('with undefined rules', () => {
    it('returns false', () => {
      expect(invalidScanners(undefined)).toBe(false);
    });
  });

  describe('with empty rules', () => {
    it('returns false', () => {
      expect(invalidScanners([])).toBe(false);
    });
  });

  describe('with rules with valid scanners', () => {
    it('returns false', () => {
      expect(invalidScanners([{ scanners: ['sast'] }])).toBe(false);
    });
  });

  describe('with rules without scanners', () => {
    it('returns true', () => {
      expect(invalidScanners([{ anotherKey: 'anotherValue' }])).toBe(false);
    });
  });

  describe('with rules with invalid scanners', () => {
    it('returns true', () => {
      expect(invalidScanners([{ scanners: ['notValid'] }])).toBe(true);
    });
  });
});

describe('getInvalidBranches', () => {
  const projectId = 3;
  const branches = {
    valid: {
      name: 'main',
      endpoint: `/api/undefined/projects/${projectId}/protected_branches/main`,
      response: HTTP_STATUS_OK,
    },
    invalid: {
      name: 'invalidBranch',
      endpoint: `/api/undefined/projects/${projectId}/protected_branches/invalidBranch`,
      response: HTTP_STATUS_NOT_FOUND,
    },
  };
  const getBranchesValues = (types, property) => {
    return types.map((type) => branches[type][property]);
  };

  let mock;

  beforeAll(() => {
    mock = new MockAdapter(axios);
    mock
      .onGet(branches.valid.endpoint)
      .reply(branches.valid.response)
      .onGet(branches.invalid.endpoint)
      .reply(branches.invalid.response);
  });

  afterAll(() => {
    mock.restore();
  });

  it.each`
    title                                                                                          | input                     | output
    ${'returns [] passed only valid branches names'}                                               | ${['valid', 'valid']}     | ${[]}
    ${'returns invalid branch names when passed only invalid branch names'}                        | ${['invalid']}            | ${[branches.invalid.name]}
    ${'returns only one invalid branch name when passed a non-unique set of invalid branch names'} | ${['invalid', 'invalid']} | ${[branches.invalid.name]}
    ${'returns invalid branch names when passed a mix of valid and invalid branch names'}          | ${['invalid', 'valid']}   | ${[branches.invalid.name]}
  `('$title', async ({ input, output }) => {
    const response = await getInvalidBranches({
      branches: getBranchesValues(input, 'name'),
      projectId,
    });
    expect(response).toStrictEqual(output);
  });
});

describe('invalidVulnerabilitiesAllowed', () => {
  it.each`
    rules                                    | expectedResult
    ${null}                                  | ${false}
    ${[]}                                    | ${false}
    ${[{}]}                                  | ${false}
    ${[{ vulnerabilities_allowed: 0 }]}      | ${false}
    ${[{ vulnerabilities_allowed: 'test' }]} | ${true}
    ${[{ vulnerabilities_allowed: 1.1 }]}    | ${true}
    ${[{ vulnerabilities_allowed: -1 }]}     | ${true}
    ${[{ scanners: [] }]}                    | ${false}
  `('returns $expectedResult when rules are set to $rules', ({ rules, expectedResult }) => {
    expect(invalidVulnerabilitiesAllowed(rules)).toBe(expectedResult);
  });
});

describe('invalidVulnerabilityStates', () => {
  const newlyDetectedStates = Object.keys(APPROVAL_VULNERABILITY_STATES[NEWLY_DETECTED]);
  const previouslyExistingStates = Object.keys(APPROVAL_VULNERABILITY_STATES[PREVIOUSLY_EXISTING]);

  it.each`
    rules                                                                   | expectedResult
    ${null}                                                                 | ${false}
    ${[]}                                                                   | ${false}
    ${[{}]}                                                                 | ${false}
    ${[{ vulnerability_states: [] }]}                                       | ${false}
    ${[{ vulnerability_states: newlyDetectedStates }]}                      | ${false}
    ${[{ vulnerability_states: previouslyExistingStates }]}                 | ${false}
    ${[{ vulnerability_states: VULNERABILITY_STATE_KEYS }]}                 | ${false}
    ${[{ vulnerability_states: ['invalid'] }]}                              | ${true}
    ${[{ vulnerability_states: [...newlyDetectedStates, 'invalid'] }]}      | ${true}
    ${[{ vulnerability_states: [...previouslyExistingStates, 'invalid'] }]} | ${true}
  `('returns $expectedResult with $rules', ({ rules, expectedResult }) => {
    expect(invalidVulnerabilityStates(rules)).toStrictEqual(expectedResult);
  });

  describe('invalidBranchType', () => {
    it.each`
      rules                                                                                 | expectedResult
      ${null}                                                                               | ${false}
      ${[]}                                                                                 | ${false}
      ${''}                                                                                 | ${false}
      ${[{}]}                                                                               | ${false}
      ${[{ branches: [] }]}                                                                 | ${false}
      ${[{ branch_type: 'invalid' }]}                                                       | ${true}
      ${[{ branch_type: 'protected' }, { branch_type: 'default' }]}                         | ${false}
      ${[{ branch_type: 'protected' }, { branch_type: 'default' }, { branch_type: 'all' }]} | ${true}
    `('returns $expectedResult with $rules', ({ rules, expectedResult }) => {
      expect(invalidBranchType(rules)).toBe(expectedResult);
    });
  });
});

describe('invalidVulnerabilityAge', () => {
  const validStates = { vulnerability_states: ['detected'] };
  const validAge = {
    vulnerability_age: { operator: GREATER_THAN_OPERATOR, value: 1, interval: AGE_DAY },
  };

  it.each`
    rules                                                                                                                         | expectedResult
    ${null}                                                                                                                       | ${false}
    ${[]}                                                                                                                         | ${false}
    ${[{}]}                                                                                                                       | ${false}
    ${[{ ...validStates, ...validAge }]}                                                                                          | ${false}
    ${[{ vulnerability_states: ['new_needs_triage', 'detected'], ...validAge }]}                                                  | ${false}
    ${[{ vulnerability_states: ['new_needs_triage'], ...validAge }]}                                                              | ${true}
    ${[{ vulnerability_states: [], ...validAge }]}                                                                                | ${true}
    ${[{ ...validAge }]}                                                                                                          | ${true}
    ${[{ ...validStates, vulnerability_age: {} }]}                                                                                | ${true}
    ${[{ ...validStates, vulnerability_age: { operator: ANY_OPERATOR } }]}                                                        | ${true}
    ${[{ ...validStates, vulnerability_age: { value: 1 } }]}                                                                      | ${true}
    ${[{ ...validStates, vulnerability_age: { interval: AGE_DAY } }]}                                                             | ${true}
    ${[{ ...validStates, vulnerability_age: { operator: 'invalid', value: 1, interval: AGE_DAY } }]}                              | ${true}
    ${[{ ...validStates, vulnerability_age: { operator: GREATER_THAN_OPERATOR, value: -1, interval: AGE_DAY } }]}                 | ${true}
    ${[{ ...validStates, vulnerability_age: { operator: GREATER_THAN_OPERATOR, value: 'invalid', interval: AGE_DAY } }]}          | ${true}
    ${[{ ...validStates, vulnerability_age: { operator: GREATER_THAN_OPERATOR, value: 1, interval: 'invalid' } }]}                | ${true}
    ${[{ ...validStates, vulnerability_age: { operator: GREATER_THAN_OPERATOR, value: 1, interval: AGE_DAY, invalidKey: 'a' } }]} | ${true}
  `('returns $expectedResult with $rules', ({ rules, expectedResult }) => {
    expect(invalidVulnerabilityAge(rules)).toStrictEqual(expectedResult);
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
