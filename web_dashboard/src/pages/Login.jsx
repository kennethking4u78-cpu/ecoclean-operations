import React from "react";
import { apiClient } from "../api";
import Container from "@mui/material/Container";
import Paper from "@mui/material/Paper";
import TextField from "@mui/material/TextField";
import Button from "@mui/material/Button";
import Typography from "@mui/material/Typography";
import Box from "@mui/material/Box";

export default function Login({ auth }) {
  const [username, setUsername] = React.useState("admin");
  const [password, setPassword] = React.useState("Admin@1234");
  const [error, setError] = React.useState(null);

  const submit = async (e) => {
    e.preventDefault();
    setError(null);
    try {
      const res = await apiClient().post("/api/auth/login", { username, password });
      auth.login(res.data.token, res.data.user);
      window.location.href = "/";
    } catch (err) {
      setError(err?.response?.data?.error || "Login failed");
    }
  };

  return (
    <Container maxWidth="sm" sx={{ py: 8 }}>
      <Box sx={{ display: "flex", justifyContent: "center", mb: 3 }}>
        <img src="/assets/ecoclean_logo.png" alt="EcoClean Ghana" style={{ height: 70 }} />
      </Box>
      <Paper sx={{ p: 4, borderRadius: 4 }}>
        <Typography variant="h5" sx={{ fontWeight: 800, mb: 1 }}>EcoClean Ghana Dashboard</Typography>
        <Typography variant="body2" sx={{ mb: 3, opacity: 0.8 }}>Login to manage clients, routes and payments.</Typography>
        <form onSubmit={submit}>
          <TextField fullWidth label="Username" value={username} onChange={(e)=>setUsername(e.target.value)} sx={{ mb: 2 }} />
          <TextField fullWidth label="Password" type="password" value={password} onChange={(e)=>setPassword(e.target.value)} sx={{ mb: 2 }} />
          {error && <Typography color="error" sx={{ mb: 2 }}>{String(error)}</Typography>}
          <Button type="submit" variant="contained" fullWidth size="large">Login</Button>
        </form>
      </Paper>
    </Container>
  );
}
