import { GlButton, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Actions from 'ee/security_configuration/corpus_management/components/columns/actions.vue';
import { corpuses } from '../../mock_data';

describe('Action buttons', () => {
  let wrapper;

  const findCorpusDownloadButton = () => wrapper.find('[data-testid="download-corpus"]');
  const findCorpusDestroyButton = () => wrapper.find('[data-testid="destroy-corpus"]');

  const createComponentFactory = (mountFn = shallowMount) => (options = {}) => {
    const defaultProps = {
      corpus: corpuses[0],
    };
    wrapper = mountFn(Actions, {
      propsData: defaultProps,
      provide: {
        canReadCorpus: true,
        canDestroyCorpus: true,
      },
      ...options,
    });
  };

  const createComponent = createComponentFactory();

  describe('corpus management with read and destroy enabled', () => {
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

        expect(wrapper.emitted().delete).toHaveLength(1);
      });
    });
  });

  describe('corpus management with read disabled', () => {
    it('renders the destroy button only', () => {
      createComponent({
        provide: {
          canReadCorpus: false,
          canDestroyCorpus: true,
        },
      });
      expect(wrapper.findAllComponents(GlButton)).toHaveLength(1);
      expect(findCorpusDownloadButton().exists()).toBe(false);
      expect(findCorpusDestroyButton().exists()).toBe(true);
    });

    describe('delete confirmation modal', () => {
      beforeEach(() => {
        createComponent({ stubs: { GlModal } });
      });

      it('calls the deleteCorpus method', async () => {
        wrapper.findComponent(GlModal).vm.$emit('primary');
        await nextTick();

        expect(wrapper.emitted().delete).toHaveLength(1);
      });
    });
  });

  describe('corpus management with destroy disabled', () => {
    it('renders the download button only', () => {
      createComponent({
        provide: {
          canReadCorpus: true,
          canDestroyCorpus: false,
        },
      });
      expect(wrapper.findAllComponents(GlButton)).toHaveLength(1);
      expect(findCorpusDownloadButton().exists()).toBe(true);
      expect(findCorpusDestroyButton().exists()).toBe(false);
    });
  });
});
