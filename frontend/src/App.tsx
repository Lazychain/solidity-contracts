import { Link } from "react-router-dom";
import AppRoutes from "./components/AppRoutes";
import { Home, AppWindow } from "lucide-react";

function App() {
  return (
    <>
      <div>
        <header>
          <nav className="flex items-center space-x-4 lg:space-x-6 mx-6">
            <Link to="/" className="flex items-center space-x-2">
              <Home className="size-6" />
            </Link>
            <Link to="/lottery" className="flex items-center space-x-2">
              <AppWindow className="size-6" ></AppWindow>
            </Link>
          </nav>
        </header>
        <main>
          <AppRoutes />
        </main>
      </div>
    </>
  );
}

export default App;
