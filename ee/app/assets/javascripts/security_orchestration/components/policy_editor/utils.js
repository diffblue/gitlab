import { isValidCron } from 'cron-validator';
import { convertToTitleCase, humanize, slugify as slugifyUtility } from '~/lib/utils/text_utility';
import createPolicyProject from 'ee/security_orchestration/graphql/mutations/create_policy_project.mutation.graphql';
import createScanExecutionPolicy from 'ee/security_orchestration/graphql/mutations/create_scan_execution_policy.mutation.graphql';
import { gqClient } from 'ee/security_orchestration/utils';
import createMergeRequestMutation from '~/graphql_shared/mutations/create_merge_request.mutation.graphql';
import { DEFAULT_MR_TITLE, SECURITY_POLICY_ACTIONS } from './constants';

/**
 * Checks if an error exists and throws it if it does
 * @param {Object} payload contains the errors if they exist
 */
const checkForErrors = ({ errors }) => {
  if (errors?.length) {
    throw new Error(errors.join('\n'));
  }
};

/**
 * Creates a merge request for the changes to the policy file
 * @param {Object} payload contains the path to the parent project, the branch to merge on the project, and the branch to merge into
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
const updatePolicy = async ({
  action = SECURITY_POLICY_ACTIONS.APPEND,
  name,
  namespacePath,
  yamlEditorValue,
}) => {
  const {
    data: {
      scanExecutionPolicyCommit: { branch, errors },
    },
  } = await gqClient.mutate({
    mutation: createScanExecutionPolicy,
    variables: {
      mode: action,
      name,
      fullPath: namespacePath,
      policyYaml: yamlEditorValue,
    },
  });

  return { branch, errors };
};

/**
 * Updates the assigned security policy project's policy file with the new policy yaml or creates one file if one does not exist
 * @param {Object} payload contains the currently assigned security policy project (if one exists), the path to the project, and the policy yaml value
 * @returns {Object} contains the currently assigned security policy project and the created merge request
 */
export const modifyPolicy = async ({
  action,
  assignedPolicyProject,
  name,
  namespacePath,
  yamlEditorValue,
}) => {
  const newPolicyCommitBranch = await updatePolicy({
    action,
    name,
    namespacePath,
    yamlEditorValue,
  });

  checkForErrors(newPolicyCommitBranch);

  const mergeRequest = await createMergeRequest({
    projectPath: assignedPolicyProject.fullPath,
    sourceBranch: newPolicyCommitBranch.branch,
    targetBranch: assignedPolicyProject.branch,
  });

  checkForErrors(mergeRequest);

  return mergeRequest;
};

/**
 * Creates a new security policy project and assigns it to the current project
 * @param {String} fullPath
 * @returns {Object} contains the new security policy project and any errors
 */
export const assignSecurityPolicyProject = async (fullPath) => {
  const {
    data: {
      securityPolicyProjectCreate: { project, errors },
    },
  } = await gqClient.mutate({
    mutation: createPolicyProject,
    variables: {
      fullPath,
    },
  });

  checkForErrors({ errors });

  return { ...project, branch: project?.branch?.rootRef, errors };
};

/**
 * Converts scanner strings to title case
 * @param {Array} scanners (e.g. 'container_scanning', `dast`, etcetera)
 * @returns {Array} (e.g. 'Container Scanning', `Dast`, etcetera)
 */
export const convertScannersToTitleCase = (scanners = []) =>
  scanners.map((scanner) => convertToTitleCase(humanize(scanner)));

/**
 * Checks for parameters unsupported by the policy "Rule Mode"
 * @param {Object} policy policy converted from YAML
 * @returns {Boolean} whether the YAML is valid to be parsed into "Rule Mode"
 */
export const isValidPolicy = ({
  policy = {},
  primaryKeys = [],
  rulesKeys = [],
  actionsKeys = [],
}) => {
  const hasInvalidKey = (object, allowedValues) => {
    return !Object.keys(object).every((item) => allowedValues.includes(item));
  };

  if (
    hasInvalidKey(policy, primaryKeys) ||
    policy.rules?.some((rule) => hasInvalidKey(rule, rulesKeys)) ||
    policy.actions?.some((action) => hasInvalidKey(action, actionsKeys))
  ) {
    return false;
  }

  return true;
};

/**
 * Replaces whitespace and non-sluggish characters with a given separator and returns array of values
 * @param str - The string to slugify
 * @param separator - The separator used to separate words (defaults to "-")
 * @returns {String[]}
 */
export const slugifyToArray = (str, separator = '-') =>
  slugifyUtility(str, separator).split(',').filter(Boolean);

/**
 * Validate cadence cron string if it exists in rule
 * @param policy
 * @returns {Boolean}
 */
export const hasInvalidCron = (policy) => {
  const hasInvalidCronString = (cronString) => (cronString ? !isValidCron(cronString) : false);

  return (policy.rules || []).some((rule) => hasInvalidCronString(rule?.cadence));
};

/**
 * Replaces whitespace and non-sluggish characters with a given separator
 * @param {String} str - The string to slugify
 * @param {String=} separator - The separator used to separate words (defaults to "-")
 * @returns {String}
 */
export const slugify = (str, separator = '-') => {
  const slug = str
    .trim()
    .replace(/[^a-zA-Z0-9_.*-/]+/g, separator)
    // Remove any duplicate separators or separator prefixes/suffixes
    .split(separator)
    .filter(Boolean)
    .join(separator);

  return slug === separator ? '' : slug;
};
