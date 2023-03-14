import { GlBadge, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { PRIMARY_SITE_SETTINGS, SECONDARY_SITE_SETTINGS } from 'ee/geo_site_form//constants';
import GeoSiteFormApp from 'ee/geo_site_form/components/app.vue';
import GeoSiteForm from 'ee/geo_site_form/components/geo_site_form.vue';
import { MOCK_SELECTIVE_SYNC_TYPES, MOCK_SYNC_SHARDS } from '../mock_data';

describe('GeoSiteFormApp', () => {
  let wrapper;

  const propsData = {
    selectiveSyncTypes: MOCK_SELECTIVE_SYNC_TYPES,
    syncShardsOptions: MOCK_SYNC_SHARDS,
    site: undefined,
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(GeoSiteFormApp, {
      propsData,
      stubs: { GlSprintf },
    });
  };

  const findGeoSiteFormTitle = () => wrapper.find('h2');
  const findGeoSiteFormBadge = () => wrapper.findComponent(GlBadge);
  const findGeoSiteFormSubTitle = () => wrapper.findByTestId('site-form-subtitle');
  const findGeoSiteFormLearnMoreLink = () => wrapper.findComponent(GlLink);
  const findGeoForm = () => wrapper.findComponent(GeoSiteForm);

  describe('render', () => {
    beforeEach(() => {
      createComponent();
    });

    describe.each`
      formType                     | site                  | title                              | subTitle                                                 | learnMoreLink              | pillTitle                        | variant
      ${'create a secondary site'} | ${null}               | ${GeoSiteFormApp.i18n.addGeoSite}  | ${'Configure various settings for your secondary site.'} | ${SECONDARY_SITE_SETTINGS} | ${GeoSiteFormApp.i18n.secondary} | ${'muted'}
      ${'update a secondary site'} | ${{ primary: false }} | ${GeoSiteFormApp.i18n.editGeoSite} | ${'Configure various settings for your secondary site.'} | ${SECONDARY_SITE_SETTINGS} | ${GeoSiteFormApp.i18n.secondary} | ${'muted'}
      ${'update a primary site'}   | ${{ primary: true }}  | ${GeoSiteFormApp.i18n.editGeoSite} | ${'Configure various settings for your primary site.'}   | ${PRIMARY_SITE_SETTINGS}   | ${GeoSiteFormApp.i18n.primary}   | ${'info'}
    `(`form header`, ({ formType, site, title, subTitle, learnMoreLink, pillTitle, variant }) => {
      describe(`when site form is to ${formType}`, () => {
        beforeEach(() => {
          propsData.site = site;
          createComponent();
        });

        it(`sets the site form title to ${title}`, () => {
          expect(findGeoSiteFormTitle().text()).toBe(title);
        });

        it(`sets the site form subtitle to ${subTitle}`, () => {
          expect(findGeoSiteFormSubTitle().text()).toContain(subTitle);
        });

        it(`sets the site form learn more link to ${learnMoreLink}`, () => {
          expect(findGeoSiteFormLearnMoreLink().attributes('href')).toBe(learnMoreLink);
        });

        it(`sets the site form pill title to ${pillTitle}`, () => {
          expect(findGeoSiteFormBadge().text()).toBe(pillTitle);
        });

        it(`sets the site form pill variant to be ${variant}`, () => {
          expect(findGeoSiteFormBadge().attributes('variant')).toBe(variant);
        });
      });
    });

    it('the Geo Site Form', () => {
      expect(findGeoForm().exists()).toBe(true);
    });
  });
});
