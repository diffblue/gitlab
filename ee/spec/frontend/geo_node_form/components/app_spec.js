import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
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
    wrapper = shallowMount(GeoNodeFormApp, {
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoNodeFormTitle = () => wrapper.find('h2');
  const findGeoNodeFormBadge = () => wrapper.find(GlBadge);
  const findGeoForm = () => wrapper.find(GeoNodeForm);

  describe('render', () => {
    beforeEach(() => {
      createComponent();
    });

    describe.each`
      formType                     | node                  | title              | pillTitle      | variant
      ${'create a secondary node'} | ${null}               | ${'Add New Site'}  | ${'Secondary'} | ${'muted'}
      ${'update a secondary node'} | ${{ primary: false }} | ${'Edit Geo Site'} | ${'Secondary'} | ${'muted'}
      ${'update a primary node'}   | ${{ primary: true }}  | ${'Edit Geo Site'} | ${'Primary'}   | ${'info'}
    `(`form header`, ({ formType, node, title, pillTitle, variant }) => {
      describe(`when node form is to ${formType}`, () => {
        beforeEach(() => {
          propsData.node = node;
          createComponent();
        });

        it(`sets the node form title to ${title}`, () => {
          expect(findGeoNodeFormTitle().text()).toBe(title);
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
