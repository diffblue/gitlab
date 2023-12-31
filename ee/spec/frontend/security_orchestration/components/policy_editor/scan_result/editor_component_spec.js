import { GlEmptyState } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import SettingsSection from 'ee/security_orchestration/components/policy_editor/scan_result/settings/settings_section.vue';
import EditorLayout from 'ee/security_orchestration/components/policy_editor/editor_layout.vue';
import {
  DEFAULT_SCAN_RESULT_POLICY,
  SCAN_RESULT_POLICY_SETTINGS_POLICY,
  getInvalidBranches,
  fromYaml,
} from 'ee/security_orchestration/components/policy_editor/scan_result/lib';
import EditorComponent from 'ee/security_orchestration/components/policy_editor/scan_result/editor_component.vue';
import {
  DEFAULT_ASSIGNED_POLICY_PROJECT,
  NAMESPACE_TYPES,
  USER_TYPE,
} from 'ee/security_orchestration/constants';
import {
  mockDefaultBranchesScanResultManifest,
  mockDefaultBranchesScanResultObject,
} from 'ee_jest/security_orchestration/mocks/mock_scan_result_policy_data';
import { unsupportedManifest } from 'ee_jest/security_orchestration/mocks/mock_data';
import { visitUrl } from '~/lib/utils/url_utility';
import {
  mergeRequestConfiguration,
  protectedBranchesConfiguration,
} from 'ee/security_orchestration/components/policy_editor/scan_result/lib/settings';

import { modifyPolicy } from 'ee/security_orchestration/components/policy_editor/utils';
import {
  SECURITY_POLICY_ACTIONS,
  EDITOR_MODE_RULE,
  EDITOR_MODE_YAML,
  PARSING_ERROR_MESSAGE,
  ALL_PROTECTED_BRANCHES,
  ANY_COMMIT,
} from 'ee/security_orchestration/components/policy_editor/constants';
import DimDisableContainer from 'ee/security_orchestration/components/policy_editor/dim_disable_container.vue';
import PolicyActionBuilder from 'ee/security_orchestration/components/policy_editor/scan_result/action/action_section.vue';
import PolicyRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result/rule/rule_section.vue';

jest.mock('ee/security_orchestration/components/policy_editor/scan_result/lib', () => ({
  ...jest.requireActual('ee/security_orchestration/components/policy_editor/scan_result/lib'),
  getInvalidBranches: jest.fn().mockResolvedValue([]),
}));

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn().mockName('visitUrlMock'),
}));

const newlyCreatedPolicyProject = {
  branch: 'main',
  fullPath: 'path/to/new-project',
};
jest.mock('ee/security_orchestration/components/policy_editor/utils', () => ({
  ...jest.requireActual('ee/security_orchestration/components/policy_editor/utils'),
  assignSecurityPolicyProject: jest.fn().mockResolvedValue({
    branch: 'main',
    fullPath: 'path/to/new-project',
  }),
  modifyPolicy: jest.fn().mockResolvedValue({ id: '2' }),
}));

describe('EditorComponent', () => {
  let wrapper;
  const defaultProjectPath = 'path/to/project';
  const policyEditorEmptyStateSvgPath = 'path/to/svg';
  const scanPolicyDocumentationPath = 'path/to/docs';
  const assignedPolicyProject = {
    branch: 'main',
    fullPath: 'path/to/existing-project',
  };
  const scanResultPolicyApprovers = {
    user: [{ id: 1, username: 'the.one', state: 'active' }],
    group: [],
    role: [],
  };

  const factory = ({ propsData = {}, provide = {}, glFeatures = {} } = {}) => {
    wrapper = shallowMountExtended(EditorComponent, {
      propsData: {
        assignedPolicyProject: DEFAULT_ASSIGNED_POLICY_PROJECT,
        ...propsData,
      },
      provide: {
        disableScanPolicyUpdate: false,
        policyEditorEmptyStateSvgPath,
        namespaceId: 1,
        namespacePath: defaultProjectPath,
        namespaceType: NAMESPACE_TYPES.PROJECT,
        scanPolicyDocumentationPath,
        scanResultPolicyApprovers,
        glFeatures,
        ...provide,
      },
    });
  };

  const factoryWithExistingPolicy = (policy = {}, provide = {}) => {
    return factory({
      propsData: {
        assignedPolicyProject,
        existingPolicy: { ...mockDefaultBranchesScanResultObject, ...policy },
        isEditing: true,
      },
      provide,
    });
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findPolicyEditorLayout = () => wrapper.findComponent(EditorLayout);
  const findPolicyActionBuilder = () => wrapper.findComponent(PolicyActionBuilder);
  const findAllPolicyActionBuilders = () => wrapper.findAllComponents(PolicyActionBuilder);
  const findAddRuleButton = () => wrapper.findByTestId('add-rule');
  const findAllDisabledComponents = () => wrapper.findAllComponents(DimDisableContainer);
  const findAllRuleBuilders = () => wrapper.findAllComponents(PolicyRuleBuilder);
  const findSettingsSection = () => wrapper.findComponent(SettingsSection);

  const changesToRuleMode = () =>
    findPolicyEditorLayout().vm.$emit('update-editor-mode', EDITOR_MODE_RULE);

  const changesToYamlMode = () =>
    findPolicyEditorLayout().vm.$emit('update-editor-mode', EDITOR_MODE_YAML);

  const verifiesParsingError = () => {
    expect(findPolicyEditorLayout().props('hasParsingError')).toBe(true);
    expect(findPolicyEditorLayout().attributes('parsingerror')).toBe(PARSING_ERROR_MESSAGE);
  };

  beforeEach(() => {
    getInvalidBranches.mockClear();
  });

  describe('rendering', () => {
    describe('with "scanResultPolicySettings" feature flag enabled', () => {
      it('passes the correct yamlEditorValue prop to the PolicyEditorLayout component', () => {
        factory({ glFeatures: { scanResultPolicySettings: true } });

        expect(findPolicyEditorLayout().props('yamlEditorValue')).toBe(
          SCAN_RESULT_POLICY_SETTINGS_POLICY,
        );
      });
    });

    it.each`
      prop                 | compareFn          | expected
      ${'yamlEditorValue'} | ${'toBe'}          | ${DEFAULT_SCAN_RESULT_POLICY}
      ${'hasParsingError'} | ${'toBe'}          | ${false}
      ${'policy'}          | ${'toStrictEqual'} | ${fromYaml({ manifest: DEFAULT_SCAN_RESULT_POLICY })}
    `(
      'passes the correct $prop prop to the PolicyEditorLayout component',
      ({ prop, compareFn, expected }) => {
        factory();

        expect(findPolicyEditorLayout().props(prop))[compareFn](expected);
      },
    );

    it('displays the initial rule and add rule button', () => {
      factory();

      expect(findAllRuleBuilders()).toHaveLength(1);
      expect(findAddRuleButton().exists()).toBe(true);
    });

    it('displays the initial action', () => {
      factory();

      expect(findAllPolicyActionBuilders()).toHaveLength(1);
      expect(findPolicyActionBuilder().props('existingApprovers')).toEqual(
        scanResultPolicyApprovers,
      );
    });

    describe('when a user is not an owner of the project', () => {
      it('displays the empty state with the appropriate properties', () => {
        factory({ provide: { disableScanPolicyUpdate: true } });

        const emptyState = findEmptyState();

        expect(emptyState.props('primaryButtonLink')).toMatch(scanPolicyDocumentationPath);
        expect(emptyState.props('primaryButtonLink')).toMatch('scan-result-policy-editor');
        expect(emptyState.props('svgPath')).toBe(policyEditorEmptyStateSvgPath);
      });
    });
  });

  describe('rule mode updates', () => {
    it.each`
      component        | oldValue | newValue
      ${'name'}        | ${''}    | ${'new policy name'}
      ${'description'} | ${''}    | ${'new description'}
      ${'enabled'}     | ${true}  | ${false}
    `('triggers a change on $component', ({ component, newValue, oldValue }) => {
      factory();

      expect(findPolicyEditorLayout().props('policy')[component]).toBe(oldValue);

      findPolicyEditorLayout().vm.$emit('set-policy-property', component, newValue);

      expect(findPolicyEditorLayout().props('policy')[component]).toBe(newValue);
    });

    describe('rule builder', () => {
      it('adds a new rule', async () => {
        const rulesCount = 1;
        factory();

        expect(findAllRuleBuilders()).toHaveLength(rulesCount);

        await findAddRuleButton().vm.$emit('click');

        expect(findAllRuleBuilders()).toHaveLength(rulesCount + 1);
      });

      it('hides add button when the limit of five rules has been reached', () => {
        const limit = 5;
        const rule = mockDefaultBranchesScanResultObject.rules[0];
        factoryWithExistingPolicy({ rules: [rule, rule, rule, rule, rule] });

        expect(findAllRuleBuilders()).toHaveLength(limit);
        expect(findAddRuleButton().exists()).toBe(false);
      });

      it('updates an existing rule', () => {
        const newValue = {
          type: 'scan_finding',
          branches: [],
          scanners: [],
          vulnerabilities_allowed: 1,
          severity_levels: [],
          vulnerability_states: [],
        };
        factory();

        findAllRuleBuilders().at(0).vm.$emit('changed', newValue);

        expect(wrapper.vm.policy.rules[0]).toEqual(newValue);
        expect(findPolicyEditorLayout().props('policy').rules[0].vulnerabilities_allowed).toBe(1);
      });

      it('deletes the initial rule', async () => {
        const initialRuleCount = 1;
        factory();

        expect(findAllRuleBuilders()).toHaveLength(initialRuleCount);

        await findAllRuleBuilders().at(0).vm.$emit('remove', 0);

        expect(findAllRuleBuilders()).toHaveLength(initialRuleCount - 1);
      });
    });

    describe('action builder', () => {
      beforeEach(() => {
        factory();
      });

      it('updates policy action when edited', async () => {
        const UPDATED_ACTION = { type: 'required_approval', group_approvers_ids: [1] };
        await findPolicyActionBuilder().vm.$emit('changed', UPDATED_ACTION);

        expect(findPolicyActionBuilder().props('initAction')).toEqual(UPDATED_ACTION);
      });

      it('updates the policy approvers', async () => {
        const newApprover = ['owner'];

        await findPolicyActionBuilder().vm.$emit('updateApprovers', {
          ...scanResultPolicyApprovers,
          role: newApprover,
        });

        expect(findPolicyActionBuilder().props('existingApprovers')).toMatchObject({
          role: newApprover,
        });
      });

      it('creates an error when the action builder emits one', async () => {
        await findPolicyActionBuilder().vm.$emit('error');
        verifiesParsingError();
      });
    });
  });

  describe('yaml mode updates', () => {
    beforeEach(factory);

    it('updates the policy yaml and policy object when "update-yaml" is emitted', async () => {
      await findPolicyEditorLayout().vm.$emit('update-yaml', mockDefaultBranchesScanResultManifest);

      expect(findPolicyEditorLayout().props('yamlEditorValue')).toBe(
        mockDefaultBranchesScanResultManifest,
      );
      expect(findPolicyEditorLayout().props('policy')).toMatchObject(
        mockDefaultBranchesScanResultObject,
      );
    });

    it('disables all rule mode related components when the yaml is invalid', async () => {
      await findPolicyEditorLayout().vm.$emit('update-yaml', unsupportedManifest);

      expect(findAllDisabledComponents().at(0).props('disabled')).toBe(true);
      expect(findAllDisabledComponents().at(1).props('disabled')).toBe(true);
    });
  });

  describe('CRUD operations', () => {
    it.each`
      status                            | action                             | event              | factoryFn                    | yamlEditorValue                          | currentlyAssignedPolicyProject
      ${'to save a new policy'}         | ${SECURITY_POLICY_ACTIONS.APPEND}  | ${'save-policy'}   | ${factory}                   | ${DEFAULT_SCAN_RESULT_POLICY}            | ${newlyCreatedPolicyProject}
      ${'to update an existing policy'} | ${SECURITY_POLICY_ACTIONS.REPLACE} | ${'save-policy'}   | ${factoryWithExistingPolicy} | ${mockDefaultBranchesScanResultManifest} | ${assignedPolicyProject}
      ${'to delete an existing policy'} | ${SECURITY_POLICY_ACTIONS.REMOVE}  | ${'remove-policy'} | ${factoryWithExistingPolicy} | ${mockDefaultBranchesScanResultManifest} | ${assignedPolicyProject}
    `(
      'navigates to the new merge request when "modifyPolicy" is emitted $status',
      async ({ action, event, factoryFn, yamlEditorValue, currentlyAssignedPolicyProject }) => {
        factoryFn();

        findPolicyEditorLayout().vm.$emit(event);
        await waitForPromises();

        expect(modifyPolicy).toHaveBeenCalledWith({
          action,
          assignedPolicyProject: currentlyAssignedPolicyProject,
          name:
            action === SECURITY_POLICY_ACTIONS.APPEND
              ? fromYaml({ manifest: yamlEditorValue }).name
              : mockDefaultBranchesScanResultObject.name,
          namespacePath: defaultProjectPath,
          yamlEditorValue,
        });
        expect(visitUrl).toHaveBeenCalledWith(
          `/${currentlyAssignedPolicyProject.fullPath}/-/merge_requests/2`,
        );
      },
    );

    describe('error handling', () => {
      const error = {
        message: 'There was an error',
        cause: [{ field: 'approver_ids' }, { field: 'approver_ids' }],
      };

      beforeEach(() => {
        modifyPolicy.mockRejectedValue(error);
        factory();
      });

      describe('when in rule mode', () => {
        it('passes errors with the cause of `approver_ids` to the action builder', async () => {
          await findPolicyEditorLayout().vm.$emit('save-policy');
          await waitForPromises();

          expect(findPolicyActionBuilder().props('errors')).toEqual(error.cause);
          expect(wrapper.emitted('error')).toContainEqual(['']);
        });
      });

      describe('when in yaml mode', () => {
        beforeEach(() => changesToYamlMode());

        it('emits errors', async () => {
          await findPolicyEditorLayout().vm.$emit('save-policy');
          await waitForPromises();

          expect(findPolicyActionBuilder().props('errors')).toEqual([]);
          expect(wrapper.emitted('error')).toContainEqual([''], [error.message]);
        });
      });
    });
  });

  describe('errors', () => {
    it('creates an error for invalid yaml', async () => {
      factory();

      await findPolicyEditorLayout().vm.$emit('update-yaml', 'invalid manifest');

      verifiesParsingError();
    });

    it('creates an error when policy scanners are invalid', async () => {
      factoryWithExistingPolicy({ rules: [{ scanners: ['cluster_image_scanning'] }] });

      await changesToRuleMode();
      verifiesParsingError();
    });

    it('creates an error when policy severity_levels are invalid', async () => {
      factoryWithExistingPolicy({ rules: [{ severity_levels: ['non-existent'] }] });

      await changesToRuleMode();
      verifiesParsingError();
    });

    it('creates an error when vulnerabilities_allowed are invalid', async () => {
      factoryWithExistingPolicy({ rules: [{ vulnerabilities_allowed: 'invalid' }] });

      await changesToRuleMode();
      verifiesParsingError();
    });

    it('creates an error when vulnerability_states are invalid', async () => {
      factoryWithExistingPolicy({ rules: [{ vulnerability_states: ['invalid'] }] });

      await changesToRuleMode();
      verifiesParsingError();
    });

    it('creates an error when vulnerability_age is invalid', async () => {
      factoryWithExistingPolicy({ rules: [{ vulnerability_age: { operator: 'invalid' } }] });

      await changesToRuleMode();
      verifiesParsingError();
    });

    it('creates an error when vulnerability_attributes are invalid', async () => {
      factoryWithExistingPolicy({ rules: [{ vulnerability_attributes: [{ invalid: true }] }] });

      await changesToRuleMode();
      verifiesParsingError();
    });

    describe('existing approvers', () => {
      const existingPolicyWithUserId = {
        actions: [{ type: 'require_approval', approvals_required: 1, user_approvers_ids: [1] }],
      };

      const existingUserApprover = {
        user: [{ id: 1, username: 'the.one', state: 'active', type: USER_TYPE }],
      };
      const nonExistingUserApprover = {
        user: [{ id: 2, username: 'the.two', state: 'active', type: USER_TYPE }],
      };

      it.each`
        title         | policy                      | approver                   | output
        ${'does not'} | ${{}}                       | ${existingUserApprover}    | ${false}
        ${'does'}     | ${{}}                       | ${nonExistingUserApprover} | ${true}
        ${'does not'} | ${existingPolicyWithUserId} | ${existingUserApprover}    | ${false}
        ${'does'}     | ${existingPolicyWithUserId} | ${nonExistingUserApprover} | ${true}
      `(
        '$title create an error when the policy does not match existing approvers',
        async ({ policy, approver, output }) => {
          factoryWithExistingPolicy(policy, {
            scanResultPolicyApprovers: approver,
          });

          await changesToRuleMode();
          expect(findPolicyEditorLayout().props('hasParsingError')).toBe(output);
        },
      );
    });
  });

  describe('branches being validated', () => {
    it.each`
      status                             | value       | errorMessage
      ${'invalid branches do not exist'} | ${[]}       | ${''}
      ${'invalid branches exist'}        | ${['main']} | ${'The following branches do not exist on this development project: main. Please review all protected branches to ensure the values are accurate before updating this policy.'}
    `(
      'triggers error event with the correct content when $status',
      async ({ value, errorMessage }) => {
        const rule = { ...mockDefaultBranchesScanResultObject.rules[0], branches: ['main'] };
        getInvalidBranches.mockReturnValue(value);

        factoryWithExistingPolicy({ rules: [rule] });

        await findPolicyEditorLayout().vm.$emit('update-editor-mode', EDITOR_MODE_RULE);
        await waitForPromises();
        const errors = wrapper.emitted('error');

        expect(errors[errors.length - 1]).toEqual([errorMessage]);
      },
    );

    it('does not query protected branches when namespaceType is other than project', async () => {
      factoryWithExistingPolicy({}, { namespaceType: NAMESPACE_TYPES.GROUP });

      await findPolicyEditorLayout().vm.$emit('update-editor-mode', EDITOR_MODE_RULE);
      await waitForPromises();

      expect(getInvalidBranches).not.toHaveBeenCalled();
    });
  });

  describe('settings', () => {
    it('does not display the settings section', () => {
      factory();

      expect(findSettingsSection().exists()).toBe(false);
    });

    describe('with "scanResultPolicySettings" feature flag enabled', () => {
      it('displays setting section', () => {
        factory({ glFeatures: { scanResultPolicySettings: true } });

        expect(findSettingsSection().exists()).toBe(true);
        expect(findSettingsSection().props('settings')).toEqual(protectedBranchesConfiguration);
      });

      it('updates the policy when a change is emitted', async () => {
        factory({ glFeatures: { scanResultPolicySettings: true } });

        await findSettingsSection().vm.$emit('changed', {
          block_protected_branch_modification: {
            enabled: false,
          },
        });

        expect(findPolicyEditorLayout().props('yamlEditorValue')).toContain(
          `block_protected_branch_modification:
    enabled: false`,
        );
      });

      it('has merge request approval settings for merge request rule', async () => {
        factory({ glFeatures: { scanResultPolicySettings: true } });

        const scanRule = {
          type: 'scan_finding',
          branches: [],
          scanners: [],
          vulnerabilities_allowed: 1,
          severity_levels: [],
          vulnerability_states: [],
        };

        await findAllRuleBuilders().at(0).vm.$emit('changed', scanRule);

        expect(findSettingsSection().props('settings')).toEqual({
          ...protectedBranchesConfiguration,
        });

        const anyMergeRequestRule = {
          type: 'any_merge_request',
          branch_type: ALL_PROTECTED_BRANCHES.value,
          commits: ANY_COMMIT,
        };

        await findAllRuleBuilders().at(0).vm.$emit('changed', anyMergeRequestRule);

        expect(findSettingsSection().props('settings')).toEqual({
          ...protectedBranchesConfiguration,
          ...mergeRequestConfiguration,
        });
      });
    });
  });
});
