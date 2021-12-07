import { GlTableLite } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ProjectStorageDetail from 'ee/usage_quotas/storage/components/project_storage_detail.vue';
import { projectData, projectHelpLinks } from '../mock_data';

describe('ProjectStorageDetail', () => {
  let wrapper;

  const defaultProps = {
    storageTypes: projectData.storage.storageTypes,
  };

  const createComponent = (props = {}) => {
    wrapper = extendedWrapper(
      mount(ProjectStorageDetail, {
        propsData: {
          ...defaultProps,
          ...props,
        },
      }),
    );
  };

  const findTable = () => wrapper.findComponent(GlTableLite);

  beforeEach(() => {
    createComponent();
  });
  afterEach(() => {
    wrapper.destroy();
  });

  describe('with storage types', () => {
    it.each(projectData.storage.storageTypes)(
      'renders table row correctly %o',
      ({ storageType: { id, name, description } }) => {
        expect(wrapper.findByTestId(`${id}-name`).text()).toBe(name);
        expect(wrapper.findByTestId(`${id}-description`).text()).toBe(description);
        expect(wrapper.findByTestId(`${id}-icon`).props('name')).toBe(id);
        expect(wrapper.findByTestId(`${id}-help-link`).attributes('href')).toBe(
          projectHelpLinks[id.replace(`Size`, ``)],
        );
      },
    );
  });

  describe('without storage types', () => {
    beforeEach(() => {
      createComponent({ storageTypes: [] });
    });

    it('should render the table header <th>', () => {
      expect(findTable().find('th').exists()).toBe(true);
    });

    it('should not render any table data <td>', () => {
      expect(findTable().find('td').exists()).toBe(false);
    });
  });
});
