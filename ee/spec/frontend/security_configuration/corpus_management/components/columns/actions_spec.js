import { GlButton, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Actions from 'ee/security_configuration/corpus_management/components/columns/actions.vue';
import { corpuses } from '../../mock_data';

describe('Action buttons', () => {
  let wrapper;

  const createComponentFactory = (mountFn = shallowMount) => (options = {}) => {
    const defaultProps = {
      corpus: corpuses[0],
    };
    wrapper = mountFn(Actions, {
      propsData: defaultProps,
      ...options,
    });
  };

  const createComponent = createComponentFactory();

  afterEach(() => {
    wrapper.destroy();
  });

  describe('corpus management', () => {
    it('renders the action buttons', () => {
      createComponent();
      expect(wrapper.findAllComponents(GlButton)).toHaveLength(2);
    });

    describe('delete confirmation modal', () => {
      beforeEach(() => {
        createComponent({ stubs: { GlModal } });
      });

      it('calls the deleteCorpus method', async () => {
        wrapper.findComponent(GlModal).vm.$emit('primary');
        await nextTick();

        expect(wrapper.emitted().delete).toBeTruthy();
      });
    });
  });
});
