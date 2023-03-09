import { shallowMount, mount } from '@vue/test-utils';
import DynamicFields from 'ee/security_configuration/components/dynamic_fields.vue';
import { makeEntities } from '../helpers';

describe('DynamicFields component', () => {
  let wrapper;

  const createComponent = (props = {}, mountFn = shallowMount) => {
    wrapper = mountFn(DynamicFields, {
      propsData: {
        ...props,
      },
    });
  };

  const findFields = () => wrapper.findAllComponents({ ref: 'fields' });

  describe.each`
    context                                     | entities
    ${'no entities'}                            | ${[]}
    ${'entities with unsupported entity types'} | ${makeEntities(3, { type: 'foo' })}
  `('given $context', ({ entities }) => {
    beforeEach(() => {
      createComponent({ entities });
    });

    it('renders no fields', () => {
      expect(findFields()).toHaveLength(0);
    });
  });

  describe.each([true, false])('given the disabled prop is %p', (disabled) => {
    let entities;

    beforeEach(() => {
      entities = makeEntities(2);
      createComponent({ entities, disabled }, mount);
    });

    it('uses a fieldset as the root element', () => {
      expect(wrapper.element.tagName).toBe('FIELDSET');
    });

    // https://developer.mozilla.org/en-US/docs/Web/HTML/Element/fieldset#attr-disabled
    it(`${disabled ? 'sets' : 'does not set'} the disabled attribute on the root element`, () => {
      expect('disabled' in wrapper.attributes()).toBe(disabled);
    });

    it('passes the disabled prop to child fields', () => {
      entities.forEach((entity, i) => {
        expect(findFields().at(i).props('disabled')).toBe(disabled);
      });
    });
  });

  describe('given valid entities', () => {
    let entities;
    let fields;

    beforeEach(() => {
      entities = makeEntities(3);
      createComponent({ entities });
      fields = findFields();
    });

    it('renders each field with the correct component', () => {
      entities.forEach((entity, i) => {
        const field = fields.at(i);
        expect(field.is(DynamicFields.entityTypeToComponent[entity.type])).toBe(true);
      });
    });

    it('passes the correct props to each field', () => {
      entities.forEach((entity, i) => {
        const field = fields.at(i);

        expect(field.props()).toMatchObject({
          field: entity.field,
          label: entity.label,
          description: entity.description,
          defaultValue: entity.defaultValue,
          value: entity.value,
        });
      });
    });

    describe.each`
      fieldIndex | newValue
      ${0}       | ${'foo'}
      ${1}       | ${'bar'}
      ${2}       | ${'qux'}
    `(
      'when a field at index $fieldIndex emits an input event value $newValue',
      ({ fieldIndex, newValue }) => {
        beforeEach(() => {
          fields.at(fieldIndex).vm.$emit('input', newValue);
        });

        it('emits an input event with the correct entity value changed', () => {
          const [[payload]] = wrapper.emitted('input');

          entities.forEach((entity, i) => {
            if (i === fieldIndex) {
              const expectedChangedEntity = {
                ...entities[fieldIndex],
                value: newValue,
              };

              expect(payload[i]).not.toBe(entities[i]);
              expect(payload[i]).toEqual(expectedChangedEntity);
            } else {
              expect(payload[i]).toBe(entities[i]);
            }
          });
        });
      },
    );
  });
});
