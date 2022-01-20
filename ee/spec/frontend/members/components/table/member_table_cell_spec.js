import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import MembersTableCell from 'ee/members/components/table/members_table_cell.vue';
import { member as memberMock, directMember } from 'jest/members/mock_data';

describe('MemberTableCell', () => {
  const WrappedComponent = {
    props: {
      memberType: {
        type: String,
        required: true,
      },
      isDirectMember: {
        type: Boolean,
        required: true,
      },
      isCurrentUser: {
        type: Boolean,
        required: true,
      },
      permissions: {
        type: Object,
        required: true,
      },
    },
    render(createElement) {
      return createElement('div', this.memberType);
    },
  };

  const localVue = createLocalVue();
  localVue.use(Vuex);
  localVue.component('WrappedComponent', WrappedComponent);

  const createStore = (state = {}) => {
    return new Vuex.Store({
      state,
    });
  };

  let wrapper;

  const createComponent = (propsData, state = {}) => {
    wrapper = mount(MembersTableCell, {
      localVue,
      propsData,
      store: createStore(state),
      provide: {
        sourceId: 1,
        currentUserId: 1,
      },
      scopedSlots: {
        default: `
          <wrapped-component
            :member-type="props.memberType"
            :is-direct-member="props.isDirectMember"
            :is-current-user="props.isCurrentUser"
            :permissions="props.permissions"
          />
        `,
      },
    });
  };

  const findWrappedComponent = () => wrapper.findComponent(WrappedComponent);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  // Implementation of props are tested in `spec/frontend/vue_shared/components/members/table/members_table_spec.js`
  it('exposes CE scoped slot props', () => {
    createComponent({ member: memberMock });

    expect(findWrappedComponent().props()).toMatchSnapshot();
  });

  describe('permissions', () => {
    describe('canOverride', () => {
      it('returns `true` when `canOverride` is `true`', () => {
        createComponent({
          member: { ...directMember, canOverride: true },
        });

        expect(findWrappedComponent().props('permissions').canOverride).toBe(true);
      });

      it('returns `false` when `canOverride` is `false`', () => {
        createComponent({
          member: { ...directMember, canOverride: false },
        });

        expect(findWrappedComponent().props('permissions').canOverride).toBe(false);
      });
    });
  });
});
