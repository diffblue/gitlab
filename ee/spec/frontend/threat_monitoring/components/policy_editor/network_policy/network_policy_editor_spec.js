import { GlEmptyState, GlFormCheckbox, GlFormGroup } from '@gitlab/ui';
import { EDITOR_MODE_YAML } from 'ee/threat_monitoring/components/policy_editor/constants';
import DimDisableContainer from 'ee/threat_monitoring/components/policy_editor/dim_disable_container.vue';
import {
  RuleDirectionInbound,
  PortMatchModeAny,
  RuleTypeEndpoint,
  EndpointMatchModeLabel,
  fromYaml,
  toYaml,
} from 'ee/threat_monitoring/components/policy_editor/network_policy/lib';
import NetworkPolicyEditor from 'ee/threat_monitoring/components/policy_editor/network_policy/network_policy_editor.vue';
import PolicyRuleBuilder from 'ee/threat_monitoring/components/policy_editor/network_policy/policy_rule_builder.vue';
import PolicyAlertPicker from 'ee/threat_monitoring/components/policy_editor/policy_alert_picker.vue';
import PolicyEditorLayout from 'ee/threat_monitoring/components/policy_editor/policy_editor_layout.vue';
import PolicyPreviewHuman from 'ee/threat_monitoring/components/policy_editor/policy_preview_human.vue';
import createStore from 'ee/threat_monitoring/store';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubTransition } from 'helpers/stub_transition';
import { redirectTo } from '~/lib/utils/url_utility';
import { mockExistingL3Policy, mockExistingL7Policy } from '../../../mocks/mock_data';

jest.mock('~/lib/utils/url_utility');

describe('NetworkPolicyEditor component', () => {
  let store;
  let wrapper;

  const defaultStore = {
    threatMonitoring: { environments: [{ id: 1 }], currentEnvironmentId: 1, hasEnvironment: true },
  };

  const factory = ({
    propsData,
    provide = {},
    updatedStore = defaultStore,
    mountFn = shallowMountExtended,
  } = {}) => {
    store = createStore();

    store.replaceState({
      ...store.state,
      networkPolicies: {
        ...store.state.networkPolicies,
        ...updatedStore.networkPolicies,
      },
      threatMonitoring: {
        ...store.state.threatMonitoring,
        ...updatedStore.threatMonitoring,
      },
    });

    jest.spyOn(store, 'dispatch').mockImplementation(() => Promise.resolve());

    wrapper = mountFn(NetworkPolicyEditor, {
      propsData: {
        ...propsData,
      },
      provide: {
        networkDocumentationPath: 'path/to/docs',
        policyEditorEmptyStateSvgPath: 'path/to/svg',
        policiesPath: '/threat-monitoring',
        projectId: '21',
        ...provide,
      },
      store,
      stubs: {
        DimDisableContainer,
        PolicyYamlEditor: true,
        transition: stubTransition(),
      },
    });
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findYamlPreview = () => wrapper.findByTestId('yaml-preview');
  const findHumanizedPreview = () => wrapper.findComponent(PolicyPreviewHuman);
  const findAddRuleButton = () => wrapper.findByTestId('add-rule');
  const findYAMLParsingAlert = () => wrapper.findByTestId('parsing-alert');
  const findPolicyAlertPicker = () => wrapper.findComponent(PolicyAlertPicker);
  const findPolicyDescription = () => wrapper.find("[id='policyDescription']");
  const findPolicyEnableContainer = () => wrapper.findByTestId('policy-enable');
  const findPolicyName = () => wrapper.find("[id='policyName']");
  const findPolicyRuleBuilder = () => wrapper.findComponent(PolicyRuleBuilder);
  const findPolicyEditorLayout = () => wrapper.findComponent(PolicyEditorLayout);
  const findCollapseToggle = () =>
    wrapper.findByRole('button', {
      name: NetworkPolicyEditor.i18n.policySummary,
    });

  const modifyPolicyAlert = async ({ isAlertEnabled }) => {
    const policyAlertPicker = findPolicyAlertPicker();
    await policyAlertPicker.vm.$emit('update-alert', isAlertEnabled);
    expect(policyAlertPicker.props('policyAlert')).toBe(isAlertEnabled);
    await findPolicyEditorLayout().vm.$emit('save-policy');
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders checkbox with label', () => {
    factory();
    expect(findPolicyEnableContainer().findComponent(GlFormGroup).attributes('label')).toBe(
      NetworkPolicyEditor.i18n.toggleLabel,
    );
    expect(findPolicyEnableContainer().findComponent(GlFormCheckbox).exists()).toBe(true);
  });

  it('disables the tooltip and enables the save button', () => {
    factory();
    expect(findPolicyEditorLayout().props()).toMatchObject({
      disableTooltip: true,
      disableUpdate: false,
    });
  });

  it('renders a default rule with label', () => {
    factory();
    expect(wrapper.findAllComponents(PolicyRuleBuilder)).toHaveLength(1);
    expect(findPolicyRuleBuilder().exists()).toBe(true);
    expect(findPolicyRuleBuilder().attributes()).toMatchObject({
      endpointlabels: '',
      endpointmatchmode: 'any',
    });
  });

  it.each`
    component                       | status                | findComponent            | state
    ${'policy alert picker'}        | ${'does display'}     | ${findPolicyAlertPicker} | ${true}
    ${'policy name input'}          | ${'does display'}     | ${findPolicyName}        | ${true}
    ${'add rule button'}            | ${'does display'}     | ${findAddRuleButton}     | ${true}
    ${'yaml policy preview'}        | ${'does display'}     | ${findYamlPreview}       | ${true}
    ${'parsing error alert'}        | ${'does not display'} | ${findYAMLParsingAlert}  | ${false}
    ${'no environment empty state'} | ${'does not display'} | ${findEmptyState}        | ${false}
  `('$status the $component', async ({ findComponent, state }) => {
    factory();
    expect(findComponent().exists()).toBe(state);
  });

  it('updates policy on yaml editor value change', async () => {
    factory();
    findPolicyEditorLayout().vm.$emit('update-yaml', mockExistingL3Policy.manifest);

    expect(wrapper.vm.policy).toMatchObject({
      name: 'test-policy-02',
      description: 'test description',
      isEnabled: true,
      endpointMatchMode: EndpointMatchModeLabel,
      endpointLabels: 'foo:bar',
      rules: [
        {
          ruleType: RuleTypeEndpoint,
          matchLabels: 'foo:bar',
        },
      ],
      labels: { 'app.gitlab.com/proj': '21' },
    });
  });

  it('given there is a name change, updates policy yaml preview', async () => {
    factory();
    const initialValue = findYamlPreview().text();
    await findPolicyName().vm.$emit('input', 'new');
    expect(findYamlPreview().text()).not.toEqual(initialValue);
  });

  it('given there is a rule change, updates policy description preview', async () => {
    factory();
    const initialValue = findHumanizedPreview().props('policyDescription');
    await findAddRuleButton().vm.$emit('click');
    expect(findHumanizedPreview().props('policyDescription')).not.toEqual(initialValue);
  });

  it('toggles the visibility for the humanized policy preview', async () => {
    factory({ mountFn: mountExtended });

    // Wait for `requestAnimationFrame` in Bootstrap Vue toggle directive
    // https://github.com/bootstrap-vue/bootstrap-vue/blob/f86c32a7d8a3c0403c9a9421850ce3c97f0ad638/src/directives/toggle/toggle.js#L219
    await waitForPromises();

    expect(findHumanizedPreview().isVisible()).toBe(true);
    expect(findCollapseToggle().attributes('aria-expanded')).toBe('true');

    await findCollapseToggle().trigger('click');

    expect(findHumanizedPreview().isVisible()).toBe(false);
    expect(findCollapseToggle().attributes('aria-expanded')).toBe('false');
  });

  it('adds a new rule', async () => {
    factory();
    expect(wrapper.findAllComponents(PolicyRuleBuilder)).toHaveLength(1);
    const button = findAddRuleButton();
    await button.vm.$emit('click');
    await button.vm.$emit('click');
    const elements = wrapper.findAllComponents(PolicyRuleBuilder);
    expect(elements).toHaveLength(3);

    elements.wrappers.forEach((builder, idx) => {
      expect(builder.props().rule).toMatchObject({
        ruleType: RuleTypeEndpoint,
        direction: RuleDirectionInbound,
        matchLabels: '',
        portMatchMode: PortMatchModeAny,
        ports: '',
      });
      expect(builder.props().endpointSelectorDisabled).toEqual(idx !== 0);
    });
  });

  it('removes a new rule', async () => {
    factory();
    await findAddRuleButton().vm.$emit('click');
    expect(wrapper.findAllComponents(PolicyRuleBuilder)).toHaveLength(2);

    await findPolicyRuleBuilder().vm.$emit('remove');
    expect(wrapper.findAllComponents(PolicyRuleBuilder)).toHaveLength(1);
  });

  it('updates yaml editor value on switch to yaml editor', async () => {
    factory();
    const policyEditorLayout = findPolicyEditorLayout();
    findPolicyName().vm.$emit('input', 'test-policy');
    await policyEditorLayout.vm.$emit('update-editor-mode', EDITOR_MODE_YAML);
    expect(fromYaml(policyEditorLayout.attributes('yamleditorvalue'))).toMatchObject({
      name: 'test-policy',
    });
  });

  describe('given there is a yaml parsing error', () => {
    beforeEach(() => {
      factory({ propsData: { existingPolicy: mockExistingL7Policy } });
    });

    it('disables policy name field', () => {
      expect(findPolicyName().attributes().disabled).toBe('true');
    });

    it('disables policy description field', () => {
      expect(findPolicyDescription().attributes().disabled).toBe('true');
    });

    it('disables policy enable/disable toggle', () => {
      expect(findPolicyEnableContainer().attributes().disabled).toBe('true');
    });

    it('does not display the humanized policy preview', () => {
      expect(findHumanizedPreview().exists()).toBe(false);
    });

    it('renders parsing error alert', () => {
      expect(findYAMLParsingAlert().exists()).toBe(true);
    });

    it('disables rule builder', () => {
      expect(wrapper.findByTestId('rule-builder-container').props().disabled).toBe(true);
    });

    it('disables action picker', () => {
      expect(wrapper.findByTestId('policy-action-container').props().disabled).toBe(true);
    });

    it('displays the manifest text and decreases the opacity to show it is disabled', () => {
      const preview = findYamlPreview();
      expect(preview.attributes('class')).toContain('gl-opacity-5');
      expect(preview.text()).toBe(mockExistingL7Policy.manifest);
    });

    it('does not update yaml editor value on switch to yaml editor', async () => {
      findPolicyName().vm.$emit('input', 'test-policy');
      const policyEditorLayout = findPolicyEditorLayout();
      await policyEditorLayout.vm.$emit('update-editor-mode', EDITOR_MODE_YAML);
      expect(policyEditorLayout.attributes('yamleditorvalue')).toEqual(
        mockExistingL7Policy.manifest,
      );
    });

    it('saves unparseable policy', async () => {
      await findPolicyEditorLayout().vm.$emit('save-policy', EDITOR_MODE_YAML);
      expect(store.dispatch).toHaveBeenCalledWith('networkPolicies/createPolicy', {
        environmentId: 1,
        policy: { manifest: mockExistingL7Policy.manifest },
      });
      expect(redirectTo).toHaveBeenCalledWith('/threat-monitoring');
    });

    it('removes unparseable policy', async () => {
      await findPolicyEditorLayout().vm.$emit('remove-policy');

      expect(store.dispatch).toHaveBeenCalledWith('networkPolicies/deletePolicy', {
        environmentId: 1,
        policy: { name: mockExistingL7Policy.name, manifest: mockExistingL7Policy.manifest },
      });
      expect(redirectTo).toHaveBeenCalledWith('/threat-monitoring');
    });
  });

  it('creates policy and redirects to a threat monitoring path', async () => {
    factory();
    await findPolicyEditorLayout().vm.$emit('save-policy');
    expect(store.dispatch).toHaveBeenCalledWith('networkPolicies/createPolicy', {
      environmentId: 1,
      policy: { manifest: toYaml(wrapper.vm.policy) },
    });
    expect(redirectTo).toHaveBeenCalledWith('/threat-monitoring');
  });

  describe('given there is a createPolicy error', () => {
    beforeEach(() => {
      factory({
        updatedStore: { networkPolicies: { errorUpdatingPolicy: true }, ...defaultStore },
      });
    });

    it('it does not redirect', async () => {
      await findPolicyEditorLayout().vm.$emit('save-policy');
      expect(redirectTo).not.toHaveBeenCalledWith('/threat-monitoring');
    });
  });

  describe('editing a policy', () => {
    beforeEach(() => {
      factory({
        propsData: {
          existingPolicy: mockExistingL3Policy,
          isEditing: true,
        },
      });
    });

    it('presents existing policy', () => {
      expect(findPolicyName().attributes().value).toEqual(mockExistingL3Policy.name);
      expect(wrapper.findAllComponents(PolicyRuleBuilder)).toHaveLength(1);
    });

    it('updates existing policy and redirects to a threat monitoring path', async () => {
      await findPolicyEditorLayout().vm.$emit('save-policy');
      expect(store.dispatch).toHaveBeenCalledWith('networkPolicies/updatePolicy', {
        environmentId: 1,
        policy: {
          name: mockExistingL3Policy.name,
          manifest: toYaml(fromYaml(mockExistingL3Policy.manifest)),
        },
      });
      expect(redirectTo).toHaveBeenCalledWith('/threat-monitoring');
    });

    describe('given there is a updatePolicy error', () => {
      beforeEach(() => {
        factory({
          propsData: { existingPolicy: mockExistingL3Policy },
          updatedStore: { networkPolicies: { errorUpdatingPolicy: true }, ...defaultStore },
        });
      });

      it('it does not redirect', async () => {
        findPolicyEditorLayout().vm.$emit('save-policy');
        await wrapper.vm.$nextTick();
        expect(redirectTo).not.toHaveBeenCalledWith('/threat-monitoring');
      });
    });

    it('removes policy and redirects to a threat monitoring path on secondary modal button click', async () => {
      await findPolicyEditorLayout().vm.$emit('remove-policy');

      expect(store.dispatch).toHaveBeenCalledWith('networkPolicies/deletePolicy', {
        environmentId: 1,
        policy: {
          name: mockExistingL3Policy.name,
          manifest: mockExistingL3Policy.manifest,
        },
      });
      expect(redirectTo).toHaveBeenCalledWith('/threat-monitoring');
    });
  });

  describe('add alert picker', () => {
    beforeEach(() => {
      factory();
    });

    it('adds a policy annotation on alert addition', async () => {
      await modifyPolicyAlert({ isAlertEnabled: true });
      expect(store.dispatch).toHaveBeenLastCalledWith('networkPolicies/createPolicy', {
        environmentId: 1,
        policy: {
          manifest: expect.stringContaining("app.gitlab.com/alert: 'true'"),
        },
      });
    });

    it('removes a policy annotation on alert removal', async () => {
      await modifyPolicyAlert({ isAlertEnabled: false });
      expect(store.dispatch).toHaveBeenLastCalledWith('networkPolicies/createPolicy', {
        environmentId: 1,
        policy: {
          manifest: expect.not.stringContaining("app.gitlab.com/alert: 'true'"),
        },
      });
    });
  });

  describe('when loading environments', () => {
    beforeEach(() => {
      factory({
        updatedStore: {
          threatMonitoring: { environments: [], hasEnvironment: true, isLoadingEnvironments: true },
        },
      });
    });

    it('does not display the "no environment" empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
    });

    it('displays the "PolicyEditorLayout" component enables the tooltip and disables the save button', () => {
      expect(findPolicyEditorLayout().props()).toMatchObject({
        disableTooltip: false,
        disableUpdate: true,
      });
    });
  });

  describe('when no environments are configured', () => {
    beforeEach(() => {
      factory({ updatedStore: { threatMonitoring: { environments: [], hasEnvironment: false } } });
    });

    it.each`
      component                       | status                | findComponent             | state
      ${'policy editor layout'}       | ${'does not display'} | ${findPolicyEditorLayout} | ${false}
      ${'no environment empty state'} | ${'does not display'} | ${findEmptyState}         | ${true}
    `('$status the $component', ({ findComponent, state }) => {
      expect(findComponent().exists()).toBe(state);
    });
  });
});
