import React from "react";
import { useParams } from "react-router-dom";
import { apiClient } from "../api";
import TopBar from "../components/TopBar";
import Container from "@mui/material/Container";
import Paper from "@mui/material/Paper";
import Typography from "@mui/material/Typography";
import Button from "@mui/material/Button";
import Grid from "@mui/material/Grid";

export default function ClientDetail({ auth }) {
  const { id } = useParams();
  const [client, setClient] = React.useState(null);

  React.useEffect(() => {
    (async () => {
      const api = apiClient(auth.token);
      const res = await api.get(`/api/clients/${id}`);
      setClient(res.data.client);
    })();
  }, [id, auth.token]);

  if (!client) return (
    <>
      <TopBar auth={auth} title="Client" />
      <Container maxWidth="lg" sx={{ py: 4 }}><Typography>Loading...</Typography></Container>
    </>
  );

  return (
    <>
      <TopBar auth={auth} title={`Client – ${client.clientCode}`} />
      <Container maxWidth="lg" sx={{ py: 4 }}>
        <Paper sx={{ p: 3, borderRadius: 4 }}>
          <Grid container spacing={2}>
            <Grid item xs={12} md={8}>
              <Typography variant="h6" sx={{ fontWeight: 900 }}>{client.fullName}</Typography>
              <Typography sx={{ opacity: 0.8 }}>{client.phone} • {client.zone}</Typography>
              <Typography sx={{ mt: 2 }}><b>Pickup Day:</b> {client.pickupDay || "-"}</Typography>
              <Typography><b>Payment Status:</b> {client.paymentStatus}</Typography>
              <Typography><b>Bins:</b> {client.binCount}</Typography>
              <Typography><b>Landmark:</b> {client.landmark || "-"}</Typography>
              <Typography><b>Notes:</b> {client.notes || "-"}</Typography>
              {client.googleMapsLink && (
                <Button sx={{ mt: 2 }} variant="contained" href={client.googleMapsLink} target="_blank">Open in Google Maps</Button>
              )}
            </Grid>
            <Grid item xs={12} md={4}>
              {client.buildingPhotoUrl ? (
                <img src={`http://localhost:4000${client.buildingPhotoUrl}`} alt="Building" style={{ width: "100%", borderRadius: 16 }} />
              ) : (
                <Typography sx={{ opacity: 0.7 }}>No photo uploaded.</Typography>
              )}
            </Grid>
          </Grid>
        </Paper>
      </Container>
    </>
  );
}
