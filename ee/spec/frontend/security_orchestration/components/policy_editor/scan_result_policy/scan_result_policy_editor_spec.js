import Vuex from 'vuex';
import { shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import Api from 'ee/api';
import waitForPromises from 'helpers/wait_for_promises';
import PolicyEditorLayout from 'ee/security_orchestration/components/policy_editor/policy_editor_layout.vue';
import {
  DEFAULT_SCAN_RESULT_POLICY,
  DEFAULT_SCAN_RESULT_POLICY_V2,
  fromYaml,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib';
import ScanResultPolicyEditor from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_result_policy_editor.vue';
import {
  DEFAULT_ASSIGNED_POLICY_PROJECT,
  NAMESPACE_TYPES,
} from 'ee/security_orchestration/constants';
import {
  mockScanResultManifest,
  mockScanResultObject,
} from 'ee_jest/security_orchestration/mocks/mock_data';
import { visitUrl } from '~/lib/utils/url_utility';

import { modifyPolicy } from 'ee/security_orchestration/components/policy_editor/utils';
import {
  SECURITY_POLICY_ACTIONS,
  EDITOR_MODE_RULE,
  PARSING_ERROR_MESSAGE,
} from 'ee/security_orchestration/components/policy_editor/constants';
import DimDisableContainer from 'ee/security_orchestration/components/policy_editor/dim_disable_container.vue';
import PolicyActionBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/policy_action_builder.vue';
import PolicyRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/policy_rule_builder.vue';
import ScanResultPoliciesStore from 'ee/security_orchestration/store/modules/scan_result_policies';
import axios from '~/lib/utils/axios_utils';
import httpStatus from '~/lib/utils/http_status';

jest.mock('~/lib/utils/url_utility', () => ({
  joinPaths: jest.requireActual('~/lib/utils/url_utility').joinPaths,
  visitUrl: jest.fn().mockName('visitUrlMock'),
  setUrlFragment: jest.requireActual('~/lib/utils/url_utility').setUrlFragment,
}));

const newlyCreatedPolicyProject = {
  branch: 'main',
  fullPath: 'path/to/new-project',
};
jest.mock('ee/security_orchestration/components/policy_editor/utils', () => ({
  assignSecurityPolicyProject: jest.fn().mockResolvedValue({
    branch: 'main',
    fullPath: 'path/to/new-project',
  }),
  modifyPolicy: jest.fn().mockResolvedValue({ id: '2' }),
  isValidPolicy: jest.requireActual('ee/security_orchestration/components/policy_editor/utils')
    .isValidPolicy,
}));

Vue.use(Vuex);

describe('ScanResultPolicyEditor', () => {
  let mock;
  let wrapper;
  const defaultProjectPath = 'path/to/project';
  const policyEditorEmptyStateSvgPath = 'path/to/svg';
  const scanPolicyDocumentationPath = 'path/to/docs';
  const assignedPolicyProject = {
    branch: 'main',
    fullPath: 'path/to/existing-project',
  };
  const scanResultPolicyApprovers = [{ id: 1, username: 'the.one', state: 'active' }];

  const factory = ({ propsData = {}, provide = {} } = {}) => {
    const store = new Vuex.Store({
      modules: {
        scanResultPolicies: ScanResultPoliciesStore(),
      },
    });

    wrapper = shallowMount(ScanResultPolicyEditor, {
      store,
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
        ...provide,
      },
    });
    nextTick();
  };

  const factoryWithExistingPolicy = (policy = {}, provide = {}) => {
    return factory({
      propsData: {
        assignedPolicyProject,
        existingPolicy: { ...mockScanResultObject, ...policy },
        isEditing: true,
      },
      provide,
    });
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findPolicyEditorLayout = () => wrapper.findComponent(PolicyEditorLayout);
  const findPolicyActionBuilder = () => wrapper.findComponent(PolicyActionBuilder);
  const findAllPolicyActionBuilders = () => wrapper.findAllComponents(PolicyActionBuilder);
  const findAddRuleButton = () => wrapper.find('[data-testid="add-rule"]');
  const findAllDisabledComponents = () => wrapper.findAllComponents(DimDisableContainer);
  const findAllRuleBuilders = () => wrapper.findAllComponents(PolicyRuleBuilder);

  const changesToRuleMode = async () => {
    findPolicyEditorLayout().vm.$emit('update-editor-mode', EDITOR_MODE_RULE);
    await nextTick();
  };

  const verifiesParsingError = () => {
    expect(findPolicyEditorLayout().props('hasParsingError')).toBe(true);
    expect(findPolicyEditorLayout().attributes('parsingerror')).toBe(PARSING_ERROR_MESSAGE);
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
  });

  describe('default', () => {
    it.each`
      policyConfig                     | licenseScanningPoliciesFlag
      ${DEFAULT_SCAN_RESULT_POLICY}    | ${false}
      ${DEFAULT_SCAN_RESULT_POLICY_V2} | ${true}
    `(
      'with licenseScanningPolices flag set to $licenseScanningPoliciesFlag it loads the correct policy config',
      async ({ policyConfig, licenseScanningPoliciesFlag }) => {
        factory({
          provide: {
            glFeatures: { licenseScanningPolicies: licenseScanningPoliciesFlag },
          },
        });
        await nextTick();
        expect(findPolicyEditorLayout().props('yamlEditorValue')).toEqual(policyConfig);
      },
    );

    it('does not display an error', async () => {
      factory();
      await nextTick();

      expect(findPolicyEditorLayout().props('hasParsingError')).toBe(false);
    });

    it('updates the policy yaml when "update-yaml" is emitted', async () => {
      const newManifest = 'new yaml!';
      factory();
      await nextTick();

      expect(findPolicyEditorLayout().attributes('yamleditorvalue')).toBe(
        DEFAULT_SCAN_RESULT_POLICY,
      );

      findPolicyEditorLayout().vm.$emit('update-yaml', newManifest);
      await nextTick();

      expect(findPolicyEditorLayout().attributes('yamleditorvalue')).toBe(newManifest);
    });

    it('displays the initial rule and add rule button', async () => {
      factory();
      await nextTick();

      expect(findAllRuleBuilders().length).toBe(1);
      expect(findAddRuleButton().exists()).toBe(true);
    });

    it('disables all rule mode related components when the yaml is invalid', async () => {
      factory();
      await nextTick();

      findPolicyEditorLayout().vm.$emit('update-yaml', 'invalid manifest');
      await nextTick();

      expect(findAllDisabledComponents().at(0).props('disabled')).toBe(true);
      expect(findAllDisabledComponents().at(1).props('disabled')).toBe(true);
    });

    it('defaults to rule mode', async () => {
      factory();
      await nextTick();

      expect(findPolicyEditorLayout().attributes().defaulteditormode).toBe(EDITOR_MODE_RULE);
    });

    it('uses name from policy rule builder', async () => {
      const newPolicyName = 'new policy name';
      factory();
      await nextTick();
      findPolicyEditorLayout().vm.$emit('set-policy-property', 'name', newPolicyName);
      findPolicyEditorLayout().vm.$emit('save-policy');
      await waitForPromises();

      expect(modifyPolicy).toHaveBeenCalledWith(
        expect.objectContaining({
          name: newPolicyName,
        }),
      );
    });

    it.each`
      component        | oldValue | newValue
      ${'name'}        | ${''}    | ${'new policy name'}
      ${'description'} | ${''}    | ${'new description'}
      ${'enabled'}     | ${true}  | ${false}
    `('triggers a change on $component', async ({ component, newValue, oldValue }) => {
      factory();
      await nextTick();

      expect(findPolicyEditorLayout().props('policy')[component]).toBe(oldValue);

      findPolicyEditorLayout().vm.$emit('set-policy-property', component, newValue);
      await nextTick();

      expect(findPolicyEditorLayout().props('policy')[component]).toBe(newValue);
    });

    it.each`
      status                            | action                             | event              | factoryFn                    | yamlEditorValue               | currentlyAssignedPolicyProject
      ${'to save a new policy'}         | ${SECURITY_POLICY_ACTIONS.APPEND}  | ${'save-policy'}   | ${factory}                   | ${DEFAULT_SCAN_RESULT_POLICY} | ${newlyCreatedPolicyProject}
      ${'to update an existing policy'} | ${SECURITY_POLICY_ACTIONS.REPLACE} | ${'save-policy'}   | ${factoryWithExistingPolicy} | ${mockScanResultManifest}     | ${assignedPolicyProject}
      ${'to delete an existing policy'} | ${SECURITY_POLICY_ACTIONS.REMOVE}  | ${'remove-policy'} | ${factoryWithExistingPolicy} | ${mockScanResultManifest}     | ${assignedPolicyProject}
    `(
      'navigates to the new merge request when "modifyPolicy" is emitted $status',
      async ({ action, event, factoryFn, yamlEditorValue, currentlyAssignedPolicyProject }) => {
        factoryFn();
        await nextTick();

        findPolicyEditorLayout().vm.$emit(event);

        await waitForPromises();

        expect(modifyPolicy).toHaveBeenCalledWith({
          action,
          assignedPolicyProject: currentlyAssignedPolicyProject,
          name:
            action === SECURITY_POLICY_ACTIONS.APPEND
              ? fromYaml(yamlEditorValue).name
              : mockScanResultObject.name,
          namespacePath: defaultProjectPath,
          yamlEditorValue,
        });
        expect(visitUrl).toHaveBeenCalledWith(
          `/${currentlyAssignedPolicyProject.fullPath}/-/merge_requests/2`,
        );
      },
    );

    it('adds a new rule', async () => {
      const rulesCount = 1;
      factory();
      await nextTick();

      expect(findAllRuleBuilders().length).toBe(rulesCount);

      findAddRuleButton().vm.$emit('click');
      await nextTick();

      expect(findAllRuleBuilders()).toHaveLength(rulesCount + 1);
    });

    it('hides add button when the limit of five rules has been reached', async () => {
      const limit = 5;
      const rule = mockScanResultObject.rules[0];
      factoryWithExistingPolicy({ rules: [rule, rule, rule, rule, rule] });
      await nextTick();

      expect(findAllRuleBuilders()).toHaveLength(limit);
      expect(findAddRuleButton().exists()).toBe(false);
    });

    it('updates an existing rule', async () => {
      const newValue = {
        type: 'scan_finding',
        branches: [],
        scanners: [],
        vulnerabilities_allowed: 1,
        severity_levels: [],
        vulnerability_states: [],
      };
      factory();
      await nextTick();
      findAllRuleBuilders().at(0).vm.$emit('changed', newValue);
      await nextTick();

      expect(wrapper.vm.policy.rules[0]).toEqual(newValue);
      expect(findPolicyEditorLayout().props('policy').rules[0].vulnerabilities_allowed).toBe(1);
    });

    it('deletes the initial rule', async () => {
      const initialRuleCount = 1;
      factory();
      await nextTick();

      expect(findAllRuleBuilders()).toHaveLength(initialRuleCount);

      findAllRuleBuilders().at(0).vm.$emit('remove', 0);
      await nextTick();

      expect(findAllRuleBuilders()).toHaveLength(initialRuleCount - 1);
    });
  });

  describe('when a user is not an owner of the project', () => {
    it('displays the empty state with the appropriate properties', async () => {
      factory({ provide: { disableScanPolicyUpdate: true } });
      await nextTick();

      const emptyState = findEmptyState();

      expect(emptyState.props('primaryButtonLink')).toMatch(scanPolicyDocumentationPath);
      expect(emptyState.props('primaryButtonLink')).toMatch('scan-result-policy-editor');
      expect(emptyState.props('svgPath')).toBe(policyEditorEmptyStateSvgPath);
    });
  });

  describe('with policy action builder', () => {
    it('renders a single policy action builder', async () => {
      factory();

      await nextTick();

      expect(findAllPolicyActionBuilders()).toHaveLength(1);
      expect(findPolicyActionBuilder().props('existingApprovers')).toEqual(
        scanResultPolicyApprovers,
      );
    });

    it('updates policy action when edited', async () => {
      const UPDATED_ACTION = { type: 'required_approval', group_approvers_ids: [1] };
      factory();

      await nextTick();
      findPolicyActionBuilder().vm.$emit('changed', UPDATED_ACTION);
      await nextTick();

      expect(findPolicyActionBuilder().props('initAction')).toEqual(UPDATED_ACTION);
    });
  });

  describe('errors', () => {
    it('creates an error for invalid yaml', async () => {
      factory();
      await nextTick();

      findPolicyEditorLayout().vm.$emit('update-yaml', 'invalid manifest');
      await nextTick();

      verifiesParsingError();
    });

    it('creates an error when policy does not match existing approvers', async () => {
      factory();
      await nextTick();
      await changesToRuleMode();
      verifiesParsingError();
    });

    it('creates an error when policy scanners are invalid', async () => {
      factoryWithExistingPolicy({ rules: [{ scanners: ['cluster_image_scanning'] }] });
      await nextTick();
      await changesToRuleMode();
      verifiesParsingError();
    });

    it('does not create an error when policy matches existing approvers', async () => {
      factoryWithExistingPolicy();
      await nextTick();
      await changesToRuleMode();
      expect(findPolicyEditorLayout().props('hasParsingError')).toBe(false);
    });
  });

  it.each`
    status                  | errorMessage
    ${httpStatus.OK}        | ${''}
    ${httpStatus.NOT_FOUND} | ${'The following branches do not exist on this development project: main. Please review all protected branches to ensure the values are accurate before updating this policy.'}
  `(
    'triggers error event with content: "$errorMessage" when http status is $status',
    async ({ status, errorMessage }) => {
      const rule = { ...mockScanResultObject.rules[0], branches: ['main'] };

      mock.onGet('/api/undefined/projects/1/protected_branches/main').replyOnce(status, {});

      factoryWithExistingPolicy({ rules: [rule] });

      await findPolicyEditorLayout().vm.$emit('update-editor-mode', EDITOR_MODE_RULE);
      await waitForPromises();
      const errors = wrapper.emitted('error');

      expect(errors[errors.length - 1]).toEqual([errorMessage]);
    },
  );

  it('does not query protected branches when namespaceType is other than project', async () => {
    jest.spyOn(Api, 'projectProtectedBranch');

    factoryWithExistingPolicy({}, { namespaceType: NAMESPACE_TYPES.GROUP });

    await findPolicyEditorLayout().vm.$emit('update-editor-mode', EDITOR_MODE_RULE);
    await waitForPromises();

    expect(Api.projectProtectedBranch).not.toHaveBeenCalled();
  });
});
