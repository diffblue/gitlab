import MockAdapter from 'axios-mock-adapter';
import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import axios from '~/lib/utils/axios_utils';
import {
  getInvalidBranches,
  invalidScanners,
  invalidVulnerabilitiesAllowed,
  invalidVulnerabilityStates,
  VULNERABILITY_STATE_KEYS,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib/rules';
import {
  APPROVAL_VULNERABILITY_STATES,
  NEWLY_DETECTED,
  PREVIOUSLY_EXISTING,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/constants';

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
});
