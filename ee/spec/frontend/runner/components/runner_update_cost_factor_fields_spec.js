import { mountExtended } from 'helpers/vue_test_utils_helper';
import RunnerUpdateCostFactorFields from 'ee/runner/components/runner_update_cost_factor_fields.vue';
import { runnerData } from 'jest/runner/mock_data';

const mockRunner = runnerData.data.runner;

describe('RunnerUpdateCostFactorFields', () => {
  let wrapper;

  const findPrivateProjectsCostFactor = () =>
    wrapper.findByTestId('runner-field-private-projects-cost-factor');
  const findPublicProjectsCostFactor = () =>
    wrapper.findByTestId('runner-field-public-projects-cost-factor');

  const triggerInput = (formGroup, value) => {
    const input = formGroup.find('input');
    input.element.value = value;
    input.trigger('input');
  };

  const createComponent = () => {
    wrapper = mountExtended(RunnerUpdateCostFactorFields, {
      propsData: {
        value: mockRunner,
      },
    });
  };

  describe('when on dot_com', () => {
    beforeEach(() => {
      gon.dot_com = true;
      createComponent();
    });

    it('shows cost factor fields', () => {
      expect(findPrivateProjectsCostFactor().exists()).toBe(true);
      expect(findPublicProjectsCostFactor().exists()).toBe(true);
    });

    it('handles input of private cost factor', async () => {
      triggerInput(findPrivateProjectsCostFactor(), '3.50');

      expect(wrapper.emitted('input').length).toBe(1);
      expect(wrapper.emitted('input')[0]).toEqual([
        {
          ...mockRunner,
          privateProjectsMinutesCostFactor: 3.5,
        },
      ]);
    });

    it('handles input of public cost factor', async () => {
      triggerInput(findPublicProjectsCostFactor(), '2.50');

      expect(wrapper.emitted('input').length).toBe(1);
      expect(wrapper.emitted('input')[0]).toEqual([
        {
          ...mockRunner,
          publicProjectsMinutesCostFactor: 2.5,
        },
      ]);
    });
  });

  describe('when self-hosted', () => {
    beforeEach(() => {
      gon.dot_com = false;
      createComponent();
    });

    it('does not show cost factor fields', () => {
      expect(findPrivateProjectsCostFactor().exists()).toBe(false);
      expect(findPublicProjectsCostFactor().exists()).toBe(false);
    });
  });
});
