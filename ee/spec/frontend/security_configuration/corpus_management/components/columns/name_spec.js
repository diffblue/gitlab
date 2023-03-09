import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Name from 'ee/security_configuration/corpus_management/components/columns/name.vue';
import { corpuses } from '../../mock_data';

describe('Name', () => {
  let wrapper;

  const findName = () => wrapper.find('[data-testid="corpus-name"]');
  const findFileSize = () => wrapper.find('[data-testid="file-size"]');

  const createComponentFactory = (mountFn = shallowMount) => (options = {}) => {
    const defaultProps = {
      corpus: corpuses[0],
    };
    wrapper = mountFn(Name, {
      propsData: defaultProps,
      ...options,
    });
  };

  const createComponent = createComponentFactory();

  describe('component', () => {
    it('renders name with correct file size', () => {
      createComponent();
      expect(findFileSize().text()).toBe('(400 MB)');
      expect(findName().element).toMatchSnapshot();
    });

    it('renders the latest job', () => {
      createComponent();
      expect(wrapper.findComponent(GlLink).exists()).toBe(true);
      expect(findFileSize().text()).toBe('(400 MB)');
      expect(findName().element).toMatchSnapshot();
    });

    describe('without job path', () => {
      it('renders a - string instead of a link', () => {
        createComponent({ propsData: { corpus: corpuses[2] } });
        expect(wrapper.findComponent(GlLink).exists()).toBe(false);
        expect(findFileSize().text()).toBe('(321 MB)');
        expect(findName().element).toMatchSnapshot();
      });
    });
  });
});
