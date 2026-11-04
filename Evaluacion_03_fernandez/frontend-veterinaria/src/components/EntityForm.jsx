import { useState } from 'react';
import Notice from './Notice.jsx';
import { toPayload } from '../utils/validation.js';

// Cada módulo define sus campos y validaciones; el envío y los errores son comunes.
export default function EntityForm({ title, initialValues, fields, validate, numericFields = [], onSave, onCancel, disabled = false }) {
  const [values, setValues] = useState(initialValues);
  const [errors, setErrors] = useState({});
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  async function submit(event) {
    event.preventDefault();
    if (saving || disabled) return;
    const nextErrors = validate(values);
    setErrors(nextErrors);
    setError('');
    if (Object.keys(nextErrors).length) {
      const field = event.currentTarget.elements.namedItem(Object.keys(nextErrors)[0]);
      field?.focus();
      return;
    }
    setSaving(true);
    try {
      await onSave(toPayload(values, numericFields));
    } catch (failure) {
      setErrors(failure.details || {});
      const detailText = Object.values(failure.details || {}).join(' ');
      setError(detailText ? `${failure.message} ${detailText}` : failure.message);
      setSaving(false);
    }
  }

  return <section className="panel form-panel" aria-labelledby="form-title">
    <div className="panel-heading"><div><span className="eyebrow">DATOS DEL REGISTRO</span><h2 id="form-title">{title}</h2></div><span className="muted">* Campos obligatorios</span></div>
    <Notice>{error}</Notice>
    <form onSubmit={submit} noValidate>
      <fieldset disabled={saving} className="form-grid">
        {fields.map(({ name, label, type = 'text', options, placeholder, ...attributes }) => {
          const common = {
            ...attributes, id: `field-${name}`, name, value: values[name] ?? '',
            onChange: (event) => {
              setValues((previous) => ({ ...previous, [name]: event.target.value }));
              setErrors((previous) => ({ ...previous, [name]: '' }));
            },
            'aria-invalid': Boolean(errors[name]),
            'aria-describedby': errors[name] ? `error-${name}` : undefined,
          };
          return <div className={`form-field ${type === 'textarea' ? 'full-width' : ''}`} key={name}>
            <label htmlFor={common.id}>{label}{attributes.required && <span className="required"> *</span>}</label>
            {type === 'select'
              ? <select {...common}><option value="">{placeholder || 'Selecciona una opción'}</option>{options?.map((option) => <option value={option.value} key={option.value}>{option.label}</option>)}</select>
              : type === 'textarea' ? <textarea {...common} rows={3} placeholder={placeholder} />
                : <input {...common} type={type} placeholder={placeholder} />}
            {errors[name] && <small className="field-error" id={`error-${name}`}>{errors[name]}</small>}
          </div>;
        })}
      </fieldset>
      <div className="form-actions"><button type="button" className="button button-secondary" disabled={saving} onClick={onCancel}>Cancelar</button><button type="submit" className="button button-primary" disabled={saving || disabled}>{saving ? 'Guardando…' : 'Guardar registro'}</button></div>
    </form>
  </section>;
}
