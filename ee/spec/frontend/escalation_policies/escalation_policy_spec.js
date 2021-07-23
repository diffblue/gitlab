import { GlSprintf, GlIcon, GlCard, GlCollapse } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { cloneDeep } from 'lodash';
import { nextTick } from 'vue';
import EditEscalationPolicyModal from 'ee/escalation_policies/components/add_edit_escalation_policy_modal.vue';
import DeleteEscalationPolicyModal from 'ee/escalation_policies/components/delete_escalation_policy_modal.vue';
import EscalationPolicy, { i18n } from 'ee/escalation_policies/components/escalation_policy.vue';

import {
  deleteEscalationPolicyModalId,
  editEscalationPolicyModalId,
} from 'ee/escalation_policies/constants';
import { parsePolicy } from 'ee/escalation_policies/utils';
import mockPolicies from './mocks/mockPolicies.json';

describe('EscalationPolicy', () => {
  let wrapper;
  const escalationPolicy = parsePolicy(cloneDeep(mockPolicies[0]));

  const createComponent = (policy = escalationPolicy) => {
    wrapper = shallowMount(EscalationPolicy, {
      propsData: {
        policy,
        index: 0,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findDeleteModal = () => wrapper.findComponent(DeleteEscalationPolicyModal);
  const findEditModal = () => wrapper.findComponent(EditEscalationPolicyModal);
  const findWarningIcon = () => wrapper.findComponent(GlIcon);
  const findGlCard = () => wrapper.findComponent(GlCard);
  const findGlCollapse = () => wrapper.findComponent(GlCollapse);

  it('renders a policy with rules', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders a policy without rules', () => {
    const policyWithoutRules = {
      id: mockPolicies[0].id,
      name: mockPolicies[0].name,
      description: mockPolicies[0].description,
      rules: [],
    };
    createComponent(policyWithoutRules);
    expect(findWarningIcon().exists()).toBe(true);
    expect(wrapper.text()).toContain(i18n.noRules);
  });

  describe('Modals', () => {
    describe('delete policy modal', () => {
      it('should render a modal and provide it with correct id', () => {
        const modal = findDeleteModal();
        expect(modal.exists()).toBe(true);
        expect(modal.props('modalId')).toBe(
          `${deleteEscalationPolicyModalId}-${escalationPolicy.id}`,
        );
      });
    });

    describe('edit policy modal', () => {
      it('should render a modal and provide it with correct id and isEditMode props', () => {
        const modal = findEditModal();
        expect(modal.exists()).toBe(true);
        expect(modal.props('modalId')).toBe(
          `${editEscalationPolicyModalId}-${escalationPolicy.id}`,
        );
        expect(modal.props('isEditMode')).toBe(true);
      });
    });
  });

  describe('Card collapsing behavior', () => {
    it('adds content body padding when it is expanded', async () => {
      findGlCollapse().vm.$emit('show');
      await nextTick();
      expect(findGlCard().props('bodyClass')).toBe('gl-p-5');
    });

    it('removes content body padding when it is collapsed', async () => {
      findGlCollapse().vm.$emit('hidden');
      await nextTick();
      expect(findGlCard().props('bodyClass')).toBe('gl-p-0');
    });
  });
});
