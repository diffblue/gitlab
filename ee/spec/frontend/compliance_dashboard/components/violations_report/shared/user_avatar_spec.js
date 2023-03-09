import { GlAvatar, GlAvatarLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import UserAvatar from 'ee/compliance_dashboard/components/violations_report/shared/user_avatar.vue';
import { DRAWER_AVATAR_SIZE } from 'ee/compliance_dashboard/constants';
import { mapViolations } from 'ee/compliance_dashboard/graphql/mappers';
import { createComplianceViolation } from '../../../mock_data';

describe('UserAvatar component', () => {
  let wrapper;
  const { violatingUser: user } = mapViolations([createComplianceViolation()])[0];

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
