import { GlAvatar, GlAvatarLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import UserAvatar from 'ee/compliance_dashboard/components/shared/user_avatar.vue';
import { DRAWER_AVATAR_SIZE } from 'ee/compliance_dashboard/constants';
import { createUser } from '../../mock_data';

describe('UserAvatar component', () => {
  let wrapper;
  const user = convertObjectPropsToCamelCase(createUser(1));

  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findAvatarLink = () => wrapper.findComponent(GlAvatarLink);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(UserAvatar, {
      propsData: {
        user,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('sets the correct attributes to the avatar', () => {
    expect(findAvatar().props()).toMatchObject({
      src: user.avatarUrl,
      entityName: user.name,
      size: DRAWER_AVATAR_SIZE,
    });
  });

  it('sets the correct props to the avatar link', () => {
    expect(findAvatarLink().attributes()).toMatchObject({
      title: user.name,
      href: user.webUrl,
      'data-name': user.name,
      'data-user-id': `${user.id}`,
    });
  });
});
