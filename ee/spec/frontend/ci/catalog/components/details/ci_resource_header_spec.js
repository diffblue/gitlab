import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CiResourceHeader from 'ee/ci/catalog/components/details/ci_resource_header.vue';

describe('CiResourceHeader', () => {
  let wrapper;

  const defaultProps = {
    description: 'This is the description of the repo',
    name: 'Ruby',
    rootNamespace: { id: 1, fullPath: '/group/project', name: 'my-dumb-project' },
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(CiResourceHeader, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the project name and description', () => {
      expect(wrapper.html()).toContain(defaultProps.name);
      expect(wrapper.html()).toContain(defaultProps.description);
    });

    it('renders the namespace and project path', () => {
      expect(wrapper.html()).toContain(defaultProps.rootNamespace.fullPath);
      expect(wrapper.html()).toContain(defaultProps.rootNamespace.name);
    });
  });
});
