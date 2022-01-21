import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PublishedCell from 'ee/incidents/components/published_cell.vue';

describe('Incidents Published Cell', () => {
  let wrapper;

  const findCell = () => wrapper.find("[data-testid='published-cell']");

  function mountComponent({
    props = { statusPagePublishedIncident: null, unPublished: 'Unpublished' },
  }) {
    wrapper = shallowMount(PublishedCell, {
      propsData: {
        ...props,
      },
      stubs: {
        GlIcon: true,
      },
    });
  }

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('Published cell', () => {
    beforeEach(() => {
      mountComponent({});
    });

    it('render a cell with unpublished by default', () => {
      expect(findCell().findComponent(GlIcon).exists()).toBe(false);
      expect(findCell().text()).toBe('Unpublished');
    });

    it('render a status success icon if statusPagePublishedIncident returns true', () => {
      wrapper.setProps({ statusPagePublishedIncident: true });

      return wrapper.vm.$nextTick().then(() => {
        expect(findCell().findComponent(GlIcon).exists()).toBe(true);
      });
    });
  });
});
