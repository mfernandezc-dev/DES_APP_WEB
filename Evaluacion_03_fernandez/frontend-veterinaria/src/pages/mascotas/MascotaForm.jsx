import EntityForm from '../../components/EntityForm.jsx';
import { today, validateMascota } from '../../utils/validation.js';
import { fullName } from '../../utils/format.js';

export default function MascotaForm({ record, related = [], ...props }) {
  const fields = [
    { name: 'nombre', label: 'Nombre', required: true, maxLength: 100, autoFocus: true },
    { name: 'especie', label: 'Especie', required: true, maxLength: 50, placeholder: 'Por ejemplo: perro, gato…' },
    { name: 'fechaNacimiento', label: 'Fecha de nacimiento', type: 'date', required: true, max: today() },
    { name: 'idPropietario', label: 'Propietario', type: 'select', required: true, placeholder: 'Selecciona un propietario', options: related.map((person) => ({ value: person.id, label: `${fullName(person)} · #${person.id}` })) },
  ];
  const initialValues = Object.fromEntries(fields.map(({ name }) => [name, record?.[name] ?? '']));
  function validate(values) {
    const errors = validateMascota(values);
    if (!related.some((person) => String(person.id) === String(values.idPropietario))) errors.idPropietario = 'Selecciona un propietario de la lista actual.';
    return errors;
  }
  return <EntityForm {...props} title={record ? `Editar mascota #${record.id}` : 'Nueva mascota'} initialValues={initialValues} fields={fields} validate={validate} numericFields={['idPropietario']} disabled={!related.length || props.disabled} />;
}
