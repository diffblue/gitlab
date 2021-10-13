import { GlSegmentedControl } from '@gitlab/ui';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import * as urlUtils from '~/lib/utils/url_utility';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DateSelector from 'ee/analytics/contribution_analytics/components/date_selector.vue';
import { DATE_OPTIONS } from 'ee/analytics/contribution_analytics/constants';

const path = 'http://path.path';

describe('DateSelector', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(DateSelector, {
      provide: {
        path,
      },
    });
  };

  const findSegmentControl = () => wrapper.findComponent(GlSegmentedControl);

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays the segmented control component', () => {
    createComponent();

    expect(findSegmentControl().exists()).toBe(true);
  });

  it('contains the correct segmented control items', () => {
    createComponent();

    expect(findSegmentControl().props('options')).toEqual(DATE_OPTIONS);
  });

  describe('on item click', () => {
    useMockLocationHelper();

    beforeEach(() => {
      jest.spyOn(urlUtils, 'getParameterByName').mockReturnValue('1234');
      createComponent();
    });

    it.each(DATE_OPTIONS)('redirects to the correct URL', ({ value }) => {
      const spy = jest.spyOn(urlUtils, 'redirectTo');

      findSegmentControl().vm.$emit('change', value);

      expect(spy).toHaveBeenCalledWith(`${path}?start_date=${value}`);
    });
  });

  describe.each(DATE_OPTIONS)('default selected option', ({ value }) => {
    beforeEach(() => {
      jest.spyOn(urlUtils, 'getParameterByName').mockReturnValue(value);
      createComponent();
    });

    it('sets the correct selected option', () => {
      expect(findSegmentControl().props('checked')).toBe(value);
    });
  });
});
