import { GlFormSelect } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EnvironmentPicker from 'ee/threat_monitoring/components/environment_picker.vue';
import { POLICY_KIND_OPTIONS } from 'ee/threat_monitoring/components/policy_editor/constants';
import NetworkPolicyEditor from 'ee/threat_monitoring/components/policy_editor/network_policy/network_policy_editor.vue';
import PolicyEditor from 'ee/threat_monitoring/components/policy_editor/policy_editor.vue';
import createStore from 'ee/threat_monitoring/store';
import { mockL3Manifest } from '../../mocks/mock_data';

describe('PolicyEditor component', () => {
  let store;
  let wrapper;

  const findEnvironmentPicker = () => wrapper.findComponent(EnvironmentPicker);
  const findFormSelect = () => wrapper.findComponent(GlFormSelect);
  const findNeworkPolicyEditor = () => wrapper.findComponent(NetworkPolicyEditor);

  const factory = ({ propsData = {}, provide = {} } = {}) => {
    store = createStore();

    jest.spyOn(store, 'dispatch').mockImplementation(() => Promise.resolve());

    wrapper = shallowMount(PolicyEditor, {
      propsData,
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

    it('renders the environment picker', () => {
      expect(findEnvironmentPicker().exists()).toBe(true);
    });

    it('renders the disabled form select', () => {
      const formSelect = findFormSelect();
      expect(formSelect.exists()).toBe(true);
      expect(formSelect.attributes('value')).toBe(POLICY_KIND_OPTIONS.network.value);
      expect(formSelect.attributes('disabled')).toBe('true');
    });

    it('renders the "NetworkPolicyEditor" component', () => {
      expect(findNeworkPolicyEditor().exists()).toBe(true);
    });
  });

  describe('when an existing policy is present', () => {
    beforeEach(() => {
      factory({ propsData: { existingPolicy: { manifest: mockL3Manifest } } });
    });

    it('renders the disabled form select', () => {
      const formSelect = findFormSelect();
      expect(formSelect.exists()).toBe(true);
      expect(formSelect.attributes('value')).toBe(POLICY_KIND_OPTIONS.network.value);
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
