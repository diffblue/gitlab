import { GlDropdown, GlDropdownItem, GlDropdownSectionHeader, GlSearchBoxByType } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import CiTemplateDropdown from 'ee/pages/admin/application_settings/ci_cd/ci_template_dropdown.vue';
import { MOCK_CI_YMLS } from './mock_data';

describe('CiTemplateDropdown', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findFirstDropdownItem = () => findDropdownItems().at(0);
  const findDropdownHeaders = () => wrapper.findAllComponents(GlDropdownSectionHeader);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);

  const search = (searchTerm) => findSearchBox().vm.$emit('input', searchTerm);

  const createComponent = ({ mountFn = shallowMount, provide } = {}) => {
    wrapper = mountFn(CiTemplateDropdown, {
      provide: { gitlabCiYmls: MOCK_CI_YMLS, ...provide },
    });
  };

  const assertDefaultDropdownItems = () => {
    const allYmls = Object.keys(MOCK_CI_YMLS).reduce((ymls, key) => {
      MOCK_CI_YMLS[key].forEach((yml) => ymls.push(yml));
      return ymls;
    }, []);

    expect(findDropdownItems()).toHaveLength(allYmls.length);
    expect(findDropdownItems().wrappers.map((h) => h.text())).toEqual(
      allYmls.map((yml) => yml.name),
    );
  };

  const assetDefaultDropdownHeaders = () => {
    expect(findDropdownHeaders()).toHaveLength(Object.keys(MOCK_CI_YMLS).length);
    expect(findDropdownHeaders().wrappers.map((h) => h.text())).toEqual(Object.keys(MOCK_CI_YMLS));
  };

  describe('renders', () => {
    beforeEach(() => {
      createComponent();
    });

    it('dropdown', () => {
      expect(findDropdown().exists()).toBe(true);
    });

    it('dropdown items', () => {
      assertDefaultDropdownItems();
    });

    it('dropdown section headers', () => {
      assetDefaultDropdownHeaders();
    });

    it('dropown `text` prop with default text', () => {
      expect(findDropdown().props('text')).toBe('No required pipeline');
    });
  });

  describe('when providing `initialSelectedGitlabCiYmlName` data', () => {
    it('sets respective dropdown item `isChecked` prop', () => {
      createComponent({ provide: { initialSelectedGitlabCiYmlName: 'test' } });

      const dropdownItem = findFirstDropdownItem();
      expect(dropdownItem.props('isChecked')).toBe(true);
    });
  });

  describe('when searching', () => {
    beforeEach(async () => {
      createComponent({ mountFn: mount });
      await search('te');
    });

    it('renders filtered dropdown items', () => {
      const dropdownItems = findDropdownItems();

      expect(dropdownItems).toHaveLength(1);
      expect(dropdownItems.at(0).text()).toBe('test');
    });

    it('only renders section headers for sections with items', () => {
      expect(findDropdownHeaders().wrappers.map((h) => h.text())).toEqual(['General']);
    });

    describe('when search is cleared', () => {
      it('resets template to default state', async () => {
        await search('');

        assertDefaultDropdownItems();
        assetDefaultDropdownHeaders();
      });
    });
  });

  describe('when dropdown item is clicked', () => {
    beforeEach(async () => {
      createComponent();

      const dropdownItem = findFirstDropdownItem();
      await dropdownItem.vm.$emit('click');
    });

    it('sets dropdown item `isChecked` prop', () => {
      const dropdownItem = findFirstDropdownItem();
      expect(dropdownItem.props('isChecked')).toBe(true);
    });

    it('`isChecked` prop of other dropdown items remains unset', () => {
      const dropdownItems = findDropdownItems().wrappers.slice(1);
      expect(dropdownItems.some((item) => item.props('isChecked') === true)).toBe(false);
    });

    it('sets dropdown `text` prop to item name', () => {
      expect(findDropdown().props('text')).toBe('test');
    });

    describe('when the selected dropdown item is clicked again', () => {
      it("unsets item's `isChecked` prop", async () => {
        const dropdownItem = findFirstDropdownItem();
        await dropdownItem.vm.$emit('click');

        expect(dropdownItem.props('isChecked')).toBe(false);
      });
    });
  });
});
