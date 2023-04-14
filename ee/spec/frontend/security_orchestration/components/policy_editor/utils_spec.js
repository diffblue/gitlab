import {
  assignSecurityPolicyProject,
  modifyPolicy,
  createHumanizedScanners,
  isValidPolicy,
  hasInvalidCron,
  slugify,
  slugifyToArray,
} from 'ee/security_orchestration/components/policy_editor/utils';
import { DEFAULT_ASSIGNED_POLICY_PROJECT } from 'ee/security_orchestration/constants';
import createPolicyProject from 'ee/security_orchestration/graphql/mutations/create_policy_project.mutation.graphql';
import createScanExecutionPolicy from 'ee/security_orchestration/graphql/mutations/create_scan_execution_policy.mutation.graphql';
import { gqClient } from 'ee/security_orchestration/utils';
import createMergeRequestMutation from '~/graphql_shared/mutations/create_merge_request.mutation.graphql';

jest.mock('ee/security_orchestration/utils');

const defaultAssignedPolicyProject = { fullPath: 'path/to/policy-project', branch: 'main' };
const newAssignedPolicyProject = {
  id: '02',
  fullPath: 'path/to/new-project',
  branch: { rootRef: 'main' },
};
const projectPath = 'path/to/current-project';
const policyName = 'policy-01';
const yamlEditorValue = `\nname: ${policyName}\ndescription: some yaml`;
const createSavePolicyInput = (assignedPolicyProject = defaultAssignedPolicyProject, action) => ({
  action,
  assignedPolicyProject,
  name: policyName,
  projectPath,
  yamlEditorValue,
});

const error = 'There was an error';

const mockApolloResponses = (shouldReject) => {
  return ({ mutation }) => {
    if (mutation === createPolicyProject) {
      return Promise.resolve({
        data: {
          securityPolicyProjectCreate: {
            project: newAssignedPolicyProject,
            errors: shouldReject ? [error] : [],
          },
        },
      });
    } else if (mutation === createScanExecutionPolicy) {
      return Promise.resolve({
        data: {
          scanExecutionPolicyCommit: {
            branch: 'new-branch',
            errors: shouldReject ? [error] : [],
          },
        },
      });
    } else if (mutation === createMergeRequestMutation) {
      return Promise.resolve({
        data: { mergeRequestCreate: { mergeRequest: { iid: '01' }, errors: [] } },
      });
    }
    return Promise.resolve();
  };
};

describe('assignSecurityPolicyProject', () => {
  it('returns the newly created policy project', async () => {
    gqClient.mutate.mockImplementation(mockApolloResponses());

    const newlyCreatedPolicyProject = await assignSecurityPolicyProject(projectPath);

    expect(newlyCreatedPolicyProject).toStrictEqual({
      branch: 'main',
      id: '02',
      errors: [],
      fullPath: 'path/to/new-project',
    });
  });

  it('throws when an error is detected', async () => {
    gqClient.mutate.mockImplementation(mockApolloResponses(true));

    await expect(assignSecurityPolicyProject(projectPath)).rejects.toThrow(error);
  });
});

describe('modifyPolicy', () => {
  it('returns the policy project and merge request on success when a policy project does not exist', async () => {
    gqClient.mutate.mockImplementation(mockApolloResponses());

    const mergeRequest = await modifyPolicy(createSavePolicyInput(DEFAULT_ASSIGNED_POLICY_PROJECT));

    expect(mergeRequest).toStrictEqual({ id: '01', errors: [] });
  });

  it('returns the policy project and merge request on success when a policy project does exist', async () => {
    gqClient.mutate.mockImplementation(mockApolloResponses());

    const mergeRequest = await modifyPolicy(createSavePolicyInput());

    expect(mergeRequest).toStrictEqual({ id: '01', errors: [] });
  });

  it('throws when an error is detected', async () => {
    gqClient.mutate.mockImplementation(mockApolloResponses(true));

    await expect(modifyPolicy(createSavePolicyInput())).rejects.toThrow(error);
  });
});

describe('createHumanizedScanners', () => {
  it.each`
    title                                            | input                                                 | output
    ${'returns empty array if no input is provided'} | ${undefined}                                          | ${[]}
    ${'returns empty array for an empty array'}      | ${[]}                                                 | ${[]}
    ${'returns converted array'}                     | ${['dast', 'container_scanning', 'secret_detection']} | ${['DAST', 'Container Scanning', 'Secret Detection']}
  `('$title', ({ input, output }) => {
    expect(createHumanizedScanners(input)).toStrictEqual(output);
  });
});

describe('isValidPolicy', () => {
  it.each`
    input                                                                                                                                          | output
    ${{}}                                                                                                                                          | ${true}
    ${{ policy: {}, primaryKeys: [], rulesKeys: [], actionsKeys: [] }}                                                                             | ${true}
    ${{ policy: { foo: 'bar' }, primaryKeys: ['foo'], rulesKeys: [], actionsKeys: [] }}                                                            | ${true}
    ${{ policy: { foo: 'bar' }, rulesKeys: [], actionsKeys: [] }}                                                                                  | ${false}
    ${{ policy: { foo: 'bar', rules: [{ zoo: 'dar' }] }, primaryKeys: ['foo', 'rules'], rulesKeys: ['zoo'], actionsKeys: [] }}                     | ${true}
    ${{ policy: { foo: 'bar', rules: [{ zoo: 'dar' }] }, primaryKeys: ['foo', 'rules'], rulesKeys: [], actionsKeys: [] }}                          | ${false}
    ${{ policy: { foo: 'bar', actions: [{ zoo: 'dar' }] }, primaryKeys: ['foo', 'actions'], rulesKeys: [], actionsKeys: ['zoo'] }}                 | ${true}
    ${{ policy: { foo: 'bar', actions: [{ zoo: 'dar' }] }, primaryKeys: ['foo', 'actions'], rulesKeys: [], actionsKeys: [] }}                      | ${false}
    ${{ policy: { foo: 'bar', actions: [{ zoo: 'dar' }, { goo: 'rar' }] }, primaryKeys: ['foo', 'actions'], rulesKeys: [], actionsKeys: ['zoo'] }} | ${false}
  `('returns `$output` when passed `$input`', ({ input, output }) => {
    expect(isValidPolicy(input)).toBe(output);
  });
});

describe('hasInvalidCron', () => {
  it.each`
    input                                                                                                      | output
    ${{ foo: 'bar', rules: [{ zoo: 'dar', cadence: '0 0 * * *' }] }}                                           | ${false}
    ${{ foo: 'bar', rules: [{ zoo: 'dar', cadence: '* 0 0 * 5' }] }}                                           | ${true}
    ${{ foo: 'bar', rules: [{ zoo: 'dar', cadence: '0 0 * asd ada' }] }}                                       | ${true}
    ${{ foo: 'bar', rules: [{ zoo: 'dar', cadence: '0 0 * asd ada' }, { zoo: 'dar', cadence: '0 0 * * *' }] }} | ${true}
  `('returns `$output` when passed `$input`', ({ input, output }) => {
    expect(hasInvalidCron(input)).toBe(output);
  });
});

const BRANCHES = [
  {
    input: 'My Input String',
    output: 'My-Input-String',
  },
  {
    input: ' a new project ',
    output: 'a-new-project',
  },
  {
    input: 'test!_bra-nch/*~',
    output: 'test-_bra-nch/*',
  },
  {
    input: 'test!!!!_pro-ject~',
    output: 'test-_pro-ject',
  },
  {
    input: 'дружба',
    output: '',
  },
  {
    input: 'Test:-)',
    output: 'Test',
  },
  {
    input: '-Test:-)-',
    output: 'Test',
  },
];

describe('slugify', () => {
  it.each`
    title                                                                                      | input                | output
    ${'should replaces whitespaces with hyphens'}                                              | ${BRANCHES[0].input} | ${BRANCHES[0].output}
    ${'should remove trailing whitespace and replace whitespaces within string with a hyphen'} | ${BRANCHES[1].input} | ${BRANCHES[1].output}
    ${'should only remove non-allowed special characters'}                                     | ${BRANCHES[2].input} | ${BRANCHES[2].output}
    ${'should squash to multiple non-allowed special characters'}                              | ${BRANCHES[3].input} | ${BRANCHES[3].output}
    ${'should return empty string if only non-allowed characters'}                             | ${BRANCHES[4].input} | ${BRANCHES[4].output}
    ${'should squash multiple separators'}                                                     | ${BRANCHES[5].input} | ${BRANCHES[5].output}
    ${'should trim any separators from the beginning and end of the slug'}                     | ${BRANCHES[6].input} | ${BRANCHES[6].output}
  `('$title', ({ input, output }) => {
    expect(slugify(input)).toBe(output);
  });
});

describe('slugifyToArray', () => {
  it('should create an array split on ","', () => {
    expect(slugifyToArray(BRANCHES.map((b) => b.input).join(','))).toEqual(
      BRANCHES.map((b) => b.output).filter(Boolean),
    );
  });
});
