import { GlButton, GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import NewIssueDropdown from 'ee/issues/list/components/new_issue_dropdown.vue';
import { WORK_ITEM_TYPE_VALUE_OBJECTIVE } from '~/work_items/constants';

const NEW_ISSUE_PATH = 'mushroom-kingdom/~/issues/new';

describe('NewIssueDropdown component', () => {
  let wrapper;

  const createComponent = () => {
    return mount(NewIssueDropdown, {
      propsData: {
        workItemType: WORK_ITEM_TYPE_VALUE_OBJECTIVE,
      },
      provide: {
        newIssuePath: NEW_ISSUE_PATH,
      },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDropdownItem = (index) =>
    findDropdown().findAllComponents(GlDisclosureDropdownItem).at(index);

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('renders a split dropdown with newIssue label', () => {
    expect(findButton().text()).toBe(NewIssueDropdown.i18n.newIssueLabel);
    expect(findButton().props('href')).toBe(NewIssueDropdown.i18n.newIssuePath);
  });

  it('renders dropdown with New Issue item', () => {
    expect(findDropdownItem(0).props('item').text).toBe(NewIssueDropdown.i18n.newIssueLabel);
    expect(findDropdownItem(0).props('item').href).toBe(NEW_ISSUE_PATH);
  });

  it('renders dropdown with new work item text', () => {
    expect(findDropdownItem(1).props('item').text).toBe('New objective');
  });

  describe('when new work item is clicked', () => {
    it('emits `select-new-work-item` event', () => {
      findDropdownItem(1).find('button').trigger('click');

      expect(wrapper.emitted('select-new-work-item')).toEqual([[]]);
    });
  });
});
