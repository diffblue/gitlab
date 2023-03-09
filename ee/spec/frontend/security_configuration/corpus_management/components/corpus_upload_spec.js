import { GlSprintf } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import CorpusUpload from 'ee/security_configuration/corpus_management/components/corpus_upload.vue';
import { decimalBytes } from '~/lib/utils/unit_format';

describe('Corpus Upload', () => {
  let wrapper;

  const findGlSprintf = () => wrapper.findComponent(GlSprintf);
  const findTotalSizeText = () => wrapper.find('[data-testid="total-size"]');
  const defaultProps = { totalSize: 4e8 };

  const createComponentFactory = (mountFn = mount) => (options = {}) => {
    wrapper = mountFn(CorpusUpload, {
      propsData: defaultProps,
      ...options,
    });
  };

  const createComponent = createComponentFactory();

  describe('component', () => {
    it('renders total size', () => {
      createComponent();

      expect(findGlSprintf().exists()).toBe(true);
      expect(findTotalSizeText().text()).toContain(
        decimalBytes(defaultProps.totalSize, 0, { unitSeparator: ' ' }),
      );
      expect(wrapper.element).toMatchSnapshot();
    });
  });
});
