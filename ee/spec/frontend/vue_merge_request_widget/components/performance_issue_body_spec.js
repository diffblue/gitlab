import { shallowMount } from '@vue/test-utils';
import component from 'ee/vue_merge_request_widget/components/performance_issue_body.vue';

describe('performance issue body', () => {
  let wrapper;

  describe.each`
    name                    | score                 | delta                 | expectedScore | expectedDelta | expectedPercentage
    ${'Transfer Size (KB)'} | ${'4974.8'}           | ${0.1999999999998181} | ${'4974.80'}  | ${'(+0.19)'}  | ${'(+0%)'}
    ${'Speed Index'}        | ${1474}               | ${727}                | ${'1474'}     | ${'(+727)'}   | ${'(+97%)'}
    ${'Checks'}             | ${'97.73%'}           | ${-2.27}              | ${'97.73%'}   | ${'(-2.27)'}  | ${null}
    ${'RPS'}                | ${22.699900441941768} | ${-1}                 | ${'22.69'}    | ${'(-1)'}     | ${'(-4%)'}
    ${'TTFB P95'}           | ${205.02902265}       | ${0}                  | ${'205.02'}   | ${null}       | ${null}
  `(
    'with an example $name performance metric',
    ({ name, score, delta, expectedScore, expectedDelta, expectedPercentage }) => {
      beforeEach(() => {
        wrapper = shallowMount(component, {
          propsData: {
            issue: {
              path: '/',
              name,
              score,
              delta,
            },
          },
        });
      });

      it('renders issue name', () => {
        expect(wrapper.text()).toContain(name);
      });

      it('renders issue score formatted', () => {
        expect(wrapper.text()).toContain(expectedScore);
      });

      if (delta) {
        it('renders issue delta formatted', () => {
          expect(wrapper.text()).toContain(expectedDelta);
        });
      } else {
        it('does not render issue delta formatted', () => {
          expect(wrapper.text()).not.toContain('(+');
          expect(wrapper.text()).not.toContain('(-');
        });
      }

      if (expectedPercentage) {
        it('renders issue delta as a percentage', () => {
          expect(wrapper.text()).toContain(expectedPercentage);
        });
      } else {
        it('does not render issue delta as a percentage', () => {
          expect(wrapper.text()).not.toContain('%)');
        });
      }
    },
  );
});
