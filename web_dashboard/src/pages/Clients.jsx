import React from "react";
import { apiClient } from "../api";
import TopBar from "../components/TopBar";
import Container from "@mui/material/Container";
import Paper from "@mui/material/Paper";
import Typography from "@mui/material/Typography";
import TextField from "@mui/material/TextField";
import Table from "@mui/material/Table";
import TableHead from "@mui/material/TableHead";
import TableRow from "@mui/material/TableRow";
import TableCell from "@mui/material/TableCell";
import TableBody from "@mui/material/TableBody";
import Chip from "@mui/material/Chip";
import Button from "@mui/material/Button";
import Box from "@mui/material/Box";

export default function Clients({ auth }) {
  const [q, setQ] = React.useState("");
  const [clients, setClients] = React.useState([]);

  const load = async () => {
    const api = apiClient(auth.token);
    const res = await api.get("/api/clients", { params: q ? { q } : {} });
    setClients(res.data.clients || []);
  };

  React.useEffect(() => { load(); }, []);

  return (
    <>
      <TopBar auth={auth} title="Clients" />
      <Container maxWidth="lg" sx={{ py: 4 }}>
        <Paper sx={{ p: 3, borderRadius: 4 }}>
          <Box sx={{ display: "flex", gap: 2, alignItems: "center", mb: 2 }}>
            <Typography variant="h6" sx={{ fontWeight: 800, flex: 1 }}>Registered Clients</Typography>
            <TextField size="small" label="Search name/phone/code" value={q} onChange={(e)=>setQ(e.target.value)} />
            <Button variant="outlined" onClick={load}>Search</Button>
          </Box>

          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Code</TableCell>
                <TableCell>Name</TableCell>
                <TableCell>Phone</TableCell>
                <TableCell>Zone</TableCell>
                <TableCell>Pickup Day</TableCell>
                <TableCell>Payment</TableCell>
                <TableCell></TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {clients.map(c => (
                <TableRow key={c.id} hover>
                  <TableCell>{c.clientCode}</TableCell>
                  <TableCell>{c.fullName}</TableCell>
                  <TableCell>{c.phone}</TableCell>
                  <TableCell>{c.zone}</TableCell>
                  <TableCell>{c.pickupDay || "-"}</TableCell>
                  <TableCell><Chip size="small" label={c.paymentStatus} /></TableCell>
                  <TableCell><Button size="small" href={`/clients/${c.id}`}>Open</Button></TableCell>
                </TableRow>
              ))}
              {clients.length === 0 && (
                <TableRow><TableCell colSpan={7}>No clients yet.</TableCell></TableRow>
              )}
            </TableBody>
          </Table>
        </Paper>
      </Container>
    </>
  );
}
