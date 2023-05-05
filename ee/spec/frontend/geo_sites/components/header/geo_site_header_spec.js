import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import GeoSiteActions from 'ee/geo_sites/components/header/geo_site_actions.vue';
import GeoSiteHeader from 'ee/geo_sites/components/header/geo_site_header.vue';
import GeoSiteHealthStatus from 'ee/geo_sites/components/header/geo_site_health_status.vue';
import GeoSiteLastUpdated from 'ee/geo_sites/components/header/geo_site_last_updated.vue';
import { MOCK_PRIMARY_SITE, MOCK_SECONDARY_SITE } from 'ee_jest/geo_sites/mock_data';

describe('GeoSiteHeader', () => {
  let wrapper;

  const defaultProps = {
    site: MOCK_PRIMARY_SITE,
    collapsed: false,
  };

  const createComponent = (props) => {
    wrapper = shallowMount(GeoSiteHeader, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findHeaderCollapseButton = () => wrapper.findComponent(GlButton);
  const findGeoSiteHealthStatus = () => wrapper.findComponent(GeoSiteHealthStatus);
  const findGeoSiteLastUpdated = () => wrapper.findComponent(GeoSiteLastUpdated);
  const findGeoSiteActions = () => wrapper.findComponent(GeoSiteActions);

  describe('template', () => {
    describe('always', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the Geo Site Health Status', () => {
        expect(findGeoSiteHealthStatus().exists()).toBe(true);
      });

      it('renders the Geo Site Actions', () => {
        expect(findGeoSiteActions().exists()).toBe(true);
      });
    });

    describe('Header Collapse Icon', () => {
      describe('when not collapsed', () => {
        beforeEach(() => {
          createComponent();
        });

        it('renders the chevron-down icon', () => {
          expect(findHeaderCollapseButton().attributes('icon')).toBe('chevron-down');
        });
      });

      describe('when collapsed', () => {
        beforeEach(() => {
          createComponent({ collapsed: true });
        });

        it('renders the chevron-right icon', () => {
          expect(findHeaderCollapseButton().attributes('icon')).toBe('chevron-right');
        });
      });

      describe('on click', () => {
        beforeEach(() => {
          createComponent();

          findHeaderCollapseButton().vm.$emit('click');
        });

        it('emits the collapse event', () => {
          expect(wrapper.emitted('collapse')).toHaveLength(1);
        });
      });
    });

    describe('Last updated', () => {
      describe('when lastSuccessfulStatusCheckTimestamp exists', () => {
        beforeEach(() => {
          createComponent({
            site: {
              ...MOCK_SECONDARY_SITE,
              lastSuccessfulStatusCheckTimestamp: new Date().getTime(),
            },
          });
        });

        it('renders', () => {
          expect(findGeoSiteLastUpdated().exists()).toBe(true);
        });
      });

      describe('when lastSuccessfulStatusCheckTimestamp does not exist', () => {
        beforeEach(() => {
          createComponent();
        });

        it('renders', () => {
          expect(findGeoSiteLastUpdated().exists()).toBe(false);
        });
      });
    });
  });
});
