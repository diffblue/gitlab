import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import searchDescendantGroups from 'ee/security_orchestration/graphql/queries/get_descendant_groups.query.graphql';
import searchNamespaceGroups from 'ee/security_orchestration/graphql/queries/get_namespace_groups.query.graphql';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import GroupSelect from 'ee/security_orchestration/components/policy_editor/scan_result_policy/group_select.vue';
import { GROUP_TYPE } from 'ee/security_orchestration/constants';

Vue.use(VueApollo);

const rootGroup = {
  avatarUrl: null,
  id: 'gid://gitlab/Group/1',
  fullName: 'Name 1',
  fullPath: 'path/to/name-1',
};

const group = {
  avatarUrl: null,
  id: 'gid://gitlab/Group/2',
  fullName: 'Name 2',
  fullPath: 'path/to/name-2',
  __typename: 'Group',
};

const DESCENDANT_GROUP_RESPONSE = {
  data: {
    group: {
      ...rootGroup,
      descendantGroups: {
        nodes: [
          {
            ...group,
          },
        ],
        __typename: 'GroupConnection',
      },
      __typename: 'Group',
    },
  },
};

const NAMESPACE_GROUP_RESPONSE = {
  data: {
    groups: {
      nodes: [
        {
          ...group,
        },
      ],
      __typename: 'GroupConnection',
    },
  },
};

describe('GroupSelect component', () => {
  let wrapper;
  const rootNamespacePath = 'root/path/to/namespace';
  const searchDescendantGroupsQueryHandlerSuccess = jest
    .fn()
    .mockResolvedValue(DESCENDANT_GROUP_RESPONSE);
  const searchNamespaceGroupsQueryHandlerSuccess = jest
    .fn()
    .mockResolvedValue(NAMESPACE_GROUP_RESPONSE);

  const createComponent = ({ propsData = {}, provide = {} } = {}) => {
    const fakeApollo = createMockApollo([
      [searchDescendantGroups, searchDescendantGroupsQueryHandlerSuccess],
      [searchNamespaceGroups, searchNamespaceGroupsQueryHandlerSuccess],
    ]);

    wrapper = mount(GroupSelect, {
      apolloProvider: fakeApollo,
      propsData: {
        existingApprovers: [],
        ...propsData,
      },
      provide: {
        globalGroupApproversEnabled: true,
        rootNamespacePath,
        ...provide,
      },
    });
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  const waitForApolloAndVue = async () => {
    await nextTick();
    jest.runOnlyPendingTimers();
  };

  describe('default', () => {
    beforeEach(async () => {
      createComponent();
      await waitForApolloAndVue();
    });

    it('filters groups when search is performed in listbox', async () => {
      expect(searchNamespaceGroupsQueryHandlerSuccess).toHaveBeenCalledWith({
        rootNamespacePath,
        search: '',
      });
      expect(searchDescendantGroupsQueryHandlerSuccess).not.toHaveBeenCalled();

      const searchTerm = 'test';
      findListbox().vm.$emit('search', searchTerm);
      await waitForApolloAndVue();

      expect(searchNamespaceGroupsQueryHandlerSuccess).toHaveBeenCalledWith({
        rootNamespacePath,
        search: searchTerm,
      });
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

    it('emits when a group is deselected', () => {
      findListbox().vm.$emit('select', [group.id]);
      findListbox().vm.$emit('select', []);
      expect(wrapper.emitted('updateSelectedApprovers')[1]).toEqual([[]]);
    });
  });

  describe('descendant group approvers', () => {
    it('filters groups when search is performed in listbox', async () => {
      createComponent({ provide: { globalGroupApproversEnabled: false } });
      await waitForApolloAndVue();

      expect(searchNamespaceGroupsQueryHandlerSuccess).not.toHaveBeenCalled();
      expect(searchDescendantGroupsQueryHandlerSuccess).toHaveBeenCalledWith({
        rootNamespacePath,
        search: '',
      });

      const searchTerm = 'test';
      findListbox().vm.$emit('search', searchTerm);
      await waitForApolloAndVue();

      expect(searchDescendantGroupsQueryHandlerSuccess).toHaveBeenCalledWith({
        rootNamespacePath,
        search: searchTerm,
      });
    });

    it('contains the root group and descendent group', async () => {
      createComponent({ provide: { globalGroupApproversEnabled: false } });
      await waitForApolloAndVue();
      await waitForPromises();

      const items = [expect.objectContaining(rootGroup), expect.objectContaining(group)];
      expect(findListbox().props('items')).toEqual(items);
    });
  });
});
