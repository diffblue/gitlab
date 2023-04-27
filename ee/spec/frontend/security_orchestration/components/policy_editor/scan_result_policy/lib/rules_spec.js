import MockAdapter from 'axios-mock-adapter';
import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import axios from '~/lib/utils/axios_utils';
import {
  getInvalidBranches,
  invalidScanners,
  invalidVulnerabilitiesAllowed,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib/rules';

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
    payload                                | expectedResult
    ${{ vulnerabilities_allowed: 'test' }} | ${true}
    ${{ vulnerabilities_allowed: 1.1 }}    | ${true}
    ${{ vulnerabilities_allowed: -1 }}     | ${true}
    ${{ scanners: [] }}                    | ${false}
  `('returns $expectedResult when payload is set to $payload', ({ payload, expectedResult }) => {
    expect(invalidVulnerabilitiesAllowed([payload])).toBe(expectedResult);
  });
});
