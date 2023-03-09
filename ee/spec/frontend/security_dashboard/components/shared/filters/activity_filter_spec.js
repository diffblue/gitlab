import { GlBadge } from '@gitlab/ui';
import { nextTick } from 'vue';
import ActivityFilter, {
  ITEMS,
  GROUPS,
} from 'ee/security_dashboard/components/shared/filters/activity_filter.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import FilterItem from 'ee/security_dashboard/components/shared/filters/filter_item.vue';
import DropdownButtonText from 'ee/security_dashboard/components/shared/filters/dropdown_button_text.vue';
import { ALL_ID } from 'ee/security_dashboard/components/shared/filters/constants';

describe('Activity Filter component', () => {
  let wrapper;

  const findItem = (id) => wrapper.findByTestId(id);
  const findHeader = (id) => wrapper.findByTestId(`header-${id}`);
  const clickItem = (id) => findItem(id).vm.$emit('click');

  const expectSelectedItems = (ids) => {
    const checkedItems = wrapper
      .findAllComponents(FilterItem)
      .wrappers.filter((item) => item.props('isChecked'))
      .map((item) => item.attributes('data-testid'));

    expect(checkedItems).toEqual(ids);
  };

  const createWrapper = () => {
    wrapper = mountExtended(ActivityFilter, {
      stubs: { QuerystringSync: true, GlBadge: true },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  it('renders the dropdown text', () => {
    expect(wrapper.findComponent(DropdownButtonText).props()).toMatchObject({
      items: wrapper.vm.selectedItemNames,
      name: ActivityFilter.i18n.label,
    });
  });

  it('renders the header text for each group', () => {
    GROUPS.forEach((group) => {
      const header = findHeader(group.header.name);

      expect(header.text()).toContain(group.header.name);
    });
  });

  it('renders the badge for each group', () => {
    GROUPS.forEach((group) => {
      const header = findHeader(group.header.name);

      expect(header.findComponent(GlBadge).attributes()).toMatchObject({
        icon: group.header.icon,
        variant: group.header.variant ?? 'muted',
      });
    });
  });

  it('renders the dropdown items for each group', () => {
    GROUPS.forEach((group) => {
      group.items.forEach(({ id, name }) => {
        expect(findItem(id).props('text')).toBe(name);
      });
    });
  });

  it('selects and unselects a dropdown item when clicked on', async () => {
    const { id } = ITEMS.HAS_ISSUE;
    clickItem(id);
    await nextTick();

    expectSelectedItems([id]);

    clickItem(id);
    await nextTick();

    expectSelectedItems([ALL_ID]);
  });

  it.each(GROUPS.map((group) => [group.header.name, group]))(
    'allows only one item to be selected for the %s group',
    async (groupName, group) => {
      for await (const { id } of group.items) {
        clickItem(id);
        await nextTick();

        expectSelectedItems([id]);
      }
    },
  );

  it('allows multiple selection of items across groups', async () => {
    // Get the first item in each group and click on them.
    const ids = GROUPS.map((group) => group.items[0].id);
    ids.forEach(clickItem);
    await nextTick();

    expectSelectedItems(ids);
  });

  describe('filter-changed event', () => {
    it('emits the expected data for the all option', async () => {
      await clickItem(ALL_ID);

      expect(wrapper.emitted('filter-changed')).toHaveLength(1);
      expect(wrapper.emitted('filter-changed')[0][0]).toStrictEqual({
        hasIssues: undefined,
        hasResolution: undefined,
      });
    });

    it.each`
      selectedItems                                                  | hasIssues | hasResolution
      ${[ITEMS.STILL_DETECTED.id, ITEMS.HAS_ISSUE.id]}               | ${true}   | ${false}
      ${[ITEMS.NO_LONGER_DETECTED.id, ITEMS.DOES_NOT_HAVE_ISSUE.id]} | ${false}  | ${true}
    `(
      'emits the expected data for $selectedItems',
      async ({ selectedItems, hasIssues, hasResolution }) => {
        selectedItems.forEach(clickItem);
        await nextTick();

        expectSelectedItems(selectedItems);
        expect(wrapper.emitted('filter-changed')[0][0]).toEqual({ hasIssues, hasResolution });
      },
    );
  });
});
