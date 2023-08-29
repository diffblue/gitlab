import { GlCollapsibleListbox, GlListboxItem, GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import WeightSelect from 'ee/boards/components/weight_select.vue';

describe('WeightSelect', () => {
  let wrapper;

  const editButton = () => wrapper.findComponent(GlButton);
  const valueContainer = () => wrapper.find('[data-testid="selected-weight"]');
  const weightDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const getWeightItemAtIndex = (index) =>
    weightDropdown().findAllComponents(GlListboxItem).at(index);
  const defaultProps = {
    weights: ['Any', 'None', 0, 1, 2, 3],
    board: {
      weight: null,
    },
    canEdit: true,
  };

  const createComponent = (props = {}) => {
    wrapper = mount(WeightSelect, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  describe('when no weight has been selected', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays "Any weight"', () => {
      expect(valueContainer().text()).toEqual('Any weight');
    });

    it('hides the weight dropdown', () => {
      expect(weightDropdown().exists()).toBe(false);
    });
  });

  describe('when the weight cannot be edited', () => {
    beforeEach(() => {
      createComponent({ canEdit: false });
    });

    it('does not render the edit button', () => {
      expect(editButton().exists()).toBe(false);
    });
  });

  describe('when the weight can be edited', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows the edit button', () => {
      expect(editButton().exists()).toBe(true);
    });

    describe('and the edit button is clicked', () => {
      beforeEach(() => {
        editButton().trigger('click');
      });

      describe('and no weight has been selected yet', () => {
        it('hides the value text', () => {
          expect(valueContainer().exists()).toBe(false);
        });

        it('shows the weight dropdown', () => {
          expect(weightDropdown().exists()).toBe(true);
        });
      });

      describe('and a weight has been selected', () => {
        beforeEach(() => {
          editButton().trigger('click');
          getWeightItemAtIndex(0).vm.$emit('click');
        });

        it('shows the value text', () => {
          expect(valueContainer().exists()).toBe(true);
        });

        it('hides the weight dropdown', () => {
          expect(weightDropdown().exists()).toBe(false);
        });
      });
    });
  });

  describe('when a new weight value is selected', () => {
    it.each`
      weight  | text
      ${null} | ${'Any weight'}
      ${0}    | ${'0'}
      ${1}    | ${'1'}
      ${-1}   | ${'Any weight'}
      ${-2}   | ${'None'}
    `('$weight displays as "$text"', ({ weight, text }) => {
      createComponent({ board: { weight } });
      expect(valueContainer().text()).toEqual(text);
    });
  });
});
