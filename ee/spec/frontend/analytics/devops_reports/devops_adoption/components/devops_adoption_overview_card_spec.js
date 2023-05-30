import { GlIcon, GlProgressBar } from '@gitlab/ui';
import DevopsAdoptionOverviewCard from 'ee/analytics/devops_reports/devops_adoption/components/devops_adoption_overview_card.vue';
import DevopsAdoptionTableCellFlag from 'ee/analytics/devops_reports/devops_adoption/components/devops_adoption_table_cell_flag.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { overallAdoptionData } from '../mock_data';

const metrics = `${overallAdoptionData.featureMeta.filter(({ adopted }) => adopted).length}/${
  overallAdoptionData.featureMeta.length
}`;

describe('DevopsAdoptionOverview', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMountExtended(DevopsAdoptionOverviewCard, {
      propsData: {
        ...overallAdoptionData,
        displayMeta: true,
        ...props,
      },
    });
  };

  const findCardLink = () => wrapper.findByTestId('card-title-link');
  const findCardDescription = () => wrapper.findByTestId('card-description');
  const findCardMetaRow = () => wrapper.findByTestId('card-meta-row');

  describe('default state', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('title', () => {
      it('displays a icon', () => {
        const icon = wrapper.findComponent(GlIcon);

        expect(icon.exists()).toBe(true);
        expect(icon.props('name')).toBe(overallAdoptionData.icon);
      });

      it('displays the title text', () => {
        const text = findCardLink();

        expect(text.exists()).toBe(true);
        expect(text.text()).toBe(overallAdoptionData.title);
      });
    });

    it('displays the progress bar', () => {
      expect(wrapper.findComponent(GlProgressBar).exists()).toBe(true);
    });

    it('displays the description correctly', () => {
      const text = findCardDescription();

      expect(text.exists()).toBe(true);
      expect(text.text()).toBe(`${metrics} Overall adoption features adopted`);
    });

    describe('meta', () => {
      it('displays the meta', () => {
        expect(findCardMetaRow().exists()).toBe(true);
      });

      it('displays the correct number of rows', () => {
        expect(wrapper.findAllByTestId('card-meta-row')).toHaveLength(
          overallAdoptionData.featureMeta.length,
        );
      });

      describe('meta row', () => {
        it('displays a cell flag component', () => {
          expect(wrapper.findComponent(DevopsAdoptionTableCellFlag).exists()).toBe(true);
        });

        it('displays the feature title', () => {
          expect(wrapper.findByTestId('card-meta-row-title').text()).toBe(
            overallAdoptionData.featureMeta[0].title,
          );
        });

        it('emits the correct event', () => {
          findCardLink().vm.$emit('click');

          expect(wrapper.emitted()).toHaveProperty('card-title-clicked');
        });
      });
    });
  });

  describe('when not displaying meta', () => {
    beforeEach(() => {
      createComponent({ displayMeta: false });
    });

    it('displays the description correctly', () => {
      const text = findCardDescription();

      expect(text.exists()).toBe(true);
      expect(text.text()).toBe(`${metrics}  features adopted`);
    });

    it('does not display the meta', () => {
      expect(findCardMetaRow().exists()).toBe(false);
    });
  });
});
