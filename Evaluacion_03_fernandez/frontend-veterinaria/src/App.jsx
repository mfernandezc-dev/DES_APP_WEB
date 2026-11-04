import { useEffect, useState } from 'react';
import Layout from './components/Layout.jsx';
import Dashboard from './pages/Dashboard.jsx';
import PropietariosPage from './pages/propietarios/PropietariosPage.jsx';
import MascotasPage from './pages/mascotas/MascotasPage.jsx';
import ConsultasPage from './pages/consultas/ConsultasPage.jsx';

const pages = { inicio: Dashboard, propietarios: PropietariosPage, mascotas: MascotasPage, consultas: ConsultasPage };
const getPage = () => Object.hasOwn(pages, window.location.hash.slice(1)) ? window.location.hash.slice(1) : 'inicio';

export default function App() {
  const [current, setCurrent] = useState(getPage);
  useEffect(() => {
    function navigate() { setCurrent(getPage()); window.scrollTo({ top: 0 }); }
    window.addEventListener('hashchange', navigate);
    return () => window.removeEventListener('hashchange', navigate);
  }, []);
  useEffect(() => { document.title = `${current.charAt(0).toUpperCase() + current.slice(1)} | Atención Veterinaria`; }, [current]);
  const Page = pages[current];
  return <Layout current={current}><Page key={current} /></Layout>;
}
