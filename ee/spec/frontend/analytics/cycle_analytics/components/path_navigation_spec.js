import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import FormattedStageCount from '~/analytics/cycle_analytics/components/formatted_stage_count.vue';
import Component from '~/analytics/cycle_analytics/components/path_navigation.vue';
import { OVERVIEW_STAGE_ID } from '~/analytics/cycle_analytics/constants';
import { transformedStagePathData, issueStage } from '../mock_data';

describe('Group PathNavigation', () => {
  let wrapper = null;

  const createComponent = (props) => {
    return extendedWrapper(
      mount(Component, {
        propsData: {
          stages: transformedStagePathData,
          selectedStage: issueStage,
          loading: false,
          ...props,
        },
      }),
    );
  };

  const pathNavigationItems = () => {
    return wrapper.findByTestId('gl-path-nav').findAll('li');
  };

  const pathItemContent = () => pathNavigationItems().wrappers.map(extendedWrapper);
  const firstPopover = () => wrapper.findAllByTestId('stage-item-popover').at(0);
  const findStageCountAtIndex = (index) => wrapper.findAllComponents(FormattedStageCount).at(index);

  const stagesWithCounts = transformedStagePathData.filter(
    (stage) => stage.id !== OVERVIEW_STAGE_ID,
  );

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('popovers', () => {
    beforeEach(() => {
      wrapper = createComponent({ stages: transformedStagePathData });
    });

    it('renders popovers for all stages except for the overview stage', () => {
      const [overviewStage, ...popoverStages] = pathItemContent();

      expect(overviewStage.text()).toContain('Overview');
      expect(overviewStage.findByTestId('stage-item-popover').exists()).toBe(false);

      popoverStages.forEach((stage) => {
        expect(stage.findByTestId('stage-item-popover').exists()).toBe(true);
      });
    });

    it('shows the sanitized start event description for the first stage item', () => {
      const expectedStartEventDescription = 'Issue created';
      expect(firstPopover().text()).toContain(expectedStartEventDescription);
    });

    it('shows the sanitized end event description for the first stage item', () => {
      const expectedStartEventDescription =
        'Issue first associated with a milestone or first added to a board';
      expect(firstPopover().text()).toContain(expectedStartEventDescription);
    });

    it('shows the median stage time for the first stage item', () => {
      expect(firstPopover().text()).toContain('Stage time (median)');
    });

    it('renders each stage with its stage count', () => {
      const popoverStages = pathItemContent().slice(1); // skip the first stage, the overview does not have a popover
      popoverStages.forEach((stage, index) => {
        const content = stage.findByTestId('stage-item-popover').html();
        expect(content).toContain('Items in stage');
        expect(findStageCountAtIndex(index).props('stageCount')).toBe(
          stagesWithCounts[index].stageCount,
        );
      });
    });
  });
});
