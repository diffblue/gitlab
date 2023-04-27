import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import ModalRuleRemove from 'ee/approvals/components/modal_rule_remove.vue';
import { stubComponent } from 'helpers/stub_component';
import GlModalVuex from '~/vue_shared/components/gl_modal_vuex.vue';

const MODAL_MODULE = 'deleteModal';
const TEST_MODAL_ID = 'test-delete-modal-id';
const TEST_RULE = {
  id: 7,
  name: 'Lorem',
  eligibleApprovers: Array(5)
    .fill(1)
    .map((x, id) => ({ id })),
};
const SINGLE_APPROVER = {
  ...TEST_RULE,
  eligibleApprovers: [{ id: 1 }],
};

Vue.use(Vuex);

describe('Approvals ModalRuleRemove', () => {
  let wrapper;
  let actions;
  let deleteModalState;

  const findModal = () => wrapper.findComponent(GlModalVuex);

  const factory = (options = {}) => {
    const store = new Vuex.Store({
      actions,
      modules: {
        [MODAL_MODULE]: {
          namespaced: true,
          state: deleteModalState,
        },
      },
    });

    const propsData = {
      modalId: TEST_MODAL_ID,
      ...options.propsData,
    };

    wrapper = shallowMount(ModalRuleRemove, {
      ...options,
      store,
      propsData,
      stubs: {
        GlModalVuex: stubComponent(GlModalVuex, {
          props: ['modalModule', 'modalId', 'actionPrimary', 'actionCancel'],
        }),
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    deleteModalState = {
      data: TEST_RULE,
    };
    actions = {
      deleteRule: jest.fn(),
    };
  });

  it('renders modal', () => {
    factory();

    const modal = findModal();

    expect(modal.exists()).toBe(true);
    expect(modal.props()).toEqual(
      expect.objectContaining({
        modalModule: MODAL_MODULE,
        modalId: TEST_MODAL_ID,
        actionPrimary: {
          text: 'Remove approvers',
          attributes: { variant: 'danger' },
        },
        actionCancel: { text: 'Cancel' },
      }),
    );
  });

  it.each`
    type                    | rule               | expectedText
    ${'multiple approvers'} | ${TEST_RULE}       | ${'You are about to remove the Lorem approver group which has 5 members'}
    ${'singular approver'}  | ${SINGLE_APPROVER} | ${'You are about to remove the Lorem approver group which has 1 member'}
  `('renders the correct text for $type', ({ expectedText, rule }) => {
    deleteModalState.data = rule;
    factory();

    expect(findModal().text()).toContain(expectedText);
  });

  it('calls deleteRule when the modal is submitted', () => {
    deleteModalState.data = TEST_RULE;
    factory();

    expect(actions.deleteRule).not.toHaveBeenCalled();

    const modal = findModal();
    modal.vm.$emit('ok', new Event('submit'));

    expect(actions.deleteRule).toHaveBeenCalledWith(expect.anything(), TEST_RULE.id);
  });
});
