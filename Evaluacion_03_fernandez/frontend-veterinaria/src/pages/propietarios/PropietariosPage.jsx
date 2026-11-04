import CrudPage from '../../components/CrudPage.jsx';
import { propietarioService } from '../../services/propietarioService.js';
import PropietarioForm from './PropietarioForm.jsx';

const config = {
  title: 'Propietarios', singular: 'Propietario', newLabel: 'Nuevo propietario', icon: 'owners',
  description: 'Administra los datos de las personas responsables de cada mascota.',
  service: propietarioService, Form: PropietarioForm,
  columns: [
    { key: 'id', label: 'ID', render: (record) => <span className="record-id">#{record.id}</span> },
    { key: 'nombre', label: 'Nombre', className: 'cell-strong' },
    { key: 'apellido', label: 'Apellido' },
    { key: 'telefono', label: 'Teléfono' },
    { key: 'correo', label: 'Correo' },
  ],
};

export default function PropietariosPage() { return <CrudPage config={config} />; }
