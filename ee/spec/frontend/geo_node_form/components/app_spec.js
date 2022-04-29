import { GlBadge, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { PRIMARY_SITE_SETTINGS, SECONDARY_SITE_SETTINGS } from 'ee/geo_node_form//constants';
import GeoNodeFormApp from 'ee/geo_node_form/components/app.vue';
import GeoNodeForm from 'ee/geo_node_form/components/geo_node_form.vue';
import { MOCK_SELECTIVE_SYNC_TYPES, MOCK_SYNC_SHARDS } from '../mock_data';

describe('GeoNodeFormApp', () => {
  let wrapper;

  const propsData = {
    selectiveSyncTypes: MOCK_SELECTIVE_SYNC_TYPES,
    syncShardsOptions: MOCK_SYNC_SHARDS,
    node: undefined,
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(GeoNodeFormApp, {
      propsData,
      stubs: { GlSprintf },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoNodeFormTitle = () => wrapper.find('h2');
  const findGeoNodeFormBadge = () => wrapper.findComponent(GlBadge);
  const findGeoNodeFormSubTitle = () => wrapper.findByTestId('node-form-subtitle');
  const findGeoNodeFormLearnMoreLink = () => wrapper.findComponent(GlLink);
  const findGeoForm = () => wrapper.findComponent(GeoNodeForm);

  describe('render', () => {
    beforeEach(() => {
      createComponent();
    });

    describe.each`
      formType                     | node                  | title                              | subTitle                                                 | learnMoreLink              | pillTitle                        | variant
      ${'create a secondary node'} | ${null}               | ${GeoNodeFormApp.i18n.addGeoSite}  | ${'Configure various settings for your secondary site.'} | ${SECONDARY_SITE_SETTINGS} | ${GeoNodeFormApp.i18n.secondary} | ${'muted'}
      ${'update a secondary node'} | ${{ primary: false }} | ${GeoNodeFormApp.i18n.editGeoSite} | ${'Configure various settings for your secondary site.'} | ${SECONDARY_SITE_SETTINGS} | ${GeoNodeFormApp.i18n.secondary} | ${'muted'}
      ${'update a primary node'}   | ${{ primary: true }}  | ${GeoNodeFormApp.i18n.editGeoSite} | ${'Configure various settings for your primary site.'}   | ${PRIMARY_SITE_SETTINGS}   | ${GeoNodeFormApp.i18n.primary}   | ${'info'}
    `(`form header`, ({ formType, node, title, subTitle, learnMoreLink, pillTitle, variant }) => {
      describe(`when node form is to ${formType}`, () => {
        beforeEach(() => {
          propsData.node = node;
          createComponent();
        });

        it(`sets the node form title to ${title}`, () => {
          expect(findGeoNodeFormTitle().text()).toBe(title);
        });

        it(`sets the node form subtitle to ${subTitle}`, () => {
          expect(findGeoNodeFormSubTitle().text()).toContain(subTitle);
        });

        it(`sets the node form learn more link to ${learnMoreLink}`, () => {
          expect(findGeoNodeFormLearnMoreLink().attributes('href')).toBe(learnMoreLink);
        });

        it(`sets the node form pill title to ${pillTitle}`, () => {
          expect(findGeoNodeFormBadge().text()).toBe(pillTitle);
        });

        it(`sets the node form pill variant to be ${variant}`, () => {
          expect(findGeoNodeFormBadge().attributes('variant')).toBe(variant);
        });
      });
    });

    it('the Geo Node Form', () => {
      expect(findGeoForm().exists()).toBe(true);
    });
  });
});
