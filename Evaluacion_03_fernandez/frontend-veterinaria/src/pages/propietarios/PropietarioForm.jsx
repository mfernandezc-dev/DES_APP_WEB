import EntityForm from '../../components/EntityForm.jsx';
import { validatePropietario } from '../../utils/validation.js';

const fields = [
  { name: 'nombre', label: 'Nombre', required: true, maxLength: 100, autoComplete: 'given-name', autoFocus: true },
  { name: 'apellido', label: 'Apellido', required: true, maxLength: 100, autoComplete: 'family-name' },
  { name: 'telefono', label: 'Teléfono', type: 'tel', maxLength: 20, autoComplete: 'tel' },
  { name: 'correo', label: 'Correo electrónico', type: 'email', maxLength: 100, autoComplete: 'email', placeholder: 'nombre@correo.com' },
];

export default function PropietarioForm({ record, ...props }) {
  const initialValues = Object.fromEntries(fields.map(({ name }) => [name, record?.[name] ?? '']));
  return <EntityForm {...props} title={record ? `Editar propietario #${record.id}` : 'Nuevo propietario'} initialValues={initialValues} fields={fields} validate={validatePropietario} />;
}
