import { GlAlert, GlFormSelect } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { POLICY_TYPE_COMPONENT_OPTIONS } from 'ee/threat_monitoring/components/constants';
import EnvironmentPicker from 'ee/threat_monitoring/components/environment_picker.vue';
import NetworkPolicyEditor from 'ee/threat_monitoring/components/policy_editor/network_policy/network_policy_editor.vue';
import PolicyEditor from 'ee/threat_monitoring/components/policy_editor/policy_editor.vue';
import { DEFAULT_ASSIGNED_POLICY_PROJECT } from 'ee/threat_monitoring/constants';
import createStore from 'ee/threat_monitoring/store';
import { mockL3Manifest } from '../../mocks/mock_data';

describe('PolicyEditor component', () => {
  let store;
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEnvironmentPicker = () => wrapper.findComponent(EnvironmentPicker);
  const findFormSelect = () => wrapper.findComponent(GlFormSelect);
  const findNeworkPolicyEditor = () => wrapper.findComponent(NetworkPolicyEditor);

  const factory = ({ propsData = {}, provide = {} } = {}) => {
    store = createStore();

    jest.spyOn(store, 'dispatch').mockImplementation(() => Promise.resolve());

    wrapper = shallowMount(PolicyEditor, {
      propsData: {
        assignedPolicyProject: DEFAULT_ASSIGNED_POLICY_PROJECT,
        ...propsData,
      },
      provide,
      store,
      stubs: { GlFormSelect },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(factory);

    it.each`
      component                          | status                | findComponent             | state
      ${'environment picker'}            | ${'does display'}     | ${findEnvironmentPicker}  | ${true}
      ${'NetworkPolicyEditor component'} | ${'does display'}     | ${findNeworkPolicyEditor} | ${true}
      ${'alert'}                         | ${'does not display'} | ${findAlert}              | ${false}
    `('$status the $component', ({ findComponent, state }) => {
      expect(findComponent().exists()).toBe(state);
    });

    it('renders the disabled form select', () => {
      const formSelect = findFormSelect();
      expect(formSelect.exists()).toBe(true);
      expect(formSelect.attributes('value')).toBe(POLICY_TYPE_COMPONENT_OPTIONS.container.value);
      expect(formSelect.attributes('disabled')).toBe('true');
    });

    it('shows an alert when "error" is emitted from the component', async () => {
      const errorMessage = 'test';
      findNeworkPolicyEditor().vm.$emit('error', errorMessage);
      await wrapper.vm.$nextTick();
      const alert = findAlert();
      expect(alert.exists()).toBe(true);
      expect(alert.text()).toBe(errorMessage);
    });
  });

  describe('when an existing policy is present', () => {
    beforeEach(() => {
      factory({ propsData: { existingPolicy: { manifest: mockL3Manifest } } });
    });

    it('renders the disabled form select', () => {
      const formSelect = findFormSelect();
      expect(formSelect.exists()).toBe(true);
      expect(formSelect.attributes('value')).toBe(POLICY_TYPE_COMPONENT_OPTIONS.container.value);
      expect(formSelect.attributes('disabled')).toBe('true');
    });
  });

  describe('with "securityOrchestrationPoliciesConfiguration" feature flag enabled', () => {
    beforeEach(() => {
      factory({ provide: { glFeatures: { securityOrchestrationPoliciesConfiguration: true } } });
    });

    it('renders the form select', () => {
      const formSelect = findFormSelect();
      expect(formSelect.exists()).toBe(true);
      expect(formSelect.attributes('disabled')).toBe(undefined);
    });
  });
});
