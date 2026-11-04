import Sidebar from './Sidebar.jsx';
import Navbar from './Navbar.jsx';

export default function Layout({ current, children }) {
  return <div className="app-layout">
    <a className="skip-link" href="#contenido">Ir al contenido</a>
    <Sidebar current={current} />
    <div className="main-layout"><Navbar current={current} /><main id="contenido" className={`content theme-${current}`} tabIndex={-1}>{children}</main>
      <footer className="main-footer">Sistema de Atención Veterinaria <span>Evaluación N.º 03 · React + Spring Boot</span></footer>
    </div>
  </div>;
}
