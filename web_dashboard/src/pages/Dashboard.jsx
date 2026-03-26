import React from "react";
import { apiClient } from "../api";
import Container from "@mui/material/Container";
import Grid from "@mui/material/Grid";
import Paper from "@mui/material/Paper";
import Typography from "@mui/material/Typography";
import Button from "@mui/material/Button";
import TopBar from "../components/TopBar";

function StatCard({ label, value }) {
  return (
    <Paper sx={{ p: 3, borderRadius: 4 }}>
      <Typography variant="body2" sx={{ opacity: 0.7 }}>{label}</Typography>
      <Typography variant="h4" sx={{ fontWeight: 900 }}>{value}</Typography>
    </Paper>
  );
}

export default function Dashboard({ auth }) {
  const [stats, setStats] = React.useState({ total: 0, paid: 0 });

  React.useEffect(() => {
    (async () => {
      const api = apiClient(auth.token);
      const res = await api.get("/api/clients");
      const clients = res.data.clients || [];
      const paid = clients.filter(c => c.paymentStatus === "PAID").length;
      setStats({ total: clients.length, paid });
    })();
  }, [auth.token]);

  return (
    <>
      <TopBar auth={auth} title="EcoClean Ghana – Dashboard" />
      <Container maxWidth="lg" sx={{ py: 4 }}>
        <Grid container spacing={2}>
          <Grid item xs={12} md={6}><StatCard label="Total Registered Clients" value={stats.total} /></Grid>
          <Grid item xs={12} md={6}><StatCard label="Paying Clients (Paid)" value={stats.paid} /></Grid>
          <Grid item xs={12}>
            <Paper sx={{ p: 3, borderRadius: 4 }}>
              <Typography variant="h6" sx={{ fontWeight: 800, mb: 1 }}>Quick Actions</Typography>
              <Button variant="contained" href="/clients" sx={{ mr: 1 }}>View Clients</Button>
              <Button variant="outlined" href="/routes">Routes</Button>
            </Paper>
          </Grid>
        </Grid>
      </Container>
    </>
  );
}
