import { GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SortingField from 'ee/audit_events/components/sorting_field.vue';

describe('SortingField component', () => {
  let wrapper;

  const initComponent = (props = {}) => {
    wrapper = shallowMount(SortingField, {
      propsData: { ...props },
    });
  };

  const getCheckedOptions = () =>
    wrapper.findAllComponents(GlDropdownItem).filter((item) => item.props().isChecked);

  beforeEach(() => {
    initComponent();
  });

  describe('when initialized', () => {
    it('should have sorting options', () => {
      expect(wrapper.findAllComponents(GlDropdownItem)).toHaveLength(2);
    });

    it('should set the sorting option to `created_desc` by default', () => {
      expect(getCheckedOptions()).toHaveLength(1);
    });

    describe('with a sortBy value', () => {
      beforeEach(() => {
        initComponent({
          sortBy: 'created_asc',
        });
      });

      it('should set the sorting option accordingly', () => {
        expect(getCheckedOptions()).toHaveLength(1);
        expect(getCheckedOptions().at(0).text()).toEqual('Oldest created');
      });
    });
  });

  describe('when the user clicks on a option', () => {
    beforeEach(() => {
      initComponent();
      wrapper.findAllComponents(GlDropdownItem).at(1).vm.$emit('click');
    });

    it('should emit the "selected" event with clicked option', () => {
      expect(wrapper.emitted().selected).toHaveLength(1);
      expect(wrapper.emitted().selected[0]).toEqual(['created_asc']);
    });
  });
});
