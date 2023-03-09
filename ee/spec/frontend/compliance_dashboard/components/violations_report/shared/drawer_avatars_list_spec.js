import { GlAvatarsInline } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import DrawerAvatarsList from 'ee/compliance_dashboard/components/violations_report/shared/drawer_avatars_list.vue';
import UserAvatar from 'ee/compliance_dashboard/components/violations_report/shared/user_avatar.vue';
import DrawerSectionSubHeader from 'ee/compliance_dashboard/components/violations_report/shared/drawer_section_sub_header.vue';
import { createApprovers } from '../../../mock_data';

describe('DrawerAvatarsList component', () => {
  let wrapper;
  const header = 'Section sub header';
  const emptyHeader = 'Empty section sub header';
  const avatars = createApprovers(3);

  const findHeader = () => wrapper.findComponent(DrawerSectionSubHeader);
  const findInlineAvatars = () => wrapper.findComponent(GlAvatarsInline);
  const findAvatars = () => wrapper.findAllComponents(UserAvatar);

  const createComponent = (mountFn = shallowMount, propsData = {}) => {
    return mountFn(DrawerAvatarsList, {
      propsData: {
        badgeSrOnlyText: 'additional approvers',
        ...propsData,
      },
    });
  };

  describe('header', () => {
    it('does not render the header if it is not given', () => {
      wrapper = createComponent();

      expect(findHeader().exists()).toBe(false);
    });

    it('Renders the header if avatars are given', () => {
      wrapper = createComponent(shallowMount, { avatars, header, emptyHeader });

      expect(findHeader().text()).toBe(header);
    });

    it('renders the empty header if no avatars are given', () => {
      wrapper = createComponent(shallowMount, { header, emptyHeader });

      expect(findHeader().text()).toBe(emptyHeader);
    });
  });

  it('does not render the avatars list if they are not given', () => {
    wrapper = createComponent();

    expect(findInlineAvatars().exists()).toBe(false);
  });

  describe('With avatars', () => {
    beforeEach(() => {
      wrapper = createComponent(mount, { avatars });
    });

    it('renders the avatars', () => {
      expect(findAvatars()).toHaveLength(avatars.length);
      expect(findInlineAvatars().props()).toMatchObject({
        avatars,
        badgeTooltipProp: 'name',
      });
    });

    it('sets the correct props to the avatars', () => {
      avatars.forEach((avatar, idx) => {
        expect(findAvatars().at(idx).props('user')).toBe(avatar);
      });
    });
  });
});
