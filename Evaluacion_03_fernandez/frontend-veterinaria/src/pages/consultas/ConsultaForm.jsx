import EntityForm from '../../components/EntityForm.jsx';
import { validateConsulta } from '../../utils/validation.js';

export default function ConsultaForm({ record, related = [], ...props }) {
  const fields = [
    { name: 'idMascota', label: 'Mascota', type: 'select', required: true, autoFocus: true, placeholder: 'Selecciona una mascota', options: related.map((pet) => ({ value: pet.id, label: `${pet.nombre} · ${pet.especie} · #${pet.id}` })) },
    { name: 'fecha', label: 'Fecha de consulta', type: 'date', required: true },
    { name: 'motivo', label: 'Motivo', type: 'textarea', required: true, maxLength: 255 },
    { name: 'diagnostico', label: 'Diagnóstico', type: 'textarea', required: true, maxLength: 500 },
    { name: 'costo', label: 'Costo (S/)', type: 'number', required: true, min: 0, max: 99999999.99, step: '0.01', placeholder: '0.00' },
  ];
  const initialValues = Object.fromEntries(fields.map(({ name }) => [name, record?.[name] ?? '']));
  function validate(values) {
    const errors = validateConsulta(values);
    if (!related.some((pet) => String(pet.id) === String(values.idMascota))) errors.idMascota = 'Selecciona una mascota de la lista actual.';
    return errors;
  }
  return <EntityForm {...props} title={record ? `Editar consulta #${record.id}` : 'Nueva consulta'} initialValues={initialValues} fields={fields} validate={validate} numericFields={['idMascota', 'costo']} disabled={!related.length || props.disabled} />;
}
