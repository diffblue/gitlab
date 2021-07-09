import assignPolicyProject from 'ee/threat_monitoring/graphql/mutations/assign_policy_project.mutation.graphql';
import createPolicyProject from 'ee/threat_monitoring/graphql/mutations/create_policy_project.mutation.graphql';
import createScanExecutionPolicy from 'ee/threat_monitoring/graphql/mutations/create_scan_execution_policy.mutation.graphql';
import { gqClient } from 'ee/threat_monitoring/utils';
import createMergeRequestMutation from '~/graphql_shared/mutations/create_merge_request.mutation.graphql';
import { DEFAULT_MR_TITLE } from './constants';

/**
 * Checks if an error exists and throws it if it does
 * @param {Object} payload contains the errors if they exist
 */
const checkForErrors = ({ errors }) => {
  if (errors?.length) {
    throw new Error(errors);
  }
};

/**
 * Creates a new security policy project and assigns it to the current project
 * @param {String} projectPath
 * @returns {Object} contains the new security policy project and any errors
 */
const assignSecurityPolicyProject = async (projectPath) => {
  const {
    data: {
      securityPolicyProjectCreate: { project, errors: createErrors },
    },
  } = await gqClient.mutate({
    mutation: createPolicyProject,
    variables: {
      projectPath,
    },
  });

  checkForErrors({ errors: createErrors });

  const {
    data: {
      securityPolicyProjectAssign: { errors: assignErrors },
    },
  } = await gqClient.mutate({
    mutation: assignPolicyProject,
    variables: {
      projectPath,
      id: project.id,
    },
  });

  return { ...project, errors: assignErrors };
};

/**
 * Creates a merge request for the changes to the policy file
 * @param {Object} payload contains the path to the project, the branch to merge on the project, and the branch to merge into
 * @returns {Object} contains the id of the merge request and any errors
 */
const createMergeRequest = async ({ projectPath, sourceBranch, targetBranch }) => {
  const input = {
    projectPath,
    sourceBranch,
    targetBranch,
    title: DEFAULT_MR_TITLE,
  };

  const {
    data: {
      mergeRequestCreate: {
        mergeRequest: { iid: id },
        errors,
      },
    },
  } = await gqClient.mutate({
    mutation: createMergeRequestMutation,
    variables: { input },
  });

  return { id, errors };
};

/**
 * Creates a new security policy on the security policy project's policy file
 * @param {Object} payload contains the path to the project and the policy yaml value
 * @returns {Object} contains the branch containing the updated policy file and any errors
 */
const updatePolicy = async ({ projectPath, yamlEditorValue }) => {
  const {
    data: {
      scanExecutionPolicyCommit: { branch, errors },
    },
  } = await gqClient.mutate({
    mutation: createScanExecutionPolicy,
    variables: {
      projectPath,
      policyYaml: yamlEditorValue,
    },
  });

  return { branch, errors };
};

/**
 * Updates the assigned security policy project's policy file with the new policy yaml or creates one (project or file) if one does not exist
 * @param {Object} payload contains the currently assigned security policy project (if one exists), the path to the project, and the policy yaml value
 * @returns {Object} contains the currently assigned security policy project and the created merge request
 */
export const savePolicy = async ({ assignedPolicyProject, projectPath, yamlEditorValue }) => {
  let currentAssignedPolicyProject = assignedPolicyProject;

  if (!currentAssignedPolicyProject.fullPath) {
    currentAssignedPolicyProject = await assignSecurityPolicyProject(projectPath);
  }

  checkForErrors(currentAssignedPolicyProject);

  const newPolicyCommitBranch = await updatePolicy({
    projectPath: currentAssignedPolicyProject.fullPath,
    yamlEditorValue,
  });

  checkForErrors(newPolicyCommitBranch);

  const mergeRequest = await createMergeRequest({
    projectPath: currentAssignedPolicyProject.fullPath,
    sourceBranch: newPolicyCommitBranch.branch,
    targetBranch: currentAssignedPolicyProject.branch,
  });

  checkForErrors(mergeRequest);

  return { currentAssignedPolicyProject, mergeRequest };
};
