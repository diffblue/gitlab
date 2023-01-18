import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import IndexEntitiesList from 'ee/admin/application_settings/advanced_search/components/index_entities_list.vue';
import { entities } from '../mock_data';

describe('IndexEntitiesList', () => {
  let wrapper;

  // Props
  const emptyText = 'emptyText';

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(IndexEntitiesList, {
      propsData: {
        entities,
        emptyText,
        ...props,
      },
    });
  };

  describe.each(entities)('rendered list of entities', (entity) => {
    beforeEach(() => {
      createComponent();
    });

    it(`renders "${entity.text}"`, () => {
      expect(wrapper.text()).toContain(entity.text);
    });
  });

  it('emits the `remove` event when clicking on the `remove` button', () => {
    createComponent();
    wrapper.findComponent(GlButton).vm.$emit('click');

    expect(wrapper.emitted('remove')).toStrictEqual([[entities[0].id]]);
  });

  it('renders an empty state when there are no entities', () => {
    createComponent({
      entities: [],
    });

    expect(wrapper.text()).toBe(emptyText);
  });
});
