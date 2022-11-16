import { GlBadge } from '@gitlab/ui';
import { nextTick } from 'vue';
import ActivityFilterOld, {
  ITEMS,
  GROUPS,
} from 'ee/security_dashboard/components/shared/filters/activity_filter_deprecated.vue';
import { activityFilter } from 'ee/security_dashboard/helpers';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FilterItem from 'ee/security_dashboard/components/shared/filters/filter_item.vue';

describe('Activity Filter component (deprecated)', () => {
  let wrapper;

  const findItem = (item) => wrapper.findByTestId(`option-${item.id}`);
  const findHeader = (id) => wrapper.findByTestId(`header-${id}`);
  const clickItem = (item) => findItem(item).vm.$emit('click');

  const expectSelectedItems = (items) => {
    const checkedItems = wrapper
      .findAllComponents(FilterItem)
      .wrappers.filter((x) => x.props('isChecked'))
      .map((x) => x.props('text'));

    const expectedItems = items.map((x) => x.name);

    expect(checkedItems.sort()).toEqual(expectedItems.sort());
  };

  const createWrapper = () => {
    wrapper = shallowMountExtended(ActivityFilterOld, {
      propsData: { filter: activityFilter },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
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
      group.items.forEach((item) => {
        expect(findItem(item).props('text')).toBe(item.name);
      });
    });
  });

  it('selects and unselects a dropdown item when clicked on', async () => {
    const item = ITEMS.HAS_ISSUE;
    clickItem(item);
    await nextTick();

    expectSelectedItems([item]);

    clickItem(item);
    await nextTick();

    expectSelectedItems([activityFilter.allOption]);
  });

  it.each(GROUPS.map((group) => [group.header.name, group]))(
    'allows only one item to be selected for the %s group',
    async (groupName, group) => {
      for await (const item of group.items) {
        clickItem(item);
        await nextTick();

        expectSelectedItems([item]);
      }
    },
  );

  it('allows multiple selection of items across groups', async () => {
    // Get the first item in each group and click on them.
    const items = GROUPS.map((group) => group.items[0]);
    items.forEach(clickItem);
    await nextTick();

    expectSelectedItems(items);
  });

  describe('filter-changed event', () => {
    it('emits the expected data for the all option', async () => {
      await clickItem(activityFilter.allOption);

      expect(wrapper.emitted('filter-changed')).toHaveLength(2);
      expect(wrapper.emitted('filter-changed')[1][0]).toStrictEqual({
        hasIssues: undefined,
        hasResolution: undefined,
      });
    });

    it.each`
      selectedItems                                            | hasIssues | hasResolution
      ${[ITEMS.HAS_ISSUE, ITEMS.STILL_DETECTED]}               | ${true}   | ${false}
      ${[ITEMS.DOES_NOT_HAVE_ISSUE, ITEMS.NO_LONGER_DETECTED]} | ${false}  | ${true}
    `(
      'emits the expected data for $selectedItems',
      async ({ selectedItems, hasIssues, hasResolution }) => {
        selectedItems.forEach(clickItem);
        await nextTick();

        expectSelectedItems(selectedItems);
        expect(wrapper.emitted('filter-changed')[1][0]).toEqual({ hasIssues, hasResolution });
      },
    );
  });
});
