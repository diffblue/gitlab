import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import GroupsDropdownFilter from 'ee/analytics/shared/components/groups_dropdown_filter.vue';
import { TEST_HOST } from 'helpers/test_constants';
import Api from '~/api';

jest.mock('~/api', () => ({
  groups: jest.fn(),
}));

const groups = [
  {
    id: 1,
    name: 'foo',
    full_name: 'foo',
    avatar_url: `${TEST_HOST}/images/home/nasa.svg`,
  },
  {
    id: 2,
    name: 'subgroup',
    full_name: 'group / subgroup',
    avatar_url: null,
  },
];

describe('GroupsDropdownFilter component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(GroupsDropdownFilter, {
      propsData: {
        ...props,
      },
    });
  };

  beforeEach(() => {
    Api.groups.mockImplementation(() => Promise.resolve(groups));
  });

  const findDropdown = () => wrapper.findComponent(GlDropdown);

  const findDropdownItems = () =>
    findDropdown()
      .findAllComponents(GlDropdownItem)
      .filter((w) => w.text() !== 'No matching results');

  const findDropdownAtIndex = (index) => findDropdownItems().at(index);
  const findDropdownButton = () => findDropdown().find('.dropdown-toggle');
  const findDropdownButtonAvatar = () => findDropdown().find('.gl-avatar');

  const shouldContainAvatar = ({ dropdown, hasImage = true, hasIdenticon = true }) => {
    expect(dropdown.find('img.gl-avatar').exists()).toBe(hasImage);
    expect(dropdown.find('div.gl-avatar-identicon').exists()).toBe(hasIdenticon);
  };

  const selectDropdownAtIndex = (index) =>
    findDropdownAtIndex(index).find('button').trigger('click');

  describe('when passed a defaultGroup as prop', () => {
    beforeEach(() => {
      createComponent({
        defaultGroup: groups[0],
      });
    });

    it("displays the defaultGroup's name", () => {
      expect(findDropdownButton().text()).toContain(groups[0].name);
    });

    it("renders the defaultGroup's avatar", () => {
      expect(findDropdownButtonAvatar().exists()).toBe(true);
    });
  });

  describe('it renders the items correctly', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should contain 2 items', () => {
      expect(findDropdownItems()).toHaveLength(2);
    });

    it('renders an avatar when the group has an avatar_url', () => {
      shouldContainAvatar({ dropdown: findDropdownAtIndex(0), hasIdenticon: false });
    });

    it("renders an identicon when the group doesn't have an avatar_url", () => {
      shouldContainAvatar({ dropdown: findDropdownAtIndex(1), hasImage: false });
    });

    it('renders the full group name and highlights the last part', () => {
      expect(findDropdownAtIndex(1).text()).toContain('group / subgroup');
    });
  });

  describe('on group click', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should emit the "selected" event with the selected group', () => {
      selectDropdownAtIndex(0);

      expect(wrapper.emitted().selected).toEqual([[groups[0]]]);
    });

    it('should change selection when new group is clicked', () => {
      selectDropdownAtIndex(1);

      expect(wrapper.emitted().selected).toEqual([[groups[1]]]);
    });

    it('renders an avatar in the dropdown button when the group has an avatar_url', async () => {
      selectDropdownAtIndex(0);

      await nextTick();
      shouldContainAvatar({ dropdown: findDropdownButton(), hasIdenticon: false });
    });

    it("renders an identicon in the dropdown button when the group doesn't have an avatar_url", async () => {
      selectDropdownAtIndex(1);

      await nextTick();
      expect(findDropdownButton().find('img.gl-avatar').exists()).toBe(false);
      expect(findDropdownButton().find('.gl-avatar-identicon').exists()).toBe(true);
    });
  });
});
