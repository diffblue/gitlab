import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import searchGroupsGroups from 'ee/security_orchestration/graphql/queries/get_users_groups.query.graphql';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import GroupSelect from 'ee/security_orchestration/components/policy_editor/scan_result_policy/group_select.vue';
import { GROUP_TYPE } from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib/actions';

Vue.use(VueApollo);

const group = {
  avatarUrl: null,
  id: 'gid://gitlab/Group/2',
  fullName: 'Name 1',
  fullPath: 'path/to/name-1',
  __typename: 'Group',
};

const USERS_RESPONSE = {
  data: {
    currentUser: {
      id: 'gid://gitlab/User/6',
      groups: {
        nodes: [
          {
            ...group,
          },
        ],
        __typename: 'GroupConnection',
      },
      __typename: 'UserCore',
    },
  },
};

describe('GroupSelect component', () => {
  let wrapper;
  const namespacePath = 'path/to/namespace';
  const searchQueryHandlerSuccess = jest.fn().mockResolvedValue(USERS_RESPONSE);

  const createComponent = (propsData = {}) => {
    const fakeApollo = createMockApollo([[searchGroupsGroups, searchQueryHandlerSuccess]]);

    wrapper = mount(GroupSelect, {
      apolloProvider: fakeApollo,
      propsData: {
        existingApprovers: [],
        ...propsData,
      },
      provide: {
        namespacePath,
      },
    });
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  const waitForApolloAndVue = async () => {
    await nextTick();
    jest.runOnlyPendingTimers();
    await waitForPromises();
  };

  beforeEach(async () => {
    createComponent();
    await waitForApolloAndVue();
  });

  it('filters groups when search is performed in listbox', async () => {
    expect(searchQueryHandlerSuccess).toHaveBeenCalledWith({ search: '' });

    const searchTerm = 'test';
    findListbox().vm.$emit('search', searchTerm);
    await waitForApolloAndVue();

    expect(searchQueryHandlerSuccess).toHaveBeenCalledWith({ search: searchTerm });
  });

  it('emits when a group is selected', async () => {
    findListbox().vm.$emit('select', [group.id]);
    await nextTick();
    expect(wrapper.emitted('updateSelectedApprovers')).toEqual([
      [
        [
          {
            ...group,
            id: getIdFromGraphQLId(group.id),
            text: group.fullName,
            type: GROUP_TYPE,
            value: group.id,
          },
        ],
      ],
    ]);
  });

  it('emits when a group is deselected', async () => {
    findListbox().vm.$emit('select', [group.id]);
    await nextTick();
    findListbox().vm.$emit('select', []);
    await nextTick();
    expect(wrapper.emitted('updateSelectedApprovers')[1]).toEqual([[]]);
  });
});
