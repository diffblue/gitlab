export const metricsResponse = {
  new_metrics: [
    { name: 'gem_size_mb{name=pg}', value: '3.0', previous_value: null },
    { name: 'memory_static_objects_retained_items', value: '258835', previous_value: null },
  ],
  existing_metrics: [
    { name: 'gem_total_size_mb', value: '194.8' },
    { name: 'memory_static_objects_allocated_mb', value: '163.7' },
    { name: 'memory_static_objects_retained_mb', value: '30.6', previous_value: '30.5' },
    { name: 'memory_static_objects_allocated_items', value: '1', previous_value: '1552382' },
  ],
  removed_metrics: [
    { name: 'gem_size_mb{name=charlock_holmes}', value: '2.7', previous_value: null },
    { name: 'gem_size_mb{name=omniauth-auth0}', value: '0.5', previous_value: null },
  ],
};

export const changedMetric = {
  name: 'name',
  value: 'value',
  previous_value: 'prev',
};
export const unchangedMetric = {
  name: 'name',
  value: 'value',
};
