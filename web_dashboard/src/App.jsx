import React from "react";
import { Routes, Route, Navigate } from "react-router-dom";
import { ThemeProvider } from "@mui/material/styles";
import { theme } from "./theme";
import Login from "./pages/Login";
import Dashboard from "./pages/Dashboard";
import Clients from "./pages/Clients";
import ClientDetail from "./pages/ClientDetail";
import RoutesPage from "./pages/Routes";

function useAuth() {
  const [token, setToken] = React.useState(localStorage.getItem("ecoclean_token"));
  const [user, setUser] = React.useState(JSON.parse(localStorage.getItem("ecoclean_user") || "null"));

  const login = (t, u) => {
    localStorage.setItem("ecoclean_token", t);
    localStorage.setItem("ecoclean_user", JSON.stringify(u));
    setToken(t); setUser(u);
  };

  const logout = () => {
    localStorage.removeItem("ecoclean_token");
    localStorage.removeItem("ecoclean_user");
    setToken(null); setUser(null);
    window.location.href = "/login";
  };

  return { token, user, login, logout };
}

export default function App() {
  const auth = useAuth();
  return (
    <ThemeProvider theme={theme}>
      <Routes>
        <Route path="/login" element={<Login auth={auth} />} />
        <Route path="/" element={auth.token ? <Dashboard auth={auth} /> : <Navigate to="/login" replace />} />
        <Route path="/clients" element={auth.token ? <Clients auth={auth} /> : <Navigate to="/login" replace />} />
        <Route path="/clients/:id" element={auth.token ? <ClientDetail auth={auth} /> : <Navigate to="/login" replace />} />
        <Route path="/routes" element={auth.token ? <RoutesPage auth={auth} /> : <Navigate to="/login" replace />} />
      </Routes>
    </ThemeProvider>
  );
}
