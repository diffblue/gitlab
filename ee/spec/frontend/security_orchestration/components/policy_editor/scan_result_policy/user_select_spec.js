import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlListbox } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import searchProjectMembers from '~/graphql_shared/queries/project_user_members_search.query.graphql';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import UserSelect from 'ee/security_orchestration/components/policy_editor/scan_result_policy/user_select.vue';
import { USER_TYPE } from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib/actions';

Vue.use(VueApollo);

const user = {
  id: 'gid://gitlab/User/2',
  name: 'Name 1',
  username: 'name.1',
  avatarUrl: 'https://www.gravatar.com/avatar/1234',
  __typename: 'UserCore',
};

const USERS_RESPONSE = {
  data: {
    project: {
      id: 'gid://gitlab/Project/6',
      projectMembers: {
        nodes: [
          {
            id: 'gid://gitlab/ProjectMember/1',
            user,
            __typename: 'ProjectMember',
          },
        ],
        __typename: 'MemberInterfaceConnection',
      },
      __typename: 'Project',
    },
  },
};

describe('UserSelect component', () => {
  let wrapper;
  const namespacePath = 'path/to/namespace';
  const searchQueryHandlerSuccess = jest.fn().mockResolvedValue(USERS_RESPONSE);

  const createComponent = (propsData = {}) => {
    const fakeApollo = createMockApollo([[searchProjectMembers, searchQueryHandlerSuccess]]);

    wrapper = mount(UserSelect, {
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

  const findListbox = () => wrapper.findComponent(GlListbox);

  const waitForApolloAndVue = async () => {
    await nextTick();
    jest.runOnlyPendingTimers();
    await waitForPromises();
  };

  beforeEach(async () => {
    createComponent();
    await waitForApolloAndVue();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('filters users when search is performed in listbox', async () => {
    expect(searchQueryHandlerSuccess).toHaveBeenCalledWith({
      fullPath: namespacePath,
      search: '',
    });

    const searchTerm = 'test';
    findListbox().vm.$emit('search', searchTerm);
    await waitForApolloAndVue();

    expect(searchQueryHandlerSuccess).toHaveBeenCalledWith({
      fullPath: namespacePath,
      search: searchTerm,
    });
  });

  it('emits when a user is selected', async () => {
    findListbox().vm.$emit('select', [user.id]);
    await nextTick();
    expect(wrapper.emitted('updateSelectedApprovers')).toEqual([
      [
        [
          {
            ...user,
            id: getIdFromGraphQLId(user.id),
            text: user.name,
            type: USER_TYPE,
            username: `@${user.username}`,
            value: user.id,
          },
        ],
      ],
    ]);
  });

  it('emits when a user is deselected', async () => {
    findListbox().vm.$emit('select', [user.id]);
    await nextTick();
    findListbox().vm.$emit('select', []);
    await nextTick();
    expect(wrapper.emitted('updateSelectedApprovers')[1]).toEqual([[]]);
  });
});
