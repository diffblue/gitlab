import { GlModal, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { cloneDeep } from 'lodash';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import AddEscalationPolicyForm from 'ee/escalation_policies/components/add_edit_escalation_policy_form.vue';
import AddEscalationPolicyModal, {
  i18n,
} from 'ee/escalation_policies/components/add_edit_escalation_policy_modal.vue';
import {
  addEscalationPolicyModalId,
  editEscalationPolicyModalId,
  EMAIL_ONCALL_SCHEDULE_USER,
} from 'ee/escalation_policies/constants';
import createEscalationPolicyMutation from 'ee/escalation_policies/graphql/mutations/create_escalation_policy.mutation.graphql';
import updateEscalationPolicyMutation from 'ee/escalation_policies/graphql/mutations/update_escalation_policy.mutation.graphql';
import { stubComponent } from 'helpers/stub_component';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import mockPolicies from './mocks/mockPolicies.json';

describe('AddEditsEscalationPolicyModal', () => {
  let wrapper;
  let requestHandlers;
  const projectPath = 'group/project';
  const modalHideSpy = jest.fn();
  const mockEscalationPolicy = cloneDeep(mockPolicies[0]);
  const updatedName = 'Policy name';
  const updatedDescription = 'Policy description';
  const updatedRules = [{ status: 'RESOLVED', elapsedTimeMinutes: 1, oncallScheduleIid: 1 }];
  const serializedRules = [{ status: 'RESOLVED', elapsedTimeSeconds: 60, oncallScheduleIid: 1 }];

  const defaultHandlers = {
    createEscalationPolicyHandler: jest.fn().mockResolvedValue({}),
    updateEscalationPolicyHandler: jest.fn().mockResolvedValue({}),
  };

  const createMockApolloProvider = (handlers) => {
    Vue.use(VueApollo);
    requestHandlers = handlers;

    return createMockApollo([
      [createEscalationPolicyMutation, handlers.createEscalationPolicyHandler],
      [updateEscalationPolicyMutation, handlers.updateEscalationPolicyHandler],
    ]);
  };

  const createComponent = ({
    escalationPolicy,
    isEditMode = false,
    modalId,
    handlers = defaultHandlers,
  } = {}) => {
    wrapper = shallowMount(AddEscalationPolicyModal, {
      apolloProvider: createMockApolloProvider(handlers),
      propsData: {
        escalationPolicy,
        isEditMode,
        modalId,
      },
      provide: {
        projectPath,
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          methods: {
            hide: modalHideSpy,
          },
        }),
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findEscalationPolicyForm = () => wrapper.findComponent(AddEscalationPolicyForm);
  const findAlert = () => wrapper.findComponent(GlAlert);

  const updateForm = () => {
    const emitUpdate = (args) =>
      findEscalationPolicyForm().vm.$emit('update-escalation-policy-form', args);

    emitUpdate({
      field: 'name',
      value: updatedName,
    });
    emitUpdate({
      field: 'description',
      value: updatedDescription,
    });
    emitUpdate({
      field: 'rules',
      value: updatedRules,
    });
  };

  describe('Create escalation policy', () => {
    beforeEach(() => {
      createComponent({ modalId: addEscalationPolicyModalId });
    });

    it('renders create modal with correct information', () => {
      const modal = findModal();
      expect(modal.props('title')).toBe(i18n.addEscalationPolicy);
      expect(modal.props('modalId')).toBe(addEscalationPolicyModalId);
    });

    it('makes a request with form data to create an escalation policy', () => {
      updateForm();
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      expect(requestHandlers.createEscalationPolicyHandler).toHaveBeenCalledWith({
        input: {
          projectPath,
          name: updatedName,
          description: updatedDescription,
          rules: serializedRules,
        },
      });
    });

    it('clears the form on modal cancel', async () => {
      updateForm();
      await nextTick();
      expect(findEscalationPolicyForm().props('form')).toMatchObject({
        name: updatedName,
        description: updatedDescription,
        rules: updatedRules,
      });

      findModal().vm.$emit('canceled', { preventDefault: jest.fn() });
      await nextTick();
      expect(findEscalationPolicyForm().props('form')).toMatchObject({
        name: '',
        description: '',
        rules: [],
      });
    });

    it('clears the validation state on modal cancel', async () => {
      const form = findEscalationPolicyForm();
      const getNameValidationState = () => form.props('validationState').name;
      expect(getNameValidationState()).toBe(false);

      form.vm.$emit('update-escalation-policy-form', {
        field: 'name',
        value: '',
      });
      await nextTick();
      expect(getNameValidationState()).toBe(false);

      findModal().vm.$emit('canceled', { preventDefault: jest.fn() });
      await nextTick();
      expect(getNameValidationState()).toBe(false);
    });
  });

  describe('Update escalation policy', () => {
    beforeEach(() => {
      createComponent({
        modalId: editEscalationPolicyModalId,
        escalationPolicy: mockEscalationPolicy,
        isEditMode: true,
      });
    });

    it('renders update modal with correct information', () => {
      const modal = findModal();
      expect(modal.props('title')).toBe(i18n.editEscalationPolicy);
      expect(modal.props('modalId')).toBe(editEscalationPolicyModalId);
    });

    it('makes a request with form data to update an escalation policy', () => {
      updateForm();
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      expect(requestHandlers.updateEscalationPolicyHandler).toHaveBeenCalledWith({
        input: {
          name: updatedName,
          description: updatedDescription,
          rules: serializedRules,
          id: mockEscalationPolicy.id,
        },
      });
    });

    it('clears the form on modal cancel', async () => {
      updateForm();
      await nextTick();
      const getForm = () => findEscalationPolicyForm().props('form');
      expect(getForm()).toMatchObject({
        name: updatedName,
        description: updatedDescription,
        rules: updatedRules,
      });

      findModal().vm.$emit('canceled', { preventDefault: jest.fn() });
      const { name, description, rules } = mockEscalationPolicy;

      await nextTick();

      expect(getForm()).toMatchObject({
        name,
        description,
        rules,
      });
    });

    it('clears the validation state on modal cancel', async () => {
      const form = findEscalationPolicyForm();
      const getNameValidationState = () => form.props('validationState').name;
      expect(getNameValidationState()).toBe(true);

      expect(findEscalationPolicyForm().props('validationState').name).toBe(true);

      form.vm.$emit('update-escalation-policy-form', {
        field: 'name',
        value: '',
      });
      await nextTick();
      expect(getNameValidationState()).toBe(false);

      findModal().vm.$emit('canceled', { preventDefault: jest.fn() });
      await nextTick();
      expect(getNameValidationState()).toBe(true);
    });
  });

  describe('Create/update success/failure', () => {
    it('hides the modal on successful policy creation', async () => {
      createComponent({
        modalId: addEscalationPolicyModalId,
        handlers: {
          ...defaultHandlers,
          createEscalationPolicyHandler: jest.fn().mockResolvedValue({
            data: {
              escalationPolicyCreate: { escalationPolicy: mockEscalationPolicy, errors: [] },
            },
          }),
        },
      });

      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();

      expect(requestHandlers.createEscalationPolicyHandler).toHaveBeenCalled();
      expect(findModal().props('visible')).toBe(false);
    });

    it("doesn't hide a modal and shows error alert on creation failure", async () => {
      const error = 'some error';
      createComponent({
        modalId: addEscalationPolicyModalId,
        handlers: {
          ...defaultHandlers,
          createEscalationPolicyHandler: jest
            .fn()
            .mockResolvedValue({ data: { escalationPolicyCreate: { errors: [error] } } }),
        },
      });

      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();
      const alert = findAlert();
      expect(modalHideSpy).not.toHaveBeenCalled();
      expect(alert.exists()).toBe(true);
      expect(alert.text()).toContain(error);
    });
  });

  describe('Modal buttons', () => {
    beforeEach(() => {
      createComponent({ modalId: addEscalationPolicyModalId });
    });

    it('should disable primary button when form is invalid', async () => {
      findEscalationPolicyForm().vm.$emit('update-escalation-policy-form', {
        field: 'name',
        value: '',
      });
      await nextTick();
      expect(findModal().props('actionPrimary').attributes.disabled).toBe(true);
    });

    it('should enable primary button when form is valid', async () => {
      const form = findEscalationPolicyForm();
      form.vm.$emit('update-escalation-policy-form', {
        field: 'name',
        value: 'Some policy name',
      });
      form.vm.$emit('update-escalation-policy-form', {
        field: 'rules',
        value: [
          {
            status: 'RESOLVED',
            elapsedTimeMinutes: 1,
            action: EMAIL_ONCALL_SCHEDULE_USER,
            oncallScheduleIid: 1,
          },
        ],
      });
      await nextTick();
      expect(findModal().props('actionPrimary').attributes.disabled).toBe(false);
    });
  });
});
