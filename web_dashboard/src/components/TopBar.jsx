import React from "react";
import AppBar from "@mui/material/AppBar";
import Toolbar from "@mui/material/Toolbar";
import Typography from "@mui/material/Typography";
import Button from "@mui/material/Button";
import Box from "@mui/material/Box";

export default function TopBar({ auth, title }) {
  return (
    <AppBar position="sticky" elevation={0} sx={{ borderBottom: "1px solid rgba(0,0,0,0.08)" }}>
      <Toolbar>
        <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
          <img src="/assets/ecoclean_logo.png" alt="EcoClean Ghana" style={{ height: 34 }} />
          <Typography variant="h6" sx={{ fontWeight: 800 }}>{title || "EcoClean Ghana"}</Typography>
        </Box>
        <Box sx={{ flex: 1 }} />
        <Typography variant="body2" sx={{ mr: 2 }}>{auth.user?.name} ({auth.user?.role})</Typography>
        <Button color="inherit" onClick={auth.logout}>Logout</Button>
      </Toolbar>
    </AppBar>
  );
}
