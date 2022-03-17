import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import timezoneMock from 'timezone-mock';
import IterationsList from 'ee/iterations/components/iterations_list.vue';
import IterationTitle from 'ee/iterations/components/iteration_title.vue';
import { getIterationPeriod } from 'ee/iterations/utils';

describe('Iterations list', () => {
  let wrapper;

  const findGlLink = () => wrapper.findComponent(GlLink);

  const mountComponent = (propsData = { iterations: [] }) => {
    wrapper = shallowMount(IterationsList, {
      propsData,
      stubs: {
        IterationTitle,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    timezoneMock.unregister();
  });

  it('shows empty state', () => {
    mountComponent();

    expect(wrapper.html()).toHaveText('No iterations to show');
  });

  describe('with iterations', () => {
    const iteration = {
      id: '123',
      title: null,
      startDate: '2020-05-27',
      dueDate: '2020-06-04',
      scopedPath: null,
      webPath: '/groups/gitlab-org/-/iterations/1',
    };

    it('shows iteration', () => {
      mountComponent({
        iterations: [iteration],
      });

      expect(wrapper.html()).not.toHaveText('No iterations to show');
      expect(findGlLink().text()).toBe(getIterationPeriod(iteration));
    });

    describe('when iteration has a title', () => {
      it('shows iteration with title', () => {
        mountComponent({
          iterations: [{ ...iteration, title: 'Iteration #1' }],
        });

        expect(wrapper.html()).not.toHaveText('No iterations to show');
        expect(findGlLink().text()).toBe(getIterationPeriod(iteration));
        expect(wrapper.html()).toHaveText('Iteration #1');
      });
    });

    it('displays dates in UTC time, regardless of user timezone', () => {
      timezoneMock.register('US/Pacific');

      mountComponent({
        iterations: [iteration],
      });

      expect(wrapper.html()).toHaveText('May 27, 2020');
      expect(wrapper.html()).toHaveText('Jun 4, 2020');
    });

    describe('when within group', () => {
      it('links to iteration report within group', () => {
        mountComponent({
          iterations: [iteration],
        });

        expect(findGlLink().attributes('href')).toBe(iteration.webPath);
      });
    });

    describe('when within project', () => {
      it('links to iteration report within project', () => {
        const scopedPath = '/gitlab-org/gitlab-test/-/iterations/inherited/1';

        mountComponent({
          iterations: [
            {
              ...iteration,
              scopedPath,
            },
          ],
        });

        expect(findGlLink().attributes('href')).toBe(scopedPath);
      });
    });
  });
});
