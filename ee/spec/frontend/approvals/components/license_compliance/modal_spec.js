import { GlSprintf, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import LicenseComplianceModal from 'ee/approvals/components/license_compliance/modal.vue';
import { APPROVALS_MODAL } from 'ee/approvals/stores/modules/license_compliance';
import GlModalVuex from '~/vue_shared/components/gl_modal_vuex.vue';

Vue.use(Vuex);

describe('EE Approvals LicenseCompliance Modal', () => {
  let wrapper;
  let store;

  const mocks = {
    actions: {
      modalHide: jest.fn(),
    },
    RuleForm: {
      template: '<div>mock-rule-form</div>',
      props: ['initRule'],
      methods: {
        submit: jest.fn(),
      },
    },
    approvalsDocumentationPath: 'http://foo.bar',
  };

  const createStore = () => {
    const storeOptions = {
      state: {
        settings: {
          approvalsDocumentationPath: mocks.approvalsDocumentationPath,
        },
      },
      modules: {
        [APPROVALS_MODAL]: {
          namespaced: true,
          actions: {
            hide: mocks.actions.modalHide,
          },
          state: {
            isVisible: false,
            data: {},
          },
        },
      },
    };

    store = new Vuex.Store(storeOptions);
  };

  const createWrapper = () => {
    wrapper = shallowMount(LicenseComplianceModal, {
      store,
      stubs: {
        GlModalVuex,
        GlSprintf,
        GlModal,
        RuleForm: mocks.RuleForm,
      },
    });
  };

  beforeEach(() => {
    createStore();
    createWrapper();
  });

  const findByHref = (href) => wrapper.find(`[href="${href}"`);
  const findModal = () => wrapper.findComponent(GlModalVuex);
  const findRuleForm = () => wrapper.findComponent(mocks.RuleForm);
  const findInformationIcon = () => wrapper.find('[name="question-o"]');
  const findOkButton = () => wrapper.find('[name="ok"]');
  const findCancelButton = () => wrapper.find('[name="cancel"]');

  describe('modal title', () => {
    it.each`
      givenStoreData     | expectTitleStartsWith
      ${null}            | ${'Add'}
      ${{ name: 'foo' }} | ${'Update'}
    `('starts with $titleStartsWith', ({ givenStoreData, expectTitleStartsWith }) => {
      store.state[APPROVALS_MODAL].data = givenStoreData;

      createWrapper();

      expect(findModal().attributes('title').startsWith(expectTitleStartsWith)).toBe(true);
    });
  });

  describe('rule form', () => {
    it(`receives the modal's states data so it can display and edit the containing rule`, () => {
      expect(findRuleForm().props('initRule')).toBe(store.state.approvalsModal.data);
    });
  });

  describe('footer information section', () => {
    it('contains an information icon', () => {
      expect(findInformationIcon().exists()).toBe(true);
    });

    it('opens a link to the relevant documentation page in a new tab', () => {
      expect(findByHref(mocks.approvalsDocumentationPath).attributes('target')).toBe('_blank');
    });
  });

  describe('action buttons', () => {
    it('submits the form when "ok" button is clicked', () => {
      expect(mocks.RuleForm.methods.submit).not.toHaveBeenCalled();

      findOkButton().vm.$emit('click');

      expect(mocks.RuleForm.methods.submit).toHaveBeenCalledTimes(1);
    });

    it('hides the modal when the "ok" button is clicked', () => {
      expect(mocks.actions.modalHide).not.toHaveBeenCalled();

      findOkButton().vm.$emit('click');

      expect(mocks.actions.modalHide).toHaveBeenCalledTimes(1);
    });

    it('hides the form when the "cancel" button is clicked', () => {
      expect(mocks.actions.modalHide).not.toHaveBeenCalled();

      findCancelButton().vm.$emit('click');

      expect(mocks.actions.modalHide).toHaveBeenCalledTimes(1);
    });
  });
});
