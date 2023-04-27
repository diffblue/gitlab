import Vue from 'vue';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import apolloProvider from 'ee/vue_shared/security_configuration/graphql/provider';
import NewPolicyApp from './components/policy_editor/new_policy.vue';
import { DEFAULT_ASSIGNED_POLICY_PROJECT } from './constants';
import { decomposeApproversV2 } from './utils';

export default (el, namespaceType) => {
  const {
    assignedPolicyProject,
    disableScanPolicyUpdate,
    createAgentHelpPath,
    globalGroupApproversEnabled,
    namespaceId,
    namespacePath,
    policiesPath,
    policy,
    policyEditorEmptyStateSvgPath,
    policyType,
    roleApproverTypes,
    rootNamespacePath,
    scanPolicyDocumentationPath,
    scanResultApprovers,
    softwareLicenses,
  } = el.dataset;

  const policyProject = JSON.parse(assignedPolicyProject);

  // TODO use convertToCamelCase on the approvers with the removal of the `:scan_result_role_action` feature flag (https://gitlab.com/gitlab-org/gitlab/-/issues/377866)
  let scanResultPolicyApprovers;
  if (gon.features?.scanResultRoleAction) {
    scanResultPolicyApprovers = scanResultApprovers
      ? decomposeApproversV2(JSON.parse(scanResultApprovers))
      : {};
  } else {
    scanResultPolicyApprovers = scanResultApprovers ? JSON.parse(scanResultApprovers) : [];
  }

  return new Vue({
    el,
    apolloProvider,
    provide: {
      createAgentHelpPath,
      disableScanPolicyUpdate: parseBoolean(disableScanPolicyUpdate),
      globalGroupApproversEnabled: parseBoolean(globalGroupApproversEnabled),
      namespaceId,
      namespacePath,
      namespaceType,
      policyEditorEmptyStateSvgPath,
      policyType,
      policiesPath,
      roleApproverTypes: JSON.parse(roleApproverTypes),
      rootNamespacePath,
      scanPolicyDocumentationPath,
      scanResultPolicyApprovers,
      softwareLicenses,
      existingPolicy: policy ? { type: policyType, ...JSON.parse(policy) } : undefined,
      assignedPolicyProject: policyProject
        ? convertObjectPropsToCamelCase(policyProject)
        : DEFAULT_ASSIGNED_POLICY_PROJECT,
    },
    render(createElement) {
      return createElement(NewPolicyApp);
    },
  });
};
