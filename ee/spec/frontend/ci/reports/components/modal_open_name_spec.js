import Vue from 'vue';
import Vuex from 'vuex';
import { mount, createWrapper } from '@vue/test-utils';
import ModalOpenName from 'ee/ci/reports/components/modal_open_name.vue';
import { VULNERABILITY_MODAL_ID } from 'ee/vue_shared/security_reports/components/constants';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';

Vue.use(Vuex);

describe('Modal open name', () => {
  let wrapper;
  let setModalDataAction;

  const createComponent = () => {
    setModalDataAction = jest.fn();

    const store = new Vuex.Store({
      actions: {
        setModalData: setModalDataAction,
      },
    });

    wrapper = mount(ModalOpenName, {
      store,
      propsData: {
        issue: {
          title: 'Issue',
        },
        status: 'failed',
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders the issue name', () => {
    expect(wrapper.text()).toEqual('Issue');
  });

  it('calls setModalData actions and opens modal when button is clicked', async () => {
    const rootWrapper = createWrapper(wrapper.vm.$root);

    await wrapper.trigger('click');

    expect(setModalDataAction).toHaveBeenCalled();
    expect(rootWrapper.emitted(BV_SHOW_MODAL)[0]).toStrictEqual([VULNERABILITY_MODAL_ID]);
  });
});
