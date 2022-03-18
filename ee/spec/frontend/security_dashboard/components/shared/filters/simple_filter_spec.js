import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueRouter from 'vue-router';
import SimpleFilter from 'ee/security_dashboard/components/shared/filters/simple_filter.vue';

Vue.use(VueRouter);
const router = new VueRouter();

const generateOptions = (length) =>
  Array.from({ length }).map((_, i) => ({ name: `Option ${i}`, id: `option-${i}`, index: i }));

const filter = {
  id: 'filter',
  name: 'filter',
  options: generateOptions(12),
  allOption: { id: 'allOptionId' },
  defaultOptions: [],
};
const optionsAt = (indexes) => filter.options.filter((x) => indexes.includes(x.index));
const optionIdsAt = (indexes) => optionsAt(indexes).map((x) => x.id);

describe('Simple Filter component', () => {
  let wrapper;

  const createWrapper = (filterOptions, props) => {
    wrapper = shallowMount(SimpleFilter, {
      router,
      propsData: { filter: { ...filter, ...filterOptions }, ...props },
    });
  };

  const dropdownItems = () => wrapper.findAll(`[data-testid^=${filter.id}]`);
  const dropdownItemAt = (index) => dropdownItems().at(index);
  const allOptionItem = () => wrapper.find('[data-testid="allOption"]');
  const isChecked = (item) => item.props('isChecked');
  const filterQuery = () => wrapper.vm.$route.query[filter.id];

  const clickAllOptionItem = async () => {
    allOptionItem().vm.$emit('click');
    await nextTick();
  };

  const clickItemAt = async (index) => {
    dropdownItemAt(index).vm.$emit('click');
    await nextTick();
  };

  const expectSelectedItems = (indexes) => {
    const checkedIndexes = dropdownItems().wrappers.map((item) => isChecked(item));
    const expectedIndexes = Array.from({ length: checkedIndexes.length }).map((_, index) =>
      indexes.includes(index),
    );

    expect(checkedIndexes).toEqual(expectedIndexes);
  };

  const expectAllOptionSelected = () => {
    expect(isChecked(allOptionItem())).toBe(true);
    const checkedIndexes = dropdownItems().wrappers.map((item) => isChecked(item));
    const expectedIndexes = new Array(checkedIndexes.length).fill(false);

    expect(checkedIndexes).toEqual(expectedIndexes);
  };

  afterEach(() => {
    wrapper.destroy();
    // Clear out the querystring if one exists, it persists between tests.
    if (router.currentRoute.query[filter.id]) {
      wrapper.vm.$router.push('/');
    }
  });

  describe('filter options', () => {
    it('shows the filter options', () => {
      createWrapper();

      expect(dropdownItems()).toHaveLength(filter.options.length);
    });

    it('initially selects the default options', () => {
      const ids = [2, 5, 7];
      createWrapper({ defaultOptions: optionsAt(ids) });

      expectSelectedItems(ids);
    });

    it('initially selects the All option if there are no default options', () => {
      createWrapper();

      expectAllOptionSelected();
    });
  });

  describe('selecting options', () => {
    beforeEach(() => {
      createWrapper({ defaultOptions: optionsAt([1, 2, 3]) });
    });

    it('de-selects every option and selects the All option when all option is clicked', async () => {
      const clickAndCheck = async () => {
        await clickAllOptionItem();
        expectAllOptionSelected();
      };

      // Click the all option 3 times. We're checking that it doesn't toggle.
      await clickAndCheck();
      await clickAndCheck();
      await clickAndCheck();
    });

    it(`toggles an option's selection when it it repeatedly clicked`, async () => {
      const item = dropdownItems().at(5);
      let checkedState = isChecked(item);

      const clickAndCheck = async () => {
        await clickItemAt(5);
        expect(isChecked(item)).toBe(!checkedState);
        checkedState = !checkedState;
      };

      // Click the option 3 times. We're checking that toggles.
      await clickAndCheck();
      await clickAndCheck();
      await clickAndCheck();
    });

    it('multi-selects options when multiple items are clicked', async () => {
      await [5, 6, 7].forEach(clickItemAt);

      expectSelectedItems([1, 2, 3, 5, 6, 7]);
    });

    it('selects the All option when last selected option is unselected', async () => {
      await [1, 2, 3].forEach(clickItemAt);

      expectAllOptionSelected();
    });

    it('emits filter-changed event with default options when created', async () => {
      const expectedIds = optionIdsAt([1, 2, 3]);
      expect(wrapper.emitted('filter-changed')).toHaveLength(1);
      expect(wrapper.emitted('filter-changed')[0][0]).toEqual({ [filter.id]: expectedIds });
    });

    it('emits filter-changed event when an option is clicked', async () => {
      const expectedIds = optionIdsAt([1, 2, 3, 4]);
      await clickItemAt(4);

      expect(wrapper.emitted('filter-changed')).toHaveLength(2);
      expect(wrapper.emitted('filter-changed')[1][0]).toEqual({ [filter.id]: expectedIds });
    });
  });

  describe('filter querystring', () => {
    const updateQuerystring = async (ids) => {
      // window.history.back() won't change the location nor fire the popstate event, so we need
      // to fake it by doing it manually.
      router.replace({ query: { [filter.id]: ids } });
      window.dispatchEvent(new Event('popstate'));
      await nextTick();
    };

    describe('clicking on items', () => {
      it('updates the querystring when options are clicked', async () => {
        createWrapper();
        const clickedIds = [];

        [1, 3, 5].forEach((index) => {
          clickItemAt(index);
          clickedIds.push(optionIdsAt([index])[0]);

          expect(filterQuery()).toEqual(clickedIds);
        });
      });

      it('sets the querystring properly when the All option is clicked', async () => {
        createWrapper();
        [1, 2, 3, 4].forEach(clickItemAt);

        expect(filterQuery()).toHaveLength(4);

        await clickAllOptionItem();

        expect(filterQuery()).toEqual([filter.allOption.id]);
      });
    });

    describe('querystring on page load', () => {
      it('selects correct items', () => {
        updateQuerystring(optionIdsAt([1, 3, 5, 7]));
        createWrapper();

        expectSelectedItems([1, 3, 5, 7]);
      });

      it('selects only valid items when querystring has valid and invalid IDs', async () => {
        const ids = optionIdsAt([2, 4, 6]).concat(['some', 'invalid', 'ids']);
        updateQuerystring(ids);
        createWrapper();

        expectSelectedItems([2, 4, 6]);
      });

      it('selects default options if querystring only has invalid items', async () => {
        updateQuerystring(['some', 'invalid', 'ids']);
        createWrapper({ defaultOptions: optionsAt([4, 5, 8]) });

        expectSelectedItems([4, 5, 8]);
      });

      it('selects All option if querystring only has invalid IDs and there are no default options', async () => {
        updateQuerystring(['some', 'invalid', 'ids']);
        createWrapper();

        expectAllOptionSelected();
      });
    });

    describe('changing the querystring', () => {
      it('selects the correct options', async () => {
        createWrapper();
        const indexes = [3, 5, 7];
        await updateQuerystring(optionIdsAt(indexes));

        expectSelectedItems(indexes);
      });

      it('select default options when querystring is blank', async () => {
        createWrapper({ defaultOptions: optionsAt([2, 5, 8]) });

        await clickItemAt(3);
        expectSelectedItems([2, 3, 5, 8]);

        await updateQuerystring([]);
        expectSelectedItems([2, 5, 8]);
      });

      it('selects All option when querystring is blank and there are no default options', async () => {
        createWrapper();

        await clickItemAt(3);
        expectSelectedItems([3]);

        await updateQuerystring([]);
        expectAllOptionSelected();
      });

      it('selects All option when querystring has all option ID', async () => {
        createWrapper({ defaultOptions: optionsAt([2, 4, 8]) });
        expectSelectedItems([2, 4, 8]);

        await updateQuerystring([filter.allOption.id]);
        expectAllOptionSelected();
      });

      it('selects All option if querystring has all option ID as well as other IDs', async () => {
        createWrapper({ defaultOptions: optionsAt([5, 6, 9]) });
        await updateQuerystring([filter.allOption.id, ...optionIdsAt([1, 2])]);

        expectAllOptionSelected();
      });

      it('selects only valid items when querystring has valid and invalid IDs', async () => {
        createWrapper();
        const ids = optionIdsAt([3, 7, 9]).concat(['some', 'invalid', 'ids']);
        await updateQuerystring(ids);

        expectSelectedItems([3, 7, 9]);
      });

      it('selects default options if querystring only has invalid IDs', async () => {
        createWrapper({ defaultOptions: optionsAt([1, 3, 4]) });

        await clickItemAt(8);
        expectSelectedItems([1, 3, 4, 8]);

        await updateQuerystring(['some', 'invalid', 'ids']);
        expectSelectedItems([1, 3, 4]);
      });

      it('selects All option if querystring only has invalid IDs and there are no default options', async () => {
        createWrapper();

        await clickItemAt(8);
        expectSelectedItems([8]);

        await updateQuerystring(['some', 'invalid', 'ids']);
        expectAllOptionSelected();
      });

      it('does not change querystring for another filter when updating querystring for current filter', async () => {
        createWrapper();
        const ids = optionIdsAt([1, 2, 3]);
        const other = ['6', '7', '8'];
        const query = { [filter.id]: ids, other };
        router.push({ query });
        window.dispatchEvent(new Event('popstate'));
        await nextTick();

        expectSelectedItems([1, 2, 3]);
        expect(wrapper.vm.$route.query.other).toEqual(other);
      });
    });
  });
});
