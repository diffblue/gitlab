import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import searchProjectMembers from '~/graphql_shared/queries/project_user_members_search.query.graphql';
import searchGroupMembers from '~/graphql_shared/queries/group_users_search.query.graphql';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import UserSelect from 'ee/security_orchestration/components/policy_editor/scan_result_policy/user_select.vue';
import { NAMESPACE_TYPES, USER_TYPE } from 'ee/security_orchestration/constants';

Vue.use(VueApollo);

const user = {
  id: 'gid://gitlab/User/2',
  name: 'Name 1',
  username: 'name.1',
  avatarUrl: 'https://www.gravatar.com/avatar/1234',
  __typename: 'UserCore',
};

const PROJECT_MEMBER_RESPONSE = {
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

const GROUP_MEMBER_RESPONSE = {
  data: {
    workspace: {
      id: 'gid://gitlab/Group/6',
      users: {
        nodes: [
          {
            id: 'gid://gitlab/GroupMember/1',
            user: { ...user, webUrl: 'path/to/user', status: null },
            __typename: 'GroupMember',
          },
        ],
        __typename: 'GroupMemberConnection',
      },
      __typename: 'Group',
    },
  },
};

describe('UserSelect component', () => {
  let wrapper;
  const namespacePath = 'path/to/namespace';
  const namespaceType = NAMESPACE_TYPES.PROJECT;
  const projectSearchQueryHandlerSuccess = jest.fn().mockResolvedValue(PROJECT_MEMBER_RESPONSE);
  const groupSearchQueryHandlerSuccess = jest.fn().mockResolvedValue(GROUP_MEMBER_RESPONSE);

  const createComponent = ({ provide = {} } = {}) => {
    const fakeApollo = createMockApollo([
      [searchProjectMembers, projectSearchQueryHandlerSuccess],
      [searchGroupMembers, groupSearchQueryHandlerSuccess],
    ]);

    wrapper = mount(UserSelect, {
      apolloProvider: fakeApollo,
      propsData: {
        existingApprovers: [],
      },
      provide: {
        namespacePath,
        namespaceType,
        ...provide,
      },
    });
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  const waitForApolloAndVue = async () => {
    await nextTick();
    jest.runOnlyPendingTimers();
    await waitForPromises();
  };

  describe('default', () => {
    beforeEach(async () => {
      createComponent();
      await waitForApolloAndVue();
    });

    it('filters users when search is performed in listbox', async () => {
      expect(projectSearchQueryHandlerSuccess).toHaveBeenCalledWith({
        fullPath: namespacePath,
        search: '',
      });

      const searchTerm = 'test';
      findListbox().vm.$emit('search', searchTerm);
      await waitForApolloAndVue();

      expect(projectSearchQueryHandlerSuccess).toHaveBeenCalledWith({
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

  it('requests project members at the project-level', async () => {
    createComponent();
    await waitForApolloAndVue();

    expect(projectSearchQueryHandlerSuccess).toHaveBeenCalledWith({
      fullPath: namespacePath,
      search: '',
    });
  });

  it('requests group members at the group-level', async () => {
    createComponent({ provide: { namespaceType: NAMESPACE_TYPES.GROUP } });
    await waitForApolloAndVue();
    expect(groupSearchQueryHandlerSuccess).toHaveBeenCalledWith({
      fullPath: namespacePath,
      search: '',
    });
  });
});
