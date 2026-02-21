import React from "react";
import TopBar from "../components/TopBar";
import Container from "@mui/material/Container";
import Paper from "@mui/material/Paper";
import Typography from "@mui/material/Typography";
import Button from "@mui/material/Button";
import TextField from "@mui/material/TextField";
import Box from "@mui/material/Box";
import MenuItem from "@mui/material/MenuItem";
import Chip from "@mui/material/Chip";
import Divider from "@mui/material/Divider";
import { apiClient } from "../api";

const DAYS = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];

export default function RoutesPage({ auth }) {
  const api = apiClient(auth.token);
  const [routes, setRoutes] = React.useState([]);
  const [drivers, setDrivers] = React.useState([]);
  const [clients, setClients] = React.useState([]);

  const [code, setCode] = React.useState("");
  const [name, setName] = React.useState("");
  const [pickupDay, setPickupDay] = React.useState("Wednesday");
  const [assignedDriverId, setAssignedDriverId] = React.useState("");
  const [stopClientIds, setStopClientIds] = React.useState("");

  const load = async () => {
    const [r, d, c] = await Promise.all([
      api.get("/api/routes"),
      api.get("/api/users", { params: { role: "DRIVER" } }),
      api.get("/api/clients")
    ]);
    setRoutes(r.data.routes || []);
    setDrivers(d.data.users || []);
    setClients(c.data.clients || []);
  };

  React.useEffect(() => { load(); }, []);

  const createRoute = async () => {
    // stopClientIds: comma-separated client codes or phones OR direct IDs
    // For MVP, user will paste client codes separated by commas; we map to IDs.
    const tokens = stopClientIds.split(",").map(s => s.trim()).filter(Boolean);
    const mappedIds = tokens.map(t => {
      const found = clients.find(c => c.clientCode === t || c.phone === t);
      return found?.id;
    }).filter(Boolean);

    await api.post("/api/routes", {
      code, name: name || null, pickupDay, assignedDriverId: assignedDriverId || null,
      stopClientIds: mappedIds
    });
    setCode(""); setName(""); setStopClientIds("");
    await load();
  };

  return (
    <>
      <TopBar auth={auth} title="Routes & Assignments" />
      <Container maxWidth="lg" sx={{ py: 4 }}>
        <Paper sx={{ p: 3, borderRadius: 4, mb: 2 }}>
          <Typography variant="h6" sx={{ fontWeight: 900, mb: 1 }}>Create Route (1 driver, 1 truck)</Typography>
          <Typography variant="body2" sx={{ opacity: 0.8, mb: 2 }}>
            Create a route, assign it to your driver, and paste client codes/phones in pickup order.
          </Typography>

          <Box sx={{ display: "grid", gridTemplateColumns: { xs: "1fr", md: "1fr 1fr 1fr" }, gap: 2 }}>
            <TextField label="Route Code (e.g., R-WED-01)" value={code} onChange={(e)=>setCode(e.target.value)} />
            <TextField label="Route Name (optional)" value={name} onChange={(e)=>setName(e.target.value)} />
            <TextField select label="Pickup Day" value={pickupDay} onChange={(e)=>setPickupDay(e.target.value)}>
              {DAYS.map(d => <MenuItem key={d} value={d}>{d}</MenuItem>)}
            </TextField>
            <TextField select label="Assign Driver" value={assignedDriverId} onChange={(e)=>setAssignedDriverId(e.target.value)}>
              <MenuItem value="">(select)</MenuItem>
              {drivers.map(u => <MenuItem key={u.id} value={u.id}>{u.name} ({u.phone || u.username})</MenuItem>)}
            </TextField>

            <TextField
              label="Stops (comma-separated client codes or phones, in order)"
              value={stopClientIds}
              onChange={(e)=>setStopClientIds(e.target.value)}
              placeholder="ECG-000001, ECG-000002, 024xxxxxxx ..."
              multiline
              minRows={2}
              sx={{ gridColumn: { xs: "1 / -1", md: "1 / -1" } }}
            />
          </Box>

          <Box sx={{ mt: 2, display: "flex", gap: 1 }}>
            <Button variant="contained" onClick={createRoute} disabled={!code || !pickupDay}>Create Route</Button>
            <Button variant="outlined" onClick={load}>Refresh</Button>
          </Box>

          <Divider sx={{ my: 2 }} />

          <Typography variant="subtitle1" sx={{ fontWeight: 900, mb: 1 }}>Tip</Typography>
          <Typography variant="body2" sx={{ opacity: 0.8 }}>
            You can copy client codes from the Clients table. The driver will see an ordered checklist on pickup day.
          </Typography>
        </Paper>

        <Paper sx={{ p: 3, borderRadius: 4 }}>
          <Typography variant="h6" sx={{ fontWeight: 900, mb: 2 }}>Existing Routes</Typography>
          {routes.length === 0 && <Typography sx={{ opacity: 0.7 }}>No routes yet.</Typography>}
          {routes.map(r => (
            <Box key={r.id} sx={{ mb: 2, p: 2, border: "1px solid rgba(0,0,0,0.08)", borderRadius: 3 }}>
              <Box sx={{ display: "flex", justifyContent: "space-between", gap: 2, flexWrap: "wrap" }}>
                <Box>
                  <Typography sx={{ fontWeight: 900 }}>{r.code} {r.name ? `• ${r.name}` : ""}</Typography>
                  <Typography sx={{ opacity: 0.8 }}>Pickup: {r.pickupDay} • Driver: {r.assignedDriver?.name || "Unassigned"}</Typography>
                </Box>
                <Chip size="small" label={r.isActive ? "Active" : "Inactive"} />
              </Box>
              <Typography sx={{ mt: 1, fontWeight: 700 }}>Stops: {r.stops?.length || 0}</Typography>
              <Typography variant="body2" sx={{ opacity: 0.8 }}>
                {r.stops?.slice(0, 8).map(s => `${s.stopOrder}. ${s.client.clientCode}`).join("  •  ")}
                {r.stops?.length > 8 ? " ..." : ""}
              </Typography>
            </Box>
          ))}
        </Paper>
      </Container>
    </>
  );
}
