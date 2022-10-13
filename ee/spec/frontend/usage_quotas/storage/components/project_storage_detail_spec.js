import { GlTableLite, GlPopover } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ProjectStorageDetail from 'ee/usage_quotas/storage/components/project_storage_detail.vue';
import { containerRegistryPopoverId } from 'ee/usage_quotas/storage/constants';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { projectData, projectHelpLinks } from '../mock_data';

describe('ProjectStorageDetail', () => {
  let wrapper;

  const { storageTypes } = projectData.storage;
  const defaultProps = { storageTypes };

  const createComponent = (props = {}) => {
    wrapper = extendedWrapper(
      mount(ProjectStorageDetail, {
        propsData: {
          ...defaultProps,
          ...props,
        },
        provide: {
          containerRegistryPopoverContent: 'Sample popover message',
        },
      }),
    );
  };

  const findTable = () => wrapper.findComponent(GlTableLite);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findWarningIcon = () => wrapper.find(`#${containerRegistryPopoverId}`);

  beforeEach(() => {
    createComponent();
  });
  afterEach(() => {
    wrapper.destroy();
  });

  describe('with storage types', () => {
    it.each(storageTypes)(
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

    it('should render items in order from the biggest usage size to the smallest', () => {
      const rows = findTable().find('tbody').findAll('tr');
      // Cloning array not to mutate the source
      const sortedStorageTypes = [...storageTypes].sort((a, b) => b.value - a.value);

      sortedStorageTypes.forEach((storageType, i) => {
        const rowUsageAmount = rows.wrappers[i].find('td:last-child').text();
        const expectedUsageAmount = numberToHumanSize(storageType.value, 1);
        expect(rowUsageAmount).toBe(expectedUsageAmount);
      });
    });
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

  describe('container registry popover note', () => {
    describe('storageTypes does not include container registry', () => {
      it('does not render warning icon and popover', () => {
        createComponent({
          storageTypes: [
            {
              storageType: {
                id: 'buildArtifactsSize',
                name: 'Artifacts',
                description: 'Pipeline artifacts and job artifacts, created with CI/CD.',
                helpPath: '/build-artifacts',
              },
              value: 400000,
            },
          ],
        });

        expect(findPopover().exists()).toBe(false);
      });
    });

    describe('storageTypes includes container registry', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders warning icon and popover', () => {
        expect(findPopover().exists()).toBe(true);
        expect(findWarningIcon().exists()).toBe(true);
      });

      it('renders popover that uses icon as target', () => {
        expect(findPopover().props().target).toBe(containerRegistryPopoverId);
      });
    });
  });
});
