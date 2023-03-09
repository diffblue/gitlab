import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import RemoveBillableMemberModal from 'ee/usage_quotas/seats/components/remove_billable_member_modal.vue';

Vue.use(Vuex);

describe('RemoveBillableMemberModal', () => {
  let wrapper;

  const defaultState = {
    namespaceName: 'foo',
    namespaceId: '1',
    billableMemberToRemove: {
      id: 2,
      username: 'username',
      name: 'First Last',
    },
  };

  const createStore = () => {
    return new Vuex.Store({
      state: defaultState,
    });
  };

  const createComponent = (mountFn = shallowMount) => {
    wrapper = mountFn(RemoveBillableMemberModal, {
      store: createStore(),
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    createComponent();

    return nextTick();
  });

  describe('on rendering', () => {
    it('renders the submit button disabled', () => {
      expect(wrapper.attributes('ok-disabled')).toBe('true');
    });

    it('renders the title with username', () => {
      expect(wrapper.attributes('title')).toBe(
        `Remove user @${defaultState.billableMemberToRemove.username} from your subscription`,
      );
    });

    it('renders the confirmation label with username', () => {
      expect(wrapper.find('label').text()).toContain(
        defaultState.billableMemberToRemove.username.substring(1),
      );
    });
  });
});
