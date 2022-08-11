import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import createMockApollo from 'helpers/mock_apollo_helper';
import ImageFilter from 'ee/security_dashboard/components/shared/filters/image_filter.vue';
import { IMAGE_FILTER_ERROR } from 'ee/security_dashboard/components/shared/filters/constants';
import { imageFilter } from 'ee/security_dashboard/helpers';
import getVulnerabilityImagesQuery from 'ee/security_dashboard/graphql/queries/vulnerability_images.query.graphql';
import FilterItem from 'ee/security_dashboard/components/shared/filters/filter_item.vue';
import { projectVulnerabilityImages } from '../../mock_data';

jest.mock('~/flash');

describe('Image Filter component', () => {
  let wrapper;
  const projectFullPath = 'test/path';
  const defaultQueryResolver = jest.fn().mockResolvedValue(projectVulnerabilityImages);
  const mockImages = projectVulnerabilityImages.data.project.vulnerabilityImages.nodes;

  const createMockApolloProvider = (queryResolver = defaultQueryResolver) => {
    Vue.use(VueApollo);
    return createMockApollo([[getVulnerabilityImagesQuery, queryResolver]]);
  };

  const createWrapper = (queryResolver) => {
    wrapper = shallowMount(ImageFilter, {
      apolloProvider: createMockApolloProvider(queryResolver),
      propsData: { filter: imageFilter },
      provide: { projectFullPath },
    });
  };

  const findFilterItems = () => wrapper.findAllComponents(FilterItem);

  afterEach(() => {
    createFlash.mockClear();
    wrapper.destroy();
  });

  describe('default behavior', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    it('retrieves the options', () => {
      expect(defaultQueryResolver).toHaveBeenCalledTimes(1);
      expect(defaultQueryResolver.mock.calls[0][0]).toEqual({ projectPath: projectFullPath });
    });

    it('displays the all option item', () => {
      expect(findFilterItems().at(0).props()).toStrictEqual({
        isChecked: true,
        text: 'All images',
        truncate: false,
      });
    });

    it('populates the filter options from the query response', () => {
      mockImages.forEach(({ name }, index) => {
        expect(
          findFilterItems()
            .at(index + 1)
            .props(),
        ).toStrictEqual({ isChecked: false, text: name, truncate: true });
      });
    });
  });

  it('shows an alert on a failed graphql request', async () => {
    const errorSpy = jest.fn().mockRejectedValue();
    createWrapper(errorSpy);
    await waitForPromises();
    expect(createFlash).toHaveBeenCalledWith({ message: IMAGE_FILTER_ERROR });
  });
});
