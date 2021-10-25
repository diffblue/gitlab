import { GlButton, GlIcon } from '@gitlab/ui';

import IssueField from 'ee/external_issues_show/components/sidebar/issue_field.vue';

import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';

describe('IssueField', () => {
  let wrapper;

  const defaultProps = {
    icon: 'calendar',
    title: 'Field Title',
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(IssueField, {
      directives: {
        GlTooltip: createMockDirective(),
      },
      propsData: { ...defaultProps, ...props },
      stubs: {
        SidebarEditableItem,
      },
      provide: {
        canUpdate: true,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findEditableItem = () => wrapper.findComponent(SidebarEditableItem);
  const findEditButton = () => wrapper.findComponent(GlButton);
  const findFieldCollapsed = () => wrapper.findByTestId('field-collapsed');
  const findFieldCollapsedTooltip = () => getBinding(findFieldCollapsed().element, 'gl-tooltip');
  const findFieldValue = () => wrapper.findByTestId('field-value');
  const findGlIcon = () => wrapper.findComponent(GlIcon);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders title', () => {
      expect(findEditableItem().props('title')).toBe(defaultProps.title);
    });

    it('renders GlIcon (when collapsed)', () => {
      expect(findGlIcon().props('name')).toBe(defaultProps.icon);
    });

    it('does not render "Edit" button', () => {
      expect(findEditButton().exists()).toBe(false);
    });
  });

  describe('without value prop', () => {
    beforeEach(() => {
      createComponent();
    });

    it('falls back to "None"', () => {
      expect(findFieldValue().text()).toBe('None');
    });

    it('renders tooltip (when collapsed) with "value" = title', () => {
      const tooltip = findFieldCollapsedTooltip();

      expect(tooltip).toBeDefined();
      expect(tooltip.value.title).toBe(defaultProps.title);
    });
  });

  describe('with value prop', () => {
    const value = 'field value';

    beforeEach(() => {
      createComponent({
        props: { value },
      });
    });

    it('renders the value', () => {
      expect(findFieldValue().text()).toBe(value);
    });

    it('renders tooltip (when collapsed) with "value" = value', () => {
      const tooltip = findFieldCollapsedTooltip();

      expect(tooltip).toBeDefined();
      expect(tooltip.value.title).toBe(value);
    });
  });

  describe('with canEdit = true', () => {
    beforeEach(() => {
      createComponent({
        props: { canEdit: true },
      });
    });

    it('renders "Edit" button', () => {
      expect(findEditButton().text()).toBe('Edit');
    });

    it('emits "issue-field-fetch" when dropdown is opened', () => {
      wrapper.vm.$refs.dropdown.showDropdown = jest.fn();

      findEditableItem().vm.$emit('open');

      expect(wrapper.vm.$refs.dropdown.showDropdown).toHaveBeenCalled();
      expect(wrapper.emitted('issue-field-fetch')).toHaveLength(1);
    });
  });
});
