import { GlTokenSelector, GlAvatar, GlToken } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import UserSelect from 'ee/escalation_policies/components/user_select.vue';
import { getParticipantsWithTokenStyles } from 'ee/escalation_policies/utils';

const mockUsers = [
  { id: 1, name: 'User 1', avatarUrl: 'avatar.com/user1.png' },
  { id: 2, name: 'User2', avatarUrl: 'avatar.com/user1.png' },
];

describe('UserSelect', () => {
  let wrapper;
  const projectPath = 'group/project';

  const createComponent = () => {
    wrapper = shallowMount(UserSelect, {
      data() {
        return {
          users: mockUsers,
        };
      },
      propsData: {
        mappedParticipants: getParticipantsWithTokenStyles([{ user: mockUsers[0] }]),
      },
      mocks: {
        $apollo: {
          queries: {
            users: { loading: false },
          },
        },
      },
      stubs: {
        GlTokenSelector,
      },
      provide: {
        projectPath,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findTokenSelector = () => wrapper.findComponent(GlTokenSelector);
  const findSelectedUserToken = () => wrapper.findComponent(GlToken);
  const findAvatar = () => wrapper.findComponent(GlAvatar);

  describe('When no user selected', () => {
    it('renders token selector and provides it with correct params', () => {
      const tokenSelector = findTokenSelector();
      expect(tokenSelector.exists()).toBe(true);
      expect(tokenSelector.props('dropdownItems')).toEqual(mockUsers);
      expect(tokenSelector.props('loading')).toEqual(false);
    });

    it('does not render selected user token', () => {
      expect(findSelectedUserToken().exists()).toBe(false);
    });
  });

  describe('On user selected', () => {
    it('hides token selector', async () => {
      const tokenSelector = findTokenSelector();
      expect(tokenSelector.exists()).toBe(true);
      tokenSelector.vm.$emit('input', [mockUsers[0]]);
      await nextTick();
      expect(tokenSelector.exists()).toBe(false);
    });

    it('shows selected user token with name and avatar', async () => {
      const selectedUser = { ...mockUsers[0], ...wrapper.props('mappedParticipants')[0] };
      findTokenSelector().vm.$emit('input', [selectedUser]);
      await nextTick();
      const userToken = findSelectedUserToken();
      expect(userToken.exists()).toBe(true);
      expect(userToken.text()).toMatchInterpolatedText(selectedUser.name);
      expect(userToken.classes(selectedUser.class)).toBe(true);
      expect(userToken.attributes('style')).toContain('background-color:');
      const avatar = findAvatar();
      expect(avatar.exists()).toBe(true);
      expect(avatar.props('src')).toBe(selectedUser.avatarUrl);
    });
  });

  describe('On user deselected', () => {
    it('hides selected user token and avatar, shows token selector', async () => {
      // select user
      findTokenSelector().vm.$emit('input', [mockUsers[0]]);
      await nextTick();
      const userToken = findSelectedUserToken();
      expect(userToken.exists()).toBe(true);
      // deselect user
      userToken.vm.$emit('close');
      await nextTick();
      expect(userToken.exists()).toBe(false);
      expect(findTokenSelector().exists()).toBe(true);
    });
  });
});
