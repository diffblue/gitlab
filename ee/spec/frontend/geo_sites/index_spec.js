import MockAdapter from 'axios-mock-adapter';
import { createWrapper } from '@vue/test-utils';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import waitForPromises from 'helpers/wait_for_promises';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { initGeoSites } from 'ee/geo_sites';
import { GEO_SITE_W_DATA_FIXTURE, MOCK_SITES_RES, MOCK_SITE_STATUSES_RES } from './mock_data';

describe('initGeoSites', () => {
  let wrapper;
  let mock;

  const mockAPI = (apiMocks) => {
    // geo_nodes API to be renamed geo_sites API => https://gitlab.com/gitlab-org/gitlab/-/issues/369140
    mock = new MockAdapter(axios);
    mock.onGet(/api\/(.*)\/geo_nodes/).reply(HTTP_STATUS_OK, apiMocks.res);
    mock.onGet(/api\/(.*)\/geo_nodes\/status/).reply(HTTP_STATUS_OK, apiMocks.statusRes);
  };

  const createAppWrapper = (fixture, apiMocks) => {
    mockAPI(apiMocks);
    setHTMLFixture(fixture);
    wrapper = createWrapper(initGeoSites());
  };

  afterEach(() => {
    resetHTMLFixture();
    mock.restore();
  });

  describe.each`
    description                            | fixture                    | link
    ${'with no geo elements'}              | ${'<div></div>'}           | ${{ href: '', expected: undefined }}
    ${'with #js-geo-sites and valid data'} | ${GEO_SITE_W_DATA_FIXTURE} | ${{ href: 'admin/geo/sites/new', expected: true }}
  `('Add Site Link: $description', ({ fixture, link }) => {
    beforeEach(() => {
      createAppWrapper(fixture, { res: MOCK_SITES_RES, statusRes: MOCK_SITE_STATUSES_RES });
    });

    it(`does${link.expected ? '' : ' not'} render with the correct URL`, async () => {
      await waitForPromises();

      expect(wrapper.vm && wrapper.find(`a[href="${link.href}"`).exists()).toBe(link.expected);
    });
  });

  describe.each`
    description                            | fixture                    | emptyState
    ${'with no geo elements'}              | ${'<div></div>'}           | ${{ src: '', expected: undefined }}
    ${'with #js-geo-sites and valid data'} | ${GEO_SITE_W_DATA_FIXTURE} | ${{ src: 'geo/sites/empty-state.svg', expected: true }}
  `('Empty State: $description', ({ fixture, emptyState }) => {
    beforeEach(() => {
      createAppWrapper(fixture, { res: [], statusRes: [] });
    });

    it(`does${emptyState.expected ? '' : ' not'} render the correct empty state SVG`, async () => {
      await waitForPromises();

      expect(wrapper.vm && wrapper.find(`img[src="${emptyState.src}"`).exists()).toBe(
        emptyState.expected,
      );
    });
  });
});
