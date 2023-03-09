import { GlLoadingIcon } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import RelatedFeatureFlags from 'ee/issues/components/related_feature_flags.vue';
import { TEST_HOST } from 'helpers/test_constants';
import { trimText } from 'helpers/text_helper';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/alert');

const ENDPOINT = `${TEST_HOST}/endpoint`;

const DEFAULT_PROVIDE = {
  endpoint: ENDPOINT,
};

const MOCK_DATA = [
  {
    id: 5,
    name: 'foo',
    iid: 2,
    active: true,
    path: '/gitlab-org/gitlab-test/-/feature_flags/2',
    reference: '[feature_flag:2]',
    link_type: 'relates_to',
  },
  {
    id: 2,
    name: 'bar',
    iid: 1,
    active: false,
    path: '/h5bp/html5-boilerplate/-/feature_flags/1',
    reference: '[feature_flag:h5bp/html5-boilerplate/1]',
    link_type: 'relates_to',
  },
];

describe('ee/issues/components/related_feature_flags.vue', () => {
  let mock;
  let wrapper;

  const createWrapper = (provide = {}) => {
    wrapper = mountExtended(RelatedFeatureFlags, {
      provide: {
        ...DEFAULT_PROVIDE,
        ...provide,
      },
    });
  };

  afterEach(() => {
    mock.restore();
  });

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  describe('with endpoint', () => {
    it('displays a loading icon while feature flags load', () => {
      mock.onGet(ENDPOINT).reply(() => new Promise(() => {}));
      createWrapper();
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });

    it('displays nothing if there are no feature flags loaded', async () => {
      mock.onGet(ENDPOINT).reply(HTTP_STATUS_OK, []);
      createWrapper();
      await waitForPromises();
      await nextTick();

      expect(wrapper.find('#related-feature-flags').exists()).toBe(false);
    });

    it('displays nothing if the request fails', async () => {
      mock.onGet(ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      createWrapper();
      await waitForPromises();
      await nextTick();

      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'There was an error loading related feature flags',
        }),
      );
      expect(wrapper.find('#related-feature-flags').exists()).toBe(false);
    });

    describe('with loaded feature flags', () => {
      beforeEach(async () => {
        mock.onGet(ENDPOINT).reply(HTTP_STATUS_OK, MOCK_DATA);
        createWrapper();
        await waitForPromises();
        await nextTick();
      });

      it('displays the number of referenced feature flags', () => {
        const header = wrapper.findByRole('heading', `Related feature flags ${MOCK_DATA.length}`);
        expect(trimText(header.text())).toBe(`Related feature flags ${MOCK_DATA.length}`);
      });

      it.each(MOCK_DATA.map((data, index) => [data.name, data, index]))(
        'displays information for feature flag %s',
        (_, flag, index) => {
          const flagRow = extendedWrapper(
            wrapper.findAllByTestId('feature-flag-details').at(index),
          );

          const icon = flagRow.findByTestId('feature-flag-details-icon');
          expect(icon.props('name')).toBe(flag.active ? 'feature-flag' : 'feature-flag-disabled');
          expect(icon.attributes('title')).toBe(flag.active ? 'Active' : 'Inactive');

          const link = flagRow.findByRole('link', flag.name);
          expect(link.attributes('href')).toBe(flag.path);
          expect(link.attributes('title')).toBe(flag.name);

          const reference = flagRow.findByTestId('feature-flag-details-reference');
          expect(reference.text()).toBe(flag.reference);
          expect(reference.attributes('title')).toBe(flag.reference);
        },
      );
    });
  });

  describe('without endoint', () => {
    it('renders nothing', async () => {
      createWrapper({ endpoint: '' });
      await nextTick();

      expect(wrapper.find('#related-feature-flags').exists()).toBe(false);
    });
  });
});
