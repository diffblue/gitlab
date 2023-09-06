import { GlIcon, GlCollapsibleListbox, GlLink } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import DependencyLocationCount from 'ee/dependencies/components/dependency_location_count.vue';
import { SEARCH_MIN_THRESHOLD } from 'ee/dependencies/components/constants';

describe('Dependency Location Count component', () => {
  let wrapper;
  let mockAxios;

  const blobPath = '/blob_path/Gemfile.lock';
  const path = 'Gemfile.lock';
  const projectName = 'test-project';
  const endpoint = 'endpoint';

  const locationsData = {
    locations: [
      {
        location: {
          blob_path: blobPath,
          path,
        },
        project: {
          name: projectName,
        },
      },
    ],
  };

  const createComponent = ({ propsData, mountFn = shallowMount, ...options } = {}) => {
    wrapper = mountFn(DependencyLocationCount, {
      propsData: {
        ...{
          locationCount: 2,
          componentId: 1,
        },
        ...propsData,
      },
      provide: { locationsEndpoint: endpoint },
      ...options,
    });
  };

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findLocationList = () => wrapper.findComponent(GlCollapsibleListbox);
  const findLocationInfo = () => wrapper.findComponent(GlLink);

  beforeEach(() => {
    createComponent();
  });

  it('renders location text and icon', () => {
    expect(findLocationList().props('headerText')).toBe('2 locations');
    expect(findIcon().props('name')).toBe('doc-text');
  });

  it('renders the listbox', () => {
    expect(findLocationList().props()).toMatchObject({
      headerText: '2 locations',
      searchable: true,
      items: [],
      loading: false,
      searching: true,
    });
  });

  describe('with fetched data', () => {
    beforeEach(() => {
      createComponent({
        mountFn: mount,
      });
      mockAxios = new MockAdapter(axios);
      mockAxios.onGet(endpoint).reply(HTTP_STATUS_OK, locationsData);
    });

    afterEach(() => {
      mockAxios.restore();
    });

    it('sets searching based on the data being fetched', async () => {
      await findLocationList().vm.$emit('shown');

      expect(findLocationList().props('searching')).toBe(true);

      await waitForPromises();

      expect(mockAxios.history.get).toHaveLength(1);

      expect(findLocationList().props('searching')).toBe(false);
    });

    it('sets searching when search term is updated', async () => {
      await findLocationList().vm.$emit('search', 'a');

      expect(findLocationList().props('searching')).toBe(true);

      await waitForPromises();

      expect(findLocationList().props('searching')).toBe(false);
    });

    it('renders location information', async () => {
      await findLocationList().vm.$emit('shown');
      await waitForPromises();

      expect(findLocationInfo().attributes('href')).toBe(blobPath);
      expect(findLocationInfo().text()).toContain(path);
      expect(wrapper.text()).toContain(projectName);
    });

    describe.each`
      locationCount               | searchable
      ${SEARCH_MIN_THRESHOLD - 1} | ${false}
      ${SEARCH_MIN_THRESHOLD + 1} | ${true}
    `('with location count equal to $locationCount', ({ locationCount, searchable }) => {
      beforeEach(() => {
        createComponent({
          propsData: { locationCount },
        });
      });

      it(`renders listbox with searchable set to ${searchable}`, async () => {
        await findLocationList().vm.$emit('shown');
        await waitForPromises();

        expect(findLocationList().props()).toMatchObject({
          headerText: `${locationCount} locations`,
          searchable,
        });
      });
    });
  });
});
