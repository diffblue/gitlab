import {
  assignSecurityPolicyProject,
  modifyPolicy,
  convertScannersToTitleCase,
} from 'ee/threat_monitoring/components/policy_editor/utils';
import { DEFAULT_ASSIGNED_POLICY_PROJECT } from 'ee/threat_monitoring/constants';
import createPolicyProject from 'ee/threat_monitoring/graphql/mutations/create_policy_project.mutation.graphql';
import createScanExecutionPolicy from 'ee/threat_monitoring/graphql/mutations/create_scan_execution_policy.mutation.graphql';
import { gqClient } from 'ee/threat_monitoring/utils';
import createMergeRequestMutation from '~/graphql_shared/mutations/create_merge_request.mutation.graphql';

jest.mock('ee/threat_monitoring/utils');

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

    await expect(assignSecurityPolicyProject(projectPath)).rejects.toThrowError(error);
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

    await expect(modifyPolicy(createSavePolicyInput())).rejects.toThrowError(error);
  });
});

describe('convertScannersToTitleCase', () => {
  it.each`
    title                                            | input                                                 | output
    ${'returns empty array if no imput is provided'} | ${undefined}                                          | ${[]}
    ${'returns empty array for an empty array'}      | ${[]}                                                 | ${[]}
    ${'returns converted array'}                     | ${['dast', 'container_scanning', 'secret_detection']} | ${['Dast', 'Container Scanning', 'Secret Detection']}
  `('$title', ({ input, output }) => {
    expect(convertScannersToTitleCase(input)).toStrictEqual(output);
  });
});
