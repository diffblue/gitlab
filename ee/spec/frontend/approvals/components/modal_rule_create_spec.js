import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import ModalRuleCreate from 'ee/approvals/components/modal_rule_create.vue';
import { stubComponent } from 'helpers/stub_component';
import RuleForm from 'ee/approvals/components/rule_form.vue';
import GlModalVuex from '~/vue_shared/components/gl_modal_vuex.vue';

const TEST_MODAL_ID = 'test-modal-create-id';
const TEST_RULE = { id: 7 };
const MODAL_MODULE = 'createModal';

Vue.use(Vuex);

describe('Approvals ModalRuleCreate', () => {
  let createModalState;
  let wrapper;
  let modal;
  let form;
  let submitMock;

  const findModal = () => wrapper.findComponent(GlModalVuex);
  const findForm = () => wrapper.findComponent(RuleForm);

  const factory = (options = {}) => {
    submitMock = jest.fn();

    const RuleFormStub = stubComponent(RuleForm, {
      template: `<span />`,
      methods: {
        submit: submitMock,
      },
    });

    const store = new Vuex.Store({
      modules: {
        [MODAL_MODULE]: {
          namespaced: true,
          state: createModalState,
        },
      },
    });

    const propsData = {
      modalId: TEST_MODAL_ID,
      ...options.propsData,
    };

    wrapper = shallowMount(ModalRuleCreate, {
      ...options,
      store,
      propsData,
      stubs: {
        GlModalVuex: stubComponent(GlModalVuex, {
          props: ['modalModule', 'modalId', 'actionPrimary', 'actionCancel'],
        }),
        RuleForm: RuleFormStub,
      },
    });
  };

  beforeEach(() => {
    createModalState = {};
  });

  describe('without data', () => {
    beforeEach(() => {
      createModalState.data = null;
      factory();
      modal = findModal();
      form = findForm();
    });

    it('renders modal', () => {
      expect(modal.exists()).toBe(true);
      expect(modal.props('modalModule')).toEqual(MODAL_MODULE);
      expect(modal.props('modalId')).toEqual(TEST_MODAL_ID);
      expect(modal.props('actionPrimary')).toStrictEqual({
        text: 'Add approval rule',
        attributes: { variant: 'confirm' },
      });
      expect(modal.props('actionCancel')).toStrictEqual({ text: 'Cancel' });
      expect(modal.attributes('title')).toEqual('Add approval rule');
    });

    it('renders form', () => {
      expect(form.exists()).toBe(true);
      expect(form.props('initRule')).toEqual(null);
    });

    it('when modal emits ok, submits form', () => {
      // An instance of Event is passed to handle .prevent vue event modifier
      modal.vm.$emit('ok', new Event('ok'));

      expect(submitMock).toHaveBeenCalled();
    });
  });

  describe('with data', () => {
    beforeEach(() => {
      createModalState.data = TEST_RULE;
      factory();
      modal = findModal();
      form = findForm();
    });

    it('renders modal', () => {
      expect(modal.exists()).toBe(true);
      expect(modal.attributes('title')).toEqual('Update approval rule');
      expect(modal.props('actionPrimary')).toStrictEqual({
        text: 'Update approval rule',
        attributes: { variant: 'confirm' },
      });
      expect(modal.props('actionCancel')).toStrictEqual({ text: 'Cancel' });
    });

    it('renders form', () => {
      expect(form.exists()).toBe(true);
      expect(form.props('initRule')).toEqual(TEST_RULE);
    });
  });

  describe('with approval suggestions', () => {
    beforeEach(() => {
      createModalState.data = { ...TEST_RULE, defaultRuleName: 'Coverage-Check' };

      factory();
      modal = findModal();
      form = findForm();
    });

    it('renders add rule modal', () => {
      expect(modal.exists()).toBe(true);
      expect(modal.attributes('title')).toEqual('Add approval rule');
      expect(modal.props('actionPrimary')).toStrictEqual({
        text: 'Add approval rule',
        attributes: { variant: 'confirm' },
      });
      expect(modal.props('actionCancel')).toStrictEqual({ text: 'Cancel' });
    });

    it('renders form with defaultRuleName', () => {
      expect(form.props('defaultRuleName')).toBe('Coverage-Check');
      expect(form.exists()).toBe(true);
    });

    it('renders the form when passing in an existing rule', () => {
      expect(form.exists()).toBe(true);
      expect(form.props('initRule')).toEqual(createModalState.data);
    });
  });
});
