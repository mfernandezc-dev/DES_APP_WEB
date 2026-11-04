import { navigation } from './Sidebar.jsx';

export default function Navbar({ current }) {
  const label = navigation.find((item) => item.id === current)?.label;
  return <header className="navbar">
    <div className="breadcrumb">Sistema de Atención Veterinaria <span>/</span> <strong>{label}</strong></div>
    <span className="local-label"><span /> Entorno local</span>
  </header>;
}
