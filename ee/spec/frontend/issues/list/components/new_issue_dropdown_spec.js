import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import NewIssueDropdown from 'ee/issues/list/components/new_issue_dropdown.vue';

describe('NewIssueDropdown component', () => {
  let wrapper;

  const mountComponent = () => {
    return mount(NewIssueDropdown, {
      provide: {
        fullPath: 'mushroom-kingdom',
        newIssuePath: 'mushroom-kingdom/~/issues/new',
      },
      data() {
        return { selectedOption: 'issue' };
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);

  const showDropdown = () => {
    findDropdown().vm.$emit('shown');
  };

  beforeEach(() => {
    wrapper = mountComponent();
  });

  it('renders a split dropdown with newIssue label', () => {
    expect(findDropdown().props('split')).toBe(true);
    expect(findDropdown().props('text')).toBe(NewIssueDropdown.i18n.newIssueLabel);
  });

  it('renders types in dropdown options', () => {
    showDropdown();
    const listItems = wrapper.findAll('li');

    expect(listItems.at(0).text()).toBe(NewIssueDropdown.i18n.newIssueLabel);
    expect(listItems.at(1).text()).toBe(NewIssueDropdown.i18n.newObjectiveLabel);
  });

  describe('when New Issue is selected', () => {
    beforeEach(() => {
      showDropdown();

      const listItems = wrapper.findAll('li');
      listItems.at(0).vm.$emit('click');
    });

    it('displays newIssueLabel name on the dropdown button', () => {
      expect(findDropdown().props('text')).toBe(NewIssueDropdown.i18n.newIssueLabel);
    });
  });

  describe('when New Objective is selected', () => {
    beforeEach(() => {
      showDropdown(wrapper.findComponent(GlDropdownItem));
      const listItems = wrapper.findAll('li');
      listItems.at(1).vm.$emit('click');
    });

    it('displays newIssueLabel name on the dropdown button', () => {
      expect(findDropdown().props('text')).toBe(NewIssueDropdown.i18n.newObjectiveLabel);
    });
  });
});
