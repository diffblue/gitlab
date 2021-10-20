import { GlSearchBoxByType } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DropdownHeader from '~/vue_shared/components/sidebar/labels_select_widget/dropdown_header.vue';

describe('DropdownHeader', () => {
  let wrapper;

  const createComponent = ({
    showDropdownContentsCreateView = false,
    labelsFetchInProgress = false,
  } = {}) => {
    wrapper = shallowMount(DropdownHeader, {
      propsData: {
        showDropdownContentsCreateView,
        labelsFetchInProgress,
        labelsCreateTitle: 'Create label',
        labelsListTitle: 'Select label',
        searchKey: '',
      },
      stubs: {
        GlSearchBoxByType,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findSearchInput = () => wrapper.findComponent(GlSearchBoxByType);
  const findGoBackButton = () => wrapper.find('[data-testid="go-back-button"]');

  beforeEach(() => {
    createComponent();
  });

  describe('Create view', () => {
    beforeEach(() => {
      createComponent({ showDropdownContentsCreateView: true });
    });

    it('renders go back button', () => {
      expect(findGoBackButton().exists()).toBe(true);
    });

    it('does not render search input field', async () => {
      expect(findSearchInput().exists()).toBe(false);
    });
  });

  describe('Labels view', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render go back button', () => {
      expect(findGoBackButton().exists()).toBe(false);
    });

    it('when loading labels - renders disabled search input field', async () => {
      createComponent({ labelsFetchInProgress: true });
      expect(findSearchInput().props('disabled')).toBe(true);
    });

    it('when labels are loaded - renders enabled search input field', async () => {
      expect(findSearchInput().props('disabled')).toBe(false);
    });
  });
});
