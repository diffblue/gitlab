import { savePolicy } from 'ee/threat_monitoring/components/policy_editor/scan_execution_policy/lib/utils';
import { DEFAULT_ASSIGNED_POLICY_PROJECT } from 'ee/threat_monitoring/constants';
import assignPolicyProject from 'ee/threat_monitoring/graphql/mutations/assign_policy_project.mutation.graphql';
import createPolicyProject from 'ee/threat_monitoring/graphql/mutations/create_policy_project.mutation.graphql';
import createScanExecutionPolicy from 'ee/threat_monitoring/graphql/mutations/create_scan_execution_policy.mutation.graphql';
import { gqClient } from 'ee/threat_monitoring/utils';
import createMergeRequestMutation from '~/graphql_shared/mutations/create_merge_request.mutation.graphql';

jest.mock('ee/threat_monitoring/utils');

const defaultAssignedPolicyProject = { fullPath: 'path/to/policy-project', branch: 'main' };
const newAssignedPolicyProject = { fullPath: 'path/to/new-project', branch: 'main' };
const projectPath = 'path/to/current-project';
const yamlEditorValue = 'some yaml';
const createSavePolicyInput = (assignedPolicyProject = defaultAssignedPolicyProject) => ({
  assignedPolicyProject,
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
            errors: [],
          },
        },
      });
    } else if (mutation === assignPolicyProject) {
      return Promise.resolve({
        data: {
          securityPolicyProjectAssign: { errors: [] },
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

describe('savePolicy', () => {
  it('returns the policy project and merge request on success when a policy project does not exist', async () => {
    gqClient.mutate.mockImplementation(mockApolloResponses());

    const { currentAssignedPolicyProject, mergeRequest } = await savePolicy(
      createSavePolicyInput(DEFAULT_ASSIGNED_POLICY_PROJECT),
    );

    expect(currentAssignedPolicyProject).toStrictEqual({ ...newAssignedPolicyProject, errors: [] });
    expect(mergeRequest).toStrictEqual({ id: '01', errors: [] });
  });

  it('returns the policy project and merge request on success when a policy project does exist', async () => {
    gqClient.mutate.mockImplementation(mockApolloResponses());

    const { currentAssignedPolicyProject, mergeRequest } = await savePolicy(
      createSavePolicyInput(),
    );

    expect(currentAssignedPolicyProject).toStrictEqual(defaultAssignedPolicyProject);
    expect(mergeRequest).toStrictEqual({ id: '01', errors: [] });
  });

  it('throws when an error is detected', async () => {
    gqClient.mutate.mockImplementation(mockApolloResponses(true));

    await expect(savePolicy(createSavePolicyInput())).rejects.toThrowError(error);
  });
});
