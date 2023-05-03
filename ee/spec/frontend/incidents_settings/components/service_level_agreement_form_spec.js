import { GlButton, GlForm, GlFormGroup } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import merge from 'lodash/merge';
import ServiceLevelAgreementForm from 'ee/incidents_settings/components/service_level_agreement_form.vue';

const defaultData = { enabled: true, duration: 15, units: 'minutes' };

describe('Alert integration settings form', () => {
  let wrapper;
  const service = { updateSettings: jest.fn().mockResolvedValue() };

  const mountComponent = (options, mountMethod = shallowMount) => {
    wrapper = mountMethod(
      ServiceLevelAgreementForm,
      merge(
        {
          provide: {
            service,
            serviceLevelAgreementSettings: { available: true },
          },
          data() {
            return { ...defaultData };
          },
        },
        options,
      ),
    );
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findSubmitButton = () => wrapper.findComponent(GlButton);

  it('renders an empty component when feature not available', () => {
    mountComponent({ provide: { serviceLevelAgreementSettings: { available: false } } });

    expect(wrapper.html()).toBe('');
  });

  it('should match the default snapshot', () => {
    mountComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  describe('Form fields', () => {
    it('should call service `updateSettings` on submit', () => {
      mountComponent({}, mount);

      findForm().trigger('submit');

      expect(service.updateSettings).toHaveBeenCalledWith(
        expect.objectContaining({
          sla_timer: true,
          sla_timer_minutes: 15,
        }),
      );
    });

    it('should allow submit when form is valid', () => {
      mountComponent();

      expect(findFormGroup().attributes('state')).toBe('true');
    });

    describe.each`
      enabled | duration | unit         | isValid  | expectedMessage
      ${true} | ${''}    | ${'minutes'} | ${false} | ${'Time limit must be a valid number'}
      ${true} | ${-15}   | ${'minutes'} | ${false} | ${'Time limit must be greater than 0'}
      ${true} | ${0}     | ${'minutes'} | ${false} | ${'Time limit must be greater than 0'}
      ${true} | ${0.5}   | ${'minutes'} | ${false} | ${'Time limit must be a multiple of 15 minutes'}
      ${true} | ${5}     | ${'minutes'} | ${false} | ${'Time limit must be a multiple of 15 minutes'}
      ${true} | ${15}    | ${'minutes'} | ${true}  | ${''}
      ${true} | ${0}     | ${'hours'}   | ${false} | ${'Time limit must be greater than 0'}
      ${true} | ${0.15}  | ${'hours'}   | ${false} | ${'Time limit must be a multiple of 15 minutes'}
      ${true} | ${0.5}   | ${'hours'}   | ${true}  | ${''}
      ${true} | ${1}     | ${'hours'}   | ${true}  | ${''}
      ${true} | ${24}    | ${'hours'}   | ${true}  | ${''}
    `(
      'Inputs enabled "$enabled", "$duration" $unit',
      ({ enabled, duration, unit, isValid, expectedMessage }) => {
        beforeEach(() => {
          mountComponent(
            {
              data() {
                return { ...defaultData, enabled, duration, unit };
              },
            },
            mount,
          );
        });

        it(`should${isValid ? '' : ' not'} allow submit`, () => {
          expect(findSubmitButton().attributes('disabled')).toBe(isValid ? undefined : 'disabled');
        });

        it(`should show ${isValid ? 'no' : 'the correct'} error message`, () => {
          expect(findFormGroup().text()).toContain(expectedMessage);
        });
      },
    );
  });
});
