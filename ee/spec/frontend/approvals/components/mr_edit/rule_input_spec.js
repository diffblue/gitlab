import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import RuleInput from 'ee/approvals/components/mr_edit/rule_input.vue';
import { createStoreOptions } from 'ee/approvals/stores';
import MREditModule from 'ee/approvals/stores/modules/mr_edit';

Vue.use(Vuex);

describe('Rule Input', () => {
  let wrapper;
  let store;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(RuleInput, {
      propsData: {
        rule: {
          approvalsRequired: 9,
          id: 5,
        },
        ...props,
      },
      store: new Vuex.Store(store),
    });
  };

  beforeEach(() => {
    store = createStoreOptions({ approvals: MREditModule() });
    store.state.settings.canEdit = true;

    store.modules.approvals.actions = {
      putRule: jest.fn(),
    };
  });

  afterEach(() => {
    store = null;
  });

  it('has value equal to the approvalsRequired', () => {
    createComponent();
    expect(Number(wrapper.element.value)).toBe(wrapper.props().rule.approvalsRequired);
  });

  it('is disabled when settings cannot edit', () => {
    store.state.settings.canEdit = false;
    createComponent();

    expect(wrapper.attributes().disabled).toBe('disabled');
  });

  it('is disabled when settings can edit', () => {
    createComponent();

    expect(wrapper.attributes().disabled).not.toBe('disabled');
  });

  it('has min equal to the minApprovalsRequired', () => {
    createComponent({
      rule: {
        minApprovalsRequired: 4,
      },
    });

    expect(Number(wrapper.attributes().min)).toBe(wrapper.props().rule.minApprovalsRequired);
  });

  it('defaults min approvals required input to 0', () => {
    createComponent();
    delete wrapper.props().rule.approvalsRequired;
    expect(Number(wrapper.attributes('min'))).toEqual(0);
  });

  it('dispatches putRule on change', async () => {
    const action = store.modules.approvals.actions.putRule;
    createComponent();
    wrapper.element.value = wrapper.props().rule.approvalsRequired + 1;
    wrapper.trigger('input');

    jest.runAllTimers();

    await nextTick();
    expect(action).toHaveBeenCalledWith(expect.anything(), { approvalsRequired: 10, id: 5 });
  });
});
