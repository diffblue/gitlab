import { mountExtended } from 'helpers/vue_test_utils_helper';
import RunnerUpdateCostFactorFields from 'ee/ci/runner/components/runner_update_cost_factor_fields.vue';
import { runnerData } from 'jest/ci/runner/mock_data';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '~/ci/runner/constants';

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

  const createComponent = ({ props } = {}) => {
    wrapper = mountExtended(RunnerUpdateCostFactorFields, {
      propsData: {
        runnerType: INSTANCE_TYPE,
        value: mockRunner,
        ...props,
      },
    });
  };

  describe('when on dot_com', () => {
    beforeEach(() => {
      gon.dot_com = true;
    });

    describe('for an instance runner', () => {
      beforeEach(() => {
        createComponent({ props: { runnerType: INSTANCE_TYPE } });
      });

      it('shows cost factor number fields', () => {
        const fieldAttrs = {
          step: 'any',
          type: 'number',
        };

        expect(findPrivateProjectsCostFactor().find('input').attributes()).toMatchObject(
          fieldAttrs,
        );
        expect(findPublicProjectsCostFactor().find('input').attributes()).toMatchObject(fieldAttrs);
      });

      it('handles input of private cost factor', () => {
        triggerInput(findPrivateProjectsCostFactor(), '3.50');

        expect(wrapper.emitted('input').length).toBe(1);
        expect(wrapper.emitted('input')[0]).toEqual([
          {
            ...mockRunner,
            privateProjectsMinutesCostFactor: 3.5,
          },
        ]);
      });

      it('handles input of public cost factor', () => {
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

    describe.each([GROUP_TYPE, PROJECT_TYPE])('for other runners', (runnerType) => {
      beforeEach(() => {
        createComponent({ props: { runnerType } });
      });

      it('does not show cost factor fields', () => {
        expect(findPrivateProjectsCostFactor().exists()).toBe(false);
        expect(findPublicProjectsCostFactor().exists()).toBe(false);
      });
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
