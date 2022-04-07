import { GlButton, GlAvatarLabeled } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ApproversListItem from 'ee/approvals/components/approvers_list_item.vue';
import HiddenGroupsItem from 'ee/approvals/components/hidden_groups_item.vue';
import { TYPE_USER, TYPE_GROUP, TYPE_HIDDEN_GROUPS } from 'ee/approvals/constants';
import { AVATAR_SHAPE_OPTION_CIRCLE, AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';

const TEST_USER = {
  id: 1,
  type: TYPE_USER,
  name: 'Lorem Ipsum',
  avatar_url: '/asd/1',
};
const TEST_GROUP = {
  id: 1,
  type: TYPE_GROUP,
  name: 'Lorem Group',
  full_path: 'dolar/sit/amit',
  avatar_url: '/asd/2',
};

describe('Approvals ApproversListItem', () => {
  let wrapper;

  const factory = (options = {}) => {
    wrapper = shallowMount(ApproversListItem, {
      ...options,
    });
  };

  const findAvatar = () => wrapper.findComponent(GlAvatarLabeled);
  const findHiddenGroupsItem = () => wrapper.findComponent(HiddenGroupsItem);

  describe('when user', () => {
    beforeEach(() => {
      factory({
        propsData: {
          approver: TEST_USER,
        },
      });
    });

    it('renders GlAvatar for user', () => {
      const avatar = findAvatar();
      expect(avatar.exists()).toBe(true);
      expect(avatar.attributes()).toMatchObject({
        'entity-name': TEST_USER.name,
        src: TEST_USER.avatar_url,
        shape: AVATAR_SHAPE_OPTION_CIRCLE,
        alt: TEST_USER.name,
      });
      expect(avatar.props('label')).toBe(TEST_USER.name);
    });

    it('when remove clicked, emits remove', async () => {
      const button = wrapper.findComponent(GlButton);
      await button.vm.$emit('click');

      expect(wrapper.emitted().remove).toEqual([[TEST_USER]]);
    });
  });

  describe('when group', () => {
    beforeEach(() => {
      factory({
        propsData: {
          approver: TEST_GROUP,
        },
      });
    });

    it('renders ProjectAvatar for group', () => {
      const avatar = findAvatar();
      expect(avatar.exists()).toBe(true);
      expect(avatar.attributes()).toMatchObject({
        'entity-name': TEST_GROUP.name,
        src: TEST_GROUP.avatar_url,
        shape: AVATAR_SHAPE_OPTION_RECT,
        alt: TEST_GROUP.name,
      });
      expect(avatar.props('label')).toBe(TEST_GROUP.full_path);
    });

    it('does not render hidden-groups-item', () => {
      expect(findHiddenGroupsItem().exists()).toBe(false);
    });
  });

  describe('when hidden groups', () => {
    beforeEach(() => {
      factory({
        propsData: {
          approver: { type: TYPE_HIDDEN_GROUPS },
        },
      });
    });

    it('renders hidden-groups-item', () => {
      expect(findHiddenGroupsItem().exists()).toBe(true);
    });

    it('does not render any avatar', () => {
      expect(findAvatar().exists()).toBe(false);
    });
  });
});
