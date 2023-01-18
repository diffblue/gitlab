import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import IndexingRestrictions from 'ee/admin/application_settings/advanced_search/components/indexing_restrictions.vue';
import IndexEntitiesSelector from 'ee/admin/application_settings/advanced_search/components/index_entities_selector.vue';
import IndexEntitiesList from 'ee/admin/application_settings/advanced_search/components/index_entities_list.vue';
import { entities } from '../mock_data';

describe('IndexingRestrictions', () => {
  let wrapper;

  // Props
  const initialSelection = () => [...entities];
  const inputName = 'inputName';
  const apiPath = 'apiPath';
  const selectorToggleText = 'selectorToggleText';
  const nameProp = 'nameProp';
  const emptyListText = 'emptyListText';

  // Finders
  const findIndexEntitiesSelector = () => wrapper.findComponent(IndexEntitiesSelector);
  const findIndexEntitiesList = () => wrapper.findComponent(IndexEntitiesList);
  const findInput = () => wrapper.find('input[type="hidden"]');

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(IndexingRestrictions, {
      propsData: {
        initialSelection: initialSelection(),
        inputName,
        apiPath,
        selectorToggleText,
        nameProp,
        emptyListText,
        ...props,
      },
    });
  };

  describe('initial state', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      value                 | propName
      ${entities}           | ${'selected'}
      ${apiPath}            | ${'apiPath'}
      ${selectorToggleText} | ${'toggleText'}
      ${nameProp}           | ${'nameProp'}
    `("passes '$value' as `$propName` to `index-entities-selector`", ({ value, propName }) => {
      expect(findIndexEntitiesSelector().props(propName)).toStrictEqual(value);
    });

    it.each`
      prop             | propName
      ${entities}      | ${'entities'}
      ${emptyListText} | ${'emptyText'}
    `("passes '$prop' as `$propName` to `index-entities-list`", ({ prop, propName }) => {
      expect(findIndexEntitiesList().props(propName)).toStrictEqual(prop);
    });

    it('passes the correct value to the input', () => {
      expect(findInput().element.value).toBe('1,2');
    });
  });

  describe('when selecting an item', () => {
    const newItem = {
      id: 3,
      text: 'Third entity',
    };

    beforeEach(() => {
      createComponent();
      findIndexEntitiesSelector().vm.$emit('select', newItem);
    });

    it('adds the selected item to the list', () => {
      expect(JSON.stringify(findIndexEntitiesList().props('entities'))).toBe(
        JSON.stringify([...entities, newItem]),
      );
    });

    it("updates the input's value accordingly", () => {
      expect(findInput().element.value).toBe('1,2,3');
    });
  });

  describe('when removing an item', () => {
    beforeEach(() => {
      createComponent();
      findIndexEntitiesList().vm.$emit('remove', entities[0].id);
    });

    it('adds the selected item to the list', () => {
      expect(JSON.stringify(findIndexEntitiesList().props('entities'))).toBe(
        JSON.stringify([entities[1]]),
      );
    });

    it("updates the input's value accordingly", () => {
      expect(findInput().element.value).toBe('2');
    });
  });
});
