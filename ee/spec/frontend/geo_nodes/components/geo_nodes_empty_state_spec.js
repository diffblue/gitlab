import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import GeoNodesEmptyState from 'ee/geo_nodes/components/geo_nodes_empty_state.vue';
import { GEO_INFO_URL } from 'ee/geo_nodes/constants';
import { MOCK_EMPTY_STATE_SVG } from '../mock_data';

describe('GeoNodesEmptyState', () => {
  let wrapper;

  const defaultProps = {
    title: 'test title',
    description: 'test description',
  };

  const createComponent = (props) => {
    wrapper = shallowMount(GeoNodesEmptyState, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        geoNodesEmptyStateSvg: MOCK_EMPTY_STATE_SVG,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoEmptyState = () => wrapper.findComponent(GlEmptyState);

  describe('template', () => {
    describe('always', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the Geo Empty State', () => {
        expect(findGeoEmptyState().exists()).toBe(true);
      });

      it('adds the correct SVG', () => {
        expect(findGeoEmptyState().props('svgPath')).toBe(MOCK_EMPTY_STATE_SVG);
      });

      it('sets the title and description', () => {
        expect(findGeoEmptyState().props('title')).toBe(defaultProps.title);
        expect(findGeoEmptyState().props('description')).toBe(defaultProps.description);
      });
    });

    describe('when showLearnMoreButton is true', () => {
      beforeEach(() => {
        createComponent({ showLearnMoreButton: true });
      });

      it('renders the learn more button with the correct link', () => {
        expect(findGeoEmptyState().props('primaryButtonText')).toBe(
          GeoNodesEmptyState.i18n.learnMoreButtonText,
        );
        expect(findGeoEmptyState().props('primaryButtonLink')).toBe(GEO_INFO_URL);
      });
    });

    describe('when showLearnMoreButton is false', () => {
      beforeEach(() => {
        createComponent({ showLearnMoreButton: false });
      });

      it('does not render the learn more button', () => {
        expect(findGeoEmptyState().props('primaryButtonText')).toBe('');
        expect(findGeoEmptyState().props('primaryButtonLink')).toBe('');
      });
    });
  });
});
