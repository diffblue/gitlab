import { GlDrawer } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TracingDetailsDrawer from 'ee/tracing/components/tracing_details_drawer.vue';

describe('TracingDetailsDrawer', () => {
  let wrapper;

  const findDrawer = () => wrapper.findComponent(GlDrawer);

  const mountComponent = () => {
    wrapper = shallowMountExtended(TracingDetailsDrawer, {
      propsData: {
        span: {
          service_name: 'service-1',
          operation: 'operation-1',
          span_id: '123',
          trace_id: '456',
          timestamp: '2021-01-01',
          duration_nano: 1000,
          statusCode: 200,
        },
        open: true,
      },
    });
  };

  beforeEach(() => {
    mountComponent();
  });

  it('renders the component properly', () => {
    expect(wrapper.exists()).toBe(true);
    expect(findDrawer().exists()).toBe(true);
    expect(findDrawer().props('open')).toBe(true);
  });

  it('emits close', () => {
    findDrawer().vm.$emit('close');
    expect(wrapper.emitted('close').length).toBe(1);
  });

  it('displays the correct title', () => {
    expect(wrapper.findByTestId('span-title').text()).toBe('Span Details service-1 : operation-1');
  });

  it('displays the correct content', () => {
    const labels = wrapper.findAll('[data-testid="section-title"]');
    const values = wrapper.findAll('[data-testid="section-value"]');

    expect(labels.at(0).text()).toBe('Span ID');
    expect(values.at(0).text()).toBe('123');

    expect(labels.at(1).text()).toBe('Trace ID');
    expect(values.at(1).text()).toBe('456');

    expect(labels.at(2).text()).toBe('Date');
    expect(values.at(2).text()).toBe('Jan 1, 2021 12:00am UTC');

    expect(labels.at(3).text()).toBe('Service');
    expect(values.at(3).text()).toBe('service-1');

    expect(labels.at(4).text()).toBe('Operation');
    expect(values.at(4).text()).toBe('operation-1');

    expect(labels.at(5).text()).toBe('Duration');
    expect(values.at(5).text()).toBe('1 ms');

    expect(labels.at(6).text()).toBe('Status Code');
    expect(values.at(6).text()).toBe('200');
  });
});
