import { GlToggle } from '@gitlab/ui';
import { EDITOR_MODE_YAML } from 'ee/threat_monitoring/components/policy_editor/constants';
import {
  RuleDirectionInbound,
  PortMatchModeAny,
  RuleTypeEndpoint,
  EndpointMatchModeLabel,
  fromYaml,
  buildRule,
  toYaml,
} from 'ee/threat_monitoring/components/policy_editor/network_policy/lib';
import NetworkPolicyEditor from 'ee/threat_monitoring/components/policy_editor/network_policy/network_policy_editor.vue';
import PolicyRuleBuilder from 'ee/threat_monitoring/components/policy_editor/network_policy/policy_rule_builder.vue';
import PolicyAlertPicker from 'ee/threat_monitoring/components/policy_editor/policy_alert_picker.vue';
import PolicyEditorLayout from 'ee/threat_monitoring/components/policy_editor/policy_editor_layout.vue';
import PolicyPreview from 'ee/threat_monitoring/components/policy_editor/policy_preview.vue';
import createStore from 'ee/threat_monitoring/store';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { redirectTo } from '~/lib/utils/url_utility';
import { mockL3Manifest, mockL7Manifest } from '../../../mocks/mock_data';

jest.mock('~/lib/utils/url_utility');

describe('NetworkPolicyEditor component', () => {
  let store;
  let wrapper;

  const factory = ({ propsData, provide = {}, state, data } = {}) => {
    store = createStore();
    Object.assign(store.state.threatMonitoring, {
      ...state,
    });
    Object.assign(store.state.networkPolicies, {
      ...state,
    });

    jest.spyOn(store, 'dispatch').mockImplementation(() => Promise.resolve());

    wrapper = shallowMountExtended(NetworkPolicyEditor, {
      propsData: {
        ...propsData,
      },
      provide: {
        threatMonitoringPath: '/threat-monitoring',
        projectId: '21',
        ...provide,
      },
      store,
      data,
      stubs: { PolicyYamlEditor: true },
    });
  };

  const findPreview = () => wrapper.findComponent(PolicyPreview);
  const findAddRuleButton = () => wrapper.findByTestId('add-rule');
  const findYAMLParsingAlert = () => wrapper.findByTestId('parsing-alert');
  const findPolicyAlertPicker = () => wrapper.findComponent(PolicyAlertPicker);
  const findPolicyDescription = () => wrapper.find("[id='policyDescription']");
  const findPolicyEnableContainer = () => wrapper.findByTestId('policy-enable');
  const findPolicyName = () => wrapper.find("[id='policyName']");
  const findPolicyRuleBuilder = () => wrapper.findComponent(PolicyRuleBuilder);
  const findPolicyEditorLayout = () => wrapper.findComponent(PolicyEditorLayout);

  const modifyPolicyAlert = async ({ isAlertEnabled }) => {
    const policyAlertPicker = findPolicyAlertPicker();
    await policyAlertPicker.vm.$emit('update-alert', isAlertEnabled);
    expect(policyAlertPicker.props('policyAlert')).toBe(isAlertEnabled);
    await findPolicyEditorLayout().vm.$emit('save-policy');
  };

  beforeEach(() => {
    factory();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders toggle with label', () => {
    const policyEnableToggle = findPolicyEnableContainer().findComponent(GlToggle);
    expect(policyEnableToggle.exists()).toBe(true);
    expect(policyEnableToggle.props('label')).toBe(NetworkPolicyEditor.i18n.toggleLabel);
  });

  it('renders a default rule with label', () => {
    expect(wrapper.findAllComponents(PolicyRuleBuilder)).toHaveLength(1);
    expect(findPolicyRuleBuilder().exists()).toBe(true);
    expect(findPolicyRuleBuilder().attributes()).toMatchObject({
      endpointlabels: '',
      endpointmatchmode: 'any',
    });
  });

  it.each`
    component                | status                | findComponent            | state
    ${'policy alert picker'} | ${'does display'}     | ${findPolicyAlertPicker} | ${true}
    ${'policy name input'}   | ${'does display'}     | ${findPolicyName}        | ${true}
    ${'add rule button'}     | ${'does display'}     | ${findAddRuleButton}     | ${true}
    ${'policy preview'}      | ${'does display'}     | ${findPreview}           | ${true}
    ${'parsing error alert'} | ${'does not display'} | ${findYAMLParsingAlert}  | ${false}
  `('$status the $component', async ({ findComponent, state }) => {
    expect(findComponent().exists()).toBe(state);
  });

  describe('given .yaml editor mode is enabled', () => {
    beforeEach(() => {
      factory({
        data: () => ({
          editorMode: EDITOR_MODE_YAML,
        }),
      });
    });

    it('updates policy on yaml editor value change', async () => {
      findPolicyEditorLayout().vm.$emit('update-yaml', mockL3Manifest);

      expect(wrapper.vm.policy).toMatchObject({
        name: 'test-policy',
        description: 'test description',
        isEnabled: false,
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

    it('saves L7 policies', async () => {
      factory({
        data: () => ({
          editorMode: EDITOR_MODE_YAML,
          yamlEditorValue: mockL7Manifest,
        }),
      });

      await findPolicyEditorLayout().vm.$emit('save-policy', EDITOR_MODE_YAML);
      expect(store.dispatch).toHaveBeenCalledWith('networkPolicies/createPolicy', {
        environmentId: -1,
        policy: { manifest: mockL7Manifest },
      });
      expect(redirectTo).toHaveBeenCalledWith('/threat-monitoring');
    });
  });

  it('given there is a name change, updates policy yaml preview', async () => {
    const initialValue = findPreview().props('policyYaml');
    await findPolicyName().vm.$emit('input', 'new');
    expect(findPreview().props('policyYaml')).not.toEqual(initialValue);
  });

  it('given there is a rule change, updates policy description preview', async () => {
    const initialValue = findPreview().props('policyDescription');
    await findAddRuleButton().vm.$emit('click');
    expect(findPreview().props('policyDescription')).not.toEqual(initialValue);
  });

  it('adds a new rule', async () => {
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
    await findAddRuleButton().vm.$emit('click');
    expect(wrapper.findAllComponents(PolicyRuleBuilder)).toHaveLength(2);

    await findPolicyRuleBuilder().vm.$emit('remove');
    expect(wrapper.findAllComponents(PolicyRuleBuilder)).toHaveLength(1);
  });

  it('updates yaml editor value on switch to yaml editor', async () => {
    const policyEditorLayout = findPolicyEditorLayout();
    findPolicyName().vm.$emit('input', 'test-policy');
    await policyEditorLayout.vm.$emit('update-editor-mode', EDITOR_MODE_YAML);
    expect(fromYaml(policyEditorLayout.attributes('yamleditorvalue'))).toMatchObject({
      name: 'test-policy',
    });
  });

  describe('given there is a yaml parsing error', () => {
    beforeEach(() => {
      factory({
        data: () => ({
          yamlEditorError: {},
        }),
      });
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

    it('renders parsing error alert', () => {
      expect(findYAMLParsingAlert().exists()).toBe(true);
    });

    it('disables rule builder', () => {
      expect(wrapper.findByTestId('rule-builder-container').props().disabled).toBe(true);
    });

    it('disables action picker', () => {
      expect(wrapper.findByTestId('policy-action-container').props().disabled).toBe(true);
    });

    it('disables policy preview', () => {
      expect(wrapper.findByTestId('policy-preview-container').props().disabled).toBe(true);
    });

    it('does not update yaml editor value on switch to yaml editor', async () => {
      findPolicyName().vm.$emit('input', 'test-policy');
      const policyEditorLayout = findPolicyEditorLayout();
      await policyEditorLayout.vm.$emit('update-editor-mode', EDITOR_MODE_YAML);
      expect(policyEditorLayout.attributes('yamleditorvalue')).toEqual('');
    });
  });

  it('creates policy and redirects to a threat monitoring path', async () => {
    await findPolicyEditorLayout().vm.$emit('save-policy');
    expect(store.dispatch).toHaveBeenCalledWith('networkPolicies/createPolicy', {
      environmentId: -1,
      policy: { manifest: toYaml(wrapper.vm.policy) },
    });
    expect(redirectTo).toHaveBeenCalledWith('/threat-monitoring');
  });

  describe('given there is a createPolicy error', () => {
    beforeEach(() => {
      factory({
        state: {
          errorUpdatingPolicy: true,
        },
      });
    });

    it('it does not redirect', async () => {
      await findPolicyEditorLayout().vm.$emit('save-policy');
      expect(redirectTo).not.toHaveBeenCalledWith('/threat-monitoring');
    });
  });

  describe('editing a policy', () => {
    const manifest = toYaml({
      name: 'policy',
      endpointLabels: '',
      rules: [buildRule()],
    });

    beforeEach(() => {
      factory({
        propsData: {
          existingPolicy: { name: 'policy', manifest },
          isEditing: true,
        },
      });
    });

    it('presents existing policy', () => {
      expect(findPolicyName().attributes().value).toEqual('policy');
      expect(wrapper.findAllComponents(PolicyRuleBuilder)).toHaveLength(1);
    });

    it('updates existing policy and redirects to a threat monitoring path', async () => {
      await findPolicyEditorLayout().vm.$emit('save-policy');
      expect(store.dispatch).toHaveBeenCalledWith('networkPolicies/updatePolicy', {
        environmentId: -1,
        policy: { name: 'policy', manifest: toYaml(wrapper.vm.policy) },
      });
      expect(redirectTo).toHaveBeenCalledWith('/threat-monitoring');
    });

    describe('given there is a updatePolicy error', () => {
      beforeEach(() => {
        factory({
          propsData: {
            existingPolicy: { name: 'policy', manifest },
          },
          state: {
            errorUpdatingPolicy: true,
          },
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
        environmentId: -1,
        policy: { name: 'policy', manifest: toYaml(wrapper.vm.policy) },
      });
      expect(redirectTo).toHaveBeenCalledWith('/threat-monitoring');
    });
  });

  describe('add alert picker', () => {
    it('adds a policy annotation on alert addition', async () => {
      await modifyPolicyAlert({ isAlertEnabled: true });
      expect(store.dispatch).toHaveBeenLastCalledWith('networkPolicies/createPolicy', {
        environmentId: -1,
        policy: {
          manifest: expect.stringContaining("app.gitlab.com/alert: 'true'"),
        },
      });
    });

    it('removes a policy annotation on alert removal', async () => {
      await modifyPolicyAlert({ isAlertEnabled: false });
      expect(store.dispatch).toHaveBeenLastCalledWith('networkPolicies/createPolicy', {
        environmentId: -1,
        policy: {
          manifest: expect.not.stringContaining("app.gitlab.com/alert: 'true'"),
        },
      });
    });
  });
});
